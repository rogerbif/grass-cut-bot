extends Node3D

const VegetationFieldScript = preload("res://scripts/level/vegetation_field.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const LawnCutTrailScript = preload("res://scripts/level/lawn_cut_trail.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const PlantScript = preload("res://scripts/plants/plant.gd")

const GRASS_MODEL: PackedScene = preload("res://assets/models/grass_01.glb")
const WHEAT_SCENE: PackedScene = preload("res://scenes/plants/wheat_tuft.tscn")
const FLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_tuft.tscn")

const GRASS_MATERIALS: Dictionary = {
	"grass_green": preload("res://shaders/interactive_grass_material.tres"),
	"grass_yellow": preload("res://shaders/interactive_grass_yellow_material.tres"),
	"grass_blue": preload("res://shaders/interactive_grass_blue_material.tres"),
	"grass_purple": preload("res://shaders/interactive_grass_purple_material.tres"),
	"grass_white": preload("res://shaders/interactive_grass_white_material.tres"),
	"grass_red": preload("res://shaders/interactive_grass_red_material.tres"),
	"grass_black": preload("res://shaders/interactive_grass_black_material.tres"),
	"wheat": preload("res://shaders/interactive_wheat_material.tres")
}

const TILE_MODELS: Dictionary = {
	"island_center": preload("res://assets/models/tiles/tile_island_center.glb"),
	"island_edge": preload("res://assets/models/tiles/tile_island_edge.glb"),
	"island_corner_out": preload("res://assets/models/tiles/tile_island_corner_out.glb"),
	"island_corner_in": preload("res://assets/models/tiles/tile_island_corner_in.glb"),
	"island_end": preload("res://assets/models/tiles/tile_island_end.glb"),
	"island_dirt": preload("res://assets/models/tiles/tile_island_dirt.glb")
}

const VEG_TYPES: Array[String] = [
	"grass_green",
	"grass_yellow",
	"grass_blue",
	"grass_purple",
	"grass_white",
	"grass_red",
	"grass_black",
	"wheat",
	"flower"
]

const GRID_STEP: float = 0.40
const TUFT_HIT_RADIUS_BONUS: float = 0.18
const MULTI_HIT_COOLDOWN_SEC: float = 0.22
const HIDDEN_TRANSFORM: Transform3D = Transform3D(
	Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO),
	Vector3(0.0, -9999.0, 0.0)
)

static var _grass_mesh: Mesh = null
static var _wheat_mesh: ArrayMesh = null
static var _flower_mesh: ArrayMesh = null
static var _tile_meshes: Dictionary = {}

# Dados por planta (SoA - Structure of Arrays para zero overhead de nós)
var _positions: PackedVector3Array = PackedVector3Array()
var _initial_transforms: Array[Transform3D] = []
var _cut_transforms: Array[Transform3D] = []
var _mmi_indices: PackedInt32Array = PackedInt32Array()
var _instance_indices: PackedInt32Array = PackedInt32Array()
var _health: PackedInt32Array = PackedInt32Array()
var _max_health: PackedInt32Array = PackedInt32Array()
var _coin_rewards: PackedInt32Array = PackedInt32Array()
var _is_cut: PackedByteArray = PackedByteArray()
var _is_hidden_by_density: PackedByteArray = PackedByteArray()
var _last_hit_time: PackedFloat32Array = PackedFloat32Array()
var _plant_keys: PackedStringArray = PackedStringArray()
var _particle_colors: PackedColorArray = PackedColorArray()

# Mapeamento do tufo para a célula lógica de 0.40m
var _tuft_logical_cell: PackedInt32Array = PackedInt32Array()

# Dados por célula lógica de 0.40m
var _cell_remaining_tufts: PackedInt32Array = PackedInt32Array()
var _cell_keys: PackedStringArray = PackedStringArray()
var _cell_rewards: PackedInt32Array = PackedInt32Array()
var _cell_is_completed: PackedByteArray = PackedByteArray()

# Contadores físicos e acumuladores de corte (10 físicos = 1 meta)
var _total_physical_grass: int = 0
var _total_physical_wheat: int = 0
var _total_physical_flower: int = 0

var _remaining_physical_grass: int = 0
var _remaining_physical_wheat: int = 0
var _remaining_physical_flower: int = 0

var _grass_cut_accumulator: int = 0
var _wheat_cut_accumulator: int = 0

# MultiMeshes ativos de vegetação (indexados por mmi_idx de 0 a VEG_TYPES.size() - 1)
var _veg_multimeshes: Array[MultiMesh] = []
var _veg_mmi_nodes: Array[MultiMeshInstance3D] = []

# MultiMeshes de aparas de folhas cortadas deitadas no chão
var _clipping_multimeshes: Array[MultiMesh] = []
var _clipping_mmi_nodes: Array[MultiMeshInstance3D] = []
var _clipping_counts: PackedInt32Array = PackedInt32Array()
static var _clipping_meshes: Dictionary = {}

# Decalque de solo orgânico e trilha
var _lawn_decal_mesh: MeshInstance3D = null
var _lawn_cut_trail: Node3D = null

# Grade espacial discreta 2D: Vector2i(cx, cz) -> PackedInt32Array de p_idx
var _grid: Dictionary = {}

# Estado atual de visibilidade para benchmark
var _last_vegetation_on: bool = true
var _last_density_step: int = 1


static func _ensure_static_meshes() -> void:
	if _grass_mesh == null:
		var grass_inst: Node = GRASS_MODEL.instantiate()
		var mi: MeshInstance3D = _find_first_mesh_instance(grass_inst)
		if mi != null and mi.mesh != null:
			_grass_mesh = mi.mesh
		grass_inst.free()

	if _wheat_mesh == null:
		var wheat_inst: Node = WHEAT_SCENE.instantiate()
		var visual_root: Node3D = wheat_inst.get_node_or_null("VisualMesh") as Node3D
		if visual_root != null:
			_wheat_mesh = _build_combined_mesh_from_hierarchy(visual_root, Transform3D.IDENTITY)
		wheat_inst.free()

	if _flower_mesh == null:
		var flower_inst: Node = FLOWER_SCENE.instantiate()
		var visual_root: Node3D = flower_inst.get_node_or_null("VisualMesh") as Node3D
		if visual_root != null:
			_flower_mesh = _build_combined_mesh_from_hierarchy(visual_root, Transform3D.IDENTITY)
		flower_inst.free()

	if _tile_meshes.is_empty():
		var model_scale_xform: Transform3D = Transform3D().scaled(Vector3(1.0, 2.0, 1.0))
		for tile_key: Variant in TILE_MODELS.keys():
			var t_id: String = String(tile_key)
			var packed: PackedScene = TILE_MODELS[t_id] as PackedScene
			if packed == null:
				continue
			var tile_inst: Node = packed.instantiate()
			var combined: ArrayMesh = _build_combined_mesh_from_hierarchy(tile_inst, model_scale_xform)
			_tile_meshes[t_id] = combined
			tile_inst.free()


