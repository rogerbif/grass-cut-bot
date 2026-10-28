class_name IslandMeshBuilder
extends RefCounted

## Gerador Procedural de Ilhas 3D por Polígono Vetorial Extrudado (Grass Cut Bot).
## Constrói a malha unificada da ilha (teto de grama, chanfro low poly, falésias de rocha),
## a fita contínua de espuma costeira e as barreiras físicas invisíveis na Camada 1.

const CLIFF_DEPTH: float = 0.72
const BEVEL_DEPTH: float = 0.06
const BEVEL_OUTSET: float = 0.015
const FOAM_Y_LEVEL: float = -0.692
const FOAM_INSET: float = 0.025
const FOAM_WIDTH: float = 0.195
const BOUNDARY_WALL_HEIGHT: float = 1.20
const BOUNDARY_WALL_THICKNESS: float = 0.06
const DEFAULT_CORNER_RADIUS: float = 0.28
const DEFAULT_CORNER_ARC_STEPS: int = 5

# Coordenadas UV canônicas no atlas de cores GRADIENT (tile_island_center_Image_0.png)
const UV_GRASS_TOP: Vector2 = Vector2(0.819989, 0.789990)
const UV_DIRT_TOP: Vector2 = Vector2(0.379995, 0.619989)
const UV_CLIFF_WALL: Vector2 = Vector2(0.189990, 0.169986)

const PALETTE_TEXTURE_PATH: String = "res://assets/models/tiles/tile_island_center_Image_0.png"
const FOAM_SHADER_PATH: String = "res://shaders/coastal_foam.gdshader"

# Parâmetros Canônicos do Solo da Ilha e Falésias (Calibrados)
static var ground_base_color: Color = Color(0.14, 0.45, 0.19, 1.0)
static var ground_brightness: float = 0.80
static var ground_diffuse_toon: bool = true
const CLIFF_COLOR: Color = Color(0.4667, 0.2431, 0.1451, 1.0)
const DIRT_COLOR: Color = Color(0.38, 0.25, 0.15, 1.0)

static var _island_material: StandardMaterial3D = null
static var _foam_material: ShaderMaterial = null


static func get_final_ground_color() -> Color:
	return Color(
		ground_base_color.r * ground_brightness,
		ground_base_color.g * ground_brightness,
		ground_base_color.b * ground_brightness,
		1.0
	)


static func set_ground_parameters(base_color: Color, brightness: float = 0.80, use_toon: bool = true) -> void:
	ground_base_color = base_color
	ground_brightness = brightness
	ground_diffuse_toon = use_toon
	if _island_material != null:
		_island_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON if ground_diffuse_toon else BaseMaterial3D.DIFFUSE_BURLEY


static func get_island_material() -> StandardMaterial3D:
	if _island_material != null:
		return _island_material

	_island_material = StandardMaterial3D.new()
	_island_material.resource_name = "Mat_ProceduralIsland"
	_island_material.roughness = 0.90
	_island_material.specular_mode = BaseMaterial3D.SPECULAR_DISABLED
	_island_material.cull_mode = BaseMaterial3D.CULL_BACK
	_island_material.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	_island_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON if ground_diffuse_toon else BaseMaterial3D.DIFFUSE_BURLEY
	_island_material.vertex_color_use_as_albedo = true
	_island_material.vertex_color_is_srgb = true
	_island_material.albedo_color = Color(1.0, 1.0, 1.0, 1.0)

	return _island_material


static func get_foam_material() -> ShaderMaterial:
	if _foam_material != null:
		return _foam_material

	if ResourceLoader.exists(FOAM_SHADER_PATH):
		var shader: Shader = load(FOAM_SHADER_PATH) as Shader
		_foam_material = ShaderMaterial.new()
		_foam_material.resource_name = "Mat_CoastalFoam"
		_foam_material.shader = shader
		_foam_material.render_priority = 2

	return _foam_material


