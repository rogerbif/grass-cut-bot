@tool
class_name BumpVersionTool
extends EditorScript

## Ferramenta de Gerenciamento e Incremento de Versão - Grass Cut Bot (Game SemVer).
## Atualiza atomicamente os 3 arquivos canônicos:
## 1. res://scripts/core/game_version.gd
## 2. res://project.godot
## 3. res://export_presets.cfg
##
## Modo de uso no Godot Editor:
## Abra este script no Script Editor da Godot e pressione Ctrl+Shift+X (ou File -> Run).

const GAME_VERSION_PATH: String = "res://scripts/core/game_version.gd"
const PROJECT_GODOT_PATH: String = "res://project.godot"
const EXPORT_PRESETS_PATH: String = "res://export_presets.cfg"

enum BumpMode {
	PATCH,   # +1 Correção / Ajuste / Polimento
	MINOR,   # +1 Novo Sistema / Fases / Entidades
	TO_BETA, # Transição para BETA (Feature Complete)
	TO_RC,   # Transição para RC (Release Candidate / Freeze)
	TO_RELEASE # Transição para Lançamento Gold 1.0
}

func _run() -> void:
	# Por padrão no _run() avança 1 PATCH. Altere o enum abaixo conforme a necessidade.
	bump(BumpMode.PATCH)

