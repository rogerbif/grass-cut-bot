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
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 3.25), "Velocidade do Nível 1 é 3.25m/s")
	assert_true(UpgradeManager.get_blade_tier() == 1, "Tier visual no Nível 1 é 1")

	# 2. Teste de Ganho de XP e Level Up (Lv 1 -> Lv 2: precisa de 50 XP)
	UpgradeManager.add_blade_xp(25.0)
	assert_true(UpgradeManager.blade_level == 1 and is_equal_approx(UpgradeManager.blade_xp, 25.0), "25 XP acumulado no Lv 1")
	assert_true(is_equal_approx(UpgradeManager.get_progress_ratio(), 0.5), "Ratio é 50%")

	UpgradeManager.add_blade_xp(25.0)
	assert_true(UpgradeManager.blade_level == 2 and is_equal_approx(UpgradeManager.blade_xp, 0.0), "Subiu para Lv 2 com 50 XP")
	assert_true(is_equal_approx(UpgradeManager.get_blade_radius(), 1.00), "Raio do Nível 2 é 1.00m")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 3.55), "Velocidade do Nível 2 é 3.55m/s")

	# 3. Subir até Nível 6 (MAX)
	# Lv 2 -> 3: 100 XP
	UpgradeManager.add_blade_xp(100.0)
	assert_true(UpgradeManager.blade_level == 3, "Subiu para Lv 3")
	assert_true(UpgradeManager.get_blade_tier() == 2, "Tier visual no Nível 3 é 2")

	# Lv 3 -> 4: 180 XP
	UpgradeManager.add_blade_xp(180.0)
	assert_true(UpgradeManager.blade_level == 4, "Subiu para Lv 4")
	assert_true(is_equal_approx(UpgradeManager.get_blade_radius(), 1.20), "Raio do Nível 4 é 1.20m")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 4.15), "Velocidade do Nível 4 é 4.15m/s")

	# Lv 4 -> 5: 280 XP
	UpgradeManager.add_blade_xp(280.0)
	assert_true(UpgradeManager.blade_level == 5, "Subiu para Lv 5")
	assert_true(UpgradeManager.get_blade_tier() == 3, "Tier visual no Nível 5 é 3")

	# Lv 5 -> 6 (MAX): 400 XP
	UpgradeManager.add_blade_xp(400.0)
	assert_true(UpgradeManager.blade_level == 6, "Subiu para Lv 6 (MAX)")
	assert_true(is_equal_approx(UpgradeManager.get_blade_radius(), 1.40), "Raio do Nível 6 (MAX) é 1.40m")
	assert_true(is_equal_approx(UpgradeManager.get_cutter_speed(), 4.75), "Velocidade do Nível 6 (MAX) é 4.75m/s")
	assert_true(UpgradeManager.get_blade_tier() == 4, "Tier visual no Nível 6 é 4 (Hexagonal)")
	assert_true(is_equal_approx(UpgradeManager.get_progress_ratio(), 1.0), "Ratio no MAX é 1.0 (100%)")

	# Adicionar XP além do MAX não deve estourar
	UpgradeManager.add_blade_xp(500.0)
	assert_true(UpgradeManager.blade_level == 6, "Permanece no Nível 6 após XP extra")

	# 4. Teste de Penalidade na Rocha (Opção A)
	# Lv 6 sofre choque -> cai para Lv 5 com XP zerado
	UpgradeManager.penalize_blade_hit()
	assert_true(UpgradeManager.blade_level == 5 and is_equal_approx(UpgradeManager.blade_xp, 0.0), "Penalidade reduziu Lv 6 para Lv 5")

	# Reduzir até Lv 1
	UpgradeManager.penalize_blade_hit() # 5 -> 4
	UpgradeManager.penalize_blade_hit() # 4 -> 3
	UpgradeManager.penalize_blade_hit() # 3 -> 2
	UpgradeManager.penalize_blade_hit() # 2 -> 1
	assert_true(UpgradeManager.blade_level == 1, "Chegou ao Lv 1")

	# Penalidade no Lv 1 com XP
	UpgradeManager.add_blade_xp(20.0)
	assert_true(is_equal_approx(UpgradeManager.blade_xp, 20.0), "Acumulou 20 XP no Lv 1")
	UpgradeManager.penalize_blade_hit()
	assert_true(UpgradeManager.blade_level == 1 and is_equal_approx(UpgradeManager.blade_xp, 0.0), "Penalidade no Lv 1 apenas zera XP")

	# 5. Teste de Compra na Garagem até Nível 5
	UpgradeManager.total_coins = 2000
	assert_true(UpgradeManager.get_blade_upgrade_cost() == 75, "Custo para Lv 2 é 75 moedas")
	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 2")
	assert_true(UpgradeManager.blade_level == 2 and UpgradeManager.total_coins == 1925, "Lv 2 ativo, moedas debitadas")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 3 (150 moedas)")
	assert_true(UpgradeManager.blade_level == 3 and UpgradeManager.total_coins == 1775, "Lv 3 ativo")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 4 (300 moedas)")
	assert_true(UpgradeManager.blade_level == 4 and UpgradeManager.total_coins == 1475, "Lv 4 ativo")

	assert_true(UpgradeManager.buy_blade_upgrade(), "Comprou Lv 5 (550 moedas)")
	assert_true(UpgradeManager.blade_level == 5 and UpgradeManager.total_coins == 925, "Lv 5 ativo")

	# Tentar comprar Lv 6 na loja (deve ser proibido)
	assert_true(UpgradeManager.get_blade_upgrade_cost() == -1, "Custo para Lv 6 na loja é -1 (proibido)")
	assert_true(not UpgradeManager.can_buy_blade_upgrade(), "can_buy_blade_upgrade() retorna false para Lv 5+")
	assert_true(not UpgradeManager.buy_blade_upgrade(), "buy_blade_upgrade() rejeitado para Lv 5+")

	# 6. Teste de Serialização SaveManager
	var exported: Dictionary = UpgradeManager.export_to_dict()
	assert_true(int(exported.get("blade_level", 0)) == 5, "Exportou blade_level 5")
	UpgradeManager.load_from_dict({"blade_level": 4, "blade_xp": 120.0}, 200)
	assert_true(UpgradeManager.blade_level == 4 and is_equal_approx(UpgradeManager.blade_xp, 120.0), "Carregou blade_level 4 e 120 XP")