## Constrói a malha 3D completa da ilha (ArrayMesh) em 1 único commit
static func build_island_mesh(
	polygons: Array[PackedVector2Array],
	holes: Array[PackedVector2Array] = []
) -> ArrayMesh:
	if polygons.is_empty():
		return null

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var final_ground_color: Color = get_final_ground_color()

	for poly: PackedVector2Array in polygons:
		if poly.size() < 3:
			continue

		# 1. Garante orientação horária para contornos externos
		var outer: PackedVector2Array = poly
		if not Geometry2D.is_polygon_clockwise(outer):
			outer = _reverse_polygon(outer)

		# 2. Triangulação da tampa superior (Teto de Grama em Y = 0.0m)
		var polys_to_triangulate: Array[PackedVector2Array] = [outer]
		if not holes.is_empty():
			for h: PackedVector2Array in holes:
				if h.size() >= 3:
					var new_polys: Array[PackedVector2Array] = []
					for p: PackedVector2Array in polys_to_triangulate:
						var clipped: Array[PackedVector2Array] = Geometry2D.clip_polygons(p, h)
						new_polys.append_array(clipped)
					polys_to_triangulate = new_polys

		for p_cap: PackedVector2Array in polys_to_triangulate:
			if p_cap.size() < 3:
				continue
			var indices: PackedInt32Array = Geometry2D.triangulate_polygon(p_cap)
			if indices.is_empty():
				continue
			var v_count: int = p_cap.size()
			for i_idx: int in range(0, indices.size(), 3):
				var i0: int = indices[i_idx]
				var i1: int = indices[i_idx + 1]
				var i2: int = indices[i_idx + 2]
				if i0 >= v_count or i1 >= v_count or i2 >= v_count:
					continue

				var p0: Vector2 = p_cap[i0]
				var p1: Vector2 = p_cap[i1]
				var p2: Vector2 = p_cap[i2]

				st.set_color(final_ground_color)
				st.set_normal(Vector3.UP)
				st.set_uv(UV_GRASS_TOP)
				st.add_vertex(Vector3(p0.x, 0.0, p0.y))

				st.set_color(final_ground_color)
				st.set_normal(Vector3.UP)
				st.set_uv(UV_GRASS_TOP)
				st.add_vertex(Vector3(p1.x, 0.0, p1.y))

				st.set_color(final_ground_color)
				st.set_normal(Vector3.UP)
				st.set_uv(UV_GRASS_TOP)
				st.add_vertex(Vector3(p2.x, 0.0, p2.y))

		# 3. Calcula normais externas por vértice do contorno perimetral
		var n_pts: int = outer.size()
		var vert_normals: Array[Vector2] = _compute_vertex_normals(outer)

		# 4. Chanfro superior e falésias costeiras verticais
		for i: int in range(n_pts):
			var next_i: int = (i + 1) % n_pts
			var p_a: Vector2 = outer[i]
			var p_b: Vector2 = outer[next_i]
			var n_a: Vector2 = vert_normals[i]
			var n_b: Vector2 = vert_normals[next_i]

			var seg_dir: Vector2 = (p_b - p_a).normalized()
			var seg_norm: Vector2 = Vector2(-seg_dir.y, seg_dir.x) # Normal perpendicular para fora

			# Pontos do chanfro (borda suave)
			var top_a: Vector3 = Vector3(p_a.x, 0.0, p_a.y)
			var top_b: Vector3 = Vector3(p_b.x, 0.0, p_b.y)
			var bev_a: Vector3 = Vector3(p_a.x + n_a.x * BEVEL_OUTSET, -BEVEL_DEPTH, p_a.y + n_a.y * BEVEL_OUTSET)
			var bev_b: Vector3 = Vector3(p_b.x + n_b.x * BEVEL_OUTSET, -BEVEL_DEPTH, p_b.y + n_b.y * BEVEL_OUTSET)
			var bot_a: Vector3 = Vector3(p_a.x, -CLIFF_DEPTH, p_a.y)
			var bot_b: Vector3 = Vector3(p_b.x, -CLIFF_DEPTH, p_b.y)

			var bev_norm_a: Vector3 = Vector3(n_a.x * 0.707, 0.707, n_a.y * 0.707).normalized()
			var bev_norm_b: Vector3 = Vector3(n_b.x * 0.707, 0.707, n_b.y * 0.707).normalized()
			var wall_norm: Vector3 = Vector3(seg_norm.x, 0.0, seg_norm.y)

			# Triângulos do Chanfro (Grama -> Borda)
			st.set_color(final_ground_color)
			# Triângulo 1: top_a, top_b, bev_b
			st.set_normal(bev_norm_a)
			st.set_uv(UV_GRASS_TOP)
			st.add_vertex(top_a)

			st.set_normal(bev_norm_b)
			st.set_uv(UV_GRASS_TOP)
			st.add_vertex(top_b)

			st.set_normal(bev_norm_b)
			st.set_uv(UV_GRASS_TOP)
			st.add_vertex(bev_b)

			# Triângulo 2: top_a, bev_b, bev_a
			st.set_normal(bev_norm_a)
			st.set_uv(UV_GRASS_TOP)
			st.add_vertex(top_a)

			st.set_normal(bev_norm_b)
			st.set_uv(UV_GRASS_TOP)
			st.add_vertex(bev_b)

			st.set_normal(bev_norm_a)
			st.set_uv(UV_GRASS_TOP)
			st.add_vertex(bev_a)

			# Triângulos da Parede da Falésia (bev_a / bev_b até bot_a / bot_b)
			st.set_color(CLIFF_COLOR)
			# Triângulo 1: bev_a, bev_b, bot_b
			st.set_normal(wall_norm)
			st.set_uv(UV_CLIFF_WALL)
			st.add_vertex(bev_a)

			st.set_normal(wall_norm)
			st.set_uv(UV_CLIFF_WALL)
			st.add_vertex(bev_b)

			st.set_normal(wall_norm)
			st.set_uv(UV_CLIFF_WALL)
			st.add_vertex(bot_b)

			# Triângulo 2: bev_a, bot_b, bot_a
			st.set_normal(wall_norm)
			st.set_uv(UV_CLIFF_WALL)
			st.add_vertex(bev_a)

			st.set_normal(wall_norm)
			st.set_uv(UV_CLIFF_WALL)
			st.add_vertex(bot_b)

			st.set_normal(wall_norm)
			st.set_uv(UV_CLIFF_WALL)
			st.add_vertex(bot_a)

	var mesh: ArrayMesh = st.commit()
	if mesh != null:
		mesh.surface_set_material(0, get_island_material())
	return mesh


