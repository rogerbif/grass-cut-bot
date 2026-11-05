extends Node

const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const LevelEditorUIScript = preload("res://scripts/editor/level_editor_ui.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

func _ready() -> void:
	print("==================================================")
	print("🧪 TESTES AUTOMATIZADOS: VARIAÇÕES DE FLORES (SILVESTRE & ROSA)")
	print("==================================================")

	# 1. Validação do TilePaletteDB para 'flower' e 'flower_rose'
	assert(TilePaletteDB.has_variations("flower"), "flower deve ter variações")
	assert(TilePaletteDB.has_variations("flower_rose"), "flower_rose deve ter variações")
	assert(not TilePaletteDB.has_variations("rock"), "rock não deve ter variações")
	assert(not TilePaletteDB.has_variations("flower_daisy"), "flower_daisy não deve ter variações")

	var vars_flower: Array = TilePaletteDB.get_variations("flower")
	assert(vars_flower.size() == 6, "flower deve conter 6 variações")
	print("  [OK] TilePaletteDB tem 6 variações registradas para 'flower'")

	var vars_rose: Array = TilePaletteDB.get_variations("flower_rose")
	assert(vars_rose.size() == 7, "flower_rose deve conter 7 variações")
	print("  [OK] TilePaletteDB tem 7 variações registradas para 'flower_rose'")

	assert(TilePaletteDB.get_base_id_for_variant("flower") == "flower")
	assert(TilePaletteDB.get_base_id_for_variant("flower_blue") == "flower")
	assert(TilePaletteDB.get_base_id_for_variant("flower_rose") == "flower_rose")
	assert(TilePaletteDB.get_base_id_for_variant("flower_rose_white") == "flower_rose")
	assert(TilePaletteDB.get_base_id_for_variant("flower_rose_yellow") == "flower_rose")
	assert(TilePaletteDB.get_base_id_for_variant("flower_rose_blue") == "flower_rose")
	assert(TilePaletteDB.get_base_id_for_variant("flower_rose_wine") == "flower_rose")
	assert(TilePaletteDB.get_base_id_for_variant("flower_rose_black") == "flower_rose")
	assert(TilePaletteDB.get_base_id_for_variant("flower_rose_peach") == "flower_rose")
	assert(TilePaletteDB.get_base_id_for_variant("rock") == "rock")
	print("  [OK] get_base_id_for_variant mapeia corretamente todas as variações para suas espécies")

	# 2. Validação da UI do Editor
	var ui: Control = LevelEditorUIScript.new()
	add_child(ui)

	# Simula seleção de 'flower_rose' na camada de objetos (layer 2)
	ui.call(
		"sync_state",
		2, # active_layer: OBJECTS
		0, # active_tool: BRUSH
		0, # active_shape: SINGLE
		1, # brush_size
		0, # rot_deg
		"island_center", # terrain_id
		"grass_green",   # grass_id
		"flower_rose",   # active_object_id
		false            # is_top_down
	)

	var dock: PanelContainer = ui.get("panel_variations_dock") as PanelContainer
	assert(dock != null, "panel_variations_dock deve existir")
	assert(dock.visible, "panel_variations_dock deve estar visível quando flower_rose está selecionada")

	var lbl_title: Label = ui.get("lbl_variations_title") as Label
	assert(lbl_title != null and lbl_title.text.contains("ROSA"), "Título do dock deve indicar ROSA")

	var var_buttons: Dictionary = ui.get("variation_buttons") as Dictionary
	assert(var_buttons.size() == 7, "variation_buttons deve conter 7 botões de variação da rosa")
	assert(var_buttons.has("flower_rose"), "deve conter botão para 'flower_rose'")
	assert(var_buttons.has("flower_rose_white"), "deve conter botão para 'flower_rose_white'")
	assert(var_buttons.has("flower_rose_blue"), "deve conter botão para 'flower_rose_blue'")
	assert(var_buttons.has("flower_rose_wine"), "deve conter botão para 'flower_rose_wine'")
	print("  [OK] Dock de variações da Rosa visível e populado com 7 cards dedicados")

	# Testa seleção do card 'flower_rose_white'
	var received_obj: Array[String] = []
	ui.connect("object_item_selected", func(o_id: String) -> void:
		received_obj.append(o_id)
	)

	var btn_white: Button = var_buttons["flower_rose_white"] as Button
	btn_white.emit_signal("pressed")
	assert(received_obj.size() == 1 and received_obj[0] == "flower_rose_white", "clicar no card deve emitir object_item_selected('flower_rose_white')")

	ui.call(
		"sync_state",
		2,
		0,
		0,
		1,
		0,
		"island_center",
		"grass_green",
		"flower_rose_white",
		false
	)
	assert(dock.visible, "dock deve continuar visível para 'flower_rose_white'")
	print("  [OK] Seleção do card 'flower_rose_white' mantém o dock ativo")

	# Testa se ao mudar para 'rock', o dock se esconde
	ui.call(
		"sync_state",
		2,
		0,
		0,
		1,
		0,
		"island_center",
		"grass_green",
		"rock",
		false
	)
	assert(not dock.visible, "dock deve ficar invisível quando 'rock' é selecionado")
	print("  [OK] Dock fica invisível para outros objetos (ex: rock)")

	# 3. Validação do LevelJsonLoader e materiais para todas as variações de rosa
	for v_item: Variant in vars_rose:
		var vd: Dictionary = v_item as Dictionary
		var vid: String = String(vd["id"])
		var node: Node3D = LevelJsonLoader.instantiate_object_node(vid, 0)
		assert(node != null, "LevelJsonLoader deve instanciar %s" % vid)
		var custom_mat: Variant = node.get("custom_material")
		assert(custom_mat != null, "Node %s deve ter custom_material configurado" % vid)
		assert(custom_mat is ShaderMaterial, "custom_material de %s deve ser ShaderMaterial" % vid)
		node.free()

	print("  [OK] LevelJsonLoader instancia corretamente todas as 7 variações da rosa com ShaderMaterial")

	# 4. Validação do VegetationGridScript para as rosas
	for v_item: Variant in vars_rose:
		var vd: Dictionary = v_item as Dictionary
		var vid: String = String(vd["id"])
		assert(VegetationGridScript.FLOWER_MATERIALS.has(vid), "VegetationGrid deve ter material para %s" % vid)
		assert(VegetationGridScript.VEG_TYPES.has(vid), "VegetationGrid deve ter tipo registrado para %s" % vid)

	print("  [OK] VegetationGrid possui materiais e tipos GPU instanciados para todas as 7 variações da rosa")

	# 5. Validação das Metas Separadas e Contagem no Editor (sem misturar com Flor Silvestre)
	var test_object_grid: Dictionary = {
		Vector2i(0, 0): { "type": "flower_rose", "rot": 0 },
		Vector2i(1, 0): { "type": "flower_rose_white", "rot": 0 },
		Vector2i(2, 0): { "type": "flower_rose_yellow", "rot": 0 },
		Vector2i(3, 0): { "type": "flower_rose_blue", "rot": 0 },
		Vector2i(4, 0): { "type": "flower_rose_wine", "rot": 0 },
		Vector2i(5, 0): { "type": "flower_rose_black", "rot": 0 },
		Vector2i(6, 0): { "type": "flower_rose_peach", "rot": 0 }
	}
	ui.update_goals_summary(100, test_object_grid, null, null)

	var detected_counts: Dictionary = ui.get("_last_detected_counts") as Dictionary
	assert(detected_counts.get("flower", 0) == 0, "Flor Silvestre NÃO deve ser contabilizada para rosas (deve ser 0)")
	assert(detected_counts.get("flower_rose", 0) == 1, "flower_rose deve ter 1")
	assert(detected_counts.get("flower_rose_white", 0) == 1, "flower_rose_white deve ter 1")
	assert(detected_counts.get("flower_rose_yellow", 0) == 1, "flower_rose_yellow deve ter 1")
	assert(detected_counts.get("flower_rose_blue", 0) == 1, "flower_rose_blue deve ter 1")
	assert(detected_counts.get("flower_rose_wine", 0) == 1, "flower_rose_wine deve ter 1")
	assert(detected_counts.get("flower_rose_black", 0) == 1, "flower_rose_black deve ter 1")
	assert(detected_counts.get("flower_rose_peach", 0) == 1, "flower_rose_peach deve ter 1")

	var goal_cards: Dictionary = ui.get("_goal_cards") as Dictionary
	var flower_card: PanelContainer = goal_cards.get("flower") as PanelContainer
	assert(flower_card != null and not flower_card.visible, "Card de Flor Silvestre deve estar oculto")

	for r_id in ["flower_rose", "flower_rose_white", "flower_rose_yellow", "flower_rose_blue", "flower_rose_wine", "flower_rose_black", "flower_rose_peach"]:
		var r_card: PanelContainer = goal_cards.get(r_id) as PanelContainer
		assert(r_card != null and r_card.visible, "Card de meta para %s deve estar visível" % r_id)

	print("  [OK] Metas das 7 variações de rosa separadas com sucesso e 0 contagem indevida de Flor Silvestre!")

	ui.queue_free()
	print("==========================================")
	print("✅ TODOS OS TESTES DE VARIAÇÃO DA ROSA PASSARAM COM SUCESSO! (0 falhas)")
	print("==========================================")
	get_tree().quit(0)
