extends RefCounted

enum ShapeType {
	SINGLE = 0,
	SQUARE = 1,
	CIRCLE = 2,
	DIAMOND = 3,
	HEART = 4,
	STAR = 5,
	CROSS = 6
}

const SHAPE_INFO: Array[Dictionary] = [
	{ "id": ShapeType.SINGLE,  "name": "Único (1x1)", "icon": "⏺️" },
	{ "id": ShapeType.SQUARE,  "name": "Quadrado",    "icon": "⬛" },
	{ "id": ShapeType.CIRCLE,  "name": "Círculo",     "icon": "⚪" },
	{ "id": ShapeType.DIAMOND, "name": "Losango",     "icon": "🔶" },
	{ "id": ShapeType.HEART,   "name": "Coração",     "icon": "❤️" },
	{ "id": ShapeType.STAR,    "name": "Estrela",     "icon": "⭐" },
	{ "id": ShapeType.CROSS,   "name": "Cruz",        "icon": "➕" }
]

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

static func get_brush_offsets(shape: int, brush_size: int) -> Array[Vector2i]:
	var offsets: Array[Vector2i] = []
	var clamped_size: int = clampi(brush_size, 1, 4)

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

		ShapeType.STAR:
			if clamped_size == 1:
				offsets = _bitmap_to_offsets(STAR_SMALL)
			elif clamped_size == 2:
				offsets = _bitmap_to_offsets(STAR_MEDIUM)
			else:
				offsets = _bitmap_to_offsets(STAR_LARGE)

		ShapeType.CROSS:
			var r: int = clamped_size
			for d in range(-r, r + 1):
				offsets.append(Vector2i(d, 0))
				if d != 0:
					offsets.append(Vector2i(0, d))

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
	var clamped_size: int = clampi(brush_size, 1, 4)

	# Raio do pincel no mundo: 1 -> 0.40m (2 células 0.20m), 2 -> 0.70m, 3 -> 1.00m, 4 -> 1.30m
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
			# Equação analítica contínua de coração: (x^2 + y^2 - 1)^3 - x^2 * y^3 <= 0
			var scale_f: float = radius_m * 1.15
			for dz: int in range(-cell_r - 2, cell_r + 2):
				for dx: int in range(-cell_r - 2, cell_r + 2):
					var x: float = (float(dx) * 0.20) / scale_f
					# Inverte Z para que o topo do coração fique para o Norte (-Z)
					var y: float = -(float(dz) * 0.20) / scale_f + 0.25
					var val: float = (x * x + y * y - 1.0)
					var eq: float = val * val * val - x * x * (y * y * y)
					if eq <= 0.0:
						offsets.append(Vector2i(dx, dz))

		ShapeType.STAR:
			# Estrela regular de 5 pontas calculada analiticamente
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

## Gera polígono vetorial analítico fechado para carimbos no plano XZ
static func get_vector_stamp_polygon(shape: int, brush_size: int, center: Vector2, rotation_deg: float = 0.0) -> PackedVector2Array:
	var poly: PackedVector2Array = PackedVector2Array()
	var clamped_size: int = clampi(brush_size, 1, 4)
	var r: float = float(clamped_size) * 0.35 + 0.15

	match shape:
		ShapeType.SINGLE, ShapeType.CIRCLE:
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
			var points: int = 10
			var r_out: float = r * 1.30
			var r_in: float = r * 0.52
			for i: int in range(points):
				var a: float = -PI * 0.5 + float(i) * PI / 5.0
				var cur_rad: float = r_out if (i % 2 == 0) else r_in
				poly.append(center + Vector2(cos(a), sin(a)) * cur_rad)

		ShapeType.CROSS:
			var arm_w: float = r * 0.35
			var arm_l: float = r * 1.15
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

	# Se gerou múltiplos contornos (auto-interseções), seleciona o maior contorno
	var best_p: PackedVector2Array = offset_res[0]
	for idx: int in range(1, offset_res.size()):
		var p_curr: PackedVector2Array = offset_res[idx]
		if p_curr.size() > best_p.size():
			best_p = p_curr
	return best_p
