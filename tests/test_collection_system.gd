extends Node

const PlantDatabaseScript = preload("res://scripts/plants/plant_database.gd")

func _ready() -> void:
	print("--- INICIANDO TESTE DO SISTEMA DE HERBÁRIO E COLEÇÃO ---")

	# 1. Validação do PlantDatabase
	var species_list: Array[Dictionary] = PlantDatabaseScript.get_all_species()
	assert(species_list.size() == 15, "PlantDatabase deve conter exatamente 15 espécies! Atual: %d" % species_list.size())
	
	var grass_count: int = 0
	var crop_count: int = 0
	var flower_count: int = 0
	for sp: Dictionary in species_list:
		var cat: String = String(sp.get("category", ""))
		var milestones: Array = sp.get("milestones", [])
		assert(milestones.size() == 10, "A espécie %s deve conter exatamente 10 marcos! Atual: %d" % [sp.get("key"), milestones.size()])
		match cat:
			"grass": grass_count += 1
			"crop": crop_count += 1
			"flower": flower_count += 1

	assert(grass_count == 7, "Devem existir 7 gramas coloridas! Atual: %d" % grass_count)
	assert(crop_count == 1, "Deve existir 1 cultura agrícola (trigo)! Atual: %d" % crop_count)
	assert(flower_count == 7, "Devem existir 7 flores/canteiros! Atual: %d" % flower_count)
	print("✔ Teste 1: PlantDatabase validado com 15 espécies e 10 marcos cada.")

	# 2. Validação do SaveManager
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr == null:
		var sm_script: Script = load("res://scripts/core/save_manager.gd")
		save_mgr = sm_script.new()
		save_mgr.name = "SaveManager"
		get_tree().root.add_child(save_mgr)

	save_mgr.reset_to_defaults()
	assert(save_mgr.get_discovered_species_count() == 0, "No reset, total de descobertas deve ser 0")
	assert(save_mgr.get_total_harvest_count() == 0, "No reset, total de ceifas deve ser 0")
	assert(save_mgr.is_species_discovered("grass_green") == false, "grass_green deve iniciar não descoberta")

	# Simula ceifa de grama verde
	save_mgr.record_plant_harvest("grass_green", 50)
	assert(save_mgr.is_species_discovered("grass_green") == true, "grass_green deve constar como descoberta")
	assert(save_mgr.get_harvest_count("grass_green") == 50, "Contagem de grass_green deve ser 50")
	assert(save_mgr.get_discovered_species_count() == 1, "Total de espécies descobertas deve ser 1")
	assert(save_mgr.get_claimed_milestone_level("grass_green") == 0, "Nenhum marco deve estar resgatado inicialmente")

	# Tenta resgatar marco nível 2 diretamente (fora de ordem) -> deve falhar
	var fail_claim: bool = save_mgr.claim_milestone_level("grass_green", 2, 20)
	assert(fail_claim == false, "Não deve permitir resgatar marco fora de ordem")

	# Resgata marco nível 1
	var ok_claim: bool = save_mgr.claim_milestone_level("grass_green", 1, 10)
	assert(ok_claim == true, "Resgate do marco nível 1 deve ter sucesso")
	assert(save_mgr.get_claimed_milestone_level("grass_green") == 1, "Marco nível 1 deve constar como resgatado")

	# Ceifa trigo e flor
	save_mgr.record_plant_harvest("wheat", 20)
	save_mgr.record_plant_harvest("flower_rose", 15)
	assert(save_mgr.get_discovered_species_count() == 3, "Total de descobertas deve ser 3")
	assert(save_mgr.get_total_harvest_count() == 85, "Total ceifado deve ser 50 + 20 + 15 = 85")
	print("✔ Teste 2: SaveManager (descoberta, ceifa e marcos progressivos) validado.")

	# 3. Teste de Persistência e Reload do Save
	var save_ok: bool = save_mgr.save_game()
	assert(save_ok == true, "save_game() deve retornar true")
	var load_ok: bool = save_mgr.load_game()
	assert(load_ok == true, "load_game() deve retornar true")
	assert(save_mgr.get_discovered_species_count() == 3, "Descobertas devem persistir após reload")
	assert(save_mgr.get_harvest_count("grass_green") == 50, "Ceifas de grass_green devem persistir")
	assert(save_mgr.get_claimed_milestone_level("grass_green") == 1, "Marco 1 resgatado deve persistir")
	print("✔ Teste 3: Serialização e reload de 'collection' validados com sucesso.")

	# 4. Teste da UI do TabCollection
	var collection_scene: PackedScene = load("res://scenes/menu/tabs/tab_collection.tscn")
	var tab_col: Control = collection_scene.instantiate() as Control
	add_child(tab_col)
	tab_col.call("refresh_ui")

	var prog_lbl: Label = tab_col.get_node("Panel/MainVBox/HeaderVBox/ProgBox/ProgLabel") as Label
	assert(prog_lbl != null, "ProgLabel deve existir na cena")
	assert(prog_lbl.text.contains("3 / 15"), "Texto de progresso deve indicar 3 / 15 descobertas! Atual: %s" % prog_lbl.text)

	var cards_vbox: VBoxContainer = tab_col.get_node("Panel/MainVBox/Scroll/CardsVBox") as VBoxContainer
	assert(cards_vbox != null, "CardsVBox deve existir na cena")
	assert(cards_vbox.get_child_count() == 15, "CardsVBox deve renderizar 15 cards no filtro 'all'! Atual: %d" % cards_vbox.get_child_count())

	# Testa filtros
	tab_col.call("_set_filter", "grass")
	assert(cards_vbox.get_child_count() == 7, "CardsVBox deve renderizar 7 cards no filtro 'grass'! Atual: %d" % cards_vbox.get_child_count())

	tab_col.call("_set_filter", "crop")
	assert(cards_vbox.get_child_count() == 1, "CardsVBox deve renderizar 1 card no filtro 'crop'! Atual: %d" % cards_vbox.get_child_count())

	tab_col.call("_set_filter", "flower")
	assert(cards_vbox.get_child_count() == 7, "CardsVBox deve renderizar 7 cards no filtro 'flower'! Atual: %d" % cards_vbox.get_child_count())

	tab_col.queue_free()
	print("✔ Teste 4: TabCollection UI (renderização dinâmica e filtros) validada.")

	print("--- TODOS OS TESTES DO HERBÁRIO FORAM APROVADOS COM SUCESSO! ---")
	await get_tree().create_timer(1.0).timeout
	get_tree().quit(0)
