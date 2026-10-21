extends RefCounted

const DEFAULT_CELL_SIZE: float = 0.80

const WATER_OCEAN_SCENE: PackedScene = preload("res://scenes/level/water_ocean.tscn")

const TILE_SCENES: Dictionary = {
	"island_center": preload("res://scenes/editor/tiles/tile_island_center.tscn"),
	"island_edge": preload("res://scenes/editor/tiles/tile_island_edge.tscn"),
	"island_corner_out": preload("res://scenes/editor/tiles/tile_island_corner_out.tscn"),
	"island_corner_in": preload("res://scenes/editor/tiles/tile_island_corner_in.tscn"),
	"island_end": preload("res://scenes/editor/tiles/tile_island_end.tscn"),
	"island_dirt": preload("res://scenes/editor/tiles/tile_island_dirt.tscn")
}

const OBJECT_SCENES: Dictionary = {
	"grass_green": preload("res://scenes/plants/grass_tuft.tscn"),
	"grass_yellow": preload("res://scenes/plants/grass_yellow.tscn"),
	"grass_blue": preload("res://scenes/plants/grass_blue.tscn"),
	"grass_purple": preload("res://scenes/plants/grass_purple.tscn"),
	"grass_white": preload("res://scenes/plants/grass_white.tscn"),
	"grass_red": preload("res://scenes/plants/grass_red.tscn"),
	"grass_black": preload("res://scenes/plants/grass_black.tscn"),
	"wheat": preload("res://scenes/plants/wheat_tuft.tscn"),
	"flower": preload("res://scenes/plants/flower_tuft.tscn"),
	"rock": preload("res://scenes/obstacles/rock.tscn")
}

static func grid_to_world(gx: int, gz: int, width: int, height: int, cell_size: float = DEFAULT_CELL_SIZE) -> Vector3:
	var offset_x: float = -(float(width) * cell_size) / 2.0 + (cell_size / 2.0)
	var offset_z: float = -(float(height) * cell_size) / 2.0 + (cell_size / 2.0)
	return Vector3(
		offset_x + float(gx) * cell_size,
		0.0,
		offset_z + float(gz) * cell_size
	)

static func world_to_grid(world_pos: Vector3, width: int, height: int, cell_size: float = DEFAULT_CELL_SIZE) -> Vector2i:
	var offset_x: float = -(float(width) * cell_size) / 2.0 + (cell_size / 2.0)
	var offset_z: float = -(float(height) * cell_size) / 2.0 + (cell_size / 2.0)
	var gx: int = roundi((world_pos.x - offset_x) / cell_size)
	var gz: int = roundi((world_pos.z - offset_z) / cell_size)
	return Vector2i(gx, gz)

static func load_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}

static func instantiate_tile_node(tile_id: String, rot_deg: int) -> Node3D:
	var scene_key: String = tile_id
	if not TILE_SCENES.has(scene_key):
		scene_key = "island_center"
	var packed: PackedScene = TILE_SCENES[scene_key] as PackedScene
	if packed == null:
		return null
	var node: Node3D = packed.instantiate() as Node3D
	if node != null:
		node.rotation_degrees.y = float(rot_deg)
	return node

static func instantiate_object_node(obj_type: String, rot_deg: int = 0) -> Node3D:
	if not OBJECT_SCENES.has(obj_type):
		return null
	var packed: PackedScene = OBJECT_SCENES[obj_type] as PackedScene
	if packed == null:
		return null
	var node: Node3D = packed.instantiate() as Node3D
	if node != null and rot_deg != 0:
		node.rotation_degrees.y = float(rot_deg)
	return node

