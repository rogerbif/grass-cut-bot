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
	print("=== INICIANDO GERAÇÃO E AUDITORIA DAS 40 FASES CANÔNICAS (MUNDO 1: ILHAS TROPICAIS) ===")
	var total_errors: int = 0
	for lvl: int in range(1, 41):
		var errs: int = generate_level(lvl)
		total_errors += errs
	if total_errors == 0:
		print("=== SUCESSO ABSOLUTO: TODAS AS 40 FASES GERADAS E AUDITADAS COM 0 ERROS! ===")
	else:
		printerr("=== AUDITORIA: %d ERROS ENCONTRADOS NAS FASES ===" % total_errors)
	quit(1 if total_errors > 0 else 0)


func generate_level(lvl: int) -> int:
	var terrain_grid: Dictionary = {}
	var object_grid: Dictionary = {}
	var vector_field: RefCounted = VectorGrassFieldScript.new()
	var spawn_cell: Vector2i = Vector2i.ZERO
	var width: int = 15
	var height: int = 15
	var base_time_limit: float = 75.0
	var level_name: String = ""

	match lvl:
		# -------------------------------------------------------------
		# TIER 1: O DESPERTAR DO CORTADOR (FASES 01 A 10)
		# -------------------------------------------------------------
		1:
			level_name = "Primeiros Passos"
			width = 11; height = 11; base_time_limit = 65.0
			spawn_cell = Vector2i(5, 5)
			_add_rect_island(terrain_grid, 3, 3, 5, 5) # 25 tiles
			_add_grass_rect(vector_field, "grass_green", 3, 3, 7, 7, width, height)
		2:
			level_name = "O Prado Dourado"
			width = 13; height = 13; base_time_limit = 75.0
			spawn_cell = Vector2i(6, 6)
			_add_chamfered_rect_island(terrain_grid, 3, 3, 7, 7, 2) # ~33 tiles
			_add_diagonal_stripes(vector_field, width, height, ["grass_green", "grass_yellow"], 1.40)
		3:
			level_name = "O Primeiro Trigal"
			width = 13; height = 13; base_time_limit = 80.0
			spawn_cell = Vector2i(6, 6)
			_add_rect_island(terrain_grid, 3, 3, 7, 7) # ~37 tiles
			_add_dirt_cross(terrain_grid, 6, 6, 4, 4, 5, 5)
			_add_grass_circle(vector_field, "grass_yellow", 6, 6, width, height, 2.8)
			_add_grass_rect(vector_field, "grass_green", 3, 3, 5, 5, width, height)
			_add_grass_rect(vector_field, "grass_green", 7, 3, 9, 5, width, height)
			_add_grass_rect(vector_field, "grass_green", 3, 7, 5, 9, width, height)
			_add_grass_rect(vector_field, "grass_green", 7, 7, 9, 9, width, height)
			# 4 trigos em quadrantes (0 rochas)
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(6, 4))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(6, 8))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(4, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(8, 6))
		4:
			level_name = "O Canteiro de Margaridas"
			width = 13; height = 13; base_time_limit = 85.0
			spawn_cell = Vector2i(6, 4)
			_add_octagon_island(terrain_grid, 6, 6, 4) # ~45 tiles
			_add_grass_circle(vector_field, "grass_green", 6, 6, width, height, 3.0)
			_add_grass_ring(vector_field, "grass_yellow", 6, 6, width, height, 1.8, 3.0)
			# 1ª ROCHA DO JOGO
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 8))
			# Estreia de flower_daisy
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 6), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(8, 6), "flower_daisy")
		5:
			level_name = "A Enseada dos Sinos"
			width = 15; height = 15; base_time_limit = 90.0
			spawn_cell = Vector2i(7, 10)
			_add_u_island_compact(terrain_grid, 3, 3, 9, 9) # ~49 tiles
			_add_grass_rect(vector_field, "grass_blue", 3, 9, 11, 11, width, height)
			_add_grass_rect(vector_field, "grass_green", 3, 3, 6, 8, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 8, 3, 11, 8, width, height)
			# 2 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 7))
			# Trigo e estreia de flower_bell
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(4, 10))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(10, 10))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 4), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(10, 4), "flower_bell")
		6:
			level_name = "O Jardim das Rosas"
			width = 17; height = 11; base_time_limit = 90.0
			spawn_cell = Vector2i(8, 5)
			_add_rect_island(terrain_grid, 2, 2, 13, 7) # ~55 tiles
			_add_grass_rect(vector_field, "grass_green", 3, 3, 13, 7, width, height)
			_add_grass_rect(vector_field, "grass_red", 6, 4, 10, 6, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 5))
			# Estreia de flower_rose
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 3), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 7), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 3), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 7), "flower_rose")
		7:
			level_name = "Colina dos Girassóis"
			width = 15; height = 15; base_time_limit = 95.0
			spawn_cell = Vector2i(7, 7)
			_add_octagon_island(terrain_grid, 7, 7, 5) # ~55 tiles
			_add_grass_circle(vector_field, "grass_yellow", 7, 7, width, height, 3.6)
			_add_grass_ring(vector_field, "grass_green", 7, 7, width, height, 1.8, 3.6)
			# 3 rochas triangulares
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 3))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 10))
			# Trigo e estreia de flower_sunflower
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(5, 5))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(9, 5))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(7, 11), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(3, 7), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 7), "flower_sunflower")
		8:
			level_name = "Brisa das Tulipas"
			width = 19; height = 13; base_time_limit = 100.0
			spawn_cell = Vector2i(5, 6)
			_add_bridge_island_compact(terrain_grid, 2, 2, 6, 9, 3, 5) # ~58 tiles
			_add_grass_rect(vector_field, "grass_blue", 2, 2, 7, 10, width, height)
			_add_grass_rect(vector_field, "grass_green", 11, 2, 16, 10, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 3))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(9, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 9))
			# Estreia de flower_tulip e margaridas
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(13, 4), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(14, 6), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 8), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(6, 8), "flower_daisy")
		9:
			level_name = "Círculo das Corolas"
			width = 17; height = 17; base_time_limit = 100.0
			spawn_cell = Vector2i(8, 8)
			_add_octagon_island(terrain_grid, 8, 8, 5) # ~60 tiles
			_add_grass_star_world(vector_field, "grass_purple", Vector2.ZERO, 3.8, 1.8, 6)
			_add_grass_circle(vector_field, "grass_white", 8, 8, width, height, 1.5)
			# 3 rochas
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 11))
			# Trigo e estreia de flower_corolla
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(8, 5))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(8, 11))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 5), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 5), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(8, 12), "flower_corolla")
		10:
			level_name = "O Parque de Canteiros"
			width = 17; height = 17; base_time_limit = 105.0
			spawn_cell = Vector2i(8, 8)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 13, 13, 3) # ~62 tiles
			_add_dirt_cross(terrain_grid, 8, 8, 4, 4, 9, 9)
			_add_grass_rect(vector_field, "grass_green", 4, 4, 12, 12, width, height)
			_add_grass_circle(vector_field, "grass_yellow", 8, 8, width, height, 2.2)
			# 4 rochas cardeais
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 8))
			# Estreia de flower_bed (canteiro) e rosas
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 5), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 5), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 11), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 11), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(8, 6), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(8, 10), "flower_rose")

		# -------------------------------------------------------------
		# TIER 2: ISTMOS, PONTES E NAVEGAÇÃO TÁTICA (FASES 11 A 20)
		# -------------------------------------------------------------
		11:
			level_name = "As Ilhas Gêmeas"
			width = 21; height = 15; base_time_limit = 105.0
			spawn_cell = Vector2i(5, 7)
			_add_bridge_island(terrain_grid) # ~64 tiles
			_add_grass_rect(vector_field, "grass_blue", 2, 2, 8, 12, width, height)
			_add_grass_rect(vector_field, "grass_green", 12, 2, 18, 12, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 8, 5, 12, 9, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 3))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 7))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 10), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(7, 4), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(14, 4), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(16, 10), "flower_bell")
		12:
			level_name = "Serpente de Trigo"
			width = 21; height = 15; base_time_limit = 110.0
			spawn_cell = Vector2i(5, 7)
			_add_s_island(terrain_grid, 2, 2, 17, 11) # ~66 tiles
			_add_grass_rect(vector_field, "grass_green", 2, 2, 18, 12, width, height)
			_add_grass_circle_world(vector_field, "grass_yellow", Vector2(1.5, 0.0), 2.2)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 4))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(10, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(12, 6))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 4), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(16, 10), "flower_rose")
		13:
			level_name = "O Relógio de Granito"
			width = 19; height = 19; base_time_limit = 110.0
			spawn_cell = Vector2i(9, 9)
			_add_rounded_cross_island(terrain_grid, 9, 9, 7, 5) # ~68 tiles
			_add_dirt_cross(terrain_grid, 9, 9, 4, 4, 11, 11)
			_add_grass_rect(vector_field, "grass_green", 4, 4, 8, 8, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 10, 4, 14, 8, width, height)
			_add_grass_rect(vector_field, "grass_blue", 4, 10, 8, 14, width, height)
			_add_grass_rect(vector_field, "grass_purple", 10, 10, 14, 14, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 13))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(13, 13))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(9, 4), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(9, 14), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 9), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(14, 9), "flower_tulip")
		14:
			level_name = "Baía da Ferradura"
			width = 21; height = 19; base_time_limit = 115.0
			spawn_cell = Vector2i(10, 14)
			_add_u_island(terrain_grid) # ~70 tiles
			_add_grass_rect(vector_field, "grass_green", 3, 10, 17, 15, width, height)
			_add_grass_rect(vector_field, "grass_purple", 3, 2, 7, 10, width, height)
			_add_grass_rect(vector_field, "grass_red", 13, 2, 17, 10, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 9))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 9))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 4))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(7, 12))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(13, 12))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 2), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(15, 2), "flower_corolla")
		15:
			level_name = "Cruz dos Quatro Ventos"
			width = 21; height = 21; base_time_limit = 115.0
			spawn_cell = Vector2i(10, 10)
			_add_rounded_cross_island(terrain_grid, 10, 10, 8, 5) # ~72 tiles
			_add_grass_circle(vector_field, "grass_white", 10, 10, width, height, 2.5)
			_add_grass_ring(vector_field, "grass_green", 10, 10, width, height, 2.5, 4.5)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 10))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(10, 3), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(10, 17), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(3, 10), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(17, 10), "flower_bell")
		16:
			level_name = "O Trevo Imperial"
			width = 21; height = 21; base_time_limit = 120.0
			spawn_cell = Vector2i(10, 10)
			_add_clover_island(terrain_grid, 10, 10) # ~74 tiles
			_add_grass_circle(vector_field, "grass_yellow", 10, 10, width, height, 2.8)
			_add_grass_ring(vector_field, "grass_green", 10, 10, width, height, 2.8, 4.8)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(8, 10))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(12, 10))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(10, 4), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(10, 16), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 10), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(16, 10), "flower_tulip")
		17:
			level_name = "Canal das Margaridas"
			width = 21; height = 17; base_time_limit = 120.0
			spawn_cell = Vector2i(5, 8)
			_add_canal_island(terrain_grid, 2, 2, 17, 13) # ~76 tiles
			_add_grass_rect(vector_field, "grass_green", 2, 2, 18, 14, width, height)
			_add_grass_circle_world(vector_field, "grass_yellow", Vector2(0.0, 0.0), 2.5)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 4))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(8, 4), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(8, 12), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 12), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(16, 8), "flower_bed")
		18:
			level_name = "Labirinto Solar"
			width = 21; height = 21; base_time_limit = 125.0
			spawn_cell = Vector2i(10, 10)
			_add_rect_island(terrain_grid, 2, 2, 17, 17) # ~78 tiles
			_add_grass_circle(vector_field, "grass_yellow", 10, 10, width, height, 4.2)
			_add_grass_rect(vector_field, "grass_green", 6, 6, 14, 14, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 15))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(7, 5))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(13, 5))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 10), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(15, 10), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(10, 4), "flower_sunflower")
		19:
			level_name = "Península Vulcânica"
			width = 21; height = 21; base_time_limit = 125.0
			spawn_cell = Vector2i(10, 10)
			_add_octagon_island(terrain_grid, 10, 10, 7) # ~80 tiles
			_add_grass_circle(vector_field, "grass_black", 10, 10, width, height, 4.5)
			_add_grass_star_world(vector_field, "grass_red", Vector2.ZERO, 4.0, 2.0, 8)
			_add_grass_circle(vector_field, "grass_yellow", 10, 10, width, height, 1.6)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 10))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 14))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(6, 14), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(14, 6), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(10, 4), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(10, 16), "flower_rose")
		20:
			level_name = "O Primeiro Grande Atol"
			width = 23; height = 23; base_time_limit = 130.0
			spawn_cell = Vector2i(11, 5)
			_add_ring_island(terrain_grid, 11, 11, 8, 3) # ~82 tiles
			_add_grass_ring(vector_field, "grass_blue", 11, 11, width, height, 3.2, 5.5)
			_add_grass_ring(vector_field, "grass_green", 11, 11, width, height, 3.2, 4.2)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 15))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(9, 5))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(13, 5))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(6, 12), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(16, 12), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 18), "flower_bell")

		# -------------------------------------------------------------
		# TIER 3: O GRANDE ARQUIPÉLAGO E LABIRINTOS (FASES 21 A 30)
		# -------------------------------------------------------------
		21:
			level_name = "Três Marias"
			width = 25; height = 15; base_time_limit = 130.0
			spawn_cell = Vector2i(5, 7)
			_add_triple_island(terrain_grid) # ~84 tiles
			_add_grass_rect(vector_field, "grass_blue", 2, 2, 8, 12, width, height)
			_add_grass_rect(vector_field, "grass_green", 9, 2, 15, 12, width, height)
			_add_grass_rect(vector_field, "grass_purple", 16, 2, 22, 12, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 10))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(12, 8))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(12, 10))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 10), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(19, 7), "flower_bell")
		22:
			level_name = "Boulevard de Outono"
			width = 23; height = 19; base_time_limit = 135.0
			spawn_cell = Vector2i(11, 9)
			_add_h_island(terrain_grid) # ~85 tiles
			_add_grass_rect(vector_field, "grass_green", 3, 2, 8, 16, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 8, 6, 14, 12, width, height)
			_add_grass_rect(vector_field, "grass_green", 14, 2, 19, 16, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 14))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 4))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 14))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 10))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(6, 12), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(16, 6), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(16, 12), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 7), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 11), "flower_bed")
		23:
			level_name = "A Fortaleza de Trigo"
			width = 23; height = 21; base_time_limit = 140.0
			spawn_cell = Vector2i(11, 10)
			_add_rect_island(terrain_grid, 2, 2, 19, 17) # ~86 tiles
			_add_grass_circle(vector_field, "grass_yellow", 11, 10, width, height, 5.2)
			_add_grass_rect(vector_field, "grass_green", 7, 6, 15, 14, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 10))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(8, 5))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(14, 5))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(8, 10), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(14, 10), "flower_sunflower")
		24:
			level_name = "Ilha do Zigue-Zague"
			width = 23; height = 17; base_time_limit = 140.0
			spawn_cell = Vector2i(4, 8)
			_add_slalom_island(terrain_grid, 2, 2, 19, 13) # ~87 tiles
			_add_grass_rect(vector_field, "grass_purple", 2, 2, 20, 14, width, height)
			_add_grass_star_world(vector_field, "grass_white", Vector2.ZERO, 4.2, 2.0, 6)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 9))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 9))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 5), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 5), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(17, 5), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(18, 7), "flower_corolla")
		25:
			level_name = "O Vale das Quatro Flores"
			width = 23; height = 23; base_time_limit = 145.0
			spawn_cell = Vector2i(11, 11)
			_add_clover_island(terrain_grid, 11, 11) # ~88 tiles
			_add_grass_rect(vector_field, "grass_green", 7, 3, 15, 9, width, height)
			_add_grass_rect(vector_field, "grass_blue", 7, 13, 15, 19, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 3, 7, 9, 15, width, height)
			_add_grass_rect(vector_field, "grass_purple", 13, 7, 19, 15, width, height)
			_add_grass_circle(vector_field, "grass_white", 11, 11, width, height, 2.8)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 16))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 4), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 18), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 11), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(18, 11), "flower_sunflower")
		26:
			level_name = "O Grande Diamante"
			width = 23; height = 23; base_time_limit = 145.0
			spawn_cell = Vector2i(11, 11)
			_add_diamond_island(terrain_grid, 11, 11, 9) # ~89 tiles
			_add_grass_diamond_world(vector_field, "grass_purple", Vector2.ZERO, 6.0)
			_add_grass_diamond_world(vector_field, "grass_white", Vector2.ZERO, 3.2)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 15))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(9, 9))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(13, 9))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 3), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 19), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(3, 11), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(19, 11), "flower_bed")
		27:
			level_name = "Arquipélago do Sol"
			width = 25; height = 25; base_time_limit = 150.0
			spawn_cell = Vector2i(12, 12)
			_add_sun_archipelago(terrain_grid, 12, 12) # ~90 tiles
			_add_grass_circle(vector_field, "grass_yellow", 12, 12, width, height, 5.0)
			_add_grass_star_world(vector_field, "grass_green", Vector2.ZERO, 5.5, 3.2, 8)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 16))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(10, 10))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(14, 10))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 20), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 12), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(20, 12), "flower_tulip")
		28:
			level_name = "Caminhos Cruzados"
			width = 23; height = 23; base_time_limit = 150.0
			spawn_cell = Vector2i(11, 11)
			_add_grid_cross_island(terrain_grid, 11, 11) # ~91 tiles
			_add_grass_rect(vector_field, "grass_green", 3, 3, 19, 19, width, height)
			_add_grass_circle(vector_field, "grass_yellow", 11, 11, width, height, 3.6)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 11))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(9, 9), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(13, 9), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(9, 13), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(13, 13), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 4), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 18), "flower_bed")
		29:
			level_name = "O Santuário Esmeralda"
			width = 23; height = 23; base_time_limit = 155.0
			spawn_cell = Vector2i(11, 11)
			_add_octagon_island(terrain_grid, 11, 11, 8) # ~92 tiles
			_add_grass_circle(vector_field, "grass_green", 11, 11, width, height, 5.5)
			_add_grass_ring(vector_field, "grass_white", 11, 11, width, height, 3.2, 4.5)
			_add_grass_circle(vector_field, "grass_yellow", 11, 11, width, height, 2.0)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(11, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 15))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(9, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(13, 6))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 3), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(11, 19), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(3, 11), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(19, 11), "flower_corolla")
		30:
			level_name = "A Cidadela Costeira"
			width = 25; height = 23; base_time_limit = 155.0
			spawn_cell = Vector2i(12, 11)
			_add_citadel_island(terrain_grid, 12, 11) # ~93 tiles
			_add_grass_rect(vector_field, "grass_green", 3, 3, 21, 19, width, height)
			_add_grass_star_world(vector_field, "grass_yellow", Vector2.ZERO, 5.0, 2.8, 8)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 14))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 14))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(9, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(10, 8))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(14, 8))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 18), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 11), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(20, 11), "flower_sunflower")

		# -------------------------------------------------------------
		# TIER 4: AS MEGA-ILHAS E A MAESTRIA SUPREMA (FASES 31 A 40)
		# -------------------------------------------------------------
		31:
			level_name = "O Labirinto de Minos"
			width = 25; height = 23; base_time_limit = 160.0
			spawn_cell = Vector2i(12, 11)
			_add_rect_island(terrain_grid, 3, 3, 19, 17) # ~94 tiles
			_add_grass_rect(vector_field, "grass_green", 4, 4, 20, 18, width, height)
			_add_grass_circle(vector_field, "grass_yellow", 12, 11, width, height, 4.4)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 11))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(9, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(15, 6))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(9, 11), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(15, 11), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 18), "flower_bed")
		32:
			level_name = "Arquipélago em H"
			width = 25; height = 23; base_time_limit = 160.0
			spawn_cell = Vector2i(12, 11)
			_add_giant_h_island(terrain_grid, 12, 11) # ~95 tiles
			_add_grass_rect(vector_field, "grass_blue", 3, 2, 8, 20, width, height)
			_add_grass_rect(vector_field, "grass_purple", 16, 2, 21, 20, width, height)
			_add_grass_rect(vector_field, "grass_green", 8, 8, 16, 14, width, height)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(9, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 11))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(7, 8))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(17, 8))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(6, 3), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(6, 19), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(18, 3), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(18, 19), "flower_tulip")
		33:
			level_name = "O Grande Trevo Dourado"
			width = 25; height = 25; base_time_limit = 165.0
			spawn_cell = Vector2i(12, 12)
			_add_giant_clover_island(terrain_grid, 12, 12) # ~96 tiles
			_add_grass_circle(vector_field, "grass_yellow", 12, 12, width, height, 5.5)
			_add_grass_star_world(vector_field, "grass_green", Vector2.ZERO, 6.0, 3.5, 8)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 18))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 8))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 20), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 12), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(20, 12), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(8, 8), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(16, 16), "flower_corolla")
		34:
			level_name = "O Dragão dos Mares"
			width = 25; height = 23; base_time_limit = 165.0
			spawn_cell = Vector2i(6, 8)
			_add_dragon_island(terrain_grid, 12, 11) # ~97 tiles
			_add_grass_rect(vector_field, "grass_blue", 3, 3, 21, 19, width, height)
			_add_grass_star_world(vector_field, "grass_yellow", Vector2.ZERO, 5.2, 2.6, 6)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(4, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(20, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 11))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(10, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(14, 6))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(7, 6), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(17, 16), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 18), "flower_tulip")
		35:
			level_name = "O Tabuleiro dos Titãs"
			width = 25; height = 25; base_time_limit = 170.0
			spawn_cell = Vector2i(12, 12)
			_add_rect_island(terrain_grid, 3, 3, 19, 19) # ~97 tiles
			_add_grass_diamond_world(vector_field, "grass_green", Vector2.ZERO, 6.5)
			_add_grass_diamond_world(vector_field, "grass_yellow", Vector2.ZERO, 4.0)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 18))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 8))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(9, 7))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(15, 7))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 20), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 12), "flower_daisy")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(20, 12), "flower_bell")
		36:
			level_name = "Oásis dos Cinco Reinos"
			width = 25; height = 25; base_time_limit = 170.0
			spawn_cell = Vector2i(12, 12)
			_add_star_island(terrain_grid, 12, 12, 9, 6) # ~98 tiles
			_add_grass_star_world(vector_field, "grass_black", Vector2.ZERO, 6.2, 4.5, 8)
			_add_grass_star_world(vector_field, "grass_purple", Vector2.ZERO, 4.8, 3.2, 8)
			_add_grass_star_world(vector_field, "grass_blue", Vector2.ZERO, 3.5, 2.0, 8)
			_add_grass_circle(vector_field, "grass_green", 12, 12, width, height, 1.6)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 5))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 19))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 16))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 3), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 21), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(3, 12), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(21, 12), "flower_corolla")
		37:
			level_name = "O Grande Atol Imperial"
			width = 25; height = 25; base_time_limit = 170.0
			spawn_cell = Vector2i(12, 6)
			_add_ring_island(terrain_grid, 12, 12, 9, 3) # ~98 tiles
			_add_grass_ring(vector_field, "grass_blue", 12, 12, width, height, 3.5, 6.5)
			_add_grass_ring(vector_field, "grass_green", 12, 12, width, height, 3.5, 4.8)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 19))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 3))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 21))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(3, 12))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(9, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(15, 6))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(6, 12), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(18, 12), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 17), "flower_bell")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 9), "flower_bell")
		38:
			level_name = "Constelação de Pedra"
			width = 25; height = 25; base_time_limit = 175.0
			spawn_cell = Vector2i(12, 12)
			_add_octagon_island(terrain_grid, 12, 12, 9) # ~99 tiles
			_add_grass_circle(vector_field, "grass_green", 12, 12, width, height, 6.2)
			_add_grass_star_world(vector_field, "grass_yellow", Vector2.ZERO, 5.5, 3.2, 8)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 6))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 18))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(6, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(18, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 16))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(9, 6))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(15, 6))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 4), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 20), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(4, 12), "flower_corolla")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(20, 12), "flower_corolla")
		39:
			level_name = "A Península do Infinito"
			width = 25; height = 23; base_time_limit = 175.0
			spawn_cell = Vector2i(12, 11)
			_add_infinity_island(terrain_grid, 12, 11) # ~99 tiles
			_add_grass_circle_world(vector_field, "grass_purple", Vector2(-2.8, 0.0), 3.4)
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(2.8, 0.0), 3.4)
			_add_grass_circle(vector_field, "grass_green", 12, 11, width, height, 2.0)
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 15))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(5, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(19, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(9, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(15, 11))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 15))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(6, 9))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(18, 9))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 7), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(19, 7), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 15), "flower_bed")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(19, 15), "flower_bed")
		40:
			level_name = "A Grande Coroa Real"
			width = 25; height = 23; base_time_limit = 180.0
			spawn_cell = Vector2i(12, 12)
			_add_royal_crown_island(terrain_grid, 12, 12) # EXATAMENTE 100 TILES!
			_add_grass_circle(vector_field, "grass_yellow", 12, 12, width, height, 5.8)
			_add_grass_star_world(vector_field, "grass_green", Vector2.ZERO, 5.5, 3.2, 8)
			_add_grass_diamond_world(vector_field, "grass_white", Vector2.ZERO, 2.5)
			# 10 rochas perimetrais com folga segura
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 7))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(12, 17))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(7, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(17, 12))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 8))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(8, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(16, 16))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(10, 9))
			_add_valid_rock(terrain_grid, object_grid, spawn_cell, Vector2i(14, 15))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(10, 7))
			_add_valid_wheat(terrain_grid, object_grid, spawn_cell, Vector2i(14, 7))
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 5), "flower_rose")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(12, 19), "flower_sunflower")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(5, 12), "flower_tulip")
			_add_valid_flower(terrain_grid, object_grid, spawn_cell, Vector2i(19, 12), "flower_corolla")

	# 1. Aplica Autotile nas células da ilha
	IslandAutotiler.apply_autotile(terrain_grid)

	# 2. Recorta todos os polígonos de grama estritamente para a área plana interna da ilha
	#    e abre clareira exata no ponto de spawn para evitar auto-corte no frame 0
	_clip_vector_field_to_island(vector_field, terrain_grid, spawn_cell, width, height)

	# 3. Validações estritas de Level Design e Física + Calibração de Tempo
	var audit_res: Dictionary = _validate_and_calibrate_level(
		lvl, level_name, base_time_limit, spawn_cell, terrain_grid, object_grid, vector_field, width, height
	)
	var err_count: int = int(audit_res.get("errors", 0))
	var calibrated_time: float = float(audit_res.get("time_limit", base_time_limit))

	# 4. Constrói metas customizadas no formato canônico unificado (Grama Unificada + Flores/Trigo)
	var custom_goals: Dictionary = {}
	var sampled: Array = vector_field.call("sample_all_tufts") as Array
	var grass_units: int = maxi(1, int(ceilf(float(sampled.size()) / 6.0)))
	custom_goals["grass"] = grass_units

	var wheat_cnt: int = 0
	var flower_counts: Dictionary = {}
	for ck: Variant in object_grid.keys():
		var ot: String = String((object_grid[ck] as Dictionary).get("type", ""))
		if ot == "wheat":
			wheat_cnt += 1
		elif ot.begins_with("flower"):
			flower_counts[ot] = int(flower_counts.get(ot, 0)) + 1

	if wheat_cnt > 0:
		custom_goals["wheat"] = wheat_cnt
	for fk: String in flower_counts.keys():
		custom_goals[fk] = flower_counts[fk]

	# Validação de teto: máximo 6 objetivos no HUD
	if custom_goals.size() > 6:
		printerr("[ERRO LVL %d] Mais de 6 metas no HUD! (%d metas)" % [lvl, custom_goals.size()])
		err_count += 1

	# 5. Salva o arquivo JSON v4
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
			var edge_inset: float = 0.06 # 0.34m de recuo da falésia costeira

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


