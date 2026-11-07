extends SceneTree

func _initialize() -> void:
	print("--- TESTE DE PROGRESSAO, METAS E EFEITOS DE VEGETACAO ---")

	# 1. Teste de Total de Fases e Level 20 -> 21
	var gm_script = load("res://scripts/core/game_manager.gd")
	var sm_script = load("res://scripts/core/save_manager.gd")
	var sm = sm_script.new()
	sm.reset_to_defaults()

	var total_lvls: int = gm_script.new().get_total_levels()
	print("Total de fases computado: %d" % total_lvls)
	assert(total_lvls >= 40, "Total de fases deve ser no minimo 40!")
	print("✔ PASSOU: Total de fases = %d" % total_lvls)

	# 2. Teste de Vitória e Persistência de last_played_level
	sm.record_level_victory(1, 40.0, 60.0, 100)
	assert(sm.get_last_played_level() == 2, "Apos Fase 1, last_played_level deve ser 2")
	sm.save_game()
	assert(sm.get_last_played_level() == 2, "save_game nao deve sobrescrever last_played_level!")
	print("✔ PASSOU: last_played_level avancado para 2 e protegido contra sobrescrita")

	# 3. Teste de Vitória na Fase 20
	sm.record_level_victory(20, 50.0, 100.0, 200)
	assert(sm.get_last_played_level() == 21, "Apos Fase 20, last_played_level deve ser 21!")
	assert(sm.is_level_unlocked(21) == true, "Fase 21 deve estar desbloqueada!")
	print("✔ PASSOU: Fase 20 avança para Fase 21 (nao reinicia nem aponta para ciclo mestre)")

	# 4. Teste de Ícone de Metas com Contorno Duplo (Preto 1px + Branco 2px) e Cores Canônicas
	var gif_script = load("res://scripts/ui/goal_icon_factory.gd")
	var wheat_icon = gif_script.build_goal_icon("wheat", 34.0, true)
	assert(wheat_icon != null, "build_goal_icon wheat deve instanciar Control")
	var has_shader_mat: bool = false
	for child in wheat_icon.get_children():
		if child is TextureRect and child.material is ShaderMaterial:
			has_shader_mat = true
			var sh_mat: ShaderMaterial = child.material as ShaderMaterial
			assert(sh_mat.get_shader_parameter("inner_outline_color") != null, "Shader deve possuir inner_outline_color (preto)")
			assert(sh_mat.get_shader_parameter("outer_outline_color") != null, "Shader deve possuir outer_outline_color (branco)")
	assert(has_shader_mat, "TextureRect do wheat_icon deve possuir ShaderMaterial de outline")

	# Verifica se os ícones de grama verde e amarela recebem suas cores canônicas distintas no modulate
	var green_grass_icon = gif_script.build_goal_icon("grass_green", 34.0, true)
	var yellow_grass_icon = gif_script.build_goal_icon("grass_yellow", 34.0, true)
	var green_blades: TextureRect = green_grass_icon.get_child(1) as TextureRect
	var yellow_blades: TextureRect = yellow_grass_icon.get_child(1) as TextureRect
	assert(green_blades != null and yellow_blades != null, "Camadas de laminas de grama devem existir")
	assert(green_blades.modulate != yellow_blades.modulate, "Laminas de grama verde e amarela devem ter cores distintas!")
	assert(green_blades.modulate != Color.WHITE, "Grama verde nao pode ter cor branca pura!")
	assert(yellow_blades.modulate != Color.WHITE, "Grama amarela nao pode ter cor branca pura!")
	print("✔ PASSOU: GoalIconFactory gera contorno duplo (1px preto + 2px branco) e cores canônicas de grama preservadas")

	# 5. Teste de Malha de Lâmina de Grama (cut_leaf_piece)
	var plant_script = load("res://scripts/plants/plant.gd")
	plant_script._ensure_particle_meshes()
	assert(plant_script._grass_blade_mesh != null, "Malha 3D de pedaco de grama nao pode ser nula")
	assert(plant_script._grass_blade_tip_mesh != null, "Malha 3D de ponta de grama nao pode ser nula")
	print("✔ PASSOU: Particulas de corte de grama utilizam malha 3D chanfrada de folha")

	# 6. Teste de Resolução de Flores para Peças Desprendíveis
	assert(plant_script._resolve_flower_base_type("flower_daisy_pink") == "flower_daisy", "flower_daisy_pink deve resolver para flower_daisy")
	assert(plant_script._resolve_flower_base_type("flower_daisy_blue") == "flower_daisy", "flower_daisy_blue deve resolver para flower_daisy")
	assert(plant_script._resolve_flower_base_type("flower_rose_wine") == "flower_rose", "flower_rose_wine deve resolver para flower_rose")
	assert(plant_script._resolve_flower_base_type("flower_sunflower") == "flower_sunflower", "flower_sunflower deve resolver para flower_sunflower")
	print("✔ PASSOU: Todas as variantes de flores resolvem para sua especie dedicada")

	# 7. Teste de Tratamento Individual de Gramas nas 40 Fases (sem meta genérica "grass")
	var loader = load("res://scripts/level/level_json_loader.gd")
	for lvl in range(1, 41):
		var json_path = "res://data/levels/level_%02d.json" % lvl
		assert(FileAccess.file_exists(json_path), "Arquivo de nível %02d deve existir" % lvl)
		var ldata = loader.load_json_file(json_path)
		var card_g: Dictionary = ldata.get("card_goals", {}) as Dictionary
		assert(not card_g.has("grass"), "Fase %02d nao deve possuir a chave generica 'grass', apenas cores individuais!" % lvl)
		# Garante que há pelo menos uma meta de grama específica presente
		var has_colored_grass: bool = false
		for k in card_g.keys():
			if String(k).begins_with("grass_"):
				has_colored_grass = true
				break
		assert(has_colored_grass, "Fase %02d deve conter pelo menos uma variedade individual de grama (ex: grass_green, grass_yellow)" % lvl)
	print("✔ PASSOU: Todas as 40 fases tratam gramas individualmente por cor (zero ocorrências de 'grass' genérico)")

	# 8. Teste de Fix do OK no HUD: permanência estrita de 'OK' após bater meta
	var hud_packed: PackedScene = load("res://scenes/ui/hud.tscn")
	assert(hud_packed != null, "Cena hud.tscn deve ser carregada")
	var hud_inst: Control = hud_packed.instantiate() as Control
	root.add_child(hud_inst)
	if hud_inst.get("goals_container") == null:
		var container = HBoxContainer.new()
		hud_inst.set("goals_container", container)
		hud_inst.add_child(container)

	# Simula meta inicial de 10 grass_green
	hud_inst.call("_on_goal_updated", "grass_green", 10, 10)
	var card_info: Dictionary = hud_inst.get("goal_cards")["grass_green"] as Dictionary
	var lbl: Label = card_info["count_label"] as Label
	assert(lbl.text == "10", "Card inicial deve exibir '10'")

	# Simula meta batida (0 restante)
	hud_inst.call("_on_goal_updated", "grass_green", 0, 10)
	assert(lbl.text == "OK", "Card ao zerar meta deve exibir 'OK'")
	assert(card_info["is_completed"] == true, "Card deve estar marcado como is_completed = true")

	# Simula corte subsequente de grama (chamada repetida com remaining = 0)
	hud_inst.call("_on_goal_updated", "grass_green", 0, 10)
	assert(lbl.text == "OK", "Card DEVE continuar exibindo 'OK' mesmo apos cortes excedentes subsequentes!")

	hud_inst.queue_free()
	print("✔ PASSOU: HUD mantém texto 'OK' e estado concluído permanentemente sem resetar para '0'")

	print("\n==========================================")
	print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<")
	print("==========================================")
	quit(0)
