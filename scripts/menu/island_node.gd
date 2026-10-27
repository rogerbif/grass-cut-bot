extends Node3D

signal island_selected(level_number: int)

const VegetationGrid = preload("res://scripts/plants/vegetation_grid.gd")
const VegetationFieldScript = preload("res://scripts/level/vegetation_field.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const IslandMeshBuilder = preload("res://scripts/level/island_mesh_builder.gd")
const ROCK_MODEL: PackedScene = preload("res://assets/models/rock.glb")

# Shaders oficiais da grama com gradiente vertical (raiz -> topo) e balanço de vento
const MAT_ACTIVE_GRASS_GREEN: ShaderMaterial = preload("res://shaders/interactive_grass_material.tres")
const MAT_ACTIVE_GRASS_YELLOW: ShaderMaterial = preload("res://shaders/interactive_grass_yellow_material.tres")
const MAT_ACTIVE_GRASS_BLUE: ShaderMaterial = preload("res://shaders/interactive_grass_blue_material.tres")
const MAT_ACTIVE_GRASS_PURPLE: ShaderMaterial = preload("res://shaders/interactive_grass_purple_material.tres")
const MAT_ACTIVE_GRASS_WHITE: ShaderMaterial = preload("res://shaders/interactive_grass_white_material.tres")
const MAT_ACTIVE_GRASS_RED: ShaderMaterial = preload("res://shaders/interactive_grass_red_material.tres")
const MAT_ACTIVE_GRASS_BLACK: ShaderMaterial = preload("res://shaders/interactive_grass_black_material.tres")
const MAT_ACTIVE_WHEAT: ShaderMaterial = preload("res://shaders/interactive_wheat_material.tres")

static var _mat_static_green: ShaderMaterial = null
static var _mat_static_yellow: ShaderMaterial = null
static var _mat_static_blue: ShaderMaterial = null
static var _mat_static_purple: ShaderMaterial = null
static var _mat_static_white: ShaderMaterial = null
static var _mat_static_red: ShaderMaterial = null
static var _mat_static_black: ShaderMaterial = null
static var _mat_static_wheat: ShaderMaterial = null
static var _mat_rock: StandardMaterial3D = null
static var _vector_materials: Dictionary = {}
static var _rock_mesh: Mesh = null

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
var is_built: bool = false

var vector_ground_container: Node3D = null
var veg_3d_container: Node3D = null
var is_3d_veg_built: bool = false
var _cached_level_data: Dictionary = {}
var _cached_width: int = 12
var _cached_height: int = 8
var _cached_cell_size: float = 0.8
var _cached_offset_x: float = 0.0
var _cached_offset_z: float = 0.0

var _rock_transforms: Array[Transform3D] = []
var _rocks_mmi: MultiMeshInstance3D = null
var veg_transforms_by_type: Dictionary = {}


func _ready() -> void:
	update_visuals()


func setup_island(lvl: int, unlocked: bool, stars: int) -> void:
	level_number = lvl
	is_unlocked = unlocked
	stars_earned = stars
	read_island_metadata(lvl)
	update_visuals()
	set_view_mode(is_map_mode, is_active_island, false)


func read_island_metadata(lvl: int) -> void:
	var json_path: String = "res://data/levels/level_%02d.json" % lvl
	if not FileAccess.file_exists(json_path):
		return
	var file: FileAccess = FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		var data: Dictionary = parsed as Dictionary
		var grid_info: Dictionary = data.get("grid", {}) as Dictionary
		var width: int = int(grid_info.get("width", 12))
		var height: int = int(grid_info.get("height", 8))
		var cell_size: float = float(grid_info.get("cell_size", 0.8))
		island_dimensions = Vector2(float(width) * cell_size, float(height) * cell_size)
		var half_w: float = island_dimensions.x / 2.0
		var half_h: float = island_dimensions.y / 2.0
		map_plaque_pos = Vector3(half_w - 1.35, 0.25, half_h - 0.85)
		if data.has("spawn") and data["spawn"] is Dictionary:
			var sp_dict: Dictionary = data["spawn"] as Dictionary
			var sp_x: int = int(sp_dict.get("gx", int(float(width) / 2.0)))
			var sp_z: int = int(sp_dict.get("gz", int(float(height) / 2.0)))
			var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_x, sp_z, width, height, cell_size)
			if bot_anchor != null:
				bot_anchor.position = Vector3(sp_world.x, -0.052, sp_world.z)


