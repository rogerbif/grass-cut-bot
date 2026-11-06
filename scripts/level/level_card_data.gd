class_name LevelCardData
extends RefCounted

## Dados de exibição do Card de Fase (Home/Mapa): tempo, metas e bioma.
## As metas ficam gravadas em cada JSON de fase na chave "card_goals" (não afeta o gameplay,
## que continua calculando as metas reais em VegetationGrid.build_from_level_json).

const BIOME_NAME: String = "Ilha Tropical"
const LEVELS_DIR: String = "res://data/levels"

static var _cache: Dictionary = {}


## Calcula as metas finais exatamente como o gameplay (usado ao salvar/gerar JSON).
static func compute_goals(data: Dictionary) -> Dictionary:
	var vg_script: GDScript = load("res://scripts/plants/vegetation_grid.gd") as GDScript
	if vg_script == null:
		return {}
	var vg: Node3D = vg_script.new() as Node3D
	var goals: Dictionary = vg.call("build_from_level_json", data, null, null) as Dictionary
	vg.free()
	return goals


## Retorna { "time": float, "goals": Dictionary, "name": String } para a fase.
static func get_level_card_data(level_num: int) -> Dictionary:
	if _cache.has(level_num):
		return _cache[level_num] as Dictionary

	var result: Dictionary = { "time": 90.0, "goals": {}, "name": BIOME_NAME }
	var json_path: String = "%s/level_%02d.json" % [LEVELS_DIR, level_num]
	if FileAccess.file_exists(json_path):
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
		if parsed is Dictionary:
			var data: Dictionary = parsed as Dictionary
			result["time"] = float(data.get("time_limit", 90.0))
			var raw_goals: Variant = data.get("card_goals", data.get("goals", {}))
			if raw_goals is Dictionary:
				var goals_out: Dictionary = {}
				for k: Variant in (raw_goals as Dictionary).keys():
					goals_out[String(k)] = int((raw_goals as Dictionary)[k])
				result["goals"] = goals_out
	_cache[level_num] = result
	return result


static func clear_cache() -> void:
	_cache.clear()


static func format_time(seconds: float) -> String:
	var total: int = int(ceilf(seconds))
	return "%d:%02d" % [int(floor(float(total) / 60.0)), total % 60]
