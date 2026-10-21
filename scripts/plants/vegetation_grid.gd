extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const PlantScript = preload("res://scripts/plants/plant.gd")

const GRASS_MODEL: PackedScene = preload("res://assets/models/grass_01.glb")
const WHEAT_SCENE: PackedScene = preload("res://scenes/plants/wheat_tuft.tscn")
const FLOWER_SCENE: PackedScene = preload("res://scenes/plants/flower_tuft.tscn")

const GRASS_MATERIALS: Dictionary = {
	"grass_green": preload("res://shaders/interactive_grass_material.tres"),
	"grass_yellow": preload("res://shaders/interactive_grass_yellow_material.tres"),
	"grass_blue": preload("res://shaders/interactive_grass_blue_material.tres"),
	"grass_purple": preload("res://shaders/interactive_grass_purple_material.tres")
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

# MultiMeshes ativos de vegetação (indexados por mmi_idx de 0 a VEG_TYPES.size() - 1)
var _veg_multimeshes: Array[MultiMesh] = []
var _veg_mmi_nodes: Array[MultiMeshInstance3D] = []

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
	_veg_multimeshes.clear()
	_veg_mmi_nodes.clear()
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

	# 3. Processa objetos (rochas e vegetação em subgrade 2x2 de 0.40m)
	var goals: Dictionary = {}
	var objects_arr: Array = data.get("objects", []) as Array

	var sub_offsets: Array[Vector3] = [
		Vector3(-0.20, 0.0, -0.20),
		Vector3(0.20, 0.0, -0.20),
		Vector3(-0.20, 0.0, 0.20),
		Vector3(0.20, 0.0, 0.20)
	]

	var pending_by_type: Dictionary = {}
	for v_type: String in VEG_TYPES:
		var empty_pos_list: Array[Vector3] = []
		pending_by_type[v_type] = empty_pos_list

	for item: Variant in objects_arr:
		if item is Dictionary:
			var od: Dictionary = item as Dictionary
			var gx: int = int(od.get("gx", 0))
			var gz: int = int(od.get("gz", 0))
			var o_type: String = String(od.get("type", ""))
			var o_rot: int = int(od.get("rot", 0))
			var base_pos: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, cell_size)

			if o_type == "rock":
				var rock_inst: Node3D = LevelJsonLoader.instantiate_object_node("rock", o_rot)
				if rock_inst != null:
					rock_inst.position = base_pos
					if obstacles_container != null:
						obstacles_container.add_child(rock_inst)
					else:
						add_child(rock_inst)
				continue

			elif o_type == "flower" or o_type == "wheat":
				(pending_by_type[o_type] as Array[Vector3]).append(base_pos + sub_offsets[0])
				goals[o_type] = int(goals.get(o_type, 0)) + 1

				for s_idx: int in range(1, 4):
					(pending_by_type["grass_green"] as Array[Vector3]).append(base_pos + sub_offsets[s_idx])
					goals["grass"] = int(goals.get("grass", 0)) + 1

			else:
				var target_type: String = o_type
				if not pending_by_type.has(target_type):
					target_type = "grass_green"
				for offset: Vector3 in sub_offsets:
					(pending_by_type[target_type] as Array[Vector3]).append(base_pos + offset)
					goals["grass"] = int(goals.get("grass", 0)) + 1

	# 4. Constrói os 6 MultiMeshInstance3D de vegetação e popula a grade espacial discreta
	_build_vegetation_multimeshes(pending_by_type)

	# 5. Posiciona o cortador no spawn
	var spawn_dict: Dictionary = data.get("spawn", {}) as Dictionary
	var sp_x: int = int(spawn_dict.get("gx", int(float(width) / 2.0)))
	var sp_z: int = int(spawn_dict.get("gz", int(float(height) / 2.0)))
	var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_x, sp_z, width, height, cell_size)
	if cutter != null:
		cutter.position = Vector3(sp_world.x, 0.1, sp_world.z)
		if "vegetation_grid" in cutter:
			cutter.set("vegetation_grid", self)

	if goals.is_empty():
		goals = { "grass": 1 }

	return goals


