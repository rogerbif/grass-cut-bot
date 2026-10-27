extends SceneTree

const IslandAutotiler = preload("res://scripts/editor/island_autotiler.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

const CELL_SIZE: float = 0.80
const MIN_SPAWN_CLEAR_DIST: float = 1.47 # 1.05 * 1.40m
const MIN_ROCK_SPACING: float = 2.80      # 2 * 1.40m

func _init() -> void:
	print("=== INICIANDO GERAÇÃO DAS 20 PRIMEIRAS FASES CANÔNICAS ===")
	for lvl in range(1, 21):
		generate_level(lvl)
	print("=== TODAS AS 20 FASES FORAM GERADAS E SALVAS COM SUCESSO! ===")
	quit()

func generate_level(lvl: int) -> void:
	var terrain_grid: Dictionary = {}
	var object_grid: Dictionary = {}
	var vector_field = VectorGrassFieldScript.new()
	var spawn_cell: Vector2i = Vector2i.ZERO
	var width: int = 14
	var height: int = 14
	var time_limit: float = 90.0
	var level_name: String = ""

	match lvl:
		1:
			level_name = "Boas-Vindas ao Jardim"
			width = 12; height = 12; time_limit = 75.0
			spawn_cell = Vector2i(6, 6)
			_add_rect_island(terrain_grid, 2, 2, 8, 8)
			_add_grass_circle(vector_field, "grass_green", 6, 6, width, height, 2.7)
			_add_grass_ring(vector_field, "grass_yellow", 6, 6, width, height, 2.7, 3.2)
		2:
			level_name = "O Prado Bicolor"
			width = 14; height = 14; time_limit = 80.0
			spawn_cell = Vector2i(7, 7)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 10, 10, 2)
			_add_diagonal_stripes(vector_field, width, height, ["grass_green", "grass_yellow"], 1.6)
			# Manchas estelares nas 4 quinas
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(-3.0, -3.0), 1.2)
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(3.0, -3.0), 1.2)
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(-3.0, 3.0), 1.2)
			_add_grass_circle_world(vector_field, "grass_blue", Vector2(3.0, 3.0), 1.2)
		3:
			level_name = "Introdução à Resistência"
			width = 14; height = 14; time_limit = 85.0
			spawn_cell = Vector2i(7, 7)
			_add_rect_island(terrain_grid, 2, 2, 10, 10)
			_add_dirt_cross(terrain_grid, 7, 7, 2, 2, 10, 10)
			_add_grass_circle(vector_field, "grass_green", 7, 7, width, height, 3.6)
			# 4 linhas de wheat separando quadrantes
			_add_wheat_line(object_grid, [Vector2i(7, 3), Vector2i(7, 4)])
			_add_wheat_line(object_grid, [Vector2i(7, 10), Vector2i(7, 11)])
			_add_wheat_line(object_grid, [Vector2i(3, 7), Vector2i(4, 7)])
			_add_wheat_line(object_grid, [Vector2i(10, 7), Vector2i(11, 7)])
		4:
			level_name = "O Jardim Nobre"
			width = 14; height = 14; time_limit = 90.0
			spawn_cell = Vector2i(7, 7)
			_add_octagon_island(terrain_grid, 7, 7, 5)
			_add_grass_circle(vector_field, "grass_blue", 7, 7, width, height, 2.2)
			_add_grass_ring(vector_field, "grass_purple", 7, 7, width, height, 2.2, 3.8)
			# 4 canteiros cardeais de margarida e sino
			_add_flower(object_grid, Vector2i(7, 3), "flower_daisy")
			_add_flower(object_grid, Vector2i(8, 3), "flower_daisy")
			_add_flower(object_grid, Vector2i(7, 11), "flower_bell")
			_add_flower(object_grid, Vector2i(8, 11), "flower_bell")
			_add_flower(object_grid, Vector2i(3, 7), "flower_daisy")
			_add_flower(object_grid, Vector2i(3, 8), "flower_daisy")
			_add_flower(object_grid, Vector2i(11, 7), "flower_bell")
			_add_flower(object_grid, Vector2i(11, 8), "flower_bell")
		5:
			level_name = "Mandala Floral Mista"
			width = 16; height = 16; time_limit = 100.0
			spawn_cell = Vector2i(8, 8)
			_add_cross_island(terrain_grid, 8, 8, 6, 3)
			_add_grass_circle(vector_field, "grass_white", 8, 8, width, height, 2.4)
			_add_grass_ring(vector_field, "grass_green", 8, 8, width, height, 2.4, 4.4)
			# Barreira circular de wheat a raio 3 células
			var wheat_ring = [
				Vector2i(8, 5), Vector2i(8, 11), Vector2i(5, 8), Vector2i(11, 8),
				Vector2i(6, 6), Vector2i(10, 6), Vector2i(6, 10), Vector2i(10, 10)
			]
			_add_wheat_line(object_grid, wheat_ring)
			# Cantos com rose e sunflower
			_add_flower(object_grid, Vector2i(4, 4), "flower_rose")
			_add_flower(object_grid, Vector2i(12, 4), "flower_rose")
			_add_flower(object_grid, Vector2i(4, 12), "flower_sunflower")
			_add_flower(object_grid, Vector2i(12, 12), "flower_sunflower")
		6:
			level_name = "O Primeiro Rochedo"
			width = 18; height = 10; time_limit = 90.0
			spawn_cell = Vector2i(9, 5)
			_add_rect_island(terrain_grid, 2, 2, 14, 6)
			_add_grass_rect(vector_field, "grass_green", 2, 2, 15, 7, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 6, 3, 12, 6, width, height)
			# Apenas 2 rochas em lados opostos (> 8.0m entre si)
			_add_rock(object_grid, Vector2i(4, 5))
			_add_rock(object_grid, Vector2i(14, 5))
		7:
			level_name = "O Triângulo de Pedra"
			width = 16; height = 14; time_limit = 90.0
			spawn_cell = Vector2i(8, 7)
			_add_hexagon_island(terrain_grid, 8, 7, 5)
			_add_grass_circle(vector_field, "grass_blue", 8, 7, width, height, 4.0)
			_add_grass_circle(vector_field, "grass_white", 8, 7, width, height, 1.8)
			# 3 rochas em formação triangular aberta
			_add_rock(object_grid, Vector2i(8, 3))
			_add_rock(object_grid, Vector2i(4, 9))
			_add_rock(object_grid, Vector2i(12, 9))
		8:
			level_name = "Caminho Dividido"
			width = 18; height = 16; time_limit = 95.0
			spawn_cell = Vector2i(9, 11)
			_add_u_island(terrain_grid, width, height)
			_add_grass_rect(vector_field, "grass_green", 4, 10, 14, 13, width, height)
			_add_grass_rect(vector_field, "grass_purple", 4, 3, 7, 9, width, height)
			_add_grass_rect(vector_field, "grass_red", 11, 3, 14, 9, width, height)
			# 2 rochas nas entradas das penínsulas
			_add_rock(object_grid, Vector2i(5, 9))
			_add_rock(object_grid, Vector2i(13, 9))
		9:
			level_name = "Pomar Protegido"
			width = 16; height = 16; time_limit = 100.0
			spawn_cell = Vector2i(8, 8)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 12, 12, 2)
			_add_grass_circle(vector_field, "grass_yellow", 8, 8, width, height, 4.2)
			# 4 rochas formando anel largo
			_add_rock(object_grid, Vector2i(8, 4))
			_add_rock(object_grid, Vector2i(8, 12))
			_add_rock(object_grid, Vector2i(4, 8))
			_add_rock(object_grid, Vector2i(12, 8))
			# Flores atrás das rochas
			_add_flower(object_grid, Vector2i(8, 3), "flower_tulip")
			_add_flower(object_grid, Vector2i(8, 13), "flower_tulip")
			_add_flower(object_grid, Vector2i(3, 8), "flower_sunflower")
			_add_flower(object_grid, Vector2i(13, 8), "flower_sunflower")
		10:
			level_name = "O Labirinto de Trigo e Granito"
			width = 18; height = 18; time_limit = 110.0
			spawn_cell = Vector2i(9, 9)
			_add_rect_island(terrain_grid, 2, 2, 14, 14)
			_add_grass_rect(vector_field, "grass_yellow", 2, 2, 15, 15, width, height)
			# 4 rochas nos vértices externos
			_add_rock(object_grid, Vector2i(5, 5))
			_add_rock(object_grid, Vector2i(13, 5))
			_add_rock(object_grid, Vector2i(5, 13))
			_add_rock(object_grid, Vector2i(13, 13))
			# Paredes de wheat
			_add_wheat_line(object_grid, [
				Vector2i(7, 5), Vector2i(8, 5), Vector2i(10, 5), Vector2i(11, 5),
				Vector2i(5, 7), Vector2i(5, 8), Vector2i(5, 10), Vector2i(5, 11),
				Vector2i(13, 7), Vector2i(13, 8), Vector2i(13, 10), Vector2i(13, 11),
				Vector2i(7, 13), Vector2i(8, 13), Vector2i(10, 13), Vector2i(11, 13)
			])
		11:
			level_name = "Ilhotas Conectadas"
			width = 20; height = 12; time_limit = 105.0
			spawn_cell = Vector2i(5, 6)
			_add_bridge_island(terrain_grid, width, height)
			_add_grass_rect(vector_field, "grass_blue", 2, 3, 7, 8, width, height)
			_add_grass_rect(vector_field, "grass_blue", 12, 3, 17, 8, width, height)
			# 3 rochas nas cabeceiras e ilha leste
			_add_rock(object_grid, Vector2i(8, 4))
			_add_rock(object_grid, Vector2i(11, 7))
			_add_rock(object_grid, Vector2i(15, 5))
			# Flores sino na ilha leste
			_add_flower(object_grid, Vector2i(14, 4), "flower_bell")
			_add_flower(object_grid, Vector2i(16, 4), "flower_bell")
			_add_flower(object_grid, Vector2i(14, 7), "flower_bell")
			_add_flower(object_grid, Vector2i(16, 7), "flower_bell")
		12:
			level_name = "Vulcânica"
			width = 16; height = 16; time_limit = 105.0
			spawn_cell = Vector2i(8, 8)
			_add_irregular_circle_island(terrain_grid, 8, 8, 5.5)
			_add_grass_circle(vector_field, "grass_black", 8, 8, width, height, 4.4)
			_add_grass_ring(vector_field, "grass_red", 8, 8, width, height, 2.5, 3.8)
			# 4 rochas cardeais
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
			width = 18; height = 18; time_limit = 110.0
			spawn_cell = Vector2i(9, 9)
			_add_cross_island(terrain_grid, 9, 9, 7, 4)
			# 4 quadrantes coloridos
			_add_grass_rect(vector_field, "grass_green", 3, 3, 8, 8, width, height)
			_add_grass_rect(vector_field, "grass_yellow", 10, 3, 15, 8, width, height)
			_add_grass_rect(vector_field, "grass_blue", 3, 10, 8, 15, width, height)
			_add_grass_rect(vector_field, "grass_purple", 10, 10, 15, 15, width, height)
			# 4 rochas diagonais
			_add_rock(object_grid, Vector2i(5, 5))
			_add_rock(object_grid, Vector2i(13, 5))
			_add_rock(object_grid, Vector2i(5, 13))
			_add_rock(object_grid, Vector2i(13, 13))
			# 4 rosas nos centros dos quadrantes
			_add_flower(object_grid, Vector2i(6, 9), "flower_rose")
			_add_flower(object_grid, Vector2i(12, 9), "flower_rose")
			_add_flower(object_grid, Vector2i(9, 6), "flower_rose")
			_add_flower(object_grid, Vector2i(9, 12), "flower_rose")
		14:
			level_name = "Serpente de Trigo"
			width = 22; height = 12; time_limit = 110.0
			spawn_cell = Vector2i(3, 6)
			_add_rect_island(terrain_grid, 2, 2, 18, 8)
			_add_grass_rect(vector_field, "grass_white", 2, 2, 19, 9, width, height)
			# 3 rochas nas curvas internas da serpente
			_add_rock(object_grid, Vector2i(7, 4))
			_add_rock(object_grid, Vector2i(11, 7))
			_add_rock(object_grid, Vector2i(15, 4))
			# Trilha sinuosa de wheat
			var snake_wheat = [
				Vector2i(6, 6), Vector2i(7, 7), Vector2i(8, 7), Vector2i(9, 6),
				Vector2i(10, 5), Vector2i(11, 4), Vector2i(12, 4), Vector2i(13, 5),
				Vector2i(14, 6), Vector2i(15, 7), Vector2i(16, 7), Vector2i(17, 6)
			]
			_add_wheat_line(object_grid, snake_wheat)
		15:
			level_name = "O Parque Central de Canteiros"
			width = 18; height = 16; time_limit = 115.0
			spawn_cell = Vector2i(9, 8)
			_add_chamfered_rect_island(terrain_grid, 2, 2, 14, 12, 3)
			_add_grass_circle(vector_field, "grass_green", 9, 8, width, height, 5.0)
			# 5 rochas assimétricas
			_add_rock(object_grid, Vector2i(5, 5))
			_add_rock(object_grid, Vector2i(13, 4))
			_add_rock(object_grid, Vector2i(4, 11))
			_add_rock(object_grid, Vector2i(12, 11))
			_add_rock(object_grid, Vector2i(14, 8))
			# 6 canteiros floridos
			_add_flower(object_grid, Vector2i(7, 5), "flower_bed")
			_add_flower(object_grid, Vector2i(11, 5), "flower_bed")
			_add_flower(object_grid, Vector2i(6, 8), "flower_bed")
			_add_flower(object_grid, Vector2i(12, 8), "flower_bed")
			_add_flower(object_grid, Vector2i(7, 11), "flower_bed")
			_add_flower(object_grid, Vector2i(10, 11), "flower_bed")
		16:
			level_name = "O Anel Exterior de Obstáculos"
			width = 18; height = 18; time_limit = 115.0
			spawn_cell = Vector2i(9, 9)
			_add_octagon_island(terrain_grid, 9, 9, 7)
			_add_grass_circle(vector_field, "grass_yellow", 9, 9, width, height, 3.2)
			_add_grass_ring(vector_field, "grass_red", 9, 9, width, height, 3.2, 5.2)
			# 6 rochas periféricas próximas à borda
			_add_rock(object_grid, Vector2i(9, 3))
			_add_rock(object_grid, Vector2i(14, 6))
			_add_rock(object_grid, Vector2i(14, 12))
			_add_rock(object_grid, Vector2i(9, 15))
			_add_rock(object_grid, Vector2i(4, 12))
			_add_rock(object_grid, Vector2i(4, 6))
			# 6 girassóis entre as rochas
			_add_flower(object_grid, Vector2i(12, 4), "flower_sunflower")
			_add_flower(object_grid, Vector2i(15, 9), "flower_sunflower")
			_add_flower(object_grid, Vector2i(12, 14), "flower_sunflower")
			_add_flower(object_grid, Vector2i(6, 14), "flower_sunflower")
			_add_flower(object_grid, Vector2i(3, 9), "flower_sunflower")
			_add_flower(object_grid, Vector2i(6, 4), "flower_sunflower")
		17:
			level_name = "Alameda Imperial"
			width = 20; height = 16; time_limit = 120.0
			spawn_cell = Vector2i(10, 8)
			_add_h_island(terrain_grid, width, height)
			_add_grass_rect(vector_field, "grass_green", 3, 3, 16, 12, width, height)
			# 4 rochas nos acessos laterais das avenidas
			_add_rock(object_grid, Vector2i(5, 4))
			_add_rock(object_grid, Vector2i(5, 12))
			_add_rock(object_grid, Vector2i(15, 4))
			_add_rock(object_grid, Vector2i(15, 12))
			# Colunas de wheat e tulip
			_add_wheat_line(object_grid, [Vector2i(6, 5), Vector2i(6, 6), Vector2i(6, 10), Vector2i(6, 11)])
			_add_wheat_line(object_grid, [Vector2i(14, 5), Vector2i(14, 6), Vector2i(14, 10), Vector2i(14, 11)])
			_add_flower(object_grid, Vector2i(7, 5), "flower_tulip")
			_add_flower(object_grid, Vector2i(7, 11), "flower_tulip")
			_add_flower(object_grid, Vector2i(13, 5), "flower_tulip")
			_add_flower(object_grid, Vector2i(13, 11), "flower_tulip")
		18:
			level_name = "O Labirinto dos Quatro Diamantes"
			width = 20; height = 20; time_limit = 120.0
			spawn_cell = Vector2i(10, 10)
			_add_diamond_island(terrain_grid, 10, 10, 8)
			_add_grass_circle(vector_field, "grass_white", 10, 10, width, height, 2.5)
			_add_grass_ring(vector_field, "grass_purple", 10, 10, width, height, 2.5, 6.0)
			# 4 rochas nos centros dos 4 diamantes
			_add_rock(object_grid, Vector2i(10, 5))
			_add_rock(object_grid, Vector2i(10, 15))
			_add_rock(object_grid, Vector2i(5, 10))
			_add_rock(object_grid, Vector2i(15, 10))
			# Canteiros floridos
			_add_flower(object_grid, Vector2i(10, 4), "flower_bed")
			_add_flower(object_grid, Vector2i(10, 16), "flower_bed")
			_add_flower(object_grid, Vector2i(4, 10), "flower_bed")
			_add_flower(object_grid, Vector2i(16, 10), "flower_bed")
		19:
			level_name = "O Oásis Multicolorido"
			width = 20; height = 20; time_limit = 125.0
			spawn_cell = Vector2i(10, 10)
			_add_star_island(terrain_grid, 10, 10, 8, 4)
			_add_grass_circle(vector_field, "grass_green", 10, 10, width, height, 2.2)
			_add_grass_ring(vector_field, "grass_blue", 10, 10, width, height, 2.2, 3.6)
			_add_grass_ring(vector_field, "grass_purple", 10, 10, width, height, 3.6, 5.0)
			_add_grass_ring(vector_field, "grass_black", 10, 10, width, height, 5.0, 6.2)
			# 5 rochas em pentágono aberto
			_add_rock(object_grid, Vector2i(10, 4))
			_add_rock(object_grid, Vector2i(15, 7))
			_add_rock(object_grid, Vector2i(13, 14))
			_add_rock(object_grid, Vector2i(7, 14))
			_add_rock(object_grid, Vector2i(5, 7))
			# Flores nobres salpicadas
			_add_flower(object_grid, Vector2i(10, 3), "flower_rose")
			_add_flower(object_grid, Vector2i(16, 6), "flower_bell")
			_add_flower(object_grid, Vector2i(14, 15), "flower_sunflower")
			_add_flower(object_grid, Vector2i(6, 15), "flower_tulip")
			_add_flower(object_grid, Vector2i(4, 6), "flower_corolla")
		20:
			level_name = "Arquipélago da Maestria"
			width = 22; height = 22; time_limit = 135.0
			spawn_cell = Vector2i(11, 11)
			_add_clover_island(terrain_grid, 11, 11, 9)
			_add_grass_circle(vector_field, "grass_yellow", 11, 11, width, height, 2.6)
			_add_grass_ring(vector_field, "grass_white", 11, 11, width, height, 2.6, 4.0)
			_add_grass_ring(vector_field, "grass_green", 11, 11, width, height, 4.0, 7.5)
			# 6 rochas em gargalos estratégicos
			_add_rock(object_grid, Vector2i(11, 6))
			_add_rock(object_grid, Vector2i(11, 16))
			_add_rock(object_grid, Vector2i(6, 11))
			_add_rock(object_grid, Vector2i(16, 11))
			_add_rock(object_grid, Vector2i(7, 7))
			_add_rock(object_grid, Vector2i(15, 15))
			# Trigo e flores nas extremidades
			_add_wheat_line(object_grid, [
				Vector2i(11, 4), Vector2i(11, 5), Vector2i(11, 17), Vector2i(11, 18),
				Vector2i(4, 11), Vector2i(5, 11), Vector2i(17, 11), Vector2i(18, 11)
			])
			_add_flower(object_grid, Vector2i(11, 3), "flower_tulip")
			_add_flower(object_grid, Vector2i(11, 19), "flower_tulip")
			_add_flower(object_grid, Vector2i(3, 11), "flower_corolla")
			_add_flower(object_grid, Vector2i(19, 11), "flower_corolla")

	# Autotile nas células da ilha
	IslandAutotiler.apply_autotile(terrain_grid)

	# Validações estritas de segurança antes de salvar:
	_validate_level(lvl, level_name, spawn_cell, object_grid, width, height)

	# Salva o arquivo JSON v3
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

	if ok:
		print("Nível %02d salvo: '%s' (grid %dx%d, time %.1fs)" % [lvl, level_name, width, height, time_limit])
	else:
		printerr("FALHA ao salvar nível %02d!" % lvl)