static func _find_first_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node as MeshInstance3D
	for child: Node in node.get_children():
		var found: MeshInstance3D = _find_first_mesh_instance(child)
		if found != null:
			return found
	return null


static func _build_combined_mesh_from_hierarchy(root_node: Node, root_xform: Transform3D) -> ArrayMesh:
	var combined_mesh: ArrayMesh = ArrayMesh.new()
	combined_mesh = _append_meshes_recursive(root_node, root_xform, combined_mesh, true)
	return combined_mesh


static func _append_meshes_recursive(
	node: Node,
	accum_xform: Transform3D,
	combined_mesh: ArrayMesh,
	is_root: bool
) -> ArrayMesh:
	var current_xform: Transform3D = accum_xform
	if not is_root and node is Node3D:
		current_xform = accum_xform * (node as Node3D).transform

	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			var surf_count: int = mi.mesh.get_surface_count()
			for s_idx: int in range(surf_count):
				var st: SurfaceTool = SurfaceTool.new()
				st.append_from(mi.mesh, s_idx, current_xform)
				var mat: Material = mi.get_active_material(s_idx)
				if mat == null:
					mat = mi.mesh.surface_get_material(s_idx)
				if mat != null:
					st.set_material(mat)
				combined_mesh = st.commit(combined_mesh)

	for child: Node in node.get_children():
		combined_mesh = _append_meshes_recursive(child, current_xform, combined_mesh, false)

	return combined_mesh


func _clear_state() -> void:
	for child: Node in get_children():
		child.queue_free()
	_positions.clear()
	_initial_transforms.clear()
	_cut_transforms.clear()
	_mmi_indices.clear()
	_instance_indices.clear()
	_health.clear()
	_max_health.clear()
	_coin_rewards.clear()
	_is_cut.clear()
	_is_hidden_by_density.clear()
	_last_hit_time.clear()
	_plant_keys.clear()
	_particle_colors.clear()
	_tuft_logical_cell.clear()
	_cell_remaining_tufts.clear()
	_cell_keys.clear()
	_cell_rewards.clear()
	_cell_is_completed.clear()
	_lawn_decal_mesh = null
	_lawn_cut_trail = null
	_veg_multimeshes.clear()
	_veg_mmi_nodes.clear()
	_clipping_multimeshes.clear()
	_clipping_mmi_nodes.clear()
	_clipping_counts.clear()
	_grid.clear()
	_last_vegetation_on = true
	_last_density_step = 1


func build_from_level_json(
	data: Dictionary,
	obstacles_container: Node3D,
	cutter: CharacterBody3D
) -> Dictionary:
	_clear_state()
	_ensure_static_meshes()

	var water: Node3D = LevelJsonLoader.WATER_OCEAN_SCENE.instantiate() as Node3D
	if water != null:
		add_child(water)

	var grid_info: Dictionary = data.get("grid", {}) as Dictionary
	var width: int = int(grid_info.get("width", 12))
	var height: int = int(grid_info.get("height", 8))
	var cell_size: float = float(grid_info.get("cell_size", LevelJsonLoader.DEFAULT_CELL_SIZE))

	# 1. Agrupa blocos de terreno por tile_id e cria MultiMeshInstance3D por tipo de tile
	var occupied_cells: Dictionary = {}
	var tile_transforms_by_id: Dictionary = {}
	var terrain_arr: Array = data.get("terrain", []) as Array

	for item: Variant in terrain_arr:
		if item is Dictionary:
			var td: Dictionary = item as Dictionary
			var gx: int = int(td.get("gx", 0))
			var gz: int = int(td.get("gz", 0))
			var t_id: String = String(td.get("tile_id", "island_center"))
			if not _tile_meshes.has(t_id):
				t_id = "island_center"
			var t_rot: int = int(td.get("rot", 0))
			var cell: Vector2i = Vector2i(gx, gz)
			occupied_cells[cell] = { "tile_id": t_id, "rot": t_rot }

			var t_pos: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, cell_size)
			var t_basis: Basis = Basis(Vector3.UP, deg_to_rad(float(t_rot)))
			var t_xform: Transform3D = Transform3D(t_basis, t_pos)

			if not tile_transforms_by_id.has(t_id):
				var list_new: Array[Transform3D] = []
				tile_transforms_by_id[t_id] = list_new
			(tile_transforms_by_id[t_id] as Array[Transform3D]).append(t_xform)

	for tile_key: Variant in tile_transforms_by_id.keys():
		var t_id: String = String(tile_key)
		var xforms: Array[Transform3D] = tile_transforms_by_id[t_id] as Array[Transform3D]
		if xforms.is_empty():
			continue
		var tile_mesh: ArrayMesh = _tile_meshes.get(t_id, null) as ArrayMesh
		if tile_mesh == null:
			continue

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = tile_mesh
		mm.instance_count = xforms.size()
		for i: int in range(xforms.size()):
			mm.set_instance_transform(i, xforms[i])

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "TileMMI_%s" % t_id
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mmi)

	# 2. Contenção costeira unificada + espuma + 1 único colisor de piso para toda a ilha
	var coastal_body: StaticBody3D = StaticBody3D.new()
	coastal_body.name = "CoastalLimits"
	coastal_body.collision_layer = 1
	coastal_body.collision_mask = 0
	add_child(coastal_body)
	LevelJsonLoader.build_coastal_colliders_and_foam(coastal_body, occupied_cells, width, height, cell_size)

	var floor_col: CollisionShape3D = CollisionShape3D.new()
	floor_col.name = "IslandFloorCollider"
	var floor_box: BoxShape3D = BoxShape3D.new()
	floor_box.size = Vector3(float(width) * cell_size + 4.0, 0.72, float(height) * cell_size + 4.0)
	floor_col.shape = floor_box
	floor_col.position = Vector3(0.0, -0.36, 0.0)
	coastal_body.add_child(floor_col)

	# 3. Processa objetos (rochas e vegetação)
	var goals: Dictionary = {}
	var objects_arr: Array = data.get("objects", []) as Array

	# Instancia rochas (obstáculos sólidos da Layer 4) e flores (objetos de tile 0.80m)
	var rock_cells: Dictionary = {}
	var flower_cells: Dictionary = {}
	for item: Variant in objects_arr:
		if item is Dictionary:
			var od: Dictionary = item as Dictionary
			var o_type: String = String(od.get("type", ""))
			var gx: int = int(od.get("gx", 0))
			var gz: int = int(od.get("gz", 0))
			var o_rot: int = int(od.get("rot", 0))
			if o_type == "rock":
				var base_pos: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, cell_size)
				rock_cells[Vector2i(gx, gz)] = true
				var rock_inst: Node3D = LevelJsonLoader.instantiate_object_node("rock", o_rot)
				if rock_inst != null:
					rock_inst.position = base_pos
					if obstacles_container != null:
						obstacles_container.add_child(rock_inst)
					else:
						add_child(rock_inst)
			elif o_type == "flower":
				flower_cells[Vector2i(gx, gz)] = o_rot

	# 4. Campo de Vegetação Vetorial v3 ou legado convertido
	var vector_field: RefCounted = null
	if data.has("grass_vectors") and data["grass_vectors"] is Array:
		vector_field = VectorGrassFieldScript.new()
		vector_field.from_dict_list(data["grass_vectors"] as Array)
	else:
		# Modo Legado v1/v2: carrega o campo discreto e converte para polígonos vetoriais
		var veg_field: RefCounted = null
		if data.has("vegetation") and data["vegetation"] is Dictionary:
			var vdict: Dictionary = data["vegetation"] as Dictionary
			var rows_arr: Array = vdict.get("rows", []) as Array
			veg_field = VegetationFieldScript.new(width, height)
			veg_field.call("from_rows", rows_arr)
		else:
			veg_field = VegetationFieldScript.new(width, height)
			veg_field.call("from_legacy_objects", objects_arr, width, height)

		# Remove vegetação sob células ocupadas por rochas
		for r_cell: Vector2i in rock_cells.keys():
			var base_cx: int = r_cell.x * 4
			var base_cz: int = r_cell.y * 4
			for dz: int in range(4):
				for dx: int in range(4):
					veg_field.call("set_cell", base_cx + dx, base_cz + dz, 0)

		vector_field = VectorGrassFieldScript.new()
		vector_field.convert_from_legacy_field(veg_field, width, height, cell_size)

	# Remove polígonos sob rochas no campo vetorial (se houver rochas)
	for r_cell: Vector2i in rock_cells.keys():
		var r_pos: Vector3 = LevelJsonLoader.grid_to_world(r_cell.x, r_cell.y, width, height, cell_size)
		var rock_clip_poly: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
			BrushPatterns.ShapeType.CIRCLE,
			1,
			Vector2(r_pos.x, r_pos.z)
		)
		vector_field.clip_shapes(rock_clip_poly)

	# Constrói MultiMeshes e grade espacial a partir do campo vetorial
	goals = _build_from_vector_field(vector_field, width, height, cell_size, flower_cells)

	# 5. Posiciona o cortador no spawn
	var spawn_dict: Dictionary = data.get("spawn", {}) as Dictionary
	var sp_x: int = int(spawn_dict.get("gx", int(float(width) / 2.0)))
	var sp_z: int = int(spawn_dict.get("gz", int(float(height) / 2.0)))
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_x, sp_z, width, height, cell_size)
	if cutter != null:
		cutter.position = Vector3(sp_world.x, 0.1, sp_world.z)
		if cutter.has_method("reset_orientation_to_camera"):
			cutter.reset_orientation_to_camera()
		if "vegetation_grid" in cutter:
			cutter.set("vegetation_grid", self)

	if goals.is_empty():
		goals = { "grass": 1 }

	return goals


