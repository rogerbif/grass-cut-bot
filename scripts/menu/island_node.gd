extends Node3D

signal island_selected(level_number: int)

const TILE_MODELS: Dictionary = {
	"island_center": preload("res://assets/models/tiles/tile_island_center.glb"),
	"island_edge": preload("res://assets/models/tiles/tile_island_edge.glb"),
	"island_corner_out": preload("res://assets/models/tiles/tile_island_corner_out.glb"),
	"island_corner_in": preload("res://assets/models/tiles/tile_island_corner_in.glb"),
	"island_dirt": preload("res://assets/models/tiles/tile_island_dirt.glb"),
	"island_end": preload("res://assets/models/tiles/tile_island_end.glb")
}

const GRASS_MODEL: PackedScene = preload("res://assets/models/grass_01.glb")
const ROCK_MODEL: PackedScene = preload("res://assets/models/rock.glb")
const WHEAT_SCENE: PackedScene = preload("res://scenes/plants/wheat_tuft.tscn")
const FLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_tuft.tscn")

# Shaders oficiais da grama com gradiente vertical (raiz -> topo) e balanço de vento
const MAT_ACTIVE_GRASS_GREEN: ShaderMaterial = preload("res://shaders/interactive_grass_material.tres")
const MAT_ACTIVE_GRASS_YELLOW: ShaderMaterial = preload("res://shaders/interactive_grass_yellow_material.tres")
const MAT_ACTIVE_GRASS_BLUE: ShaderMaterial = preload("res://shaders/interactive_grass_blue_material.tres")
const MAT_ACTIVE_GRASS_PURPLE: ShaderMaterial = preload("res://shaders/interactive_grass_purple_material.tres")

static var _mat_static_green: ShaderMaterial = null
static var _mat_static_yellow: ShaderMaterial = null
static var _mat_static_blue: ShaderMaterial = null
static var _mat_static_purple: ShaderMaterial = null
static var _mat_rock: StandardMaterial3D = null

@export var level_number: int = 1
@export var is_unlocked: bool = true
@export var stars_earned: int = 0 # 0 a 3

@onready var bot_anchor: Marker3D = $BotAnchor
@onready var fallback_mesh: Node3D = $FallbackMesh
@onready var miniature_container: Node3D = $MiniatureContainer
@onready var plaque_root: Node3D = $Plaque
@onready var plaque_board: MeshInstance3D = $Plaque/BoardMesh
@onready var plaque_post: MeshInstance3D = $Plaque/PostMesh
@onready var level_label: Label3D = $Plaque/LevelLabel
@onready var stars_label: Label3D = $Plaque/StarsLabel
@onready var click_area: Area3D = $ClickArea

var is_map_mode: bool = true
var is_active_island: bool = false
var island_dimensions: Vector2 = Vector2(12.0, 10.0)
var map_plaque_pos: Vector3 = Vector3(4.5, 0.25, 3.5)
var plaque_tween: Tween = null
var grass_mesh_records: Array[Dictionary] = []

func _ready() -> void:
	update_visuals()

func setup_island(lvl: int, unlocked: bool, stars: int) -> void:
	level_number = lvl
	is_unlocked = unlocked
	stars_earned = stars
	build_miniature_from_json(lvl)
	update_visuals()
	set_view_mode(is_map_mode, is_active_island, false)

static func _init_materials() -> void:
	if _mat_static_green == null:
		# Duplica os shaders e zera o vento para as ilhas de fundo / visão mapa (máxima performance mobile)
		_mat_static_green = MAT_ACTIVE_GRASS_GREEN.duplicate() as ShaderMaterial
		_mat_static_green.set_shader_parameter("wind_strength", 0.0)

		_mat_static_yellow = MAT_ACTIVE_GRASS_YELLOW.duplicate() as ShaderMaterial
		_mat_static_yellow.set_shader_parameter("wind_strength", 0.0)

		_mat_static_blue = MAT_ACTIVE_GRASS_BLUE.duplicate() as ShaderMaterial
		_mat_static_blue.set_shader_parameter("wind_strength", 0.0)

		_mat_static_purple = MAT_ACTIVE_GRASS_PURPLE.duplicate() as ShaderMaterial
		_mat_static_purple.set_shader_parameter("wind_strength", 0.0)

		_mat_rock = StandardMaterial3D.new()
		_mat_rock.albedo_color = Color(0.42, 0.46, 0.50, 1.0)
		_mat_rock.roughness = 0.95

