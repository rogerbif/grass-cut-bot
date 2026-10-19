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
	# 1. Garante contenção física invisível estanque (Layer 1)
	# em todas as faces onde um bloco de ilha faz fronteira com a água (vazio).
	var dirs: Array[Dictionary] = [
		{ "offset": Vector2i(0, -1), "pos": Vector3(0.0, 0.45, -cell_size * 0.48), "size": Vector3(cell_size, 1.2, 0.06), "norm": Vector3(0.0, 0.0, -1.0) },
		{ "offset": Vector2i(0, 1),  "pos": Vector3(0.0, 0.45,  cell_size * 0.48), "size": Vector3(cell_size, 1.2, 0.06), "norm": Vector3(0.0, 0.0, 1.0) },
		{ "offset": Vector2i(1, 0),  "pos": Vector3( cell_size * 0.48, 0.45, 0.0), "size": Vector3(0.06, 1.2, cell_size), "norm": Vector3(1.0, 0.0, 0.0) },
		{ "offset": Vector2i(-1, 0), "pos": Vector3(-cell_size * 0.48, 0.45, 0.0), "size": Vector3(0.06, 1.2, cell_size), "norm": Vector3(-1.0, 0.0, 0.0) }
	]

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var half_s: float = cell_size * 0.5
	var inner_r: float = cell_size * 0.32 # Rente à base da falésia
	var outer_r: float = cell_size * 0.58 # Estende para a água
	var foam_y: float = -0.695 # 1.5cm acima do plano da água (-0.71m)

	for cell_key in occupied_cells:
		var cell: Vector2i = cell_key as Vector2i
		var cell_world: Vector3 = grid_to_world(cell.x, cell.y, width, height, cell_size)
		var cx: float = cell_world.x
		var cz: float = cell_world.z

		var has_open_n: bool = not occupied_cells.has(cell + Vector2i(0, -1))
		var has_open_s: bool = not occupied_cells.has(cell + Vector2i(0, 1))
		var has_open_e: bool = not occupied_cells.has(cell + Vector2i(1, 0))
		var has_open_w: bool = not occupied_cells.has(cell + Vector2i(-1, 0))

		for d in dirs:
			var neighbor: Vector2i = cell + (d["offset"] as Vector2i)
			if not occupied_cells.has(neighbor):
				# Colisor invisível de costa (impede queda na água sem cerca)
				var col: CollisionShape3D = CollisionShape3D.new()
				var box: BoxShape3D = BoxShape3D.new()
				box.size = d["size"] as Vector3
				col.shape = box
				col.position = cell_world + (d["pos"] as Vector3)
				parent_body.add_child(col)

		# 2. Gera geometria da fita de espuma costeira nos lados abertos
		if has_open_n:
			_add_foam_quad(st,
				Vector3(cx - half_s, foam_y, cz - inner_r),
				Vector3(cx + half_s, foam_y, cz - inner_r),
				Vector3(cx + half_s, foam_y, cz - outer_r),
				Vector3(cx - half_s, foam_y, cz - outer_r),
				Vector3(0.0, 0.0, -1.0)
			)
		if has_open_s:
			_add_foam_quad(st,
				Vector3(cx + half_s, foam_y, cz + inner_r),
				Vector3(cx - half_s, foam_y, cz + inner_r),
				Vector3(cx - half_s, foam_y, cz + outer_r),
				Vector3(cx + half_s, foam_y, cz + outer_r),
				Vector3(0.0, 0.0, 1.0)
			)
		if has_open_w:
			_add_foam_quad(st,
				Vector3(cx - inner_r, foam_y, cz + half_s),
				Vector3(cx - inner_r, foam_y, cz - half_s),
				Vector3(cx - outer_r, foam_y, cz - half_s),
				Vector3(cx - outer_r, foam_y, cz + half_s),
				Vector3(-1.0, 0.0, 0.0)
			)
		if has_open_e:
			_add_foam_quad(st,
				Vector3(cx + inner_r, foam_y, cz - half_s),
				Vector3(cx + inner_r, foam_y, cz + half_s),
				Vector3(cx + outer_r, foam_y, cz + half_s),
				Vector3(cx + outer_r, foam_y, cz - half_s),
				Vector3(1.0, 0.0, 0.0)
			)

		# Quinas externas diagonais para fechamento estanque contínuo
		if has_open_n and has_open_w:
			_add_foam_quad(st,
				Vector3(cx - inner_r, foam_y, cz - inner_r),
				Vector3(cx - half_s, foam_y, cz - inner_r),
				Vector3(cx - outer_r, foam_y, cz - outer_r),
				Vector3(cx - inner_r, foam_y, cz - half_s),
				Vector3(-0.707, 0.0, -0.707)
			)
		if has_open_n and has_open_e:
			_add_foam_quad(st,
				Vector3(cx + half_s, foam_y, cz - inner_r),
				Vector3(cx + inner_r, foam_y, cz - inner_r),
				Vector3(cx + inner_r, foam_y, cz - half_s),
				Vector3(cx + outer_r, foam_y, cz - outer_r),
				Vector3(0.707, 0.0, -0.707)
			)
		if has_open_s and has_open_w:
			_add_foam_quad(st,
				Vector3(cx - inner_r, foam_y, cz + half_s),
				Vector3(cx - outer_r, foam_y, cz + outer_r),
				Vector3(cx - half_s, foam_y, cz + inner_r),
				Vector3(cx - inner_r, foam_y, cz + inner_r),
				Vector3(-0.707, 0.0, 0.707)
			)
		if has_open_s and has_open_e:
			_add_foam_quad(st,
				Vector3(cx + inner_r, foam_y, cz + inner_r),
				Vector3(cx + half_s, foam_y, cz + inner_r),
				Vector3(cx + outer_r, foam_y, cz + outer_r),
				Vector3(cx + inner_r, foam_y, cz + half_s),
				Vector3(0.707, 0.0, 0.707)
			)

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

static func _add_foam_quad(st: SurfaceTool, p0: Vector3, p1: Vector3, p2: Vector3, p3: Vector3, norm: Vector3) -> void:
	# p0 e p1: base rente à falésia (UV.y = 0.0)
	# p2 e p3: ponta externa na água (UV.y = 1.0)
	# Triângulo 1: p0, p1, p2
	st.set_normal(norm)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(p0)

	st.set_normal(norm)
	st.set_uv(Vector2(1.0, 0.0))
	st.add_vertex(p1)

	st.set_normal(norm)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(p2)

	# Triângulo 2: p0, p2, p3
	st.set_normal(norm)
	st.set_uv(Vector2(0.0, 0.0))
	st.add_vertex(p0)

	st.set_normal(norm)
	st.set_uv(Vector2(1.0, 1.0))
	st.add_vertex(p2)

	st.set_normal(norm)
	st.set_uv(Vector2(0.0, 1.0))
	st.add_vertex(p3)

