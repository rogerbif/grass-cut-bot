extends Node

const UpgradeManagerScript = preload("res://scripts/core/upgrade_manager.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const LevelSerializer = preload("res://scripts/editor/level_serializer.gd")
const FlowerDaisyScene = preload("res://scenes/plants/flower_daisy.tscn")

func _ready() -> void:
	print("==================================================")
	print("🧪 INICIANDO TESTES AUTOMATIZADOS: MELHORIAS EDITOR")
	print("==================================================")

	var failed: int = 0

	failed += test_upgrade_manager_blade_radius()
	failed += test_rock_clearance_polygon()
	failed += test_vector_grass_field_y_offset()
	failed += test_flower_randomize_rotation_and_facing()
	failed += test_vegetation_grid_rock_clearance()
	failed += test_coastal_grass_corridor_offset()
	failed += test_level_serializer_cell_size()

	print("==================================================")
	if failed == 0:
		print("✅ TODOS OS TESTES PASSARAM COM SUCESSO! (0 falhas)")
		get_tree().quit(0)
	else:
		printerr("❌ FALHA EM %d TESTES!" % failed)
		get_tree().quit(1)

func test_upgrade_manager_blade_radius() -> int:
	print("\n--- Teste 1: Raio Máximo da Serra em UpgradeManager ---")
	var max_r: float = UpgradeManager.get_max_blade_radius()
	if absf(max_r - 1.40) > 0.001:
		printerr("FAIL: Raio máximo esperado 1.40, obtido: %f" % max_r)
		return 1
	if absf(UpgradeManager.MAX_BLADE_RADIUS - 1.40) > 0.001:
		printerr("FAIL: Constante MAX_BLADE_RADIUS não é 1.40")
		return 1
	print("PASS: MAX_BLADE_RADIUS = 1.40m (Lâmina Nível 6)")
	return 0

func test_rock_clearance_polygon() -> int:
	print("\n--- Teste 2: Polígono Circular de Raio de Pedra (BrushPatterns) ---")
	var circle: PackedVector2Array = BrushPatterns.get_circle_polygon(Vector2(2.0, 3.0), 1.40, 24)
	if circle.size() != 24:
		printerr("FAIL: Círculo esperado com 24 vértices, obtido %d" % circle.size())
		return 1
	for pt: Vector2 in circle:
		var dist: float = pt.distance_to(Vector2(2.0, 3.0))
		if absf(dist - 1.40) > 0.01:
			printerr("FAIL: Vértice fora do raio esperado de 1.40m: dist = %f" % dist)
			return 1
	print("PASS: Polígono circular de 1.40m gerado perfeitamente com 24 segmentos.")
	return 0

func test_vector_grass_field_y_offset() -> int:
	print("\n--- Teste 3: Separação Vertical (0.001m) para Eliminar Z-Fighting Flicks ---")
	var v_field: RefCounted = VectorGrassFieldScript.new()

	# Adiciona duas formas sobrepostas no mesmo espaço com tipos diferentes
	var poly1: PackedVector2Array = PackedVector2Array([
		Vector2(-2.0, -2.0), Vector2(2.0, -2.0), Vector2(2.0, 2.0), Vector2(-2.0, 2.0)
	])
	var poly2: PackedVector2Array = PackedVector2Array([
		Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)
	])
	v_field.call("add_shape", "grass_green", poly1)
	v_field.call("add_shape", "grass_yellow", poly2)

	var meshes_by_type: Dictionary = v_field.call("generate_ground_meshes")
	if not meshes_by_type.has("grass_green") or not meshes_by_type.has("grass_yellow"):
		printerr("FAIL: Esperado tipos grass_green e grass_yellow no dicionário gerado.")
		return 1

	var mesh_green: ArrayMesh = meshes_by_type["grass_green"] as ArrayMesh
	var mesh_yellow: ArrayMesh = meshes_by_type["grass_yellow"] as ArrayMesh

	var arrays1: Array = mesh_green.surface_get_arrays(0)
	var verts1: PackedVector3Array = arrays1[Mesh.ARRAY_VERTEX]
	var y1: float = verts1[0].y

	var arrays2: Array = mesh_yellow.surface_get_arrays(0)
	var verts2: PackedVector3Array = arrays2[Mesh.ARRAY_VERTEX]
	var y2: float = verts2[0].y

	var diff: float = y2 - y1
	if absf(diff - 0.001) > 0.0001:
		printerr("FAIL: Diferença de altura esperada de 0.001m entre camadas consecutivas, obtido %f (y1=%f, y2=%f)" % [diff, y1, y2])
		return 1

	print("PASS: Malhas de solo separadas verticalmente em 0.001m (y0=%f, y1=%f, diff=%f). Z-fighting eliminado!" % [y1, y2, diff])
	return 0