static func _clear_node_owners(node: Node) -> void:
	node.owner = null
	for c in node.get_children():
		_clear_node_owners(c)

static func _strip_visual_mesh(inst: Node3D) -> Node3D:
	var visual: Node3D = inst.get_node_or_null("VisualMesh") as Node3D
	if visual != null:
		inst.remove_child(visual)
		_clear_node_owners(visual)
		inst.queue_free()
		return visual
	_clear_node_owners(inst)
	return inst

static func create_miniature_object(otype: String) -> Node3D:
	_init_materials()
	if otype == "rock":
		var r_inst: Node3D = ROCK_MODEL.instantiate() as Node3D
		for child in r_inst.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).material_override = _mat_rock
		return r_inst

	elif otype == "wheat":
		var w_inst: Node3D = WHEAT_SCENE.instantiate() as Node3D
		return _strip_visual_mesh(w_inst)

	elif otype == "flower":
		var f_inst: Node3D = FLOWER_SCENE.instantiate() as Node3D
		return _strip_visual_mesh(f_inst)

	else:
		# grass_green, grass_yellow, grass_blue, grass_purple (ou fallback)
		var g_inst: Node3D = GRASS_MODEL.instantiate() as Node3D
		var target_mat: ShaderMaterial = _mat_static_green
		if otype == "grass_yellow":
			target_mat = _mat_static_yellow
		elif otype == "grass_blue":
			target_mat = _mat_static_blue
		elif otype == "grass_purple":
			target_mat = _mat_static_purple

		for child in g_inst.get_children():
			if child is MeshInstance3D:
				(child as MeshInstance3D).material_override = target_mat
		return g_inst

func set_grass_animated(enabled: bool) -> void:
	_init_materials()
	for rec in grass_mesh_records:
		var mi: MeshInstance3D = rec.get("mesh", null) as MeshInstance3D
		if mi == null or not is_instance_valid(mi):
			continue
		var gtype: String = String(rec.get("type", "grass_green"))
		if enabled:
			match gtype:
				"grass_yellow":
					mi.material_override = MAT_ACTIVE_GRASS_YELLOW
				"grass_blue":
					mi.material_override = MAT_ACTIVE_GRASS_BLUE
				"grass_purple":
					mi.material_override = MAT_ACTIVE_GRASS_PURPLE
				_:
					mi.material_override = MAT_ACTIVE_GRASS_GREEN
		else:
			match gtype:
				"grass_yellow":
					mi.material_override = _mat_static_yellow
				"grass_blue":
					mi.material_override = _mat_static_blue
				"grass_purple":
					mi.material_override = _mat_static_purple
				_:
					mi.material_override = _mat_static_green

