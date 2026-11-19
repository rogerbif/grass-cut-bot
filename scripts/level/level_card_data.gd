class_name LevelCardData
extends RefCounted

## Dados de exibição do Card de Fase (Home/Mapa): tempo, metas e bioma.
## As metas ficam gravadas em cada JSON de fase na chave "card_goals" (não afeta o gameplay,
## que continua calculando as metas reais em VegetationGrid.build_from_level_json).

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

const BIOME_NAME: String = "Ilha Tropical"
const LEVELS_DIR: String = "res://data/levels"

static var _cache: Dictionary = {}
static var _json_cache: Dictionary = {}
static var _meta_cache: Dictionary = {}


## Lê e faz parse de level_XX.json uma única vez por sessão, mantendo cache estático em memória.
static func get_cached_level_json(level_num: int) -> Dictionary:
	if _json_cache.has(level_num):
		return _json_cache[level_num] as Dictionary

	var json_path: String = "%s/level_%02d.json" % [LEVELS_DIR, level_num]
	var data: Dictionary = LevelJsonLoader.load_json_file(json_path)
	_json_cache[level_num] = data
	return data


## Retorna metadados geométricos em O(1) para dimensionamento e posicionamento das ilhas no menu.
static func get_cached_island_meta(level_num: int) -> Dictionary:
	if _meta_cache.has(level_num):
		return _meta_cache[level_num] as Dictionary

	var data: Dictionary = get_cached_level_json(level_num)
	if data.is_empty():
		var empty_meta: Dictionary = { "valid": false }
		_meta_cache[level_num] = empty_meta
		return empty_meta

	var grid_info: Dictionary = data.get("grid", {}) as Dictionary
	var width: int = int(grid_info.get("width", 12))
	var height: int = int(grid_info.get("height", 8))
	var cell_size: float = float(grid_info.get("cell_size", 0.8))
	var dims: Vector2 = Vector2(float(width) * cell_size, float(height) * cell_size)
	var has_spawn: bool = data.has("spawn") and data["spawn"] is Dictionary
	var bot_pos: Vector3 = Vector3.ZERO
	if has_spawn:
		var sp_dict: Dictionary = data["spawn"] as Dictionary
		var sp_x: int = int(sp_dict.get("gx", int(float(width) / 2.0)))
		var sp_z: int = int(sp_dict.get("gz", int(float(height) / 2.0)))
		var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_x, sp_z, width, height, cell_size)
		bot_pos = Vector3(sp_world.x, -0.052, sp_world.z)

	var meta: Dictionary = {
		"valid": true,
		"dimensions": dims,
		"has_spawn": has_spawn,
		"bot_pos": bot_pos
	}
	_meta_cache[level_num] = meta
	return meta


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
	var data: Dictionary = get_cached_level_json(level_num)
	if not data.is_empty():
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
	_json_cache.clear()
	_meta_cache.clear()


static func format_time(seconds: float) -> String:
	var total: int = int(ceilf(seconds))
	return "%d:%02d" % [int(floor(float(total) / 60.0)), total % 60]