static func _resolve_clipping_color(v_type: String) -> Color:
	match v_type:
		"grass_green":
			return Color(0.12, 0.36, 0.12, 1.0)
		"grass_yellow":
			return Color(0.56, 0.44, 0.08, 1.0)
		"grass_blue":
			return Color(0.10, 0.28, 0.42, 1.0)
		"grass_purple":
			return Color(0.32, 0.14, 0.38, 1.0)
		"grass_white":
			return Color(0.62, 0.68, 0.60, 1.0)
		"grass_red":
			return Color(0.48, 0.14, 0.12, 1.0)
		"grass_black":
			return Color(0.12, 0.14, 0.12, 1.0)
		"wheat":
			return Color(0.64, 0.46, 0.10, 1.0)
		"flower":
			return Color(0.85, 0.22, 0.55, 1.0)
		_:
			return Color(0.12, 0.36, 0.12, 1.0)


static func _get_or_create_clippings_mesh(v_type: String) -> ArrayMesh:
	if _clipping_meshes.has(v_type):
		return _clipping_meshes[v_type] as ArrayMesh

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var leaf_color: Color = _resolve_clipping_color(v_type)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = leaf_color
	mat.roughness = 0.90
	mat.cull_mode = BaseMaterial3D.CULL_BACK
	st.set_material(mat)

	# 6 lâminas fatiadas deitadas no plano XZ em posições e orientações aleatórias
	var leaf_configs: Array[Vector4] = [
		Vector4(0.04, 0.05, 0.12, 0.45),
		Vector4(-0.06, 0.03, 0.10, 1.85),
		Vector4(0.05, -0.06, 0.11, 2.75),
		Vector4(-0.05, -0.05, 0.13, 3.90),
		Vector4(0.00, 0.08, 0.09, 5.10),
		Vector4(-0.02, -0.09, 0.11, 0.95)
	]

	for cfg: Vector4 in leaf_configs:
		var cx: float = cfg.x
		var cz: float = cfg.y
		var length: float = cfg.z
		var angle: float = cfg.w
		var half_w: float = 0.013 # largura 2.6cm

		var fwd := Vector3(cos(angle), 0.0, sin(angle))
		var right := Vector3(-sin(angle), 0.0, cos(angle))
		var center := Vector3(cx, 0.005, cz)

		# 4 vértices do losango fino deitado no chão
		var p_back := center - fwd * (length * 0.45)
		var p_left := center + right * half_w
		var p_front := center + fwd * (length * 0.55)
		var p_right := center - right * half_w

		st.set_normal(Vector3.UP)
		st.set_color(leaf_color)

		# Triângulo 1: back, front, left (anti-horário olhando de cima)
		st.add_vertex(p_back)
		st.add_vertex(p_front)
		st.add_vertex(p_left)

		# Triângulo 2: back, right, front
		st.add_vertex(p_back)
		st.add_vertex(p_right)
		st.add_vertex(p_front)

	var mesh: ArrayMesh = st.commit()
	_clipping_meshes[v_type] = mesh
	return mesh