func build_miniature_from_json(lvl: int) -> void:
	if miniature_container == null:
		return

	# Limpa tiles anteriores da miniatura e registros de grama
	for c in miniature_container.get_children():
		c.queue_free()
	grass_mesh_records.clear()

	var json_path: String = "res://data/levels/level_%02d.json" % lvl
	if not FileAccess.file_exists(json_path):
		if fallback_mesh != null:
			fallback_mesh.visible = true
		return

	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		if fallback_mesh != null:
			fallback_mesh.visible = true
		return

	var text: String = file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(text)
	if not (parsed is Dictionary):
		if fallback_mesh != null:
			fallback_mesh.visible = true
		return

	var data: Dictionary = parsed as Dictionary
	var grid_info: Dictionary = data.get("grid", {}) as Dictionary
	var width: int = int(grid_info.get("width", 12))
	var height: int = int(grid_info.get("height", 8))
	var cell_size: float = float(grid_info.get("cell_size", 0.8))

	var offset_x: float = -(float(width) * cell_size) / 2.0 + (cell_size / 2.0)
	var offset_z: float = -(float(height) * cell_size) / 2.0 + (cell_size / 2.0)

	var terrain_arr: Array = data.get("terrain", []) as Array
	if terrain_arr.is_empty():
		if fallback_mesh != null:
			fallback_mesh.visible = true
		return

	# Oculta o bloco de fallback e constrói a miniatura
	if fallback_mesh != null:
		fallback_mesh.visible = false

	# Escala real 1.0x (idêntica ao gameplay)
	miniature_container.scale = Vector3(1.0, 1.0, 1.0)
	island_dimensions = Vector2(float(width) * cell_size, float(height) * cell_size)

	var half_w: float = island_dimensions.x / 2.0
	var half_h: float = island_dimensions.y / 2.0
	# Posiciona a placa no canto inferior direito da ilha (escala real 1.0x)
	map_plaque_pos = Vector3(half_w - 1.35, 0.25, half_h - 0.85)

	for item in terrain_arr:
		if not (item is Dictionary):
			continue
		var td: Dictionary = item as Dictionary
		var gx: int = int(td.get("gx", 0))
		var gz: int = int(td.get("gz", 0))
		var tile_id: String = String(td.get("tile_id", "island_center"))
		var rot: int = int(td.get("rot", 0))

		var model_scene: PackedScene = TILE_MODELS.get(tile_id, TILE_MODELS["island_center"]) as PackedScene
		if model_scene == null:
			continue

		var tile_inst: Node3D = model_scene.instantiate() as Node3D
		if tile_inst == null:
			continue

		var local_x: float = offset_x + float(gx) * cell_size
		var local_z: float = offset_z + float(gz) * cell_size
		tile_inst.position = Vector3(local_x, 0.0, local_z)
		tile_inst.rotation_degrees.y = float(rot)

		miniature_container.add_child(tile_inst)

	# Instancia os elementos/objetos sobre a ilha (vegetação, rochas, trigo, flores)
	var objects_arr: Array = data.get("objects", []) as Array

	# Subgrade 2x2 de células de 0.40m por bloco de terreno de 0.80m
	var sub_offsets: Array[Vector3] = [
		Vector3(-0.20, 0.0, -0.20),
		Vector3(0.20, 0.0, -0.20),
		Vector3(-0.20, 0.0, 0.20),
		Vector3(0.20, 0.0, 0.20)
	]

	for obj_item in objects_arr:
		if not (obj_item is Dictionary):
			continue
		var od: Dictionary = obj_item as Dictionary
		var ogx: int = int(od.get("gx", 0))
		var ogz: int = int(od.get("gz", 0))
		var otype: String = String(od.get("type", "grass_green"))
		var orot: int = int(od.get("rot", 0))

		var local_ox: float = offset_x + float(ogx) * cell_size
		var local_oz: float = offset_z + float(ogz) * cell_size
		var base_pos: Vector3 = Vector3(local_ox, 0.0, local_oz)

		if otype == "rock":
			# Rocha no tamanho original sem nenhuma grama naquele bloco
			var r_visual: Node3D = create_miniature_object("rock")
			if r_visual != null:
				r_visual.position = base_pos
				r_visual.rotation_degrees.y = float(orot)
				miniature_container.add_child(r_visual)
			continue

		elif otype == "flower" or otype == "wheat":
			# Flor ou trigo ocupa uma das células de 0.40m
			var p_visual: Node3D = create_miniature_object(otype)
			if p_visual != null:
				p_visual.position = base_pos + sub_offsets[0]
				p_visual.rotation_degrees.y = float(orot)
				p_visual.scale = Vector3(0.50, 0.50, 0.50)
				miniature_container.add_child(p_visual)

			# Preenche as outras 3 subcélulas de 0.40m com grama verde condensada
			for s_idx in range(1, 4):
				var g_sub: Node3D = create_miniature_object("grass_green")
				if g_sub != null:
					g_sub.position = base_pos + sub_offsets[s_idx]
					var sub_seed: float = float(ogx * 73 + ogz * 19 + s_idx * 31)
					g_sub.rotation.y = fmod(sub_seed, TAU)
					var s_y: float = (0.72 + fmod(sub_seed * 0.13, 0.13)) * 0.75
					var s_xz: float = (0.96 + fmod(sub_seed * 0.27, 0.14)) * 0.42
					g_sub.scale = Vector3(s_xz, s_y, s_xz)
					for child in g_sub.get_children():
						if child is MeshInstance3D:
							grass_mesh_records.append({"mesh": child, "type": "grass_green"})
					miniature_container.add_child(g_sub)

		elif otype.begins_with("grass_"):
			# Preenche as 4 células de 0.40m com grama condensada
			for s_idx in range(4):
				var g_visual: Node3D = create_miniature_object(otype)
				if g_visual != null:
					g_visual.position = base_pos + sub_offsets[s_idx]
					var sub_seed: float = float(ogx * 73 + ogz * 19 + s_idx * 31)
					g_visual.rotation.y = fmod(sub_seed, TAU)
					var s_y: float = (0.72 + fmod(sub_seed * 0.13, 0.13)) * 0.75
					var s_xz: float = (0.96 + fmod(sub_seed * 0.27, 0.14)) * 0.42
					g_visual.scale = Vector3(s_xz, s_y, s_xz)
					for child in g_visual.get_children():
						if child is MeshInstance3D:
							grass_mesh_records.append({"mesh": child, "type": otype})
					miniature_container.add_child(g_visual)
		else:
			var visual: Node3D = create_miniature_object(otype)
			if visual != null:
				visual.position = base_pos
				visual.rotation_degrees.y = float(orot)
				miniature_container.add_child(visual)

	# Atualiza o estado da animação de vento conforme o modo e atividade da ilha
	set_grass_animated(not is_map_mode and is_active_island)

