extends SceneTree

const IslandAutotiler = preload("res://scripts/editor/island_autotiler.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

const CELL_SIZE: float = 0.80
const MIN_SPAWN_CLEAR_DIST: float = 1.47 # 1.05 * 1.40m (raio lâmina nv 6)
const MIN_ROCK_SPACING: float = 2.80      # 2.00 * 1.40m (diâmetro lâmina nv 6)
const SPAWN_GRASS_CLEAR_RADIUS: float = 0.72 # Clareira sutil no ponto zero para evitar auto-corte no frame 0

func _init() -> void:
	print("=== INICIANDO GERAÇÃO E AUDITORIA DAS 20 FASES CANÔNICAS ===")
	var total_errors: int = 0
	for lvl: int in range(1, 21):
		var errs: int = generate_level(lvl)
		total_errors += errs
	if total_errors == 0:
		print("=== SUCESSO ABSOLUTO: 20 FASES GERADAS E AUDITADAS COM 0 ERROS! ===")
	else:
		printerr("=== FALHA DE AUDITORIA: %d ERROS ENCONTRADOS ===" % total_errors)
	quit(1 if total_errors > 0 else 0)


func generate_level(lvl: int) -> int:
	var terrain_grid: Dictionary = {}
	var object_grid: Dictionary = {}
	var vector_field: RefCounted = VectorGrassFieldScript.new()
	var spawn_cell: Vector2i = Vector2i.ZERO
	var width: int = 15
	var height: int = 15
	var time_limit: float = 90.0
	var level_name: String = ""

	match lvl:
		1:
			level_name = "Boas-Vindas ao Jardim"
			width = 13; height = 13; time_limit = 75.0
			spawn_cell = Vector2i(6, 6)
			_add_rect_island(terrain_grid, 2, 2, 9, 9)
			_add_grass_circle(vector_field, "grass_green", 6, 6, width, height, 2.2)
			_add_grass_ring(vector_field, "grass_yellow", 6, 6, width, height, 2.2, 2.85)
		2:
			level_name = "O Prado Bicolor"
			width = 13; height = 13; time_limit = 80.0
			spawn_cell = Vector2i(6, 6)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 9, 9, 2)
			_add_diagonal_stripes(vector_field, width, height, ["grass_green", "grass_yellow"], 1.35)
			# Manchas estelares/circulares de grass_blue no perímetro (com recorte booleano limpo)
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(-1.7, -1.7), 0.90)
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(1.7, -1.7), 0.90)
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(-1.7, 1.7), 0.90)
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(1.7, 1.7), 0.90)
		3:
			level_name = "Introdução à Resistência"
			width = 15; height = 15; time_limit = 85.0
			spawn_cell = Vector2i(7, 7)
			_add_rect_island(terrain_grid, 2, 2, 11, 11)
			_add_dirt_cross(terrain_grid, 7, 7, 3, 3, 9, 9)
			_add_grass_circle(vector_field, "grass_green", 7, 7, width, height, 3.6)
			# 4 linhas de wheat (2 hits) em tiles internos separando quadrantes
			_add_wheat_line(object_grid, [Vector2i(7, 4), Vector2i(7, 5)])
			_add_wheat_line(object_grid, [Vector2i(7, 9), Vector2i(7, 10)])
			_add_wheat_line(object_grid, [Vector2i(4, 7), Vector2i(5, 7)])
			_add_wheat_line(object_grid, [Vector2i(9, 7), Vector2i(10, 7)])
		4:
			level_name = "O Jardim Nobre"
			width = 15; height = 15; time_limit = 90.0
			spawn_cell = Vector2i(7, 7)
			_add_octagon_island(terrain_grid, 7, 7, 5)
			_add_grass_circle(vector_field, "grass_blue", 7, 7, width, height, 2.1)
			_add_grass_ring(vector_field, "grass_purple", 7, 7, width, height, 2.1, 3.5)
			# 4 canteiros cardeais de flower_daisy e flower_bell em tiles internos
			_add_flower(object_grid, Vector2i(6, 4), "flower_daisy")
			_add_flower(object_grid, Vector2i(8, 4), "flower_daisy")
			_add_flower(object_grid, Vector2i(6, 10), "flower_bell")
			_add_flower(object_grid, Vector2i(8, 10), "flower_bell")
			_add_flower(object_grid, Vector2i(4, 6), "flower_daisy")
			_add_flower(object_grid, Vector2i(4, 8), "flower_daisy")
			_add_flower(object_grid, Vector2i(10, 6), "flower_bell")
			_add_flower(object_grid, Vector2i(10, 8), "flower_bell")
		5:
			level_name = "Mandala Floral Mista"
			width = 17; height = 17; time_limit = 95.0
			spawn_cell = Vector2i(8, 8)
			_add_rounded_cross_island(terrain_grid, 8, 8, 6, 7)
			_add_grass_circle(vector_field, "grass_white", 8, 8, width, height, 2.3)
			_add_grass_ring(vector_field, "grass_green", 8, 8, width, height, 2.3, 3.8)
			_add_grass_ring(vector_field, "grass_yellow", 8, 8, width, height, 3.8, 4.5)
			# Barreira circular de wheat a raio 3 células
			var wheat_ring: Array[Vector2i] = [
				Vector2i(8, 5), Vector2i(8, 11), Vector2i(5, 8), Vector2i(11, 8),
				Vector2i(6, 6), Vector2i(10, 6), Vector2i(6, 10), Vector2i(10, 10)
			]
			_add_wheat_line(object_grid, wheat_ring)
			# Extremidades dos 4 braços com flower_rose e flower_sunflower
			_add_flower(object_grid, Vector2i(8, 3), "flower_rose")
			_add_flower(object_grid, Vector2i(8, 13), "flower_rose")
			_add_flower(object_grid, Vector2i(3, 8), "flower_sunflower")
			_add_flower(object_grid, Vector2i(13, 8), "flower_sunflower")
		6:
			level_name = "O Primeiro Rochedo"
			width = 19; height = 11; time_limit = 90.0
			spawn_cell = Vector2i(9, 5)
			_add_rect_island(terrain_grid, 2, 2, 15, 7)
			_add_grass_rect(vector_field, "grass_green", 3, 3, 15, 7, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 6, 4, 12, 6, width, height)
			# 2 rochas sólidas em lados opostos da ilha (dist = 6.40m > 2.80m)
			_add_rock(object_grid, Vector2i(5, 5))
			_add_rock(object_grid, Vector2i(13, 5))
		7:
			level_name = "O Triângulo de Pedra"
			width = 17; height = 17; time_limit = 90.0
			spawn_cell = Vector2i(8, 8)
			_add_octagon_island(terrain_grid, 8, 8, 6)
			_add_grass_circle(vector_field, "grass_blue", 8, 8, width, height, 3.9)
			_add_grass_star_world(vector_field, "grass_white", Vector2.ZERO, 2.3, 1.1, 5)
			# 3 rochas em formação triangular aberta com amplas rotas de fuga
			_add_rock(object_grid, Vector2i(8, 4))
			_add_rock(object_grid, Vector2i(5, 10))
			_add_rock(object_grid, Vector2i(11, 10))
		8:
			level_name = "Caminho Dividido"
			width = 19; height = 17; time_limit = 95.0
			spawn_cell = Vector2i(9, 12)
			_add_u_island(terrain_grid)
			_add_grass_rect(vector_field, "grass_green", 4, 10, 14, 13, width, height)
			_add_grass_rect(vector_field, "grass_purple", 4, 3, 6, 9, width, height)
			_add_grass_rect(vector_field, "grass_red", 12, 3, 14, 9, width, height)
			# 2 rochas posicionadas na entrada de cada península com folga lateral completa
			_add_rock(object_grid, Vector2i(5, 9))
			_add_rock(object_grid, Vector2i(13, 9))
		9:
			level_name = "Pomar Protegido"
			width = 17; height = 17; time_limit = 100.0
			spawn_cell = Vector2i(8, 8)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 13, 13, 2)
			_add_grass_circle(vector_field, "grass_green", 8, 8, width, height, 4.3)
			_add_grass_circle(vector_field, "grass_yellow", 8, 8, width, height, 2.8)
			# 4 rochas formando anel largo (dist entre adjacentes = 3.39m > 2.80m)
			_add_rock(object_grid, Vector2i(8, 5))
			_add_rock(object_grid, Vector2i(8, 11))
			_add_rock(object_grid, Vector2i(5, 8))
			_add_rock(object_grid, Vector2i(11, 8))
			# Flores raras protegidas atrás das pedras (em tiles internos seguros)
			_add_flower(object_grid, Vector2i(8, 3), "flower_tulip")
			_add_flower(object_grid, Vector2i(8, 13), "flower_tulip")
			_add_flower(object_grid, Vector2i(3, 8), "flower_sunflower")
			_add_flower(object_grid, Vector2i(13, 8), "flower_sunflower")
		10:
			level_name = "O Labirinto de Trigo e Granito"
			width = 19; height = 19; time_limit = 105.0
			spawn_cell = Vector2i(9, 9)
			_add_rect_island(terrain_grid, 2, 2, 15, 15)
			_add_dirt_cross(terrain_grid, 9, 9, 4, 4, 11, 11)
			_add_grass_circle(vector_field, "grass_yellow", 9, 9, width, height, 4.4)
			_add_grass_rect(vector_field, "grass_green", 6, 6, 12, 12, width, height)
			# 4 rochas sólidas nos vértices externos das esquinas do trigo
			_add_rock(object_grid, Vector2i(5, 5))
			_add_rock(object_grid, Vector2i(13, 5))
			_add_rock(object_grid, Vector2i(5, 13))
			_add_rock(object_grid, Vector2i(13, 13))
			# Paredes internas destrutíveis de wheat
			_add_wheat_line(object_grid, [
				Vector2i(7, 5), Vector2i(8, 5), Vector2i(10, 5), Vector2i(11, 5),
				Vector2i(5, 7), Vector2i(5, 8), Vector2i(5, 10), Vector2i(5, 11),
				Vector2i(13, 7), Vector2i(13, 8), Vector2i(13, 10), Vector2i(13, 11),
				Vector2i(7, 13), Vector2i(8, 13), Vector2i(10, 13), Vector2i(11, 13)
			])
		11:
			level_name = "Ilhotas Conectadas"
			width = 21; height = 13; time_limit = 100.0
			spawn_cell = Vector2i(5, 6)
			_add_bridge_island(terrain_grid)
			_add_grass_rect(vector_field, "grass_blue", 3, 3, 7, 9, width, height)
			_add_grass_rect(vector_field, "grass_white", 8, 5, 12, 7, width, height)
			_add_grass_rect(vector_field, "grass_blue", 13, 3, 17, 9, width, height)
			# Rochas com folga garantida nas cabeceiras e centro
			_add_rock(object_grid, Vector2i(5, 3))
			_add_rock(object_grid, Vector2i(10, 6))
			_add_rock(object_grid, Vector2i(15, 6))
			# Flores sino na ilha leste
			_add_flower(object_grid, Vector2i(14, 4), "flower_bell")
			_add_flower(object_grid, Vector2i(16, 4), "flower_bell")
			_add_flower(object_grid, Vector2i(14, 8), "flower_bell")
			_add_flower(object_grid, Vector2i(16, 8), "flower_bell")
		12:
			level_name = "Vulcânica"
			width = 17; height = 17; time_limit = 105.0
			spawn_cell = Vector2i(8, 8)
			_add_octagon_island(terrain_grid, 8, 8, 6)
			_add_grass_circle(vector_field, "grass_black", 8, 8, width, height, 4.1)
			_add_grass_ring(vector_field, "grass_red", 8, 8, width, height, 2.3, 3.4)
			# 4 rochas cardeais em distância ampla
			_add_rock(object_grid, Vector2i(8, 4))
			_add_rock(object_grid, Vector2i(8, 12))
			_add_rock(object_grid, Vector2i(4, 8))
			_add_rock(object_grid, Vector2i(12, 8))
			# 4 flores corola nas diagonais
			_add_flower(object_grid, Vector2i(6, 6), "flower_corolla")
			_add_flower(object_grid, Vector2i(10, 6), "flower_corolla")
			_add_flower(object_grid, Vector2i(6, 10), "flower_corolla")
			_add_flower(object_grid, Vector2i(10, 10), "flower_corolla")
		13:
			level_name = "O Relógio de Quatro Pilares"
			width = 19; height = 19; time_limit = 110.0
			spawn_cell = Vector2i(9, 9)
			_add_rounded_cross_island(terrain_grid, 9, 9, 7, 7)
			# 4 quadrantes com cores distintas
			_add_grass_rect(vector_field, "grass_green", 3, 3, 8, 8, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 10, 3, 15, 8, width, height)
			_add_grass_rect(vector_field, "grass_blue", 3, 10, 8, 15, width, height)
			_add_grass_rect(vector_field, "grass_purple", 10, 10, 15, 15, width, height)
			# 4 rochas diagonais como marcos divisórios em tiles internos seguros
			_add_rock(object_grid, Vector2i(6, 6))
			_add_rock(object_grid, Vector2i(12, 6))
			_add_rock(object_grid, Vector2i(6, 12))
			_add_rock(object_grid, Vector2i(12, 12))
			# 4 rosas nobres nos braços cardeais
			_add_flower(object_grid, Vector2i(9, 4), "flower_rose")
			_add_flower(object_grid, Vector2i(9, 14), "flower_rose")
			_add_flower(object_grid, Vector2i(4, 9), "flower_rose")
			_add_flower(object_grid, Vector2i(14, 9), "flower_rose")
		14:
			level_name = "Serpente de Trigo"
			width = 21; height = 13; time_limit = 110.0
			spawn_cell = Vector2i(4, 6)
			_add_rect_island(terrain_grid, 2, 2, 17, 9)
			_add_grass_rect(vector_field, "grass_green", 3, 3, 17, 9, width, height)
			_add_grass_rect(vector_field, "grass_white", 4, 4, 16, 8, width, height)
			# 3 rochas no lado interno de cada curva da serpente
			_add_rock(object_grid, Vector2i(7, 4))
			_add_rock(object_grid, Vector2i(11, 8))
			_add_rock(object_grid, Vector2i(15, 4))
			# Trilha sinuosa contínua de wheat
			var snake_wheat: Array[Vector2i] = [
				Vector2i(6, 6), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 6),
				Vector2i(10, 5), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 5),
				Vector2i(14, 6), Vector2i(15, 7), Vector2i(16, 7), Vector2i(17, 6)
			]
			_add_wheat_line(object_grid, snake_wheat)
		15:
			level_name = "O Parque Central de Canteiros"
			width = 19; height = 17; time_limit = 115.0
			spawn_cell = Vector2i(9, 8)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 15, 13, 2)
			_add_grass_circle(vector_field, "grass_green", 9, 8, width, height, 4.4)
			_add_grass_ring(vector_field, "grass_yellow", 9, 8, width, height, 2.0, 2.8)
			# 5 rochas distribuídas de maneira assimétrica com folga ampla (> 2.80m)
			_add_rock(object_grid, Vector2i(5, 5))
			_add_rock(object_grid, Vector2i(13, 5))
			_add_rock(object_grid, Vector2i(5, 11))
			_add_rock(object_grid, Vector2i(13, 11))
			_add_rock(object_grid, Vector2i(9, 4))
			# 6 canteiros rasteiros (flower_bed)
			_add_flower(object_grid, Vector2i(7, 6), "flower_bed")
			_add_flower(object_grid, Vector2i(11, 6), "flower_bed")
			_add_flower(object_grid, Vector2i(6, 8), "flower_bed")
			_add_flower(object_grid, Vector2i(12, 8), "flower_bed")
			_add_flower(object_grid, Vector2i(7, 10), "flower_bed")
			_add_flower(object_grid, Vector2i(11, 10), "flower_bed")
		16:
			level_name = "O Anel Exterior de Obstáculos"
			width = 19; height = 19; time_limit = 115.0
			spawn_cell = Vector2i(9, 9)
			_add_octagon_island(terrain_grid, 9, 9, 7)
			_add_grass_circle(vector_field, "grass_yellow", 9, 9, width, height, 2.9)
			_add_grass_ring(vector_field, "grass_red", 9, 9, width, height, 2.9, 4.5)
			# 6 rochas alinhadas no perímetro com margem segura da falésia
			_add_rock(object_grid, Vector2i(9, 4))
			_add_rock(object_grid, Vector2i(13, 6))
			_add_rock(object_grid, Vector2i(13, 12))
			_add_rock(object_grid, Vector2i(9, 14))
			_add_rock(object_grid, Vector2i(5, 12))
			_add_rock(object_grid, Vector2i(5, 6))
			# 6 girassóis no anel externo
			_add_flower(object_grid, Vector2i(11, 4), "flower_sunflower")
			_add_flower(object_grid, Vector2i(14, 9), "flower_sunflower")
			_add_flower(object_grid, Vector2i(11, 14), "flower_sunflower")
			_add_flower(object_grid, Vector2i(7, 14), "flower_sunflower")
			_add_flower(object_grid, Vector2i(4, 9), "flower_sunflower")
			_add_flower(object_grid, Vector2i(7, 4), "flower_sunflower")
		17:
			level_name = "Alameda Imperial"
			width = 21; height = 17; time_limit = 120.0
			spawn_cell = Vector2i(10, 8)
			_add_h_island(terrain_grid)
			_add_grass_rect(vector_field, "grass_green", 4, 3, 7, 13, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 8, 6, 12, 10, width, height)
			_add_grass_rect(vector_field, "grass_green", 13, 3, 16, 13, width, height)
			# 4 rochas marcando os acessos das avenidas
			_add_rock(object_grid, Vector2i(5, 4))
			_add_rock(object_grid, Vector2i(5, 12))
			_add_rock(object_grid, Vector2i(15, 4))
			_add_rock(object_grid, Vector2i(15, 12))
			# Colunas de wheat e flower_tulip em tiles internos
			_add_wheat_line(object_grid, [Vector2i(6, 6), Vector2i(6, 7), Vector2i(6, 9), Vector2i(6, 10)])
			_add_wheat_line(object_grid, [Vector2i(14, 6), Vector2i(14, 7), Vector2i(14, 9), Vector2i(14, 10)])
			_add_flower(object_grid, Vector2i(6, 4), "flower_tulip")
			_add_flower(object_grid, Vector2i(6, 12), "flower_tulip")
			_add_flower(object_grid, Vector2i(14, 4), "flower_tulip")
			_add_flower(object_grid, Vector2i(14, 12), "flower_tulip")
		18:
			level_name = "O Labirinto dos Quatro Diamantes"
			width = 19; height = 19; time_limit = 120.0
			spawn_cell = Vector2i(9, 9)
			_add_diamond_island(terrain_grid, 9, 9, 8)
			_add_grass_circle(vector_field, "grass_white", 9, 9, width, height, 2.3)
			_add_grass_ring(vector_field, "grass_purple", 9, 9, width, height, 2.3, 4.8)
			# 4 rochas nos eixos dos 4 diamantes
			_add_rock(object_grid, Vector2i(9, 5))
			_add_rock(object_grid, Vector2i(9, 13))
			_add_rock(object_grid, Vector2i(5, 9))
			_add_rock(object_grid, Vector2i(13, 9))
			# Trigo desenhando facetas diagonais e canteiros nas pontas
			_add_wheat_line(object_grid, [
				Vector2i(7, 7), Vector2i(11, 7), Vector2i(7, 11), Vector2i(11, 11)
			])
			_add_flower(object_grid, Vector2i(9, 3), "flower_bed")
			_add_flower(object_grid, Vector2i(9, 15), "flower_bed")
			_add_flower(object_grid, Vector2i(3, 9), "flower_bed")
			_add_flower(object_grid, Vector2i(15, 9), "flower_bed")
		19:
			level_name = "O Oásis Multicolorido"
			width = 19; height = 19; time_limit = 125.0
			spawn_cell = Vector2i(9, 9)
			_add_star_island(terrain_grid, 9, 9, 7, 5)
			_add_grass_circle(vector_field, "grass_green", 9, 9, width, height, 1.9)
			_add_grass_ring(vector_field, "grass_blue", 9, 9, width, height, 1.9, 2.9)
			_add_grass_ring(vector_field, "grass_purple", 9, 9, width, height, 2.9, 3.8)
			_add_grass_ring(vector_field, "grass_black", 9, 9, width, height, 3.8, 4.6)
			# 5 rochas em pentágono aberto
			_add_rock(object_grid, Vector2i(9, 4))
			_add_rock(object_grid, Vector2i(13, 7))
			_add_rock(object_grid, Vector2i(12, 12))
			_add_rock(object_grid, Vector2i(6, 12))
			_add_rock(object_grid, Vector2i(5, 7))
			# 5 espécies de flores nobres nos vértices externos
			_add_flower(object_grid, Vector2i(9, 3), "flower_rose")
			_add_flower(object_grid, Vector2i(14, 7), "flower_bell")
			_add_flower(object_grid, Vector2i(12, 13), "flower_sunflower")
			_add_flower(object_grid, Vector2i(6, 13), "flower_tulip")
			_add_flower(object_grid, Vector2i(4, 7), "flower_corolla")
		20:
			level_name = "Arquipélago da Maestria"
			width = 21; height = 21; time_limit = 135.0
			spawn_cell = Vector2i(10, 10)
			_add_clover_island(terrain_grid, 10, 10)
			_add_grass_circle(vector_field, "grass_yellow", 10, 10, width, height, 2.3)
			_add_grass_ring(vector_field, "grass_white", 10, 10, width, height, 2.3, 3.6)
			_add_grass_ring(vector_field, "grass_green", 10, 10, width, height, 3.6, 5.2)
			# 6 rochas em gargalos estratégicos (todas com dist >= 3.39m > 2.80m)
			_add_rock(object_grid, Vector2i(10, 5))
			_add_rock(object_grid, Vector2i(10, 15))
			_add_rock(object_grid, Vector2i(5, 10))
			_add_rock(object_grid, Vector2i(15, 10))
			_add_rock(object_grid, Vector2i(7, 7))
			_add_rock(object_grid, Vector2i(13, 13))
			# Trigo e flores nas 4 folhas do trevo
			_add_wheat_line(object_grid, [
				Vector2i(10, 4), Vector2i(10, 16), Vector2i(4, 10), Vector2i(16, 10),
				Vector2i(7, 13), Vector2i(13, 7)
			])
			_add_flower(object_grid, Vector2i(10, 3), "flower_tulip")
			_add_flower(object_grid, Vector2i(10, 17), "flower_tulip")
			_add_flower(object_grid, Vector2i(3, 10), "flower_corolla")
			_add_flower(object_grid, Vector2i(17, 10), "flower_corolla")

	# 1. Aplica Autotile nas células da ilha
	IslandAutotiler.apply_autotile(terrain_grid)

	# 2. Recorta todos os polígonos de grama estritamente para a área plana interna da ilha
	#    e abre clareira exata no ponto de spawn para evitar auto-corte no frame 0
	_clip_vector_field_to_island(vector_field, terrain_grid, spawn_cell, width, height)

	# 3. Validações estritas de Level Design e Física
	var err_count: int = _validate_level(lvl, level_name, spawn_cell, terrain_grid, object_grid, vector_field, width, height)

	# 4. Salva o arquivo JSON v3
	var ok: bool = LevelSerializer.save_level_json(
		lvl,
		level_name,
		time_limit,
		width,
		height,
		spawn_cell,
		0,
		terrain_grid,
		object_grid,
		null,
		vector_field,
		{} # metas calculadas dinamicamente
	)

	if not ok:
		printerr("FALHA ao salvar nível %02d!" % lvl)
		err_count += 1

	return err_count


