extends RefCounted

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const IslandMeshBuilder = preload("res://scripts/level/island_mesh_builder.gd")
const LevelCardDataScript = preload("res://scripts/level/level_card_data.gd")

const LEVELS_JSON_DIR: String = "res://data/levels"
const LEVELS_TSCN_DIR: String = "res://scenes/levels"
const CELL_SIZE: float = 0.40


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
	veg_field: RefCounted = null,
	vector_field: RefCounted = null,
	custom_goals: Dictionary = {},
	cell_size: float = CELL_SIZE,
	vector_terrain: RefCounted = null
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
		# Em v2/v3, rochas, flores e trigos ficam em objects (discretos por tile de 0.80m)
		if obj_type.begins_with("rock") or obj_type.begins_with("flower") or obj_type == "wheat":
			objects_list.append({
				"gx": cell.x,
				"gz": cell.y,
				"type": obj_type,
				"rot": int(entry.get("rot", 0))
			})

	# Preservação defensiva: se vector_field for nulo, tenta preservar grass_vectors do arquivo existente
	var existing_grass_vectors: Array = []
	var path: String = get_json_path(level_id)
	if vector_field == null and FileAccess.file_exists(path):
		var prev_content: String = FileAccess.get_file_as_string(path)
		var parsed: Variant = JSON.parse_string(prev_content)
		if parsed is Dictionary and (parsed as Dictionary).has("grass_vectors"):
			existing_grass_vectors = (parsed as Dictionary)["grass_vectors"] as Array

	var has_vector_data: bool = (vector_field != null and vector_field.has_method("to_dict_list")) or not existing_grass_vectors.is_empty()

	# Gera e salva os polígonos contínuos da ilha para o formato vetorial v4/v5
	var island_polys_data: Array = []
	var island_holes_data: Array = []

	if vector_terrain != null and vector_terrain.has_method("to_dict"):
		var vt_dict: Dictionary = vector_terrain.call("to_dict") as Dictionary
		island_polys_data = vt_dict.get("island_polygons", []) as Array
		island_holes_data = vt_dict.get("island_holes", []) as Array
	elif not terrain_list.is_empty():
		var island_polys: Array[PackedVector2Array] = IslandMeshBuilder.convert_tile_grid_to_polygons(
			terrain_list, grid_width, grid_height, cell_size
		)
		for p: PackedVector2Array in island_polys:
			var pts: Array = []
			for pt: Vector2 in p:
				pts.append([snappedf(pt.x, 0.001), snappedf(pt.y, 0.001)])
			island_polys_data.append(pts)

	# Se terrain_list estiver vazia mas houver terreno vetorial, gera rasterização de segurança
	if terrain_list.is_empty() and vector_terrain != null and vector_terrain.has_method("is_point_on_land"):
		var offset_x: float = -(float(grid_width) * cell_size) / 2.0 + (cell_size / 2.0)
		var offset_z: float = -(float(grid_height) * cell_size) / 2.0 + (cell_size / 2.0)
		for gz in range(grid_height):
			for gx in range(grid_width):
				var pt: Vector2 = Vector2(offset_x + float(gx) * cell_size, offset_z + float(gz) * cell_size)
				if vector_terrain.call("is_point_on_land", pt):
					terrain_list.append({
						"gx": gx,
						"gz": gz,
						"tile_id": "island_center",
						"rot": 0,
						"auto": true
					})

	var version_num: int = 5 if (has_vector_data or not island_polys_data.is_empty() or not island_holes_data.is_empty()) else 2

	var payload: Dictionary = {
		"version": version_num,
		"level_id": level_id,
		"name": level_name,
		"time_limit": time_limit,
		"grid": {
			"cell_size": cell_size,
			"width": grid_width,
			"height": grid_height
		},
		"spawn": {
			"gx": spawn_cell.x,
			"gz": spawn_cell.y,
			"rot": spawn_rot
		},
		"terrain": terrain_list,
		"island_polygons": island_polys_data,
		"island_holes": island_holes_data,
		"objects": objects_list
	}

	if not custom_goals.is_empty():
		payload["goals"] = custom_goals

	if vector_field != null and vector_field.has_method("to_dict_list"):
		payload["grass_vectors"] = vector_field.call("to_dict_list")
	elif not existing_grass_vectors.is_empty():
		payload["grass_vectors"] = existing_grass_vectors
	elif veg_field != null and veg_field.has_method("to_rows"):
		payload["vegetation"] = {
			"res": 0.20,
			"rows": veg_field.call("to_rows")
		}

	# Grava as metas finais (idênticas ao gameplay) para o Card de Fase do menu (Home/Mapa)
	if not custom_goals.is_empty():
		payload["card_goals"] = custom_goals.duplicate(true)
	else:
		payload["card_goals"] = LevelCardDataScript.compute_goals(payload)
	LevelCardDataScript.clear_cache()

	var json_str: String = JSON.stringify(payload, "\t")
	if json_str.length() < 20:
		push_error("Erro crítico: payload JSON inválido ou vazio para a Fase %02d" % level_id)
		return false

	# 1. Se o arquivo já existir, grava cópia de segurança em user://editor_backups/
	if FileAccess.file_exists(path):
		var prev_str: String = FileAccess.get_file_as_string(path)
		if prev_str.length() > 20:
			var bak_dir: String = "user://editor_backups"
			if not DirAccess.dir_exists_absolute(bak_dir):
				DirAccess.make_dir_recursive_absolute(bak_dir)
			var bak_path: String = "%s/level_%02d_bak.json" % [bak_dir, level_id]
			var bak_file: FileAccess = FileAccess.open(bak_path, FileAccess.WRITE)
			if bak_file != null:
				bak_file.store_string(prev_str)
				bak_file.flush()
				bak_file.close()

	# 2. Gravação Atômica via arquivo temporário (.tmp)
	var global_target: String = ProjectSettings.globalize_path(path)
	var global_tmp: String = global_target + ".tmp"
	var tmp_file: FileAccess = FileAccess.open(global_tmp, FileAccess.WRITE)
	if tmp_file != null:
		tmp_file.store_string(json_str)
		tmp_file.flush()
		tmp_file.close()
		var verify_str: String = FileAccess.get_file_as_string(global_tmp)
		if verify_str.length() >= json_str.length():
			var final_f: FileAccess = FileAccess.open(global_target, FileAccess.WRITE)
			if final_f != null:
				final_f.store_string(json_str)
				final_f.flush()
				final_f.close()
				DirAccess.remove_absolute(global_tmp)
				return true
		DirAccess.remove_absolute(global_tmp)

	# Fallback direto caso o sistema de arquivos virtual bloqueie o .tmp
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		file = FileAccess.open(global_target, FileAccess.WRITE)
	if file == null:
		push_error("Erro crítico ao gravar JSON de nível: %s (err: %d)" % [path, FileAccess.get_open_error()])
		return false
	file.store_string(json_str)
	file.flush()
	file.close()
	return true


