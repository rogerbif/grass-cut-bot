extends SceneTree

const VectorTerrainField = preload("res://scripts/level/vector_terrain_field.gd")
const IslandMeshBuilder = preload("res://scripts/level/island_mesh_builder.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")

func _init() -> void:
	print("=== INICIANDO TESTE: TERRENO VETORIAL (VectorTerrainField) ===")
	var total_tests: int = 0
	var passed_tests: int = 0

	# Teste 1: Instanciação e Adição de Terra (add_land)
	total_tests += 1
	var vt: VectorTerrainField = VectorTerrainField.new()
	assert(vt.is_empty(), "Deveria iniciar vazio")

	var rect1: PackedVector2Array = PackedVector2Array([
		Vector2(-4.0, -4.0),
		Vector2(4.0, -4.0),
		Vector2(4.0, 4.0),
		Vector2(-4.0, 4.0)
	])
	vt.add_land(rect1)
	assert(not vt.is_empty(), "Não deveria mais estar vazio")
	assert(vt.get_outer_polygons().size() == 1, "Deveria ter 1 polígono externo")
	assert(vt.is_point_on_land(Vector2(0, 0)), "Origem deve estar sobre terra firme")
	assert(not vt.is_point_on_land(Vector2(10, 10)), "Ponto externo (10, 10) deve ser mar")
	print("[PASS] Teste 1: Adição básica de terra firme")
	passed_tests += 1

	# Teste 2: Fusão (Merge) de porção de terra adjacente
	total_tests += 1
	var rect2: PackedVector2Array = PackedVector2Array([
		Vector2(3.0, -2.0),
		Vector2(7.0, -2.0),
		Vector2(7.0, 2.0),
		Vector2(3.0, 2.0)
	])
	vt.add_land(rect2)
	assert(vt.get_outer_polygons().size() == 1, "Os dois retângulos sobrepostos devem se fundir em 1 polígono")
	assert(vt.is_point_on_land(Vector2(5.0, 0.0)), "A nova área (5, 0) deve estar sobre terra firme")
	print("[PASS] Teste 2: Fusão com Clipper (merge_polygons)")
	passed_tests += 1

	# Teste 3: Recorte de Baía / Canal (carve_water)
	total_tests += 1
	var bay_cutter: PackedVector2Array = PackedVector2Array([
		Vector2(-5.0, -1.0),
		Vector2(-2.0, -1.0),
		Vector2(-2.0, 1.0),
		Vector2(-5.0, 1.0)
	])
	vt.carve_water(bay_cutter)
	assert(not vt.is_point_on_land(Vector2(-3.0, 0.0)), "A baía recortada (-3, 0) deve virar água")
	assert(vt.is_point_on_land(Vector2(0.0, 0.0)), "O centro da ilha continua sendo terra")
	print("[PASS] Teste 3: Recorte de baía externa (carve_water)")
	passed_tests += 1

	# Teste 4: Serialização e Desserialização (to_dict / from_dict)
	total_tests += 1
	var serialized: Dictionary = vt.to_dict()
	assert(serialized.has("island_polygons"), "Deveria ter chave island_polygons")
	assert(serialized.has("island_holes"), "Deveria ter chave island_holes")

	var vt_clone: VectorTerrainField = VectorTerrainField.new()
	vt_clone.from_dict(serialized)
	assert(vt_clone.get_outer_polygons().size() == vt.get_outer_polygons().size(), "Clone deve ter o mesmo número de polígonos")
	assert(vt_clone.is_point_on_land(Vector2(0.0, 0.0)) == vt.is_point_on_land(Vector2(0.0, 0.0)), "Clone deve ter o mesmo comportamento espacial")
	print("[PASS] Teste 4: Serialização e restauração idempotente")
	passed_tests += 1

	# Teste 5: Conversão de grade de tiles legada (convert_from_tile_grid)
	total_tests += 1
	var legacy_tiles: Array = [
		{ "gx": 0, "gz": 0 },
		{ "gx": 1, "gz": 0 },
		{ "gx": 0, "gz": 1 },
		{ "gx": 1, "gz": 1 }
	]
	var vt_legacy: VectorTerrainField = VectorTerrainField.new()
	vt_legacy.convert_from_tile_grid(legacy_tiles, 4, 4, 0.80)
	assert(not vt_legacy.is_empty(), "Conversão de tiles legados deve gerar polígonos")
	assert(vt_legacy.get_outer_polygons().size() == 1, "4 tiles adjacentes devem virar 1 polígono")
	print("[PASS] Teste 5: Conversão de fases legadas em polígonos")
	passed_tests += 1

	# Teste 6: Construção 3D Procedural via IslandMeshBuilder
	total_tests += 1
	var mesh: ArrayMesh = IslandMeshBuilder.build_island_mesh(vt.get_outer_polygons(), vt.get_holes())
	assert(mesh != null, "A malha 3D da ilha não pode ser nula")
	assert(mesh.get_surface_count() > 0, "A malha 3D deve conter superfícies geradas")

	var foam: ArrayMesh = IslandMeshBuilder.build_coastal_foam_mesh(vt.get_outer_polygons(), vt.get_holes())
	assert(foam != null, "A fita de espuma costeira deve ser gerada")

	var col_body: StaticBody3D = StaticBody3D.new()
	IslandMeshBuilder.build_coastal_colliders(col_body, vt.get_outer_polygons(), vt.get_holes())
	assert(col_body.get_child_count() > 0, "Colisores costeiros devem ser instanciados no StaticBody3D")
	for child in col_body.get_children():
		child.free()
	col_body.free()
	print("[PASS] Teste 6: Geração de malha 3D, colisão costeira e espuma")
	passed_tests += 1

	# Teste 7: Compatibilidade com LevelSerializer e LevelJsonLoader
	total_tests += 1
	var lvl1_path: String = LevelSerializer.get_json_path(1)
	assert(FileAccess.file_exists(lvl1_path), "Fase 01 deve existir")
	var lvl1_data: Dictionary = LevelJsonLoader.load_json_file(lvl1_path)
	var lvl1_polys: Array[PackedVector2Array] = LevelJsonLoader.get_island_polygons(lvl1_data)
	assert(not lvl1_polys.is_empty(), "Fase 01 deve carregar polígonos com sucesso")
	print("[PASS] Teste 7: Compatibilidade total com arquivos de fases existentes")
	passed_tests += 1

	print("\n>>> SUCESSO: Todos os %d testes de terreno vetorial passaram com êxito! <<<" % total_tests)
	quit(0)