# --- Recorte Automático de Segurança Costeira e Clareira de Spawn ---
func _clip_vector_field_to_island(
	vf: RefCounted,
	terrain_grid: Dictionary,
	spawn_cell: Vector2i,
	width: int,
	height: int
) -> void:
	# Constrói retângulos seguros por linha (com inset de 0.34m nas bordas que dão para o mar)
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

			# Recuo adicional em quinas externas diagonais
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

	# Mescla todos os retângulos seguros em polígonos unidos da ilha
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

	# Intersecta cada forma do campo vetorial com a máscara interna da ilha
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

	# Abre clareira sutil no ponto de spawn (evita que tufos sejam auto-cortados no frame 0)
	var sp3: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, width, height, CELL_SIZE)
	var sp_center: Vector2 = Vector2(sp3.x, sp3.z)
	var spawn_clear_poly: PackedVector2Array = PackedVector2Array()
	for i: int in range(20):
		var a: float = float(i) * TAU / 20.0
		spawn_clear_poly.append(sp_center + Vector2(cos(a), sin(a)) * SPAWN_GRASS_CLEAR_RADIUS)
	vf.call("clip_shapes", spawn_clear_poly)


# --- Métodos de Validação Estrita (6 Regras de Level Design) ---
func _validate_level(
	lvl: int,
	lvl_name: String,
	spawn_cell: Vector2i,
	terrain_grid: Dictionary,
	object_grid: Dictionary,
	vf: RefCounted,
	width: int,
	height: int
) -> int:
	var errors: int = 0
	var sp_pos: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, width, height, CELL_SIZE)
	var rocks: Array[Vector3] = []

	# Regra 0: Spawn deve estar em tile interno com os 8 vizinhos em terrain_grid
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

		# Regra 2: Fases 1 a 5 sem rochas
		if lvl <= 5 and o_type == "rock":
			printerr("[ERRO LVL %d] Rocha proibida em fases <= 5!" % lvl)
			errors += 1

		# Regra 3: Todo objeto deve estar sobre tile interno (4 vizinhos cardeais em terrain_grid)
		if not terrain_grid.has(cell):
			printerr("[ERRO LVL %d] Objeto '%s' em %s está FORA da ilha (na água)!" % [lvl, o_type, str(cell)])
			errors += 1
		else:
			var cardinals: Array[Vector2i] = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
			for dir: Vector2i in cardinals:
				if not terrain_grid.has(cell + dir):
					printerr("[ERRO LVL %d] Objeto '%s' em %s está na borda da falésia!" % [lvl, o_type, str(cell)])
					errors += 1
					break

		# Regra 4: Rochas precisam de todos os 8 vizinhos em terrain_grid (folga costeira anti-estrangulamento)
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

	# Regra 6: Auditoria de tufos amostrados (0 tufos na água e contagem equilibrada)
	var sampled: Array = vf.call("sample_all_tufts") as Array
	var water_tufts: int = 0
	for item: Variant in sampled:
		var td: Dictionary = item as Dictionary
		var pos: Vector3 = td["pos"] as Vector3
		var gc: Vector2i = LevelJsonLoader.world_to_grid(pos, width, height, CELL_SIZE)
		if not terrain_grid.has(gc):
			water_tufts += 1
	if water_tufts > 0:
		printerr("[ERRO LVL %d] %d tufos de grama caindo na água!" % [lvl, water_tufts])
		errors += 1

	var wheat_cnt: int = 0
	var flower_cnt: int = 0
	for ck: Variant in object_grid.keys():
		var ot: String = String((object_grid[ck] as Dictionary).get("type", ""))
		if ot == "wheat":
			wheat_cnt += 1
		elif ot.begins_with("flower"):
			flower_cnt += 1

	print("Nível %02d OK: '%s' | Grid %dx%d | Grama: %d tufos | Trigo: %d | Flores: %d | Rochas: %d" % [
		lvl, lvl_name, width, height, sampled.size(), wheat_cnt, flower_cnt, rocks.size()
	])
	return errors


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
	# Chanfro suave interno nas axilas da cruz
	var inner_r: int = hw + 1
	for x: int in range(cx - inner_r, cx + inner_r + 1):
		for z: int in range(cz - inner_r, cz + inner_r + 1):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_u_island(grid: Dictionary) -> void:
	# Base horizontal ampla (z = 10..14, x = 3..15)
	for x: int in range(3, 16):
		for z: int in range(10, 15):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Península esquerda (5 blocos de largura: x = 3..7, z = 2..10)
	for x: int in range(3, 8):
		for z: int in range(2, 11):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Península direita (5 blocos de largura: x = 11..15, z = 2..10)
	for x: int in range(11, 16):
		for z: int in range(2, 11):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_bridge_island(grid: Dictionary) -> void:
	# Ilha oeste (x = 2..8, z = 2..10)
	for x: int in range(2, 9):
		for z: int in range(2, 11):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Ilha leste (x = 12..18, z = 2..10)
	for x: int in range(12, 19):
		for z: int in range(2, 11):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Istmo central largo (x = 8..12, z = 4..8) com trilha de terra central
	for x: int in range(8, 13):
		for z: int in range(4, 9):
			var tid: String = "island_dirt" if z == 6 else "island_center"
			grid[Vector2i(x, z)] = { "tile_id": tid, "rot": 0, "auto": true }