static func build_coastal_colliders_and_foam(
	parent_body: StaticBody3D,
	occupied_cells: Dictionary,
	width: int,
	height: int,
	cell_size: float = DEFAULT_CELL_SIZE
) -> void:
	# 1. Garante contenção física invisível estanque (Layer 1) com mesclagem gulosa (greedy merge)
	# de segmentos colineares onde blocos de ilha fazem fronteira com a água (vazio).
	var north_by_z: Dictionary = {}
	var south_by_z: Dictionary = {}
	var east_by_x: Dictionary = {}
	var west_by_x: Dictionary = {}

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var foam_y: float = -0.692 # Acima do plano da água (-0.71m)

	for cell_key in occupied_cells:
		var cell: Vector2i = cell_key as Vector2i
		var cell_world: Vector3 = grid_to_world(cell.x, cell.y, width, height, cell_size)

		if not occupied_cells.has(cell + Vector2i(0, -1)):
			if not north_by_z.has(cell.y):
				var arr_n: Array[int] = []
				north_by_z[cell.y] = arr_n
			(north_by_z[cell.y] as Array[int]).append(cell.x)
		if not occupied_cells.has(cell + Vector2i(0, 1)):
			if not south_by_z.has(cell.y):
				var arr_s: Array[int] = []
				south_by_z[cell.y] = arr_s
			(south_by_z[cell.y] as Array[int]).append(cell.x)
		if not occupied_cells.has(cell + Vector2i(1, 0)):
			if not east_by_x.has(cell.x):
				var arr_e: Array[int] = []
				east_by_x[cell.x] = arr_e
			(east_by_x[cell.x] as Array[int]).append(cell.y)
		if not occupied_cells.has(cell + Vector2i(-1, 0)):
			if not west_by_x.has(cell.x):
				var arr_w: Array[int] = []
				west_by_x[cell.x] = arr_w
			(west_by_x[cell.x] as Array[int]).append(cell.y)

		var tile_id: String = "island_center"
		var tile_rot: int = 0
		var entry_val: Variant = occupied_cells[cell]
		if entry_val is Dictionary:
			var entry_dict: Dictionary = entry_val as Dictionary
			tile_id = String(entry_dict.get("tile_id", "island_center"))
			tile_rot = int(entry_dict.get("rot", 0))

		if tile_id == "island_edge" or tile_id == "island_corner_out" or tile_id == "island_corner_in" or tile_id == "island_end":
			_add_tile_foam_curve(st, tile_id, tile_rot, cell_world, foam_y, cell_size)
		else:
			# Fallback para blocos planos que façam fronteira direta com a água
			if not occupied_cells.has(cell + Vector2i(0, -1)):
				_add_tile_foam_curve(st, "island_edge", 0, cell_world, foam_y, cell_size)
			if not occupied_cells.has(cell + Vector2i(0, 1)):
				_add_tile_foam_curve(st, "island_edge", 180, cell_world, foam_y, cell_size)
			if not occupied_cells.has(cell + Vector2i(1, 0)):
				_add_tile_foam_curve(st, "island_edge", 270, cell_world, foam_y, cell_size)
			if not occupied_cells.has(cell + Vector2i(-1, 0)):
				_add_tile_foam_curve(st, "island_edge", 90, cell_world, foam_y, cell_size)

	_add_merged_horizontal_colliders(parent_body, north_by_z, -cell_size * 0.48, width, height, cell_size)
	_add_merged_horizontal_colliders(parent_body, south_by_z, cell_size * 0.48, width, height, cell_size)
	_add_merged_vertical_colliders(parent_body, east_by_x, cell_size * 0.48, width, height, cell_size)
	_add_merged_vertical_colliders(parent_body, west_by_x, -cell_size * 0.48, width, height, cell_size)

	var foam_mesh: ArrayMesh = st.commit()
	if foam_mesh != null and foam_mesh.get_surface_count() > 0:
		var foam_inst: MeshInstance3D = MeshInstance3D.new()
		foam_inst.name = "CoastalFoamRibbon"
		foam_inst.mesh = foam_mesh
		var foam_shader: Shader = preload("res://shaders/coastal_foam.gdshader")
		var foam_mat: ShaderMaterial = ShaderMaterial.new()
		foam_mat.shader = foam_shader
		foam_inst.material_override = foam_mat
		parent_body.add_child(foam_inst)

static func _add_merged_horizontal_colliders(
	parent_body: StaticBody3D,
	edges_by_z: Dictionary,
	z_offset: float,
	width: int,
	height: int,
	cell_size: float
) -> void:
	for z_key in edges_by_z:
		var gz: int = int(z_key)
		var xs: Array[int] = edges_by_z[z_key] as Array[int]
		if xs.is_empty():
			continue
		xs.sort()
		var run_start: int = xs[0]
		var run_end: int = xs[0]
		for i in range(1, xs.size()):
			var x_val: int = xs[i]
			if x_val == run_end + 1:
				run_end = x_val
			else:
				_create_horizontal_collider_segment(parent_body, run_start, run_end, gz, z_offset, width, height, cell_size)
				run_start = x_val
				run_end = x_val
		_create_horizontal_collider_segment(parent_body, run_start, run_end, gz, z_offset, width, height, cell_size)

