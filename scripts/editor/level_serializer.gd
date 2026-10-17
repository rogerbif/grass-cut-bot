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
	object_grid: Dictionary
) -> bool:
	var global_dir: String = ProjectSettings.globalize_path(LEVELS_JSON_DIR)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	var terrain_list: Array[Dictionary] = []
	var sorted_terrain_keys: Array = terrain_grid.keys()
	sorted_terrain_keys.sort()

	for k in sorted_terrain_keys:
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

	for k in sorted_obj_keys:
		var cell: Vector2i = k as Vector2i
		var entry: Dictionary = object_grid[cell] as Dictionary
		var obj_type: String = String(entry.get("type", ""))
		if obj_type == "" or obj_type == "cutter_spawn":
			continue
		objects_list.append({
			"gx": cell.x,
			"gz": cell.y,
			"type": obj_type,
			"rot": int(entry.get("rot", 0))
		})

	var payload: Dictionary = {
		"version": 1,
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
	for i in range(1, 51):
		if FileAccess.file_exists(get_json_path(i)) or ResourceLoader.exists(get_tscn_path(i)):
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
	object_grid: Dictionary
) -> bool:
	var global_dir: String = ProjectSettings.globalize_path(LEVELS_TSCN_DIR)
	if not DirAccess.dir_exists_absolute(global_dir):
		DirAccess.make_dir_recursive_absolute(global_dir)

	var root: Node3D = Node3D.new()
	root.name = "Level%02d" % level_id
	var base_script: Script = load("res://scripts/level/base_level.gd") as Script
	if base_script != null:
		root.set_script(base_script)
		root.set("level_number", level_id)
		root.set("time_limit", time_limit)

	var terrain_holder: Node3D = Node3D.new()
	terrain_holder.name = "Terrain"
	root.add_child(terrain_holder)
	terrain_holder.owner = root

	var water: Node3D = LevelJsonLoader.WATER_OCEAN_SCENE.instantiate() as Node3D
	if water != null:
		water.name = "WaterOcean"
		terrain_holder.add_child(water)
		water.owner = root

	var tiles_container: Node3D = Node3D.new()
	tiles_container.name = "IslandTiles"
	terrain_holder.add_child(tiles_container)
	tiles_container.owner = root

	var idx_tile: int = 1
	for cell_key in terrain_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var t_data: Dictionary = terrain_grid[cell] as Dictionary
		var t_id: String = String(t_data.get("tile_id", "island_center"))
		var t_rot: int = int(t_data.get("rot", 0))
		var t_node: Node3D = LevelJsonLoader.instantiate_tile_node(t_id, t_rot)
		if t_node != null:
			t_node.name = "Tile_%03d" % idx_tile
			idx_tile += 1
			t_node.position = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
			tiles_container.add_child(t_node)
			t_node.owner = root

	var coastal_body: StaticBody3D = StaticBody3D.new()
	coastal_body.name = "CoastalLimits"
	coastal_body.collision_layer = 1
	coastal_body.collision_mask = 0
	terrain_holder.add_child(coastal_body)
	coastal_body.owner = root

	LevelJsonLoader.build_coastal_colliders_and_foam(coastal_body, terrain_grid, grid_width, grid_height, CELL_SIZE)
	for child in coastal_body.get_children():
		child.owner = root

	var spawn_marker: Marker3D = Marker3D.new()
	spawn_marker.name = "CutterSpawn"
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, grid_width, grid_height, CELL_SIZE)
	spawn_marker.position = Vector3(sp_world.x, 0.1, sp_world.z)
	spawn_marker.rotation_degrees.y = float(spawn_rot)
	root.add_child(spawn_marker)
	spawn_marker.owner = root

	var obstacles_node: Node3D = Node3D.new()
	obstacles_node.name = "Obstacles"
	root.add_child(obstacles_node)
	obstacles_node.owner = root

	var plants_node: Node3D = Node3D.new()
	plants_node.name = "Plants"
	root.add_child(plants_node)
	plants_node.owner = root

	var idx_plant: int = 1
	var idx_rock: int = 1
	for cell_key in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var o_data: Dictionary = object_grid[cell] as Dictionary
		var o_type: String = String(o_data.get("type", ""))
		var o_rot: int = int(o_data.get("rot", 0))
		if o_type == "" or o_type == "cutter_spawn":
			continue
		var inst: Node3D = LevelJsonLoader.instantiate_object_node(o_type, o_rot)
		if inst == null:
			continue
		inst.position = LevelJsonLoader.grid_to_world(cell.x, cell.y, grid_width, grid_height, CELL_SIZE)
		if o_type == "rock":
			inst.name = "Rock_%02d" % idx_rock
			idx_rock += 1
			obstacles_node.add_child(inst)
			inst.owner = root
		else:
			inst.name = "Plant_%03d" % idx_plant
			idx_plant += 1
			plants_node.add_child(inst)
			inst.owner = root

	var packed: PackedScene = PackedScene.new()
	var err: Error = packed.pack(root)
	root.free()
	if err != OK:
		return false

	var save_err: Error = ResourceSaver.save(packed, get_tscn_path(level_id))
	return save_err == OK
