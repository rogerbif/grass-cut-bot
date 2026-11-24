extends Node

func _ready() -> void:
	print("==================================================")
	print("🎁 TESTE UNITÁRIO: BÔNUS DIÁRIO (7 DIAS)")
	print("==================================================")

	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr == null:
		var save_script: GDScript = load("res://scripts/core/save_manager.gd") as GDScript
		save_mgr = save_script.new()
		save_mgr.name = "SaveManager"
		get_tree().root.add_child(save_mgr)
	assert(save_mgr != null, "SaveManager não pôde ser instanciado!")

	save_mgr.reset_to_defaults()

	# 1. Estado inicial: Dia 1 disponível, +50 moedas
	save_mgr._debug_day_override = 20000
	assert(save_mgr.can_claim_daily_bonus() == true, "Primeiro acesso deve permitir resgate")
	assert(save_mgr.get_daily_bonus_next_day() == 1, "Primeiro dia deve ser Dia 1")
	assert(save_mgr.get_daily_bonus_reward_for_day(1) == 50, "Dia 1 deve valer 50 moedas")

	var res1: Dictionary = save_mgr.claim_daily_bonus()
	assert(bool(res1.get("success", false)) == true, "Resgate Dia 1 deve ter sucesso")
	assert(int(res1.get("day", 0)) == 1, "Deve registrar Dia 1")
	assert(int(res1.get("coins", 0)) == 50, "Deve conceder 50 moedas")
	assert(save_mgr.can_claim_daily_bonus() == false, "Não deve permitir duplo resgate no mesmo dia")
	var res1_dup: Dictionary = save_mgr.claim_daily_bonus()
	assert(bool(res1_dup.get("success", false)) == false, "Duplo resgate no mesmo dia deve falhar")
	print("✔ Teste 1: Primeiro resgate e bloqueio no mesmo dia OK.")

	# 2. Progressão consecutiva Dias 2 a 7 (Dia 7 recarrega vidas!)
	save_mgr.consume_life()
	assert(save_mgr.get_lives() == 4, "Deve ter 4 vidas antes do Dia 7")

	var expected_rewards: Array[int] = [50, 100, 150, 250, 350, 500, 1000]
	for day_idx: int in range(2, 8):
		save_mgr._debug_day_override = 20000 + (day_idx - 1)
		assert(save_mgr.can_claim_daily_bonus() == true, "Dia %d consecutivo deve liberar" % day_idx)
		assert(save_mgr.get_daily_bonus_next_day() == day_idx, "Próximo dia deve ser %d" % day_idx)
		var res_d: Dictionary = save_mgr.claim_daily_bonus()
		assert(bool(res_d.get("success", false)) == true, "Resgate Dia %d deve ter sucesso" % day_idx)
		assert(int(res_d.get("coins", 0)) == expected_rewards[day_idx - 1], "Recompensa Dia %d incorreta" % day_idx)
		if day_idx == 7:
			assert(bool(res_d.get("refilled_lives", false)) == true, "Dia 7 deve recarregar vidas")
			assert(save_mgr.get_lives() == 5, "Vidas devem estar cheias (5) após Dia 7")
	print("✔ Teste 2: Ciclo completo Dias 1..7 + Refil de Vidas no Dia 7 OK.")

	# 3. Reinício de ciclo no Dia 8 (volta para Dia 1)
	save_mgr._debug_day_override = 20007
	assert(save_mgr.can_claim_daily_bonus() == true, "Dia 8 deve liberar novo ciclo")
	assert(save_mgr.get_daily_bonus_next_day() == 1, "Após Dia 7, próximo deve voltar ao Dia 1")
	var res8: Dictionary = save_mgr.claim_daily_bonus()
	assert(int(res8.get("day", 0)) == 1 and int(res8.get("coins", 0)) == 50, "Novo ciclo deve iniciar no Dia 1 (+50)")
	print("✔ Teste 3: Reinício automático do ciclo após Dia 7 OK.")

	# 4. Perda de sequência ao pular 1 dia inteiro (gap >= 2 dias)
	save_mgr._debug_day_override = 20008
	save_mgr.claim_daily_bonus() # Dia 2
	assert(save_mgr.get_daily_bonus_effective_streak() == 2, "Deve estar no streak 2")
	save_mgr._debug_day_override = 20010 # Pulou o dia 20009!
	assert(save_mgr.get_daily_bonus_effective_streak() == 0, "Pular um dia deve zerar o streak efetivo")
	assert(save_mgr.get_daily_bonus_next_day() == 1, "Após perder streak, volta para Dia 1")
	print("✔ Teste 4: Reset de streak ao pular dia OK.")

	# 5. Instanciação da cena DailyBonusModal e MainMenu sem erros de parse
	var modal_scene: PackedScene = load("res://scenes/ui/daily_bonus_modal.tscn") as PackedScene
	assert(modal_scene != null, "daily_bonus_modal.tscn deve carregar")
	var modal: Control = modal_scene.instantiate() as Control
	assert(modal != null, "DailyBonusModal deve instanciar sem erros")
	add_child(modal)
	modal.queue_free()

	var main_menu_scene: PackedScene = load("res://scenes/menu/main_menu.tscn") as PackedScene
	assert(main_menu_scene != null, "main_menu.tscn deve carregar")
	var main_menu: Node3D = main_menu_scene.instantiate() as Node3D
	assert(main_menu != null, "MainMenu deve instanciar sem erros")
	main_menu.queue_free()
	print("✔ Teste 5: Cenas DailyBonusModal e MainMenu validadas OK.")

	# Limpa o estado de teste para não sujar o save local
	save_mgr._debug_day_override = -1
	save_mgr.reset_to_defaults()

	print("==================================================")
	print("✅ [SUCESSO] Todos os testes do Bônus Diário passaram!")
	print("==================================================")
	get_tree().quit(0)
