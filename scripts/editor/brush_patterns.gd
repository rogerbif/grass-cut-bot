extends RefCounted

enum ShapeType {
	SINGLE = 0,
	SQUARE = 1,
	CIRCLE = 2,
	DIAMOND = 3,
	HEART = 4,
	STAR = 5,
	CROSS = 6,
	RING = 7,
	IMAGE_STAMP = 8
}

const SHAPE_INFO: Array[Dictionary] = [
	{ "id": ShapeType.SINGLE,      "name": "Único (1x1)", "icon": "⏺️" },
	{ "id": ShapeType.SQUARE,      "name": "Quadrado",    "icon": "⬛" },
	{ "id": ShapeType.CIRCLE,      "name": "Círculo",     "icon": "⚪" },
	{ "id": ShapeType.DIAMOND,     "name": "Losango",     "icon": "🔶" },
	{ "id": ShapeType.HEART,       "name": "Coração",     "icon": "❤️" },
	{ "id": ShapeType.STAR,        "name": "Estrela",     "icon": "⭐" },
	{ "id": ShapeType.CROSS,       "name": "Cruz",        "icon": "➕" },
	{ "id": ShapeType.RING,        "name": "Anel / Furo", "icon": "🍩" },
	{ "id": ShapeType.IMAGE_STAMP, "name": "Imagem P&B",  "icon": "🖼️" }
]

const IMAGE_PRESETS_META: Array[Dictionary] = [
	{ "id": "paw",    "name": "🐾 Patinha" },
	{ "id": "spiral", "name": "🌀 Espiral" },
	{ "id": "moon",   "name": "🌙 Meia-Lua" },
	{ "id": "bolt",   "name": "⚡ Raio" },
	{ "id": "clover", "name": "🍀 Trevo" },
	{ "id": "puzzle", "name": "🧩 Puzzle" }
]

static var _image_polygon_cache: Dictionary = {}
static var _preset_images_cache: Dictionary = {}

# Bitmaps para Coração em 3 escalas (Pequeno 5x5, Médio 7x7, Grande 9x9)
const HEART_SMALL: Array[String] = [
	".#.#.",
	"#####",
	"#####",
	".###.",
	"..#.."
]

const HEART_MEDIUM: Array[String] = [
	".##.##.",
	"#######",
	"#######",
	"#######",
	".#####.",
	"..###..",
	"...#..."
]

const HEART_LARGE: Array[String] = [
	".###.###.",
	"#########",
	"#########",
	"#########",
	".#######.",
	"..#####..",
	"...###...",
	"....#...."
]

# Bitmaps para Estrela em 3 escalas (Pequeno 5x5, Médio 7x7, Grande 9x9)
const STAR_SMALL: Array[String] = [
	"..#..",
	"#####",
	".###.",
	".#.#.",
	"#...#"
]

const STAR_MEDIUM: Array[String] = [
	"...#...",
	"..###..",
	"#######",
	".#####.",
	"..###..",
	".##.##.",
	"#.....#"
]

const STAR_LARGE: Array[String] = [
	"....#....",
	"...###...",
	"...###...",
	"#########",
	".#######.",
	"..#####..",
	".###.###.",
	"##.....##",
	"#.......#"
]