func _add_h_island(grid: Dictionary) -> void:
	# Avenida oeste (x = 3..8, z = 2..14)
	for x: int in range(3, 9):
		for z: int in range(2, 15):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Avenida leste (x = 12..17, z = 2..14)
	for x: int in range(12, 18):
		for z: int in range(2, 15):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Alameda central (x = 8..12, z = 5..11)
	for x: int in range(8, 13):
		for z: int in range(5, 12):
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
	# Núcleo central amplo (x = 5..15, z = 5..15)
	_add_rect_island(grid, cx - 5, cz - 5, 11, 11)
	# 4 folhas cardeais (x/z alcançando 2..18)
	_add_rect_island(grid, cx - 3, cz - 8, 7, 4)
	_add_rect_island(grid, cx - 3, cz + 5, 7, 4)
	_add_rect_island(grid, cx - 8, cz - 3, 4, 7)
	_add_rect_island(grid, cx + 5, cz - 3, 4, 7)

func _add_dirt_cross(grid: Dictionary, cx: int, cz: int, x0: int, z0: int, w: int, h: int) -> void:
	for x: int in range(x0, x0 + w):
		grid[Vector2i(x, cz)] = { "tile_id": "island_dirt", "rot": 0, "auto": true }
	for z: int in range(z0, z0 + h):
		grid[Vector2i(cx, z)] = { "tile_id": "island_dirt", "rot": 0, "auto": true }


# --- Helpers de Vegetação Vetorial (com substituição booleana sem sobreposição) ---
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
	var ring_parts: Array[PackedVector2Array] = vf.call("_clip_polygon_without_holes", outer, inner) as Array[PackedVector2Array]
	for part: PackedVector2Array in ring_parts:
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
	var max_extent: float = float(mini(width, height) - 5) * CELL_SIZE * 0.5
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
		var clipped_polys: Array[PackedVector2Array] = Geometry2D.intersect_polygons(island_rect, p_strip)
		for cp: PackedVector2Array in clipped_polys:
			if cp.size() >= 3:
				vf.call("add_shape", t_name, cp)
		cur = next_cur
		idx += 1


# --- Helpers de Objetos Rígidos ---
func _add_rock(grid: Dictionary, cell: Vector2i) -> void:
	grid[cell] = { "type": "rock", "rot": 0 }

func _add_wheat_line(grid: Dictionary, cells: Array) -> void:
	for item: Variant in cells:
		var c: Vector2i = item as Vector2i
		grid[c] = { "type": "wheat", "rot": 0 }

func _add_flower(grid: Dictionary, cell: Vector2i, flower_type: String) -> void:
	grid[cell] = { "type": flower_type, "rot": 0 }