## Constrói a fita de espuma costeira contínua (CoastalFoamRibbon)
static func build_coastal_foam_mesh(
	polygons: Array[PackedVector2Array],
	foam_y: float = FOAM_Y_LEVEL
) -> ArrayMesh:
	if polygons.is_empty():
		return null

	var st: SurfaceTool = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	for poly: PackedVector2Array in polygons:
		if poly.size() < 3:
			continue

		var outer: PackedVector2Array = poly
		if not Geometry2D.is_polygon_clockwise(outer):
			outer = _reverse_polygon(outer)

		var n_pts: int = outer.size()
		var vert_normals: Array[Vector2] = _compute_vertex_normals(outer)

		for i: int in range(n_pts):
			var next_i: int = (i + 1) % n_pts
			var u0: float = float(i) / float(n_pts)
			var u1: float = float(i + 1) / float(n_pts)

			var p0: Vector2 = outer[i]
			var p1: Vector2 = outer[next_i]
			var n0: Vector2 = vert_normals[i]
			var n1: Vector2 = vert_normals[next_i]

			var v_in0: Vector3 = Vector3(p0.x - n0.x * FOAM_INSET, foam_y, p0.y - n0.y * FOAM_INSET)
			var v_in1: Vector3 = Vector3(p1.x - n1.x * FOAM_INSET, foam_y, p1.y - n1.y * FOAM_INSET)
			var v_out0: Vector3 = Vector3(p0.x + n0.x * FOAM_WIDTH, foam_y, p0.y + n0.y * FOAM_WIDTH)
			var v_out1: Vector3 = Vector3(p1.x + n1.x * FOAM_WIDTH, foam_y, p1.y + n1.y * FOAM_WIDTH)

			var n0_world: Vector3 = Vector3(n0.x, 0.0, n0.y)
			var n1_world: Vector3 = Vector3(n1.x, 0.0, n1.y)

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

	var foam_mesh: ArrayMesh = st.commit()
	if foam_mesh != null and foam_mesh.get_surface_count() > 0:
		foam_mesh.surface_set_material(0, get_foam_material())
	return foam_mesh


