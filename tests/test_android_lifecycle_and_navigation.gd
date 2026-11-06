extends Node

func _ready() -> void:
	print("--- TESTE: CICLO DE VIDA ANDROID, AUTO-PAUSA E BOTÃO VOLTAR ---")

	# 1. Teste de Auto-Pausa em Perda de Foco / Minimização do App
	print("1. Testando GameManager auto-pausa em NOTIFICATION_APPLICATION_PAUSED / FOCUS_OUT...")
	GameManager.current_state = GameManager.GameState.PLAYING
	get_tree().paused = false
	assert(GameManager.current_state == GameManager.GameState.PLAYING, "Estado inicial deve ser PLAYING")

	# Simula notificação do SO ao receber chamada ou minimizar
	GameManager._notification(MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT)
	assert(GameManager.current_state == GameManager.GameState.PAUSED, "Deve pausar ao receber FOCUS_OUT")
	assert(get_tree().paused == true, "get_tree().paused deve ser true")

	# Simula retomada pelo usuário
	GameManager.toggle_pause()
	assert(GameManager.current_state == GameManager.GameState.PLAYING, "Deve retornar a PLAYING")
	assert(get_tree().paused == false, "get_tree().paused deve ser false")

	GameManager._notification(MainLoop.NOTIFICATION_APPLICATION_PAUSED)
	assert(GameManager.current_state == GameManager.GameState.PAUSED, "Deve pausar ao receber APPLICATION_PAUSED")
	assert(get_tree().paused == true, "get_tree().paused deve ser true")

	get_tree().paused = false
	GameManager.current_state = GameManager.GameState.READY
	print("✔ Teste 1 aprovado: Auto-pausa ativada com sucesso em ambas as notificações de perda de foco!")

	# 2. Teste de Resolução de Safe Area no HUD
	print("2. Testando cálculo de Safe Area e layout do HUD...")
	var hud_scene: PackedScene = load("res://scenes/ui/hud.tscn")
	var hud: Control = hud_scene.instantiate() as Control
	add_child(hud)

	var safe_margin: float = hud._get_safe_area_top_margin()
	assert(safe_margin >= 0.0, "Safe area margin deve ser não-negativa")
	print("✔ Teste 2 aprovado: Safe area calculada com sucesso (margin: %.1f px)" % safe_margin)

	# 3. Teste de Navegação com Botão Voltar no HUD (Modais e Gameplay)
	print("3. Testando hierarquia do Botão Voltar no HUD...")
	GameManager.current_state = GameManager.GameState.PLAYING

	# Cenário A: Partida em andamento -> Voltar pausa o jogo
	hud._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(GameManager.current_state == GameManager.GameState.PAUSED, "Voltar durante gameplay deve pausar o jogo")
	print("  ✔ Cenário 3A: Voltar durante gameplay abriu pausa.")

	# Cenário B: Pausa aberta -> Voltar retoma a partida
	hud._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(GameManager.current_state == GameManager.GameState.PLAYING, "Voltar na pausa deve retomar o jogo")
	print("  ✔ Cenário 3B: Voltar no modal de pausa retomou o jogo.")

	# Cenário C: Oficina aberta -> Voltar fecha a oficina
	hud.workshop_modal.visible = true
	hud._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(hud.workshop_modal.visible == false, "Voltar na oficina deve fechar o modal da oficina")
	print("  ✔ Cenário 3C: Voltar no modal da oficina fechou o modal.")

	hud.queue_free()

	# 4. Teste de Navegação com Botão Voltar no Menu Principal
	print("4. Testando hierarquia do Botão Voltar no Menu Principal...")
	var menu_scene: PackedScene = load("res://scenes/menu/main_menu.tscn")
	var menu_node: Node3D = menu_scene.instantiate() as Node3D
	add_child(menu_node)

	# Cenário A: Modal de configurações aberto -> Voltar fecha modal
	menu_node.settings_modal.open_modal()
	assert(menu_node.settings_modal.is_open() == true, "Modal de configurações deve estar aberto")
	menu_node._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(menu_node.settings_modal.is_open() == false, "Voltar com configurações abertas deve fechar o modal")
	print("  ✔ Cenário 4A: Voltar com configurações abertas fechou o modal.")

	# Cenário B: Câmera em modo Mapa (Arquipélago) -> Voltar retorna à visão do Robô
	menu_node.menu_camera.switch_to_map_view()
	assert(menu_node.menu_camera.current_mode == menu_node.menu_camera.CameraMode.MAP_VIEW, "Câmera deve estar no MAP_VIEW")
	menu_node._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(menu_node.menu_camera.current_mode == menu_node.menu_camera.CameraMode.BOT_VIEW, "Voltar no mapa deve retornar à visão do robô")
	print("  ✔ Cenário 4B: Voltar no mapa retornou à visão focada no robô.")

	# Cenário C: Aba secundária (Garagem / Loja / Coleção) -> Voltar retorna à Home (aba 0)
	menu_node.bottom_nav.select_tab(1) # Garagem
	assert(menu_node.bottom_nav.current_tab == 1, "Aba atual deve ser Garagem (1)")
	menu_node._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	assert(menu_node.bottom_nav.current_tab == 0, "Voltar de aba secundária deve retornar à Home (0)")
	print("  ✔ Cenário 4C: Voltar de aba secundária retornou à Home (aba 0).")

	menu_node.queue_free()

	print("==================================================")
	print(">>> TODOS OS TESTES DE CICLO DE VIDA E VOLTAR APROVADOS! <<<")
	print("==================================================")
