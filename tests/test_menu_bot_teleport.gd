extends Node

const MENU_BOT_SCENE: PackedScene = preload("res://scenes/menu/menu_bot.tscn")
const TELEPORT_SHADER: Shader = preload("res://shaders/teleport_effect.gdshader")

func _ready() -> void:
	print("--- INICIANDO TESTE DO SISTEMA DE TELEPORTE (CUTTER BOT) ---")

	assert(TELEPORT_SHADER != null, "Shader de teleporte deve estar carregado e compilado!")
	print("✔ Teste 1: Shader de teleporte carregado com sucesso.")

	var bot: Node3D = MENU_BOT_SCENE.instantiate() as Node3D
	assert(bot != null, "MenuBot deve ser instanciado a partir da cena!")
	add_child(bot)
	print("✔ Teste 2: MenuBot instanciado e adicionado à árvore.")

	var initial_pos: Vector3 = Vector3(0.0, 0.0, 0.0)
	var target_pos: Vector3 = Vector3(5.5, 0.0, -18.5)
	bot.position = initial_pos

	var status: Dictionary = {"completed": false}
	bot.teleport_to_position(target_pos, func() -> void:
		status["completed"] = true
	)

	assert(bot.get("is_teleporting") == true, "Bot deve estar com is_teleporting = true durante o teleporte!")
	var mats: Array = bot.get("_teleport_materials") as Array
	assert(mats.size() > 0, "Materiais de teleporte devem ter sido atribuídos às superfícies!")
	print("✔ Teste 3: Teleporte iniciado, materiais e estado de transição validados.")

	# Aguarda a animação do teleporte concluir (~0.85s)
	await get_tree().create_timer(1.0).timeout

	assert(status["completed"] == true, "Callback de conclusão de teleporte deve ter sido disparado!")
	assert(bot.get("is_teleporting") == false, "Bot deve desativar is_teleporting após conclusão!")
	assert(bot.position.is_equal_approx(target_pos), "Posição final do robô deve corresponder ao destino!")
	var cleared_mats: Array = bot.get("_teleport_materials") as Array
	assert(cleared_mats.is_empty(), "Lista de materiais de teleporte deve ser liberada após conclusão!")
	print("✔ Teste 4: Ciclo completo de desintegração, reposicionamento e materialização concluído.")

	print("--- TODOS OS TESTES DE TELEPORTE PASSARAM COM SUCESSO! ---")
