extends SceneTree

# Script de Calibração Canônica de Níveis:
# 1. Nenhuma grama em tiles de borda/costa.
# 2. Nenhuma pedra em tiles de borda.
# 3. Espaçamento de pelo menos 2 tiles livres entre rochas (dist >= 3).
# 4. Espaçamento de pelo menos 2 tiles livres entre rochas e bordas (dist >= 3).
# 5. Expansão das dimensões e terreno dos mapas quando necessário.

const IslandAutotiler = preload("res://scripts/editor/island_autotiler.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

func _init() -> void:
	print("=== INICIANDO CALIBRAÇÃO DOS 20 NÍVEIS ===")
	for lvl in range(1, 21):
		var path: String = "res://data/levels/level_%02d.json" % lvl
		if not FileAccess.file_exists(path):
			continue
		calibrate_level(path, lvl)
	print("=== CALIBRAÇÃO CONCLUÍDA COM SUCESSO ===")
	quit()

func calibrate_level(path: String, lvl_num: int) -> void:
	var data: Dictionary = LevelJsonLoader.load_json_file(path)
	if data.is_empty():
		return

	var grid_info: Dictionary = data.get("grid", {}) as Dictionary
	var width: int = int(grid_info.get("width", 14))
	var height: int = int(grid_info.get("height", 10))
	var cell_size: float = float(grid_info.get("cell_size", 0.8))

	# 1. Carrega terrain
	var terrain_grid: Dictionary = {}
	for item in data.get("terrain", []):
		if item is Dictionary:
			var cell: Vector2i = Vector2i(int(item.get("gx", 0)), int(item.get("gz", 0)))
			terrain_grid[cell] = {
				"tile_id": String(item.get("tile_id", "island_center")),
				"rot": int(item.get("rot", 0)),
				"auto": bool(item.get("auto", true))
			}

	# 2. Carrega objetos existentes
	var rocks: Array[Vector2i] = []
	var plants: Array[Dictionary] = []
	for item in data.get("objects", []):
		if item is Dictionary:
			var o_type: String = String(item.get("type", ""))
			var cell: Vector2i = Vector2i(int(item.get("gx", 0)), int(item.get("gz", 0)))
			if o_type == "rock":
				if not rocks.has(cell):
					rocks.append(cell)
			else:
				plants.append({ "cell": cell, "type": o_type, "rot": int(item.get("rot", 0)) })

	# 3. Identifica células de borda
	var border_cells: Dictionary = _find_border_cells(terrain_grid)

	# 4. Verifica se as rochas precisam de expansão do mapa
	# Se alguma rocha violar a distância >= 3 de borda ou de outra rocha:
	var needs_expansion: bool = false
	for r in rocks:
		if _dist_to_borders(r, border_cells) < 3:
			needs_expansion = true
			break

	for i in range(rocks.size()):
		for j in range(i + 1, rocks.size()):
			if _chebyshev(rocks[i], rocks[j]) < 3:
				needs_expansion = true
				break

	if needs_expansion:
		print("Nível %02d precisa de ajuste/expansão de rochas..." % lvl_num)
		# Se o nível tiver rochas muito próximas, reposiciona em posições válidas
		# ou expande a ilha em 2 células ao redor
		var expanded: Dictionary = _expand_island_by_rings(terrain_grid, width, height, 2)
		terrain_grid = expanded["terrain"]
		var pad: int = int(expanded["pad"])
		width += pad * 2
		height += pad * 2

		# Reposiciona rochas com o offset de pad
		var shifted_rocks: Array[Vector2i] = []
		for r in rocks:
			shifted_rocks.append(r + Vector2i(pad, pad))
		rocks = shifted_rocks

		# Reposiciona spawn
		var spawn_dict: Dictionary = data.get("spawn", {}) as Dictionary
		if not spawn_dict.is_empty():
			spawn_dict["gx"] = int(spawn_dict.get("gx", 0)) + pad
			spawn_dict["gz"] = int(spawn_dict.get("gz", 0)) + pad

		# Recalcula bordas após expansão
		border_cells = _find_border_cells(terrain_grid)

	# 5. Ajusta/filtra rochas para garantir estritamente >= 2 tiles livres entre si e da borda
	var valid_rocks: Array[Vector2i] = []
	for r in rocks:
		# Se a rocha estiver a dist < 3 de borda, tenta empurrar para o interior
		var adjusted_r: Vector2i = r
		var b_dist: int = _dist_to_borders(adjusted_r, border_cells)
		if b_dist < 3:
			# Procura vizinho mais profundo
			adjusted_r = _find_nearest_deep_cell(adjusted_r, terrain_grid, border_cells, valid_rocks)

		# Verifica se colide ou fica a dist < 3 de rochas já aceitas
		var collides: bool = false
		for vr in valid_rocks:
			if _chebyshev(adjusted_r, vr) < 3:
				collides = true
				break

		if not collides and terrain_grid.has(adjusted_r) and _dist_to_borders(adjusted_r, border_cells) >= 3:
			valid_rocks.append(adjusted_r)
		else:
			# Procura uma posição alternativa válida no interior
			var alt_pos: Vector2i = _find_nearest_deep_cell(adjusted_r, terrain_grid, border_cells, valid_rocks)
			if alt_pos != Vector2i(-999, -999):
				valid_rocks.append(alt_pos)

	# 6. Atualiza autotile no terreno
	IslandAutotiler.apply_autotile(terrain_grid)
	border_cells = _find_border_cells(terrain_grid)

	# 7. Distribui vegetação EXCLUSIVAMENTE nos tiles de interior (sem bordas, sem rochas)
	var final_objects: Array[Dictionary] = []
	for vr in valid_rocks:
		final_objects.append({
			"gx": vr.x,
			"gz": vr.y,
			"type": "rock",
			"rot": 0
		})

	# Preenche todas as células internas com vegetação
	# Mantendo a proporção de tipos (trigo, flor, grama colorida) do nível
	var plant_types: Array[String] = _get_level_plant_palette(data, lvl_num)
	var p_idx: int = 0

	# Identifica o spawn
	var spawn_info: Dictionary = data.get("spawn", {}) as Dictionary
	var sp_x: int = int(spawn_info.get("gx", int(float(width) / 2.0)))
	var sp_z: int = int(spawn_info.get("gz", int(float(height) / 2.0)))
	var spawn_cell: Vector2i = Vector2i(sp_x, sp_z)

	# Se spawn caiu em borda ou rocha, move para centro seguro
	if border_cells.has(spawn_cell) or valid_rocks.has(spawn_cell) or not terrain_grid.has(spawn_cell):
		var safe_center: Vector2i = _find_safe_spawn(terrain_grid, border_cells, valid_rocks)
		spawn_info["gx"] = safe_center.x
		spawn_info["gz"] = safe_center.y
		spawn_cell = safe_center

	for cell_key in terrain_grid.keys():
		var c: Vector2i = cell_key as Vector2i
		# Regra Estrita: NÃO pode estar na borda
		if border_cells.has(c):
			continue
		# NÃO pode ter rocha
		if valid_rocks.has(c):
			continue
		# Não coloca grama sob o pé do robô no spawn para dar folga visual
		if c == spawn_cell:
			continue

		var p_type: String = plant_types[p_idx % plant_types.size()]
		p_idx += 1
		final_objects.append({
			"gx": c.x,
			"gz": c.y,
			"type": p_type,
			"rot": 0
		})

	# 8. Monta JSON final e grava
	var final_terrain: Array[Dictionary] = []
	for c_key in terrain_grid.keys():
		var c: Vector2i = c_key as Vector2i
		var entry: Dictionary = terrain_grid[c] as Dictionary
		final_terrain.append({
			"gx": c.x,
			"gz": c.y,
			"tile_id": entry.get("tile_id", "island_center"),
			"rot": entry.get("rot", 0),
			"auto": true
		})

	data["grid"]["width"] = width
	data["grid"]["height"] = height
	data["terrain"] = final_terrain
	data["objects"] = final_objects
	data["spawn"] = spawn_info

	var out_text: String = JSON.stringify(data, "\t")
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(out_text)
		file.close()
		print("Nível %02d calibrado: %d tiles, %d rochas, %d plantas, 0 plantas na borda." % [lvl_num, final_terrain.size(), valid_rocks.size(), final_objects.size() - valid_rocks.size()])

func _find_border_cells(terrain_grid: Dictionary) -> Dictionary:
	var borders: Dictionary = {}
	var neighbors: Array[Vector2i] = [
		Vector2i(0, -1), Vector2i(0, 1), Vector2i(1, 0), Vector2i(-1, 0),
		Vector2i(1, -1), Vector2i(-1, -1), Vector2i(1, 1), Vector2i(-1, 1)
	]
	for c_key in terrain_grid.keys():
		var c: Vector2i = c_key as Vector2i
		var is_border: bool = false
		for n in neighbors:
			if not terrain_grid.has(c + n):
				is_border = true
				break
		if is_border:
			borders[c] = true
	return borders

func _dist_to_borders(cell: Vector2i, border_cells: Dictionary) -> int:
	var min_d: int = 999
	for b_key in border_cells.keys():
		var b: Vector2i = b_key as Vector2i
		var d: int = _chebyshev(cell, b)
		if d < min_d:
			min_d = d
	return min_d

func _chebyshev(a: Vector2i, b: Vector2i) -> int:
	return maxi(absi(a.x - b.x), absi(a.y - b.y))

func _find_nearest_deep_cell(origin: Vector2i, terrain: Dictionary, borders: Dictionary, existing_rocks: Array[Vector2i]) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-999, -999)
	var best_dist: int = -1
	var min_origin_dist: int = 999

	for c_key in terrain.keys():
		var c: Vector2i = c_key as Vector2i
		if borders.has(c):
			continue
		var b_dist: int = _dist_to_borders(c, borders)
		if b_dist < 3:
			continue
		# Verifica distância para rochas já aceitas
		var too_close: bool = false
		for er in existing_rocks:
			if _chebyshev(c, er) < 3:
				too_close = true
				break
		if too_close:
			continue

		var o_dist: int = _chebyshev(c, origin)
		if o_dist < min_origin_dist:
			min_origin_dist = o_dist
			best_cell = c

	return best_cell