func _is_in_front_of_bot(pos: Vector3) -> bool:
	if bot_anchor == null:
		return false
	var bot_pos: Vector3 = bot_anchor.position
	var dz: float = pos.z - bot_pos.z
	var dx: float = absf(pos.x - bot_pos.x)
	# Na visão BOT_VIEW (modo Home), o robô fica voltado para +Z em direção à câmera.
	# Qualquer elemento no setor frontal do robô (dz > -0.30m) dentro do enquadramento (dx < 3.2m)
	# obstrui o corpo, cabeça, lâmina ou a área de avanço frontal do bot.
	return dz > -0.30 and dx < 3.2


func _set_rocks_in_front_hidden(hidden: bool) -> void:
	if _rocks_mmi == null or _rocks_mmi.multimesh == null or _rock_transforms.is_empty():
		return
	var mm: MultiMesh = _rocks_mmi.multimesh
	for idx: int in range(_rock_transforms.size()):
		var xform: Transform3D = _rock_transforms[idx]
		if hidden and _is_in_front_of_bot(xform.origin):
			mm.set_instance_transform(idx, Transform3D(Basis.from_scale(Vector3.ZERO), Vector3(0, -999.0, 0)))
		else:
			mm.set_instance_transform(idx, xform)


func ensure_content_loaded() -> void:
	if is_built:
		return
	is_built = true
	build_miniature_from_json(level_number)
	set_view_mode(is_map_mode, is_active_island, false)


static func _ensure_rock_mesh() -> void:
	if _rock_mesh == null:
		var r_inst: Node = ROCK_MODEL.instantiate()
		var mesh_node: MeshInstance3D = r_inst.get_node_or_null("rock_export") as MeshInstance3D
		if mesh_node == null:
			for child: Node in r_inst.get_children():
				if child is MeshInstance3D and (child as MeshInstance3D).mesh != null:
					mesh_node = child as MeshInstance3D
					break
		if mesh_node != null:
			_rock_mesh = mesh_node.mesh
		r_inst.free()


static func _get_vector_material(v_type: String) -> StandardMaterial3D:
	if _vector_materials.has(v_type):
		return _vector_materials[v_type] as StandardMaterial3D

	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.roughness = 0.90
	mat.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL

	match v_type:
		"grass_yellow":
			mat.albedo_color = Color(0.88, 0.80, 0.32, 1.0)
		"grass_blue":
			mat.albedo_color = Color(0.34, 0.62, 0.90, 1.0)
		"grass_purple":
			mat.albedo_color = Color(0.69, 0.39, 0.85, 1.0)
		"grass_white":
			mat.albedo_color = Color(0.92, 0.94, 0.96, 1.0)
		"grass_red":
			mat.albedo_color = Color(0.88, 0.35, 0.37, 1.0)
		"grass_black":
			mat.albedo_color = Color(0.18, 0.18, 0.22, 1.0)
		"wheat":
			mat.albedo_color = Color(0.92, 0.72, 0.20, 1.0)
		"flower":
			mat.albedo_color = Color(0.95, 0.35, 0.65, 1.0)
		_:
			mat.albedo_color = Color(0.34, 0.72, 0.37, 1.0) # grass_green

	_vector_materials[v_type] = mat
	return mat


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

		_mat_static_white = MAT_ACTIVE_GRASS_WHITE.duplicate() as ShaderMaterial
		_mat_static_white.set_shader_parameter("wind_strength", 0.0)

		_mat_static_red = MAT_ACTIVE_GRASS_RED.duplicate() as ShaderMaterial
		_mat_static_red.set_shader_parameter("wind_strength", 0.0)

		_mat_static_black = MAT_ACTIVE_GRASS_BLACK.duplicate() as ShaderMaterial
		_mat_static_black.set_shader_parameter("wind_strength", 0.0)

		_mat_static_wheat = MAT_ACTIVE_WHEAT.duplicate() as ShaderMaterial
		_mat_static_wheat.set_shader_parameter("wind_strength", 0.0)

		_mat_rock = StandardMaterial3D.new()
		_mat_rock.albedo_color = Color(0.42, 0.46, 0.50, 1.0)
		_mat_rock.roughness = 0.95


