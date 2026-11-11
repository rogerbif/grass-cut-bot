extends Node3D

const VegetationFieldScript = preload("res://scripts/level/vegetation_field.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const PlantScript = preload("res://scripts/plants/plant.gd")

const GRASS_MODEL: PackedScene = preload("res://assets/models/grass_01.glb")
const WHEAT_SCENE: PackedScene = preload("res://scenes/plants/wheat_tuft.tscn")
const FLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_tuft.tscn")
const FLOWER_ROSE_SCENE: PackedScene = preload("res://scenes/plants/flower_rose.tscn")
const FLOWER_DAISY_SCENE: PackedScene = preload("res://scenes/plants/flower_daisy.tscn")
const FLOWER_SUNFLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_sunflower.tscn")
const FLOWER_TULIP_SCENE: PackedScene = preload("res://scenes/plants/flower_tulip.tscn")
const FLOWER_BED_SCENE: PackedScene = preload("res://scenes/plants/flower_bed.tscn")

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

const FLOWER_MATERIALS: Dictionary = {
	"flower": preload("res://shaders/interactive_flower_material.tres"),
	"flower_blue": preload("res://shaders/interactive_flower_blue_material.tres"),
	"flower_sunset": preload("res://shaders/interactive_flower_sunset_material.tres"),
	"flower_purple": preload("res://shaders/interactive_flower_purple_material.tres"),
	"flower_white": preload("res://shaders/interactive_flower_white_material.tres"),
	"flower_turquoise": preload("res://shaders/interactive_flower_turquoise_material.tres"),
	"flower_rose": preload("res://shaders/flower_rose_material.tres"),
	"flower_rose_white": preload("res://shaders/flower_rose_white_material.tres"),
	"flower_rose_yellow": preload("res://shaders/flower_rose_yellow_material.tres"),
	"flower_rose_blue": preload("res://shaders/flower_rose_blue_material.tres"),
	"flower_rose_wine": preload("res://shaders/flower_rose_wine_material.tres"),
	"flower_rose_black": preload("res://shaders/flower_rose_black_material.tres"),
	"flower_rose_peach": preload("res://shaders/flower_rose_peach_material.tres"),
	"flower_daisy": preload("res://shaders/flower_daisy_material.tres"),
	"flower_daisy_blue": preload("res://shaders/flower_daisy_blue_material.tres"),
	"flower_daisy_orange": preload("res://shaders/flower_daisy_orange_material.tres"),
	"flower_daisy_yellow": preload("res://shaders/flower_daisy_yellow_material.tres"),
	"flower_daisy_red": preload("res://shaders/flower_daisy_red_material.tres"),
	"flower_daisy_pink": preload("res://shaders/flower_daisy_pink_material.tres"),
	"flower_daisy_bicolor": preload("res://shaders/flower_daisy_bicolor_material.tres"),
	"flower_sunflower": preload("res://shaders/flower_sunflower_material.tres"),
	"flower_tulip": preload("res://shaders/flower_tulip_material.tres"),
	"flower_tulip_yellow": preload("res://shaders/flower_tulip_yellow_material.tres"),
	"flower_tulip_purple": preload("res://shaders/flower_tulip_purple_material.tres"),
	"flower_tulip_orange": preload("res://shaders/flower_tulip_orange_material.tres"),
	"flower_bed": preload("res://shaders/flower_bed_material.tres"),
	"flower_bed_blue": preload("res://shaders/flower_bed_blue_material.tres"),
	"flower_bed_white": preload("res://shaders/flower_bed_white_material.tres")
}
const FLOWER_LEAVES_MATERIAL: Material = preload("res://shaders/interactive_flower_leaves_material.tres")
const FLOWER_STEM_MATERIAL: Material = preload("res://shaders/interactive_flower_stem_material.tres")

const VEG_TYPES: Array[String] = [
	"grass_green",
	"grass_yellow",
	"grass_blue",
	"grass_purple",
	"grass_white",
	"grass_red",
	"grass_black",
	"wheat",
	"flower",
	"flower_blue",
	"flower_sunset",
	"flower_purple",
	"flower_white",
	"flower_turquoise",
	"flower_rose",
	"flower_rose_white",
	"flower_rose_yellow",
	"flower_rose_blue",
	"flower_rose_wine",
	"flower_rose_black",
	"flower_rose_peach",
	"flower_daisy",
	"flower_daisy_blue",
	"flower_daisy_orange",
	"flower_daisy_yellow",
	"flower_daisy_red",
	"flower_daisy_pink",
	"flower_daisy_bicolor",
	"flower_sunflower",
	"flower_tulip",
	"flower_tulip_yellow",
	"flower_tulip_purple",
	"flower_tulip_orange",
	"flower_bed",
	"flower_bed_blue",
	"flower_bed_white"
]

const GRID_STEP: float = 0.40
const GRASS_TUFTS_PER_UNIT: int = 6
const TUFT_HIT_RADIUS_BONUS: float = 0.0
const MULTI_HIT_COOLDOWN_SEC: float = 0.28
const HIDDEN_TRANSFORM: Transform3D = Transform3D(
	Basis(Vector3(0.0001, 0.0, 0.0), Vector3(0.0, 0.0001, 0.0), Vector3(0.0, 0.0, 0.0001)),
	Vector3(0.0, -50.0, 0.0)
)
const FIXED_ISLAND_AABB: AABB = AABB(Vector3(-35.0, -5.0, -35.0), Vector3(70.0, 12.0, 70.0))

static var _grass_mesh: Mesh = null
static var _wheat_mesh: ArrayMesh = null
static var _flower_mesh: ArrayMesh = null
static var _flower_variation_meshes: Dictionary = {}
static var _flower_rose_mesh: ArrayMesh = null
static var _flower_daisy_mesh: ArrayMesh = null
static var _flower_sunflower_mesh: ArrayMesh = null
static var _flower_tulip_mesh: ArrayMesh = null
static var _flower_bed_mesh: ArrayMesh = null

# Dados por planta (SoA - Structure of Arrays para zero overhead de nós)
var _positions: PackedVector3Array = PackedVector3Array()
var _initial_transforms: Array[Transform3D] = []
var _mmi_indices: PackedInt32Array = PackedInt32Array()
var _instance_indices: PackedInt32Array = PackedInt32Array()
var _health: PackedInt32Array = PackedInt32Array()
var _max_health: PackedInt32Array = PackedInt32Array()
var _is_cut: PackedByteArray = PackedByteArray()
var _is_hidden_by_density: PackedByteArray = PackedByteArray()
var _last_hit_time: PackedFloat32Array = PackedFloat32Array()
var _plant_keys: PackedStringArray = PackedStringArray()
var _particle_colors: PackedColorArray = PackedColorArray()
var _actively_shaking_tufts: PackedInt32Array = PackedInt32Array()

# Contadores físicos e acumuladores de corte por espécie
var _total_physical_grass: int = 0
var _total_physical_wheat: int = 0
var _total_physical_flower: int = 0

var _remaining_physical_grass: int = 0
var _remaining_physical_wheat: int = 0
var _remaining_physical_flower: int = 0

var _remaining_grass_by_type: Dictionary = {}
var _grass_cut_accumulator_by_type: Dictionary = {}

var _has_custom_goals: bool = false

# MultiMeshes ativos de vegetação (indexados por mmi_idx de 0 a VEG_TYPES.size() - 1)
var _veg_multimeshes: Array[MultiMesh] = []
var _veg_mmi_nodes: Array[MultiMeshInstance3D] = []

# MultiMeshes de aparas de folhas cortadas deitadas no chão
var _clipping_multimeshes: Array[MultiMesh] = []
var _clipping_mmi_nodes: Array[MultiMeshInstance3D] = []
var _clipping_counts: PackedInt32Array = PackedInt32Array()
static var _clipping_meshes: Dictionary = {}

# Índice espacial plano (CSR): células de GRID_STEP em arranjo contíguo, sem alocação por célula.
# _grid_items guarda os p_idx agrupados por célula; _grid_cell_start[ci]..[ci + 1] delimita a célula ci,
# com ci = (cz - _grid_min_cz) * _grid_cols + (cx - _grid_min_cx). Imutável após a construção da fase.
var _grid_min_cx: int = 0
var _grid_min_cz: int = 0
var _grid_cols: int = 0
var _grid_rows: int = 0
var _grid_cell_start: PackedInt32Array = PackedInt32Array()
var _grid_items: PackedInt32Array = PackedInt32Array()

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
		_flower_mesh = _build_flower_combined_mesh("flower", FLOWER_SCENE)
		_flower_variation_meshes["flower"] = _flower_mesh

	for f_var_key in ["flower_blue", "flower_sunset", "flower_purple", "flower_white", "flower_turquoise"]:
		if not _flower_variation_meshes.has(f_var_key):
			_flower_variation_meshes[f_var_key] = _build_flower_combined_mesh(f_var_key, FLOWER_SCENE)

	if _flower_rose_mesh == null:
		_flower_rose_mesh = _build_flower_combined_mesh("flower_rose", FLOWER_ROSE_SCENE)
		_flower_variation_meshes["flower_rose"] = _flower_rose_mesh

	for r_var_key in ["flower_rose_white", "flower_rose_yellow", "flower_rose_blue", "flower_rose_wine", "flower_rose_black", "flower_rose_peach"]:
		if not _flower_variation_meshes.has(r_var_key):
			_flower_variation_meshes[r_var_key] = _build_flower_combined_mesh(r_var_key, FLOWER_ROSE_SCENE)

	if _flower_daisy_mesh == null:
		_flower_daisy_mesh = _build_flower_combined_mesh("flower_daisy", FLOWER_DAISY_SCENE)
		_flower_variation_meshes["flower_daisy"] = _flower_daisy_mesh

	for d_var_key in ["flower_daisy_blue", "flower_daisy_orange", "flower_daisy_yellow", "flower_daisy_red", "flower_daisy_pink", "flower_daisy_bicolor"]:
		if not _flower_variation_meshes.has(d_var_key):
			_flower_variation_meshes[d_var_key] = _build_flower_combined_mesh(d_var_key, FLOWER_DAISY_SCENE)

	if _flower_sunflower_mesh == null:
		_flower_sunflower_mesh = _build_flower_combined_mesh("flower_sunflower", FLOWER_SUNFLOWER_SCENE)

	if _flower_tulip_mesh == null:
		_flower_tulip_mesh = _build_flower_combined_mesh("flower_tulip", FLOWER_TULIP_SCENE)
		_flower_variation_meshes["flower_tulip"] = _flower_tulip_mesh

	for t_var_key in ["flower_tulip_yellow", "flower_tulip_purple", "flower_tulip_orange"]:
		if not _flower_variation_meshes.has(t_var_key):
			_flower_variation_meshes[t_var_key] = _build_flower_combined_mesh(t_var_key, FLOWER_TULIP_SCENE)

	if _flower_bed_mesh == null:
		_flower_bed_mesh = _build_flower_combined_mesh("flower_bed", FLOWER_BED_SCENE)
		_flower_variation_meshes["flower_bed"] = _flower_bed_mesh

	for b_var_key in ["flower_bed_blue", "flower_bed_white"]:
		if not _flower_variation_meshes.has(b_var_key):
			_flower_variation_meshes[b_var_key] = _build_flower_combined_mesh(b_var_key, FLOWER_BED_SCENE)


static func _build_flower_combined_mesh(flower_type: String, packed_scene: PackedScene) -> ArrayMesh:
	var inst: Node = packed_scene.instantiate()
	var visual_root: Node3D = inst.get_node_or_null("VisualMesh") as Node3D
	if visual_root == null:
		inst.free()
		return null

	var flower_mat: Material = FLOWER_MATERIALS.get(flower_type, FLOWER_MATERIALS["flower"]) as Material
	var overrides_by_name: Dictionary = {
		"Flower_Petals": flower_mat,
		"Flower_Leaves": FLOWER_LEAVES_MATERIAL,
		"Flower_Stem": FLOWER_STEM_MATERIAL,
	}

	var combined_mesh: ArrayMesh = ArrayMesh.new()
	combined_mesh = _append_flower_meshes_recursive(visual_root, Transform3D.IDENTITY, combined_mesh, true, overrides_by_name)
	inst.free()
	return combined_mesh


static func _append_flower_meshes_recursive(
	node: Node,
	accum_xform: Transform3D,
	combined_mesh: ArrayMesh,
	is_root: bool,
	overrides_by_name: Dictionary
) -> ArrayMesh:
	var current_xform: Transform3D = accum_xform
	if not is_root and node is Node3D:
		current_xform = accum_xform * (node as Node3D).transform

	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		if mi.mesh != null:
			var forced_mat: Material = overrides_by_name.get(String(mi.name), null) as Material
			var surf_count: int = mi.mesh.get_surface_count()
			for s_idx: int in range(surf_count):
				var st: SurfaceTool = SurfaceTool.new()
				st.append_from(mi.mesh, s_idx, current_xform)
				var mat: Material = forced_mat
				if mat == null:
					mat = mi.get_surface_override_material(s_idx)
				if mat == null:
					mat = mi.get_active_material(s_idx)
				if mat == null:
					mat = mi.mesh.surface_get_material(s_idx)
				if mat != null:
					st.set_material(mat)
				combined_mesh = st.commit(combined_mesh)

	for child: Node in node.get_children():
		combined_mesh = _append_flower_meshes_recursive(child, current_xform, combined_mesh, false, overrides_by_name)

	return combined_mesh


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
	_has_custom_goals = false
	for child: Node in get_children():
		child.queue_free()
	_positions.clear()
	_initial_transforms.clear()
	_mmi_indices.clear()
	_instance_indices.clear()
	_health.clear()
	_max_health.clear()
	_is_cut.clear()
	_is_hidden_by_density.clear()
	_last_hit_time.clear()
	_plant_keys.clear()
	_particle_colors.clear()
	_actively_shaking_tufts.clear()
	_veg_multimeshes.clear()
	_veg_mmi_nodes.clear()
	_clipping_multimeshes.clear()
	_clipping_mmi_nodes.clear()
	_clipping_counts.clear()
	_grid_min_cx = 0
	_grid_min_cz = 0
	_grid_cols = 0
	_grid_rows = 0
	_grid_cell_start.clear()
	_grid_items.clear()
	_remaining_grass_by_type.clear()
	_grass_cut_accumulator_by_type.clear()
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

	# 1. Obtém os polígonos e furos da ilha (formato v4/v5 ou gerados retrocompatíveis a partir de terrain[])
	var island_polys: Array[PackedVector2Array] = LevelJsonLoader.get_island_polygons(data)
	var island_holes: Array[PackedVector2Array] = LevelJsonLoader.get_island_holes(data)

	# 2. Constrói a malha procedural única da ilha (ArrayMesh em 1 Draw Call)
	var island_mesh: ArrayMesh = IslandMeshBuilder.build_island_mesh(island_polys, island_holes)
	if island_mesh != null:
		var island_mi: MeshInstance3D = MeshInstance3D.new()
		island_mi.name = "IslandMesh"
		island_mi.mesh = island_mesh
		island_mi.material_override = IslandMeshBuilder.get_island_material()
		island_mi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		island_mi.custom_aabb = FIXED_ISLAND_AABB
		island_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(island_mi)

	# 3. Contenção costeira unificada (Layer 1) + fita contínua de espuma costeira
	var coastal_body: StaticBody3D = StaticBody3D.new()
	coastal_body.name = "CoastalLimits"
	coastal_body.collision_layer = 1
	coastal_body.collision_mask = 0
	add_child(coastal_body)

	var floor_col: CollisionShape3D = CollisionShape3D.new()
	floor_col.name = "IslandFloorCollider"
	var floor_box: BoxShape3D = BoxShape3D.new()
	floor_box.size = Vector3(float(width) * cell_size + 4.0, 0.72, float(height) * cell_size + 4.0)
	floor_col.shape = floor_box
	floor_col.position = Vector3(0.0, -0.36, 0.0)
	coastal_body.add_child(floor_col)

	IslandMeshBuilder.build_coastal_colliders(coastal_body, island_polys, island_holes)

	var foam_mesh: ArrayMesh = IslandMeshBuilder.build_coastal_foam_mesh(island_polys, island_holes)
	if foam_mesh != null and foam_mesh.get_surface_count() > 0:
		var foam_inst: MeshInstance3D = MeshInstance3D.new()
		foam_inst.name = "CoastalFoamRibbon"
		foam_inst.mesh = foam_mesh
		foam_inst.material_override = IslandMeshBuilder.get_foam_material()
		foam_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		coastal_body.add_child(foam_inst)

	# 3. Processa objetos (rochas e vegetação)
	var goals: Dictionary = {}
	var objects_arr: Array = data.get("objects", []) as Array

	# Instancia rochas (obstáculos sólidos da Layer 4), flores e trigos (objetos de tile 0.80m)
	var rock_cells: Dictionary = {}
	var flower_cells: Dictionary = {}
	var wheat_cells: Dictionary = {}
	for item: Variant in objects_arr:
		if item is Dictionary:
			var od: Dictionary = item as Dictionary
			var o_type: String = String(od.get("type", ""))
			var gx: int = int(od.get("gx", 0))
			var gz: int = int(od.get("gz", 0))
			var o_rot: int = int(od.get("rot", 0))
			if o_type.begins_with("rock"):
				var base_pos: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, cell_size)
				rock_cells[Vector2i(gx, gz)] = true
				var rock_inst: Node3D = LevelJsonLoader.instantiate_object_node(o_type, o_rot)
				if rock_inst != null:
					rock_inst.position = base_pos
					if obstacles_container != null:
						obstacles_container.add_child(rock_inst)
					else:
						add_child(rock_inst)
			elif o_type.begins_with("flower"):
				flower_cells[Vector2i(gx, gz)] = { "type": o_type, "rot": o_rot }
			elif o_type == "wheat":
				wheat_cells[Vector2i(gx, gz)] = o_rot

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

	# Remove polígonos sob rochas no campo vetorial com raio da menor lâmina (0.90m)
	for r_cell: Vector2i in rock_cells.keys():
		var r_pos: Vector3 = LevelJsonLoader.grid_to_world(r_cell.x, r_cell.y, width, height, cell_size)
		var rock_clip_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(
			Vector2(r_pos.x, r_pos.z),
			0.90
		)
		vector_field.clip_shapes(rock_clip_poly)

	# Remove grama na clareira de spawn do robô com o raio atual da rocha (1.40m)
	if data.has("spawn") and data["spawn"] is Dictionary:
		var sp_dict: Dictionary = data["spawn"] as Dictionary
		var sp_gx: int = int(sp_dict.get("gx", int(float(width) / 2.0)))
		var sp_gz: int = int(sp_dict.get("gz", int(float(height) / 2.0)))
		var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_gx, sp_gz, width, height, cell_size)
		var spawn_clip_poly: PackedVector2Array = BrushPatterns.get_circle_polygon(
			Vector2(sp_world.x, sp_world.z),
			1.40
		)
		vector_field.clip_shapes(spawn_clip_poly)

	# Constrói MultiMeshes e grade espacial a partir do campo vetorial
	goals = _build_from_vector_field(vector_field, width, height, cell_size, flower_cells, wheat_cells, rock_cells)

	# Se o JSON possui metas personalizadas definidas pelo editor, substitui as metas padrão
	_has_custom_goals = false
	if data.has("goals") and data["goals"] is Dictionary:
		var custom_goals: Dictionary = data["goals"] as Dictionary
		if not custom_goals.is_empty():
			_has_custom_goals = true
			goals.clear()
			for g_key: Variant in custom_goals:
				var k_str: String = String(g_key)
				var raw_val: int = int(custom_goals[g_key])
				if k_str == "grass" or k_str.begins_with("grass_"):
					var phys_cnt: int = _total_physical_grass if k_str == "grass" else int(_remaining_grass_by_type.get(k_str, 0))
					var max_grouped: int = maxi(1, int(ceilf(float(phys_cnt) / float(GRASS_TUFTS_PER_UNIT))))
					# Se o valor salvo estiver dentro do limite de unidades agrupadas, respeita-o;
					# caso exceda (ex: nível antigo salvo com tufos brutos), trava no total físico agrupado
					goals[k_str] = clampi(raw_val, 1, max_grouped)
				else:
					goals[k_str] = raw_val

	# 5. Posiciona o cortador no spawn
	var spawn_dict: Dictionary = data.get("spawn", {}) as Dictionary
	var sp_x: int = int(spawn_dict.get("gx", int(float(width) / 2.0)))
	var sp_z: int = int(spawn_dict.get("gz", int(float(height) / 2.0)))
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_x, sp_z, width, height, cell_size)
	if cutter != null:
		cutter.position = Vector3(sp_world.x, 0.1, sp_world.z)
		cutter.reset_physics_interpolation()
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
			return Color(0.17, 0.36, 0.17, 1.0)
		"grass_yellow":
			return Color(0.64, 0.46, 0.10, 1.0)
		"grass_blue":
			return Color(0.16, 0.31, 0.42, 1.0)
		"grass_purple":
			return Color(0.33, 0.19, 0.38, 1.0)
		"grass_white":
			return Color(0.70, 0.73, 0.68, 1.0)
		"grass_red":
			return Color(0.48, 0.21, 0.19, 1.0)
		"grass_black":
			return Color(0.12, 0.14, 0.12, 1.0)
		"wheat":
			return Color(0.64, 0.46, 0.10, 1.0)
		"flower":
			return Color(0.85, 0.22, 0.55, 1.0)
		"flower_blue":
			return Color(0.20, 0.60, 0.85, 1.0)
		"flower_sunset":
			return Color(0.88, 0.45, 0.15, 1.0)
		"flower_purple":
			return Color(0.65, 0.35, 0.80, 1.0)
		"flower_white":
			return Color(0.88, 0.88, 0.90, 1.0)
		"flower_turquoise":
			return Color(0.15, 0.70, 0.65, 1.0)
		"flower_rose":
			return Color(0.72, 0.12, 0.25, 1.0)
		"flower_rose_white":
			return Color(0.92, 0.90, 0.85, 1.0)
		"flower_rose_yellow":
			return Color(0.90, 0.75, 0.10, 1.0)
		"flower_rose_blue":
			return Color(0.25, 0.60, 0.90, 1.0)
		"flower_rose_wine":
			return Color(0.38, 0.08, 0.20, 1.0)
		"flower_rose_black":
			return Color(0.12, 0.05, 0.08, 1.0)
		"flower_rose_peach":
			return Color(0.90, 0.55, 0.40, 1.0)
		"flower_daisy":
			return Color(0.85, 0.85, 0.88, 1.0)
		"flower_daisy_blue":
			return Color(0.40, 0.62, 0.95, 1.0)
		"flower_daisy_orange":
			return Color(0.95, 0.45, 0.10, 1.0)
		"flower_daisy_yellow":
			return Color(0.95, 0.82, 0.15, 1.0)
		"flower_daisy_red":
			return Color(0.85, 0.15, 0.20, 1.0)
		"flower_daisy_pink":
			return Color(0.90, 0.40, 0.65, 1.0)
		"flower_daisy_bicolor":
			return Color(0.90, 0.85, 0.50, 1.0)
		"flower_sunflower":
			return Color(0.82, 0.65, 0.08, 1.0)
		"flower_tulip":
			return Color(0.75, 0.12, 0.18, 1.0)
		"flower_bed":
			return Color(0.65, 0.28, 0.78, 1.0)
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
		var center := Vector3(cx, 0.016, cz)

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
	tile_flowers: Dictionary = {},
	tile_wheat: Dictionary = {},
	tile_rocks: Dictionary = {}
) -> Dictionary:
	var goals: Dictionary = {}
	if vector_field == null:
		return goals

	var tufts: Array[Dictionary] = []

	# Adiciona flores de tile caso existam no JSON (respeitando clareira de rochas de 1.40m)
	# Regra canônica: flores convivem harmoniosamente com a grama (não limpam tufos de grama)
	for f_cell: Vector2i in tile_flowers.keys():
		var f_pos: Vector3 = LevelJsonLoader.grid_to_world(f_cell.x, f_cell.y, width_blocks, height_blocks, block_cell_size)
		var inside_rock_radius: bool = false
		for r_cell: Vector2i in tile_rocks.keys():
			var r_pos: Vector3 = LevelJsonLoader.grid_to_world(r_cell.x, r_cell.y, width_blocks, height_blocks, block_cell_size)
			if Vector2(f_pos.x - r_pos.x, f_pos.z - r_pos.z).length() <= 1.40:
				inside_rock_radius = true
				break
		if inside_rock_radius:
			continue

		var f_val: Variant = tile_flowers[f_cell]
		var f_type: String = "flower"
		var f_rot: float = 0.0
		if f_val is Dictionary:
			f_type = String((f_val as Dictionary).get("type", "flower"))
			f_rot = float((f_val as Dictionary).get("rot", 0.0))
		elif f_val is String and not String(f_val).is_empty():
			f_type = String(f_val)

		tufts.append({
			"pos": f_pos,
			"type": f_type,
			"scale_factor": 1.0,
			"seed": float(f_cell.x * 79 + f_cell.y * 31),
			"rot": f_rot
		})

	# Adiciona trigos de tile (cultura agrícola discreta) caso existam no JSON (respeitando clareira de rochas de 1.40m)
	for w_cell: Vector2i in tile_wheat.keys():
		var w_pos: Vector3 = LevelJsonLoader.grid_to_world(w_cell.x, w_cell.y, width_blocks, height_blocks, block_cell_size)
		var inside_rock: bool = false
		for r_cell: Vector2i in tile_rocks.keys():
			var r_pos: Vector3 = LevelJsonLoader.grid_to_world(r_cell.x, r_cell.y, width_blocks, height_blocks, block_cell_size)
			if Vector2(w_pos.x - r_pos.x, w_pos.z - r_pos.z).length() <= 1.40:
				inside_rock = true
				break
		if inside_rock:
			continue

		tufts.append({
			"pos": w_pos,
			"type": "wheat",
			"scale_factor": 1.25,
			"seed": float(w_cell.x * 67 + w_cell.y * 43)
		})

	var sampled_tufts: Array = vector_field.call("sample_all_tufts") as Array
	for item: Variant in sampled_tufts:
		if item is Dictionary:
			tufts.append(item as Dictionary)

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

		if count <= 0:
			_veg_multimeshes[mmi_idx] = null
			_veg_mmi_nodes[mmi_idx] = null
			_clipping_multimeshes[mmi_idx] = null
			_clipping_mmi_nodes[mmi_idx] = null
			continue

		var is_flower: bool = v_type.begins_with("flower")
		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		if is_flower:
			mm.use_custom_data = true
			if v_type.begins_with("flower_rose"):
				mm.mesh = _flower_variation_meshes.get(v_type, _flower_rose_mesh)
			elif v_type.begins_with("flower_daisy"):
				mm.mesh = _flower_variation_meshes.get(v_type, _flower_daisy_mesh)
			elif v_type == "flower_sunflower":
				mm.mesh = _flower_sunflower_mesh
			elif v_type.begins_with("flower_tulip"):
				mm.mesh = _flower_variation_meshes.get(v_type, _flower_tulip_mesh)
			elif v_type.begins_with("flower_bed"):
				mm.mesh = _flower_variation_meshes.get(v_type, _flower_bed_mesh)
			else:
				mm.mesh = _flower_mesh
		elif v_type == "wheat":
			mm.mesh = _wheat_mesh
		else:
			mm.mesh = _grass_mesh
		mm.instance_count = count

		var mmi: MultiMeshInstance3D = MultiMeshInstance3D.new()
		mmi.name = "VegMMI_%s" % v_type
		mmi.multimesh = mm
		mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		mmi.custom_aabb = FIXED_ISLAND_AABB
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
		clip_mmi.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		clip_mmi.custom_aabb = FIXED_ISLAND_AABB
		clip_mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(clip_mmi)

		_veg_multimeshes[mmi_idx] = mm
		_veg_mmi_nodes[mmi_idx] = mmi
		_clipping_multimeshes[mmi_idx] = clip_mm
		_clipping_mmi_nodes[mmi_idx] = clip_mmi

		var is_grass: bool = (v_type != "wheat" and not is_flower)
		var max_hp: int = 1 if is_grass else (3 if is_flower else 2)
		var p_col: Color = _resolve_type_particle_color(v_type)

		for inst_idx: int in range(count):
			var entry: Dictionary = entry_list[inst_idx]
			var pos: Vector3 = entry["pos"] as Vector3
			var s_seed: float = float(entry["seed"])
			var scale_factor: float = float(entry.get("scale_factor", 1.0))

			var plant_rot: float = deg_to_rad(float(entry.get("rot", 0.0))) if is_flower else fmod(s_seed * 1.618, TAU)

			var scale_vec: Vector3
			if is_grass:
				var scale_y: float = lerpf(0.48, 0.62, scale_factor) * (0.95 + fmod(s_seed * 0.13, 0.10))
				var scale_xz: float = lerpf(0.32, 0.44, scale_factor) * (0.95 + fmod(s_seed * 0.27, 0.10))
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			elif v_type == "wheat":
				# Escala aumentada em 100% (dobrada: 0.55~0.70 -> 1.10~1.40 Y, 0.34~0.46 -> 0.68~0.92 XZ)
				var scale_y: float = lerpf(1.10, 1.40, scale_factor) * (0.95 + fmod(s_seed * 0.13, 0.10))
				var scale_xz: float = lerpf(0.68, 0.92, scale_factor) * (0.95 + fmod(s_seed * 0.27, 0.10))
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			else:
				var sf: float = 0.676 * scale_factor
				scale_vec = Vector3(sf, sf, sf)

			var inst_basis: Basis = Basis(Vector3.UP, plant_rot) * Basis.from_scale(scale_vec)
			var xform: Transform3D = Transform3D(inst_basis, pos)
			mm.set_instance_transform(inst_idx, xform)

			_positions.append(pos)
			_initial_transforms.append(xform)
			_mmi_indices.append(mmi_idx)
			_instance_indices.append(inst_idx)
			_health.append(max_hp)
			_max_health.append(max_hp)
			_is_cut.append(0)
			_is_hidden_by_density.append(0)
			_last_hit_time.append(-10.0)
			var own_plant_key: String = v_type
			_plant_keys.append(own_plant_key)
			_particle_colors.append(p_col)

	_build_spatial_index()

	# Unifica contagem de metas: 10 tufos físicos = 1 unidade virtual de meta
	_total_physical_grass = 0
	_total_physical_wheat = 0
	_total_physical_flower = 0
	var flower_counts_by_type: Dictionary = {}
	var grass_counts_by_type: Dictionary = {}
	for p_idx: int in range(_positions.size()):
		var pk: String = _plant_keys[p_idx]
		if pk == "wheat":
			_total_physical_wheat += 1
		elif pk.begins_with("flower"):
			_total_physical_flower += 1
			flower_counts_by_type[pk] = int(flower_counts_by_type.get(pk, 0)) + 1
		else:
			_total_physical_grass += 1
			grass_counts_by_type[pk] = int(grass_counts_by_type.get(pk, 0)) + 1

	_remaining_physical_grass = _total_physical_grass
	_remaining_physical_wheat = _total_physical_wheat
	_remaining_physical_flower = _total_physical_flower

	_remaining_grass_by_type.clear()
	_grass_cut_accumulator_by_type.clear()
	for g_type: Variant in grass_counts_by_type.keys():
		var gt_str: String = String(g_type)
		_remaining_grass_by_type[gt_str] = int(grass_counts_by_type[g_type])
		_grass_cut_accumulator_by_type[gt_str] = 0

	goals.clear()
	# Todas as variedades de grama são tratadas individualmente por cor/tipo
	for g_key: Variant in grass_counts_by_type.keys():
		var g_count: int = int(grass_counts_by_type[g_key])
		goals[String(g_key)] = maxi(1, int(ceilf(float(g_count) / float(GRASS_TUFTS_PER_UNIT))))
	if _total_physical_wheat > 0:
		goals["wheat"] = _total_physical_wheat
	if _total_physical_flower > 0:
		for f_key: Variant in flower_counts_by_type.keys():
			goals[String(f_key)] = int(flower_counts_by_type[f_key])

	return goals