func _find_safe_spawn(terrain: Dictionary, borders: Dictionary, rocks: Array[Vector2i]) -> Vector2i:
	for c_key in terrain.keys():
		var c: Vector2i = c_key as Vector2i
		if not borders.has(c) and not rocks.has(c):
			var safe: bool = true
			for r in rocks:
				if _chebyshev(c, r) < 2:
					safe = false
					break
			if safe:
				return c
	return Vector2i(0, 0)

func _expand_island_by_rings(orig_terrain: Dictionary, orig_w: int, orig_h: int, rings: int) -> Dictionary:
	var new_terrain: Dictionary = {}
	var pad: int = rings

	# Move todas as células existentes com o offset
	for c_key in orig_terrain.keys():
		var c: Vector2i = c_key as Vector2i
		new_terrain[c + Vector2i(pad, pad)] = { "tile_id": "island_center", "rot": 0, "auto": true }

	# Adiciona anéis de preenchimento ao redor de todas as células para aumentar a massa de terra
	for r in range(rings):
		var to_add: Array[Vector2i] = []
		for c_key in new_terrain.keys():
			var c: Vector2i = c_key as Vector2i
			for dx in [-1, 0, 1]:
				for dz in [-1, 0, 1]:
					var n: Vector2i = c + Vector2i(dx, dz)
					if not new_terrain.has(n):
						to_add.append(n)
		for a in to_add:
			new_terrain[a] = { "tile_id": "island_center", "rot": 0, "auto": true }

	return { "terrain": new_terrain, "pad": pad }

func _get_level_plant_palette(data: Dictionary, lvl_num: int) -> Array[String]:
	var types: Array[String] = []
	for item in data.get("objects", []):
		if item is Dictionary:
			var t: String = String(item.get("type", ""))
			if t != "rock" and not t.is_empty() and not types.has(t):
				types.append(t)
	if types.is_empty():
		match lvl_num:
			1, 2, 3:
				types = ["grass_green"]
			4, 5, 6:
				types = ["grass_green", "wheat"]
			7, 8, 9:
				types = ["grass_green", "wheat", "flower"]
			_:
				types = ["grass_green", "wheat", "flower", "grass_yellow", "grass_blue", "grass_purple"]
	return types
