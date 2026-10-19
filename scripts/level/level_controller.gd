extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

# Espaçamento canônico padrão de vegetação: elimina folga livre entre folhas adjacentes
const DEFAULT_VEGETATION_SPACING: float = 0.80

@export var grass_scene: PackedScene = preload("res://scenes/plants/grass_tuft.tscn")
@export var wheat_scene: PackedScene = preload("res://scenes/plants/wheat_tuft.tscn")
@export var flower_scene: PackedScene = preload("res://scenes/plants/flower_tuft.tscn")
@export var rock_scene: PackedScene = preload("res://scenes/obstacles/rock.tscn")

@onready var plants_container: Node3D = $PlantsContainer
@onready var obstacles_container: Node3D = $ObstaclesContainer
@onready var cutter: CharacterBody3D = $Cutter

var current_level_node: Node3D = null
@onready var default_terrain: Node3D = get_node_or_null("../Terrain") as Node3D

func _ready() -> void:
	generate_level(GameManager.current_level)

func generate_level(level_num: int) -> void:
	# Remove nível instanciado anterior se houver
	if current_level_node != null:
		current_level_node.queue_free()
		current_level_node = null

	# Limpa entidades anteriores se houver
	for child in plants_container.get_children():
		child.queue_free()
	for child in obstacles_container.get_children():
		child.queue_free()

	# Prioridade 1: Carrega arquivo de dados JSON da fase (gerado pelo Editor de Fases)
	var json_path: String = "res://data/levels/level_%02d.json" % level_num
	if FileAccess.file_exists(json_path):
		if _load_level_json(json_path, level_num):
			return

	# Prioridade 2: Tenta carregar a cena customizada do nível (ex: res://scenes/levels/level_01.tscn)
	var scene_path: String = "res://scenes/levels/level_%02d.tscn" % level_num
	if ResourceLoader.exists(scene_path):
		_load_level_scene(scene_path, level_num)
	else:
		# Fallback para geradores procedurais caso o nível ainda não possua JSON ou cena própria
		if default_terrain:
			default_terrain.visible = true
			default_terrain.process_mode = Node.PROCESS_MODE_INHERIT
		match level_num:
			1:
				_build_level_1_mvp()
			2:
				_build_level_2()
			3:
				_build_level_3()
			_:
				_build_procedural_level(level_num)

func _load_level_json(path: String, level_num: int) -> bool:
	var data: Dictionary = LevelJsonLoader.load_json_file(path)
	if data.is_empty():
		return false

	if default_terrain != null:
		default_terrain.visible = false
		default_terrain.process_mode = Node.PROCESS_MODE_DISABLED

	var lvl_root: Node3D = Node3D.new()
	lvl_root.name = "JsonLevel_%02d" % level_num
	add_child(lvl_root)
	current_level_node = lvl_root

	var water: Node3D = LevelJsonLoader.WATER_OCEAN_SCENE.instantiate() as Node3D
	if water != null:
		lvl_root.add_child(water)

	var grid_info: Dictionary = data.get("grid", {}) as Dictionary
	var width: int = int(grid_info.get("width", 12))
	var height: int = int(grid_info.get("height", 8))
	var cell_size: float = float(grid_info.get("cell_size", DEFAULT_VEGETATION_SPACING))
	var time_limit: float = float(data.get("time_limit", 90.0))

	var occupied_cells: Dictionary = {}
	var terrain_arr: Array = data.get("terrain", []) as Array
	for item in terrain_arr:
		if item is Dictionary:
			var td: Dictionary = item as Dictionary
			var gx: int = int(td.get("gx", 0))
			var gz: int = int(td.get("gz", 0))
			var t_id: String = String(td.get("tile_id", "island_center"))
			var t_rot: int = int(td.get("rot", 0))
			var cell: Vector2i = Vector2i(gx, gz)
			occupied_cells[cell] = { "tile_id": t_id, "rot": t_rot }
			var t_node: Node3D = LevelJsonLoader.instantiate_tile_node(t_id, t_rot)
			if t_node != null:
				t_node.position = LevelJsonLoader.grid_to_world(gx, gz, width, height, cell_size)
				lvl_root.add_child(t_node)

	var coastal_body: StaticBody3D = StaticBody3D.new()
	coastal_body.name = "CoastalLimits"
	coastal_body.collision_layer = 1
	coastal_body.collision_mask = 0
	lvl_root.add_child(coastal_body)
	LevelJsonLoader.build_coastal_colliders_and_foam(coastal_body, occupied_cells, width, height, cell_size)

	var goals: Dictionary = {}
	var objects_arr: Array = data.get("objects", []) as Array
	for item in objects_arr:
		if item is Dictionary:
			var od: Dictionary = item as Dictionary
			var gx: int = int(od.get("gx", 0))
			var gz: int = int(od.get("gz", 0))
			var o_type: String = String(od.get("type", ""))
			var o_rot: int = int(od.get("rot", 0))
			var inst: Node3D = LevelJsonLoader.instantiate_object_node(o_type, o_rot)
			if inst == null:
				continue
			inst.position = LevelJsonLoader.grid_to_world(gx, gz, width, height, cell_size)
			if o_type == "rock":
				obstacles_container.add_child(inst)
			else:
				plants_container.add_child(inst)
				if "plant_key" in inst:
					var p_key: String = String(inst.get("plant_key"))
					goals[p_key] = int(goals.get(p_key, 0)) + 1

	var spawn_dict: Dictionary = data.get("spawn", {}) as Dictionary
	var sp_x: int = int(spawn_dict.get("gx", int(float(width) / 2.0)))
	var sp_z: int = int(spawn_dict.get("gz", int(float(height) / 2.0)))
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_x, sp_z, width, height, cell_size)
	if cutter != null:
		cutter.position = Vector3(sp_world.x, 0.1, sp_world.z)

	if goals.is_empty():
		goals = { "grass": 1 }

	GameManager.start_level(level_num, goals, time_limit)
	return true