## Constrói o índice espacial plano (CSR) a partir de _positions.
## Counting sort estável: dentro de cada célula os p_idx permanecem em ordem crescente,
## idêntica à ordem de inserção da antiga grade por Dictionary.
func _build_spatial_index() -> void:
	_grid_cell_start.clear()
	_grid_items.clear()
	_grid_cols = 0
	_grid_rows = 0
	var total: int = _positions.size()
	if total == 0:
		return

	var min_cx: int = 0x7FFFFFFF
	var min_cz: int = 0x7FFFFFFF
	var max_cx: int = -0x7FFFFFFF
	var max_cz: int = -0x7FFFFFFF
	for i: int in range(total):
		var p: Vector3 = _positions[i]
		var kx: int = roundi(p.x / GRID_STEP)
		var kz: int = roundi(p.z / GRID_STEP)
		min_cx = mini(min_cx, kx)
		max_cx = maxi(max_cx, kx)
		min_cz = mini(min_cz, kz)
		max_cz = maxi(max_cz, kz)

	_grid_min_cx = min_cx
	_grid_min_cz = min_cz
	_grid_cols = max_cx - min_cx + 1
	_grid_rows = max_cz - min_cz + 1
	var cell_count: int = _grid_cols * _grid_rows

	_grid_cell_start.resize(cell_count + 1)
	_grid_cell_start.fill(0)
	var cell_of: PackedInt32Array = PackedInt32Array()
	cell_of.resize(total)
	for i: int in range(total):
		var p2: Vector3 = _positions[i]
		var ci: int = (roundi(p2.z / GRID_STEP) - min_cz) * _grid_cols + (roundi(p2.x / GRID_STEP) - min_cx)
		cell_of[i] = ci
		_grid_cell_start[ci + 1] += 1
	for c: int in range(cell_count):
		_grid_cell_start[c + 1] += _grid_cell_start[c]

	_grid_items.resize(total)
	var cursor: PackedInt32Array = _grid_cell_start.duplicate()
	for i: int in range(total):
		var cj: int = cell_of[i]
		_grid_items[cursor[cj]] = i
		cursor[cj] += 1


