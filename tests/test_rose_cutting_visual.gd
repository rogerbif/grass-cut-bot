extends Node3D

const FlowerRoseScene = preload("res://scenes/plants/flower_rose.tscn")

func _ready() -> void:
	print("--- TESTE DE CORTE E DESPETALAÇÃO DA ROSA NOBRE ---")
	var rose: Node3D = FlowerRoseScene.instantiate()
	add_child(rose)
	rose.global_position = Vector3(0, 0, 0)
	
	# Aguarda 2 frames
	await get_tree().process_frame
	await get_tree().process_frame
	
	print("1. Rosa instanciada com saúde:", rose.get("health"))
	assert(rose.get("health") == 3, "Rosa deve iniciar com 3 HP")
	
	# Verifica que Flower_Stem tem o novo material com gradiente escuro -> claro
	var stem_mi: MeshInstance3D = rose.find_child("Flower_Stem", true, false) as MeshInstance3D
	assert(stem_mi != null, "Flower_Stem deve existir")
	var stem_mat: Material = stem_mi.get_surface_override_material(0)
	assert(stem_mat != null, "Flower_Stem deve ter surface_material_override")
	print("  [OK] Flower_Stem usando material com gradiente:", stem_mat.resource_path)
	
	# Aplica Hit 1
	print("2. Aplicando Hit 1 (corte de raio)...")
	rose.call("cut", 1)
	assert(rose.get("health") == 2, "Rosa deve ter 2 HP após Hit 1")
	print("  [OK] Hit 1 aplicado com sucesso! Saúde restante: 2")
	
	# Aguarda cooldown de 0.28s entre hits
	await get_tree().create_timer(0.32).timeout
		
	# Aplica Hit 2
	print("3. Aplicando Hit 2 (segunda despetalação)...")
	rose.call("cut", 1)
	assert(rose.get("health") == 1, "Rosa deve ter 1 HP após Hit 2")
	print("  [OK] Hit 2 aplicado com sucesso! Saúde restante: 1")
	
	await get_tree().create_timer(0.32).timeout
		
	# Aplica Hit 3 (ceifa fatal)
	print("4. Aplicando Hit 3 (ceifa fatal)...")
	rose.call("cut", 1)
	assert(rose.get("health") == 0, "Rosa deve ter 0 HP após Hit 3")
	print("  [OK] Hit 3 ceifou a flor com sucesso!")
	
	print("==========================================")
	print("✅ TESTE DE CORTE DA ROSA CONCLUÍDO SEM ERROS!")
	print("==========================================")
	get_tree().quit(0)
