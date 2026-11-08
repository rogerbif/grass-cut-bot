extends SceneTree

const LevelEditorUiScript = preload("res://scripts/editor/level_editor_ui.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")

func _init() -> void:
	print("=== INICIANDO TESTE: CONVIVÊNCIA DE FLORES COM GRAMA E VISIBILIDADE DE METAS ===")
	var total_tests: int = 0
	var passed_tests: int = 0

	# ---------------------------------------------------------
	# Teste 1: UI do Editor - Cards com contagem 0 devem estar ocultos
	# ---------------------------------------------------------
	total_tests += 1
	var ui = LevelEditorUiScript.new()
	root.add_child(ui)
	ui.call("_build_ui")
	var goal_cards: Dictionary = ui.get("_goal_cards") as Dictionary
	assert(not goal_cards.is_empty(), "Cards de metas devem ter sido instanciados")

	# Por padrão, antes de carregar ou com contagem 0, todos os cards devem iniciar ocultos
	for k: Variant in goal_cards.keys():
		var card: PanelContainer = goal_cards[k] as PanelContainer
		assert(not card.visible, "Card de %s deve iniciar oculto quando contagem é 0" % String(k))

	# Simula campo contendo apenas grama verde e rosa amarela
	var vg = VectorGrassFieldScript.new()
	var poly = BrushPatterns.get_vector_stamp_polygon(BrushPatterns.ShapeType.CIRCLE, 2, Vector2.ZERO)
	vg.call("add_shape", "grass_green", poly)

	var obj_grid: Dictionary = {
		Vector2i(0, 0): { "type": "flower_rose_yellow", "rot": 0 }
	}

	ui.call("update_goals_summary", 20, obj_grid, null, vg)

	assert(goal_cards["grass_green"].visible == true, "Card de grama verde presente DEVE estar visível")
	assert(goal_cards["flower_rose_yellow"].visible == true, "Card de rosa amarela presente DEVE estar visível")
	assert(goal_cards["grass_blue"].visible == false, "Card de grama azul (0 tufos) DEVE estar oculto")
	assert(goal_cards["grass_yellow"].visible == false, "Card de grama amarela (0 tufos) DEVE estar oculto")
	assert(goal_cards["wheat"].visible == false, "Card de trigo (0 trigos) DEVE estar oculto")
	assert(goal_cards["flower"].visible == false, "Card de flor silvestre (0 flores) DEVE estar oculto")
	assert(goal_cards["flower_rose"].visible == false, "Card de rosa vermelha (0 rosas) DEVE estar oculto")
	assert(goal_cards["flower_daisy"].visible == false, "Card de margarida (0 margaridas) DEVE estar oculto")
	assert(goal_cards["flower_sunflower"].visible == false, "Card de girassol (0 girassóis) DEVE estar oculto")

	var lbl_no_goals: Label = ui.get("lbl_no_goals_hint") as Label
	assert(lbl_no_goals != null and not lbl_no_goals.visible, "Dica de sem objetivos deve estar oculta quando há metas")

	print("[PASS] Teste 1: Painel do editor oculta cards ausentes e exibe apenas espécies presentes")
	passed_tests += 1

	# ---------------------------------------------------------
	# Teste 2: UI do Editor - Limpeza total e exibição de dica
	# ---------------------------------------------------------
	total_tests += 1
	var empty_vg = VectorGrassFieldScript.new()
	ui.call("update_goals_summary", 0, {}, null, empty_vg)

	for k: Variant in goal_cards.keys():
		var card: PanelContainer = goal_cards[k] as PanelContainer
		assert(not card.visible, "Todos os cards devem ficar ocultos com mapa vazio: %s" % String(k))
	assert(lbl_no_goals.visible == true, "Dica informativa deve ficar visível quando não há vegetação no mapa")

	print("[PASS] Teste 2: Mapa sem vegetação oculta todos os cards e exibe aviso informativo")
	passed_tests += 1
	ui.queue_free()

	# ---------------------------------------------------------
	# Teste 3: VegetationGrid - Flores sobre a grama NÃO removem tufos de grama
	# ---------------------------------------------------------
	total_tests += 1
	var veg_grid: Node3D = VegetationGridScript.new()
	root.add_child(veg_grid)

	# Nível com polígono de grama cobrindo de -2.0 a 2.0 (4x4m)
	# E uma flor posicionada exatamente no centro (gx=2, gz=2)
	var square_grass_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-2.0, -2.0),
		Vector2(2.0, -2.0),
		Vector2(2.0, 2.0),
		Vector2(-2.0, 2.0)
	])

	# Primeiro: constrói sem flores para saber quantos tufos de grama são gerados
	var test_data_no_flower: Dictionary = {
		"grid": { "width": 5, "height": 5, "cell_size": 0.8 },
		"island_polygons": [square_grass_poly],
		"grass_vectors": [
			{
				"id": 1,
				"type": "grass_green",
				"polygon": [
					[-2.0, -2.0], [2.0, -2.0], [2.0, 2.0], [-2.0, 2.0]
				]
			}
		],
		"objects": [],
		"spawn": { "gx": 0, "gz": 0 }
	}

	var goals_no_flower: Dictionary = veg_grid.call("build_from_level_json", test_data_no_flower, null, null) as Dictionary
	var grass_count_baseline: int = int(goals_no_flower.get("grass_green", 0))
	var physical_grass_baseline: int = int(veg_grid.get("_total_physical_grass"))

	assert(grass_count_baseline > 0, "Deveria haver grama gerada no baseline")
	assert(physical_grass_baseline > 0, "Tufos físicos baseline > 0")

	# Segundo: constrói COM uma flor (rosa amarela) no centro
	var test_data_with_flower: Dictionary = {
		"grid": { "width": 5, "height": 5, "cell_size": 0.8 },
		"island_polygons": [square_grass_poly],
		"grass_vectors": [
			{
				"id": 1,
				"type": "grass_green",
				"polygon": [
					[-2.0, -2.0], [2.0, -2.0], [2.0, 2.0], [-2.0, 2.0]
				]
			}
		],
		"objects": [
			{ "gx": 2, "gz": 2, "type": "flower_rose_yellow", "rot": 0 }
		],
		"spawn": { "gx": 0, "gz": 0 }
	}

	var goals_with_flower: Dictionary = veg_grid.call("build_from_level_json", test_data_with_flower, null, null) as Dictionary
	var grass_count_with_flower: int = int(goals_with_flower.get("grass_green", 0))
	var flower_count: int = int(goals_with_flower.get("flower_rose_yellow", 0))
	var physical_grass_with_flower: int = int(veg_grid.get("_total_physical_grass"))

	assert(flower_count == 1, "Deve haver 1 rosa amarela nas metas")
	assert(grass_count_with_flower == grass_count_baseline, "Metas de grama verde NÃO devem diminuir ao colocar uma flor! Baseline: %d, Com flor: %d" % [grass_count_baseline, grass_count_with_flower])
	assert(physical_grass_with_flower == physical_grass_baseline, "Tufos físicos de grama NÃO devem ser descartados ao colocar flor! Baseline: %d, Com flor: %d" % [physical_grass_baseline, physical_grass_with_flower])

	print("[PASS] Teste 3: Tufos de grama permanecem íntegros e convivem com a flor no mesmo local")
	passed_tests += 1

	# ---------------------------------------------------------
	# Teste 4: Apenas rochas limpam a grama ao redor (raio de clareira)
	# ---------------------------------------------------------
	total_tests += 1
	var test_data_with_rock: Dictionary = {
		"grid": { "width": 5, "height": 5, "cell_size": 0.8 },
		"island_polygons": [square_grass_poly],
		"grass_vectors": [
			{
				"id": 1,
				"type": "grass_green",
				"polygon": [
					[-2.0, -2.0], [2.0, -2.0], [2.0, 2.0], [-2.0, 2.0]
				]
			}
		],
		"objects": [
			{ "gx": 2, "gz": 2, "type": "rock", "rot": 0 }
		],
		"spawn": { "gx": 0, "gz": 0 }
	}

	var goals_with_rock: Dictionary = veg_grid.call("build_from_level_json", test_data_with_rock, null, null) as Dictionary
	var physical_grass_with_rock: int = int(veg_grid.get("_total_physical_grass"))

	assert(physical_grass_with_rock < physical_grass_baseline, "Rocha DEVE recortar e limpar a grama ao redor (baseline %d -> rock %d)" % [physical_grass_baseline, physical_grass_with_rock])

	print("[PASS] Teste 4: Rocha recorta e mantém espaço limpo ao redor conforme regra canônica")
	passed_tests += 1

	veg_grid.queue_free()

	print("\n>>> SUCESSO: Todos os %d testes passaram com êxito! <<<" % passed_tests)
	quit(0)