## Transformação da apara deitada no solo: só a rotação em Y e a posição do tufo.
## Derivada de _initial_transforms (R * escala positiva): as colunas já são ortogonais,
## então orthonormalized() devolve exatamente a rotação, sem armazenar um array extra.
func _get_cut_transform(p_idx: int) -> Transform3D:
	return Transform3D(_initial_transforms[p_idx].basis.orthonormalized(), _positions[p_idx])


func _resolve_type_particle_color(v_type: String) -> Color:
	if GRASS_MATERIALS.has(v_type):
		var sm: ShaderMaterial = GRASS_MATERIALS[v_type] as ShaderMaterial
		if sm != null:
			var col_light: Variant = sm.get_shader_parameter("color_light")
			if col_light is Color:
				return col_light as Color
			var col_variant: Variant = sm.get_shader_parameter("color_top")
			if col_variant is Color:
				return col_variant as Color
	if v_type == "wheat":
		return Color(0.69, 0.55, 0.10, 1.0)
	if v_type.begins_with("flower_rose"):
		var r_cols: Dictionary = PlantScript.get_flower_colors(v_type)
		return r_cols.get("petal", Color(1.0, 0.08, 0.35, 1.0))
	if v_type.begins_with("flower_daisy"):
		var d_cols: Dictionary = PlantScript.get_flower_colors(v_type)
		return d_cols.get("petal", Color(1.0, 1.0, 1.0, 1.0))
	if v_type == "flower_sunflower":
		return Color(1.0, 0.88, 0.0, 1.0)
	if v_type.begins_with("flower_tulip"):
		var t_cols: Dictionary = PlantScript.get_flower_colors(v_type)
		return t_cols.get("petal", Color(1.0, 0.08, 0.24, 1.0))
	if v_type.begins_with("flower_bed"):
		var b_cols: Dictionary = PlantScript.get_flower_colors(v_type)
		return b_cols.get("petal", Color(0.88, 0.30, 1.0, 1.0))
	if v_type == "flower":
		return Color(1.0, 0.18, 0.65, 1.0)
	return Color(0.30, 0.70, 0.32, 1.0)