## Constrói barreiras de colisão costeira invisíveis na Camada 1 ao redor do perímetro
static func build_coastal_colliders(
	parent_body: StaticBody3D,
	polygons: Array[PackedVector2Array]
) -> void:
	if parent_body == null or polygons.is_empty():
		return

	for poly: PackedVector2Array in polygons:
		if poly.size() < 3:
			continue

		var outer: PackedVector2Array = poly
		if not Geometry2D.is_polygon_clockwise(outer):
			outer = _reverse_polygon(outer)

		var n_pts: int = outer.size()
		var _vert_normals: Array[Vector2] = _compute_vertex_normals(outer)

		for i: int in range(n_pts):
			var next_i: int = (i + 1) % n_pts
			var p_a: Vector2 = outer[i]
			var p_b: Vector2 = outer[next_i]
			var seg_len: float = p_a.distance_to(p_b)
			if seg_len <= 0.001:
				continue

			var mid_2d: Vector2 = (p_a + p_b) * 0.5
			var seg_dir: Vector2 = (p_b - p_a) / seg_len
			# Normal apontando para fora do polígono
			var seg_norm: Vector2 = Vector2(-seg_dir.y, seg_dir.x)

			# Leve recuo da barreira na direção interna para a contenção ser rente à borda
			var wall_pos_2d: Vector2 = mid_2d - seg_norm * (BOUNDARY_WALL_THICKNESS * 0.5)

			var col: CollisionShape3D = CollisionShape3D.new()
			var box: BoxShape3D = BoxShape3D.new()
			box.size = Vector3(seg_len, BOUNDARY_WALL_HEIGHT, BOUNDARY_WALL_THICKNESS)
			col.shape = box

			# Posiciona e orienta a barreira ao longo do segmento
			var angle_y: float = -atan2(seg_dir.y, seg_dir.x)
			col.rotation.y = angle_y
			col.position = Vector3(wall_pos_2d.x, 0.45, wall_pos_2d.y)

			parent_body.add_child(col)


## Converte uma grade de tiles discreta [gx, gz] em polígonos fechados contínuos via Clipper
static func convert_tile_grid_to_polygons(
	terrain_list: Array,
	width: int,
	height: int,
	cell_size: float = 0.80,
	corner_radius: float = DEFAULT_CORNER_RADIUS,
	arc_steps: int = DEFAULT_CORNER_ARC_STEPS
) -> Array[PackedVector2Array]:
	if terrain_list.is_empty():
		return []

	var offset_x: float = -(float(width) * cell_size) / 2.0 + (cell_size / 2.0)
	var offset_z: float = -(float(height) * cell_size) / 2.0 + (cell_size / 2.0)
	var half_cell: float = cell_size * 0.5

	var squares: Array[PackedVector2Array] = []
	for item: Variant in terrain_list:
		if not (item is Dictionary):
			continue
		var td: Dictionary = item as Dictionary
		var gx: int = int(td.get("gx", 0))
		var gz: int = int(td.get("gz", 0))
		var cx: float = offset_x + float(gx) * cell_size
		var cz: float = offset_z + float(gz) * cell_size

		# Cria o quadrado de cada bloco com sentido horário
		var sq: PackedVector2Array = PackedVector2Array([
			Vector2(cx - half_cell, cz - half_cell),
			Vector2(cx + half_cell, cz - half_cell),
			Vector2(cx + half_cell, cz + half_cell),
			Vector2(cx - half_cell, cz + half_cell)
		])
		squares.append(sq)

	if squares.is_empty():
		return []

	# Fusão progressiva dos quadrados adjacentes
	var merged_polys: Array[PackedVector2Array] = [squares[0]]
	for i: int in range(1, squares.size()):
		var sq_to_add: PackedVector2Array = squares[i]
		var next_list: Array[PackedVector2Array] = []
		var did_merge: bool = false

		for p: PackedVector2Array in merged_polys:
			var res: Array[PackedVector2Array] = Geometry2D.merge_polygons(p, sq_to_add)
			if res.size() == 1:
				sq_to_add = res[0]
				did_merge = true
			else:
				next_list.append(p)

		next_list.append(sq_to_add)

		# Se houve fusão, realiza redução para juntar polígonos que agora se tocam
		if did_merge and next_list.size() > 1:
			merged_polys = _reduce_overlapping_polygons(next_list)
		else:
			merged_polys = next_list

	if corner_radius > 0.001:
		var rounded_polys: Array[PackedVector2Array] = []
		for p: PackedVector2Array in merged_polys:
			rounded_polys.append(round_polygon_corners(p, corner_radius, arc_steps))
		return rounded_polys

	return merged_polys