static func save_autosave_snapshot(
	level_id: int,
	time_limit: float,
	grid_width: int,
	grid_height: int,
	spawn_cell: Vector2i,
	spawn_rot: int,
	object_grid: Dictionary,
	vector_field: RefCounted = null,
	custom_goals: Dictionary = {},
	cell_size: float = CELL_SIZE,
	vector_terrain: RefCounted = null
) -> bool:
	var vt_dict: Dictionary = vector_terrain.call("to_dict") if (vector_terrain != null and vector_terrain.has_method("to_dict")) else {}
	var objects_list: Array[Dictionary] = []
	for k: Variant in object_grid.keys():
		var c: Vector2i = k as Vector2i
		var entry: Dictionary = object_grid[c] as Dictionary
		objects_list.append({
			"gx": c.x,
			"gz": c.y,
			"type": String(entry.get("type", "")),
			"rot": int(entry.get("rot", 0))
		})
	var snap: Dictionary = {
		"version": 5,
		"level_id": level_id,
		"timestamp": int(Time.get_unix_time_from_system()),
		"time_limit": time_limit,
		"grid": { "cell_size": cell_size, "width": grid_width, "height": grid_height },
		"spawn": { "gx": spawn_cell.x, "gz": spawn_cell.y, "rot": spawn_rot },
		"island_polygons": vt_dict.get("island_polygons", []),
		"island_holes": vt_dict.get("island_holes", []),
		"objects": objects_list,
		"grass_vectors": vector_field.call("to_dict_list") if (vector_field != null and vector_field.has_method("to_dict_list")) else [],
		"goals": custom_goals
	}
	var f: FileAccess = FileAccess.open("user://editor_autosave.json", FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(snap, "\t"))
	f.flush()
	f.close()
	return true


static func list_existing_levels() -> Array[int]:
	var found: Array[int] = []
	for i: int in range(1, 101):
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
	veg_field: RefCounted = null,
	vector_field: RefCounted = null,
	custom_goals: Dictionary = {},
	cell_size: float = CELL_SIZE,
	vector_terrain: RefCounted = null
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
		veg_field,
		vector_field,
		custom_goals,
		cell_size,
		vector_terrain
	)