static func get_brush_offsets(shape: int, brush_size: int, custom_params: Dictionary = {}) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	var clamped_size: int = clampi(brush_size, 1, 20)

	# Para formas paramétricas avançadas (STAR customizada, CROSS customizada, RING, IMAGE_STAMP),
	# amostramos os polígonos vetoriais na grade de células de 0.40m para paridade 1:1!
	if shape == ShapeType.STAR or shape == ShapeType.CROSS or shape == ShapeType.RING or shape == ShapeType.IMAGE_STAMP:
		var polys: Array[PackedVector2Array] = get_vector_stamp_polygons(
			shape, clamped_size, Vector2.ZERO, 0.0, 0.0, custom_params
		)
		if not polys.is_empty():
			var cell_step: float = 0.40
			var r_cells: int = clampi(clamped_size + 2, 2, 24)
			for dz: int in range(-r_cells, r_cells + 1):
				for dx: int in range(-r_cells, r_cells + 1):
					var pt: Vector2 = Vector2(float(dx) * cell_step, float(dz) * cell_step)
					if shape == ShapeType.RING and polys.size() >= 2:
						if Geometry2D.is_point_in_polygon(pt, polys[0]) and not Geometry2D.is_point_in_polygon(pt, polys[1]):
							offsets.append(Vector2i(dx, dz))
					else:
						for p: PackedVector2Array in polys:
							if Geometry2D.is_point_in_polygon(pt, p):
								offsets.append(Vector2i(dx, dz))
								break
		if offsets.is_empty():
			offsets.append(Vector2i.ZERO)
		return offsets

	match shape:
		ShapeType.SINGLE:
			offsets.append(Vector2i.ZERO)

		ShapeType.SQUARE:
			var r: int = clamped_size
			for dz in range(-r, r + 1):
				for dx in range(-r, r + 1):
					offsets.append(Vector2i(dx, dz))

		ShapeType.CIRCLE:
			var r: int = clamped_size
			var max_dist_sq: float = (float(r) + 0.35) * (float(r) + 0.35)
			for dz in range(-r, r + 1):
				for dx in range(-r, r + 1):
					var d_sq: float = float(dx * dx + dz * dz)
					if d_sq <= max_dist_sq:
						offsets.append(Vector2i(dx, dz))

		ShapeType.DIAMOND:
			var r: int = clamped_size
			for dz in range(-r, r + 1):
				for dx in range(-r, r + 1):
					if absi(dx) + absi(dz) <= r:
						offsets.append(Vector2i(dx, dz))

		ShapeType.HEART:
			if clamped_size == 1:
				offsets = _bitmap_to_offsets(HEART_SMALL)
			elif clamped_size == 2:
				offsets = _bitmap_to_offsets(HEART_MEDIUM)
			else:
				offsets = _bitmap_to_offsets(HEART_LARGE)

		_:
			offsets.append(Vector2i.ZERO)

	return offsets

