class_name GameVersion
extends RefCounted

## Gerenciador Central de Versionamento - Grass Cut Bot (Game SemVer).
## Fonte única de verdade para a versão do jogo, ciclo de maturidade (Alpha, Beta, Gold)
## e compatibilidade de saves e presets de exportação.

const MAJOR: int = 0
const MINOR: int = 12
const PATCH: int = 2
const STAGE: String = "ALPHA" # "PRE-ALPHA", "ALPHA", "BETA", "RC", "RELEASE"
const BUILD_TYPE: String = "dev" # "dev", "nightly", "public"

## Retorna a string semântica padrão com prefixo 'v' (ex: "v0.7.2-alpha")
static func get_version_string() -> String:
	var base: String = "v%d.%d.%d" % [MAJOR, MINOR, PATCH]
	if not STAGE.is_empty() and STAGE.to_upper() != "RELEASE":
		base += "-%s" % STAGE.to_lower()
	return base

## Retorna a versão crua sem prefixo 'v' para o project.godot (ex: "0.7.2-alpha")
static func get_raw_version() -> String:
	var base: String = "%d.%d.%d" % [MAJOR, MINOR, PATCH]
	if not STAGE.is_empty() and STAGE.to_upper() != "RELEASE":
		base += "-%s" % STAGE.to_lower()
	return base

## Retorna o nome completo com título do jogo (ex: "Grass Cut Bot v0.7.2-alpha")
static func get_display_name() -> String:
	return "Grass Cut Bot %s" % get_version_string()

## Retorna um código numérico de versão para versionCode do Android (ex: 702 para 0.7.2)
static func get_version_code() -> int:
	return MAJOR * 10000 + MINOR * 100 + PATCH

## Retorna se a versão atual é Pre-Alpha
static func is_pre_alpha() -> bool:
	return STAGE.to_upper() == "PRE-ALPHA"

## Retorna se a versão atual é Alpha
static func is_alpha() -> bool:
	return STAGE.to_upper() == "ALPHA"

## Retorna se a versão atual é Beta
static func is_beta() -> bool:
	return STAGE.to_upper() == "BETA"

## Retorna se a versão atual é Release Candidate (Freeze)
static func is_rc() -> bool:
	return STAGE.to_upper() == "RC"

## Retorna se a versão atual é de Lançamento Comercial / Gold Master
static func is_release() -> bool:
	return STAGE.to_upper() == "RELEASE" or (MAJOR >= 1 and STAGE.is_empty())

## Retorna um dicionário estruturado com todos os metadados da versão
static func get_full_info() -> Dictionary:
	return {
		"version_string": get_version_string(),
		"raw_version": get_raw_version(),
		"display_name": get_display_name(),
		"version_code": get_version_code(),
		"major": MAJOR,
		"minor": MINOR,
		"patch": PATCH,
		"stage": STAGE,
		"build_type": BUILD_TYPE
	}
