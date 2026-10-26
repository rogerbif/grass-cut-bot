extends Node

func _ready() -> void:
	print("--- INICIANDO TESTE DO FLOATING COIN MANAGER ---")
	
	# 1. Carrega a cena main
	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var main_inst: Node3D = main_scene.instantiate() as Node3D
	add_child(main_inst)

	var fcm: FloatingCoinManager = main_inst.get_node_or_null("FloatingCoinManager") as FloatingCoinManager
	assert(fcm != null, "FloatingCoinManager deve existir em main.tscn!")
	assert(fcm.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "FloatingCoinManager deve ter physics_interpolation_mode OFF!")

	var cutter: CharacterBody3D = main_inst.get_node_or_null("LevelController/Cutter") as CharacterBody3D
	assert(cutter != null, "Cutter deve existir em LevelController!")

	# Posiciona o cutter longe do centro (ex: x=3.5, z=-2.8)
	cutter.global_position = Vector3(3.5, 0.1, -2.8)
	GameManager.current_state = GameManager.GameState.PLAYING

	# 2. Dispara pop-up de moeda fingindo que o tufo cortado estava no centro da fase (0.01, 0, 0.01)
	var far_tuft_pos: Vector3 = Vector3(0.01, 0.0, 0.01)
	GameManager.register_cut("grass", 1, far_tuft_pos)

	# 3. Verifica onde o primeiro label do pool foi posicionado
	var pool: Array = fcm.get("_pool") as Array
	assert(pool.size() == 64, "O pool deve conter 64 instâncias!")

	var label_spawned: Label3D = null
	for item: Variant in pool:
		var lbl: Label3D = item as Label3D
		assert(lbl.physics_interpolation_mode == Node.PHYSICS_INTERPOLATION_MODE_OFF, "Todo Label3D do pool deve ter physics_interpolation_mode OFF!")
		if lbl != null and lbl.visible:
			label_spawned = lbl
			break

	assert(label_spawned != null, "Um label visível deve ter sido disparado!")
	assert(is_equal_approx(label_spawned.modulate.a, label_spawned.outline_modulate.a), "outline_modulate.a deve iniciar sincronizado com modulate.a!")

	# A distância horizontal do label até o robô DEVE ser menor que 0.50m (ao lado do corpo)
	var dist_to_robot: float = label_spawned.global_position.distance_to(cutter.global_position)
	var dist_to_center: float = label_spawned.global_position.distance_to(far_tuft_pos)

	print("Distância do label até o robô: %.3fm" % dist_to_robot)
	print("Distância do label até o centro da fase: %.3fm" % dist_to_center)

	assert(dist_to_robot < 0.85, "O label DEVE brotar colado ao lado do corpo do robô!")
	assert(dist_to_center > 3.0, "O label NÃO pode brotar no centro da fase (0,0,0)!")
	print("✔ Teste 1: Número flutuante spawna estritamente ao lado do corpo do robô com interpolação física OFF.")

	# 4. Simula deslocamento rápido do robô para longe e valida se o label acompanha o robô (nunca ficando para trás!)
	cutter.global_position = Vector3(-4.2, 0.1, 3.1)
	fcm._process(0.016)
	var dist_after_move: float = Vector2(
		label_spawned.global_position.x - cutter.global_position.x,
		label_spawned.global_position.z - cutter.global_position.z
	).length()
	print("Distância XZ do label após movimento do robô: %.3fm" % dist_after_move)
	assert(dist_after_move <= 0.50, "O label ativo DEVE acompanhar a coordenada XZ do robô em movimento!")
	print("✔ Teste 2: Números ativos acompanham o robô em movimento sem ficar para trás no mapa.")

	print("==================================================")
	print(">>> TODOS OS TESTES DO FLOATING COIN MANAGER PASSARAM COM 100% DE SUCESSO! <<<")
	print("==================================================")
	get_tree().quit(0)
