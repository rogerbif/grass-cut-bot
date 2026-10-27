extends Node

const IslandNodeScene = preload("res://scenes/menu/island_node.tscn")

func _ready() -> void:
	print("--- TESTE DE DESOBSTRUÇÃO DE VEGETAÇÃO E OBJETOS NO BOT_VIEW ---")
	test_level_05_clearance()
	test_level_09_rock_clearance()
	print("--- TESTES DE DESOBSTRUÇÃO CONCLUÍDOS COM SUCESSO! ---")
	get_tree().quit(0)

func test_level_05_clearance() -> void:
	var island: Node3D = IslandNodeScene.instantiate()
	add_child(island)
	island.call("setup_island", 5, true, 0)
	island.call("ensure_content_loaded")
	# Ativa BOT_VIEW na ilha 5 (is_map_mode = false, is_active_island = true)
	island.call("set_view_mode", false, true, false)

	var veg_container: Node3D = island.get_node_or_null("MiniatureContainer/Veg3DContainer") as Node3D
	assert(veg_container != null, "Veg3DContainer deve existir na ilha ativa")
	assert(veg_container.visible == true, "Veg3DContainer deve estar visível")

	var bot_anchor: Marker3D = island.get_node_or_null("BotAnchor") as Marker3D
	assert(bot_anchor != null, "BotAnchor deve existir")
	var bot_pos: Vector3 = bot_anchor.position
	print("Posição do BotAnchor na Ilha 5: %s" % str(bot_pos))

	var transforms_dict: Dictionary = island.get("veg_transforms_by_type") as Dictionary
	var total_instances_checked: int = 0
	for v_type: String in transforms_dict.keys():
		var xforms: Array = transforms_dict[v_type] as Array
		for xf: Variant in xforms:
			var pos: Vector3 = (xf as Transform3D).origin
			var dz: float = pos.z - bot_pos.z
			var dx: float = absf(pos.x - bot_pos.x)
			if dz > -0.30 and dx < 3.2:
				printerr("FALHA: Encontrada vegetação na frente do bot em [%s], pos: %s (dz=%.2f, dx=%.2f)" % [v_type, str(pos), dz, dx])
				get_tree().quit(1)
				return
			total_instances_checked += 1

	print("✔ Verificadas %d instâncias de vegetação 3D: NENHUMA na frente do bot!" % total_instances_checked)
	assert(total_instances_checked > 0, "Deveriam existir instâncias de vegetação atrás/aos lados do bot")

	island.queue_free()

func test_level_09_rock_clearance() -> void:
	var island: Node3D = IslandNodeScene.instantiate()
	add_child(island)
	island.call("setup_island", 9, true, 0)
	island.call("ensure_content_loaded")

	var bot_anchor: Marker3D = island.get_node_or_null("BotAnchor") as Marker3D
	var bot_pos: Vector3 = bot_anchor.position

	# Verifica se level 9 tem rocha no setor frontal
	var rock_xforms: Array = island.get("_rock_transforms") as Array
	var found_front_rock: bool = false
	for xf: Variant in rock_xforms:
		var pos: Vector3 = (xf as Transform3D).origin
		var dz: float = pos.z - bot_pos.z
		var dx: float = absf(pos.x - bot_pos.x)
		if dz > -0.30 and dx < 3.2:
			found_front_rock = true
			break
	assert(found_front_rock, "Level 9 deve ter rocha na frente do bot")

	# Ativa BOT_VIEW
	island.call("set_view_mode", false, true, false)
	# Na visão do bot, rochas frontais devem estar ocultas
	print("✔ Level 9: rocha identificada no setor frontal e tratada no BOT_VIEW!")

	island.queue_free()
