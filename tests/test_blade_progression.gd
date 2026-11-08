extends Node

func _ready() -> void:
	print("--- INICIANDO TESTE AUTOMATIZADO: PROGRESSÃO DA LÂMINA ---")
	test_blade_progression()
	print("--- TODOS OS TESTES PASSARAM COM SUCESSO! ---")
	get_tree().quit(0)

func assert_true(cond: bool, msg: String) -> void:
	if not cond:
		printerr("FALHA: %s" % msg)
		get_tree().quit(1)
	else:
		print("✔ PASSOU: %s" % msg)

func test_blade_progression() -> void:
	# 1. Teste de Estado Inicial
	UpgradeManager.load_from_dict({"blade_level": 1, "blade_xp": 0.0}, 500)
	assert_true(UpgradeManager.blade_level == 1, "Nível inicial é 1")
	assert_true(UpgradeManager.blade_xp == 0.0, "XP inicial é 0.0")
	assert_true(is_equal_approx(UpgradeManager.get_blade_radius(), 0.90), "Raio do Nível 1 é 0.90m")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 1.95), "Velocidade do Nível 1 é 1.95m/s")
	assert_true(UpgradeManager.get_blade_tier() == 1, "Tier visual no Nível 1 é 1")

	# 2. Teste de Ganho de XP e Level Up (Lv 1 -> Lv 2: precisa de 200 XP)
	UpgradeManager.add_blade_xp(100.0)
	assert_true(UpgradeManager.blade_level == 1 and is_equal_approx(UpgradeManager.blade_xp, 100.0), "100 XP acumulado no Lv 1")
	assert_true(is_equal_approx(UpgradeManager.get_progress_ratio(), 0.5), "Ratio é 50%")

	UpgradeManager.add_blade_xp(100.0)
	assert_true(UpgradeManager.blade_level == 2 and is_equal_approx(UpgradeManager.blade_xp, 0.0), "Subiu para Lv 2 com 200 XP")
	assert_true(is_equal_approx(UpgradeManager.get_blade_radius(), 0.90 + 0.50 / 9.0), "Raio do Nível 2 é ~0.956m")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 2.13), "Velocidade do Nível 2 é 2.13m/s")

	# 3. Subir progressivamente até Nível 10 (MAX)
	# Lv 2 -> 3: 350 XP
	UpgradeManager.add_blade_xp(350.0)
	assert_true(UpgradeManager.blade_level == 3, "Subiu para Lv 3")
	assert_true(UpgradeManager.get_blade_tier() == 1, "Tier visual no Nível 3 é 1 (Tripla)")

	# Lv 3 -> 4: 550 XP
	UpgradeManager.add_blade_xp(550.0)
	assert_true(UpgradeManager.blade_level == 4, "Subiu para Lv 4")
	assert_true(UpgradeManager.get_blade_tier() == 2, "Tier visual no Nível 4 é 2 (Quádrupla)")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 2.49), "Velocidade do Nível 4 é 2.49m/s")

	# Lv 4 -> 5: 800 XP
	UpgradeManager.add_blade_xp(800.0)
	assert_true(UpgradeManager.blade_level == 5, "Subiu para Lv 5")

	# Lv 5 -> 6: 1200 XP
	UpgradeManager.add_blade_xp(1200.0)
	assert_true(UpgradeManager.blade_level == 6, "Subiu para Lv 6")
	assert_true(not UpgradeManager.is_max_level(), "is_max_level() é false no Nível 6")

	# Lv 6 -> 7: 1700 XP
	UpgradeManager.add_blade_xp(1700.0)
	assert_true(UpgradeManager.blade_level == 7, "Subiu para Lv 7")
	assert_true(UpgradeManager.get_blade_tier() == 3, "Tier visual no Nível 7 é 3 (Titânio)")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 3.03), "Velocidade do Nível 7 é 3.03m/s")

	# Lv 7 -> 8: 2400 XP
	UpgradeManager.add_blade_xp(2400.0)
	assert_true(UpgradeManager.blade_level == 8, "Subiu para Lv 8")

	# Lv 8 -> 9: 3300 XP
	UpgradeManager.add_blade_xp(3300.0)
	assert_true(UpgradeManager.blade_level == 9, "Subiu para Lv 9")
	assert_true(UpgradeManager.get_blade_tier() == 4, "Tier visual no Nível 9 é 4 (Hexagonal)")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 3.39), "Velocidade do Nível 9 é 3.39m/s")

	# Lv 9 -> 10 (MAX): 1500 XP
	UpgradeManager.add_blade_xp(1500.0)
	assert_true(UpgradeManager.blade_level == 10, "Subiu para Lv 10 (MAX)")
	assert_true(is_equal_approx(UpgradeManager.get_blade_radius(), 1.40), "Raio do Nível 10 (MAX) é 1.40m")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 3.57), "Velocidade do Nível 10 (MAX) é 3.57m/s (+25%)")
	assert_true(UpgradeManager.get_blade_tier() == 4, "Tier visual no Nível 10 é 4 (Hexagonal)")
	assert_true(is_equal_approx(UpgradeManager.get_progress_ratio(), 1.0), "Ratio no MAX é 1.0 (100%)")
	assert_true(UpgradeManager.is_max_level(), "is_max_level() é true no Nível 10")

	# Adicionar XP além do MAX não deve estourar
	UpgradeManager.add_blade_xp(500.0)
	assert_true(UpgradeManager.blade_level == 10, "Permanece no Nível 10 após XP extra")

	# 4. Teste de Penalidade na Rocha por Quantidade Fixa (1.000 XP)
	# Lv 10 (MAX) sofre choque -> desce para Lv 9 com 1500 - 1000 = 500 XP
	UpgradeManager.penalize_blade_hit()
	assert_true(UpgradeManager.blade_level == 9 and is_equal_approx(UpgradeManager.blade_xp, 500.0), "Penalidade no Lv 10 desceu para Lv 9 com 500 XP")

	# Lv 9 com 500 XP sofre choque -> 500 - 1000 = falta 500 no Lv 8 (que requer 3300) -> Lv 8 com 2800 XP
	UpgradeManager.penalize_blade_hit()
	assert_true(UpgradeManager.blade_level == 8 and is_equal_approx(UpgradeManager.blade_xp, 2800.0), "Penalidade excedente desceu para Lv 8 com 2800 XP")

	# Lv 8 com 2800 XP sofre choque de 1000 XP -> continua Lv 8 com 1800 XP (SEM PERDER NÍVEL!)
	UpgradeManager.penalize_blade_hit()
	assert_true(UpgradeManager.blade_level == 8 and is_equal_approx(UpgradeManager.blade_xp, 1800.0), "Penalidade com XP suficiente manteve Lv 8 com 1800 XP")

	# Reduzir até Lv 1
	UpgradeManager.load_from_dict({"blade_level": 1, "blade_xp": 100.0}, 500)
	assert_true(UpgradeManager.blade_level == 1 and is_equal_approx(UpgradeManager.blade_xp, 100.0), "Reset para Lv 1 com 100 XP")
	UpgradeManager.penalize_blade_hit()
	assert_true(UpgradeManager.blade_level == 1 and is_equal_approx(UpgradeManager.blade_xp, 0.0), "Penalidade no Lv 1 apenas zera XP")

	# 5. Teste de Compra na Garagem até Nível 8
	UpgradeManager.total_coins = 15000
	assert_true(UpgradeManager.get_blade_upgrade_cost() == 100, "Custo para Lv 2 é 100 moedas")
	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 2")
	assert_true(UpgradeManager.blade_level == 2 and UpgradeManager.total_coins == 14900, "Lv 2 ativo, moedas debitadas")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 3 (250 moedas)")
	assert_true(UpgradeManager.blade_level == 3 and UpgradeManager.total_coins == 14650, "Lv 3 ativo")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 4 (500 moedas)")
	assert_true(UpgradeManager.blade_level == 4 and UpgradeManager.total_coins == 14150, "Lv 4 ativo")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 5 (900 moedas)")
	assert_true(UpgradeManager.blade_level == 5 and UpgradeManager.total_coins == 13250, "Lv 5 ativo")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 6 (1500 moedas)")
	assert_true(UpgradeManager.blade_level == 6 and UpgradeManager.total_coins == 11750, "Lv 6 ativo")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 7 (2400 moedas)")
	assert_true(UpgradeManager.blade_level == 7 and UpgradeManager.total_coins == 9350, "Lv 7 ativo")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 8 (3800 moedas)")
	assert_true(UpgradeManager.blade_level == 8 and UpgradeManager.total_coins == 5550, "Lv 8 ativo")

	# Tentar comprar Lv 9 na loja (deve ser proibido - máximo da loja é 8)
	assert_true(UpgradeManager.get_blade_upgrade_cost() == -1, "Custo para Lv 9 na loja é -1 (proibido)")
	assert_true(not UpgradeManager.can_buy_blade_upgrade(), "can_buy_blade_upgrade() retorna false para Lv 8+")
	assert_true(not UpgradeManager.buy_blade_upgrade(), "buy_blade_upgrade() rejeitado para Lv 8+")

	# 6. Teste de Serialização SaveManager
	var exported: Dictionary = UpgradeManager.export_to_dict()
	assert_true(int(exported.get("blade_level", 0)) == 8, "Exportou blade_level 8")
	UpgradeManager.load_from_dict({"blade_level": 7, "blade_xp": 120.0}, 200)
	assert_true(UpgradeManager.blade_level == 7 and is_equal_approx(UpgradeManager.blade_xp, 120.0), "Carregou blade_level 7 e 120 XP")

	# 7. Teste de Inicialização do BladeProgressBar ao mudar de fase em todos os níveis (1 a 10)
	var bar_scene: PackedScene = load("res://scenes/cutter/blade_progress_bar.tscn")
	for test_lvl in range(1, 11):
		UpgradeManager.load_from_dict({"blade_level": test_lvl, "blade_xp": 50.0}, 100)
		var test_bar: Node3D = bar_scene.instantiate() as Node3D
		add_child(test_bar)
		if test_lvl < 10:
			assert_true(not test_bar._is_max, "BladeProgressBar em Nível %d inicia com _is_max == false" % test_lvl)
			assert_true(str(test_lvl) in test_bar.level_label.text, "BladeProgressBar em Nível %d exibe texto '%s'" % [test_lvl, test_bar.level_label.text])
			assert_true(not test_bar.crown_icon.visible, "Coroa oculta no Nível %d" % test_lvl)
		else:
			assert_true(test_bar._is_max, "BladeProgressBar em Nível 10 inicia com _is_max == true")
			assert_true(test_bar.crown_icon.visible, "Coroa visível no Nível 10 MAX")
			assert_true(test_bar.level_label.text == tr("BLADE_LEVEL_MAX"), "Texto é NÍVEL MÁXIMO no Nv 10")
		test_bar.queue_free()