func _build_from_vector_field(
	vector_field: RefCounted,
	width_blocks: int,
	height_blocks: int,
	block_cell_size: float,
	tile_flowers: Dictionary = {}
) -> Dictionary:
	var goals: Dictionary = {}
	if vector_field == null:
		return goals

	var sampled_tufts: Array = vector_field.call("sample_all_tufts") as Array
	var tufts: Array[Dictionary] = []
	for item: Variant in sampled_tufts:
		if item is Dictionary:
			tufts.append(item as Dictionary)

	# Adiciona flores de tile caso existam no JSON
	for f_cell: Vector2i in tile_flowers.keys():
		var f_pos: Vector3 = LevelJsonLoader.grid_to_world(f_cell.x, f_cell.y, width_blocks, height_blocks, block_cell_size)
		tufts.append({
			"pos": f_pos,
			"type": "flower",
			"scale_factor": 1.0,
			"seed": float(f_cell.x * 79 + f_cell.y * 31)
		})

	# Agrupa por célula lógica de 0.40m para manter metas consistentes e pontuação justa
	var logical_cells_map: Dictionary = {}
	for t_dict: Dictionary in tufts:
		var pos: Vector3 = t_dict["pos"] as Vector3
		var lx: int = roundi(pos.x / 0.40)
		var lz: int = roundi(pos.z / 0.40)
		var lkey: Vector2i = Vector2i(lx, lz)
		if not logical_cells_map.has(lkey):
			var new_cell_idx: int = _cell_keys.size()
			var v_type: String = String(t_dict.get("type", "grass_green"))
			var g_key: String = "grass"
			var r_coins: int = 1
			if v_type == "wheat":
				g_key = "wheat"
				r_coins = 3
			elif v_type == "flower":
				g_key = "flower"
				r_coins = 5

			logical_cells_map[lkey] = new_cell_idx
			_cell_keys.append(g_key)
			_cell_rewards.append(r_coins)
			_cell_remaining_tufts.append(0)
			_cell_is_completed.append(0)
			goals[g_key] = goals.get(g_key, 0) + 1

		var c_idx: int = int(logical_cells_map[lkey])
		t_dict["cell_idx"] = c_idx

	# Agrupa por tipo de vegetação para alimentar os MultiMeshes
	var tufts_by_type: Dictionary = {}
	for vt: String in VEG_TYPES:
		var empty_list: Array[Dictionary] = []
		tufts_by_type[vt] = empty_list

	for t_dict: Dictionary in tufts:
		var vt: String = String(t_dict.get("type", "grass_green"))
		if not tufts_by_type.has(vt):
			vt = "grass_green"
		(tufts_by_type[vt] as Array[Dictionary]).append(t_dict)
		var c_idx: int = int(t_dict["cell_idx"])
		_cell_remaining_tufts[c_idx] = _cell_remaining_tufts[c_idx] + 1

	# Constrói MultiMeshes por tipo
	_veg_multimeshes.resize(VEG_TYPES.size())
	_veg_mmi_nodes.resize(VEG_TYPES.size())
	_clipping_multimeshes.resize(VEG_TYPES.size())
	_clipping_mmi_nodes.resize(VEG_TYPES.size())
	_clipping_counts.resize(VEG_TYPES.size())
	_clipping_counts.fill(0)

	for mmi_idx: int in range(VEG_TYPES.size()):
		var v_type: String = VEG_TYPES[mmi_idx]
		var entry_list: Array[Dictionary] = tufts_by_type.get(v_type, []) as Array[Dictionary]
		var count: int = entry_list.size()

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		if v_type == "flower":
			mm.mesh = _flower_mesh
		else:
			mm.mesh = _grass_mesh
		mm.instance_count = count

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "VegMMI_%s" % v_type
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if GRASS_MATERIALS.has(v_type):
			mmi.material_override = GRASS_MATERIALS[v_type] as Material
		add_child(mmi)

		var clip_mm: MultiMesh = MultiMesh.new()
		clip_mm.transform_format = MultiMesh.TRANSFORM_3D
		clip_mm.mesh = _get_or_create_clippings_mesh(v_type)
		clip_mm.instance_count = count
		clip_mm.visible_instance_count = 0

		var clip_mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		clip_mmi.name = "ClippingsMMI_%s" % v_type
		clip_mmi.multimesh = clip_mm
		clip_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(clip_mmi)

		_veg_multimeshes[mmi_idx] = mm
		_veg_mmi_nodes[mmi_idx] = mmi
		_clipping_multimeshes[mmi_idx] = clip_mm
		_clipping_mmi_nodes[mmi_idx] = clip_mmi

		var is_grass: bool = (v_type != "wheat" and v_type != "flower")
		var max_hp: int = 1 if is_grass else 2
		var p_col: Color = _resolve_type_particle_color(v_type)

		for inst_idx: int in range(count):
			var entry: Dictionary = entry_list[inst_idx]
			var pos: Vector3 = entry["pos"] as Vector3
			var cell_idx: int = int(entry["cell_idx"])
			var s_seed: float = float(entry["seed"])
			var scale_factor: float = float(entry.get("scale_factor", 1.0))

			var random_rot: float = fmod(s_seed * 1.618, TAU)

			var scale_vec: Vector3
			if is_grass:
				var scale_y: float = lerpf(0.48, 0.62, scale_factor) * (0.95 + fmod(s_seed * 0.13, 0.10))
				var scale_xz: float = lerpf(0.32, 0.44, scale_factor) * (0.95 + fmod(s_seed * 0.27, 0.10))
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			elif v_type == "wheat":
				var scale_y: float = lerpf(0.55, 0.70, scale_factor) * (0.95 + fmod(s_seed * 0.13, 0.10))
				var scale_xz: float = lerpf(0.34, 0.46, scale_factor) * (0.95 + fmod(s_seed * 0.27, 0.10))
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			else:
				var sf: float = 0.52 * scale_factor
				scale_vec = Vector3(sf, sf, sf)

			var inst_basis: Basis = Basis(Vector3.UP, random_rot) * Basis.from_scale(scale_vec)
			var xform: Transform3D = Transform3D(inst_basis, pos)
			mm.set_instance_transform(inst_idx, xform)
			clip_mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)

			var cut_xform: Transform3D = Transform3D(Basis(Vector3.UP, random_rot), pos)

			var p_idx: int = _positions.size()
			_positions.append(pos)
			_initial_transforms.append(xform)
			_cut_transforms.append(cut_xform)
			_mmi_indices.append(mmi_idx)
			_instance_indices.append(inst_idx)
			_health.append(max_hp)
			_max_health.append(max_hp)
			_coin_rewards.append(1)
			_is_cut.append(0)
			_is_hidden_by_density.append(0)
			_last_hit_time.append(-10.0)
			_plant_keys.append(_cell_keys[cell_idx])
			_particle_colors.append(p_col)
			_tuft_logical_cell.append(cell_idx)

			# Adiciona à grade de colisão 0.40m
			var cell_key: Vector2i = Vector2i(roundi(pos.x / GRID_STEP), roundi(pos.z / GRID_STEP))
			if not _grid.has(cell_key):
				var bucket_new: PackedInt32Array = PackedInt32Array()
				bucket_new.append(p_idx)
				_grid[cell_key] = bucket_new
			else:
				var bucket: PackedInt32Array = _grid[cell_key] as PackedInt32Array
				bucket.append(p_idx)
				_grid[cell_key] = bucket

	# Unifica contagem de metas: 10 tufos físicos = 1 unidade virtual de meta
	_total_physical_grass = 0
	_total_physical_wheat = 0
	_total_physical_flower = 0
	for p_idx: int in range(_positions.size()):
		var pk: String = _plant_keys[p_idx]
		if pk == "wheat":
			_total_physical_wheat += 1
		elif pk == "flower":
			_total_physical_flower += 1
		else:
			_total_physical_grass += 1

	_remaining_physical_grass = _total_physical_grass
	_remaining_physical_wheat = _total_physical_wheat
	_remaining_physical_flower = _total_physical_flower
	_grass_cut_accumulator = 0
	_wheat_cut_accumulator = 0

	goals.clear()
	goals["grass"] = maxi(1, int(ceilf(float(_total_physical_grass) / 10.0)))
	if _total_physical_wheat > 0:
		goals["wheat"] = maxi(1, int(ceilf(float(_total_physical_wheat) / 10.0)))
	if _total_physical_flower > 0:
		goals["flower"] = _total_physical_flower

	return goals


