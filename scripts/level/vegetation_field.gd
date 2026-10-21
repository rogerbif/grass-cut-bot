extends RefCounted

# Campo de vegetação em resolução fina de 0.20 m (4x4 subcélulas por bloco de terreno de 0.80 m).
# Células armazenam 1 byte:
# 0: Vazio
# 1: grass_green
# 2: grass_yellow
# 3: grass_blue
# 4: grass_purple
# 5: grass_white
# 6: grass_red
# 7: grass_black
# 8: wheat
# 9: flower

const CELL_RES: float = 0.20
const SUB_PER_BLOCK: int = 4 # 0.80 / 0.20

const TYPE_NAMES: Array[String] = [
	"empty",
	"grass_green",
	"grass_yellow",
	"grass_blue",
	"grass_purple",
	"grass_white",
	"grass_red",
	"grass_black",
	"wheat",
	"flower"
]

const CHAR_TO_TYPE: Dictionary = {
	".": 0,
	"1": 1,
	"2": 2,
	"3": 3,
	"4": 4,
	"5": 5,
	"6": 6,
	"7": 7,
	"8": 8,
	"9": 9
}

const TYPE_TO_CHAR: Array[String] = [
	".", "1", "2", "3", "4", "5", "6", "7", "8", "9"
]

var width_blocks: int = 12
var height_blocks: int = 8
var cols: int = 48
var rows: int = 32
var data: PackedByteArray = PackedByteArray()

func _init(w_blocks: int = 12, h_blocks: int = 8) -> void:
	resize_blocks(w_blocks, h_blocks)

func resize_blocks(w_blocks: int, h_blocks: int) -> void:
	width_blocks = maxi(1, w_blocks)
	height_blocks = maxi(1, h_blocks)
	cols = width_blocks * SUB_PER_BLOCK
	rows = height_blocks * SUB_PER_BLOCK
	data.resize(cols * rows)
	data.fill(0)

func clear() -> void:
	data.fill(0)

func get_cell(cx: int, cz: int) -> int:
	if cx < 0 or cx >= cols or cz < 0 or cz >= rows:
		return 0
	return int(data[cz * cols + cx])

func set_cell(cx: int, cz: int, type_id: int) -> void:
	if cx < 0 or cx >= cols or cz < 0 or cz >= rows:
		return
	data[cz * cols + cx] = clampi(type_id, 0, 9)

static func type_name_to_id(t_name: String) -> int:
	var idx: int = TYPE_NAMES.find(t_name)
	return idx if idx >= 0 else 1

static func type_id_to_name(t_id: int) -> String:
	if t_id >= 1 and t_id < TYPE_NAMES.size():
		return TYPE_NAMES[t_id]
	return "grass_green"

# Converte posição no mundo para coordenadas de subcélula (cx, cz)
func world_to_cell(world_pos: Vector3, block_cell_size: float = 0.80) -> Vector2i:
	var total_w_m: float = float(width_blocks) * block_cell_size
	var total_h_m: float = float(height_blocks) * block_cell_size
	var origin_x: float = -total_w_m * 0.5
	var origin_z: float = -total_h_m * 0.5
	var cx: int = floori((world_pos.x - origin_x) / CELL_RES)
	var cz: int = floori((world_pos.z - origin_z) / CELL_RES)
	return Vector2i(cx, cz)

# Converte coordenadas de subcélula (cx, cz) para centro no mundo
func cell_to_world(cx: int, cz: int, block_cell_size: float = 0.80) -> Vector3:
	var total_w_m: float = float(width_blocks) * block_cell_size
	var total_h_m: float = float(height_blocks) * block_cell_size
	var origin_x: float = -total_w_m * 0.5
	var origin_z: float = -total_h_m * 0.5
	return Vector3(
		origin_x + (float(cx) + 0.5) * CELL_RES,
		0.0,
		origin_z + (float(cz) + 0.5) * CELL_RES
	)

# Serialização JSON v2 em linhas de caracteres compactas
func to_rows() -> Array[String]:
	var res: Array[String] = []
	for r: int in range(rows):
		var row_chars: PackedStringArray = PackedStringArray()
		var start_idx: int = r * cols
		for c: int in range(cols):
			var val: int = int(data[start_idx + c])
			row_chars.append(TYPE_TO_CHAR[val] if val < TYPE_TO_CHAR.size() else ".")
		res.append("".join(row_chars))
	return res

func from_rows(row_strings: Array) -> void:
	for r: int in range(mini(rows, row_strings.size())):
		var line: String = String(row_strings[r])
		var start_idx: int = r * cols
		for c: int in range(mini(cols, line.length())):
			var ch: String = line[c]
			data[start_idx + c] = int(CHAR_TO_TYPE.get(ch, 0))

