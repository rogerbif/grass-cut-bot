extends Node

const LevelEditorUiScript = preload("res://scripts/editor/level_editor_ui.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")

func _ready() -> void:
	print("--- TESTE AUTOMATIZADO: METAS POR COR DE GRAMA E PAINEL DO EDITOR ---")
	test_goals_ui_separation_and_constraints()
	test_vegetation_grid_custom_goals()
	print("--- TODOS OS TESTES PASSARAM COM SUCESSO! ---")
	get_tree().quit(0)

func test_goals_ui_separation_and_constraints() -> void:
	var ui = LevelEditorUiScript.new()
	add_child(ui)

	# 1. Verifica se todos os itens de GOALS_CATALOG foram criados
	var catalog: Array = LevelEditorUiScript.GOALS_CATALOG
	assert(catalog.size() == 16, "Devem existir 16 itens no catálogo de metas (7 cores de grama + trigo + 8 flores)")

	var chks: Dictionary = ui.get("_goal_checkboxes") as Dictionary
	var totals: Dictionary = ui.get("_goal_total_labels") as Dictionary
	var spins: Dictionary = ui.get("_goal_spinboxes") as Dictionary

	for gm in catalog:
		var k: String = String(gm["key"])
		assert(chks.has(k), "Checkbox para %s deve existir" % k)
		assert(totals.has(k), "Label de total para %s deve existir" % k)
		assert(spins.has(k), "SpinBox para %s deve existir" % k)
		# Inicialmente desmarcado e spinbox fechado (oculto)
		var spin: SpinBox = spins[k] as SpinBox
		assert(not spin.visible, "Spinbox de %s deve iniciar fechado/oculto" % k)

	print("✔ Todos os 16 tipos de metas criados e inicializados com SpinBox fechado")

	# 2. Simula contagem de campo: 248 green, 244 blue, 28 purple, 8 wheat, 4 flowers, 0 yellow
	var vg = VectorGrassFieldScript.new()
	var poly = BrushPatterns.get_vector_stamp_polygon(BrushPatterns.ShapeType.CIRCLE, 2, Vector2.ZERO)
	vg.call("add_shape", "grass_green", poly)
	vg.call("add_shape", "grass_blue", poly)
	vg.call("add_shape", "grass_purple", poly)

	var obj_grid: Dictionary = {
		Vector2i(1, 1): { "type": "wheat" },
		Vector2i(2, 2): { "type": "flower_rose" }
	}

	ui.call("update_goals_summary", 50, obj_grid, null, vg)

	var last_detected: Dictionary = ui.get("_last_detected_counts") as Dictionary
	var green_count: int = int(last_detected.get("grass_green", 0))
	var yellow_count: int = int(last_detected.get("grass_yellow", 0))
	var wheat_count: int = int(last_detected.get("wheat", 0))
	var rose_count: int = int(last_detected.get("flower_rose", 0))

	assert(green_count > 0, "Grama verde deve ser detectada (>0)")
	assert(yellow_count == 0, "Grama amarela deve ter 0 tufos detectados")
	assert(wheat_count == 1, "Trigo deve ter 1 detectado")
	assert(rose_count == 1, "Rosa Nobre deve ter 1 detectada individualmente")

	# Verifica se item com 0 tufos desativa o checkbox
	var chk_yellow: CheckBox = chks["grass_yellow"] as CheckBox
	assert(chk_yellow.disabled, "Grama amarela com 0 tufos deve ter checkbox desabilitado")

	# 3. Testa ativação como meta e abertura do campo (SpinBox)
	var chk_green: CheckBox = chks["grass_green"] as CheckBox
	var spin_green: SpinBox = spins["grass_green"] as SpinBox
	assert(not chk_green.disabled, "Grama verde com tufos deve ter checkbox habilitado")
	assert(chk_green.button_pressed, "Grama verde presente deve vir marcada por padrão")
	assert(spin_green.visible, "Ao estar ativa como meta por padrão, o SpinBox deve abrir (visible=true)")
	assert(spin_green.min_value == 1, "Valor mínimo do SpinBox deve ser 1 (não pode ser zero ou negativo)")
	assert(spin_green.max_value == green_count, "Valor máximo deve ser igual ao total de tufos na fase (%d)" % green_count)
	assert(spin_green.value == green_count, "Valor padrão deve ser o total de tufos (%d)" % green_count)

	# 4. Testa restrições de edição: não pode exceder total e não pode ser <= 0
	spin_green.value = green_count + 500
	assert(spin_green.value == green_count, "Valor que excede o total deve ser clamped para max_value (%d), obtido: %f" % [green_count, spin_green.value])

	spin_green.value = 0
	assert(spin_green.value == 1, "Valor zero deve ser clamped para 1 (não pode ser zero ou negativo), obtido: %f" % spin_green.value)

	spin_green.value = -50
	assert(spin_green.value == 1, "Valor negativo deve ser clamped para 1, obtido: %f" % spin_green.value)

	# Valor válido menor que total
	var valid_val: int = maxi(1, int(green_count / 2))
	spin_green.value = valid_val
	assert(spin_green.value == valid_val, "Valor válido entre 1 e total deve ser aceito")

	# 5. Testa desativação: fechamento do campo
	chk_green.button_pressed = false
	assert(not spin_green.visible, "Ao desativar meta, o campo deve fechar (visible=false)")

	# 6. Testa get_configured_goals e set_configured_goals
	chk_green.button_pressed = true
	spin_green.value = valid_val
	var goals_res: Dictionary = ui.call("get_configured_goals") as Dictionary
	assert(goals_res.has("grass_green"), "Metas configuradas devem conter grass_green")
	assert(int(goals_res["grass_green"]) == valid_val, "Meta configurada deve ser %d" % valid_val)
	assert(not goals_res.has("grass_yellow"), "Metas configuradas NÃO devem conter grass_yellow desativada")

	# Salva e recarrega metas configuradas
	var custom_cfg: Dictionary = {
		"grass_green": 10,
		"wheat": 1
	}
	ui.call("set_configured_goals", custom_cfg)
	assert(chk_green.button_pressed, "grass_green deve estar marcado após set_configured_goals")
	assert(spin_green.visible, "spin_green deve estar visível")
	assert(int(spin_green.value) == 10, "spin_green deve ter valor 10")

	var chk_wheat: CheckBox = chks["wheat"] as CheckBox
	var spin_wheat: SpinBox = spins["wheat"] as SpinBox
	assert(chk_wheat.button_pressed, "wheat deve estar marcado")
	assert(spin_wheat.visible, "spin_wheat deve estar visível")
	assert(int(spin_wheat.value) == 1, "spin_wheat deve ter valor 1")

	print("✔ Teste de UI: Separação por cor, ativação, exibição de tufos e restrições de edição validadas!")
	ui.queue_free()