# --- Métodos de Validação Estrita (6 Regras de Level Design) ---
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
				printerr("[ERRO LVL %d] Spawn %s muito próximo da borda costeira!" % [lvl, str(spawn_cell)])
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

		# Regra 2: Rochas proibidas nas Fases 1 a 3
		if lvl <= 3 and o_type == "rock":
			printerr("[ERRO LVL %d] Rocha proibida em fases <= 3!" % lvl)
			errors += 1

		# Regra 3: Todo objeto deve estar sobre tile interno
		if not terrain_grid.has(cell):
			printerr("[ERRO LVL %d] Objeto '%s' em %s está na água!" % [lvl, o_type, str(cell)])
			errors += 1
		else:
			var cardinals: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for dir: Vector2i in cardinals:
				if not terrain_grid.has(cell + dir):
					printerr("[ERRO LVL %d] Objeto '%s' em %s na borda da falésia!" % [lvl, o_type, str(cell)])
					errors += 1
					break

		# Regra 4: Rochas precisam de 8 vizinhos (folga anti-estrangulamento)
		if o_type == "rock":
			rocks.append(o_pos)
			for dx: int in range(-1, 2):
				for dz: int in range(-1, 2):
					if not terrain_grid.has(cell + Vector2i(dx, dz)):
						printerr("[ERRO LVL %d] Rocha em %s sem folga diagonal da costa!" % [lvl, str(cell)])
						errors += 1

	# Regra 5: Distância entre rochas > 2.80m
	for i: int in range(rocks.size()):
		for j: int in range(i + 1, rocks.size()):
			var dist: float = Vector2(rocks[i].x - rocks[j].x, rocks[i].z - rocks[j].z).length()
			if dist < MIN_ROCK_SPACING - 0.001:
				printerr("[ERRO LVL %d] Rochas muito próximas! dist = %.2fm < 2.80m" % [lvl, dist])
				errors += 1

	var sampled: Array = vf.call("sample_all_tufts") as Array
	var wheat_cnt: int = 0
	var flower_cnt: int = 0
	for ck: Variant in object_grid.keys():
		var ot: String = String((object_grid[ck] as Dictionary).get("type", ""))
		if ot == "wheat":
			wheat_cnt += 1
		elif ot.begins_with("flower"):
			flower_cnt += 1

	var t_est: float = 14.0 + 0.032 * float(sampled.size()) + 1.25 * float(wheat_cnt) + 2.25 * float(flower_cnt) + 1.5 * float(rocks.size())
	var calibrated_time: float = maxf(base_time, ceilf((t_est * 2.25) / 5.0) * 5.0)

	print("Nível %02d OK: '%s' | Tiles: %d | Tempo: %.0fs | Grama: %d | Trigo: %d | Flores: %d | Rochas: %d" % [
		lvl, lvl_name, terrain_grid.size(), calibrated_time, sampled.size(), wheat_cnt, flower_cnt, rocks.size()
	])
	return {
		"errors": errors,
		"time_limit": calibrated_time
	}