# --- Métodos de Validação ---
func _validate_level(lvl: int, lvl_name: String, spawn_cell: Vector2i, object_grid: Dictionary, width: int, height: int) -> void:
	var sp_pos: Vector3 = LevelJsonLoader.grid_to_world(spawn_cell.x, spawn_cell.y, width, height, CELL_SIZE)
	var rocks: Array[Vector3] = []

	for cell_key: Variant in object_grid.keys():
		var cell: Vector2i = cell_key as Vector2i
		var obj: Dictionary = object_grid[cell] as Dictionary
		var o_type: String = String(obj.get("type", ""))
		var o_pos: Vector3 = LevelJsonLoader.grid_to_world(cell.x, cell.y, width, height, CELL_SIZE)
		var dist_to_spawn: float = Vector2(o_pos.x - sp_pos.x, o_pos.z - sp_pos.z).length()

		# Regra 1: Spawn Seguro Central >= 1.47m
		if dist_to_spawn < MIN_SPAWN_CLEAR_DIST:
			printerr("[ERRO LVL %d] Objeto rígido '%s' em %s colide com o spawn! dist = %.2fm < 1.47m" % [lvl, o_type, str(cell), dist_to_spawn])

		# Fases 1 a 5 não podem ter rochas
		if lvl <= 5 and o_type == "rock":
			printerr("[ERRO LVL %d] Rocha proibida em fases <= 5!" % lvl)

		if o_type == "rock":
			rocks.append(o_pos)

	# Regra 2: Distância entre rochas > 2.80m
	for i in range(rocks.size()):
		for j in range(i + 1, rocks.size()):
			var dist: float = Vector2(rocks[i].x - rocks[j].x, rocks[i].z - rocks[j].z).length()
			if dist < MIN_ROCK_SPACING - 0.001:
				printerr("[ERRO LVL %d] Rochas muito próximas! dist = %.2fm < 2.80m" % [lvl, dist])

