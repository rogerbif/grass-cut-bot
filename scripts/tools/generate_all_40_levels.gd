extends SceneTree

const IslandAutotiler = preload("res://scripts/editor/island_autotiler.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")

const CELL_SIZE: float = 0.80
const MIN_SPAWN_CLEAR_DIST: float = 1.47 # 1.05 * 1.40m (raio lâmina nv 6)
const MIN_ROCK_SPACING: float = 2.80      # 2.00 * 1.40m (diâmetro lâmina nv 6)
const SPAWN_GRASS_CLEAR_RADIUS: float = 0.72 # Clareira sutil no spawn

func _init() -> void:
	print("=== GERADOR E AUDITOR DAS FASES DE EXPANSÃO 21 A 40 (MEGA-ILHAS CANÔNICAS) ===")
	var total_errors: int = 0
	for lvl: int in range(21, 41):
		var errs: int = generate_level(lvl)
		total_errors += errs
	if total_errors == 0:
		print("=== SUCESSO ABSOLUTO: TODAS AS FASES 21 A 40 GERADAS COM 0 ERROS! ===")
	else:
		printerr("=== AUDITORIA: %d ERROS ENCONTRADOS NAS FASES ===" % total_errors)
	quit(1 if total_errors > 0 else 0)


func generate_level(lvl: int) -> int:
	var terrain_grid: Dictionary = {}
	var object_grid: Dictionary = {}
	var vector_field: RefCounted = VectorGrassFieldScript.new()
	var spawn_cell: Vector2i = Vector2i.ZERO
	var width: int = 25
	var height: int = 25
	var base_time_limit: float = 120.0
	var level_name: String = ""
	var custom_goals: Dictionary = {}

	match lvl:
		21:
			level_name = "O Labirinto da Serpente Dourada"
			width = 23; height = 23; base_time_limit = 135.0
			spawn_cell = Vector2i(11, 11)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 19, 19, 3) # ~310 tiles
			_add_diagonal_stripes(vector_field, width, height, ["grass_green", "grass_yellow"], 1.60)
			# 5 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 6))
			# Trigo sinuoso e flores sino
			for c: Vector2i in [
				Vector2i(9, 9), Vector2i(10, 9), Vector2i(12, 9), Vector2i(13, 9),
				Vector2i(9, 13), Vector2i(10, 13), Vector2i(12, 13), Vector2i(13, 13),
				Vector2i(9, 10), Vector2i(9, 12), Vector2i(13, 10), Vector2i(13, 12)
			]:
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c)
			for c: Vector2i in [Vector2i(6, 11), Vector2i(16, 11), Vector2i(11, 4), Vector2i(11, 18), Vector2i(5, 5), Vector2i(17, 17)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_bell")
			custom_goals = { "grass": 160, "wheat": 12, "flower_bell": 6 }

		22:
			level_name = "O Grande Atol Esmeralda"
			width = 23; height = 23; base_time_limit = 140.0
			spawn_cell = Vector2i(11, 11)
			_add_octagon_island(terrain_grid, 11, 11, 9) # ~290 tiles
			_add_grass_circle(vector_field, "grass_blue", 11, 11, width, height, 4.8)
			_add_grass_ring(vector_field, "grass_green", 11, 11, width, height, 2.5, 4.8)
			_add_grass_ring(vector_field, "grass_yellow", 11, 11, width, height, 4.8, 6.4)
			# 6 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 15))
			# 8 margaridas + 6 girassóis
			for c: Vector2i in [Vector2i(8, 6), Vector2i(14, 6), Vector2i(8, 16), Vector2i(14, 16), Vector2i(6, 8), Vector2i(16, 8), Vector2i(6, 14), Vector2i(16, 14)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_daisy")
			for c: Vector2i in [Vector2i(11, 8), Vector2i(11, 14), Vector2i(8, 11), Vector2i(14, 11), Vector2i(7, 15), Vector2i(15, 7)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_sunflower")
			custom_goals = { "grass": 170, "flower_daisy": 8, "flower_sunflower": 6 }

		23:
			level_name = "As Ilhas Gêmeas de Safira"
			width = 25; height = 21; base_time_limit = 140.0
			spawn_cell = Vector2i(6, 10)
			# Duas grandes ilhas com ponte larga
			_add_chamfered_rect_island(terrain_grid, 2, 2, 9, 17, 2)
			_add_chamfered_rect_island(terrain_grid, 14, 2, 9, 17, 2)
			_add_rect_island(terrain_grid, 9, 8, 7, 5) # Ponte larga de 5 tiles
			_add_grass_rect(vector_field, "grass_blue", 2, 2, 10, 18, width, height)
			_add_grass_rect(vector_field, "grass_purple", 14, 2, 22, 18, width, height)
			_add_grass_rect(vector_field, "grass_green", 8, 8, 16, 12, width, height)
			# 5 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 10))
			# Trigo e Tulipas
			for c: Vector2i in [Vector2i(11, 7), Vector2i(11, 13), Vector2i(13, 7), Vector2i(13, 13), Vector2i(4, 10), Vector2i(8, 10), Vector2i(16, 10), Vector2i(20, 10)]:
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c)
			for c: Vector2i in [Vector2i(4, 4), Vector2i(8, 4), Vector2i(4, 16), Vector2i(8, 16), Vector2i(16, 4), Vector2i(20, 4), Vector2i(16, 16), Vector2i(20, 16)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_tulip")
			custom_goals = { "grass": 165, "wheat": 8, "flower_tulip": 8 }

		24:
			level_name = "O Bosque dos Três Canteiros"
			width = 25; height = 25; base_time_limit = 145.0
			spawn_cell = Vector2i(12, 12)
			_add_rounded_cross_island(terrain_grid, 12, 12, 10, 9) # ~340 tiles
			_add_grass_rect(vector_field, "grass_green", 3, 3, 12, 12, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 13, 3, 21, 12, width, height)
			_add_grass_rect(vector_field, "grass_blue", 3, 13, 12, 21, width, height)
			_add_grass_rect(vector_field, "grass_purple", 13, 13, 21, 21, width, height)
			_add_grass_circle(vector_field, "grass_white", 12, 12, width, height, 3.2)
			# 6 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 19))
			# 8 canteiros + 6 rosas
			for c: Vector2i in [Vector2i(9, 7), Vector2i(15, 7), Vector2i(9, 17), Vector2i(15, 17), Vector2i(7, 9), Vector2i(17, 9), Vector2i(7, 15), Vector2i(17, 15)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_bed")
			for c: Vector2i in [Vector2i(12, 8), Vector2i(12, 16), Vector2i(8, 12), Vector2i(16, 12), Vector2i(5, 12), Vector2i(19, 12)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_rose")
			custom_goals = { "grass": 180, "flower_bed": 8, "flower_rose": 6 }

		25:
			level_name = "A Fortaleza de Granito"
			width = 25; height = 25; base_time_limit = 150.0
			spawn_cell = Vector2i(12, 12)
			_add_diamond_island(terrain_grid, 12, 12, 10) # ~220 tiles
			_add_grass_diamond_world(vector_field, "grass_black", Vector2.ZERO, 6.8)
			_add_grass_diamond_world(vector_field, "grass_red", Vector2.ZERO, 4.5)
			_add_grass_diamond_world(vector_field, "grass_yellow", Vector2.ZERO, 2.5)
			# 7 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 18))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(9, 9))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 9))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(9, 15))
			# 6 corolas + 12 trigo
			for c: Vector2i in [Vector2i(12, 8), Vector2i(12, 16), Vector2i(8, 12), Vector2i(16, 12), Vector2i(15, 15), Vector2i(14, 10)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_corolla")
			for c: Vector2i in [
				Vector2i(10, 8), Vector2i(14, 8), Vector2i(10, 16), Vector2i(14, 16),
				Vector2i(8, 10), Vector2i(8, 14), Vector2i(16, 10), Vector2i(16, 14),
				Vector2i(11, 7), Vector2i(13, 7), Vector2i(11, 17), Vector2i(13, 17)
			]:
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c)
			custom_goals = { "grass": 175, "flower_corolla": 6, "wheat": 12 }

		26:
			level_name = "O Vale das Tulipas Imperiais"
			width = 25; height = 25; base_time_limit = 150.0
			spawn_cell = Vector2i(12, 12)
			# H grande
			_add_rect_island(terrain_grid, 2, 2, 7, 21)
			_add_rect_island(terrain_grid, 16, 2, 7, 21)
			_add_rect_island(terrain_grid, 8, 9, 9, 7) # Conexão
			_add_grass_rect(vector_field, "grass_green", 2, 2, 8, 22, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 16, 2, 22, 22, width, height)
			_add_grass_rect(vector_field, "grass_white", 8, 9, 16, 15, width, height)
			# 6 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 19))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 19))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 12))
			# 10 tulipas + 6 margaridas
			for c: Vector2i in [
				Vector2i(4, 7), Vector2i(6, 7), Vector2i(4, 17), Vector2i(6, 17),
				Vector2i(18, 7), Vector2i(20, 7), Vector2i(18, 17), Vector2i(20, 17),
				Vector2i(10, 12), Vector2i(14, 12)
			]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_tulip")
			for c: Vector2i in [Vector2i(4, 10), Vector2i(6, 14), Vector2i(18, 10), Vector2i(20, 14), Vector2i(12, 10), Vector2i(12, 14)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_daisy")
			custom_goals = { "grass": 185, "flower_tulip": 10, "flower_daisy": 6 }

		27:
			level_name = "O Grande Lago Interior"
			width = 27; height = 27; base_time_limit = 155.0
			spawn_cell = Vector2i(13, 5)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 23, 23, 3) # ~450 tiles
			# Recorta lago central de 7x7
			for x: int in range(10, 17):
				for z: int in range(10, 17):
					terrain_grid.erase(Vector2i(x, z))
			_add_grass_rect(vector_field, "grass_blue", 3, 3, 23, 23, width, height)
			_add_grass_rect(vector_field, "grass_green", 5, 5, 21, 21, width, height)
			# 6 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(20, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 20))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(20, 20))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 21))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 13))
			# 8 girassóis + 16 trigos
			for c: Vector2i in [Vector2i(13, 8), Vector2i(13, 18), Vector2i(8, 13), Vector2i(18, 13), Vector2i(9, 7), Vector2i(17, 7), Vector2i(9, 19), Vector2i(17, 19)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_sunflower")
			for c: Vector2i in [
				Vector2i(8, 9), Vector2i(9, 8), Vector2i(17, 8), Vector2i(18, 9),
				Vector2i(8, 17), Vector2i(9, 18), Vector2i(17, 18), Vector2i(18, 17),
				Vector2i(7, 13), Vector2i(19, 13), Vector2i(13, 3), Vector2i(13, 23),
				Vector2i(3, 13), Vector2i(23, 13), Vector2i(10, 5), Vector2i(16, 5)
			]:
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c)
			custom_goals = { "grass": 190, "flower_sunflower": 8, "wheat": 16 }

		28:
			level_name = "A Espiral da Colheita"
			width = 27; height = 27; base_time_limit = 160.0
			spawn_cell = Vector2i(13, 13)
			_add_octagon_island(terrain_grid, 13, 13, 11) # ~370 tiles
			_add_grass_circle(vector_field, "grass_yellow", 13, 13, width, height, 7.5)
			_add_grass_circle(vector_field, "grass_green", 13, 13, width, height, 5.0)
			_add_grass_circle(vector_field, "grass_yellow", 13, 13, width, height, 2.5)
			# 6 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 20))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 13))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(20, 13))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 18))
			# 20 trigo + 8 flores sino
			for c: Vector2i in [
				Vector2i(10, 10), Vector2i(11, 10), Vector2i(12, 10), Vector2i(14, 10), Vector2i(15, 10), Vector2i(16, 10),
				Vector2i(10, 16), Vector2i(11, 16), Vector2i(12, 16), Vector2i(14, 16), Vector2i(15, 16), Vector2i(16, 16),
				Vector2i(10, 11), Vector2i(10, 12), Vector2i(10, 14), Vector2i(10, 15),
				Vector2i(16, 11), Vector2i(16, 12), Vector2i(16, 14), Vector2i(16, 15)
			]:
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c)
			for c: Vector2i in [Vector2i(13, 9), Vector2i(13, 17), Vector2i(9, 13), Vector2i(17, 13), Vector2i(8, 18), Vector2i(18, 8), Vector2i(5, 9), Vector2i(21, 17)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_bell")
			custom_goals = { "grass": 195, "wheat": 20, "flower_bell": 8 }

		29:
			level_name = "A Rosa dos Ventos"
			width = 27; height = 27; base_time_limit = 160.0
			spawn_cell = Vector2i(13, 13)
			_add_star_island(terrain_grid, 13, 13, 11, 8) # ~340 tiles
			_add_grass_star_world(vector_field, "grass_black", Vector2.ZERO, 7.5, 6.0, 8)
			_add_grass_star_world(vector_field, "grass_blue", Vector2.ZERO, 6.0, 4.5, 8)
			_add_grass_star_world(vector_field, "grass_red", Vector2.ZERO, 4.5, 3.0, 8)
			_add_grass_star_world(vector_field, "grass_yellow", Vector2.ZERO, 3.0, 1.8, 8)
			# 6 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 21))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 13))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(21, 13))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 18))
			# 8 rosas + 8 corolas
			for c: Vector2i in [Vector2i(13, 7), Vector2i(13, 19), Vector2i(7, 13), Vector2i(19, 13), Vector2i(9, 9), Vector2i(17, 9), Vector2i(9, 17), Vector2i(17, 17)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_rose")
			for c: Vector2i in [Vector2i(13, 10), Vector2i(13, 16), Vector2i(10, 13), Vector2i(16, 13), Vector2i(10, 10), Vector2i(16, 10), Vector2i(10, 16), Vector2i(16, 16)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_corolla")
			custom_goals = { "grass": 190, "flower_rose": 8, "flower_corolla": 8 }

		30:
			level_name = "O Arquipélago das Quatro Lagoas"
			width = 27; height = 27; base_time_limit = 165.0
			spawn_cell = Vector2i(13, 13)
			_add_clover_island(terrain_grid, 13, 13)
			# Expande as 4 folhas
			_add_rect_island(terrain_grid, 6, 2, 15, 6)
			_add_rect_island(terrain_grid, 6, 19, 15, 6)
			_add_rect_island(terrain_grid, 2, 6, 6, 15)
			_add_rect_island(terrain_grid, 19, 6, 6, 15)
			_add_grass_rect(vector_field, "grass_green", 6, 2, 20, 8, width, height)
			_add_grass_rect(vector_field, "grass_blue", 6, 18, 20, 24, width, height)
			_add_grass_rect(vector_field, "grass_purple", 2, 6, 8, 20, width, height)
			_add_grass_rect(vector_field, "grass_red", 18, 6, 24, 20, width, height)
			_add_grass_circle(vector_field, "grass_white", 13, 13, width, height, 4.2)
			# 7 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 19))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 13))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 13))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(9, 9))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(9, 17))
			# 6 canteiros + 6 girassóis + 12 trigo
			for c: Vector2i in [Vector2i(13, 4), Vector2i(13, 22), Vector2i(4, 13), Vector2i(22, 13), Vector2i(8, 8), Vector2i(18, 18)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_bed")
			for c: Vector2i in [Vector2i(10, 4), Vector2i(16, 4), Vector2i(10, 22), Vector2i(16, 22), Vector2i(4, 10), Vector2i(22, 16)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_sunflower")
			for c: Vector2i in [
				Vector2i(11, 10), Vector2i(15, 10), Vector2i(11, 16), Vector2i(15, 16),
				Vector2i(10, 11), Vector2i(10, 15), Vector2i(16, 11), Vector2i(16, 15),
				Vector2i(12, 9), Vector2i(14, 9), Vector2i(12, 17), Vector2i(14, 17)
			]:
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c)
			custom_goals = { "grass": 200, "flower_bed": 6, "flower_sunflower": 6, "wheat": 12 }

		31:
			level_name = "O Tridente Coralino"
			width = 29; height = 29; base_time_limit = 170.0
			spawn_cell = Vector2i(14, 23)
			# Base sul e 3 penínsulas
			_add_rect_island(terrain_grid, 2, 18, 25, 9)
			_add_rect_island(terrain_grid, 3, 2, 6, 17)
			_add_rect_island(terrain_grid, 11, 2, 7, 17)
			_add_rect_island(terrain_grid, 20, 2, 6, 17)
			_add_grass_rect(vector_field, "grass_blue", 2, 18, 26, 26, width, height)
			_add_grass_rect(vector_field, "grass_green", 3, 2, 9, 18, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 11, 2, 18, 18, width, height)
			_add_grass_rect(vector_field, "grass_purple", 20, 2, 26, 18, width, height)
			# 6 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(23, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 20))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(20, 20))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 18))
			# 8 flores sino + 8 tulipas
			for c: Vector2i in [Vector2i(6, 4), Vector2i(6, 8), Vector2i(14, 4), Vector2i(14, 8), Vector2i(23, 4), Vector2i(23, 8), Vector2i(5, 22), Vector2i(23, 22)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_bell")
			for c: Vector2i in [Vector2i(6, 6), Vector2i(6, 15), Vector2i(14, 6), Vector2i(14, 15), Vector2i(23, 6), Vector2i(23, 15), Vector2i(10, 22), Vector2i(18, 22)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_tulip")
			custom_goals = { "grass": 210, "flower_bell": 8, "flower_tulip": 8 }

		32:
			level_name = "O Jardim Suspenso da Falésia"
			width = 29; height = 29; base_time_limit = 170.0
			spawn_cell = Vector2i(14, 14)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 25, 25, 4) # ~460 tiles
			_add_diagonal_stripes(vector_field, width, height, ["grass_green", "grass_yellow"], 2.20)
			# 7 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(21, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 21))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(21, 21))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 22))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 14))
			# 10 canteiros + 8 margaridas
			for c: Vector2i in [
				Vector2i(10, 8), Vector2i(18, 8), Vector2i(10, 20), Vector2i(18, 20),
				Vector2i(8, 10), Vector2i(20, 10), Vector2i(8, 18), Vector2i(20, 18),
				Vector2i(14, 9), Vector2i(14, 19)
			]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_bed")
			for c: Vector2i in [Vector2i(11, 11), Vector2i(17, 11), Vector2i(11, 17), Vector2i(17, 17), Vector2i(9, 14), Vector2i(19, 14), Vector2i(5, 10), Vector2i(23, 18)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_daisy")
			custom_goals = { "grass": 220, "flower_bed": 10, "flower_daisy": 8 }

		33:
			level_name = "O Enclave dos Monólitos"
			width = 29; height = 29; base_time_limit = 175.0
			spawn_cell = Vector2i(14, 14)
			_add_octagon_island(terrain_grid, 14, 14, 12) # ~440 tiles
			_add_grass_circle(vector_field, "grass_purple", 14, 14, width, height, 8.5)
			_add_grass_circle(vector_field, "grass_white", 14, 14, width, height, 4.8)
			_add_grass_ring(vector_field, "grass_green", 14, 14, width, height, 4.8, 7.0)
			# 8 rochas em círculo amplo
			for i: int in range(8):
				var a: float = float(i) * TAU / 8.0
				var rx: int = 14 + int(round(cos(a) * 7.5))
				var rz: int = 14 + int(round(sin(a) * 7.5))
				_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(rx, rz))
			# 8 rosas + 16 trigo
			for c: Vector2i in [
				Vector2i(14, 9), Vector2i(14, 19), Vector2i(9, 14), Vector2i(19, 14),
				Vector2i(11, 11), Vector2i(17, 11), Vector2i(11, 17), Vector2i(17, 17)
			]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_rose")
			for i: int in range(16):
				var a: float = float(i) * TAU / 16.0
				var wx: int = 14 + int(round(cos(a) * 10.0))
				var wz: int = 14 + int(round(sin(a) * 10.0))
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(wx, wz))
			custom_goals = { "grass": 225, "flower_rose": 8, "wheat": 16 }

		34:
			level_name = "O Mosaico Imperial"
			width = 29; height = 29; base_time_limit = 175.0
			spawn_cell = Vector2i(14, 14)
			_add_rounded_cross_island(terrain_grid, 14, 14, 12, 11) # ~480 tiles
			_add_grass_circle(vector_field, "grass_yellow", 14, 14, width, height, 8.8)
			_add_grass_ring(vector_field, "grass_red", 14, 14, width, height, 4.2, 7.0)
			_add_grass_circle(vector_field, "grass_green", 14, 14, width, height, 4.2)
			# 7 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(20, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 20))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(20, 20))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 23))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 14))
			# 8 corolas + 8 tulipas
			for c: Vector2i in [Vector2i(14, 8), Vector2i(14, 20), Vector2i(8, 14), Vector2i(20, 14), Vector2i(11, 11), Vector2i(17, 11), Vector2i(11, 17), Vector2i(17, 17)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_corolla")
			for c: Vector2i in [Vector2i(14, 11), Vector2i(14, 17), Vector2i(11, 14), Vector2i(17, 14), Vector2i(6, 11), Vector2i(22, 11), Vector2i(6, 17), Vector2i(22, 17)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_tulip")
			custom_goals = { "grass": 230, "flower_corolla": 8, "flower_tulip": 8 }

		35:
			level_name = "A Encruzilhada das Quatro Estações"
			width = 31; height = 31; base_time_limit = 180.0
			spawn_cell = Vector2i(15, 15)
			# 4 grandes quadrantes unidos por praça
			_add_chamfered_rect_island(terrain_grid, 2, 2, 13, 13, 2)
			_add_chamfered_rect_island(terrain_grid, 16, 2, 13, 13, 2)
			_add_chamfered_rect_island(terrain_grid, 2, 16, 13, 13, 2)
			_add_chamfered_rect_island(terrain_grid, 16, 16, 13, 13, 2)
			_add_rect_island(terrain_grid, 10, 10, 11, 11) # Praça central
			_add_grass_rect(vector_field, "grass_green", 2, 2, 14, 14, width, height)  # Primavera
			_add_grass_rect(vector_field, "grass_yellow", 16, 2, 28, 14, width, height) # Verão
			_add_grass_rect(vector_field, "grass_red", 2, 16, 14, 28, width, height)    # Outono
			_add_grass_rect(vector_field, "grass_white", 16, 16, 28, 28, width, height) # Inverno
			_add_grass_circle(vector_field, "grass_blue", 15, 15, width, height, 4.0)
			# 8 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(23, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 23))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(23, 23))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 22))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(22, 15))
			# 6 girassóis + 6 rosas + 6 tulipas + 12 trigo
			for c: Vector2i in [Vector2i(21, 5), Vector2i(25, 5), Vector2i(21, 9), Vector2i(25, 9), Vector2i(23, 11), Vector2i(19, 7)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_sunflower")
			for c: Vector2i in [Vector2i(5, 5), Vector2i(9, 5), Vector2i(5, 9), Vector2i(9, 9), Vector2i(7, 11), Vector2i(11, 7)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_rose")
			for c: Vector2i in [Vector2i(5, 21), Vector2i(9, 21), Vector2i(5, 25), Vector2i(9, 25), Vector2i(21, 21), Vector2i(25, 25)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_tulip")
			for c: Vector2i in [
				Vector2i(13, 11), Vector2i(17, 11), Vector2i(13, 19), Vector2i(17, 19),
				Vector2i(11, 13), Vector2i(11, 17), Vector2i(19, 13), Vector2i(19, 17),
				Vector2i(14, 10), Vector2i(16, 10), Vector2i(14, 20), Vector2i(16, 20)
			]:
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c)
			custom_goals = { "grass": 240, "flower_sunflower": 6, "flower_rose": 6, "flower_tulip": 6, "wheat": 12 }

		36:
			level_name = "O Labirinto dos Guardiões"
			width = 31; height = 31; base_time_limit = 185.0
			spawn_cell = Vector2i(15, 15)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 27, 27, 4) # ~540 tiles
			_add_grass_rect(vector_field, "grass_green", 3, 3, 27, 27, width, height)
			_add_grass_ring(vector_field, "grass_yellow", 15, 15, width, height, 4.0, 7.5)
			_add_grass_ring(vector_field, "grass_yellow", 15, 15, width, height, 9.0, 11.5)
			# 8 rochas
			for i: int in range(8):
				var a: float = float(i) * TAU / 8.0
				var rx: int = 15 + int(round(cos(a) * 8.5))
				var rz: int = 15 + int(round(sin(a) * 8.5))
				_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(rx, rz))
			# 24 trigos formando muralhas + 8 canteiros
			for i: int in range(24):
				var a: float = float(i) * TAU / 24.0
				var wx: int = 15 + int(round(cos(a) * 5.5))
				var wz: int = 15 + int(round(sin(a) * 5.5))
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(wx, wz))
			for c: Vector2i in [
				Vector2i(15, 9), Vector2i(15, 21), Vector2i(9, 15), Vector2i(21, 15),
				Vector2i(6, 6), Vector2i(24, 6), Vector2i(6, 24), Vector2i(24, 24)
			]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_bed")
			custom_goals = { "grass": 250, "wheat": 24, "flower_bed": 8 }

		37:
			level_name = "A Coroa de Ilhotas"
			width = 31; height = 31; base_time_limit = 185.0
			spawn_cell = Vector2i(15, 15)
			_add_octagon_island(terrain_grid, 15, 15, 7) # Núcleo
			# 4 satélites chanfrados
			_add_chamfered_rect_island(terrain_grid, 2, 2, 9, 9, 2)
			_add_chamfered_rect_island(terrain_grid, 20, 2, 9, 9, 2)
			_add_chamfered_rect_island(terrain_grid, 2, 20, 9, 9, 2)
			_add_chamfered_rect_island(terrain_grid, 20, 20, 9, 9, 2)
			# Istmos de 3 tiles de largura
			for i: int in range(9, 14):
				for j: int in range(i - 1, i + 2):
					terrain_grid[Vector2i(j, j)] = { "tile_id": "island_center", "rot": 0, "auto": true }
					terrain_grid[Vector2i(30 - j, j)] = { "tile_id": "island_center", "rot": 0, "auto": true }
			_add_grass_circle(vector_field, "grass_blue", 15, 15, width, height, 5.0)
			_add_grass_rect(vector_field, "grass_yellow", 2, 2, 10, 10, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 20, 2, 28, 10, width, height)
			_add_grass_rect(vector_field, "grass_green", 2, 20, 10, 28, width, height)
			_add_grass_rect(vector_field, "grass_green", 20, 20, 28, 28, width, height)
			# 8 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(24, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 24))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(24, 24))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 20))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(20, 15))
			# 8 flores sino + 8 margaridas
			for c: Vector2i in [Vector2i(4, 6), Vector2i(8, 6), Vector2i(22, 6), Vector2i(26, 6), Vector2i(4, 24), Vector2i(8, 24), Vector2i(22, 24), Vector2i(26, 24)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_bell")
			for c: Vector2i in [Vector2i(6, 4), Vector2i(6, 8), Vector2i(24, 4), Vector2i(24, 8), Vector2i(13, 13), Vector2i(17, 13), Vector2i(13, 17), Vector2i(17, 17)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_daisy")
			custom_goals = { "grass": 235, "flower_bell": 8, "flower_daisy": 8 }

		38:
			level_name = "O Grande Fiorde Selvagem"
			width = 31; height = 31; base_time_limit = 190.0
			spawn_cell = Vector2i(15, 6)
			# Grande S largo
			_add_rect_island(terrain_grid, 2, 2, 27, 8)
			_add_rect_island(terrain_grid, 21, 8, 8, 15)
			_add_rect_island(terrain_grid, 2, 14, 21, 8)
			_add_rect_island(terrain_grid, 2, 20, 8, 9)
			_add_rect_island(terrain_grid, 8, 22, 21, 7)
			_add_grass_rect(vector_field, "grass_black", 2, 2, 28, 9, width, height)
			_add_grass_rect(vector_field, "grass_red", 2, 14, 28, 21, width, height)
			_add_grass_rect(vector_field, "grass_green", 2, 22, 28, 28, width, height)
			# 8 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(23, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(24, 14))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 18))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 25))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 25))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(25, 25))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 18))
			# 10 corolas + 20 trigos
			for c: Vector2i in [
				Vector2i(5, 6), Vector2i(12, 6), Vector2i(19, 6), Vector2i(25, 10), Vector2i(25, 18),
				Vector2i(7, 18), Vector2i(15, 18), Vector2i(21, 18), Vector2i(12, 25), Vector2i(21, 25)
			]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_corolla")
			for i: int in range(20):
				var c_tr: Vector2i = Vector2i(4 + i, 4 if i < 10 else (16 if i < 16 else 24))
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c_tr)
			custom_goals = { "grass": 245, "flower_corolla": 10, "wheat": 20 }

		39:
			level_name = "O Santuário Botânico"
			width = 31; height = 31; base_time_limit = 195.0
			spawn_cell = Vector2i(15, 15)
			_add_octagon_island(terrain_grid, 15, 15, 13) # ~520 tiles
			_add_grass_star_world(vector_field, "grass_purple", Vector2.ZERO, 9.5, 7.5, 12)
			_add_grass_star_world(vector_field, "grass_blue", Vector2.ZERO, 7.5, 5.5, 12)
			_add_grass_star_world(vector_field, "grass_yellow", Vector2.ZERO, 5.5, 3.5, 12)
			_add_grass_circle(vector_field, "grass_green", 15, 15, width, height, 3.5)
			# 8 rochas
			for i: int in range(8):
				var a: float = float(i) * TAU / 8.0
				var rx: int = 15 + int(round(cos(a) * 9.5))
				var rz: int = 15 + int(round(sin(a) * 9.5))
				_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(rx, rz))
			# 6 rosas + 6 girassóis + 6 tulipas + 6 canteiros
			for i: int in range(6):
				var a: float = float(i) * TAU / 6.0
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(15 + int(round(cos(a) * 6.5)), 15 + int(round(sin(a) * 6.5))), "flower_rose")
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(15 + int(round(cos(a + 0.25) * 8.0)), 15 + int(round(sin(a + 0.25) * 8.0))), "flower_sunflower")
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(15 + int(round(cos(a + 0.5) * 9.5)), 15 + int(round(sin(a + 0.5) * 9.5))), "flower_tulip")
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(15 + int(round(cos(a + 0.75) * 11.0)), 15 + int(round(sin(a + 0.75) * 11.0))), "flower_bed")
			custom_goals = { "grass": 255, "flower_rose": 6, "flower_sunflower": 6, "flower_tulip": 6, "flower_bed": 6 }

		40:
			level_name = "O Grande Arquipélago Mestre"
			width = 31; height = 31; base_time_limit = 200.0
			spawn_cell = Vector2i(15, 15)
			# Mega-arquipélago: ilha central e 4 cantos com pontes largas
			_add_chamfered_rect_island(terrain_grid, 9, 9, 13, 13, 3) # Centro
			_add_chamfered_rect_island(terrain_grid, 2, 2, 10, 10, 2)
			_add_chamfered_rect_island(terrain_grid, 19, 2, 10, 10, 2)
			_add_chamfered_rect_island(terrain_grid, 2, 19, 10, 10, 2)
			_add_chamfered_rect_island(terrain_grid, 19, 19, 10, 10, 2)
			# Pontes largas de 4 tiles de largura
			_add_rect_island(terrain_grid, 7, 7, 6, 6)
			_add_rect_island(terrain_grid, 18, 7, 6, 6)
			_add_rect_island(terrain_grid, 7, 18, 6, 6)
			_add_rect_island(terrain_grid, 18, 18, 6, 6)
			_add_grass_circle(vector_field, "grass_white", 15, 15, width, height, 4.8)
			_add_grass_ring(vector_field, "grass_yellow", 15, 15, width, height, 2.5, 4.8)
			_add_grass_rect(vector_field, "grass_green", 2, 2, 11, 11, width, height)
			_add_grass_rect(vector_field, "grass_blue", 19, 2, 28, 11, width, height)
			_add_grass_rect(vector_field, "grass_purple", 2, 19, 11, 28, width, height)
			_add_grass_rect(vector_field, "grass_red", 19, 19, 28, 28, width, height)
			# 8 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(24, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 24))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(24, 24))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 22))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(22, 15))
			# 6 rosas + 6 tulipas + 6 girassóis + 6 margaridas + 16 trigos (exatamente 6 metas!)
			for c: Vector2i in [Vector2i(4, 4), Vector2i(8, 4), Vector2i(4, 8), Vector2i(13, 11), Vector2i(17, 11), Vector2i(15, 12)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_rose")
			for c: Vector2i in [Vector2i(22, 4), Vector2i(26, 4), Vector2i(26, 8), Vector2i(13, 19), Vector2i(17, 19), Vector2i(15, 18)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_tulip")
			for c: Vector2i in [Vector2i(4, 22), Vector2i(8, 22), Vector2i(4, 26), Vector2i(11, 13), Vector2i(11, 17), Vector2i(12, 15)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_sunflower")
			for c: Vector2i in [Vector2i(22, 26), Vector2i(26, 26), Vector2i(26, 22), Vector2i(19, 13), Vector2i(19, 17), Vector2i(18, 15)]:
				_add_valid_flower(terrain_grid, object_grid, spawn_cell, c, "flower_daisy")
			for c: Vector2i in [
				Vector2i(7, 7), Vector2i(8, 7), Vector2i(7, 8), Vector2i(8, 8),
				Vector2i(22, 7), Vector2i(23, 7), Vector2i(22, 8), Vector2i(23, 8),
				Vector2i(7, 22), Vector2i(8, 22), Vector2i(7, 23), Vector2i(8, 23),
				Vector2i(22, 22), Vector2i(23, 22), Vector2i(22, 23), Vector2i(23, 23)
			]:
				_add_valid_wheat(terrain_grid, object_grid, spawn_cell, c)
			custom_goals = { "grass": 270, "flower_rose": 6, "flower_tulip": 6, "flower_sunflower": 6, "flower_daisy": 6, "wheat": 16 }

	IslandAutotiler.apply_autotile(terrain_grid)
	_clip_vector_field_to_island(vector_field, terrain_grid, spawn_cell, width, height)

	if lvl == 27:
		var p0: Vector3 = LevelJsonLoader.grid_to_world(10, 10, width, height, CELL_SIZE)
		var p1: Vector3 = LevelJsonLoader.grid_to_world(16, 16, width, height, CELL_SIZE)
		var lake_poly: PackedVector2Array = PackedVector2Array([
			Vector2(p0.x - 0.50, p0.z - 0.50),
			Vector2(p1.x + 0.50, p0.z - 0.50),
			Vector2(p1.x + 0.50, p1.z + 0.50),
			Vector2(p0.x - 0.50, p1.z + 0.50)
		])
		vector_field.call("clip_shapes", lake_poly)

	var audit_res: Dictionary = _validate_and_calibrate_level(
		lvl, level_name, base_time_limit, spawn_cell, terrain_grid, object_grid, vector_field, width, height
	)
	var err_count: int = int(audit_res.get("errors", 0))
	var calibrated_time: float = float(audit_res.get("time_limit", base_time_limit))

	var ok: bool = LevelSerializer.save_level_json(
		lvl,
		level_name,
		calibrated_time,
		width,
		height,
		spawn_cell,
		0,
		terrain_grid,
		object_grid,
		null,
		vector_field,
		custom_goals
	)

	if not ok:
		printerr("FALHA ao salvar nível %02d!" % lvl)
		err_count += 1

	return err_count


# --- Helpers Garantidores de Posição de Objetos ---
func _add_valid_rock(terrain_grid: Dictionary, object_grid: Dictionary, spawn_cell: Vector2i, pref: Vector2i) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-999, -999)
	var best_dist: float = 9999.0

	for dx: int in range(-4, 5):
		for dz: int in range(-4, 5):
			var c: Vector2i = pref + Vector2i(dx, dz)
			if object_grid.has(c) or not terrain_grid.has(c):
				continue
			var has_8: bool = true
			for ndx: int in range(-1, 2):
				for ndz: int in range(-1, 2):
					if not terrain_grid.has(c + Vector2i(ndx, ndz)):
						has_8 = false
						break
				if not has_8:
					break
			if not has_8:
				continue

			var dist_sp: float = float((c - spawn_cell).length()) * CELL_SIZE
			if dist_sp < MIN_SPAWN_CLEAR_DIST + 0.05:
				continue

			var rocks_ok: bool = true
			for ok: Variant in object_grid.keys():
				if String((object_grid[ok] as Dictionary).get("type", "")) == "rock":
					var dist_r: float = float((c - (ok as Vector2i)).length()) * CELL_SIZE
					if dist_r < MIN_ROCK_SPACING + 0.01:
						rocks_ok = false
						break
			if not rocks_ok:
				continue

			var d_pref: float = float((c - pref).length())
			if d_pref < best_dist:
				best_dist = d_pref
				best_cell = c

	if best_cell != Vector2i(-999, -999):
		object_grid[best_cell] = { "type": "rock", "rot": 0 }
		return best_cell
	else:
		printerr("AVISO: Falha ao posicionar rocha perto de %s" % str(pref))
		return Vector2i.ZERO


func _add_valid_flower(terrain_grid: Dictionary, object_grid: Dictionary, spawn_cell: Vector2i, pref: Vector2i, flower_type: String) -> Vector2i:
	var best_cell: Vector2i = Vector2i(-999, -999)
	var best_dist: float = 9999.0
	var cardinals: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

	for dx: int in range(-4, 5):
		for dz: int in range(-4, 5):
			var c: Vector2i = pref + Vector2i(dx, dz)
			if object_grid.has(c) or not terrain_grid.has(c):
				continue
			var cards_ok: bool = true
			for dir: Vector2i in cardinals:
				if not terrain_grid.has(c + dir):
					cards_ok = false
					break
			if not cards_ok:
				continue

			var dist_sp: float = float((c - spawn_cell).length()) * CELL_SIZE
			if dist_sp < MIN_SPAWN_CLEAR_DIST + 0.05:
				continue

			var d_pref: float = float((c - pref).length())
			if d_pref < best_dist:
				best_dist = d_pref
				best_cell = c

	if best_cell != Vector2i(-999, -999):
		object_grid[best_cell] = { "type": flower_type, "rot": 0 }
		return best_cell
	else:
		printerr("AVISO: Falha ao posicionar flor '%s' perto de %s" % [flower_type, str(pref)])
		return Vector2i.ZERO


func _add_valid_wheat(terrain_grid: Dictionary, object_grid: Dictionary, spawn_cell: Vector2i, pref: Vector2i) -> Vector2i:
	return _add_valid_flower(terrain_grid, object_grid, spawn_cell, pref, "wheat")


# --- Recorte Automático de Segurança Costeira e Clareira de Spawn ---
func _clip_vector_field_to_island(
	vf: RefCounted,
	terrain_grid: Dictionary,
	spawn_cell: Vector2i,
	width: int,
	height: int
) -> void:
	var row_polys: Array[PackedVector2Array] = []
	for gz: int in range(height):
		for gx: int in range(width):
			var c: Vector2i = Vector2i(gx, gz)
			if not terrain_grid.has(c):
				continue
			var center3: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, CELL_SIZE)
			var half: float = CELL_SIZE * 0.5 + 0.005
			var edge_inset: float = 0.06

			var min_x: float = center3.x - (half if terrain_grid.has(c + Vector2i(-1, 0)) else edge_inset)
			var max_x: float = center3.x + (half if terrain_grid.has(c + Vector2i(1, 0)) else edge_inset)
			var min_z: float = center3.z - (half if terrain_grid.has(c + Vector2i(0, -1)) else edge_inset)
			var max_z: float = center3.z + (half if terrain_grid.has(c + Vector2i(0, 1)) else edge_inset)

			if terrain_grid.has(c + Vector2i(-1, 0)) and terrain_grid.has(c + Vector2i(0, -1)) and not terrain_grid.has(c + Vector2i(-1, -1)):
				min_x = maxf(min_x, center3.x - 0.22)
				min_z = maxf(min_z, center3.z - 0.22)
			if terrain_grid.has(c + Vector2i(1, 0)) and terrain_grid.has(c + Vector2i(0, -1)) and not terrain_grid.has(c + Vector2i(1, -1)):
				max_x = minf(max_x, center3.x + 0.22)
				min_z = maxf(min_z, center3.z - 0.22)
			if terrain_grid.has(c + Vector2i(-1, 0)) and terrain_grid.has(c + Vector2i(0, 1)) and not terrain_grid.has(c + Vector2i(-1, 1)):
				min_x = maxf(min_x, center3.x - 0.22)
				max_z = minf(max_z, center3.z + 0.22)
			if terrain_grid.has(c + Vector2i(1, 0)) and terrain_grid.has(c + Vector2i(0, 1)) and not terrain_grid.has(c + Vector2i(1, 1)):
				max_x = minf(max_x, center3.x + 0.22)
				max_z = minf(max_z, center3.z + 0.22)

			if max_x > min_x and max_z > min_z:
				row_polys.append(PackedVector2Array([
					Vector2(min_x, min_z),
					Vector2(max_x, min_z),
					Vector2(max_x, max_z),
					Vector2(min_x, max_z)
				]))

	var mask_polys: Array[PackedVector2Array] = []
	for rp: PackedVector2Array in row_polys:
		var current_poly: PackedVector2Array = rp
		var remaining: Array[PackedVector2Array] = []
		for mp: PackedVector2Array in mask_polys:
			var merged: Array[PackedVector2Array] = Geometry2D.merge_polygons(current_poly, mp)
			var outer_merged: Array[PackedVector2Array] = []
			for m_part: PackedVector2Array in merged:
				if not Geometry2D.is_polygon_clockwise(m_part):
					outer_merged.append(m_part)
			if outer_merged.size() == 1:
				current_poly = outer_merged[0]
			else:
				remaining.append(mp)
		remaining.append(current_poly)
		mask_polys = remaining

	var old_shapes: Array = (vf.call("get_shapes") as Array).duplicate(true)
	vf.call("clear")
	for s_var: Variant in old_shapes:
		var s: Dictionary = s_var as Dictionary
		var s_type: String = String(s.get("type", "grass_green"))
		var s_poly: PackedVector2Array = s.get("polygon", PackedVector2Array()) as PackedVector2Array
		for mp: PackedVector2Array in mask_polys:
			var inter: Array[PackedVector2Array] = Geometry2D.intersect_polygons(s_poly, mp)
			for part: PackedVector2Array in inter:
				if not Geometry2D.is_polygon_clockwise(part) and part.size() >= 3:
					vf.call("add_shape", s_type, part)

	var sp3: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, width, height, CELL_SIZE)
	var sp_center: Vector2 = Vector2(sp3.x, sp3.z)
	var spawn_clear_poly: PackedVector2Array = PackedVector2Array()
	for i: int in range(20):
		var a: float = float(i) * TAU / 20.0
		spawn_clear_poly.append(sp_center + Vector2(cos(a), sin(a)) * SPAWN_GRASS_CLEAR_RADIUS)
	vf.call("clip_shapes", spawn_clear_poly)


# --- Métodos de Validação Estrita e Calibração de Tempo ---
func _validate_and_calibrate_level(
	lvl: int,
	lvl_name: String,
	base_time: float,
	spawn_cell: Vector2i,
	terrain_grid: Dictionary,
	object_grid: Dictionary,
	vf: RefCounted,
	width: int,
	height: int
) -> Dictionary:
	var errors: int = 0
	var sp_pos: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, width, height, CELL_SIZE)
	var rocks: Array[Vector3] = []

	# Regra 0: Spawn deve estar em tile interno
	for dx: int in range(-1, 2):
		for dz: int in range(-1, 2):
			if not terrain_grid.has(spawn_cell + Vector2i(dx, dz)):
				printerr("[ERRO LVL %d] Spawn %s próximo demais da borda costeira!" % [lvl, str(spawn_cell)])
				errors += 1

	for cell_key: Variant in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var obj: Dictionary = object_grid[cell] as Dictionary
		var o_type: String = String(obj.get("type", ""))
		var o_pos: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, width, height, CELL_SIZE)
		var dist_to_spawn: float = Vector2(o_pos.x - sp_pos.x, o_pos.z - sp_pos.z).length()

		# Regra 1: Spawn Seguro Central >= 1.47m
		if dist_to_spawn < MIN_SPAWN_CLEAR_DIST:
			printerr("[ERRO LVL %d] Objeto '%s' em %s invade spawn seguro! dist = %.2fm < 1.47m" % [lvl, o_type, str(cell), dist_to_spawn])
			errors += 1

		# Regra 2: Todo objeto deve estar sobre tile interno
		if not terrain_grid.has(cell):
			printerr("[ERRO LVL %d] Objeto '%s' em %s está FORA da ilha!" % [lvl, o_type, str(cell)])
			errors += 1
		else:
			var cardinals: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for dir: Vector2i in cardinals:
				if not terrain_grid.has(cell + dir):
					printerr("[ERRO LVL %d] Objeto '%s' em %s na borda!" % [lvl, o_type, str(cell)])
					errors += 1
					break

		if o_type == "rock":
			rocks.append(o_pos)
			for dx: int in range(-1, 2):
				for dz: int in range(-1, 2):
					if not terrain_grid.has(cell + Vector2i(dx, dz)):
						printerr("[ERRO LVL %d] Rocha em %s sem folga de 8 vizinhos!" % [lvl, str(cell)])
						errors += 1

	# Regra 3: Distância entre rochas > 2.80m
	for i: int in range(rocks.size()):
		for j: int in range(i + 1, rocks.size()):
			var dist: float = Vector2(rocks[i].x - rocks[j].x, rocks[i].z - rocks[j].z).length()
			if dist < MIN_ROCK_SPACING - 0.001:
				printerr("[ERRO LVL %d] Rochas muito próximas! dist = %.2fm < 2.80m" % [lvl, dist])
				errors += 1

	var sampled: Array = vf.call("sample_all_tufts") as Array
	var water_tufts: int = 0
	for item: Variant in sampled:
		var td: Dictionary = item as Dictionary
		var pos: Vector3 = td["pos"] as Vector3
		var gc: Vector2i = LevelJsonLoader.world_to_grid(pos, width, height, CELL_SIZE)
		if not terrain_grid.has(gc):
			water_tufts += 1
	if water_tufts > 0:
		printerr("[ERRO LVL %d] %d tufos caindo na água!" % [lvl, water_tufts])
		errors += 1

	var wheat_cnt: int = 0
	var flower_cnt: int = 0
	for ck: Variant in object_grid.keys():
		var ot: String = String((object_grid[ck] as Dictionary).get("type", ""))
		if ot == "wheat":
			wheat_cnt += 1
		elif ot.begins_with("flower"):
			flower_cnt += 1

	var t_est_nv1: float = 20.0 + 0.015 * float(sampled.size()) + 1.0 * float(wheat_cnt) + 1.5 * float(flower_cnt) + 1.0 * float(rocks.size())
	var calibrated_time: float = clampf(ceilf((t_est_nv1 * 1.5) / 5.0) * 5.0, base_time, 210.0)

	print("Nível %02d OK: '%s' | Grid %dx%d | Terreno: %d | Tempo: %.0fs | Grama: %d | Trigo: %d | Flores: %d | Rochas: %d" % [
		lvl, lvl_name, width, height, terrain_grid.size(), calibrated_time, sampled.size(), wheat_cnt, flower_cnt, rocks.size()
	])
	return {
		"errors": errors,
		"time_limit": calibrated_time
	}


# --- Geradores de Ilhas Geométricas ---
func _add_rect_island(grid: Dictionary, x0: int, z0: int, w: int, h: int) -> void:
	for x: int in range(x0, x0 + w):
		for z: int in range(z0, z0 + h):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_chamfered_rect_island(grid: Dictionary, x0: int, z0: int, w: int, h: int, chamfer: int) -> void:
	for x: int in range(x0, x0 + w):
		for z: int in range(z0, z0 + h):
			var dx: int = mini(x - x0, (x0 + w - 1) - x)
			var dz: int = mini(z - z0, (z0 + h - 1) - z)
			if dx + dz >= chamfer:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_octagon_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void:
	for x: int in range(cx - radius, cx + radius + 1):
		for z: int in range(cz - radius, cz + radius + 1):
			var dx: int = absi(x - cx)
			var dz: int = absi(z - cz)
			if dx <= radius and dz <= radius and (dx + dz) <= radius + 3:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_rounded_cross_island(grid: Dictionary, cx: int, cz: int, arm_len: int, arm_w: int) -> void:
	var hw: int = int(arm_w / 2.0)
	for x: int in range(cx - arm_len, cx + arm_len + 1):
		for z: int in range(cz - hw, cz + hw + 1):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for z: int in range(cz - arm_len, cz + arm_len + 1):
		for x: int in range(cx - hw, cx + hw + 1):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	var inner_r: int = hw + 1
	for x: int in range(cx - inner_r, cx + inner_r + 1):
		for z: int in range(cz - inner_r, cz + inner_r + 1):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_diamond_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void:
	for x: int in range(cx - radius, cx + radius + 1):
		for z: int in range(cz - radius, cz + radius + 1):
			var dx: int = absi(x - cx)
			var dz: int = absi(z - cz)
			if dx + dz <= radius:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_star_island(grid: Dictionary, cx: int, cz: int, outer_r: int, inner_r: int) -> void:
	_add_octagon_island(grid, cx, cz, outer_r)
	_add_rect_island(grid, cx - inner_r, cz - inner_r, inner_r * 2 + 1, inner_r * 2 + 1)

func _add_clover_island(grid: Dictionary, cx: int, cz: int) -> void:
	_add_rect_island(grid, cx - 6, cz - 6, 13, 13)
	_add_rect_island(grid, cx - 4, cz - 10, 9, 5)
	_add_rect_island(grid, cx - 4, cz + 6, 9, 5)
	_add_rect_island(grid, cx - 10, cz - 4, 5, 9)
	_add_rect_island(grid, cx + 6, cz - 4, 5, 9)


# --- Helpers de Vegetação Vetorial ---
func _add_grass_circle(vf: RefCounted, type_name: String, gx: int, gz: int, width: int, height: int, radius: float) -> void:
	var center3: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, CELL_SIZE)
	_add_grass_circle_world(vf, type_name, Vector2(center3.x, center3.z), radius)

func _add_grass_circle_world(vf: RefCounted, type_name: String, center: Vector2, radius: float) -> void:
	var poly: PackedVector2Array = PackedVector2Array()
	var segs: int = 24
	for i: int in range(segs):
		var a: float = float(i) * TAU / float(segs)
		poly.append(center + Vector2(cos(a), sin(a)) * radius)
	vf.call("merge_or_add_shape", type_name, poly)

func _add_grass_ring(vf: RefCounted, type_name: String, gx: int, gz: int, width: int, height: int, r_in: float, r_out: float) -> void:
	var center3: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, CELL_SIZE)
	var center: Vector2 = Vector2(center3.x, center3.z)
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	var segs: int = 24
	for i: int in range(segs):
		var a: float = float(i) * TAU / float(segs)
		outer.append(center + Vector2(cos(a), sin(a)) * r_out)
		inner.append(center + Vector2(cos(a), sin(a)) * r_in)
	var clipped: Array[PackedVector2Array] = Geometry2D.clip_polygons(outer, inner)
	for part: PackedVector2Array in clipped:
		vf.call("merge_or_add_shape", type_name, part)

func _add_grass_rect(vf: RefCounted, type_name: String, gx0: int, gz0: int, gx1: int, gz1: int, width: int, height: int) -> void:
	var p0: Vector3 = LevelJsonLoader.grid_to_world(gx0, gz0, width, height, CELL_SIZE)
	var p1: Vector3 = LevelJsonLoader.grid_to_world(gx1, gz1, width, height, CELL_SIZE)
	var min_x: float = minf(p0.x, p1.x) - CELL_SIZE * 0.4
	var max_x: float = maxf(p0.x, p1.x) + CELL_SIZE * 0.4
	var min_z: float = minf(p0.z, p1.z) - CELL_SIZE * 0.4
	var max_z: float = maxf(p0.z, p1.z) + CELL_SIZE * 0.4
	var poly: PackedVector2Array = PackedVector2Array([
		Vector2(min_x, min_z),
		Vector2(max_x, min_z),
		Vector2(max_x, max_z),
		Vector2(min_x, max_z)
	])
	vf.call("merge_or_add_shape", type_name, poly)

func _add_diagonal_stripes(vf: RefCounted, width: int, height: int, types: Array[String], stripe_w: float) -> void:
	var max_extent: float = float(mini(width, height) - 4) * CELL_SIZE * 0.5
	var island_rect: PackedVector2Array = PackedVector2Array([
		Vector2(-max_extent, -max_extent),
		Vector2(max_extent, -max_extent),
		Vector2(max_extent, max_extent),
		Vector2(-max_extent, max_extent)
	])
	var num_types: int = types.size()
	var d_max: float = max_extent * 2.82
	var d: float = -d_max
	var idx: int = 0
	while d < d_max:
		var n: Vector2 = Vector2(0.7071, 0.7071)
		var perp: Vector2 = Vector2(-0.7071, 0.7071)
		var p_mid: Vector2 = n * d
		var l: float = d_max * 1.5
		var poly: PackedVector2Array = PackedVector2Array([
			p_mid - perp * l,
			p_mid + perp * l,
			(p_mid + n * stripe_w) + perp * l,
			(p_mid + n * stripe_w) - perp * l
		])
		var inter: Array[PackedVector2Array] = Geometry2D.intersect_polygons(poly, island_rect)
		for part: PackedVector2Array in inter:
			if not Geometry2D.is_polygon_clockwise(part) and part.size() >= 3:
				vf.call("merge_or_add_shape", types[idx % num_types], part)
		d += stripe_w
		idx += 1

func _add_grass_diamond_world(vf: RefCounted, type_name: String, center: Vector2, radius: float) -> void:
	var poly: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -radius),
		center + Vector2(radius, 0.0),
		center + Vector2(0.0, radius),
		center + Vector2(-radius, 0.0)
	])
	vf.call("merge_or_add_shape", type_name, poly)

func _add_grass_star_world(vf: RefCounted, type_name: String, center: Vector2, r_out: float, r_in: float, points: int) -> void:
	var poly: PackedVector2Array = PackedVector2Array()
	var total_pts: int = points * 2
	for i: int in range(total_pts):
		var a: float = float(i) * TAU / float(total_pts) - PI * 0.5
		var r: float = r_out if (i % 2 == 0) else r_in
		poly.append(center + Vector2(cos(a), sin(a)) * r)
	vf.call("merge_or_add_shape", type_name, poly)