func _load_level_scene(path: String, level_num: int) -> void:
	var level_packed: PackedScene = load(path) as PackedScene
	if level_packed == null:
		return

	var lvl: Node3D = level_packed.instantiate() as Node3D
	add_child(lvl)
	current_level_node = lvl

	# Se o nível instanciado possui o próprio terreno, oculta/desativa o terreno de fallback da main
	if lvl.has_node("Terrain") and default_terrain != null:
		default_terrain.visible = false
		default_terrain.process_mode = Node.PROCESS_MODE_DISABLED

	# Posiciona o cortador no spawn do nível
	if cutter:
		if lvl.has_method("get_spawn_position"):
			cutter.position = lvl.get_spawn_position()
		else:
			cutter.position = Vector3(0.0, 0.1, 0.0)

	# Obtém as metas automaticamente através dos nós da cena
	var goals: Dictionary = {}
	var time_limit: float = 90.0

	if lvl.has_method("get_goals"):
		goals = lvl.get_goals()
	if "time_limit" in lvl:
		time_limit = float(lvl.time_limit)

	# Se nenhuma meta foi detectada, garante a meta básica
	if goals.is_empty():
		goals = { "grass": 56 }

	GameManager.start_level(level_num, goals, time_limit)


func _build_level_1_mvp() -> void:
	var width_count: int = 10
	var height_count: int = 6
	var spacing: float = DEFAULT_VEGETATION_SPACING
	var offset_x: float = -(float(width_count) * spacing) / 2.0 + (spacing / 2.0)
	var offset_z: float = -(float(height_count) * spacing) / 2.0 + (spacing / 2.0)

	var total_grass: int = 0
	for x in range(width_count):
		for z in range(height_count):
			var pos: Vector3 = Vector3(offset_x + float(x) * spacing, 0.0, offset_z + float(z) * spacing)
			if pos.length() < 0.7:
				continue
			var tuft: Node3D = grass_scene.instantiate() as Node3D
			tuft.position = pos
			plants_container.add_child(tuft)
			total_grass += 1

	if cutter:
		cutter.position = Vector3(0, 0.1, 0)

	var goals: Dictionary = { "grass": total_grass }
	GameManager.start_level(1, goals, 90.0)

func _build_level_2() -> void:
	var width_count: int = 11
	var height_count: int = 8
	var spacing: float = DEFAULT_VEGETATION_SPACING
	var offset_x: float = -(float(width_count) * spacing) / 2.0 + (spacing / 2.0)
	var offset_z: float = -(float(height_count) * spacing) / 2.0 + (spacing / 2.0)

	var rock_coords: Array[Vector2i] = [Vector2i(3, 2), Vector2i(7, 5), Vector2i(4, 6)]
	for rc in rock_coords:
		var r_pos: Vector3 = Vector3(offset_x + float(rc.x) * spacing, 0.0, offset_z + float(rc.y) * spacing)
		var rock: Node3D = rock_scene.instantiate() as Node3D
		rock.position = r_pos
		obstacles_container.add_child(rock)

	var grass_count: int = 0
	var wheat_count: int = 0

	for x in range(width_count):
		for z in range(height_count):
			var grid_coord: Vector2i = Vector2i(x, z)
			if grid_coord in rock_coords:
				continue
			var pos: Vector3 = Vector3(offset_x + float(x) * spacing, 0.0, offset_z + float(z) * spacing)
			if pos.length() < 0.7:
				continue

			if (x + z) % 4 == 0:
				var wheat: Node3D = wheat_scene.instantiate() as Node3D
				wheat.position = pos
				plants_container.add_child(wheat)
				wheat_count += 1
			else:
				var grass: Node3D = grass_scene.instantiate() as Node3D
				grass.position = pos
				plants_container.add_child(grass)
				grass_count += 1

	if cutter:
		cutter.position = Vector3(0, 0.1, 0)

	var goals: Dictionary = { "grass": grass_count, "wheat": wheat_count }
	GameManager.start_level(2, goals, 100.0)

