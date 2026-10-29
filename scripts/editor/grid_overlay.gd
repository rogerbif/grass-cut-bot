extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

var grid_mesh_inst: MeshInstance3D
var preview_fill_inst: MeshInstance3D
var preview_line_inst: MeshInstance3D
var selection_fill_inst: MeshInstance3D
var selection_line_inst: MeshInstance3D
var axis_line_inst: MeshInstance3D

var _grid_mat: StandardMaterial3D
var _preview_fill_mat: StandardMaterial3D
var _preview_line_mat: StandardMaterial3D
var _selection_fill_mat: StandardMaterial3D
var _selection_line_mat: StandardMaterial3D
var _axis_line_mat: StandardMaterial3D

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

	_selection_fill_mat = StandardMaterial3D.new()
	_selection_fill_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selection_fill_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_selection_fill_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_selection_fill_mat.no_depth_test = true
	_selection_fill_mat.albedo_color = Color(0.85, 0.45, 1.0, 0.25)

	_selection_line_mat = StandardMaterial3D.new()
	_selection_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_selection_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_selection_line_mat.no_depth_test = true
	_selection_line_mat.albedo_color = Color(0.95, 0.65, 1.0, 0.95)

	grid_mesh_inst = MeshInstance3D.new()
	grid_mesh_inst.material_override = _grid_mat
	add_child(grid_mesh_inst)

	preview_fill_inst = MeshInstance3D.new()
	preview_fill_inst.material_override = _preview_fill_mat
	add_child(preview_fill_inst)

	preview_line_inst = MeshInstance3D.new()
	preview_line_inst.material_override = _preview_line_mat
	add_child(preview_line_inst)

	selection_fill_inst = MeshInstance3D.new()
	selection_fill_inst.material_override = _selection_fill_mat
	add_child(selection_fill_inst)

	selection_line_inst = MeshInstance3D.new()
	selection_line_inst.material_override = _selection_line_mat
	add_child(selection_line_inst)

	_axis_line_mat = StandardMaterial3D.new()
	_axis_line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_axis_line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_axis_line_mat.no_depth_test = true
	_axis_line_mat.albedo_color = Color(0.95, 0.78, 0.35, 0.85)

	axis_line_inst = MeshInstance3D.new()
	axis_line_inst.material_override = _axis_line_mat
	add_child(axis_line_inst)

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

func rebuild_grid(width: int, height: int, c_size: float = 0.40) -> void:
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
		var is_primary: bool = (x_idx % 2 == 0)
		var col: Color = Color(0.45, 0.95, 1.0, 0.75) if is_border else (Color(1.0, 1.0, 1.0, 0.35) if is_primary else Color(1.0, 1.0, 1.0, 0.16))
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(x_pos, y_pos, min_z))
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(x_pos, y_pos, max_z))

	for z_idx in range(height + 1):
		var z_pos: float = min_z + float(z_idx) * cell_size
		var is_border: bool = (z_idx == 0 or z_idx == height)
		var is_primary: bool = (z_idx % 2 == 0)
		var col: Color = Color(0.45, 0.95, 1.0, 0.75) if is_border else (Color(1.0, 1.0, 1.0, 0.35) if is_primary else Color(1.0, 1.0, 1.0, 0.16))
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(min_x, y_pos, z_pos))
		im.surface_set_color(col)
		im.surface_add_vertex(Vector3(max_x, y_pos, z_pos))

	im.surface_end()
	grid_mesh_inst.mesh = im

func update_brush_preview(
	cells: Array[Vector2i],
	center_cell: Vector2i,
	rot_deg: int,
	fill_color: Color,
	line_color: Color,
	clearance_radius: float = 0.0
) -> void:
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

	# Desenha anel de clareira protegida (ex: raio de 1.40m da maior serra ao redor de rochas)
	if clearance_radius > 0.0 and center_cell.x >= 0 and center_cell.x < current_width and center_cell.y >= 0 and center_cell.y < current_height:
		var c_wp: Vector3 = LevelJsonLoader.grid_to_world(center_cell.x, center_cell.y, current_width, current_height, cell_size)
		var c_center: Vector3 = Vector3(c_wp.x, y_h + 0.015, c_wp.z)
		var segs: int = 36
		for i in range(segs):
			var a0: float = float(i) * TAU / float(segs)
			var a1: float = float(i + 1) * TAU / float(segs)
			var pt0: Vector3 = c_center + Vector3(cos(a0) * clearance_radius, 0.0, sin(a0) * clearance_radius)
			var pt1: Vector3 = c_center + Vector3(cos(a1) * clearance_radius, 0.0, sin(a1) * clearance_radius)
			im_line.surface_add_vertex(pt0)
			im_line.surface_add_vertex(pt1)
			im_fill.surface_add_vertex(c_center)
			im_fill.surface_add_vertex(pt0)
			im_fill.surface_add_vertex(pt1)

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