static func _create_horizontal_collider_segment(
	parent_body: StaticBody3D,
	x_start: int,
	x_end: int,
	gz: int,
	z_offset: float,
	width: int,
	height: int,
	cell_size: float
) -> void:
	var run_len: int = x_end - x_start + 1
	var p_start: Vector3 = grid_to_world(x_start, gz, width, height, cell_size)
	var p_end: Vector3 = grid_to_world(x_end, gz, width, height, cell_size)
	var center_world: Vector3 = (p_start + p_end) * 0.5
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(float(run_len) * cell_size, 1.2, 0.06)
	col.shape = box
	col.position = center_world + Vector3(0.0, 0.45, z_offset)
	parent_body.add_child(col)

static func _add_merged_vertical_colliders(
	parent_body: StaticBody3D,
	edges_by_x: Dictionary,
	x_offset: float,
	width: int,
	height: int,
	cell_size: float
) -> void:
	for x_key in edges_by_x:
		var gx: int = int(x_key)
		var zs: Array[int] = edges_by_x[x_key] as Array[int]
		if zs.is_empty():
			continue
		zs.sort()
		var run_start: int = zs[0]
		var run_end: int = zs[0]
		for i in range(1, zs.size()):
			var z_val: int = zs[i]
			if z_val == run_end + 1:
				run_end = z_val
			else:
				_create_vertical_collider_segment(parent_body, gx, run_start, run_end, x_offset, width, height, cell_size)
				run_start = z_val
				run_end = z_val
		_create_vertical_collider_segment(parent_body, gx, run_start, run_end, x_offset, width, height, cell_size)

static func _create_vertical_collider_segment(
	parent_body: StaticBody3D,
	gx: int,
	z_start: int,
	z_end: int,
	x_offset: float,
	width: int,
	height: int,
	cell_size: float
) -> void:
	var run_len: int = z_end - z_start + 1
	var p_start: Vector3 = grid_to_world(gx, z_start, width, height, cell_size)
	var p_end: Vector3 = grid_to_world(gx, z_end, width, height, cell_size)
	var center_world: Vector3 = (p_start + p_end) * 0.5
	var col: CollisionShape3D = CollisionShape3D.new()
	var box: BoxShape3D = BoxShape3D.new()
	box.size = Vector3(0.06, 1.2, float(run_len) * cell_size)
	col.shape = box
	col.position = center_world + Vector3(x_offset, 0.45, 0.0)
	parent_body.add_child(col)