func test_vegetation_grid_custom_goals() -> void:
	var vg: Node3D = VegetationGridScript.new()
	add_child(vg)

	var dummy_level_data: Dictionary = {
		"grid": { "width": 8, "height": 8, "cell_size": 0.8 },
		"island_polygons": [
			PackedVector2Array([Vector2(-2.0, -2.0), Vector2(2.0, -2.0), Vector2(2.0, 2.0), Vector2(-2.0, 2.0)])
		],
		"grass_vectors": [
			{
				"id": 1,
				"type": "grass_green",
				"polygon": [
					[-1.5, -1.5], [1.5, -1.5], [1.5, 1.5], [-1.5, 1.5]
				]
			}
		],
		"objects": [],
		"spawn": { "gx": 4, "gz": 4 },
		"goals": {
			"grass_green": 15
		}
	}

	var goals: Dictionary = vg.call("build_from_level_json", dummy_level_data, null, null) as Dictionary
	assert(vg.get("_has_custom_goals") == true, "_has_custom_goals deve ser true para nível com metas personalizadas")
	assert(goals.has("grass_green"), "goals deve conter grass_green")
	assert(int(goals["grass_green"]) == 15, "grass_green deve ter meta 15")

	print("✔ VegetationGrid: Detecção e processamento de metas personalizadas 1:1 validados!")
	vg.queue_free()