func _build_from_vegetation_field(
	field: RefCounted,
	width_blocks: int,
	height_blocks: int,
	block_cell_size: float,
	tile_flowers: Dictionary = {}
) -> Dictionary:
	var goals: Dictionary = {}
	var cols: int = int(field.get("cols"))
	var rows: int = int(field.get("rows"))
	var sdf: PackedFloat32Array = field.call("compute_sdf_depth_map") as PackedFloat32Array

	# Agrupa subcélulas por célula lógica de 0.40m: Vector2i(lx, lz) onde lx = cx / 2, lz = cz / 2
	var logical_subcells: Dictionary = {}
	for r: int in range(rows):
		for c: int in range(cols):
			var t_id: int = int(field.call("get_cell", c, r))
			if t_id == 0:
				continue
			var lx: int = c >> 1
			var lz: int = r >> 1
			var lkey: Vector2i = Vector2i(lx, lz)
			if not logical_subcells.has(lkey):
				var list_new: Array[Vector2i] = []
				logical_subcells[lkey] = list_new
			(logical_subcells[lkey] as Array[Vector2i]).append(Vector2i(c, r))

	# Determina tipo lógico, meta e recompensa por célula de 0.40m
	var cell_indices_by_key: Dictionary = {}
	for lkey: Vector2i in logical_subcells.keys():
		var subs: Array[Vector2i] = logical_subcells[lkey] as Array[Vector2i]
		var type_counts: Dictionary = {}
		for sub_c: Vector2i in subs:
			var tid: int = int(field.call("get_cell", sub_c.x, sub_c.y))
			type_counts[tid] = int(type_counts.get(tid, 0)) + 1

		# Prioridade: flower (9) > wheat (8) > maioria das gramas
		var chosen_tid: int = 1
		if type_counts.has(9):
			chosen_tid = 9
		elif type_counts.has(8):
			chosen_tid = 8
		else:
			var max_c: int = 0
			for tid_cand: int in type_counts.keys():
				var c_cnt: int = int(type_counts[tid_cand])
				if c_cnt > max_c:
					max_c = c_cnt
					chosen_tid = tid_cand

		var cell_idx: int = _cell_remaining_tufts.size()
		cell_indices_by_key[lkey] = cell_idx

		var p_key: String = "grass"
		var reward: int = 1
		if chosen_tid == 8:
			p_key = "wheat"
			reward = 3
		elif chosen_tid == 9:
			p_key = "flower"
			reward = 5

		goals[p_key] = int(goals.get(p_key, 0)) + 1

		_cell_keys.append(p_key)
		_cell_rewards.append(reward)
		_cell_is_completed.append(0)
		# Inicializa com 0 tufos; será incrementado ao criar cada micro-tufo
		_cell_remaining_tufts.append(0)

	# Agrupa posições e escalas dos micro-tufos por mmi_type
	var tufts_by_type: Dictionary = {}
	for v_type: String in VEG_TYPES:
		var empty_list: Array[Dictionary] = []
		tufts_by_type[v_type] = empty_list

	# Adiciona flores de tile (0.80m) como objetos discretos com sua própria célula lógica
	for f_cell: Vector2i in tile_flowers.keys():
		var cell_idx: int = _cell_remaining_tufts.size()
		var flower_pos: Vector3 = LevelJsonLoader.grid_to_world(f_cell.x, f_cell.y, width_blocks, height_blocks, block_cell_size)
		goals["flower"] = int(goals.get("flower", 0)) + 1
		_cell_keys.append("flower")
		_cell_rewards.append(5)
		_cell_is_completed.append(0)
		_cell_remaining_tufts.append(1)

		var f_entry: Dictionary = {
			"pos": flower_pos,
			"cell_idx": cell_idx,
			"tid": 9,
			"sdf": 0.50,
			"seed": float(f_cell.x * 79 + f_cell.y * 31)
		}
		(tufts_by_type["flower"] as Array[Dictionary]).append(f_entry)

	var processed_flowers: Dictionary = {}

	for lkey: Vector2i in logical_subcells.keys():
		var cell_idx: int = int(cell_indices_by_key[lkey])
		var subs: Array[Vector2i] = logical_subcells[lkey] as Array[Vector2i]

		for sub_c: Vector2i in subs:
			var tid: int = int(field.call("get_cell", sub_c.x, sub_c.y))
			if tid == 0:
				continue
			var v_type: String = VegetationFieldScript.type_id_to_name(tid)
			if not tufts_by_type.has(v_type):
				v_type = "grass_green"

			if tid == 9:
				# Flor: 1 única instância centralizada por bloco lógico de 0.40m
				if processed_flowers.has(lkey):
					continue
				processed_flowers[lkey] = true
				var flower_pos: Vector3 = field.call("cell_to_world", lkey.x * 2, lkey.y * 2, block_cell_size) as Vector3
				flower_pos.x += 0.10
				flower_pos.z += 0.10

				var f_entry: Dictionary = {
					"pos": flower_pos,
					"cell_idx": cell_idx,
					"tid": tid,
					"sdf": 0.50, # centro sempre farto
					"seed": float(lkey.x * 79 + lkey.y * 31)
				}
				(tufts_by_type["flower"] as Array[Dictionary]).append(f_entry)
				_cell_remaining_tufts[cell_idx] = _cell_remaining_tufts[cell_idx] + 1
				continue

			# Micro-tufo comum (gramas e trigo)
			var base_pos: Vector3 = field.call("cell_to_world", sub_c.x, sub_c.y, block_cell_size) as Vector3
			var sub_seed: float = float(sub_c.x * 73 + sub_c.y * 19)
			# Jitter determinístico de até +-0.06m para aparência orgânica
			var j_x: float = (fmod(sub_seed * 0.17, 1.0) - 0.5) * 0.12
			var j_z: float = (fmod(sub_seed * 0.31, 1.0) - 0.5) * 0.12
			var tuft_pos: Vector3 = base_pos + Vector3(j_x, 0.0, j_z)

			var sdf_dist: float = sdf[sub_c.y * cols + sub_c.x]

			var t_entry: Dictionary = {
				"pos": tuft_pos,
				"cell_idx": cell_idx,
				"tid": tid,
				"sdf": sdf_dist,
				"seed": sub_seed
			}
			(tufts_by_type[v_type] as Array[Dictionary]).append(t_entry)
			_cell_remaining_tufts[cell_idx] = _cell_remaining_tufts[cell_idx] + 1

	# Constrói MultiMeshes por tipo
	_veg_multimeshes.resize(VEG_TYPES.size())
	_veg_mmi_nodes.resize(VEG_TYPES.size())
	_clipping_multimeshes.resize(VEG_TYPES.size())
	_clipping_mmi_nodes.resize(VEG_TYPES.size())
	_clipping_counts.resize(VEG_TYPES.size())
	_clipping_counts.fill(0)

	for mmi_idx: int in range(VEG_TYPES.size()):
		var v_type: String = VEG_TYPES[mmi_idx]
		var entry_list: Array[Dictionary] = tufts_by_type.get(v_type, []) as Array[Dictionary]
		var count: int = entry_list.size()

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		if v_type == "flower":
			mm.mesh = _flower_mesh
		else:
			mm.mesh = _grass_mesh
		mm.instance_count = count

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "VegMMI_%s" % v_type
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if GRASS_MATERIALS.has(v_type):
			mmi.material_override = GRASS_MATERIALS[v_type] as Material
		add_child(mmi)

		var clip_mm: MultiMesh = MultiMesh.new()
		clip_mm.transform_format = MultiMesh.TRANSFORM_3D
		clip_mm.mesh = _get_or_create_clippings_mesh(v_type)
		clip_mm.instance_count = count
		clip_mm.visible_instance_count = 0

		var clip_mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		clip_mmi.name = "ClippingsMMI_%s" % v_type
		clip_mmi.multimesh = clip_mm
		clip_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(clip_mmi)

		_veg_multimeshes[mmi_idx] = mm
		_veg_mmi_nodes[mmi_idx] = mmi
		_clipping_multimeshes[mmi_idx] = clip_mm
		_clipping_mmi_nodes[mmi_idx] = clip_mmi

		var is_grass: bool = (v_type != "wheat" and v_type != "flower")
		var max_hp: int = 1 if is_grass else 2
		var p_col: Color = _resolve_type_particle_color(v_type)

		for inst_idx: int in range(count):
			var entry: Dictionary = entry_list[inst_idx]
			var pos: Vector3 = entry["pos"] as Vector3
			var cell_idx: int = int(entry["cell_idx"])
			var s_seed: float = float(entry["seed"])
			var dist_m: float = float(entry["sdf"])

			# Afinamento suave de borda por SDF (envelhecimento/diminuição de escala na fronteira vazia)
			var edge_t: float = smoothstep(0.0, 0.28, dist_m)
			var random_rot: float = fmod(s_seed * 1.618, TAU)

			var scale_vec: Vector3
			if is_grass:
				var scale_y: float = lerpf(0.48, 0.62, edge_t) * (0.95 + fmod(s_seed * 0.13, 0.10))
				var scale_xz: float = lerpf(0.32, 0.44, edge_t) * (0.95 + fmod(s_seed * 0.27, 0.10))
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			elif v_type == "wheat":
				var scale_y: float = lerpf(0.55, 0.70, edge_t) * (0.95 + fmod(s_seed * 0.13, 0.10))
				var scale_xz: float = lerpf(0.34, 0.46, edge_t) * (0.95 + fmod(s_seed * 0.27, 0.10))
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			else:
				# Flor
				var sf: float = 0.52
				scale_vec = Vector3(sf, sf, sf)

			var inst_basis: Basis = Basis(Vector3.UP, random_rot) * Basis.from_scale(scale_vec)
			var xform: Transform3D = Transform3D(inst_basis, pos)
			mm.set_instance_transform(inst_idx, xform)
			clip_mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)

			var cut_xform: Transform3D = Transform3D(Basis(Vector3.UP, random_rot), pos)

			var p_idx: int = _positions.size()
			_positions.append(pos)
			_initial_transforms.append(xform)
			_cut_transforms.append(cut_xform)
			_mmi_indices.append(mmi_idx)
			_instance_indices.append(inst_idx)
			_health.append(max_hp)
			_max_health.append(max_hp)
			_coin_rewards.append(1) # a recompensa total é gerenciada por célula lógica
			_is_cut.append(0)
			_is_hidden_by_density.append(0)
			_last_hit_time.append(-10.0)
			_plant_keys.append(_cell_keys[cell_idx])
			_particle_colors.append(p_col)
			_tuft_logical_cell.append(cell_idx)

			# Adiciona à grade de colisão 0.40m
			var cell_key: Vector2i = Vector2i(roundi(pos.x / GRID_STEP), roundi(pos.z / GRID_STEP))
			if not _grid.has(cell_key):
				var bucket_new: PackedInt32Array = PackedInt32Array()
				bucket_new.append(p_idx)
				_grid[cell_key] = bucket_new
			else:
				var bucket: PackedInt32Array = _grid[cell_key] as PackedInt32Array
				bucket.append(p_idx)
				_grid[cell_key] = bucket

	# Unifica contagem de metas: 10 tufos físicos = 1 unidade virtual de meta
	_total_physical_grass = 0
	_total_physical_wheat = 0
	_total_physical_flower = 0
	for p_idx: int in range(_positions.size()):
		var pk: String = _plant_keys[p_idx]
		if pk == "wheat":
			_total_physical_wheat += 1
		elif pk == "flower":
			_total_physical_flower += 1
		else:
			_total_physical_grass += 1

	_remaining_physical_grass = _total_physical_grass
	_remaining_physical_wheat = _total_physical_wheat
	_remaining_physical_flower = _total_physical_flower
	_grass_cut_accumulator = 0
	_wheat_cut_accumulator = 0

	goals.clear()
	goals["grass"] = maxi(1, int(ceilf(float(_total_physical_grass) / 10.0)))
	if _total_physical_wheat > 0:
		goals["wheat"] = maxi(1, int(ceilf(float(_total_physical_wheat) / 10.0)))
	if _total_physical_flower > 0:
		goals["flower"] = _total_physical_flower

	return goals


