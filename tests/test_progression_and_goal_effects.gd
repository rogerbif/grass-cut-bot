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

	# 4. Teste de Ícone de Metas com Borda Branca (GoalIconFactory)
	var gif_script = load("res://scripts/ui/goal_icon_factory.gd")
	var wheat_icon = gif_script.build_goal_icon("wheat", 34.0, true)
	assert(wheat_icon != null, "build_goal_icon wheat deve instanciar Control")
	var has_shader_mat: bool = false
	for child in wheat_icon.get_children():
		if child is TextureRect and child.material is ShaderMaterial:
			has_shader_mat = true
	assert(has_shader_mat, "TextureRect do wheat_icon deve possuir ShaderMaterial de outline")
	print("✔ PASSOU: GoalIconFactory gera icone com ShaderMaterial de contorno branco")

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

	print("\n==========================================")
	print(">>> TODOS OS TESTES PASSARAM COM SUCESSO! <<<")
	print("==========================================")
	quit(0)
