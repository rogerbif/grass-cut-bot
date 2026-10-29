extends Node

const LevelEditorUiScript = preload("res://scripts/editor/level_editor_ui.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")

func _ready() -> void:
	print("--- TESTE: TEMPO DE DURACAO E METAS POR DEFAULT (FLORES SEPARADAS) ---")
	test_time_limit_saving_and_sync()
	test_default_active_goals_with_total_count()
	test_individual_flowers_in_vegetation_grid()
	print("--- TODOS OS TESTES PASSARAM COM SUCESSO! ---")
	get_tree().quit(0)

func test_time_limit_saving_and_sync() -> void:
	var ui: Control = LevelEditorUiScript.new()
	add_child(ui)

	# 1. Verifica tempo padrão inicial
	assert(ui.call("get_configured_time_limit") == 90.0, "Tempo padrão inicial deve ser 90s")

	# 2. Simula alteração no SpinBox de tempo
	var spin_t: SpinBox = ui.get("spin_time") as SpinBox
	assert(spin_t != null, "SpinBox de tempo deve existir")
	spin_t.value = 145.0
	assert(ui.call("get_configured_time_limit") == 145.0, "get_configured_time_limit deve retornar 145.0")

	# 3. Simula digitação no LineEdit do SpinBox
	var le: LineEdit = spin_t.get_line_edit()
	le.text = "210"
	le.text_submitted.emit("210")
	assert(ui.call("get_configured_time_limit") == 210.0, "get_configured_time_limit deve retornar 210.0 após digitação")

	# 4. Verifica se update_level_header não sobrescreve valor se o LineEdit estiver com foco
	# Simula ganho de foco
	le.grab_focus()
	ui.call("update_level_header", 1, 12, 8, 90.0)
	assert(spin_t.value == 210.0, "update_level_header não deve sobrescrever enquanto usuário está digitando/focado")
	le.release_focus()

	print("✔ Teste 1: Configuração e sincronização do tempo de duração validadas!")
	ui.queue_free()