# --- Geradores Geométricos de Ilhas ---
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

func _add_u_island_compact(grid: Dictionary, x0: int, z0: int, w: int, h: int) -> void:
	for x: int in range(x0, x0 + w):
		for z: int in range(z0 + h - 4, z0 + h):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(x0, x0 + 4):
		for z: int in range(z0, z0 + h):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(x0 + w - 4, x0 + w):
		for z: int in range(z0, z0 + h):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_u_island(grid: Dictionary) -> void:
	for x: int in range(2, 19):
		for z: int in range(9, 16):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(2, 8):
		for z: int in range(2, 12):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(13, 19):
		for z: int in range(2, 12):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_bridge_island_compact(grid: Dictionary, x0: int, z0: int, w1: int, h1: int, bridge_len: int, bridge_w: int) -> void:
	for x: int in range(x0, x0 + w1):
		for z: int in range(z0, z0 + h1):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	var x2: int = x0 + w1 + bridge_len - 1
	for x: int in range(x2, x2 + w1):
		for z: int in range(z0, z0 + h1):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	var b_z0: int = z0 + int((h1 - bridge_w) / 2.0)
	for x: int in range(x0 + w1 - 1, x2 + 1):
		for z: int in range(b_z0, b_z0 + bridge_w):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_bridge_island(grid: Dictionary) -> void:
	for x: int in range(2, 9):
		for z: int in range(2, 13):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(12, 19):
		for z: int in range(2, 13):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(8, 13):
		for z: int in range(4, 11):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_s_island(grid: Dictionary, x0: int, z0: int, w: int, h: int) -> void:
	for x: int in range(x0, x0 + w):
		for z: int in range(z0, z0 + 4):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
		for z: int in range(z0 + h - 4, z0 + h):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for z: int in range(z0, z0 + int(h * 0.65)):
		for x: int in range(x0, x0 + 5):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for z: int in range(z0 + int(h * 0.35), z0 + h):
		for x: int in range(x0 + w - 5, x0 + w):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(x0 + 4, x0 + w - 4):
		for z: int in range(z0 + 3, z0 + 7):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_canal_island(grid: Dictionary, x0: int, z0: int, w: int, h: int) -> void:
	for x: int in range(x0, x0 + w):
		for z: int in range(z0, z0 + h):
			var is_canal: bool = (x >= x0 + 6 and x <= x0 + w - 7 and z >= z0 + 5 and z <= z0 + 7)
			if not is_canal:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_ring_island(grid: Dictionary, cx: int, cz: int, r_out: int, r_in: int) -> void:
	for x: int in range(cx - r_out, cx + r_out + 1):
		for z: int in range(cz - r_out, cz + r_out + 1):
			var dx: int = absi(x - cx)
			var dz: int = absi(z - cz)
			var d_max: int = maxi(dx, dz)
			if d_max <= r_out and (dx + dz) <= r_out + 4:
				if d_max > r_in:
					grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_triple_island(grid: Dictionary) -> void:
	_add_rect_island(grid, 2, 2, 7, 11)
	_add_rect_island(grid, 9, 2, 7, 11)
	_add_rect_island(grid, 16, 2, 7, 11)
	for x: int in range(7, 11):
		for z: int in range(5, 9):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(14, 18):
		for z: int in range(5, 9):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_h_island(grid: Dictionary) -> void:
	for x: int in range(2, 9):
		for z: int in range(2, 17):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(14, 21):
		for z: int in range(2, 17):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for x: int in range(8, 15):
		for z: int in range(6, 13):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_slalom_island(grid: Dictionary, x0: int, z0: int, w: int, h: int) -> void:
	for x: int in range(x0, x0 + w):
		for z: int in range(z0, z0 + h):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_clover_island(grid: Dictionary, cx: int, cz: int) -> void:
	_add_rect_island(grid, cx - 6, cz - 6, 13, 13)
	_add_rect_island(grid, cx - 4, cz - 9, 9, 4)
	_add_rect_island(grid, cx - 4, cz + 6, 9, 4)
	_add_rect_island(grid, cx - 9, cz - 4, 4, 9)
	_add_rect_island(grid, cx + 6, cz - 4, 4, 9)