func _setup_lawn_decal_and_trail(
	field: RefCounted,
	width_blocks: int,
	height_blocks: int,
	block_cell_size: float
) -> void:
	if field == null:
		return

	var total_w_m: float = float(width_blocks) * block_cell_size
	var total_h_m: float = float(height_blocks) * block_cell_size
	var origin_2d: Vector2 = Vector2(-total_w_m * 0.5, -total_h_m * 0.5)
	var size_2d: Vector2 = Vector2(total_w_m, total_h_m)

	# Instancia o gerenciador de trilha por SubViewport
	_lawn_cut_trail = LawnCutTrailScript.new(origin_2d, size_2d) as Node3D
	_lawn_cut_trail.name = "LawnCutTrail"
	add_child(_lawn_cut_trail)

	# Gera textura de densidade colorida a partir do campo
	var density_img: Image = field.call("to_density_image") as Image
	var density_tex: ImageTexture = ImageTexture.create_from_image(density_img)

	# Cria malha plana cobrindo toda a ilha
	var plane_mesh: PlaneMesh = PlaneMesh.new()
	plane_mesh.size = size_2d

	var decal_mat: ShaderMaterial = ShaderMaterial.new()
	var decal_shader: Shader = preload("res://shaders/lawn_base_decal.gdshader")
	decal_mat.shader = decal_shader
	decal_mat.set_shader_parameter("density_tex", density_tex)
	var trail_tex: ViewportTexture = _lawn_cut_trail.call("get_trail_texture") as ViewportTexture
	if trail_tex != null:
		decal_mat.set_shader_parameter("cut_tex", trail_tex)
	decal_mat.set_shader_parameter("island_origin", origin_2d)
	decal_mat.set_shader_parameter("island_size", size_2d)

	_lawn_decal_mesh = MeshInstance3D.new()
	_lawn_decal_mesh.name = "LawnBaseDecal"
	_lawn_decal_mesh.mesh = plane_mesh
	_lawn_decal_mesh.material_override = decal_mat
	_lawn_decal_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_lawn_decal_mesh.position = Vector3(0.0, 0.005, 0.0)
	add_child(_lawn_decal_mesh)