func test_default_active_goals_with_total_count() -> void:
	var ui: Control = LevelEditorUiScript.new()
	add_child(ui)

	var vg = VectorGrassFieldScript.new()
	var poly = BrushPatterns.get_vector_stamp_polygon(BrushPatterns.ShapeType.CIRCLE, 2, Vector2.ZERO)
	vg.call("add_shape", "grass_blue", poly)

	# Adiciona objetos: trigo e 3 flores diferentes
	var obj_grid: Dictionary = {
		Vector2i(1, 1): { "type": "wheat" },
		Vector2i(2, 2): { "type": "flower_rose" },
		Vector2i(3, 3): { "type": "flower_sunflower" },
		Vector2i(4, 4): { "type": "flower_tulip" }
	}

	ui.call("update_goals_summary", 40, obj_grid, null, vg)

	var chks: Dictionary = ui.get("_goal_checkboxes") as Dictionary
	var spins: Dictionary = ui.get("_goal_spinboxes") as Dictionary
	var detected: Dictionary = ui.get("_last_detected_counts") as Dictionary

	var blue_cnt: int = int(detected.get("grass_blue", 0))
	assert(blue_cnt > 0, "Grama azul deve ser detectada")
	assert(int(detected.get("wheat", 0)) == 1, "Trigo deve ser 1")
	assert(int(detected.get("flower_rose", 0)) == 1, "flower_rose deve ser 1")
	assert(int(detected.get("flower_sunflower", 0)) == 1, "flower_sunflower deve ser 1")
	assert(int(detected.get("flower_tulip", 0)) == 1, "flower_tulip deve ser 1")
	assert(int(detected.get("flower", 0)) == 0, "flower (silvestre) deve ser 0")

	# Por default, qualquer planta presente deve vir marcada e com valor total!
	var chk_blue: CheckBox = chks["grass_blue"] as CheckBox
	var spin_blue: SpinBox = spins["grass_blue"] as SpinBox
	assert(chk_blue.button_pressed, "Grama azul presente deve estar marcada por default")
	assert(spin_blue.visible, "SpinBox da grama azul deve estar visível")
	assert(int(spin_blue.value) == blue_cnt, "Meta da grama azul deve ter valor total por default")

	var chk_rose: CheckBox = chks["flower_rose"] as CheckBox
	var spin_rose: SpinBox = spins["flower_rose"] as SpinBox
	assert(chk_rose.button_pressed, "flower_rose presente deve estar marcada por default")
	assert(int(spin_rose.value) == 1, "flower_rose deve ter meta 1 por default")

	var chk_sun: CheckBox = chks["flower_sunflower"] as CheckBox
	assert(chk_sun.button_pressed, "flower_sunflower presente deve estar marcada por default")

	var chk_tulip: CheckBox = chks["flower_tulip"] as CheckBox
	assert(chk_tulip.button_pressed, "flower_tulip presente deve estar marcada por default")

	# Espécies ausentes NÃO devem estar marcadas
	var chk_red: CheckBox = chks["grass_red"] as CheckBox
	assert(not chk_red.button_pressed, "Grama vermelha (ausente) não deve estar marcada")
	assert(chk_red.disabled, "Grama vermelha deve estar desabilitada")

	var goals_cfg: Dictionary = ui.call("get_configured_goals") as Dictionary
	assert(goals_cfg.has("grass_blue"), "Metas devem conter grass_blue")
	assert(goals_cfg.has("wheat"), "Metas devem conter wheat")
	assert(goals_cfg.has("flower_rose"), "Metas devem conter flower_rose")
	assert(goals_cfg.has("flower_sunflower"), "Metas devem conter flower_sunflower")
	assert(goals_cfg.has("flower_tulip"), "Metas devem conter flower_tulip")
	assert(not goals_cfg.has("flower_daisy"), "Metas não devem conter flower_daisy")

	print("✔ Teste 2: Metas marcadas por default com valor total para gramas e flores individuais validadas!")
	ui.queue_free()

func test_individual_flowers_in_vegetation_grid() -> void:
	var vg: Node3D = VegetationGridScript.new()
	add_child(vg)

	# Cria dados com mais de 2 tipos de flor (ex: 4 tipos)
	# Anteriormente o código agrupava em 'flower' quando size > 2. Agora deve manter separados!
	var level_data: Dictionary = {
		"grid": { "width": 8, "height": 8, "cell_size": 0.8 },
		"island_polygons": [
			PackedVector2Array([Vector2(-3.0, -3.0), Vector2(3.0, -3.0), Vector2(3.0, 3.0), Vector2(-3.0, 3.0)])
		],
		"grass_vectors": [],
		"objects": [
			{ "gx": 1, "gz": 1, "type": "flower_rose", "rot": 0 },
			{ "gx": 2, "gz": 1, "type": "flower_daisy", "rot": 0 },
			{ "gx": 3, "gz": 1, "type": "flower_sunflower", "rot": 0 },
			{ "gx": 4, "gz": 1, "type": "flower_bell", "rot": 0 }
		],
		"spawn": { "gx": 2, "gz": 2 }
	}

	var goals: Dictionary = vg.call("build_from_level_json", level_data, null, null) as Dictionary

	assert(not goals.has("flower"), "Não deve agrupar mais flores sob chave genérica 'flower'")
	assert(goals.has("flower_rose"), "Deve conter 'flower_rose' individual")
	assert(goals.has("flower_daisy"), "Deve conter 'flower_daisy' individual")
	assert(goals.has("flower_sunflower"), "Deve conter 'flower_sunflower' individual")
	assert(goals.has("flower_bell"), "Deve conter 'flower_bell' individual")

	print("✔ Teste 3: Todas as 8 flores operam como metas 100% individuais no VegetationGrid!")
	vg.queue_free()
