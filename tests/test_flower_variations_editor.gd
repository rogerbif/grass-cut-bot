extends Node

const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const LevelEditorUIScript = preload("res://scripts/editor/level_editor_ui.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

func _ready() -> void:
	print("==================================================")
	print("🧪 TESTES AUTOMATIZADOS: VARIAÇÕES DE FLORES NO EDITOR")
	print("==================================================")

	# 1. Validação do TilePaletteDB
	assert(TilePaletteDB.has_variations("flower"), "flower deve ter variações")
	assert(not TilePaletteDB.has_variations("rock"), "rock não deve ter variações")
	assert(not TilePaletteDB.has_variations("flower_daisy"), "flower_daisy não deve ter variações")

	var vars: Array = TilePaletteDB.get_variations("flower")
	assert(vars.size() == 6, "flower deve conter 6 variações")
	print("  [OK] TilePaletteDB tem 6 variações registradas para 'flower'")

	assert(TilePaletteDB.get_base_id_for_variant("flower") == "flower")
	assert(TilePaletteDB.get_base_id_for_variant("flower_blue") == "flower")
	assert(TilePaletteDB.get_base_id_for_variant("flower_sunset") == "flower")
	assert(TilePaletteDB.get_base_id_for_variant("flower_purple") == "flower")
	assert(TilePaletteDB.get_base_id_for_variant("flower_white") == "flower")
	assert(TilePaletteDB.get_base_id_for_variant("flower_turquoise") == "flower")
	assert(TilePaletteDB.get_base_id_for_variant("rock") == "rock")
	print("  [OK] get_base_id_for_variant mapeia corretamente todas as variações para 'flower'")

	# 2. Validação da UI do Editor
	var ui: Control = LevelEditorUIScript.new()
	add_child(ui)

	# Simula seleção de 'flower' na camada de objetos (layer 2)
	ui.call(
		"sync_state",
		2, # active_layer: OBJECTS
		0, # active_tool: BRUSH
		0, # active_shape: SINGLE
		1, # brush_size
		0, # rot_deg
		"island_center", # terrain_id
		"grass_green",   # grass_id
		"flower",        # active_object_id
		false            # is_top_down
	)

	var dock: PanelContainer = ui.get("panel_variations_dock") as PanelContainer
	assert(dock != null, "panel_variations_dock deve existir")
	assert(dock.visible, "panel_variations_dock deve estar visível quando flower está selecionada")

	var var_buttons: Dictionary = ui.get("variation_buttons") as Dictionary
	assert(var_buttons.size() == 6, "variation_buttons deve conter 6 botões de variação")
	assert(var_buttons.has("flower"), "deve conter botão para 'flower'")
	assert(var_buttons.has("flower_blue"), "deve conter botão para 'flower_blue'")
	print("  [OK] Dock de variações visível e populado com 6 cards")

	# Testa se ao selecionar outra variação ('flower_blue'), o dock permanece visível
	var received_obj: Array[String] = []
	ui.connect("object_item_selected", func(o_id: String) -> void:
		received_obj.append(o_id)
	)

	var btn_blue: Button = var_buttons["flower_blue"] as Button
	btn_blue.emit_signal("pressed")
	assert(received_obj.size() == 1 and received_obj[0] == "flower_blue", "clicar no card deve emitir object_item_selected('flower_blue')")

	ui.call(
		"sync_state",
		2,
		0,
		0,
		1,
		0,
		"island_center",
		"grass_green",
		"flower_blue",
		false
	)
	assert(dock.visible, "dock deve continuar visível para 'flower_blue'")
	print("  [OK] Seleção do card 'flower_blue' mantém o dock ativo e selecionado")

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

	# Testa se ao mudar para camada 1 (grama), o dock se esconde
	ui.call(
		"sync_state",
		1, # GRASS
		0,
		0,
		1,
		0,
		"island_center",
		"grass_green",
		"flower",
		false
	)
	assert(not dock.visible, "dock deve ficar invisível na camada de grama")
	print("  [OK] Dock fica invisível em outras camadas (Grama/Terreno)")

	# 3. Validação do LevelJsonLoader e materiais
	for v_item: Variant in vars:
		var vd: Dictionary = v_item as Dictionary
		var vid: String = String(vd["id"])
		var node: Node3D = LevelJsonLoader.instantiate_object_node(vid, 0)
		assert(node != null, "LevelJsonLoader deve instanciar %s" % vid)
		var custom_mat: Variant = node.get("custom_material")
		assert(custom_mat != null, "Node %s deve ter custom_material configurado" % vid)
		assert(custom_mat is ShaderMaterial, "custom_material de %s deve ser ShaderMaterial" % vid)
		node.free()

	print("  [OK] LevelJsonLoader instancia corretamente todas as 6 variações com ShaderMaterial")

	# 4. Validação do VegetationGridScript
	for v_item: Variant in vars:
		var vd: Dictionary = v_item as Dictionary
		var vid: String = String(vd["id"])
		assert(VegetationGridScript.FLOWER_MATERIALS.has(vid), "VegetationGrid deve ter material para %s" % vid)
		assert(VegetationGridScript.VEG_TYPES.has(vid), "VegetationGrid deve ter tipo registrado para %s" % vid)

	print("  [OK] VegetationGrid possui materiais e tipos GPU instanciados para todas as 6 variações")

	ui.queue_free()
	print("==========================================")
	print("✅ TODOS OS TESTES DE VARIAÇÃO PASSARAM COM SUCESSO! (0 falhas)")
	print("==========================================")
	get_tree().quit(0)
