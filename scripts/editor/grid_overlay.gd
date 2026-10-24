extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

var grid_mesh_inst: MeshInstance3D
var preview_fill_inst: MeshInstance3D
var preview_line_inst: MeshInstance3D

var _grid_mat: StandardMaterial3D
var _preview_fill_mat: StandardMaterial3D
var _preview_line_mat: StandardMaterial3D

var current_width: int = 14
var current_height: int = 10
var cell_size: float = 0.80

func _ready() -> void:
	_grid_mat = StandardMaterial3D.new()
	_grid_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_grid_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_grid_mat.vertex_color_use_as_albedo = true

	_preview_fill_mat = StandardMaterial3D.new()
	_preview_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_preview_fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_preview_fill_mat.no_depth_test = true
	_preview_fill_mat.albedo_color = Color(0.2, 1.0, 0.55, 0.38)

	_preview_line_mat = StandardMaterial3D.new()
	_preview_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_preview_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_line_mat.no_depth_test = true
	_preview_line_mat.albedo_color = Color(0.4, 1.0, 0.75, 0.95)

	grid_mesh_inst = MeshInstance3D.new()
	grid_mesh_inst.material_override = _grid_mat
	add_child(grid_mesh_inst)

	preview_fill_inst = MeshInstance3D.new()
	preview_fill_inst.material_override = _preview_fill_mat
	add_child(preview_fill_inst)

	preview_line_inst = MeshInstance3D.new()
	preview_line_inst.material_override = _preview_line_mat
	add_child(preview_line_inst)

	rebuild_grid(current_width, current_height, cell_size)

func update_field_preview(
	field_cells: Array[Vector2i],
	line_color: Color,
	fill_color: Color
) -> void:
	if preview_fill_inst == null or preview_line_inst == null:
		return

	if field_cells.is_empty():
		preview_fill_inst.mesh = null
		preview_line_inst.mesh = null
		return

	_preview_fill_mat.albedo_color = fill_color
	_preview_line_mat.albedo_color = line_color

	var im_fill: ImmediateMesh = ImmediateMesh.new()
	var im_line: ImmediateMesh = ImmediateMesh.new()
	var res: float = 0.20
	var half: float = (res * 0.94) / 2.0
	var y_h: float = 0.038

	var total_w_m: float = float(current_width) * cell_size
	var total_h_m: float = float(current_height) * cell_size
	var origin_x: float = -total_w_m * 0.5
	var origin_z: float = -total_h_m * 0.5

	im_fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	im_line.surface_begin(Mesh.PRIMITIVE_LINES)

	for c in field_cells:
		var wp_x: float = origin_x + (float(c.x) + 0.5) * res
		var wp_z: float = origin_z + (float(c.y) + 0.5) * res
		var p0: Vector3 = Vector3(wp_x - half, y_h, wp_z - half)
		var p1: Vector3 = Vector3(wp_x + half, y_h, wp_z - half)
		var p2: Vector3 = Vector3(wp_x + half, y_h, wp_z + half)
		var p3: Vector3 = Vector3(wp_x - half, y_h, wp_z + half)

		im_fill.surface_add_vertex(p0)
		im_fill.surface_add_vertex(p1)
		im_fill.surface_add_vertex(p2)

		im_fill.surface_add_vertex(p0)
		im_fill.surface_add_vertex(p2)
		im_fill.surface_add_vertex(p3)

		im_line.surface_add_vertex(p0)
		im_line.surface_add_vertex(p1)
		im_line.surface_add_vertex(p1)
		im_line.surface_add_vertex(p2)
		im_line.surface_add_vertex(p2)
		im_line.surface_add_vertex(p3)
		im_line.surface_add_vertex(p3)
		im_line.surface_add_vertex(p0)

	im_fill.surface_end()
	im_line.surface_end()

	preview_fill_inst.mesh = im_fill
	preview_line_inst.mesh = im_line

## Atualiza a visualização holográfica de um polígono vetorial analítico no chão da ilha
func update_vector_preview(
	poly: PackedVector2Array,
	line_color: Color,
	fill_color: Color
) -> void:
	if preview_fill_inst == null or preview_line_inst == null:
		return

	if poly.size() < 3:
		preview_fill_inst.mesh = null
		preview_line_inst.mesh = null
		return

	_preview_fill_mat.albedo_color = fill_color
	_preview_line_mat.albedo_color = line_color

	var y_h: float = 0.040
	var indices: PackedInt32Array = Geometry2D.triangulate_polygon(poly)
	if not indices.is_empty():
		var im_fill: ImmediateMesh = ImmediateMesh.new()
		im_fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for idx: int in indices:
			var pt: Vector2 = poly[idx]
			im_fill.surface_add_vertex(Vector3(pt.x, y_h, pt.y))
		im_fill.surface_end()
		preview_fill_inst.mesh = im_fill
	else:
		preview_fill_inst.mesh = null

	var im_line: ImmediateMesh = ImmediateMesh.new()
	im_line.surface_begin(Mesh.PRIMITIVE_LINES)
	var n: int = poly.size()
	for i: int in range(n):
		var p0: Vector2 = poly[i]
		var p1: Vector2 = poly[(i + 1) % n]
		im_line.surface_add_vertex(Vector3(p0.x, y_h + 0.002, p0.y))
		im_line.surface_add_vertex(Vector3(p1.x, y_h + 0.002, p1.y))
	im_line.surface_end()
	preview_line_inst.mesh = im_line