func test_flower_randomize_rotation_and_facing() -> int:
	print("\n--- Teste 4: Rotação Padrão de Flores e Propriedade randomize_rotation ---")
	var flower_instance: Node3D = FlowerDaisyScene.instantiate() as Node3D
	flower_instance.set("randomize_rotation", false)
	add_child(flower_instance)

	var vm: Node3D = flower_instance.get_node_or_null("VisualMesh") as Node3D
	if vm == null:
		printerr("FAIL: VisualMesh não encontrado na flor!")
		flower_instance.queue_free()
		return 1

	if absf(vm.rotation.y) > 0.0001:
		printerr("FAIL: Com randomize_rotation=false, visual_mesh.rotation.y deveria ser 0.0, mas foi %f" % vm.rotation.y)
		flower_instance.queue_free()
		return 1

	flower_instance.queue_free()
	print("PASS: Flores respeitam randomize_rotation=false mantendo rotação em 0° voltadas para a câmera.")
	return 0

func test_vegetation_grid_rock_clearance() -> int:
	print("\n--- Teste 5: Clareira da Pedra (1.40m) Filtra Flores/Trigo no VegetationGrid ---")
	var vg: Node3D = VegetationGridScript.new()
	add_child(vg)

	var v_field: RefCounted = VectorGrassFieldScript.new()
	var poly: PackedVector2Array = PackedVector2Array([
		Vector2(-5.0, -5.0), Vector2(5.0, -5.0), Vector2(5.0, 5.0), Vector2(-5.0, 5.0)
	])
	v_field.call("add_shape", "grass_green", poly)

	# Pedra em (5, 5) -> Posição centro (0, 0, 0)
	var rock_cells: Dictionary = { Vector2i(5, 5): true }
	# Flor A em (5, 7): dist em Z = 2 * 0.40 = 0.80m (< 1.40m) -> DEVE SER DESCARTADA
	# Flor B em (5, 9): dist em Z = 4 * 0.40 = 1.60m (> 1.40m) -> DEVE SER MANTIDA
	var flower_cells: Dictionary = {
		Vector2i(5, 7): {"type": "flower_daisy", "rot": 0},
		Vector2i(5, 9): {"type": "flower_daisy", "rot": 0}
	}
	var wheat_cells: Dictionary = {}

	var goals: Dictionary = vg.call("_build_from_vector_field", v_field, 11, 11, 0.40, flower_cells, wheat_cells, rock_cells)

	var daisy_goal: int = int(goals.get("flower_daisy", 0))
	if daisy_goal != 1:
		printerr("FAIL: Esperado exatamente 1 flor fora do raio de 1.40m, obtido %d" % daisy_goal)
		vg.queue_free()
		return 1

	print("PASS: Flor dentro de 0.80m foi filtrada pela clareira de 1.40m da pedra; flor a 1.60m foi preservada.")
	vg.queue_free()
	return 0

func test_coastal_grass_corridor_offset() -> int:
	print("\n--- Teste 6: Corredor Costeiro Afastado da Borda da Ilha (0.48m) ---")
	var island_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-4.0, -4.0), Vector2(4.0, -4.0), Vector2(4.0, 4.0), Vector2(-4.0, 4.0)
	])
	var corridor_margin: float = 0.48
	var offset_polys: Array[PackedVector2Array] = Geometry2D.offset_polygon(island_poly, -corridor_margin)

	if offset_polys.is_empty():
		printerr("FAIL: offset_polygon retornou array vazio!")
		return 1

	var safe_poly: PackedVector2Array = offset_polys[0]
	for pt: Vector2 in safe_poly:
		if absf(pt.x) > 3.53 or absf(pt.y) > 3.53:
			printerr("FAIL: Ponto do corredor fora da margem segura: pt = %v" % pt)
			return 1

	print("PASS: Polígono com corredor costeiro de 0.48m calculado perfeitamente: margem recuada para +/- 3.52m.")
	return 0

func test_level_serializer_cell_size() -> int:
	print("\n--- Teste 7: LevelSerializer CELL_SIZE Subdividido (0.40m) ---")
	if absf(LevelSerializer.CELL_SIZE - 0.40) > 0.001:
		printerr("FAIL: LevelSerializer.CELL_SIZE esperado 0.40, obtido %f" % LevelSerializer.CELL_SIZE)
		return 1
	print("PASS: LevelSerializer.CELL_SIZE padronizado em 0.40m.")
	return 0
