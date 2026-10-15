extends Node3D

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
	# Remove nivel instanciado anterior se houver
	if current_level_node != null:
		current_level_node.queue_free()
		current_level_node = null

	# Limpa entidades anteriores se houver
	for child in plants_container.get_children():
		child.queue_free()
	for child in obstacles_container.get_children():
		child.queue_free()

	# Tenta carregar a cena customizada do nível (ex: res://scenes/levels/level_01.tscn)
	var scene_path: String = "res://scenes/levels/level_%02d.tscn" % level_num
	if ResourceLoader.exists(scene_path):
		_load_level_scene(scene_path, level_num)
	else:
		# Fallback para geradores procedurais caso o nível ainda não possua cena própria
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
	# Fase 1 (MVP de Validação do GDD):
	# Área retangular compacta coberta por grama verde básica
	# Meta: 60 tufos de grama verde, cronômetro de 90 segundos (1:30)
	# Sem obstáculos internos
	var width_count: int = 10
	var height_count: int = 6
	var spacing: float = DEFAULT_VEGETATION_SPACING
	var offset_x: float = -(float(width_count) * spacing) / 2.0 + (spacing / 2.0)
	var offset_z: float = -(float(height_count) * spacing) / 2.0 + (spacing / 2.0)

	var total_grass: int = 0
	for x in range(width_count):
		for z in range(height_count):
			var pos = Vector3(offset_x + x * spacing, 0.0, offset_z + z * spacing)
			# Deixa o centro inicial livre para o cortador começar suave
			if pos.length() < 0.7:
				continue
			var tuft = grass_scene.instantiate()
			tuft.position = pos
			plants_container.add_child(tuft)
			total_grass += 1

	if cutter:
		cutter.position = Vector3(0, 0.1, 0)

	# Inicia no GameManager com a meta exata de grama
	var goals = { "grass": total_grass }
	GameManager.start_level(1, goals, 90.0)

func _build_level_2() -> void:
	# Fase 2: Introdução de Trigo e Rochas
	var width_count: int = 11
	var height_count: int = 8
	var spacing: float = DEFAULT_VEGETATION_SPACING
	var offset_x: float = -(float(width_count) * spacing) / 2.0 + (spacing / 2.0)
	var offset_z: float = -(float(height_count) * spacing) / 2.0 + (spacing / 2.0)

	# Adiciona algumas rochas de obstáculo
	var rock_coords: Array[Vector2i] = [Vector2i(3, 2), Vector2i(7, 5), Vector2i(4, 6)]
	for rc in rock_coords:
		var r_pos = Vector3(offset_x + float(rc.x) * spacing, 0.0, offset_z + float(rc.y) * spacing)
		var rock = rock_scene.instantiate()
		rock.position = r_pos
		obstacles_container.add_child(rock)

	var grass_count: int = 0
	var wheat_count: int = 0

	for x in range(width_count):
		for z in range(height_count):
			var grid_coord = Vector2i(x, z)
			if grid_coord in rock_coords:
				continue
			var pos = Vector3(offset_x + float(x) * spacing, 0.0, offset_z + float(z) * spacing)
			if pos.length() < 0.7:
				continue

			if (x + z) % 4 == 0:
				var wheat = wheat_scene.instantiate()
				wheat.position = pos
				plants_container.add_child(wheat)
				wheat_count += 1
			else:
				var grass = grass_scene.instantiate()
				grass.position = pos
				plants_container.add_child(grass)
				grass_count += 1

	if cutter:
		cutter.position = Vector3(0, 0.1, 0)

	var goals: Dictionary = { "grass": grass_count, "wheat": wheat_count }
	GameManager.start_level(2, goals, 100.0)

func _build_level_3() -> void:
	# Fase 3: Introdução de Flores e mais obstáculos
	var width_count: int = 12
	var height_count: int = 10
	var spacing: float = DEFAULT_VEGETATION_SPACING
	var offset_x: float = -(float(width_count) * spacing) / 2.0 + (spacing / 2.0)
	var offset_z: float = -(float(height_count) * spacing) / 2.0 + (spacing / 2.0)

	var rock_coords: Array[Vector2i] = [Vector2i(2, 2), Vector2i(9, 2), Vector2i(2, 7), Vector2i(9, 7), Vector2i(6, 4)]
	for rc in rock_coords:
		var r_pos = Vector3(offset_x + float(rc.x) * spacing, 0.0, offset_z + float(rc.y) * spacing)
		var rock = rock_scene.instantiate()
		rock.position = r_pos
		obstacles_container.add_child(rock)

	var grass_count: int = 0
	var wheat_count: int = 0
	var flower_count: int = 0

	for x in range(width_count):
		for z in range(height_count):
			var grid_coord = Vector2i(x, z)
			if grid_coord in rock_coords:
				continue
			var pos = Vector3(offset_x + x * spacing, 0.0, offset_z + z * spacing)
			if pos.length() < 0.7:
				continue

			var rnd = randf()
			if rnd < 0.15:
				var fl = flower_scene.instantiate()
				fl.position = pos
				plants_container.add_child(fl)
				flower_count += 1
			elif rnd < 0.35:
				var wh = wheat_scene.instantiate()
				wh.position = pos
				plants_container.add_child(wh)
				wheat_count += 1
			else:
				var gr = grass_scene.instantiate()
				gr.position = pos
				plants_container.add_child(gr)
				grass_count += 1

	if cutter:
		cutter.position = Vector3(0, 0.1, 0)

	var goals = { "grass": grass_count, "wheat": wheat_count, "flower": flower_count }
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
			var pos = Vector3(offset_x + x * spacing, 0.0, offset_z + z * spacing)
			if pos.length() < 0.7:
				continue

			var rnd = randf()
			if rnd < 0.2:
				var fl = flower_scene.instantiate()
				fl.position = pos
				plants_container.add_child(fl)
				goals["flower"] += 1
			elif rnd < 0.45:
				var wh = wheat_scene.instantiate()
				wh.position = pos
				plants_container.add_child(wh)
				goals["wheat"] += 1
			else:
				var gr = grass_scene.instantiate()
				gr.position = pos
				plants_container.add_child(gr)
				goals["grass"] += 1

	if cutter:
		cutter.position = Vector3(0, 0.1, 0)

	GameManager.start_level(level_num, goals, 120.0)