## Atualiza o retângulo visual de seleção múltipla (Selection Box / Marquee)
func update_selection_preview(
	rect: Rect2i,
	is_active: bool,
	fill_col: Color = Color(0.85, 0.45, 1.0, 0.22),
	line_col: Color = Color(0.95, 0.65, 1.0, 0.95)
) -> void:
	if selection_fill_inst == null or selection_line_inst == null:
		return

	if not is_active or rect.size.x <= 0 or rect.size.y <= 0:
		selection_fill_inst.mesh = null
		selection_line_inst.mesh = null
		return

	_selection_fill_mat.albedo_color = fill_col
	_selection_line_mat.albedo_color = line_col

	var im_fill: ImmediateMesh = ImmediateMesh.new()
	var im_line: ImmediateMesh = ImmediateMesh.new()
	var y_h: float = 0.040

	var min_c: Vector2i = rect.position
	var max_c: Vector2i = rect.position + rect.size - Vector2i(1, 1)

	var p_min: Vector3 = LevelJsonLoader.grid_to_world(min_c.x, min_c.y, current_width, current_height, cell_size)
	var p_max: Vector3 = LevelJsonLoader.grid_to_world(max_c.x, max_c.y, current_width, current_height, cell_size)

	var half: float = cell_size * 0.5
	var x0: float = p_min.x - half
	var x1: float = p_max.x + half
	var z0: float = p_min.z - half
	var z1: float = p_max.z + half

	var v0: Vector3 = Vector3(x0, y_h, z0)
	var v1: Vector3 = Vector3(x1, y_h, z0)
	var v2: Vector3 = Vector3(x1, y_h, z1)
	var v3: Vector3 = Vector3(x0, y_h, z1)

	im_fill.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	im_fill.surface_add_vertex(v0)
	im_fill.surface_add_vertex(v1)
	im_fill.surface_add_vertex(v2)

	im_fill.surface_add_vertex(v0)
	im_fill.surface_add_vertex(v2)
	im_fill.surface_add_vertex(v3)
	im_fill.surface_end()

	im_line.surface_begin(Mesh.PRIMITIVE_LINES)
	# Contorno externo retangular
	im_line.surface_add_vertex(v0)
	im_line.surface_add_vertex(v1)
	im_line.surface_add_vertex(v1)
	im_line.surface_add_vertex(v2)
	im_line.surface_add_vertex(v2)
	im_line.surface_add_vertex(v3)
	im_line.surface_add_vertex(v3)
	im_line.surface_add_vertex(v0)

	# Cantoneiras reforçadas para estética visual profissional
	var bracket_len: float = minf(cell_size * 0.75, (x1 - x0) * 0.3)
	# Canto Top-Left
	im_line.surface_add_vertex(v0)
	im_line.surface_add_vertex(v0 + Vector3(bracket_len, 0.002, 0.0))
	im_line.surface_add_vertex(v0)
	im_line.surface_add_vertex(v0 + Vector3(0.0, 0.002, bracket_len))
	# Canto Top-Right
	im_line.surface_add_vertex(v1)
	im_line.surface_add_vertex(v1 - Vector3(bracket_len, -0.002, 0.0))
	im_line.surface_add_vertex(v1)
	im_line.surface_add_vertex(v1 + Vector3(0.0, 0.002, bracket_len))
	# Canto Bottom-Right
	im_line.surface_add_vertex(v2)
	im_line.surface_add_vertex(v2 - Vector3(bracket_len, -0.002, 0.0))
	im_line.surface_add_vertex(v2)
	im_line.surface_add_vertex(v2 - Vector3(0.0, -0.002, bracket_len))
	# Canto Bottom-Left
	im_line.surface_add_vertex(v3)
	im_line.surface_add_vertex(v3 + Vector3(bracket_len, 0.002, 0.0))
	im_line.surface_add_vertex(v3)
	im_line.surface_add_vertex(v3 - Vector3(0.0, -0.002, bracket_len))

	im_line.surface_end()

	selection_fill_inst.mesh = im_fill
	selection_line_inst.mesh = im_line

## Atualiza a linha guia dos eixos de simetria do modo espelho
func update_mirror_axis(mirror_mode: int) -> void:
	if axis_line_inst == null:
		return
	if mirror_mode == 0:
		axis_line_inst.mesh = null
		return

	var im: ImmediateMesh = ImmediateMesh.new()
	var y_h: float = 0.038
	var max_x: float = float(current_width) * cell_size * 0.5 + 0.35
	var max_z: float = float(current_height) * cell_size * 0.5 + 0.35

	im.surface_begin(Mesh.PRIMITIVE_LINES)

	# Eixo X (divide Esquerda e Direita no centro do mapa em X = 0)
	if mirror_mode == 1 or mirror_mode == 3:
		im.surface_add_vertex(Vector3(0.0, y_h, -max_z))
		im.surface_add_vertex(Vector3(0.0, y_h, max_z))

	# Eixo Z (divide Norte e Sul no centro do mapa em Z = 0)
	if mirror_mode == 2 or mirror_mode == 3:
		im.surface_add_vertex(Vector3(-max_x, y_h, 0.0))
		im.surface_add_vertex(Vector3(max_x, y_h, 0.0))

	im.surface_end()
	axis_line_inst.mesh = im