func set_grass_animated(enabled: bool) -> void:
	_init_materials()
	for rec: Dictionary in grass_mesh_records:
		var gi: GeometryInstance3D = rec.get("mesh", null) as GeometryInstance3D
		if gi == null or not is_instance_valid(gi):
			continue
		var gtype: String = String(rec.get("type", "grass_green"))
		if enabled:
			match gtype:
				"grass_yellow":
					gi.material_override = MAT_ACTIVE_GRASS_YELLOW
				"grass_blue":
					gi.material_override = MAT_ACTIVE_GRASS_BLUE
				"grass_purple":
					gi.material_override = MAT_ACTIVE_GRASS_PURPLE
				"grass_white":
					gi.material_override = MAT_ACTIVE_GRASS_WHITE
				"grass_red":
					gi.material_override = MAT_ACTIVE_GRASS_RED
				"grass_black":
					gi.material_override = MAT_ACTIVE_GRASS_BLACK
				"wheat":
					gi.material_override = MAT_ACTIVE_WHEAT
				_:
					gi.material_override = MAT_ACTIVE_GRASS_GREEN
		else:
			match gtype:
				"grass_yellow":
					gi.material_override = _mat_static_yellow
				"grass_blue":
					gi.material_override = _mat_static_blue
				"grass_purple":
					gi.material_override = _mat_static_purple
				"grass_white":
					gi.material_override = _mat_static_white
				"grass_red":
					gi.material_override = _mat_static_red
				"grass_black":
					gi.material_override = _mat_static_black
				"wheat":
					gi.material_override = _mat_static_wheat
				_:
					gi.material_override = _mat_static_green


func build_miniature_from_json(lvl: int) -> void:
	if miniature_container == null:
		return

	# Limpa elementos anteriores da miniatura e registros de grama
	for c: Node in miniature_container.get_children():
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

	if fallback_mesh != null:
		fallback_mesh.visible = false

	_init_materials()
	VegetationGrid._ensure_static_meshes()

	# Escala real 1.0x (idêntica ao gameplay)
	miniature_container.scale = Vector3(1.0, 1.0, 1.0)
	island_dimensions = Vector2(float(width) * cell_size, float(height) * cell_size)

	var half_w: float = island_dimensions.x / 2.0
	var half_h: float = island_dimensions.y / 2.0
	# Posiciona a placa no canto inferior direito da ilha (escala real 1.0x)
	map_plaque_pos = Vector3(half_w - 1.35, 0.25, half_h - 0.85)

	if data.has("spawn") and data["spawn"] is Dictionary:
		var sp_dict: Dictionary = data["spawn"] as Dictionary
		var sp_x: int = int(sp_dict.get("gx", int(float(width) / 2.0)))
		var sp_z: int = int(sp_dict.get("gz", int(float(height) / 2.0)))
		var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_x, sp_z, width, height, cell_size)
		if bot_anchor != null:
			bot_anchor.position = Vector3(sp_world.x, -0.052, sp_world.z)

	# 1. Constrói a miniatura unificada da ilha via IslandMeshBuilder (1 Draw Call)
	var island_polys: Array[PackedVector2Array] = LevelJsonLoader.get_island_polygons(data)
	var island_mesh: ArrayMesh = IslandMeshBuilder.build_island_mesh(island_polys)
	if island_mesh != null:
		var mini_mi: MeshInstance3D = MeshInstance3D.new()
		mini_mi.name = "MiniIslandMesh"
		mini_mi.mesh = island_mesh
		mini_mi.material_override = IslandMeshBuilder.get_island_material()
		mini_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		miniature_container.add_child(mini_mi)

	# Fita de espuma costeira animada (CoastalFoamRibbon) na base exata das falésias
	var foam_mesh: ArrayMesh = IslandMeshBuilder.build_coastal_foam_mesh(island_polys)
	if foam_mesh != null and foam_mesh.get_surface_count() > 0:
		var foam_inst: MeshInstance3D = MeshInstance3D.new()
		foam_inst.name = "CoastalFoamRibbon"
		foam_inst.mesh = foam_mesh
		foam_inst.material_override = IslandMeshBuilder.get_foam_material()
		foam_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		miniature_container.add_child(foam_inst)

	# 2. Agrupa rochas em MultiMeshInstance3D único (1 draw call por ilha)
	var objects_arr: Array = data.get("objects", []) as Array
	_rock_transforms.clear()

	for obj_item: Variant in objects_arr:
		if not (obj_item is Dictionary):
			continue
		var od: Dictionary = obj_item as Dictionary
		var ogx: int = int(od.get("gx", 0))
		var ogz: int = int(od.get("gz", 0))
		var otype: String = String(od.get("type", ""))
		var orot: int = int(od.get("rot", 0))

		var local_ox: float = offset_x + float(ogx) * cell_size
		var local_oz: float = offset_z + float(ogz) * cell_size
		var base_pos: Vector3 = Vector3(local_ox, 0.0, local_oz)

		if otype == "rock":
			var r_basis: Basis = Basis(Vector3.UP, deg_to_rad(float(orot)))
			_rock_transforms.append(Transform3D(r_basis, base_pos))

	if not _rock_transforms.is_empty():
		_ensure_rock_mesh()
		if _rock_mesh != null:
			var r_mm: MultiMesh = MultiMesh.new()
			r_mm.transform_format = MultiMesh.TRANSFORM_3D
			r_mm.mesh = _rock_mesh
			r_mm.instance_count = _rock_transforms.size()
			for idx: int in range(_rock_transforms.size()):
				r_mm.set_instance_transform(idx, _rock_transforms[idx])

			_rocks_mmi = MultiMeshInstance3D.new()
			_rocks_mmi.name = "MiniRocksMMI"
			_rocks_mmi.multimesh = r_mm
			_rocks_mmi.material_override = _mat_rock
			_rocks_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			miniature_container.add_child(_rocks_mmi)

	# 3. Cacheia metadados e constrói containers de vegetação vetorial e 3D
	_cached_level_data = data
	_cached_width = width
	_cached_height = height
	_cached_cell_size = cell_size
	_cached_offset_x = offset_x
	_cached_offset_z = offset_z
	is_3d_veg_built = false

	vector_ground_container = Node3D.new()
	vector_ground_container.name = "VectorGroundContainer"
	miniature_container.add_child(vector_ground_container)

	veg_3d_container = Node3D.new()
	veg_3d_container.name = "Veg3DContainer"
	miniature_container.add_child(veg_3d_container)

	# Constrói imediatamente o chão vetorial 2D plano (ultra-rápido, ~0.3ms)
	_build_vector_ground(data, width, height, cell_size)

	# Se for a ilha ativa na visão do robô, constrói a grama 3D antecipadamente
	if not is_map_mode and is_active_island:
		_ensure_3d_veg_built()

	_apply_mode_visibility()


