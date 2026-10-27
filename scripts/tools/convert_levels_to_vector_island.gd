extends SceneTree

const IslandMeshBuilderScript = preload("res://scripts/level/island_mesh_builder.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

func _init() -> void:
	print("--- INICIANDO MIGRAÇÃO DOS NÍVEIS PARA ILHAS VETORIAIS (v4) ---")

	var success_count: int = 0
	for lvl in range(1, 21):
		var path: String = "res://data/levels/level_%02d.json" % lvl
		var data: Dictionary = LevelJsonLoader.load_json_file(path)
		if data.is_empty():
			print("Nível %02d não encontrado em %s" % [lvl, path])
			continue

		var terrain_arr: Array = data.get("terrain", []) as Array
		var grid_info: Dictionary = data.get("grid", {}) as Dictionary
		var width: int = int(grid_info.get("width", 12))
		var height: int = int(grid_info.get("height", 8))
		var cell_size: float = float(grid_info.get("cell_size", 0.80))

		var polys: Array[PackedVector2Array] = IslandMeshBuilderScript.convert_tile_grid_to_polygons(
			terrain_arr, width, height, cell_size
		)

		if polys.is_empty():
			print("ERRO: Nível %02d gerou polígonos vazios!" % lvl)
			continue

		var polys_data: Array = []
		for p: PackedVector2Array in polys:
			var pts: Array = []
			for pt: Vector2 in p:
				pts.append([snappedf(pt.x, 0.001), snappedf(pt.y, 0.001)])
			polys_data.append(pts)

		data["version"] = 4
		data["island_polygons"] = polys_data

		var json_str: String = JSON.stringify(data, "\t")
		var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(json_str)
			file.close()
			print("Nível %02d migrado com sucesso: %d polígono(s), %d vértices" % [lvl, polys.size(), polys[0].size()])
			success_count += 1
		else:
			print("FALHA ao salvar nível %02d!" % lvl)

	print("--- MIGRAÇÃO CONCLUÍDA: %d/20 níveis migrados para v4 ---" % success_count)
	quit()
