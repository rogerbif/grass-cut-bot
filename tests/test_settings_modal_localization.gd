extends SceneTree

func _init() -> void:
	call_deferred("_run_test")

func _run_test() -> void:
	print("--- TEST SETTINGS MODAL LOCALIZATION ---")
	var modal_scene: PackedScene = load("res://scenes/ui/settings_modal.tscn")
	assert(modal_scene != null, "Falha ao carregar settings_modal.tscn")
	
	var modal: Control = modal_scene.instantiate() as Control
	root.add_child(modal)
	
	var btn_pt: Button = modal.find_child("BtnLangPT", true, false) as Button
	var btn_en: Button = modal.find_child("BtnLangEN", true, false) as Button
	var btn_es: Button = modal.find_child("BtnLangES", true, false) as Button
	var title_lbl: Label = modal.find_child("Title", true, false) as Label
	
	assert(btn_pt != null, "BtnLangPT não encontrado!")
	assert(btn_en != null, "BtnLangEN não encontrado!")
	assert(btn_es != null, "BtnLangES não encontrado!")
	assert(title_lbl != null, "Title label não encontrado!")
	
	# Simular clique em EN
	btn_en.emit_signal("pressed")
	assert(TranslationServer.get_locale() == "en", "TranslationServer deveria estar em 'en'")
	assert(title_lbl.text == "SETTINGS", "Título deveria estar em inglês 'SETTINGS', obtido: " + title_lbl.text)
	print("✔ Troca para EN validada com sucesso.")
	
	# Simular clique em ES
	btn_es.emit_signal("pressed")
	assert(TranslationServer.get_locale() == "es", "TranslationServer deveria estar em 'es'")
	assert(title_lbl.text == "CONFIGURACIÓN", "Título deveria estar em espanhol 'CONFIGURACIÓN', obtido: " + title_lbl.text)
	print("✔ Troca para ES validada com sucesso.")
	
	# Simular clique em PT
	btn_pt.emit_signal("pressed")
	assert(TranslationServer.get_locale() == "pt_BR", "TranslationServer deveria estar em 'pt_BR'")
	assert(title_lbl.text == "CONFIGURAÇÕES", "Título deveria estar em português 'CONFIGURAÇÕES', obtido: " + title_lbl.text)
	print("✔ Troca para PT validada com sucesso.")
	
	modal.queue_free()
	print("--- TESTE DO SETTINGS MODAL CONCLUÍDO COM 100% DE SUCESSO! ---")
	quit(0)