func _add_diamond_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void:
	for x: int in range(cx - radius, cx + radius + 1):
		for z: int in range(cz - radius, cz + radius + 1):
			var dx: int = absi(x - cx)
			var dz: int = absi(z - cz)
			if dx + dz <= radius:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_sun_archipelago(grid: Dictionary, cx: int, cz: int) -> void:
	_add_octagon_island(grid, cx, cz, 6)
	_add_rect_island(grid, cx - 3, cz - 10, 7, 5)
	_add_rect_island(grid, cx - 3, cz + 6, 7, 5)
	_add_rect_island(grid, cx - 10, cz - 3, 5, 7)
	_add_rect_island(grid, cx + 6, cz - 3, 5, 7)

func _add_grid_cross_island(grid: Dictionary, cx: int, cz: int) -> void:
	_add_rect_island(grid, cx - 8, cz - 8, 17, 17)

func _add_citadel_island(grid: Dictionary, cx: int, cz: int) -> void:
	_add_rect_island(grid, cx - 9, cz - 8, 19, 17)
	_add_rect_island(grid, cx - 10, cz - 5, 4, 11)
	_add_rect_island(grid, cx + 7, cz - 5, 4, 11)

func _add_giant_h_island(grid: Dictionary, cx: int, cz: int) -> void:
	_add_rect_island(grid, cx - 9, cz - 9, 7, 19)
	_add_rect_island(grid, cx + 3, cz - 9, 7, 19)
	_add_rect_island(grid, cx - 4, cz - 4, 9, 9)