static func get_box_cells(start_cell: Vector2i, end_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var min_x: int = mini(start_cell.x, end_cell.x)
	var max_x: int = maxi(start_cell.x, end_cell.x)
	var min_z: int = mini(start_cell.y, end_cell.y)
	var max_z: int = maxi(start_cell.y, end_cell.y)

	for gz in range(min_z, max_z + 1):
		for gx in range(min_x, max_x + 1):
			cells.append(Vector2i(gx, gz))
	return cells

static func _bitmap_to_offsets(rows: Array[String]) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var h: int = rows.size()
	if h == 0:
		return result
	var w: int = rows[0].length()
	var center_x: int = int(float(w - 1) / 2.0)
	var center_z: int = int(float(h - 1) / 2.0)

	for r_idx in range(h):
		var line: String = rows[r_idx]
		for c_idx in range(line.length()):
			if line[c_idx] == "#":
				result.append(Vector2i(c_idx - center_x, r_idx - center_z))
	return result

# Retorna offsets em resolução fina de 0.20m usando geometria analítica contínua
static func get_field_offsets(shape: int, brush_size: int) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	var clamped_size: int = clampi(brush_size, 1, 20)

	var radius_m: float = 0.40 + float(clamped_size - 1) * 0.30
	var cell_r: int = ceili(radius_m / 0.20)

	match shape:
		ShapeType.SINGLE:
			offsets.append(Vector2i.ZERO)

		ShapeType.SQUARE:
			for dz: int in range(-cell_r, cell_r + 1):
				for dx: int in range(-cell_r, cell_r + 1):
					offsets.append(Vector2i(dx, dz))

		ShapeType.CIRCLE:
			var r_sq: float = (radius_m + 0.05) * (radius_m + 0.05)
			for dz: int in range(-cell_r, cell_r + 1):
				for dx: int in range(-cell_r, cell_r + 1):
					var dist_m_sq: float = float(dx * dx + dz * dz) * (0.20 * 0.20)
					if dist_m_sq <= r_sq:
						offsets.append(Vector2i(dx, dz))

		ShapeType.DIAMOND:
			for dz: int in range(-cell_r, cell_r + 1):
				for dx: int in range(-cell_r, cell_r + 1):
					var manhattan_m: float = (float(absi(dx)) + float(absi(dz))) * 0.20
					if manhattan_m <= radius_m + 0.05:
						offsets.append(Vector2i(dx, dz))

		ShapeType.HEART:
			var scale_f: float = radius_m * 1.15
			for dz: int in range(-cell_r - 2, cell_r + 2):
				for dx: int in range(-cell_r - 2, cell_r + 2):
					var x: float = (float(dx) * 0.20) / scale_f
					var y: float = -(float(dz) * 0.20) / scale_f + 0.25
					var val: float = (x * x + y * y - 1.0)
					var eq: float = val * val * val - x * x * (y * y * y)
					if eq <= 0.0:
						offsets.append(Vector2i(dx, dz))

		ShapeType.STAR:
			var r_outer: float = radius_m * 1.2
			var r_inner: float = r_outer * 0.45
			for dz: int in range(-cell_r - 2, cell_r + 2):
				for dx: int in range(-cell_r - 2, cell_r + 2):
					var px: float = float(dx) * 0.20
					var pz: float = float(dz) * 0.20
					var d: float = sqrt(px * px + pz * pz)
					if d > r_outer + 0.05:
						continue
					if d <= r_inner:
						offsets.append(Vector2i(dx, dz))
						continue
					var ang: float = atan2(pz, px) + PI * 0.5
					var sector: float = fmod(ang + TAU * 2.0, TAU / 5.0) - (TAU / 10.0)
					var r_bound: float = r_inner / maxf(cos(absf(sector)), 0.2)
					if d <= r_bound * 1.35:
						offsets.append(Vector2i(dx, dz))

		ShapeType.CROSS:
			var bar_w_cells: int = 1
			for dz: int in range(-cell_r, cell_r + 1):
				for dx: int in range(-cell_r, cell_r + 1):
					if absi(dx) <= bar_w_cells or absi(dz) <= bar_w_cells:
						offsets.append(Vector2i(dx, dz))

		_:
			offsets.append(Vector2i.ZERO)

	return offsets

## Gera polígono circular métrico de raio exato no plano XZ
static func get_circle_polygon(center: Vector2, radius_m: float, segments: int = 24) -> PackedVector2Array:
	var poly: PackedVector2Array = PackedVector2Array()
	var segs: int = maxi(segments, 8)
	poly.resize(segs)
	for i: int in range(segs):
		var a: float = float(i) * TAU / float(segs)
		poly[i] = center + Vector2(cos(a), sin(a)) * radius_m
	return poly

## Gera lista de polígonos vetoriais (suporta formas compostas, imagens P&B e anéis com furo)
static func get_vector_stamp_polygons(
	shape: int,
	brush_size: int,
	center: Vector2,
	rotation_deg: float = 0.0,
	corner_radius: float = 0.28,
	custom_params: Dictionary = {}
) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var clamped_size: int = clampi(brush_size, 1, 20)
	var r: float = float(clamped_size) * 0.35 + 0.15

	if shape == ShapeType.RING:
		var hole_ratio: float = clampf(float(custom_params.get("ring_hole_ratio", 0.50)), 0.15, 0.85)
		var outer_poly: PackedVector2Array = get_circle_polygon(center, r, 28)
		var inner_poly: PackedVector2Array = get_circle_polygon(center, r * hole_ratio, 24)
		result.append(outer_poly)
		result.append(inner_poly)
		return result

	if shape == ShapeType.IMAGE_STAMP:
		var img_id: String = String(custom_params.get("image_id", "paw"))
		var invert: bool = bool(custom_params.get("image_invert", false))
		var eps: float = clampf(float(custom_params.get("image_epsilon", 1.5)), 0.4, 5.0)
		var norm_polys: Array[PackedVector2Array] = get_normalized_image_polygons(img_id, invert, eps)
		var scale_m: float = r * 1.25
		var rot_rad: float = deg_to_rad(rotation_deg)
		var has_rot: bool = not is_zero_approx(rotation_deg)
		for np: PackedVector2Array in norm_polys:
			if np.size() < 3:
				continue
			var tp: PackedVector2Array = PackedVector2Array()
			tp.resize(np.size())
			for i: int in range(np.size()):
				var v: Vector2 = np[i] * scale_m
				if has_rot:
					v = v.rotated(rot_rad)
				tp[i] = center + v
			result.append(tp)
		if result.is_empty():
			result.append(get_circle_polygon(center, r, 20))
		return result

	var single_p: PackedVector2Array = get_vector_stamp_polygon(
		shape, brush_size, center, rotation_deg, corner_radius, custom_params
	)
	if single_p.size() >= 3:
		result.append(single_p)
	return result

## Gera polígono vetorial analítico fechado para carimbos simples no plano XZ
static func get_vector_stamp_polygon(
	shape: int,
	brush_size: int,
	center: Vector2,
	rotation_deg: float = 0.0,
	_corner_radius: float = 0.28,
	custom_params: Dictionary = {}
) -> PackedVector2Array:
	var poly: PackedVector2Array = PackedVector2Array()
	var clamped_size: int = clampi(brush_size, 1, 20)
	var r: float = float(clamped_size) * 0.35 + 0.15

	match shape:
		ShapeType.SINGLE, ShapeType.CIRCLE, ShapeType.RING:
			var segments: int = 24
			for i: int in range(segments):
				var a: float = float(i) * TAU / float(segments)
				poly.append(center + Vector2(cos(a), sin(a)) * r)

		ShapeType.SQUARE:
			var h: float = r * 0.95
			poly.append(center + Vector2(-h, -h))
			poly.append(center + Vector2(h, -h))
			poly.append(center + Vector2(h, h))
			poly.append(center + Vector2(-h, h))

		ShapeType.DIAMOND:
			var d: float = r * 1.25
			poly.append(center + Vector2(0.0, -d))
			poly.append(center + Vector2(d, 0.0))
			poly.append(center + Vector2(0.0, d))
			poly.append(center + Vector2(-d, 0.0))

		ShapeType.HEART:
			var steps: int = 28
			var scale_cardioid: float = r / 16.0
			for i: int in range(steps):
				var t: float = float(i) * TAU / float(steps)
				var st: float = sin(t)
				var ct: float = cos(t)
				var px: float = 16.0 * (st * st * st)
				var pz: float = -(13.0 * ct - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t))
				poly.append(center + Vector2(px, pz) * scale_cardioid)

		ShapeType.STAR:
			var num_points: int = clampi(int(custom_params.get("star_points", 5)), 3, 16)
			var inner_ratio: float = clampf(float(custom_params.get("star_inner_ratio", 0.45)), 0.15, 1.00)
			var r_out: float = r * 1.30
			# Se inner_ratio >= 0.99, gera um Polígono Regular de num_points lados!
			if inner_ratio >= 0.99:
				for i: int in range(num_points):
					var a_reg: float = -PI * 0.5 + float(i) * TAU / float(num_points)
					poly.append(center + Vector2(cos(a_reg), sin(a_reg)) * r_out)
			else:
				var total_verts: int = num_points * 2
				var r_in: float = r_out * inner_ratio
				for i: int in range(total_verts):
					var a: float = -PI * 0.5 + float(i) * PI / float(num_points)
					var cur_rad: float = r_out if (i % 2 == 0) else r_in
					poly.append(center + Vector2(cos(a), sin(a)) * cur_rad)

		ShapeType.CROSS:
			var thickness: float = clampf(float(custom_params.get("cross_thickness", 0.35)), 0.15, 0.75)
			var arm_l: float = r * 1.15
			var arm_w: float = arm_l * thickness
			poly.append(center + Vector2(-arm_w, -arm_l))
			poly.append(center + Vector2(arm_w, -arm_l))
			poly.append(center + Vector2(arm_w, -arm_w))
			poly.append(center + Vector2(arm_l, -arm_w))
			poly.append(center + Vector2(arm_l, arm_w))
			poly.append(center + Vector2(arm_w, arm_w))
			poly.append(center + Vector2(arm_w, arm_l))
			poly.append(center + Vector2(-arm_w, arm_l))
			poly.append(center + Vector2(-arm_w, arm_w))
			poly.append(center + Vector2(-arm_l, arm_w))
			poly.append(center + Vector2(-arm_l, -arm_w))
			poly.append(center + Vector2(-arm_w, -arm_w))

		ShapeType.IMAGE_STAMP:
			var multi: Array[PackedVector2Array] = get_vector_stamp_polygons(
				shape, brush_size, center, rotation_deg, _corner_radius, custom_params
			)
			if not multi.is_empty():
				return multi[0]

		_:
			var segs: int = 20
			for i: int in range(segs):
				var a: float = float(i) * TAU / float(segs)
				poly.append(center + Vector2(cos(a), sin(a)) * r)

	if not is_zero_approx(rotation_deg):
		var rot_rad: float = deg_to_rad(rotation_deg)
		var rotated_poly: PackedVector2Array = PackedVector2Array()
		rotated_poly.resize(poly.size())
		for i: int in range(poly.size()):
			var rel: Vector2 = poly[i] - center
			rotated_poly[i] = center + rel.rotated(rot_rad)
		return rotated_poly

	return poly

