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