# --- Geradores de Ilhas Geométricas ---
func _add_rect_island(grid: Dictionary, x0: int, z0: int, w: int, h: int) -> void:
	for x in range(x0, x0 + w):
		for z in range(z0, z0 + h):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_chamfered_rect_island(grid: Dictionary, x0: int, z0: int, w: int, h: int, chamfer: int) -> void:
	for x in range(x0, x0 + w):
		for z in range(z0, z0 + h):
			var dx: int = min(x - x0, (x0 + w - 1) - x)
			var dz: int = min(z - z0, (z0 + h - 1) - z)
			if dx + dz >= chamfer:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_octagon_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void:
	for x in range(cx - radius, cx + radius + 1):
		for z in range(cz - radius, cz + radius + 1):
			var dx: int = abs(x - cx)
			var dz: int = abs(z - cz)
			if dx <= radius and dz <= radius and (dx + dz) <= radius + 2:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_hexagon_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void:
	for x in range(cx - radius, cx + radius + 1):
		for z in range(cz - radius, cz + radius + 1):
			var dx: float = float(x - cx)
			var dz: float = float(z - cz) * 1.15
			if dx * dx + dz * dz <= float(radius * radius):
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_cross_island(grid: Dictionary, cx: int, cz: int, arm_len: int, arm_w: int) -> void:
	var hw: int = int(arm_w / 2)
	for x in range(cx - arm_len, cx + arm_len + 1):
		for z in range(cz - hw, cz + hw + 1):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	for z in range(cz - arm_len, cz + arm_len + 1):
		for x in range(cx - hw, cx + hw + 1):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_u_island(grid: Dictionary, width: int, height: int) -> void:
	# Base horizontal
	for x in range(4, 15):
		for z in range(10, 14):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Braço esquerdo
	for x in range(4, 8):
		for z in range(3, 10):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Braço direito
	for x in range(11, 15):
		for z in range(3, 10):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_bridge_island(grid: Dictionary, width: int, height: int) -> void:
	# Ilha oeste
	for x in range(2, 8):
		for z in range(3, 9):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Ilha leste
	for x in range(12, 18):
		for z in range(3, 9):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Ponte/istmo
	for x in range(8, 12):
		for z in range(5, 8):
			grid[Vector2i(x, z)] = { "tile_id": "island_dirt", "rot": 0, "auto": true }