## Extrai e faz cache dos polígonos normalizados (-1..+1) de um preset ou arquivo PNG P&B usando BitMap
static func get_normalized_image_polygons(image_id: String, invert: bool = false, epsilon: float = 1.5) -> Array[PackedVector2Array]:
	var cache_key: String = "%s|%s|%.2f" % [image_id, str(invert), epsilon]
	if _image_polygon_cache.has(cache_key):
		var cached: Array = _image_polygon_cache[cache_key] as Array
		var copy_res: Array[PackedVector2Array] = []
		for p_var: Variant in cached:
			copy_res.append((p_var as PackedVector2Array).duplicate())
		return copy_res

	var img: Image = get_or_build_brush_image(image_id)
	if img == null or img.is_empty():
		return []

	var res: Array[PackedVector2Array] = extract_normalized_polygons_from_image(img, invert, epsilon)
	_image_polygon_cache[cache_key] = res
	return res

static func extract_normalized_polygons_from_image(img: Image, invert: bool = false, epsilon: float = 1.5) -> Array[PackedVector2Array]:
	var out: Array[PackedVector2Array] = []
	if img == null or img.is_empty():
		return out

	var w: int = img.get_width()
	var h: int = img.get_height()
	if w < 4 or h < 4:
		return out

	var bm: BitMap = BitMap.new()
	bm.create(Vector2i(w, h))

	# Deixa 1px de margem transparente nas bordas para o Marching Squares sempre fechar contornos
	for y: int in range(1, h - 1):
		for x: int in range(1, w - 1):
			var c: Color = img.get_pixel(x, y)
			# Suporta tanto imagens P&B (luminância) quanto PNGs com fundo transparente
			var is_white: bool = (c.a > 0.25 and c.get_luminance() >= 0.5) if c.a >= 0.95 else (c.a >= 0.5)
			if invert:
				is_white = not is_white
			bm.set_bit(x, y, is_white)

	var raw_polys: Array[PackedVector2Array] = bm.opaque_to_polygons(Rect2i(0, 0, w, h), epsilon)
	var half_w: float = float(w) * 0.5
	var half_h: float = float(h) * 0.5
	var max_half: float = maxf(half_w, half_h)

	for rp: PackedVector2Array in raw_polys:
		if rp.size() < 3:
			continue
		var np: PackedVector2Array = PackedVector2Array()
		np.resize(rp.size())
		for i: int in range(rp.size()):
			var pt: Vector2 = rp[i]
			np[i] = Vector2((pt.x - half_w) / max_half, (pt.y - half_h) / max_half)
		out.append(np)

	return out

