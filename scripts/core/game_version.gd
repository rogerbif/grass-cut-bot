class_name GameVersion
extends RefCounted

## Gerenciador Central de Versionamento - Grass Cut Bot (Game SemVer).
## Fonte Ãºnica de verdade para a versÃ£o do jogo, ciclo de maturidade (Alpha, Beta, Gold)
## e compatibilidade de saves e presets de exportaÃ§Ã£o.

const MAJOR: int = 0
const MINOR: int = 12
const PATCH: int = 59
const STAGE: String = "ALPHA" # "PRE-ALPHA", "ALPHA", "BETA", "RC", "RELEASE"
const BUILD_TYPE: String = "dev" # "dev", "nightly", "public"

## Retorna a string semÃ¢ntica padrÃ£o com prefixo 'v' (ex: "v0.7.2-alpha")
static func get_version_string() -> String:
	var base: String = "v%d.%d.%d" % [MAJOR, MINOR, PATCH]
	if not STAGE.is_empty() and STAGE.to_upper() != "RELEASE":
		base += "-%s" % STAGE.to_lower()
	return base

## Retorna a versÃ£o crua sem prefixo 'v' para o project.godot (ex: "0.7.2-alpha")
static func get_raw_version() -> String:
	var base: String = "%d.%d.%d" % [MAJOR, MINOR, PATCH]
	if not STAGE.is_empty() and STAGE.to_upper() != "RELEASE":
		base += "-%s" % STAGE.to_lower()
	return base

## Retorna o nome completo com tÃ­tulo do jogo (ex: "Grass Cut Bot v0.7.2-alpha")
static func get_display_name() -> String:
	return "Grass Cut Bot %s" % get_version_string()

## Retorna um cÃ³digo numÃ©rico de versÃ£o para versionCode do Android (ex: 702 para 0.7.2)
static func get_version_code() -> int:
	return MAJOR * 10000 + MINOR * 100 + PATCH

## Retorna se a versÃ£o atual Ã© Pre-Alpha
static func is_pre_alpha() -> bool:
	return STAGE.to_upper() == "PRE-ALPHA"

## Retorna se a versÃ£o atual Ã© Alpha
static func is_alpha() -> bool:
	return STAGE.to_upper() == "ALPHA"

## Retorna se a versÃ£o atual Ã© Beta
static func is_beta() -> bool:
	return STAGE.to_upper() == "BETA"

## Retorna se a versÃ£o atual Ã© Release Candidate (Freeze)
static func is_rc() -> bool:
	return STAGE.to_upper() == "RC"

## Retorna se a versÃ£o atual Ã© de LanÃ§amento Comercial / Gold Master
static func is_release() -> bool:
	return STAGE.to_upper() == "RELEASE" or (MAJOR >= 1 and STAGE.is_empty())

## Retorna um dicionÃ¡rio estruturado com todos os metadados da versÃ£o
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