func update_visuals() -> void:
	if level_label == null or stars_label == null:
		return

	if is_unlocked:
		level_label.text = str(level_number)
		if stars_earned > 0:
			var stars_str: String = ""
			for i in range(stars_earned):
				stars_str += "⭐"
			stars_label.text = stars_str
			stars_label.visible = true
		else:
			stars_label.text = "ATUAL"
			stars_label.visible = true
	else:
		level_label.text = "🔒"
		stars_label.text = ""
		stars_label.visible = false

	# Ajusta o material da placa (madeira/pedra fosca com status)
	if plaque_board != null:
		var mat: StandardMaterial3D = plaque_board.get_active_material(0) as StandardMaterial3D
		if mat != null:
			var new_mat: StandardMaterial3D = mat.duplicate() as StandardMaterial3D
			if is_unlocked:
				new_mat.albedo_color = Color(0.22, 0.48, 0.76, 1.0) # Azul náutico acolhedor
			else:
				new_mat.albedo_color = Color(0.35, 0.38, 0.42, 1.0) # Cinza fosco bloqueado
			plaque_board.material_override = new_mat

func set_view_mode(map_view: bool, active_island: bool, animated: bool = true) -> void:
	is_map_mode = map_view
	is_active_island = active_island

	# Animação de vento da grama ativa EXCLUSIVAMENTE na ilha onde o robô estiver na visão do bot
	set_grass_animated(not is_map_mode and is_active_island)

	if plaque_root == null:
		return

	var target_pos: Vector3 = Vector3.ZERO
	var target_rot: Vector3 = Vector3.ZERO
	var target_vis: bool = true

	if is_map_mode:
		# Na visão do mapa: repousa no canto inferior direito sobre o chão voltada para cima (-58° para a câmera)
		target_pos = map_plaque_pos
		target_rot = Vector3(-58.0, 0.0, 0.0)
		target_vis = true
		if plaque_post != null:
			plaque_post.visible = false # Oculta a estaca para virar um marco no chão
	else:
		# Na visão do bot: placa oculta para foco total no robô cortador
		target_pos = map_plaque_pos
		target_rot = Vector3(-58.0, 0.0, 0.0)
		target_vis = false
		if plaque_post != null:
			plaque_post.visible = false

	if animated:
		if plaque_tween != null and plaque_tween.is_valid():
			plaque_tween.kill()
		plaque_tween = create_tween()
		plaque_tween.set_parallel(true)
		plaque_tween.tween_property(plaque_root, "position", target_pos, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		plaque_tween.tween_property(plaque_root, "rotation_degrees", target_rot, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if not target_vis:
			plaque_tween.chain().tween_callback(func() -> void: plaque_root.visible = false)
		else:
			plaque_root.visible = true
	else:
		plaque_root.position = target_pos
		plaque_root.rotation_degrees = target_rot
		plaque_root.visible = target_vis

func get_island_dimensions() -> Vector2:
	return island_dimensions

func get_bot_position() -> Vector3:
	if bot_anchor != null:
		return bot_anchor.global_position
	return global_position + Vector3(0, -0.052, 0)

func _on_click_area_input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			island_selected.emit(level_number)