static func get_or_build_brush_image(image_id: String) -> Image:
	if _preset_images_cache.has(image_id):
		return _preset_images_cache[image_id] as Image

	# Se for um caminho de arquivo válido (.png / .jpg / .webp)
	if image_id.contains("/") or image_id.ends_with(".png") or image_id.ends_with(".jpg") or image_id.ends_with(".webp"):
		if FileAccess.file_exists(image_id):
			var loaded_img: Image = Image.load_from_file(ProjectSettings.globalize_path(image_id))
			if loaded_img != null and not loaded_img.is_empty():
				if loaded_img.get_width() > 256 or loaded_img.get_height() > 256:
					loaded_img.resize(128, 128, Image.INTERPOLATE_BILINEAR)
				_preset_images_cache[image_id] = loaded_img
				return loaded_img

	# Gera imagem P&B 128x128 procedural de alta nitidez para os 6 presets embutidos
	var size: int = 128
	var img: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.0, 0.0, 0.0, 1.0)) # Fundo preto

	for y: int in range(size):
		for x: int in range(size):
			var nx: float = (float(x) - 64.0) / 56.0
			var ny: float = (float(y) - 64.0) / 56.0
			var white: bool = false

			match image_id:
				"paw":
					# Almofada central + 4 dedos independentes (gera 5 polígonos no BitMap!)
					var pad_dx: float = nx / 0.52
					var pad_dy: float = (ny - 0.22) / 0.40
					if pad_dx * pad_dx + pad_dy * pad_dy <= 1.0:
						white = true
					var toes: Array[Vector2] = [
						Vector2(-0.56, -0.22),
						Vector2(-0.20, -0.52),
						Vector2(0.20, -0.52),
						Vector2(0.56, -0.22)
					]
					for t_center: Vector2 in toes:
						var tdx: float = (nx - t_center.x) / 0.17
						var tdy: float = (ny - t_center.y) / 0.22
						if tdx * tdx + tdy * tdy <= 1.0:
							white = true

				"spiral":
					var r_sp: float = sqrt(nx * nx + ny * ny)
					if r_sp <= 0.92:
						if r_sp <= 0.16:
							white = true
						else:
							var ang_sp: float = atan2(ny, nx)
							var phase: float = fposmod(r_sp * 2.2 - ang_sp / TAU, 1.0)
							if phase < 0.52:
								white = true

				"moon":
					var d_outer: float = nx * nx + ny * ny
					var d_cut: float = (nx - 0.36) * (nx - 0.36) + (ny - 0.08) * (ny - 0.08)
					if d_outer <= 0.85 and d_cut >= 0.52:
						white = true

				"bolt":
					# Raio estilizado usando distância a 3 segmentos conectados
					var p_cur: Vector2 = Vector2(nx, ny)
					var s1: Vector2 = Geometry2D.get_closest_point_to_segment(p_cur, Vector2(0.22, -0.82), Vector2(-0.28, 0.04))
					var s2: Vector2 = Geometry2D.get_closest_point_to_segment(p_cur, Vector2(-0.28, 0.04), Vector2(0.26, -0.04))
					var s3: Vector2 = Geometry2D.get_closest_point_to_segment(p_cur, Vector2(0.26, -0.04), Vector2(-0.22, 0.82))
					var min_d: float = minf(p_cur.distance_to(s1), minf(p_cur.distance_to(s2), p_cur.distance_to(s3)))
					if min_d <= 0.21:
						white = true

				"clover":
					# Trevo de 4 folhas (4 lóbulos diagonais + centro)
					var lobes: Array[Vector2] = [
						Vector2(-0.34, -0.34),
						Vector2(0.34, -0.34),
						Vector2(-0.34, 0.34),
						Vector2(0.34, 0.34)
					]
					for lc: Vector2 in lobes:
						if Vector2(nx, ny).distance_to(lc) <= 0.40:
							white = true

				"puzzle":
					# Peça de quebra-cabeça (quadrado central + 2 pinos + 1 encaixe)
					if absf(nx) <= 0.56 and absf(ny) <= 0.56:
						white = true
					if Vector2(nx, ny + 0.62).length() <= 0.24:
						white = true
					if Vector2(nx - 0.62, ny).length() <= 0.24:
						white = true
					if Vector2(nx, ny - 0.52).length() <= 0.23:
						white = false

				_:
					if nx * nx + ny * ny <= 0.80:
						white = true

			if white:
				img.set_pixel(x, y, Color(1.0, 1.0, 1.0, 1.0))

	_preset_images_cache[image_id] = img
	return img