func _add_irregular_circle_island(grid: Dictionary, cx: int, cz: int, radius: float) -> void:
	for x in range(int(cx - radius - 1), int(cx + radius + 2)):
		for z in range(int(cz - radius - 1), int(cz + radius + 2)):
			var dx: float = float(x - cx)
			var dz: float = float(z - cz)
			var dist: float = sqrt(dx * dx + dz * dz)
			var angle: float = atan2(dz, dx)
			var noise_r: float = radius + sin(angle * 5.0) * 0.4
			if dist <= noise_r:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_h_island(grid: Dictionary, width: int, height: int) -> void:
	# Avenida oeste
	for x in range(4, 8):
		for z in range(2, 14):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Avenida leste
	for x in range(12, 16):
		for z in range(2, 14):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }
	# Conexão central
	for x in range(8, 12):
		for z in range(6, 10):
			grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_diamond_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void:
	for x in range(cx - radius, cx + radius + 1):
		for z in range(cz - radius, cz + radius + 1):
			var dx: int = abs(x - cx)
			var dz: int = abs(z - cz)
			if dx + dz <= radius:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_star_island(grid: Dictionary, cx: int, cz: int, outer_r: int, inner_r: int) -> void:
	_add_diamond_island(grid, cx, cz, outer_r)
	_add_rect_island(grid, cx - inner_r, cz - inner_r, inner_r * 2 + 1, inner_r * 2 + 1)

