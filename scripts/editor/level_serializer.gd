extends RefCounted

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

const LEVELS_JSON_DIR: String = "res://data/levels"
const LEVELS_TSCN_DIR: String = "res://scenes/levels"
const CELL_SIZE: float = 0.80


static func get_json_path(level_id: int) -> String:
	return "%s/level_%02d.json" % [LEVELS_JSON_DIR, level_id]


static func get_tscn_path(level_id: int) -> String:
	return "%s/level_%02d.tscn" % [LEVELS_TSCN_DIR, level_id]


static func save_level_json(
	level_id: int,
	level_name: String,
	time_limit: float,
	grid_width: int,
	grid_height: int,
	spawn_cell: Vector2i,
	spawn_rot: int,
	terrain_grid: Dictionary,
	object_grid: Dictionary,
	veg_field: RefCounted = null
) -> bool:
	var global_dir: String = ProjectSettings.globalize_path(LEVELS_JSON_DIR)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	var terrain_list: Array[Dictionary] = []
	var sorted_terrain_keys: Array = terrain_grid.keys()
	sorted_terrain_keys.sort()

	for k: Variant in sorted_terrain_keys:
		var cell: Vector2i = k as Vector2i
		var entry: Dictionary = terrain_grid[cell] as Dictionary
		terrain_list.append({
			"gx": cell.x,
			"gz": cell.y,
			"tile_id": String(entry.get("tile_id", "island_center")),
			"rot": int(entry.get("rot", 0)),
			"auto": bool(entry.get("auto", true))
		})

	var objects_list: Array[Dictionary] = []
	var sorted_obj_keys: Array = object_grid.keys()
	sorted_obj_keys.sort()

	for k: Variant in sorted_obj_keys:
		var cell: Vector2i = k as Vector2i
		var entry: Dictionary = object_grid[cell] as Dictionary
		var obj_type: String = String(entry.get("type", ""))
		# Em v2, rochas e flores ficam em objects (discretos por tile de 0.80m)
		if obj_type == "rock" or obj_type == "flower":
			objects_list.append({
				"gx": cell.x,
				"gz": cell.y,
				"type": obj_type,
				"rot": int(entry.get("rot", 0))
			})

	var payload: Dictionary = {
		"version": 2,
		"level_id": level_id,
		"name": level_name,
		"time_limit": time_limit,
		"grid": {
			"cell_size": CELL_SIZE,
			"width": grid_width,
			"height": grid_height
		},
		"spawn": {
			"gx": spawn_cell.x,
			"gz": spawn_cell.y,
			"rot": spawn_rot
		},
		"terrain": terrain_list,
		"objects": objects_list
	}

	if veg_field != null and veg_field.has_method("to_rows"):
		payload["vegetation"] = {
			"res": 0.20,
			"rows": veg_field.call("to_rows")
		}

	var json_str: String = JSON.stringify(payload, "\t")
	var path: String = get_json_path(level_id)
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(json_str)
	file.close()
	return true


static func list_existing_levels() -> Array[int]:
	var found: Array[int] = []
	for i: int in range(1, 51):
		if FileAccess.file_exists(get_json_path(i)):
			found.append(i)
	if found.is_empty():
		found.append(1)
	return found


static func bake_to_tscn(
	level_id: int,
	time_limit: float,
	grid_width: int,
	grid_height: int,
	spawn_cell: Vector2i,
	spawn_rot: int,
	terrain_grid: Dictionary,
	object_grid: Dictionary,
	veg_field: RefCounted = null
) -> bool:
	return save_level_json(
		level_id,
		"Fase %02d" % level_id,
		time_limit,
		grid_width,
		grid_height,
		spawn_cell,
		spawn_rot,
		terrain_grid,
		object_grid,
		veg_field
	)
