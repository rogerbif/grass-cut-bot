extends Node

func _ready() -> void:
	print("--- INICIANDO TESTE DE INCLINAÇÃO DA SERRA (BLADE TILT) ---")
	
	# 1. Instancia o cortador oficial de gameplay
	var cutter_scene: PackedScene = load("res://scenes/cutter/cutter.tscn")
	var cutter: CharacterBody3D = cutter_scene.instantiate() as CharacterBody3D
	add_child(cutter)

	var robot_body: Node3D = cutter.get_node_or_null("VisualPivot/GrassBot/Robot/Body") as Node3D
	assert(robot_body != null, "robot_body deve existir na cena Cutter!")

	var blade_spinner: Node3D = robot_body.get_node_or_null("BladeSpinner") as Node3D
	assert(blade_spinner != null, "BladeSpinner deve ter sido reparentado para dentro de Body no _ready()!")
	print("✔ Teste 1: BladeSpinner reparentado com sucesso sob Body.")

	# 2. Testa inclinação frontal (Pitch = +6.0°)
	robot_body.rotation.x = deg_to_rad(6.0)
	var body_up: Vector3 = robot_body.global_transform.basis.y.normalized()
	var blade_up: Vector3 = blade_spinner.global_transform.basis.y.normalized()
	var angle_diff: float = rad_to_deg(body_up.angle_to(blade_up))
	assert(is_equal_approx(angle_diff, 0.0), "A lâmina deve acompanhar o pitch do corpo!")
	print("✔ Teste 2: Inclinação frontal (pitch +6.0°) validada com desvio 0.0°.")

	# 3. Testa inclinação traseira e rolagem lateral (Pitch = -4.0°, Roll = +4.5°)
	robot_body.rotation.x = deg_to_rad(-4.0)
	robot_body.rotation.z = deg_to_rad(4.5)
	body_up = robot_body.global_transform.basis.y.normalized()
	blade_up = blade_spinner.global_transform.basis.y.normalized()
	angle_diff = rad_to_deg(body_up.angle_to(blade_up))
	assert(is_equal_approx(angle_diff, 0.0), "A lâmina deve acompanhar pitch e roll combinados!")
	print("✔ Teste 3: Inclinação combinada (pitch -4.0° e roll +4.5°) validada com desvio 0.0°.")

	# 4. Testa rotação contínua da serra no plano inclinado
	blade_spinner.rotate_y(deg_to_rad(120.0))
	blade_up = blade_spinner.global_transform.basis.y.normalized()
	angle_diff = rad_to_deg(body_up.angle_to(blade_up))
	assert(is_equal_approx(angle_diff, 0.0), "A rotação da serra deve permanecer coplanar ao deck inclinado!")
	print("✔ Teste 4: Rotação contínua da lâmina (rotate_y) mantém coplanaridade perfeita.")

	# 5. Testa o MenuBot da tela Home
	var menu_bot_scene: PackedScene = load("res://scenes/menu/menu_bot.tscn")
	var menu_bot: Node3D = menu_bot_scene.instantiate() as Node3D
	add_child(menu_bot)

	var menu_body: Node3D = menu_bot.get_node_or_null("VisualPivot/GrassBot/Robot/Body") as Node3D
	assert(menu_body != null, "menu_body deve existir na cena MenuBot!")

	var menu_blade: Node3D = menu_body.get_node_or_null("BladeSpinner") as Node3D
	assert(menu_blade != null, "BladeSpinner do MenuBot deve ter sido reparentado para dentro de Body no _ready()!")

	menu_body.rotation.x = deg_to_rad(3.5) # Pitch de avanço no menu
	var menu_body_up: Vector3 = menu_body.global_transform.basis.y.normalized()
	var menu_blade_up: Vector3 = menu_blade.global_transform.basis.y.normalized()
	var menu_angle_diff: float = rad_to_deg(menu_body_up.angle_to(menu_blade_up))
	assert(is_equal_approx(menu_angle_diff, 0.0), "A lâmina do MenuBot deve acompanhar o pitch no menu!")
	print("✔ Teste 5: MenuBot reparentado e inclinação da serra validada no menu inicial.")

	# 6. Testa nivelamento imediato ao iniciar comemoração de vitória
	cutter.call("play_victory_celebration")
	assert(is_equal_approx(float(cutter.get("current_pitch")), 0.0), "current_pitch deve ser zerado na vitória!")
	assert(is_equal_approx(float(cutter.get("current_roll")), 0.0), "current_roll deve ser zerado na vitória!")
	print("✔ Teste 6: Nivelamento de pitch/roll na comemoração de vitória validado.")

	print("==================================================")
	print(">>> TODOS OS TESTES DE INCLINAÇÃO DA SERRA PASSARAM COM 100% DE SUCESSO! <<<")
	print("==================================================")
	get_tree().quit(0)
