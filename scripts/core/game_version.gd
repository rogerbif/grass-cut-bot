class_name GameVersion
extends RefCounted

## Gerenciador Central de Versionamento - Grass Cut Bot (Game SemVer).
## Fonte canÃ´nica para a versÃ£o do jogo, ciclo de maturidade (Alpha, Beta, Gold)
## e compatibilidade de saves e presets de exportaÃ§Ã£o.

const MAJOR: int = 0
const MINOR: int = 12
const PATCH: int = 90
const STAGE: String = "ALPHA" # "PRE-ALPHA", "ALPHA", "BETA", "RC", "RELEASE"
const BUILD_TYPE: String = "dev" # "dev", "nightly", "public"

## Retorna a versÃ£o crua sem prefixo 'v' (ex: "0.12.67-alpha").
## LÃª dinamicamente do ProjectSettings se disponÃ­vel para garantir sincronizaÃ§Ã£o automÃ¡tica.
static func get_raw_version() -> String:
	var proj_ver: String = String(ProjectSettings.get_setting("application/config/version", ""))
	if not proj_ver.is_empty():
		return proj_ver
	var base: String = "%d.%d.%d" % [MAJOR, MINOR, PATCH]
	if not STAGE.is_empty() and STAGE.to_upper() != "RELEASE":
		base += "-%s" % STAGE.to_lower()
	return base

## Retorna a string semÃ¢ntica padrÃ£o com prefixo 'v' (ex: "v0.12.67-alpha")
static func get_version_string() -> String:
	var raw: String = get_raw_version()
	if not raw.begins_with("v"):
		return "v%s" % raw
	return raw

## Retorna o nome completo com tÃ­tulo do jogo (ex: "Grass Cut Bot v0.12.67-alpha")
static func get_display_name() -> String:
	return "Grass Cut Bot %s" % get_version_string()

## Retorna um cÃ³digo numÃ©rico de versÃ£o para versionCode do Android (ex: 1267 para 0.12.67)
static func get_version_code() -> int:
	var raw: String = get_raw_version()
	var clean: String = raw.trim_prefix("v").split("-")[0]
	var parts: PackedStringArray = clean.split(".")
	if parts.size() >= 3:
		return parts[0].to_int() * 10000 + parts[1].to_int() * 100 + parts[2].to_int()
	return MAJOR * 10000 + MINOR * 100 + PATCH

## Retorna se a versÃ£o atual Ã© Pre-Alpha
static func is_pre_alpha() -> bool:
	return get_raw_version().to_upper().contains("PRE-ALPHA")

## Retorna se a versÃ£o atual Ã© Alpha
static func is_alpha() -> bool:
	return get_raw_version().to_upper().contains("ALPHA") and not is_pre_alpha()

## Retorna se a versÃ£o atual Ã© Beta
static func is_beta() -> bool:
	return get_raw_version().to_upper().contains("BETA")

## Retorna se a versÃ£o atual Ã© Release Candidate (Freeze)
static func is_rc() -> bool:
	return get_raw_version().to_upper().contains("RC")

## Retorna se a versÃ£o atual Ã© de LanÃ§amento Comercial / Gold Master
static func is_release() -> bool:
	return not is_pre_alpha() and not is_alpha() and not is_beta() and not is_rc()

## Retorna um dicionÃ¡rio estruturado com todos os metadados da versÃ£o
static func get_full_info() -> Dictionary:
	var raw: String = get_raw_version()
	var clean: String = raw.trim_prefix("v").split("-")[0]
	var parts: PackedStringArray = clean.split(".")
	var cur_maj: int = MAJOR
	var cur_min: int = MINOR
	var cur_pat: int = PATCH
	if parts.size() >= 3:
		cur_maj = parts[0].to_int()
		cur_min = parts[1].to_int()
		cur_pat = parts[2].to_int()
	return {
		"version_string": get_version_string(),
		"raw_version": raw,
		"display_name": get_display_name(),
		"version_code": get_version_code(),
		"major": cur_maj,
		"minor": cur_min,
		"patch": cur_pat,
		"stage": STAGE,
		"build_type": BUILD_TYPE
	}