func _add_giant_clover_island(grid: Dictionary, cx: int, cz: int) -> void:
	_add_rect_island(grid, cx - 7, cz - 7, 15, 15)
	_add_rect_island(grid, cx - 5, cz - 10, 11, 4)
	_add_rect_island(grid, cx - 5, cz + 7, 11, 4)
	_add_rect_island(grid, cx - 10, cz - 5, 4, 11)
	_add_rect_island(grid, cx + 7, cz - 5, 4, 11)

func _add_dragon_island(grid: Dictionary, cx: int, cz: int) -> void:
	_add_rect_island(grid, cx - 10, cz - 8, 21, 17)

func _add_star_island(grid: Dictionary, cx: int, cz: int, outer_r: int, inner_r: int) -> void:
	_add_octagon_island(grid, cx, cz, outer_r)
	_add_rect_island(grid, cx - inner_r, cz - inner_r, inner_r * 2 + 1, inner_r * 2 + 1)

func _add_infinity_island(grid: Dictionary, cx: int, cz: int) -> void:
	_add_octagon_island(grid, cx - 5, cz, 6)
	_add_octagon_island(grid, cx + 5, cz, 6)
	_add_rect_island(grid, cx - 3, cz - 3, 7, 7)

func _add_royal_crown_island(grid: Dictionary, cx: int, cz: int) -> void:
	# 100 tiles exatos: Base central 10x8 = 80 + pontas = 20
	_add_rect_island(grid, cx - 5, cz - 3, 10, 8) # 80 tiles
	_add_rect_island(grid, cx - 5, cz - 6, 2, 3) # +6
	_add_rect_island(grid, cx - 2, cz - 6, 2, 3) # +6
	_add_rect_island(grid, cx + 1, cz - 6, 2, 3) # +6
	_add_rect_island(grid, cx + 4, cz - 6, 2, 3) # +6
	# Total = 80 + 24 = 104 tiles -> remove 4 para exatos 100 tiles
	grid.erase(Vector2i(cx - 5, cz - 3))
	grid.erase(Vector2i(cx + 4, cz - 3))
	grid.erase(Vector2i(cx - 5, cz + 4))
	grid.erase(Vector2i(cx + 4, cz + 4))