func _build_vegetation_multimeshes(pending_by_type: Dictionary) -> void:
	_veg_multimeshes.resize(VEG_TYPES.size())
	_veg_mmi_nodes.resize(VEG_TYPES.size())

	for mmi_idx: int in range(VEG_TYPES.size()):
		var v_type: String = VEG_TYPES[mmi_idx]
		var pos_list: Array[Vector3] = pending_by_type.get(v_type, []) as Array[Vector3]
		var count: int = pos_list.size()

		var mm: MultiMesh = MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		if v_type == "wheat":
			mm.mesh = _wheat_mesh
		elif v_type == "flower":
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

		_veg_multimeshes[mmi_idx] = mm
		_veg_mmi_nodes[mmi_idx] = mmi

		var is_grass: bool = (v_type != "wheat" and v_type != "flower")
		var p_key: String = "grass" if is_grass else v_type
		var max_hp: int = 1 if is_grass else 2
		var reward: int = 1
		if v_type == "wheat":
			reward = 3
		elif v_type == "flower":
			reward = 5
		var p_col: Color = _resolve_type_particle_color(v_type)

		for inst_idx: int in range(count):
			var pos: Vector3 = pos_list[inst_idx]
			var random_rot: float = randf_range(0.0, TAU)
			var scale_vec: Vector3
			if is_grass:
				var scale_y: float = randf_range(0.53, 0.64)
				var scale_xz: float = randf_range(0.40, 0.45)
				scale_vec = Vector3(scale_xz, scale_y, scale_xz)
			else:
				var s: float = randf_range(0.48, 0.58)
				scale_vec = Vector3(s, s, s)

			var basis: Basis = Basis(Vector3.UP, random_rot) * Basis.from_scale(scale_vec)
			var xform: Transform3D = Transform3D(basis, pos)
			mm.set_instance_transform(inst_idx, xform)

			var p_idx: int = _positions.size()
			_positions.append(pos)
			_initial_transforms.append(xform)
			_mmi_indices.append(mmi_idx)
			_instance_indices.append(inst_idx)
			_health.append(max_hp)
			_max_health.append(max_hp)
			_coin_rewards.append(reward)
			_is_cut.append(0)
			_is_hidden_by_density.append(0)
			_last_hit_time.append(-10.0)
			_plant_keys.append(p_key)
			_particle_colors.append(p_col)

			var cell_key: Vector2i = Vector2i(roundi(pos.x / GRID_STEP), roundi(pos.z / GRID_STEP))
			if not _grid.has(cell_key):
				var bucket_new: PackedInt32Array = PackedInt32Array()
				bucket_new.append(p_idx)
				_grid[cell_key] = bucket_new
			else:
				var bucket: PackedInt32Array = _grid[cell_key] as PackedInt32Array
				bucket.append(p_idx)
				_grid[cell_key] = bucket


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
					_spawn_cut_particles_at(p_pos, _particle_colors[p_idx])
					if GameManager != null:
						GameManager.register_cut(_plant_keys[p_idx], _coin_rewards[p_idx])
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

		if _is_cut[p_idx] == 0 and _is_hidden_by_density[p_idx] == 0:
			mm.set_instance_transform(inst_idx, _initial_transforms[p_idx])
		else:
			mm.set_instance_transform(inst_idx, HIDDEN_TRANSFORM)


func reset_all_plants() -> void:
	var total: int = _positions.size()
	for p_idx: int in range(total):
		_is_cut[p_idx] = 0
		_health[p_idx] = _max_health[p_idx]
		_last_hit_time[p_idx] = -10.0
	set_benchmark_visibility(_last_vegetation_on, _last_density_step)