func _get_game_manager() -> Node:
	if not is_inside_tree():
		return null
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("GameManager")


func cut_in_circle(center: Vector3, blade_radius: float, power: int) -> Vector3:
	var gm: Node = _get_game_manager()
	if gm != null and int(gm.get("current_state")) != 1:
		return Vector3.ZERO

	# Trilha contínua da serra no solo removida: a antiga cadeia LawnCutTrail nunca era instanciada.

	var hit_radius: float = blade_radius + TUFT_HIT_RADIUS_BONUS
	var hit_radius_sq: float = hit_radius * hit_radius
	var min_cx: int = floori((center.x - hit_radius) / GRID_STEP)
	var max_cx: int = ceili((center.x + hit_radius) / GRID_STEP)
	var min_cz: int = floori((center.z - hit_radius) / GRID_STEP)
	var max_cz: int = ceili((center.z + hit_radius) / GRID_STEP)

	var now_sec: float = float(Time.get_ticks_msec()) * 0.001
	var particles_spawned_this_frame: int = 0
	var new_shaking_tufts: PackedInt32Array = PackedInt32Array()
	var first_hit_recoil: Vector3 = Vector3.ZERO
	var tree_node: SceneTree = get_tree()
	var s_root: Node = tree_node.current_scene if (tree_node != null and tree_node.current_scene != null) else self
	var am_node: Node = get_node_or_null("/root/AudioManager") if is_inside_tree() else null
	var sm_node: Node = get_node_or_null("/root/SaveManager") if is_inside_tree() else null
	var um_node: Node = get_node_or_null("/root/UpgradeManager") if is_inside_tree() else null
	var xp_gained_this_frame: float = 0.0
	var any_hit_feedback: bool = false
	var any_tuft_cut: bool = false

	# Consulta o índice plano limitando a janela aos limites da grade (fora dela não há tufos)
	for cx: int in range(maxi(min_cx, _grid_min_cx), mini(max_cx, _grid_min_cx + _grid_cols - 1) + 1):
		for cz: int in range(maxi(min_cz, _grid_min_cz), mini(max_cz, _grid_min_cz + _grid_rows - 1) + 1):
			var cell_i: int = (cz - _grid_min_cz) * _grid_cols + (cx - _grid_min_cx)
			for i: int in range(_grid_cell_start[cell_i], _grid_cell_start[cell_i + 1]):
				var p_idx: int = _grid_items[i]
				if _is_cut[p_idx] == 1 or _is_hidden_by_density[p_idx] == 1:
					continue

				var p_pos: Vector3 = _positions[p_idx]
				var dx: float = p_pos.x - center.x
				var dz: float = p_pos.z - center.z
				if dx * dx + dz * dz > hit_radius_sq:
					continue

				if now_sec - _last_hit_time[p_idx] < MULTI_HIT_COOLDOWN_SEC:
					# Enquanto a serra estiver em contato antes de fechar o tempo de 1s, treme sutilmente a planta resistente
					if _max_health[p_idx] > 1 and _is_cut[p_idx] == 0 and _health[p_idx] > 0:
						var jitter_amp: float = 0.022
						var jitter_x: float = sin(now_sec * 65.0 + float(p_idx) * 13.0) * jitter_amp
						var jitter_z: float = cos(now_sec * 65.0 + float(p_idx) * 17.0) * jitter_amp
						var shake_mmi_idx: int = _mmi_indices[p_idx]
						var shake_inst_idx: int = _instance_indices[p_idx]
						var shake_mm: MultiMesh = _veg_multimeshes[shake_mmi_idx]
						if shake_mm != null:
							var init_xform: Transform3D = _initial_transforms[p_idx]
							var shake_xform: Transform3D = Transform3D(init_xform.basis, init_xform.origin + Vector3(jitter_x, 0.0, jitter_z))
							shake_mm.set_instance_transform(shake_inst_idx, shake_xform)
							new_shaking_tufts.append(p_idx)
					continue

				var old_hp: int = _health[p_idx]
				_last_hit_time[p_idx] = now_sec
				var new_hp: int = old_hp - power
				_health[p_idx] = new_hp
				if _max_health[p_idx] > 1 and old_hp == _max_health[p_idx] and new_hp > 0:
					var recoil_vec: Vector3 = Vector3(center.x - p_pos.x, 0.0, center.z - p_pos.z)
					if recoil_vec.length_squared() > 0.0001:
						first_hit_recoil += recoil_vec.normalized()
					else:
						first_hit_recoil += Vector3(0.0, 0.0, 1.0)

				var mmi_idx: int = _mmi_indices[p_idx]
				var inst_idx: int = _instance_indices[p_idx]
				var mm: MultiMesh = _veg_multimeshes[mmi_idx]

				if new_hp <= 0:
					_is_cut[p_idx] = 1
					any_tuft_cut = true
					any_hit_feedback = true
					if mm != null:
						mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)
					var clip_mm: MultiMesh = _clipping_multimeshes[mmi_idx]
					if clip_mm != null:
						var c_idx: int = _clipping_counts[mmi_idx]
						if c_idx < clip_mm.instance_count:
							clip_mm.set_instance_transform(c_idx, _get_cut_transform(p_idx))
							c_idx += 1
							_clipping_counts[mmi_idx] = c_idx
							clip_mm.visible_instance_count = c_idx
					if particles_spawned_this_frame < 8:
						var max_p_dist: float = blade_radius * 0.75
						var dist_xz: float = sqrt(dx * dx + dz * dz)
						var safe_p_pos: Vector3 = p_pos
						if dist_xz > max_p_dist and dist_xz > 0.001:
							var ratio: float = max_p_dist / dist_xz
							safe_p_pos = Vector3(center.x + dx * ratio, p_pos.y, center.z + dz * ratio)
						var p_key_part: String = _plant_keys[p_idx]
						if p_key_part.begins_with("flower"):
							PlantScript.spawn_flower_cut_particles(s_root, safe_p_pos, p_key_part)
							PlantScript.spawn_flower_detach_pieces(s_root, _initial_transforms[p_idx], p_key_part)
						else:
							PlantScript.spawn_grass_cut_particles(s_root, safe_p_pos, _particle_colors[p_idx])
						particles_spawned_this_frame += 1

					# Atualização de metas e concessão de XP da lâmina: Trigo (3 XP), Flores (5 XP), Grama (1 XP)
					var p_key: String = _plant_keys[p_idx]
					if sm_node != null and sm_node.has_method("record_plant_harvest"):
						sm_node.call("record_plant_harvest", p_key, 1)

					if p_key == "wheat":
						xp_gained_this_frame += 3.0
						_remaining_physical_wheat = maxi(0, _remaining_physical_wheat - 1)
						if gm != null:
							gm.call("register_cut", "wheat", 3, p_pos)
					elif p_key.begins_with("flower"):
						xp_gained_this_frame += 5.0
						_remaining_physical_flower = maxi(0, _remaining_physical_flower - 1)
						if gm != null:
							gm.call("register_cut", p_key, 5, p_pos)
					else:
						xp_gained_this_frame += 1.0
						# Qualquer tipo/cor de grama (contabilizada por cor específica ou genérica)
						_remaining_physical_grass = maxi(0, _remaining_physical_grass - 1)
						var g_rem: int = maxi(0, int(_remaining_grass_by_type.get(p_key, 0)) - 1)
						_remaining_grass_by_type[p_key] = g_rem

						var acc: int = int(_grass_cut_accumulator_by_type.get(p_key, 0)) + 1
						var target_goal: String = p_key
						if gm != null and not _has_goal_safe(p_key) and _has_goal_safe("grass"):
							target_goal = "grass"

						# Agrupamento canônico: cada 6 tufos visuais de grama contam como 1 (meta + número flutuante)
						if acc >= GRASS_TUFTS_PER_UNIT:
							acc -= GRASS_TUFTS_PER_UNIT
							if gm != null and (not _has_custom_goals or _has_goal_safe(target_goal)):
								gm.call("register_cut", target_goal, 1, p_pos)
						elif g_rem <= 0 and acc > 0:
							acc = 0
							if gm != null and _get_remaining_goal_safe(target_goal) > 0:
								gm.call("register_cut", target_goal, 1, p_pos)

						_grass_cut_accumulator_by_type[p_key] = acc
				else:
					var p_key: String = _plant_keys[p_idx]
					any_hit_feedback = true

					if mm != null:
						if p_key.begins_with("flower"):
							var stage: float = 1.0 if new_hp == 2 else 2.0
							mm.set_instance_custom_data(inst_idx, Color(stage, 0.0, 0.0, 0.0))
							PlantScript.spawn_flower_petal_burst(s_root, p_pos, p_key)
							if new_hp == 2:
								PlantScript.spawn_flower_detach_pieces(s_root, _initial_transforms[p_idx], p_key)
						elif p_key == "wheat":
							PlantScript.spawn_grass_cut_particles(s_root, p_pos, _particle_colors[p_idx])

						var init_xform: Transform3D = _initial_transforms[p_idx]
						var squash_xform: Transform3D = Transform3D(
							init_xform.basis.scaled(Vector3(1.25, 1.25, 1.25)),
							init_xform.origin
						)
						mm.set_instance_transform(inst_idx, squash_xform)
					if tree_node != null:
						tree_node.create_timer(0.08).timeout.connect(_restore_plant_transform.bind(p_idx))

	if any_hit_feedback:
		if am_node != null and am_node.has_method("play_cut_sfx"):
			am_node.call("play_cut_sfx", false)
		if gm != null and gm.has_method("trigger_haptic_cut"):
			gm.call("trigger_haptic_cut")

	if xp_gained_this_frame > 0.0 and um_node != null and um_node.has_method("add_blade_xp"):
		um_node.call("add_blade_xp", xp_gained_this_frame)

	if any_tuft_cut and gm != null:
		# Proteção anti-trava por categoria independente executada 1x ao final do frame de corte:
		if _remaining_physical_wheat <= 0 and _get_remaining_goal_safe("wheat") > 0:
			while _get_remaining_goal_safe("wheat") > 0:
				gm.call("register_cut", "wheat", 3, Vector3.ZERO)
		if _remaining_physical_flower <= 0:
			var gm_goals: Variant = gm.get("goals")
			if gm_goals is Dictionary:
				for g_key_var: Variant in (gm_goals as Dictionary).keys():
					var g_key_str: String = String(g_key_var)
					if g_key_str.begins_with("flower"):
						while _get_remaining_goal_safe(g_key_str) > 0:
							gm.call("register_cut", g_key_str, 5, Vector3.ZERO)
		for g_type_key: Variant in _remaining_grass_by_type.keys():
			var gt_str: String = String(g_type_key)
			if int(_remaining_grass_by_type[gt_str]) <= 0:
				var g_target: String = gt_str
				if not _has_goal_safe(gt_str) and _has_goal_safe("grass"):
					g_target = "grass"
				while _get_remaining_goal_safe(g_target) > 0:
					gm.call("register_cut", g_target, 1, Vector3.ZERO)

	# Restaura qualquer tufo que estava tremendo no frame anterior mas não está mais em contato
	for old_p_idx: int in _actively_shaking_tufts:
		if not new_shaking_tufts.has(old_p_idx):
			_restore_plant_transform(old_p_idx)
	_actively_shaking_tufts = new_shaking_tufts
	return first_hit_recoil.normalized() if first_hit_recoil.length_squared() > 0.0001 else Vector3.ZERO


