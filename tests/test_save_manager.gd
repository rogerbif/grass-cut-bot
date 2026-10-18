extends Node

func _ready() -> void:
	print("--- INICIANDO TESTE DO SISTEMA DE SAVEGAME ---")
	
	var save_mgr = get_node_or_null("/root/SaveManager")
	if save_mgr == null:
		var script = load("res://scripts/core/save_manager.gd")
		save_mgr = script.new()
		save_mgr.name = "SaveManager"
		get_tree().root.add_child(save_mgr)
	
	assert(save_mgr != null, "SaveManager não pôde ser instanciado!")

	# 1. Teste de Reset e Defaults
	save_mgr.reset_to_defaults()
	assert(save_mgr.get_max_unlocked_level() == 1, "Max unlocked level padrão deve ser 1")
	assert(save_mgr.is_level_unlocked(1) == true, "Fase 1 deve sempre estar desbloqueada")
	assert(save_mgr.is_level_unlocked(2) == false, "Fase 2 deve iniciar bloqueada")
	assert(save_mgr.get_level_stars(1) == 0, "Estrelas da fase 1 devem iniciar em 0")
	assert(save_mgr.get_setting("music_enabled", false) == true, "Música deve iniciar ativada")
	print("✔ Teste 1: Padrões e Reset validados com sucesso.")

	# 2. Teste de Configurações (Settings)
	save_mgr.set_setting("vib_enabled", false)
	assert(save_mgr.get_setting("vib_enabled", true) == false, "Configuração de vibração deve persistir false")
	save_mgr.set_setting("vib_enabled", true)
	assert(save_mgr.get_setting("vib_enabled", false) == true, "Configuração de vibração deve persistir true")
	print("✔ Teste 2: Configurações get/set validadas com sucesso.")

	# 3. Teste de Cálculo de Estrelas e Registro de Vitória
	# Cenário A: Conclusão com 55% do tempo restante -> 3 estrelas (>= 50%)
	var stars_a: int = save_mgr.record_level_victory(1, 55.0, 100.0, 80)
	assert(stars_a == 3, "Tempo restante >= 50% deve conceder 3 estrelas")
	assert(save_mgr.get_level_stars(1) == 3, "Fase 1 deve registrar 3 estrelas")
	assert(save_mgr.is_level_unlocked(2) == true, "Fase 2 deve estar desbloqueada após vencer Fase 1")
	assert(save_mgr.get_max_unlocked_level() == 2, "Max unlocked level deve ser 2")

	# Cenário B: Conclusão da Fase 2 com 30% do tempo restante -> 2 estrelas (>= 25% e < 50%)
	var stars_b: int = save_mgr.record_level_victory(2, 30.0, 100.0, 120)
	assert(stars_b == 2, "Tempo restante >= 25% e < 50% deve conceder 2 estrelas")
	assert(save_mgr.get_level_stars(2) == 2, "Fase 2 deve registrar 2 estrelas")
	assert(save_mgr.is_level_unlocked(3) == true, "Fase 3 deve estar desbloqueada após vencer Fase 2")

	# Cenário C: Conclusão da Fase 3 com 10% do tempo restante -> 1 estrela (< 25%)
	var stars_c: int = save_mgr.record_level_victory(3, 10.0, 100.0, 150)
	assert(stars_c == 1, "Tempo restante < 25% deve conceder 1 estrela")
	assert(save_mgr.get_level_stars(3) == 1, "Fase 3 deve registrar 1 estrela")

	# Cenário D: Rejogar Fase 2 e conseguir 3 estrelas -> Não deve regredir recorde
	var stars_d: int = save_mgr.record_level_victory(2, 60.0, 100.0, 200)
	assert(stars_d == 3, "Nova vitória com melhor tempo deve subir para 3 estrelas")
	assert(save_mgr.get_level_stars(2) == 3, "Fase 2 deve ter subido para 3 estrelas")
	print("✔ Teste 3: Regras de Estrelas (1, 2, 3) e Desbloqueio validadas com sucesso.")

	# 4. Teste de Salvamento Atômico e Recarga
	var save_ok: bool = save_mgr.save_game()
	assert(save_ok == true, "save_game() deve retornar true")
	
	# Recarrega em memória
	var load_ok: bool = save_mgr.load_game()
	assert(load_ok == true, "load_game() deve retornar true")
	assert(save_mgr.get_level_stars(1) == 3, "Estrelas da fase 1 devem persistir após recarga")
	assert(save_mgr.get_level_stars(2) == 3, "Estrelas da fase 2 devem persistir após recarga")
	assert(save_mgr.get_level_stars(3) == 1, "Estrelas da fase 3 devem persistir após recarga")
	assert(save_mgr.is_level_unlocked(3) == true, "Fase 3 deve permanecer desbloqueada")
	print("✔ Teste 4: Persistência em disco e recarga validadas com sucesso.")

	# 5. Teste de Recuperação por Backup (.bak)
	# Força corrupção no arquivo principal e recarrega
	var file = FileAccess.open(save_mgr.SAVE_PATH, FileAccess.WRITE)
	if file != null:
		file.store_string("{ ARQUIVO_CORROMPIDO_INVALIDO_JSON !!!")
		file.close()
	
	var recovered: bool = save_mgr.load_game()
	assert(recovered == true, "load_game() deve recuperar os dados a partir do arquivo .bak")
	assert(save_mgr.get_level_stars(1) == 3, "Dados recuperados do .bak devem estar intactos")
	print("✔ Teste 5: Recuperação automática e resiliência via backup (.bak) comprovada!")

	print("==================================================")
	print(">>> TODOS OS TESTES DO SAVEGAME PASSARAM COM 100% DE SUCESSO! <<<")
	print("==================================================")
	get_tree().quit(0)