func _resolve_type_particle_color(v_type: String) -> Color:
	if GRASS_MATERIALS.has(v_type):
		var sm: ShaderMaterial = GRASS_MATERIALS[v_type] as ShaderMaterial
		if sm != null:
			var col_variant: Variant = sm.get_shader_parameter("color_top")
			if col_variant is Color:
				return col_variant as Color
	if v_type == "wheat":
		return Color(0.96, 0.75, 0.15, 1.0)
	if v_type == "flower":
		return Color(0.95, 0.35, 0.65, 1.0)
	return Color(0.25, 0.75, 0.3, 1.0)


func cut_in_circle(center: Vector3, blade_radius: float, power: int) -> void:
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
		return

	# Pinta a trilha contínua da serra no solo
	if _lawn_cut_trail != null and is_instance_valid(_lawn_cut_trail):
		_lawn_cut_trail.call("paint", center, blade_radius)

	var hit_radius: float = blade_radius + TUFT_HIT_RADIUS_BONUS
	var hit_radius_sq: float = hit_radius * hit_radius
	var min_cx: int = floori((center.x - hit_radius) / GRID_STEP)
	var max_cx: int = ceili((center.x + hit_radius) / GRID_STEP)
	var min_cz: int = floori((center.z - hit_radius) / GRID_STEP)
	var max_cz: int = ceili((center.z + hit_radius) / GRID_STEP)

	var now_sec: float = float(Time.get_ticks_msec()) * 0.001

	for cx: int in range(min_cx, max_cx + 1):
		for cz: int in range(min_cz, max_cz + 1):
			var cell_key: Vector2i = Vector2i(cx, cz)
			if not _grid.has(cell_key):
				continue
			var bucket: PackedInt32Array = _grid[cell_key] as PackedInt32Array
			for i: int in range(bucket.size()):
				var p_idx: int = bucket[i]
				if _is_cut[p_idx] == 1 or _is_hidden_by_density[p_idx] == 1:
					continue

				var p_pos: Vector3 = _positions[p_idx]
				var dx: float = p_pos.x - center.x
				var dz: float = p_pos.z - center.z
				if dx * dx + dz * dz > hit_radius_sq:
					continue

				if now_sec - _last_hit_time[p_idx] < MULTI_HIT_COOLDOWN_SEC:
					continue

				_last_hit_time[p_idx] = now_sec
				var new_hp: int = _health[p_idx] - power
				_health[p_idx] = new_hp

				var mmi_idx: int = _mmi_indices[p_idx]
				var inst_idx: int = _instance_indices[p_idx]
				var mm: MultiMesh = _veg_multimeshes[mmi_idx]

				if new_hp <= 0:
					_is_cut[p_idx] = 1
					if mm != null:
						mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)
					var clip_mm: MultiMesh = _clipping_multimeshes[mmi_idx]
					if clip_mm != null:
						var c_idx: int = _clipping_counts[mmi_idx] if mmi_idx < _clipping_counts.size() else 0
						if c_idx < clip_mm.instance_count:
							clip_mm.set_instance_transform(c_idx, _cut_transforms[p_idx])
							c_idx += 1
							if mmi_idx < _clipping_counts.size():
								_clipping_counts[mmi_idx] = c_idx
							clip_mm.visible_instance_count = c_idx
					_spawn_cut_particles_at(p_pos, _particle_colors[p_idx])

					# Acumulador unificado: 10 tufos físicos = 1 unidade de meta
					var p_key: String = _plant_keys[p_idx]
					if p_key == "wheat":
						_remaining_physical_wheat = maxi(0, _remaining_physical_wheat - 1)
						_wheat_cut_accumulator += 1
						if _wheat_cut_accumulator >= 10:
							_wheat_cut_accumulator -= 10
							if GameManager != null:
								GameManager.register_cut("wheat", 3, p_pos)
						elif _remaining_physical_wheat <= 0 and _wheat_cut_accumulator > 0:
							_wheat_cut_accumulator = 0
							if GameManager != null and _get_remaining_goal_safe("wheat") > 0:
								GameManager.register_cut("wheat", 3, p_pos)
					elif p_key == "flower":
						_remaining_physical_flower = maxi(0, _remaining_physical_flower - 1)
						if GameManager != null:
							GameManager.register_cut("flower", 5, p_pos)
					else:
						# Qualquer tipo/cor de grama
						_remaining_physical_grass = maxi(0, _remaining_physical_grass - 1)
						_grass_cut_accumulator += 1
						if _grass_cut_accumulator >= 10:
							_grass_cut_accumulator -= 10
							if GameManager != null:
								GameManager.register_cut("grass", 1, p_pos)
						elif _remaining_physical_grass <= 0 and _grass_cut_accumulator > 0:
							_grass_cut_accumulator = 0
							if GameManager != null and _get_remaining_goal_safe("grass") > 0:
								GameManager.register_cut("grass", 1, p_pos)

					# Proteção anti-trava: se todos os tufos físicos foram ceifados, fecha metas residuais
					if _remaining_physical_grass <= 0 and _remaining_physical_wheat <= 0 and _remaining_physical_flower <= 0:
						if GameManager != null:
							while _get_remaining_goal_safe("grass") > 0:
								GameManager.register_cut("grass", 1, p_pos)
							while _get_remaining_goal_safe("wheat") > 0:
								GameManager.register_cut("wheat", 3, p_pos)
							while _get_remaining_goal_safe("flower") > 0:
								GameManager.register_cut("flower", 5, p_pos)
				else:
					if mm != null:
						var init_xform: Transform3D = _initial_transforms[p_idx]
						var squash_xform: Transform3D = Transform3D(
							init_xform.basis.scaled(Vector3(1.25, 1.25, 1.25)),
							init_xform.origin
						)
						mm.set_instance_transform(inst_idx, squash_xform)
					var tree: SceneTree = get_tree()
					if tree != null:
						tree.create_timer(0.08).timeout.connect(_restore_plant_transform.bind(p_idx))


