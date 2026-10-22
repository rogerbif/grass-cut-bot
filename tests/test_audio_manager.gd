extends Node

func _ready() -> void:
	print("--- INICIANDO TESTE DO SISTEMA DE AUDIO (AUDIOMANAGER) ---")

	var audio_mgr = get_node_or_null("/root/AudioManager")
	if audio_mgr == null:
		var script = load("res://scripts/core/audio_manager.gd")
		audio_mgr = script.new()
		audio_mgr.name = "AudioManager"
		get_tree().root.add_child(audio_mgr)

	assert(audio_mgr != null, "AudioManager não pôde ser instanciado!")
	print("✔ Teste 1: AudioManager instanciado com sucesso.")

	# 2. Teste de Barramentos de Áudio
	var music_bus = AudioServer.get_bus_index("Music")
	var sfx_bus = AudioServer.get_bus_index("SFX")
	assert(music_bus >= 0, "Barramento 'Music' deve existir no layout de áudio")
	assert(sfx_bus >= 0, "Barramento 'SFX' deve existir no layout de áudio")
	print("✔ Teste 2: Barramentos 'Music' e 'SFX' verificados no AudioServer.")

	# 3. Teste de Carregamento dos Recursos
	assert(audio_mgr.MUSIC_MENU != null, "MUSIC_MENU deve estar carregado")
	assert(audio_mgr.MUSIC_GAMEPLAY != null, "MUSIC_GAMEPLAY deve estar carregado")
	assert(audio_mgr.SFX_GRASS_CUT != null, "SFX_GRASS_CUT deve estar carregado")
	assert(audio_mgr.SFX_CUT_FRUIT != null, "SFX_CUT_FRUIT deve estar carregado")
	assert(audio_mgr.SFX_SLAP_ROCK != null, "SFX_SLAP_ROCK deve estar carregado")
	assert(audio_mgr.SFX_ELECTRIC_ENGINE != null, "SFX_ELECTRIC_ENGINE deve estar carregado")
	assert(audio_mgr.SFX_COIN_PICKUP != null, "SFX_COIN_PICKUP deve estar carregado")
	assert(audio_mgr.SFX_TIMER_COUNTDOWN != null, "SFX_TIMER_COUNTDOWN deve estar carregado")
	assert(audio_mgr.SFX_GOAL_COMPLETED != null, "SFX_GOAL_COMPLETED deve estar carregado")
	assert(audio_mgr.SFX_STAR_WIN != null, "SFX_STAR_WIN deve estar carregado")
	assert(audio_mgr.SFX_STAR_POP != null, "SFX_STAR_POP deve estar carregado")
	assert(audio_mgr.SFX_MACHINE_POWER_OFF != null, "SFX_MACHINE_POWER_OFF deve estar carregado")
	assert(audio_mgr.SFX_PAUSE != null, "SFX_PAUSE deve estar carregado")
	assert(audio_mgr.SFX_UNPAUSE != null, "SFX_UNPAUSE deve estar carregado")
	assert(audio_mgr.SFX_CONFIRM != null, "SFX_CONFIRM deve estar carregado")
	assert(audio_mgr.SFX_CLOSE != null, "SFX_CLOSE deve estar carregado")
	assert(audio_mgr.SFX_BUY_SELL != null, "SFX_BUY_SELL deve estar carregado")
	assert(audio_mgr.SFX_POWER_UP != null, "SFX_POWER_UP deve estar carregado")
	assert(audio_mgr.SFX_DENIED != null, "SFX_DENIED deve estar carregado")
	assert(audio_mgr.SFX_FAST_FORWARD != null, "SFX_FAST_FORWARD deve estar carregado")
	assert(audio_mgr.SFX_USE_ITEM != null, "SFX_USE_ITEM deve estar carregado")
	assert(audio_mgr.SFX_WATER_SPLASH != null, "SFX_WATER_SPLASH deve estar carregado")
	print("✔ Teste 3: Todos os 22 recursos de áudio foram pré-carregados com sucesso.")

	# 4. Teste de SFX e Throttling
	audio_mgr.play_cut_sfx(false)
	audio_mgr.play_cut_sfx(true)
	audio_mgr.play_coin_sfx()
	audio_mgr.play_sfx("confirm")
	audio_mgr.play_sfx("buy")
	audio_mgr.play_sfx("slap_rock")
	audio_mgr.play_sfx("star_pop")
	audio_mgr.play_sfx("goal_completed")
	audio_mgr.play_countdown_alert()
	print("✔ Teste 4: Métodos de SFX e debounce executados sem erros.")

	# 5. Teste de Motor Elétrico
	audio_mgr.start_engine()
	audio_mgr.update_engine_speed(0.5)
	audio_mgr.update_engine_speed(1.0)
	audio_mgr.stop_engine()
	print("✔ Teste 5: Ciclo do motor elétrico executado com sucesso.")

	# 6. Teste de Música e Alternância
	audio_mgr.play_menu_music(0.1)
	audio_mgr.play_gameplay_music(0.1)
	audio_mgr.stop_music(0.1)
	print("✔ Teste 6: Alternância de trilhas executada com sucesso.")

	# 7. Teste de Controle de Barramentos / Mute
	audio_mgr.set_music_enabled(false)
	assert(audio_mgr.is_music_enabled() == false, "Música deve estar desativada")
	assert(AudioServer.is_bus_mute(music_bus) == true, "Barramento Music deve estar mutado")

	audio_mgr.set_music_enabled(true)
	assert(audio_mgr.is_music_enabled() == true, "Música deve estar ativada")
	assert(AudioServer.is_bus_mute(music_bus) == false, "Barramento Music não deve estar mutado")

	audio_mgr.set_sfx_enabled(false)
	assert(audio_mgr.is_sfx_enabled() == false, "SFX deve estar desativado")
	assert(AudioServer.is_bus_mute(sfx_bus) == true, "Barramento SFX deve estar mutado")

	audio_mgr.set_sfx_enabled(true)
	assert(audio_mgr.is_sfx_enabled() == true, "SFX deve estar ativado")
	assert(AudioServer.is_bus_mute(sfx_bus) == false, "Barramento SFX não deve estar mutado")
	print("✔ Teste 7: Controles de mute/unmute dos barramentos validados com sucesso.")

	print("--- TODOS OS TESTES DE AUDIO PASSARAM COM 100% DE SUCESSO! ---")
	var timer = get_tree().create_timer(1.5)
	timer.timeout.connect(func(): get_tree().quit(0))