static func bump(mode: BumpMode = BumpMode.PATCH) -> void:
	print("[BUMP_VERSION] Iniciando processo de atualização de versão...")

	var major: int = GameVersion.MAJOR
	var minor: int = GameVersion.MINOR
	var patch: int = GameVersion.PATCH
	var stage: String = GameVersion.STAGE

	print("[BUMP_VERSION] Versão atual em memória: %s" % GameVersion.get_version_string())

	match mode:
		BumpMode.PATCH:
			patch += 1
		BumpMode.MINOR:
			minor += 1
			patch = 0
		BumpMode.TO_BETA:
			stage = "BETA"
			patch = 0
		BumpMode.TO_RC:
			stage = "RC"
			patch = 0
		BumpMode.TO_RELEASE:
			stage = "RELEASE"
			if major == 0:
				major = 1
				minor = 0
				patch = 0

	var new_ver_str: String = "v%d.%d.%d" % [major, minor, patch]
	if not stage.is_empty() and stage.to_upper() != "RELEASE":
		new_ver_str += "-%s" % stage.to_lower()

	var raw_version: String = "%d.%d.%d" % [major, minor, patch]
	if not stage.is_empty() and stage.to_upper() != "RELEASE":
		raw_version += "-%s" % stage.to_lower()

	var version_code: int = major * 10000 + minor * 100 + patch

	print("[BUMP_VERSION] Nova versão calculada: %s (Raw: %s, Code: %d)" % [new_ver_str, raw_version, version_code])

	# 1. Atualiza scripts/core/game_version.gd
	var gv_content: String = """class_name GameVersion
extends RefCounted

## Gerenciador Central de Versionamento - Grass Cut Bot (Game SemVer).
## Fonte canônica para a versão do jogo, ciclo de maturidade (Alpha, Beta, Gold)
## e compatibilidade de saves e presets de exportação.

const MAJOR: int = %d
const MINOR: int = %d
const PATCH: int = %d
const STAGE: String = "%s" # "PRE-ALPHA", "ALPHA", "BETA", "RC", "RELEASE"
const BUILD_TYPE: String = "dev" # "dev", "nightly", "public"

## Retorna a versão crua sem prefixo 'v' (ex: "0.12.68-alpha").
## Lê dinamicamente do ProjectSettings se disponível para garantir sincronização automática.
static func get_raw_version() -> String:
\tvar proj_ver: String = String(ProjectSettings.get_setting("application/config/version", ""))
\tif not proj_ver.is_empty():
\t\treturn proj_ver
\tvar base: String = "%%d.%%d.%%d" %% [MAJOR, MINOR, PATCH]
\tif not STAGE.is_empty() and STAGE.to_upper() != "RELEASE":
\t\tbase += "-%%s" %% STAGE.to_lower()
\treturn base

## Retorna a string semântica padrão com prefixo 'v' (ex: "v0.12.68-alpha")
static func get_version_string() -> String:
\tvar raw: String = get_raw_version()
\tif not raw.begins_with("v"):
\t\treturn "v%%s" %% raw
\treturn raw

## Retorna o nome completo com título do jogo (ex: "Grass Cut Bot v0.12.68-alpha")
static func get_display_name() -> String:
\treturn "Grass Cut Bot %%s" %% get_version_string()

## Retorna um código numérico de versão para versionCode do Android (ex: 1268 para 0.12.68)
static func get_version_code() -> int:
\tvar raw: String = get_raw_version()
\tvar clean: String = raw.trim_prefix("v").split("-")[0]
\tvar parts: PackedStringArray = clean.split(".")
\tif parts.size() >= 3:
\t\treturn parts[0].to_int() * 10000 + parts[1].to_int() * 100 + parts[2].to_int()
\treturn MAJOR * 10000 + MINOR * 100 + PATCH

## Retorna se a versão atual é Pre-Alpha
static func is_pre_alpha() -> bool:
\treturn get_raw_version().to_upper().contains("PRE-ALPHA")

## Retorna se a versão atual é Alpha
static func is_alpha() -> bool:
\treturn get_raw_version().to_upper().contains("ALPHA") and not is_pre_alpha()

## Retorna se a versão atual é Beta
static func is_beta() -> bool:
\treturn get_raw_version().to_upper().contains("BETA")

## Retorna se a versão atual é Release Candidate (Freeze)
static func is_rc() -> bool:
\treturn get_raw_version().to_upper().contains("RC")

## Retorna se a versão atual é de Lançamento Comercial / Gold Master
static func is_release() -> bool:
\treturn not is_pre_alpha() and not is_alpha() and not is_beta() and not is_rc()

## Retorna um dicionário estruturado com todos os metadados da versão
static func get_full_info() -> Dictionary:
\tvar raw: String = get_raw_version()
\tvar clean: String = raw.trim_prefix("v").split("-")[0]
\tvar parts: PackedStringArray = clean.split(".")
\tvar cur_maj: int = MAJOR
\tvar cur_min: int = MINOR
\tvar cur_pat: int = PATCH
\tif parts.size() >= 3:
\t\tcur_maj = parts[0].to_int()
\t\tcur_min = parts[1].to_int()
\t\tcur_pat = parts[2].to_int()
\treturn {
\t\t"version_string": get_version_string(),
\t\t"raw_version": raw,
\t\t"display_name": get_display_name(),
\t\t"version_code": get_version_code(),
\t\t"major": cur_maj,
\t\t"minor": cur_min,
\t\t"patch": cur_pat,
\t\t"stage": STAGE,
\t\t"build_type": BUILD_TYPE
\t}
""" % [major, minor, patch, stage]

	var f_gv: FileAccess = FileAccess.open(GAME_VERSION_PATH, FileAccess.WRITE)
	if f_gv != null:
		f_gv.store_string(gv_content)
		f_gv.close()
		print("[BUMP_VERSION] -> %s atualizado com sucesso!" % GAME_VERSION_PATH)
	else:
		push_error("[BUMP_VERSION] Falha ao abrir %s para escrita!" % GAME_VERSION_PATH)
		return

	# 2. Atualiza project.godot
	if FileAccess.file_exists(PROJECT_GODOT_PATH):
		var f_proj: FileAccess = FileAccess.open(PROJECT_GODOT_PATH, FileAccess.READ)
		if f_proj != null:
			var proj_text: String = f_proj.get_as_text()
			f_proj.close()

			var re_ver: RegEx = RegEx.new()
			re_ver.compile('config/version="[^"]*"')
			if re_ver.search(proj_text):
				proj_text = re_ver.sub(proj_text, 'config/version="%s"' % raw_version)
			else:
				proj_text = proj_text.replace('[application]\n', '[application]\n\nconfig/version="%s"\n' % raw_version)

			var f_proj_w: FileAccess = FileAccess.open(PROJECT_GODOT_PATH, FileAccess.WRITE)
			if f_proj_w != null:
				f_proj_w.store_string(proj_text)
				f_proj_w.close()
				print("[BUMP_VERSION] -> %s atualizado com sucesso!" % PROJECT_GODOT_PATH)

	# 3. Atualiza export_presets.cfg
	if FileAccess.file_exists(EXPORT_PRESETS_PATH):
		var f_exp: FileAccess = FileAccess.open(EXPORT_PRESETS_PATH, FileAccess.READ)
		if f_exp != null:
			var exp_text: String = f_exp.get_as_text()
			f_exp.close()

			var re_code: RegEx = RegEx.new()
			re_code.compile('version/code=\\d+')
			exp_text = re_code.sub(exp_text, 'version/code=%d' % version_code)

			var re_name: RegEx = RegEx.new()
			re_name.compile('version/name="[^"]*"')
			exp_text = re_name.sub(exp_text, 'version/name="%s"' % raw_version)

			var f_exp_w: FileAccess = FileAccess.open(EXPORT_PRESETS_PATH, FileAccess.WRITE)
			if f_exp_w != null:
				f_exp_w.store_string(exp_text)
				f_exp_w.close()
				print("[BUMP_VERSION] -> %s atualizado com sucesso!" % EXPORT_PRESETS_PATH)

	print("[BUMP_VERSION] Concluído com sucesso! Nova versão ativa: %s" % new_ver_str)