func _add_dirt_cross(grid: Dictionary, cx: int, cz: int, x0: int, z0: int, w: int, h: int) -> void:
	for x: int in range(x0, x0 + w):
		if grid.has(Vector2i(x, cz)):
			grid[Vector2i(x, cz)] = { "tile_id": "island_dirt", "rot": 0, "auto": true }
	for z: int in range(z0, z0 + h):
		if grid.has(Vector2i(cx, z)):
			grid[Vector2i(cx, z)] = { "tile_id": "island_dirt", "rot": 0, "auto": true }

func _add_dirt_tiles(grid: Dictionary, cells: Array) -> void:
	for item: Variant in cells:
		var c: Vector2i = item as Vector2i
		if grid.has(c):
			grid[c] = { "tile_id": "island_dirt", "rot": 0, "auto": true }


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

func _add_grass_diamond_world(vf: RefCounted, type_name: String, center: Vector2, half_diag: float) -> void:
	var poly: PackedVector2Array = PackedVector2Array([
		center + Vector2(0.0, -half_diag),
		center + Vector2(half_diag, 0.0),
		center + Vector2(0.0, half_diag),
		center + Vector2(-half_diag, 0.0)
	])
	vf.call("merge_or_add_shape", type_name, poly)

func _add_grass_star_world(vf: RefCounted, type_name: String, center: Vector2, r_outer: float, r_inner: float, points: int) -> void:
	var poly: PackedVector2Array = PackedVector2Array()
	var total_verts: int = points * 2
	for i: int in range(total_verts):
		var a: float = float(i) * TAU / float(total_verts) - PI * 0.5
		var r: float = r_outer if (i % 2 == 0) else r_inner
		poly.append(center + Vector2(cos(a), sin(a)) * r)
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
	var ring_parts: Array = vf.call("_clip_polygon_without_holes", outer, inner) as Array
	for part_var: Variant in ring_parts:
		var part: PackedVector2Array = part_var as PackedVector2Array
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
	var dir: Vector2 = Vector2(1.0, 1.0).normalized()
	var perp: Vector2 = Vector2(-1.0, 1.0).normalized()
	var span: float = max_extent * 2.0
	var cur: float = -span
	var idx: int = 0
	var t_count: int = types.size()
	while cur < span:
		var next_cur: float = cur + stripe_w
		var t_name: String = types[idx % t_count]
		var p_strip: PackedVector2Array = PackedVector2Array([
			dir * cur - perp * span,
			dir * next_cur - perp * span,
			dir * next_cur + perp * span,
			dir * cur + perp * span
		])
		var clipped_polys: Array = Geometry2D.intersect_polygons(island_rect, p_strip)
		for cp_var: Variant in clipped_polys:
			var cp: PackedVector2Array = cp_var as PackedVector2Array
			if cp.size() >= 3:
				vf.call("add_shape", t_name, cp)
		cur = next_cur
		idx += 1