func _restore_plant_transform(p_idx: int) -> void:
	if p_idx < 0 or p_idx >= _positions.size():
		return
	if _is_cut[p_idx] == 0 and _is_hidden_by_density[p_idx] == 0:
		var mmi_idx: int = _mmi_indices[p_idx]
		var inst_idx: int = _instance_indices[p_idx]
		var mm: MultiMesh = _veg_multimeshes[mmi_idx]
		if mm != null:
			mm.set_instance_transform(inst_idx, _initial_transforms[p_idx])


## Resolve a colisão física contra plantas rígidas (> 1 vida vivas) para impedir que o cortador as atravesse.
func resolve_rigid_plant_collision(cutter_pos: Vector3, cutter_vel: Vector3, body_radius: float, plant_radius: float = 0.18) -> Dictionary:
	var max_plant_radius: float = maxf(plant_radius, 0.23)
	var search_radius: float = body_radius + max_plant_radius
	var min_cx: int = floori((cutter_pos.x - search_radius) / GRID_STEP)
	var max_cx: int = ceili((cutter_pos.x + search_radius) / GRID_STEP)
	var min_cz: int = floori((cutter_pos.z - search_radius) / GRID_STEP)
	var max_cz: int = ceili((cutter_pos.z + search_radius) / GRID_STEP)

	var resolved_pos: Vector3 = cutter_pos
	var resolved_vel: Vector3 = cutter_vel

	# Consulta o índice plano limitando a janela aos limites da grade (fora dela não há tufos)
	for cx: int in range(maxi(min_cx, _grid_min_cx), mini(max_cx, _grid_min_cx + _grid_cols - 1) + 1):
		for cz: int in range(maxi(min_cz, _grid_min_cz), mini(max_cz, _grid_min_cz + _grid_rows - 1) + 1):
			var cell_i: int = (cz - _grid_min_cz) * _grid_cols + (cx - _grid_min_cx)
			for i: int in range(_grid_cell_start[cell_i], _grid_cell_start[cell_i + 1]):
				var p_idx: int = _grid_items[i]
				if _max_health[p_idx] <= 1 or _is_cut[p_idx] == 1 or _health[p_idx] <= 0:
					continue

				var eff_plant_radius: float = 0.23 if _plant_keys[p_idx].begins_with("flower") else plant_radius
				var total_radius: float = body_radius + eff_plant_radius
				var total_radius_sq: float = total_radius * total_radius

				var p_pos: Vector3 = _positions[p_idx]
				var dx: float = resolved_pos.x - p_pos.x
				var dz: float = resolved_pos.z - p_pos.z
				var dist_sq: float = dx * dx + dz * dz

				if dist_sq < total_radius_sq and dist_sq > 0.000001:
					var dist: float = sqrt(dist_sq)
					var norm_x: float = dx / dist
					var norm_z: float = dz / dist
					var penetration: float = total_radius - dist

					resolved_pos.x += norm_x * penetration
					resolved_pos.z += norm_z * penetration

					var norm3: Vector3 = Vector3(norm_x, 0.0, norm_z)
					if resolved_vel.dot(-norm3) > 0.0:
						resolved_vel = resolved_vel.slide(norm3)

	return {
		"position": resolved_pos,
		"velocity": resolved_vel
	}


