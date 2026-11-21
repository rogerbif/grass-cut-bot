extends SceneTree

const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const LevelJsonLoaderScript = preload("res://scripts/level/level_json_loader.gd")

func _init() -> void:
	print("--- TESTE DE VALIDACAO: MULTIMESH SPATIAL CHUNKING & AABB ---")

	var path: String = "res://data/levels/level_36.json"
	var fa: FileAccess = FileAccess.open(path, FileAccess.READ)
	var text: String = fa.get_as_text()
	fa.close()

	var json: JSON = JSON.new()
	assert(json.parse(text) == OK)
	var data: Dictionary = json.data as Dictionary

	var root_node: Node3D = Node3D.new()
	root.add_child(root_node)
	current_scene = root_node

	var veg_grid: Node3D = VegetationGridScript.new()
	root_node.add_child(veg_grid)

	var obstacles: Node3D = Node3D.new()
	root_node.add_child(obstacles)

	var goals: Dictionary = veg_grid.call("build_from_level_json", data, obstacles, null) as Dictionary
	print("Metas construidas com sucesso: ", goals)

	var total_plants: int = int(veg_grid.get("_positions").size())
	print("Total de plantas no VegetationGrid: ", total_plants)
	assert(total_plants > 2000, "Level 36 deve ter mais de 2000 plantas")

	var multimeshes: Array = veg_grid.get("_veg_multimeshes") as Array
	var mmi_nodes: Array = veg_grid.get("_veg_mmi_nodes") as Array
	print("Quantidade de MultiMeshes (chunks) criados: ", multimeshes.size())
	assert(multimeshes.size() > 2, "Deveria ter multiplos chunks para Level 36")

	# Verifica se cada MultiMeshInstance3D possui um custom_aabb valido e restrito (não o FIXED gigante)
	for i: int in range(mmi_nodes.size()):
		var mmi: MultiMeshInstance3D = mmi_nodes[i] as MultiMeshInstance3D
		if mmi != null:
			var aabb: AABB = mmi.custom_aabb
			print("Chunk %d (%s): inst_count=%d AABB=%s" % [
				i,
				mmi.name,
				mmi.multimesh.instance_count,
				str(aabb)
			])
			assert(aabb.size.x > 0.0 and aabb.size.z > 0.0, "AABB deve ser valido")
			assert(aabb.size.x < 50.0 and aabb.size.z < 50.0, "AABB deve ser menor que o antigo FIXED_ISLAND_AABB de 70x70")

	# Testa corte simulado em um ponto qualquer
	var p0: Vector3 = (veg_grid.get("_positions") as Array)[0] as Vector3
	var recoil: Vector3 = veg_grid.call("cut_in_circle", p0, 1.5, 10) as Vector3
	print("Recoil retornado pelo corte: ", recoil)
	var is_cut_arr: PackedByteArray = veg_grid.get("_is_cut") as PackedByteArray
	assert(is_cut_arr[0] == 1, "Planta 0 deve estar marcada como cortada")

	print("TESTE DE MULTIMESH CHUNKING PASSOU COM SUCESSO!")
	root_node.queue_free()
	quit(0)