func _build_vector_ground(data: Dictionary, width: int, height: int, cell_size: float) -> void:
	if vector_ground_container == null:
		return

	for c: Node in vector_ground_container.get_children():
		c.queue_free()

	if not data.has("grass_vectors") or not (data["grass_vectors"] is Array):
		return

	var vector_field: RefCounted = VectorGrassFieldScript.new()
	vector_field.call("from_dict_list", data["grass_vectors"] as Array)

	var objects_arr: Array = data.get("objects", []) as Array

	# Remove polígonos sob rochas para manter recorte estético limpo
	for obj_item: Variant in objects_arr:
		if obj_item is Dictionary and String((obj_item as Dictionary).get("type", "")) == "rock":
			var rx: int = int((obj_item as Dictionary).get("gx", 0))
			var rz: int = int((obj_item as Dictionary).get("gz", 0))
			var r_world: Vector3 = LevelJsonLoader.grid_to_world(rx, rz, width, height, cell_size)
			var rock_clip_poly: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
				BrushPatterns.ShapeType.CIRCLE,
				1,
				Vector2(r_world.x, r_world.z)
			)
			vector_field.call("clip_shapes", rock_clip_poly)

	# Adiciona flores e trigos de tile como selos circulares na malha vetorial
	for obj_item: Variant in objects_arr:
		if obj_item is Dictionary:
			var od: Dictionary = obj_item as Dictionary
			var o_type: String = String(od.get("type", ""))
			if o_type.begins_with("flower") or o_type == "wheat":
				var fx: int = int(od.get("gx", 0))
				var fz: int = int(od.get("gz", 0))
				var f_pos: Vector3 = LevelJsonLoader.grid_to_world(fx, fz, width, height, cell_size)
				var stamp_poly: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
					BrushPatterns.ShapeType.CIRCLE,
					1,
					Vector2(f_pos.x, f_pos.z)
				)
				var v_stamp_type: String = "wheat" if o_type == "wheat" else "flower"
				vector_field.call("add_shape", v_stamp_type, stamp_poly)

	var ground_meshes: Dictionary = vector_field.call("generate_ground_meshes") as Dictionary
	for v_type_var: Variant in ground_meshes.keys():
		var vt: String = String(v_type_var)
		var mesh_res: Mesh = ground_meshes[vt] as Mesh
		if mesh_res == null:
			continue
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.name = "VectorGroundMesh_%s" % vt
		mi.mesh = mesh_res
		mi.material_override = _get_vector_material(vt)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		vector_ground_container.add_child(mi)