func rebuild_grid(width: int, height: int, c_size: float = 0.80) -> void:
	current_width = width
	current_height = height
	cell_size = c_size

	if grid_mesh_inst == null:
		return

	var im: ImmediateMesh = ImmediateMesh.new()
	var total_w: float = float(width) * cell_size
	var total_h: float = float(height) * cell_size
	var min_x: float = -total_w / 2.0
	var max_x: float = total_w / 2.0
	var min_z: float = -total_h / 2.0
	var max_z: float = total_h / 2.0
	var y_pos: float = 0.012

	im.surface_begin(Mesh.PRIMITIVE_LINES)

	for x_idx in range(width + 1):
		var x_pos: float = min_x + float(x_idx) * cell_size
		var is_border: bool = (x_idx == 0 or x_idx == width)
		var col: Color = Color(0.45, 0.95, 1.0, 0.75) if is_border else Color(1.0, 1.0, 1.0, 0.22)
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(x_pos, y_pos, min_z))
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(x_pos, y_pos, max_z))

	for z_idx in range(height + 1):
		var z_pos: float = min_z + float(z_idx) * cell_size
		var is_border: bool = (z_idx == 0 or z_idx == height)
		var col: Color = Color(0.45, 0.95, 1.0, 0.75) if is_border else Color(1.0, 1.0, 1.0, 0.22)
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(min_x, y_pos, z_pos))
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(max_x, y_pos, z_pos))

	im.surface_end()
	grid_mesh_inst.mesh = im

func update_brush_preview(cells: Array[Vector2i], center_cell: Vector2i, rot_deg: int, fill_color: Color, line_color: Color) -> void:
	if preview_fill_inst == null or preview_line_inst == null:
		return

	if cells.is_empty():
		preview_fill_inst.mesh = null
		preview_line_inst.mesh = null
		return

	_preview_fill_mat.albedo_color = fill_color
	_preview_line_mat.albedo_color = line_color

	var im_fill: ImmediateMesh = ImmediateMesh.new()
	var im_line: ImmediateMesh = ImmediateMesh.new()
	var half: float = (cell_size * 0.92) / 2.0
	var y_h: float = 0.035

	im_fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	im_line.surface_begin(Mesh.PRIMITIVE_LINES)

	for cell in cells:
		if cell.x < 0 or cell.x >= current_width or cell.y < 0 or cell.y >= current_height:
			continue
		var wp: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, current_width, current_height, cell_size)
		var p0: Vector3 = Vector3(wp.x - half, y_h, wp.z - half)
		var p1: Vector3 = Vector3(wp.x + half, y_h, wp.z - half)
		var p2: Vector3 = Vector3(wp.x + half, y_h, wp.z + half)
		var p3: Vector3 = Vector3(wp.x - half, y_h, wp.z + half)

		# Dois triângulos formando o quad holográfico
		im_fill.surface_add_vertex(p0)
		im_fill.surface_add_vertex(p1)
		im_fill.surface_add_vertex(p2)

		im_fill.surface_add_vertex(p0)
		im_fill.surface_add_vertex(p2)
		im_fill.surface_add_vertex(p3)

		# Contorno nítido da célula
		im_line.surface_add_vertex(p0)
		im_line.surface_add_vertex(p1)
		im_line.surface_add_vertex(p1)
		im_line.surface_add_vertex(p2)
		im_line.surface_add_vertex(p2)
		im_line.surface_add_vertex(p3)
		im_line.surface_add_vertex(p3)
		im_line.surface_add_vertex(p0)

	# Desenha seta direcional na célula central para indicar a orientação de rotação (R)
	if center_cell.x >= 0 and center_cell.x < current_width and center_cell.y >= 0 and center_cell.y < current_height:
		var c_wp: Vector3 = LevelJsonLoader.grid_to_world(center_cell.x, center_cell.y, current_width, current_height, cell_size)
		var rad: float = deg_to_rad(float(rot_deg))
		var fwd: Vector3 = Vector3(sin(rad), 0.0, -cos(rad))
		var right_v: Vector3 = Vector3(cos(rad), 0.0, sin(rad))
		var tip: Vector3 = Vector3(c_wp.x, y_h + 0.02, c_wp.z) + fwd * (half * 0.78)
		var tail: Vector3 = Vector3(c_wp.x, y_h + 0.02, c_wp.z) - fwd * (half * 0.45)
		var wing_l: Vector3 = tip - fwd * 0.14 - right_v * 0.12
		var wing_r: Vector3 = tip - fwd * 0.14 + right_v * 0.12

		im_line.surface_add_vertex(tail)
		im_line.surface_add_vertex(tip)
		im_line.surface_add_vertex(tip)
		im_line.surface_add_vertex(wing_l)
		im_line.surface_add_vertex(tip)
		im_line.surface_add_vertex(wing_r)

	im_fill.surface_end()
	im_line.surface_end()

	preview_fill_inst.mesh = im_fill
	preview_line_inst.mesh = im_line