## Gera polígono inflado (ribbon) com pontas arredondadas a partir de um traço livre contínuo
static func create_ribbon_polygon(stroke_points: Array[Vector2], width_m: float) -> PackedVector2Array:
	if stroke_points.size() < 2:
		if stroke_points.size() == 1:
			var c: Vector2 = stroke_points[0]
			var rad: float = width_m * 0.5
			var disc: PackedVector2Array = PackedVector2Array()
			for i: int in range(16):
				var a: float = float(i) * TAU / 16.0
				disc.append(c + Vector2(cos(a), sin(a)) * rad)
			return disc
		return PackedVector2Array()

	var polyline: PackedVector2Array = PackedVector2Array(stroke_points)
	var offset_res: Array[PackedVector2Array] = Geometry2D.offset_polyline(
		polyline,
		width_m * 0.5,
		Geometry2D.JOIN_ROUND,
		Geometry2D.END_ROUND
	)
	if offset_res.is_empty():
		return PackedVector2Array()
	if offset_res.size() == 1:
		return offset_res[0]

	var best_p: PackedVector2Array = offset_res[0]
	for idx: int in range(1, offset_res.size()):
		var p_curr: PackedVector2Array = offset_res[idx]
		if p_curr.size() > best_p.size():
			best_p = p_curr
	return best_p