func _ensure_3d_veg_built() -> void:
	if is_3d_veg_built or veg_3d_container == null or _cached_level_data.is_empty():
		return
	is_3d_veg_built = true

	var data: Dictionary = _cached_level_data
	var width: int = _cached_width
	var height: int = _cached_height
	var cell_size: float = _cached_cell_size
	var offset_x: float = _cached_offset_x
	var offset_z: float = _cached_offset_z
	var objects_arr: Array = data.get("objects", []) as Array

	veg_transforms_by_type.clear()
	for v_type: String in VegetationGrid.VEG_TYPES:
		var empty_xforms: Array[Transform3D] = []
		veg_transforms_by_type[v_type] = empty_xforms

	if data.has("grass_vectors") and data["grass_vectors"] is Array:
		var vector_field: RefCounted = VectorGrassFieldScript.new()
		vector_field.call("from_dict_list", data["grass_vectors"] as Array)

		for obj_item: Variant in objects_arr:
			if obj_item is Dictionary and String((obj_item as Dictionary).get("type", "")) == "rock":
				var rx: int = int((obj_item as Dictionary).get("gx", 0))
				var rz: int = int((obj_item as Dictionary).get("gz", 0))
				var r_world: Vector3 = LevelJsonLoader.grid_to_world(rx, rz, width, height, cell_size)
				var rock_clip_poly: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
					BrushPatterns.ShapeType.CIRCLE,
					1,
					Vector2(r_world.x, r_world.z)
				)
				vector_field.call("clip_shapes", rock_clip_poly)

		for obj_item: Variant in objects_arr:
			if obj_item is Dictionary:
				var od: Dictionary = obj_item as Dictionary
				var o_type: String = String(od.get("type", ""))
				if o_type.begins_with("flower"):
					var fx: int = int(od.get("gx", 0))
					var fz: int = int(od.get("gz", 0))
					var f_pos: Vector3 = LevelJsonLoader.grid_to_world(fx, fz, width, height, cell_size)
					if _is_in_front_of_bot(f_pos):
						continue
					var f_basis: Basis = Basis(Vector3.UP, fmod(float(fx * 79 + fz * 31), TAU)).scaled(Vector3(0.676, 0.676, 0.676))
					var f_key: String = o_type if veg_transforms_by_type.has(o_type) else "flower"
					(veg_transforms_by_type[f_key] as Array[Transform3D]).append(Transform3D(f_basis, f_pos))
				elif o_type == "wheat":
					var wx: int = int(od.get("gx", 0))
					var wz: int = int(od.get("gz", 0))
					var w_pos: Vector3 = LevelJsonLoader.grid_to_world(wx, wz, width, height, cell_size)
					if _is_in_front_of_bot(w_pos):
						continue
					var w_basis: Basis = Basis(Vector3.UP, fmod(float(wx * 67 + wz * 43), TAU)).scaled(Vector3(0.84, 1.30, 0.84))
					(veg_transforms_by_type["wheat"] as Array[Transform3D]).append(Transform3D(w_basis, w_pos))

		var sampled_tufts: Array = vector_field.call("sample_all_tufts") as Array
		for item: Variant in sampled_tufts:
			if not (item is Dictionary):
				continue
			var td: Dictionary = item as Dictionary
			var pos: Vector3 = td["pos"] as Vector3
			if _is_in_front_of_bot(pos):
				continue
			var v_type: String = String(td.get("type", "grass_green"))
			if not veg_transforms_by_type.has(v_type):
				v_type = "grass_green"
			var scale_factor: float = float(td.get("scale_factor", 1.0))
			var s_seed: float = float(td.get("seed", 0.0))
			var random_rot: float = fmod(s_seed * 1.618, TAU)

			var scale_vec: Vector3
			if v_type == "wheat":
				var scale_y: float = lerpf(1.10, 1.40, scale_factor) * (0.95 + fmod(s_seed * 0.13, 0.10))
				var scale_xz: float = lerpf(0.68, 0.92, scale_factor) * (0.95 + fmod(s_seed * 0.27, 0.10))
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			elif not v_type.begins_with("flower"):
				var scale_y: float = lerpf(0.48, 0.62, scale_factor) * (0.95 + fmod(s_seed * 0.13, 0.10))
				var scale_xz: float = lerpf(0.32, 0.44, scale_factor) * (0.95 + fmod(s_seed * 0.27, 0.10))
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			else:
				var sf: float = 0.676 * scale_factor
				scale_vec = Vector3(sf, sf, sf)

			var g_basis: Basis = Basis(Vector3.UP, random_rot) * Basis.from_scale(scale_vec)
			(veg_transforms_by_type[v_type] as Array[Transform3D]).append(Transform3D(g_basis, pos))
	else:
		# Modo Legado v1/v2
		var veg_field: RefCounted = null
		if data.has("vegetation") and data["vegetation"] is Dictionary:
			var vdict: Dictionary = data["vegetation"] as Dictionary
			var rows_arr: Array = vdict.get("rows", []) as Array
			veg_field = VegetationFieldScript.new(width, height)
			veg_field.call("from_rows", rows_arr)
		else:
			veg_field = VegetationFieldScript.new(width, height)
			veg_field.call("from_legacy_objects", objects_arr, width, height)

		for obj_item: Variant in objects_arr:
			if obj_item is Dictionary and String((obj_item as Dictionary).get("type", "")) == "rock":
				var rx: int = int((obj_item as Dictionary).get("gx", 0))
				var rz: int = int((obj_item as Dictionary).get("gz", 0))
				for dz: int in range(4):
					for dx: int in range(4):
						veg_field.call("set_cell", rx * 4 + dx, rz * 4 + dz, 0)

		var cols: int = int(veg_field.get("cols"))
		var rows: int = int(veg_field.get("rows"))
		var sdf: PackedFloat32Array = veg_field.call("compute_sdf_depth_map") as PackedFloat32Array
		var processed_flowers: Dictionary = {}

		for obj_item: Variant in objects_arr:
			if obj_item is Dictionary and String((obj_item as Dictionary).get("type", "")) == "flower":
				var fx: int = int((obj_item as Dictionary).get("gx", 0))
				var fz: int = int((obj_item as Dictionary).get("gz", 0))
				var f_pos: Vector3 = Vector3(offset_x + float(fx) * cell_size, 0.0, offset_z + float(fz) * cell_size)
				if _is_in_front_of_bot(f_pos):
					continue
				var f_basis: Basis = Basis(Vector3.UP, fmod(float(fx * 79 + fz * 31), TAU)).scaled(Vector3(0.676, 0.676, 0.676))
				(veg_transforms_by_type["flower"] as Array[Transform3D]).append(Transform3D(f_basis, f_pos))

		for r: int in range(rows):
			for c: int in range(cols):
				var tid: int = int(veg_field.call("get_cell", c, r))
				if tid == 0:
					continue
				var v_type: String = VegetationFieldScript.type_id_to_name(tid)
				if not veg_transforms_by_type.has(v_type):
					v_type = "grass_green"

				var lx: int = c >> 1
				var lz: int = r >> 1
				var lkey: Vector2i = Vector2i(lx, lz)

				if tid == 9:
					if processed_flowers.has(lkey):
						continue
					processed_flowers[lkey] = true
					var flower_pos: Vector3 = veg_field.call("cell_to_world", lx * 2, lz * 2, cell_size) as Vector3
					flower_pos.x += 0.10
					flower_pos.z += 0.10
					if _is_in_front_of_bot(flower_pos):
						continue
					var f_basis: Basis = Basis(Vector3.UP, fmod(float(lx * 79 + lz * 31), TAU)).scaled(Vector3(0.676, 0.676, 0.676))
					(veg_transforms_by_type["flower"] as Array[Transform3D]).append(Transform3D(f_basis, flower_pos))
					continue

				var base_pos: Vector3 = veg_field.call("cell_to_world", c, r, cell_size) as Vector3
				var sub_seed: float = float(c * 73 + r * 19)
				var j_x: float = (fmod(sub_seed * 0.17, 1.0) - 0.5) * 0.12
				var j_z: float = (fmod(sub_seed * 0.31, 1.0) - 0.5) * 0.12
				var tuft_pos: Vector3 = base_pos + Vector3(j_x, 0.0, j_z)
				if _is_in_front_of_bot(tuft_pos):
					continue

				var dist_m: float = sdf[r * cols + c]
				var edge_t: float = smoothstep(0.0, 0.28, dist_m)
				var rot_y: float = fmod(sub_seed * 1.618, TAU)

				var scale_vec: Vector3
				if v_type == "wheat":
					var scale_y: float = lerpf(1.10, 1.40, edge_t) * (0.95 + fmod(sub_seed * 0.13, 0.10))
					var scale_xz: float = lerpf(0.68, 0.92, edge_t) * (0.95 + fmod(sub_seed * 0.27, 0.10))
					scale_vec = Vector3(scale_xz, scale_y, scale_xz)
				elif not v_type.begins_with("flower"):
					var scale_y: float = lerpf(0.48, 0.62, edge_t) * (0.95 + fmod(sub_seed * 0.13, 0.10))
					var scale_xz: float = lerpf(0.32, 0.44, edge_t) * (0.95 + fmod(sub_seed * 0.27, 0.10))
					scale_vec = Vector3(scale_xz, scale_y, scale_xz)
				else:
					var sf: float = 0.676
					scale_vec = Vector3(sf, sf, sf)

				var g_basis: Basis = Basis(Vector3.UP, rot_y) * Basis.from_scale(scale_vec)
				(veg_transforms_by_type[v_type] as Array[Transform3D]).append(Transform3D(g_basis, tuft_pos))

	for v_type: String in VegetationGrid.VEG_TYPES:
		var xforms: Array[Transform3D] = veg_transforms_by_type[v_type] as Array[Transform3D]
		if xforms.is_empty():
			continue

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		if v_type.begins_with("flower"):
			mm.use_custom_data = true
			if v_type == "flower_rose":
				mm.mesh = VegetationGrid._flower_rose_mesh
			elif v_type == "flower_daisy":
				mm.mesh = VegetationGrid._flower_daisy_mesh
			elif v_type == "flower_sunflower":
				mm.mesh = VegetationGrid._flower_sunflower_mesh
			elif v_type == "flower_bell":
				mm.mesh = VegetationGrid._flower_bell_mesh
			elif v_type == "flower_corolla":
				mm.mesh = VegetationGrid._flower_corolla_mesh
			elif v_type == "flower_tulip":
				mm.mesh = VegetationGrid._flower_tulip_mesh
			elif v_type == "flower_bed":
				mm.mesh = VegetationGrid._flower_bed_mesh
			else:
				mm.mesh = VegetationGrid._flower_mesh
		elif v_type == "wheat":
			mm.mesh = VegetationGrid._wheat_mesh
		else:
			mm.mesh = VegetationGrid._grass_mesh
		mm.instance_count = xforms.size()
		for i: int in range(xforms.size()):
			mm.set_instance_transform(i, xforms[i])

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "MiniVegMMI_%s" % v_type
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		veg_3d_container.add_child(mmi)

		if v_type.begins_with("grass_") or v_type == "wheat":
			grass_mesh_records.append({"mesh": mmi, "type": v_type})

	set_grass_animated(not is_map_mode and is_active_island)