static func _add_tile_foam_curve(
	st: SurfaceTool,
	tile_id: String,
	tile_rot: int,
	cell_world: Vector3,
	foam_y: float,
	cell_size: float
) -> void:
	var scale_f: float = cell_size / DEFAULT_CELL_SIZE
	var inset: float = 0.025 * scale_f
	var foam_w: float = 0.195 * scale_f
	var pts: Array[Vector2] = []
	var norms: Array[Vector2] = []

	if tile_id == "island_edge":
		var steps: int = 4
		for i in range(steps + 1):
			var t: float = float(i) / float(steps)
			pts.append(Vector2(lerpf(-0.40, 0.40, t) * scale_f, -0.20 * scale_f))
			norms.append(Vector2(0.0, -1.0))
	elif tile_id == "island_corner_out":
		pts.append(Vector2(-0.40 * scale_f, -0.20 * scale_f))
		norms.append(Vector2(0.0, -1.0))
		var arc_steps: int = 10
		var center_out: Vector2 = Vector2(-0.12, 0.12)
		var radius_out: float = 0.32
		for i in range(arc_steps + 1):
			var t: float = float(i) / float(arc_steps)
			var ang: float = lerpf(-PI * 0.5, 0.0, t)
			var dir: Vector2 = Vector2(cos(ang), sin(ang))
			pts.append((center_out + dir * radius_out) * scale_f)
			norms.append(dir)
		pts.append(Vector2(0.20 * scale_f, 0.40 * scale_f))
		norms.append(Vector2(1.0, 0.0))
	elif tile_id == "island_corner_in":
		var arc_steps_in: int = 10
		var center_in: Vector2 = Vector2(-0.40, -0.40)
		var radius_in: float = 0.20
		for i in range(arc_steps_in + 1):
			var t: float = float(i) / float(arc_steps_in)
			var ang: float = lerpf(PI * 0.5, 0.0, t)
			var dir: Vector2 = Vector2(cos(ang), sin(ang))
			pts.append((center_in + dir * radius_in) * scale_f)
			norms.append(-dir)
	elif tile_id == "island_end":
		pts.append(Vector2(-0.20 * scale_f, 0.40 * scale_f))
		norms.append(Vector2(-1.0, 0.0))
		var arc_steps_end: int = 12
		var radius_end: float = 0.20
		for i in range(arc_steps_end + 1):
			var t: float = float(i) / float(arc_steps_end)
			var ang: float = lerpf(-PI, 0.0, t)
			var dir: Vector2 = Vector2(cos(ang), sin(ang))
			pts.append(dir * radius_end * scale_f)
			norms.append(dir)
		pts.append(Vector2(0.20 * scale_f, 0.40 * scale_f))
		norms.append(Vector2(1.0, 0.0))

	if pts.size() < 2:
		return

	var rot_rad: float = deg_to_rad(float(tile_rot))
	var count: int = pts.size() - 1
	for i in range(count):
		var u0: float = float(i) / float(count)
		var u1: float = float(i + 1) / float(count)

		var p0_2d: Vector2 = pts[i]
		var p1_2d: Vector2 = pts[i + 1]
		var n0_2d: Vector2 = norms[i]
		var n1_2d: Vector2 = norms[i + 1]

		var in0_local: Vector3 = Vector3(p0_2d.x - n0_2d.x * inset, 0.0, p0_2d.y - n0_2d.y * inset).rotated(Vector3.UP, rot_rad)
		var in1_local: Vector3 = Vector3(p1_2d.x - n1_2d.x * inset, 0.0, p1_2d.y - n1_2d.y * inset).rotated(Vector3.UP, rot_rad)
		var out0_local: Vector3 = Vector3(p0_2d.x + n0_2d.x * foam_w, 0.0, p0_2d.y + n0_2d.y * foam_w).rotated(Vector3.UP, rot_rad)
		var out1_local: Vector3 = Vector3(p1_2d.x + n1_2d.x * foam_w, 0.0, p1_2d.y + n1_2d.y * foam_w).rotated(Vector3.UP, rot_rad)

		var n0_world: Vector3 = Vector3(n0_2d.x, 0.0, n0_2d.y).rotated(Vector3.UP, rot_rad).normalized()
		var n1_world: Vector3 = Vector3(n1_2d.x, 0.0, n1_2d.y).rotated(Vector3.UP, rot_rad).normalized()

		var v_in0: Vector3 = Vector3(cell_world.x + in0_local.x, foam_y, cell_world.z + in0_local.z)
		var v_in1: Vector3 = Vector3(cell_world.x + in1_local.x, foam_y, cell_world.z + in1_local.z)
		var v_out1: Vector3 = Vector3(cell_world.x + out1_local.x, foam_y, cell_world.z + out1_local.z)
		var v_out0: Vector3 = Vector3(cell_world.x + out0_local.x, foam_y, cell_world.z + out0_local.z)

		# Triângulo 1: v_in0, v_in1, v_out1
		st.set_normal(n0_world)
		st.set_uv(Vector2(u0, 0.0))
		st.add_vertex(v_in0)

		st.set_normal(n1_world)
		st.set_uv(Vector2(u1, 0.0))
		st.add_vertex(v_in1)

		st.set_normal(n1_world)
		st.set_uv(Vector2(u1, 1.0))
		st.add_vertex(v_out1)

		# Triângulo 2: v_in0, v_out1, v_out0
		st.set_normal(n0_world)
		st.set_uv(Vector2(u0, 0.0))
		st.add_vertex(v_in0)

		st.set_normal(n1_world)
		st.set_uv(Vector2(u1, 1.0))
		st.add_vertex(v_out1)

		st.set_normal(n0_world)
		st.set_uv(Vector2(u0, 1.0))
		st.add_vertex(v_out0)


