extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("--- TEST UI LOCALIZATION INTEGRATION ---")
	
	var PlantDatabaseScript = load("res://scripts/plants/plant_database.gd")
	var sp_wheat: Dictionary = PlantDatabaseScript.get_species("wheat")
	var sp_rose: Dictionary = PlantDatabaseScript.get_species("flower_rose")
	
	# 1. Testar em Português
	TranslationServer.set_locale("pt_BR")
	assert(PlantDatabaseScript.get_species_name(sp_wheat) == "Trigo Dourado Enraizado", "Falha wheat pt_BR")
	assert(PlantDatabaseScript.get_species_name(sp_rose) == "Rosa Rubra Nobre", "Falha rose pt_BR")
	assert(tr("NAV_HOME") == "Início", "Falha NAV_HOME pt_BR")
	assert(tr("NAV_HERBARIUM") == "Herbário", "Falha NAV_HERBARIUM pt_BR")
	assert(tr("CARD_STARS") == "Estrelas", "Falha CARD_STARS pt_BR")
	assert(tr("HUD_LEVEL_CLEAR") % 3 == "FASE 03 CONCLUÍDA!", "Falha HUD_LEVEL_CLEAR pt_BR")
	print("✔ Testes integrados de UI em pt_BR aprovados.")
	
	# 2. Testar em Inglês
	TranslationServer.set_locale("en")
	assert(PlantDatabaseScript.get_species_name(sp_wheat) == "Golden Rooted Wheat", "Falha wheat en")
	assert(PlantDatabaseScript.get_species_name(sp_rose) == "Noble Red Rose", "Falha rose en")
	assert(tr("NAV_HOME") == "Home", "Falha NAV_HOME en")
	assert(tr("NAV_HERBARIUM") == "Herbarium", "Falha NAV_HERBARIUM en")
	assert(tr("CARD_STARS") == "Stars", "Falha CARD_STARS en")
	assert(tr("HUD_LEVEL_CLEAR") % 3 == "LEVEL 03 CLEARED!", "Falha HUD_LEVEL_CLEAR en")
	print("✔ Testes integrados de UI em en aprovados.")
	
	# 3. Testar em Espanhol
	TranslationServer.set_locale("es")
	assert(PlantDatabaseScript.get_species_name(sp_wheat) == "Trigo Dorado Enraizado", "Falha wheat es")
	assert(PlantDatabaseScript.get_species_name(sp_rose) == "Rosa Roja Noble", "Falha rose es")
	assert(tr("NAV_HOME") == "Inicio", "Falha NAV_HOME es")
	assert(tr("NAV_HERBARIUM") == "Herbario", "Falha NAV_HERBARIUM es")
	assert(tr("CARD_STARS") == "Estrellas", "Falha CARD_STARS es")
	assert(tr("HUD_LEVEL_CLEAR") % 3 == "¡NIVEL 03 COMPLETADO!", "Falha HUD_LEVEL_CLEAR es")
	print("✔ Testes integrados de UI em es aprovados.")
	
	print("--- TODOS OS TESTES INTEGRADOS DE LOCALIZAÇÃO PASSARAM COM SUCESSO! ---")
	quit(0)