func _add_clover_island(grid: Dictionary, cx: int, cz: int, radius: int) -> void:
	# Centro
	_add_rect_island(grid, cx - 3, cz - 3, 7, 7)
	# 4 pétalas
	_add_circle_island(grid, cx, cz - 5, 4.0)
	_add_circle_island(grid, cx, cz + 5, 4.0)
	_add_circle_island(grid, cx - 5, cz, 4.0)
	_add_circle_island(grid, cx + 5, cz, 4.0)

func _add_circle_island(grid: Dictionary, cx: int, cz: int, radius: float) -> void:
	for x in range(int(cx - radius - 1), int(cx + radius + 2)):
		for z in range(int(cz - radius - 1), int(cz + radius + 2)):
			var dx: float = float(x - cx)
			var dz: float = float(z - cz)
			if dx * dx + dz * dz <= radius * radius:
				grid[Vector2i(x, z)] = { "tile_id": "island_center", "rot": 0, "auto": true }

func _add_dirt_cross(grid: Dictionary, cx: int, cz: int, x0: int, z0: int, w: int, h: int) -> void:
	for x in range(x0, x0 + w):
		grid[Vector2i(x, cz)] = { "tile_id": "island_dirt", "rot": 0, "auto": true }
	for z in range(z0, z0 + h):
		grid[Vector2i(cx, z)] = { "tile_id": "island_dirt", "rot": 0, "auto": true }