func _spawn_cut_particles_at(world_pos: Vector3, col: Color) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return
	var scene_root: Node = tree.current_scene
	if scene_root == null:
		scene_root = self
	PlantScript.spawn_grass_cut_particles(scene_root, world_pos, col)


func get_total_tufts() -> int:
	return _positions.size()


func set_benchmark_visibility(vegetation_on: bool, density_step: int) -> void:
	_last_vegetation_on = vegetation_on
	var step: int = maxi(1, density_step)
	_last_density_step = step

	for mmi_idx: int in range(_clipping_counts.size()):
		_clipping_counts[mmi_idx] = 0

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
		elif _is_cut[p_idx] == 1 and _is_hidden_by_density[p_idx] == 0:
			mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)
			if clip_mm != null:
				var c_idx: int = _clipping_counts[mmi_idx]
				if c_idx < clip_mm.instance_count:
					clip_mm.set_instance_transform(c_idx, _get_cut_transform(p_idx))
					_clipping_counts[mmi_idx] = c_idx + 1
		else:
			mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)

	for mmi_idx: int in range(_clipping_multimeshes.size()):
		var clip_mm: MultiMesh = _clipping_multimeshes[mmi_idx]
		if clip_mm != null:
			clip_mm.visible_instance_count = 0 if not vegetation_on else _clipping_counts[mmi_idx]


