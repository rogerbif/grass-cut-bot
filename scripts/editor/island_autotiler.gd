extends RefCounted

# Recalcula automaticamente os tiles de borda, quina externa e centro
# para todas as células marcadas com "auto": true no dicionário terrain_grid.
static func apply_autotile(terrain_grid: Dictionary) -> void:
	for cell_key in terrain_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var entry: Dictionary = terrain_grid[cell] as Dictionary
		if not entry.get("auto", false):
			continue

		var resolved: Dictionary = compute_tile_for_cell(cell, terrain_grid)
		entry["tile_id"] = resolved["tile_id"]
		entry["rot"] = resolved["rot"]

static func compute_tile_for_cell(cell: Vector2i, terrain_grid: Dictionary) -> Dictionary:
	var has_n: bool = terrain_grid.has(cell + Vector2i(0, -1))
	var has_s: bool = terrain_grid.has(cell + Vector2i(0, 1))
	var has_e: bool = terrain_grid.has(cell + Vector2i(1, 0))
	var has_w: bool = terrain_grid.has(cell + Vector2i(-1, 0))

	# Quinas externas (2 lados adjacentes voltados para o mar)
	if not has_n and not has_e and has_s and has_w:
		return { "tile_id": "island_corner_out", "rot": 0 }
	if not has_n and not has_w and has_s and has_e:
		return { "tile_id": "island_corner_out", "rot": 90 }
	if not has_s and not has_w and has_n and has_e:
		return { "tile_id": "island_corner_out", "rot": 180 }
	if not has_s and not has_e and has_n and has_w:
		return { "tile_id": "island_corner_out", "rot": 270 }

	# Bordas retas simples (1 lado voltado para o mar)
	if not has_n and has_s and has_e and has_w:
		return { "tile_id": "island_edge", "rot": 0 }
	if not has_w and has_n and has_s and has_e:
		return { "tile_id": "island_edge", "rot": 90 }
	if not has_s and has_n and has_e and has_w:
		return { "tile_id": "island_edge", "rot": 180 }
	if not has_e and has_n and has_s and has_w:
		return { "tile_id": "island_edge", "rot": 270 }

	# Centro ou corredor estreito (as barreiras e espumas extras são injetadas pelo LevelJsonLoader)
	return { "tile_id": "island_center", "rot": 0 }