# --- Helpers de Vegetação Vetorial ---
func _add_grass_circle(vf: RefCounted, type_name: String, gx: int, gz: int, width: int, height: int, radius: float) -> void:
	var center3: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, CELL_SIZE)
	_add_grass_circle_world(vf, type_name, Vector2(center3.x, center3.z), radius)

func _add_grass_circle_world(vf: RefCounted, type_name: String, center: Vector2, radius: float) -> void:
	var poly: PackedVector2Array = PackedVector2Array()
	var segs: int = 24
	for i in range(segs):
		var a: float = float(i) * TAU / float(segs)
		poly.append(center + Vector2(cos(a), sin(a)) * radius)
	vf.call("add_shape", type_name, poly)

func _add_grass_ring(vf: RefCounted, type_name: String, gx: int, gz: int, width: int, height: int, r_in: float, r_out: float) -> void:
	var center3: Vector3 = LevelJsonLoader.grid_to_world(gx, gz, width, height, CELL_SIZE)
	var center: Vector2 = Vector2(center3.x, center3.z)
	var outer: PackedVector2Array = PackedVector2Array()
	var inner: PackedVector2Array = PackedVector2Array()
	var segs: int = 24
	for i in range(segs):
		var a: float = float(i) * TAU / float(segs)
		outer.append(center + Vector2(cos(a), sin(a)) * r_out)
		inner.append(center + Vector2(cos(a), sin(a)) * r_in)
	vf.call("add_shape", type_name, outer, [inner])