# Conversor retrocompatível: lê formato legacy v1 (array de objects) e popula o grid fino
func from_legacy_objects(objects_arr: Array, w_blocks: int, h_blocks: int) -> void:
	resize_blocks(w_blocks, h_blocks)
	for item: Variant in objects_arr:
		if not (item is Dictionary):
			continue
		var od: Dictionary = item as Dictionary
		var gx: int = int(od.get("gx", 0))
		var gz: int = int(od.get("gz", 0))
		var o_type: String = String(od.get("type", ""))
		if o_type == "" or o_type == "rock" or o_type == "cutter_spawn":
			continue

		var base_cx: int = gx * SUB_PER_BLOCK
		var base_cz: int = gz * SUB_PER_BLOCK

		if o_type == "flower" or o_type == "wheat":
			var special_id: int = type_name_to_id(o_type)
			# Slot especial em 0.40m (subcélulas 0,0 a 1,1) e grama verde no restante do bloco
			for dz: int in range(2):
				for dx: int in range(2):
					set_cell(base_cx + dx, base_cz + dz, special_id)
			for dz: int in range(SUB_PER_BLOCK):
				for dx: int in range(SUB_PER_BLOCK):
					if dx >= 2 or dz >= 2:
						set_cell(base_cx + dx, base_cz + dz, 1) # grass_green
		else:
			var tid: int = type_name_to_id(o_type)
			for dz: int in range(SUB_PER_BLOCK):
				for dx: int in range(SUB_PER_BLOCK):
					set_cell(base_cx + dx, base_cz + dz, tid)

# Retorna distância aproximada em metros até a borda vazia mais próxima (Chamfer 2-pass)
func compute_sdf_depth_map() -> PackedFloat32Array:
	var count: int = cols * rows
	var dist: PackedFloat32Array = PackedFloat32Array()
	dist.resize(count)
	const INF_DIST: float = 999.0

	for i: int in range(count):
		dist[i] = INF_DIST if data[i] != 0 else 0.0

	# Passada 1 (topo-esquerda para base-direita)
	for r: int in range(rows):
		for c: int in range(cols):
			var idx: int = r * cols + c
			if dist[idx] == 0.0:
				continue
			var d: float = dist[idx]
			if c > 0:
				d = minf(d, dist[idx - 1] + 1.0)
			if r > 0:
				d = minf(d, dist[idx - cols] + 1.0)
			if c > 0 and r > 0:
				d = minf(d, dist[idx - cols - 1] + 1.414)
			if c + 1 < cols and r > 0:
				d = minf(d, dist[idx - cols + 1] + 1.414)
			dist[idx] = d

	# Passada 2 (base-direita para topo-esquerda)
	for r: int in range(rows - 1, -1, -1):
		for c: int in range(cols - 1, -1, -1):
			var idx: int = r * cols + c
			if dist[idx] == 0.0:
				continue
			var d: float = dist[idx]
			if c + 1 < cols:
				d = minf(d, dist[idx + 1] + 1.0)
			if r + 1 < rows:
				d = minf(d, dist[idx + cols] + 1.0)
			if c + 1 < cols and r + 1 < rows:
				d = minf(d, dist[idx + cols + 1] + 1.414)
			if c > 0 and r + 1 < rows:
				d = minf(d, dist[idx + cols - 1] + 1.414)
			dist[idx] = d

	# Multiplica por CELL_RES para obter distância real em metros
	for i: int in range(count):
		dist[i] = dist[i] * CELL_RES

	return dist

# Gera Image RGBA8 do campo para o decal de solo orgânico
func to_density_image() -> Image:
	var img: Image = Image.create(cols, rows, false, Image.FORMAT_RGBA8)
	var type_palette: Array[Color] = [
		Color(0, 0, 0, 0),                       # 0 vazio
		Color(0.25, 0.78, 0.32, 1.0),            # 1 grass_green
		Color(0.95, 0.80, 0.20, 1.0),            # 2 grass_yellow
		Color(0.25, 0.68, 0.96, 1.0),            # 3 grass_blue
		Color(0.72, 0.35, 0.92, 1.0),            # 4 grass_purple
		Color(0.92, 0.94, 0.98, 1.0),            # 5 grass_white
		Color(0.95, 0.22, 0.24, 1.0),            # 6 grass_red
		Color(0.20, 0.20, 0.24, 1.0),            # 7 grass_black
		Color(0.92, 0.68, 0.18, 1.0),            # 8 wheat
		Color(0.95, 0.38, 0.68, 1.0)             # 9 flower
	]
	for r: int in range(rows):
		for c: int in range(cols):
			var val: int = int(data[r * cols + c])
			img.set_pixel(c, r, type_palette[val])
	return img
