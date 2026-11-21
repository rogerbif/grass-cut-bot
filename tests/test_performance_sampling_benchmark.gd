extends SceneTree

const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const LevelJsonLoaderScript = preload("res://scripts/level/level_json_loader.gd")

func _init() -> void:
	print("--- TESTE DE BENCHMARK DE PERFORMANCE: CARREGAMENTO & AMOSTRAGEM ---")
	var total_time_ms: int = 0
	var total_tufts: int = 0

	VectorGrassField.clear_global_cache()

	var t_start_all: int = Time.get_ticks_msec()

	for lvl: int in range(1, 41):
		var path: String = "res://data/levels/level_%02d.json" % lvl
		if not FileAccess.file_exists(path):
			continue

		var fa: FileAccess = FileAccess.open(path, FileAccess.READ)
		var text: String = fa.get_as_text()
		fa.close()

		var json: JSON = JSON.new()
		if json.parse(text) != OK:
			continue
		var data: Dictionary = json.data as Dictionary

		var vf: RefCounted = VectorGrassFieldScript.new()
		if data.has("grass_sample_distance"):
			vf.set("sample_distance", float(data["grass_sample_distance"]))
		if data.has("grass_vectors") and data["grass_vectors"] is Array:
			vf.call("from_dict_list", data["grass_vectors"] as Array)

		var t0: int = Time.get_ticks_msec()
		var tufts: Array = vf.call("sample_all_tufts") as Array
		var elapsed: int = Time.get_ticks_msec() - t0

		total_time_ms += elapsed
		total_tufts += tufts.size()

		if lvl == 36 or elapsed > 50:
			print("Fase %02d: %d tufos em %d ms" % [lvl, tufts.size(), elapsed])

	var total_wall_ms: int = Time.get_ticks_msec() - t_start_all
	print("TOTAL 40 FASES: %d tufos amostrados em %d ms (CPU pura: %d ms)" % [total_tufts, total_wall_ms, total_time_ms])

	# Valida o ganho de tempo do cache (2ª chamada para a mesma fase)
	var vf_cache: RefCounted = VectorGrassFieldScript.new()
	vf_cache.set("cache_key", "level_1")
	var t_cache0: int = Time.get_ticks_msec()
	var _cached_result: Array = vf_cache.call("sample_all_tufts") as Array
	var elapsed_cache: int = Time.get_ticks_msec() - t_cache0
	print("Segunda amostragem com CACHE (Fase 01): %d ms" % elapsed_cache)

	print("BENCHMARK CONCLUIDO COM SUCESSO!")
	quit(0)