func _apply_mode_visibility() -> void:
	if is_map_mode:
		if vector_ground_container != null:
			vector_ground_container.visible = true
		if veg_3d_container != null:
			veg_3d_container.visible = false
		set_grass_animated(false)
		_set_rocks_in_front_hidden(false)
	else:
		if is_active_island:
			_ensure_3d_veg_built()
			if vector_ground_container != null:
				vector_ground_container.visible = false
			if veg_3d_container != null:
				veg_3d_container.visible = true
			set_grass_animated(true)
			_set_rocks_in_front_hidden(true)
		else:
			if vector_ground_container != null:
				vector_ground_container.visible = true
			if veg_3d_container != null:
				veg_3d_container.visible = false
			set_grass_animated(false)
			_set_rocks_in_front_hidden(false)


func set_active_in_tree(is_active: bool) -> void:
	if click_area != null:
		click_area.monitoring = is_active
		click_area.monitorable = is_active
		var col: CollisionShape3D = click_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if col != null:
			col.disabled = not is_active
	process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED


func update_visuals() -> void:
	if level_label == null or stars_label == null:
		return

	if is_unlocked:
		level_label.text = str(level_number)
		if stars_earned > 0:
			var stars_str: String = ""
			for i: int in range(stars_earned):
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

	_apply_mode_visibility()

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
