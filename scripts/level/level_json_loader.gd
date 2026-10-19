extends RefCounted

const DEFAULT_CELL_SIZE: float = 0.80

const WATER_OCEAN_SCENE: PackedScene = preload("res://scenes/level/water_ocean.tscn")

const TILE_SCENES: Dictionary = {
	"island_center": preload("res://scenes/editor/tiles/tile_island_center.tscn"),
	"island_edge": preload("res://scenes/editor/tiles/tile_island_edge.tscn"),
	"island_corner_out": preload("res://scenes/editor/tiles/tile_island_corner_out.tscn"),
	"island_corner_in": preload("res://scenes/editor/tiles/tile_island_corner_in.tscn"),
	"island_dirt": preload("res://scenes/editor/tiles/tile_island_center.tscn")
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
	# Garante contenção física invisível estanque (Layer 1) e espuma costeira
	# em todas as faces onde um bloco de ilha faz fronteira com a água (vazio).
	var foam_mat: StandardMaterial3D = StandardMaterial3D.new()
	foam_mat.roughness = 0.85
	foam_mat.albedo_color = Color(0.55, 0.86, 0.94, 1.0)

	var lip_mat: StandardMaterial3D = StandardMaterial3D.new()
	lip_mat.roughness = 0.92
	lip_mat.albedo_color = Color(0.26, 0.54, 0.20, 1.0)

	var dirs: Array[Dictionary] = [
		{ "offset": Vector2i(0, -1), "pos": Vector3(0.0, 0.45, -cell_size * 0.48), "size": Vector3(cell_size, 0.9, 0.06), "foam_pos": Vector3(0.0, -0.328, -cell_size * 0.53), "foam_size": Vector3(cell_size + 0.08, 0.02, 0.14), "lip_pos": Vector3(0.0, -0.035, -cell_size * 0.46), "lip_size": Vector3(cell_size, 0.05, 0.07) },
		{ "offset": Vector2i(0, 1),  "pos": Vector3(0.0, 0.45,  cell_size * 0.48), "size": Vector3(cell_size, 0.9, 0.06), "foam_pos": Vector3(0.0, -0.328,  cell_size * 0.53), "foam_size": Vector3(cell_size + 0.08, 0.02, 0.14), "lip_pos": Vector3(0.0, -0.035,  cell_size * 0.46), "lip_size": Vector3(cell_size, 0.05, 0.07) },
		{ "offset": Vector2i(1, 0),  "pos": Vector3( cell_size * 0.48, 0.45, 0.0), "size": Vector3(0.06, 0.9, cell_size), "foam_pos": Vector3( cell_size * 0.53, -0.328, 0.0), "foam_size": Vector3(0.14, 0.02, cell_size + 0.08), "lip_pos": Vector3( cell_size * 0.46, -0.035, 0.0), "lip_size": Vector3(0.07, 0.05, cell_size) },
		{ "offset": Vector2i(-1, 0), "pos": Vector3(-cell_size * 0.48, 0.45, 0.0), "size": Vector3(0.06, 0.9, cell_size), "foam_pos": Vector3(-cell_size * 0.53, -0.328, 0.0), "foam_size": Vector3(0.14, 0.02, cell_size + 0.08), "lip_pos": Vector3(-cell_size * 0.46, -0.035, 0.0), "lip_size": Vector3(0.07, 0.05, cell_size) }
	]

	for cell_key in occupied_cells:
		var cell: Vector2i = cell_key as Vector2i
		var cell_world: Vector3 = grid_to_world(cell.x, cell.y, width, height, cell_size)
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

				# Espuma costeira contínua na linha d'água
				var foam_mesh_inst: MeshInstance3D = MeshInstance3D.new()
				var foam_box: BoxMesh = BoxMesh.new()
				foam_box.size = d["foam_size"] as Vector3
				foam_box.material = foam_mat
				foam_mesh_inst.mesh = foam_box
				foam_mesh_inst.position = cell_world + (d["foam_pos"] as Vector3)
				parent_body.add_child(foam_mesh_inst)

				# Borda de acabamento gramado no topo da falésia
				var lip_mesh_inst: MeshInstance3D = MeshInstance3D.new()
				var lip_box: BoxMesh = BoxMesh.new()
				lip_box.size = d["lip_size"] as Vector3
				lip_box.material = lip_mat
				lip_mesh_inst.mesh = lip_box
				lip_mesh_inst.position = cell_world + (d["lip_pos"] as Vector3)
				parent_body.add_child(lip_mesh_inst)
