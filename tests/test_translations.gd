extends SceneTree

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- TEST TRANSLATIONS INITIALIZATION ---")
	
	var loaded_locales: PackedStringArray = TranslationServer.get_loaded_locales()
	print("Loaded locales: ", loaded_locales)
	
	# Verificar se os 3 idiomas foram carregados
	assert("pt_BR" in loaded_locales or "pt_br" in loaded_locales, "Locale pt_BR não encontrado!")
	assert("en" in loaded_locales, "Locale en não encontrado!")
	assert("es" in loaded_locales, "Locale es não encontrado!")
	
	# Testar Português
	TranslationServer.set_locale("pt_BR")
	assert(tr("BTN_PLAY") == "JOGAR", "Falha em BTN_PLAY pt_BR: " + tr("BTN_PLAY"))
	assert(tr("SETTINGS_TITLE") == "CONFIGURAÇÕES", "Falha em SETTINGS_TITLE pt_BR: " + tr("SETTINGS_TITLE"))
	assert(tr("PLANT_WHEAT") == "Trigo Dourado Enraizado", "Falha em PLANT_WHEAT pt_BR: " + tr("PLANT_WHEAT"))
	assert(tr("HUD_LEVEL_LABEL") % 1 == "Fase 1", "Falha em formatação pt_BR")
	assert(tr("HUD_MAIN_MENU") == "MENU INICIAL", "Falha em HUD_MAIN_MENU pt_BR")
	assert(tr("EXIT_MODAL_TITLE") == "SAIR DO JOGO?", "Falha em EXIT_MODAL_TITLE pt_BR")
	print("✔ Testes pt_BR passaram com sucesso!")
	
	# Testar Inglês
	TranslationServer.set_locale("en")
	assert(tr("BTN_PLAY") == "PLAY", "Falha em BTN_PLAY en: " + tr("BTN_PLAY"))
	assert(tr("SETTINGS_TITLE") == "SETTINGS", "Falha em SETTINGS_TITLE en: " + tr("SETTINGS_TITLE"))
	assert(tr("PLANT_WHEAT") == "Golden Rooted Wheat", "Falha em PLANT_WHEAT en: " + tr("PLANT_WHEAT"))
	assert(tr("HUD_LEVEL_LABEL") % 1 == "Level 1", "Falha em formatação en")
	assert(tr("HUD_MAIN_MENU") == "MAIN MENU", "Falha em HUD_MAIN_MENU en")
	assert(tr("EXIT_MODAL_TITLE") == "EXIT GAME?", "Falha em EXIT_MODAL_TITLE en")
	print("✔ Testes en passaram com sucesso!")
	
	# Testar Espanhol
	TranslationServer.set_locale("es")
	assert(tr("BTN_PLAY") == "JUGAR", "Falha em BTN_PLAY es: " + tr("BTN_PLAY"))
	assert(tr("SETTINGS_TITLE") == "CONFIGURACIÓN", "Falha em SETTINGS_TITLE es: " + tr("SETTINGS_TITLE"))
	assert(tr("PLANT_WHEAT") == "Trigo Dorado Enraizado", "Falha em PLANT_WHEAT es: " + tr("PLANT_WHEAT"))
	assert(tr("HUD_LEVEL_LABEL") % 1 == "Nivel 1", "Falha em formatação es")
	assert(tr("HUD_MAIN_MENU") == "MENÚ INICIAL", "Falha em HUD_MAIN_MENU es")
	assert(tr("EXIT_MODAL_TITLE") == "¿SALIR DEL JUEGO?", "Falha em EXIT_MODAL_TITLE es")
	print("✔ Testes es passaram com sucesso!")
	
	print("--- TODOS OS TESTES DE TRADUÇÃO PASSARAM COM 100% DE SUCESSO! ---")
	quit(0)