## Arredonda cantos externos convexos de um polígono com arcos tangentes circulares suaves
static func round_polygon_corners(
	poly: PackedVector2Array,
	radius: float = DEFAULT_CORNER_RADIUS,
	arc_steps: int = DEFAULT_CORNER_ARC_STEPS
) -> PackedVector2Array:
	if poly.size() < 3 or radius <= 0.001:
		return poly

	var p_clean: PackedVector2Array = poly
	var was_cw: bool = Geometry2D.is_polygon_clockwise(p_clean)
	if not was_cw:
		p_clean = _reverse_polygon(p_clean)

	var n: int = p_clean.size()
	var out: PackedVector2Array = PackedVector2Array()

	for i: int in range(n):
		var prev_i: int = (i - 1 + n) % n
		var next_i: int = (i + 1) % n

		var p_curr: Vector2 = p_clean[i]
		var v_in: Vector2 = p_curr - p_clean[prev_i]
		var v_out: Vector2 = p_clean[next_i] - p_curr

		var len_in: float = v_in.length()
		var len_out: float = v_out.length()
		if len_in < 0.001 or len_out < 0.001:
			out.append(p_curr)
			continue

		var dir_in: Vector2 = v_in / len_in
		var dir_out: Vector2 = v_out / len_out

		var cross: float = dir_in.x * dir_out.y - dir_in.y * dir_out.x
		# Em polígono CW, cantos convexos (voltados para fora da ilha) possuem cross < -0.01
		if cross >= -0.01:
			out.append(p_curr)
			continue

		var dot: float = clampf(dir_in.dot(dir_out), -1.0, 1.0)
		if dot > 0.999:
			out.append(p_curr)
			continue

		# Distância de tangência segura (no máximo 45% do menor segmento adjacente)
		var max_d: float = minf(len_in * 0.45, len_out * 0.45)
		var d_tan: float = minf(radius, max_d)

		var start_pt: Vector2 = p_curr - dir_in * d_tan
		var end_pt: Vector2 = p_curr + dir_out * d_tan

		# Centro do arco (normal à direita de dir_in no sentido horário)
		var norm_in: Vector2 = Vector2(dir_in.y, -dir_in.x)
		var arc_center: Vector2 = start_pt + norm_in * d_tan

		var ang_start: float = (start_pt - arc_center).angle()
		var ang_end: float = (end_pt - arc_center).angle()

		var sweep: float = ang_end - ang_start
		while sweep > 0.0:
			sweep -= TAU

		for s: int in range(arc_steps + 1):
			var t: float = float(s) / float(arc_steps)
			var a: float = ang_start + sweep * t
			out.append(arc_center + Vector2(cos(a), sin(a)) * d_tan)

	if not was_cw:
		return _reverse_polygon(out)

	return out


## Redução iterativa de polígonos que se sobrepõem
static func _reduce_overlapping_polygons(input_polys: Array[PackedVector2Array]) -> Array[PackedVector2Array]:
	var current: Array[PackedVector2Array] = input_polys.duplicate()
	var merged_in_pass: bool = true

	while merged_in_pass:
		merged_in_pass = false
		var next_list: Array[PackedVector2Array] = []
		var skip: Dictionary = {}

		for i: int in range(current.size()):
			if skip.has(i):
				continue
			var p_i: PackedVector2Array = current[i]
			for j: int in range(i + 1, current.size()):
				if skip.has(j):
					continue
				var p_j: PackedVector2Array = current[j]
				var m: Array[PackedVector2Array] = Geometry2D.merge_polygons(p_i, p_j)
				if m.size() == 1:
					p_i = m[0]
					skip[j] = true
					merged_in_pass = true
			next_list.append(p_i)
		current = next_list

	return current


## Calcula normais externas médias por vértice para contornos suaves
static func _compute_vertex_normals(poly: PackedVector2Array) -> Array[Vector2]:
	var count: int = poly.size()
	var normals: Array[Vector2] = []
	normals.resize(count)

	for i: int in range(count):
		var prev_i: int = (i - 1 + count) % count
		var next_i: int = (i + 1) % count

		var d_prev: Vector2 = (poly[i] - poly[prev_i]).normalized()
		var d_next: Vector2 = (poly[next_i] - poly[i]).normalized()

		# Normais voltadas para fora (para polígonos com sentido horário)
		var n_prev: Vector2 = Vector2(-d_prev.y, d_prev.x)
		var n_next: Vector2 = Vector2(-d_next.y, d_next.x)

		var avg_n: Vector2 = (n_prev + n_next).normalized()
		if avg_n.length_squared() < 0.001:
			avg_n = n_next
		normals[i] = avg_n

	return normals


static func _reverse_polygon(poly: PackedVector2Array) -> PackedVector2Array:
	var reversed: PackedVector2Array = PackedVector2Array()
	var count: int = poly.size()
	for i: int in range(count - 1, -1, -1):
		reversed.append(poly[i])
	return reversed