func _add_grass_rect(vf: RefCounted, type_name: String, gx0: int, gz0: int, gx1: int, gz1: int, width: int, height: int) -> void:
	var p0: Vector3 = LevelJsonLoader.grid_to_world(gx0, gz0, width, height, CELL_SIZE)
	var p1: Vector3 = LevelJsonLoader.grid_to_world(gx1, gz1, width, height, CELL_SIZE)
	var min_x: float = min(p0.x, p1.x) - CELL_SIZE * 0.4
	var max_x: float = max(p0.x, p1.x) + CELL_SIZE * 0.4
	var min_z: float = min(p0.z, p1.z) - CELL_SIZE * 0.4
	var max_z: float = max(p0.z, p1.z) + CELL_SIZE * 0.4
	var poly: PackedVector2Array = PackedVector2Array([
		Vector2(min_x, min_z),
		Vector2(max_x, min_z),
		Vector2(max_x, max_z),
		Vector2(min_x, max_z)
	])
	vf.call("add_shape", type_name, poly)

func _add_diagonal_stripes(vf: RefCounted, width: int, height: int, types: Array[String], stripe_w: float) -> void:
	# Cobre a área da ilha em listras diagonais intersectadas com o retângulo útil da ilha
	var max_extent: float = float(min(width, height) - 4) * CELL_SIZE * 0.5
	var island_rect := PackedVector2Array([
		Vector2(-max_extent, -max_extent),
		Vector2(max_extent, -max_extent),
		Vector2(max_extent, max_extent),
		Vector2(-max_extent, max_extent)
	])
	var span: float = max_extent * 2.5
	var cur: float = -span
	var idx: int = 0
	var t_count: int = types.size()
	while cur < span:
		var next_cur: float = cur + stripe_w
		var t_name: String = types[idx % t_count]
		var p_strip: PackedVector2Array = PackedVector2Array([
			Vector2(cur - span, span),
			Vector2(next_cur - span, span),
			Vector2(span, -next_cur + span),
			Vector2(span, -cur + span)
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
	for item in cells:
		var c: Vector2i = item as Vector2i
		grid[c] = { "type": "wheat", "rot": 0 }

func _add_flower(grid: Dictionary, cell: Vector2i, flower_type: String) -> void:
	grid[cell] = { "type": flower_type, "rot": 0 }
