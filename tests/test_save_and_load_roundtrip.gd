extends Node

const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const LevelEditorScene = preload("res://scenes/editor/level_editor.tscn")

func _ready() -> void:
	print("==================================================")
	print("🧪 TESTE: ROUNDTRIP DE SAVE E LOAD NOVO FORMATO (0.40m)")
	print("==================================================")

	var failed: int = 0
	failed += test_save_and_load_roundtrip()

	print("==================================================")
	if failed == 0:
		print("✅ TESTE DE ROUNDTRIP PASSOU COM 100% DE SUCESSO!")
		get_tree().quit(0)
	else:
		printerr("❌ FALHA NO TESTE DE ROUNDTRIP: %d erros" % failed)
		get_tree().quit(1)

func test_save_and_load_roundtrip() -> int:
	var test_lvl_id: int = 49 # Usa nível 49 para teste sem colidir com fases principais
	var level_name: String = "Fase Teste Roundtrip"
	var time_limit: float = 75.0
	var width: int = 20
	var height: int = 16
	var cell_size: float = 0.40
	var spawn_cell: Vector2i = Vector2i(10, 8)
	var spawn_rot: int = 90

	var terrain_grid: Dictionary = {}
	for z in range(height):
		for x in range(width):
			terrain_grid[Vector2i(x, z)] = {
				"tile_id": "island_center",
				"rot": 0,
				"auto": true
			}

	var object_grid: Dictionary = {
		Vector2i(4, 4): { "type": "rock", "rot": 0 },
		Vector2i(12, 10): { "type": "flower_daisy", "rot": 0 },
		Vector2i(14, 10): { "type": "wheat", "rot": 0 }
	}

	var vector_grass: RefCounted = VectorGrassFieldScript.new()
	var poly1: PackedVector2Array = PackedVector2Array([
		Vector2(-2.0, -1.0), Vector2(2.0, -1.0), Vector2(2.0, 1.0), Vector2(-2.0, 1.0)
	])
	vector_grass.call("add_shape", "grass_yellow", poly1)

	var custom_goals: Dictionary = {
		"grass_yellow": 15,
		"flower_daisy": 1,
		"wheat": 1
	}

	print("1. Gravando nível de teste %d via LevelSerializer.save_level_json..." % test_lvl_id)
	var save_ok: bool = LevelSerializer.save_level_json(
		test_lvl_id,
		level_name,
		time_limit,
		width,
		height,
		spawn_cell,
		spawn_rot,
		terrain_grid,
		object_grid,
		null,
		vector_grass,
		custom_goals,
		cell_size
	)

	if not save_ok:
		printerr("FAIL: LevelSerializer.save_level_json retornou false!")
		return 1

	print("2. Lendo arquivo JSON recém gravado via LevelJsonLoader.load_json_file...")
	var json_path: String = LevelSerializer.get_json_path(test_lvl_id)
	var loaded_data: Dictionary = LevelJsonLoader.load_json_file(json_path)

	if loaded_data.is_empty():
		printerr("FAIL: LevelJsonLoader.load_json_file retornou dicionário vazio!")
		return 1

	var g_info: Dictionary = loaded_data.get("grid", {}) as Dictionary
	var l_cell_size: float = float(g_info.get("cell_size", 0.0))
	var l_width: int = int(g_info.get("width", 0))
	var l_height: int = int(g_info.get("height", 0))

	if absf(l_cell_size - 0.40) > 0.001:
		printerr("FAIL: cell_size gravado/lido incorreto: %f (esperado 0.40)" % l_cell_size)
		return 1
	if l_width != 20 or l_height != 16:
		printerr("FAIL: Dimensões da grade incorretas: %dx%d (esperado 20x16)" % [l_width, l_height])
		return 1

	print("3. Instanciando LevelEditor e executando _load_or_init_level(%d)..." % test_lvl_id)
	var editor: Node3D = LevelEditorScene.instantiate() as Node3D
	add_child(editor)

	editor.call("_load_or_init_level", test_lvl_id)

	# Validações internas do LevelEditor após carregamento
	if editor.get("grid_width") != 20 or editor.get("grid_height") != 16:
		printerr("FAIL: LevelEditor grid_width/height incorretos: %dx%d" % [editor.get("grid_width"), editor.get("grid_height")])
		editor.queue_free()
		return 1

	var ed_terrain: Dictionary = editor.get("terrain_grid") as Dictionary
	if ed_terrain.size() != width * height:
		printerr("FAIL: terrain_grid size incorreto: %d (esperado %d)" % [ed_terrain.size(), width * height])
		editor.queue_free()
		return 1

	var ed_objects: Dictionary = editor.get("object_grid") as Dictionary
	if ed_objects.size() != 3:
		printerr("FAIL: object_grid size incorreto: %d (esperado 3)" % ed_objects.size())
		editor.queue_free()
		return 1

	if not ed_objects.has(Vector2i(4, 4)) or not ed_objects.has(Vector2i(12, 10)) or not ed_objects.has(Vector2i(14, 10)):
		printerr("FAIL: Chaves de objetos esperadas ausentes em object_grid!")
		editor.queue_free()
		return 1

	var ed_vgrass: RefCounted = editor.get("vector_grass") as RefCounted
	if ed_vgrass == null:
		printerr("FAIL: vector_grass é nulo no editor!")
		editor.queue_free()
		return 1

	var shapes: Array = ed_vgrass.call("to_dict_list") as Array
	if shapes.size() != 1:
		printerr("FAIL: Formas de grama vetorial esperadas 1, obtido %d" % shapes.size())
		editor.queue_free()
		return 1

	var shape0: Dictionary = shapes[0] as Dictionary
	if String(shape0.get("type", "")) != "grass_yellow":
		printerr("FAIL: Tipo de grama carregado incorreto: %s (esperado grass_yellow)" % String(shape0.get("type", "")))
		editor.queue_free()
		return 1

	print("4. Limpando arquivo de teste %d..." % test_lvl_id)
	editor.queue_free()
	var global_path: String = ProjectSettings.globalize_path(json_path)
	if FileAccess.file_exists(json_path):
		DirAccess.remove_absolute(global_path)

	print("PASS: Roundtrip completo de gravação e leitura validado com 100% de integridade!")
	return 0
