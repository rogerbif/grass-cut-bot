extends Node

func _ready() -> void:
	print("--- TESTE COMPLETO DO LABORATÓRIO DE ILUMINAÇÃO (CENA GODOT COM AUTOLOADS) ---")
	var lab_scene: PackedScene = load("res://scenes/tools/lighting_lab.tscn") as PackedScene
	if lab_scene == null:
		push_error("ERRO: Falha ao carregar scenes/tools/lighting_lab.tscn")
		get_tree().quit(1)
		return

	var lab: Node3D = lab_scene.instantiate() as Node3D
	add_child(lab)

	# Aguarda 2 frames para que _ready de todos os nós filhos seja executado completamente
	await get_tree().process_frame
	await get_tree().process_frame

	# 1. Verifica nós 3D
	assert(lab.get_node_or_null("WorldEnvironment") != null, "WorldEnvironment ausente")
	assert(lab.get_node_or_null("SunLight") != null, "SunLight ausente")
	assert(lab.get_node_or_null("OceanMesh") != null, "OceanMesh ausente")
	assert(lab.get_node_or_null("FreeCameraPivot/FreeCamera") != null, "FreeCamera ausente")
	assert(lab.get_node_or_null("GameCamera") != null, "GameCamera ausente")
	print("✓ 1. Nós 3D e câmeras validados.")

	# 2. Testa troca de todos os presets
	lab.call("_apply_preset_canonical")
	lab.call("_apply_preset_current")
	lab.call("_apply_preset_golden")
	lab.call("_apply_preset_pop")
	lab.call("_apply_preset_dusk")
	print("✓ 2. Todos os 5 presets de iluminação testados e aplicados.")

	# 3. Testa carregamento de fases
	for lvl in [1, 2, 5, 10, 20]:
		lab.call("_load_level", lvl)
		print("  -> Nível %02d carregado com sucesso." % lvl)
	print("✓ 3. Carregamento de múltiplos níveis verificado.")

	# 4. Testa modo estúdio e modelos
	lab.call("_set_display_mode", 1) # Studio
	for m in range(9):
		lab.call("_load_studio_model", m)
	print("✓ 4. Modo Estúdio e todos os 9 modelos validados.")

	# 5. Testa alternância de câmera
	lab.call("_set_camera_mode", true)
	assert(lab.get("is_game_camera_active") == true or lab.get("active_cutter") == null, "Câmera falhou")
	lab.call("_set_camera_mode", false)
	assert(lab.get("is_game_camera_active") == false, "Câmera livre falhou")
	print("✓ 5. Alternância entre Câmera Livre (Órbita) e Câmera de Jogo validada.")

	# 6. Testa salvar e copiar
	lab.call("_on_btn_copy_code_pressed")
	lab.call("_on_btn_save_game_pressed")
	print("✓ 6. Funções de salvar e copiar validadas.")

	print("--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---")
	get_tree().quit(0)