func _build_level_3() -> void:
	var width_count: int = 12
	var height_count: int = 10
	var spacing: float = DEFAULT_VEGETATION_SPACING
	var offset_x: float = -(float(width_count) * spacing) / 2.0 + (spacing / 2.0)
	var offset_z: float = -(float(height_count) * spacing) / 2.0 + (spacing / 2.0)

	var rock_coords: Array[Vector2i] = [Vector2i(2, 2), Vector2i(9, 2), Vector2i(2, 7), Vector2i(9, 7), Vector2i(6, 4)]
	for rc in rock_coords:
		var r_pos: Vector3 = Vector3(offset_x + float(rc.x) * spacing, 0.0, offset_z + float(rc.y) * spacing)
		var rock: Node3D = rock_scene.instantiate() as Node3D
		rock.position = r_pos
		obstacles_container.add_child(rock)

	var grass_count: int = 0
	var wheat_count: int = 0
	var flower_count: int = 0

	for x in range(width_count):
		for z in range(height_count):
			var grid_coord: Vector2i = Vector2i(x, z)
			if grid_coord in rock_coords:
				continue
			var pos: Vector3 = Vector3(offset_x + float(x) * spacing, 0.0, offset_z + float(z) * spacing)
			if pos.length() < 0.7:
				continue

			var rnd: float = randf()
			if rnd < 0.15:
				var fl: Node3D = flower_scene.instantiate() as Node3D
				fl.position = pos
				plants_container.add_child(fl)
				flower_count += 1
			elif rnd < 0.35:
				var wh: Node3D = wheat_scene.instantiate() as Node3D
				wh.position = pos
				plants_container.add_child(wh)
				wheat_count += 1
			else:
				var gr: Node3D = grass_scene.instantiate() as Node3D
				gr.position = pos
				plants_container.add_child(gr)
				grass_count += 1

	if cutter:
		cutter.position = Vector3(0, 0.1, 0)

	var goals: Dictionary = { "grass": grass_count, "wheat": wheat_count, "flower": flower_count }
	GameManager.start_level(3, goals, 110.0)

func _build_procedural_level(level_num: int) -> void:
	var width_count: int = mini(14, 10 + int(float(level_num) / 2.0))
	var height_count: int = mini(12, 8 + int(float(level_num) / 2.0))
	var spacing: float = DEFAULT_VEGETATION_SPACING
	var offset_x: float = -(float(width_count) * spacing) / 2.0 + (spacing / 2.0)
	var offset_z: float = -(float(height_count) * spacing) / 2.0 + (spacing / 2.0)

	var goals: Dictionary = { "grass": 0, "wheat": 0, "flower": 0 }

	for x in range(width_count):
		for z in range(height_count):
			var pos: Vector3 = Vector3(offset_x + float(x) * spacing, 0.0, offset_z + float(z) * spacing)
			if pos.length() < 0.7:
				continue

			var rnd: float = randf()
			if rnd < 0.2:
				var fl: Node3D = flower_scene.instantiate() as Node3D
				fl.position = pos
				plants_container.add_child(fl)
				goals["flower"] = int(goals["flower"]) + 1
			elif rnd < 0.45:
				var wh: Node3D = wheat_scene.instantiate() as Node3D
				wh.position = pos
				plants_container.add_child(wh)
				goals["wheat"] = int(goals["wheat"]) + 1
			else:
				var gr: Node3D = grass_scene.instantiate() as Node3D
				gr.position = pos
				plants_container.add_child(gr)
				goals["grass"] = int(goals["grass"]) + 1

	if cutter:
		cutter.position = Vector3(0, 0.1, 0)

	GameManager.start_level(level_num, goals, 120.0)
