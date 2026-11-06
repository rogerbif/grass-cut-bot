extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

func _ready() -> void:
	print("--- TESTE: NÃO REPETIÇÃO DE ÁUDIO & CONTROLE EXATO DE METAS ---")
	test_no_repeat_goal_completed_sound()
	test_phases_goals_exact_balance()
	print("--- TODOS OS TESTES PASSARAM COM SUCESSO! ---")
	get_tree().quit(0)

func test_no_repeat_goal_completed_sound() -> void:
	print("1. Testando GameManager.register_cut com meta batida e cortes extras...")
	var test_goals: Dictionary = {
		"wheat": 2,
		"grass_green": 1
	}
	GameManager.start_level(99, test_goals, 60.0)
	
	var goal_completed_events: Array[String] = []
	var on_completed: Callable = func(p_type: String) -> void:
		goal_completed_events.append(p_type)
	GameManager.goal_completed.connect(on_completed)
	
	# Primeiro corte de trigo: faltava 2, agora falta 1
	GameManager.register_cut("wheat", 3, Vector3.ZERO)
	assert(goal_completed_events.size() == 0, "Não deve emitir goal_completed com 1 restante")
	assert(GameManager.get_remaining_goal("wheat") == 1, "Deve restar 1 trigo")
	
	# Segundo corte de trigo: atinge a meta exata (restante == 0)
	GameManager.register_cut("wheat", 3, Vector3.ZERO)
	assert(goal_completed_events.size() == 1, "Deve emitir goal_completed exatamente 1 vez ao atingir a meta")
	assert(goal_completed_events[0] == "wheat", "Evento deve ser de trigo")
	assert(GameManager.get_remaining_goal("wheat") == 0, "Deve restar 0 trigo")
	
	# Terceiro corte de trigo (corte excedente da mesma espécie já concluída):
	GameManager.register_cut("wheat", 3, Vector3.ZERO)
	assert(goal_completed_events.size() == 1, "NÃO PODE emitir goal_completed nem tocar som ao cortar tufo excedente")
	assert(GameManager.get_remaining_goal("wheat") == 0, "Deve continuar 0 restante")
	
	# Quarto corte de trigo (mais um excedente):
	GameManager.register_cut("wheat", 3, Vector3.ZERO)
	assert(goal_completed_events.size() == 1, "Permanece exatamente 1 disparo sem repetições")
	
	# Agora atinge a meta de grama verde:
	GameManager.register_cut("grass_green", 1, Vector3.ZERO)
	assert(goal_completed_events.size() == 2, "Agora deve disparar para grass_green")
	assert(goal_completed_events[1] == "grass_green", "Segundo evento deve ser grass_green")
	
	# Corte excedente de grama verde:
	GameManager.register_cut("grass_green", 1, Vector3.ZERO)
	assert(goal_completed_events.size() == 2, "NÃO PODE repetir para grass_green excedente")
	
	GameManager.goal_completed.disconnect(on_completed)
	print("✔ Teste 1 aprovado: Som e evento de conclusão tocam estritamente 1 vez!")

func test_phases_goals_exact_balance() -> void:
	print("2. Testando balanço de metas físicas vs entregues das Fases 1 a 5...")
	for lvl in [1, 2, 3, 4, 5]:
		var data: Dictionary = LevelJsonLoader.load_json_file("res://data/levels/level_%02d.json" % lvl)
		assert(not data.is_empty(), "Fase %d deve existir" % lvl)
		
		var vg: Node3D = VegetationGridScript.new() as Node3D
		add_child(vg)
		var runtime_goals: Dictionary = vg.call("build_from_level_json", data, null, null) as Dictionary
		
		var phys_grass_dict: Dictionary = vg.get("_remaining_grass_by_type") as Dictionary
		
		for gk in runtime_goals:
			var target: int = int(runtime_goals[gk])
			if gk.begins_with("grass_"):
				var raw_phys: int = int(phys_grass_dict.get(gk, 0))
				var max_units: int = maxi(1, int(ceilf(float(raw_phys) / 6.0)))
				assert(target == max_units, "Fase %d meta %s deve ter exatamente %d unidades (tinha %d)" % [lvl, gk, max_units, target])
			elif gk == "wheat":
				var w_cnt: int = int(vg.get("_total_physical_wheat"))
				assert(target == w_cnt, "Fase %d trigo deve ser 1:1 (%d vs %d)" % [lvl, w_cnt, target])
			elif gk.begins_with("flower"):
				assert(target > 0, "Fase %d flor %s deve ser maior que 0" % [lvl, gk])
		
		print("✔ Fase %02d validada com paridade 100%% física: %s" % [lvl, JSON.stringify(runtime_goals)])
		vg.queue_free()