func _restore_plant_transform(p_idx: int) -> void:
	if p_idx < 0 or p_idx >= _positions.size():
		return
	if _is_cut[p_idx] == 0 and _is_hidden_by_density[p_idx] == 0:
		var mmi_idx: int = _mmi_indices[p_idx]
		var inst_idx: int = _instance_indices[p_idx]
		var mm: MultiMesh = _veg_multimeshes[mmi_idx]
		if mm != null:
			mm.set_instance_transform(inst_idx, _initial_transforms[p_idx])


func _spawn_cut_particles_at(world_pos: Vector3, col: Color) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var scene_root: Node = tree.current_scene
	if scene_root == null:
		scene_root = self

	if PlantScript._particle_pool.is_empty() or not is_instance_valid(PlantScript._particle_pool[0]) or not PlantScript._particle_pool[0].is_inside_tree():
		PlantScript._init_particle_pool(scene_root)

	var emitter: CPUParticles3D = PlantScript._particle_pool[PlantScript._pool_idx]
	PlantScript._pool_idx = (PlantScript._pool_idx + 1) % PlantScript.POOL_SIZE

	emitter.material_override = PlantScript._get_or_create_particle_material(col)
	emitter.global_position = world_pos + Vector3(0.0, 0.15, 0.0)
	emitter.restart()


func get_total_tufts() -> int:
	return _positions.size()


func set_benchmark_visibility(vegetation_on: bool, density_step: int) -> void:
	_last_vegetation_on = vegetation_on
	var step: int = maxi(1, density_step)
	_last_density_step = step

	var total: int = _positions.size()
	for p_idx: int in range(total):
		var visible_by_density: bool = vegetation_on and (p_idx % step == 0)
		_is_hidden_by_density[p_idx] = 0 if visible_by_density else 1

		var mmi_idx: int = _mmi_indices[p_idx]
		var inst_idx: int = _instance_indices[p_idx]
		var mm: MultiMesh = _veg_multimeshes[mmi_idx]
		if mm == null:
			continue

		var clip_mm: MultiMesh = _clipping_multimeshes[mmi_idx]
		if _is_cut[p_idx] == 0 and _is_hidden_by_density[p_idx] == 0:
			mm.set_instance_transform(inst_idx, _initial_transforms[p_idx])
			if clip_mm != null:
				clip_mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)
		elif _is_cut[p_idx] == 1 and _is_hidden_by_density[p_idx] == 0:
			mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)
			if clip_mm != null:
				clip_mm.set_instance_transform(inst_idx, _cut_transforms[p_idx])
		else:
			mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)
			if clip_mm != null:
				clip_mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)

	for mmi_idx: int in range(_clipping_multimeshes.size()):
		var clip_mm: MultiMesh = _clipping_multimeshes[mmi_idx]
		if clip_mm != null:
			if not vegetation_on:
				clip_mm.visible_instance_count = 0
			else:
				var c_cnt: int = _clipping_counts[mmi_idx] if mmi_idx < _clipping_counts.size() else 0
				clip_mm.visible_instance_count = c_cnt


func reset_all_plants() -> void:
	var total: int = _positions.size()
	for p_idx: int in range(total):
		_is_cut[p_idx] = 0
		_health[p_idx] = _max_health[p_idx]
		_last_hit_time[p_idx] = -10.0

	for c_idx: int in range(_cell_is_completed.size()):
		_cell_is_completed[c_idx] = 0

	# Recalcula a contagem de tufos restantes por célula lógica
	for c_idx: int in range(_cell_remaining_tufts.size()):
		_cell_remaining_tufts[c_idx] = 0
	for p_idx: int in range(total):
		var c_idx: int = _tuft_logical_cell[p_idx]
		if c_idx >= 0 and c_idx < _cell_remaining_tufts.size():
			_cell_remaining_tufts[c_idx] = _cell_remaining_tufts[c_idx] + 1

	_remaining_physical_grass = _total_physical_grass
	_remaining_physical_wheat = _total_physical_wheat
	_remaining_physical_flower = _total_physical_flower
	_grass_cut_accumulator = 0
	_wheat_cut_accumulator = 0

	if _lawn_cut_trail != null and is_instance_valid(_lawn_cut_trail):
		_lawn_cut_trail.call("reset_trail")

	for mmi_idx: int in range(_clipping_multimeshes.size()):
		if mmi_idx < _clipping_counts.size():
			_clipping_counts[mmi_idx] = 0
		var clip_mm: MultiMesh = _clipping_multimeshes[mmi_idx]
		if clip_mm != null:
			clip_mm.visible_instance_count = 0

	set_benchmark_visibility(_last_vegetation_on, _last_density_step)


static func _get_remaining_goal_safe(p_type: String) -> int:
	if GameManager == null:
		return 0
	if GameManager.has_method("get_remaining_goal"):
		return GameManager.get_remaining_goal(p_type)
	var g_val: Variant = GameManager.goals.get(p_type, null)
	if g_val is Dictionary:
		var gd: Dictionary = g_val as Dictionary
		return maxi(0, int(gd.get("target", 0)) - int(gd.get("current", 0)))
	elif g_val is int:
		return maxi(0, int(g_val))
	return 0