func reset_all_plants() -> void:
	var total: int = _positions.size()
	for p_idx: int in range(total):
		_is_cut[p_idx] = 0
		_health[p_idx] = _max_health[p_idx]
		_last_hit_time[p_idx] = -10.0

	_remaining_physical_grass = _total_physical_grass
	_remaining_physical_wheat = _total_physical_wheat
	_remaining_physical_flower = _total_physical_flower

	for mmi_idx: int in range(_clipping_multimeshes.size()):
		if mmi_idx < _clipping_counts.size():
			_clipping_counts[mmi_idx] = 0
		var clip_mm: MultiMesh = _clipping_multimeshes[mmi_idx]
		if clip_mm != null:
			clip_mm.visible_instance_count = 0

	set_benchmark_visibility(_last_vegetation_on, _last_density_step)


static func _get_remaining_goal_safe(p_type: String) -> int:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return 0
	var gm: Node = tree.root.get_node_or_null("GameManager")
	if gm == null:
		return 0
	if gm.has_method("get_remaining_goal"):
		return int(gm.call("get_remaining_goal", p_type))
	var goals_dict: Variant = gm.get("goals")
	if goals_dict is Dictionary:
		var g_val: Variant = (goals_dict as Dictionary).get(p_type, null)
		if g_val is Dictionary:
			var gd: Dictionary = g_val as Dictionary
			return maxi(0, int(gd.get("target", 0)) - int(gd.get("current", 0)))
		elif g_val is int:
			return maxi(0, int(g_val))
	return 0


static func _has_goal_safe(p_type: String) -> bool:
	var tree: SceneTree = Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return false
	var gm: Node = tree.root.get_node_or_null("GameManager")
	if gm == null:
		return false
	var goals_dict: Variant = gm.get("goals")
	if goals_dict is Dictionary:
		return (goals_dict as Dictionary).has(p_type)
	return false
