extends SceneTree

const IslandMeshBuilderScript = preload("res://scripts/level/island_mesh_builder.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

func _init() -> void:
	print("==================================================")
	print("   INICIANDO SUÍTE DE TESTES: ISLAND MESH BUILDER  ")
	print("==================================================")

	# Teste 1: Polígono quadrado simples
	var test_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-2.0, -2.0),
		Vector2(2.0, -2.0),
		Vector2(2.0, 2.0),
		Vector2(-2.0, 2.0)
	])

	var mesh: ArrayMesh = IslandMeshBuilderScript.build_island_mesh([test_poly])
	assert(mesh != null, "Malha básica não pode ser nula")
	assert(mesh.get_surface_count() == 1, "Malha deve conter exatamente 1 superfície")
	print("✔ Teste 1: Malha básica procedural quadrada gerada com sucesso.")

	# Teste 2: Polígono com furo interno (lago / reentrância)
	var hole: PackedVector2Array = PackedVector2Array([
		Vector2(-0.5, -0.5),
		Vector2(0.5, -0.5),
		Vector2(0.5, 0.5),
		Vector2(-0.5, 0.5)
	])
	var mesh_with_hole: ArrayMesh = IslandMeshBuilderScript.build_island_mesh([test_poly], [hole])
	assert(mesh_with_hole != null, "Malha com furo não pode ser nula")
	assert(mesh_with_hole.get_surface_count() == 1, "Malha com furo deve ter 1 superfície")
	print("✔ Teste 2: Malha com furo/reentrância interna triangulada com sucesso.")

	# Teste 3: Fita contínua de espuma costeira
	var foam_mesh: ArrayMesh = IslandMeshBuilderScript.build_coastal_foam_mesh([test_poly])
	assert(foam_mesh != null, "Fita de espuma não pode ser nula")
	assert(foam_mesh.get_surface_count() == 1, "Fita de espuma deve conter 1 superfície")
	print("✔ Teste 3: Fita de espuma costeira contínua gerada com sucesso.")

	# Teste 4: Barreiras de contenção física (Camada 1)
	var static_body: StaticBody3D = StaticBody3D.new()
	IslandMeshBuilderScript.build_coastal_colliders(static_body, [test_poly])
	assert(static_body.get_child_count() == 4, "Deve gerar 4 colisores para as 4 arestas externas")
	print("✔ Teste 4: 4 colisores verticais de perímetro gerados com sucesso.")
	static_body.free()

	# Teste 5: Validação completa em todos os 20 níveis do jogo
	var total_polys: int = 0
	var total_verts: int = 0
	for lvl in range(1, 21):
		var path: String = "res://data/levels/level_%02d.json" % lvl
		var data: Dictionary = LevelJsonLoader.load_json_file(path)
		assert(not data.is_empty(), "Arquivo de nível não pode ser vazio: %s" % path)

		var polys: Array[PackedVector2Array] = LevelJsonLoader.get_island_polygons(data)
		assert(not polys.is_empty(), "Nível %02d deve conter pelo menos 1 polígono de ilha" % lvl)

		var lvl_mesh: ArrayMesh = IslandMeshBuilderScript.build_island_mesh(polys)
		assert(lvl_mesh != null, "Malha procedural do nível %02d falhou ao gerar" % lvl)

		var lvl_foam: ArrayMesh = IslandMeshBuilderScript.build_coastal_foam_mesh(polys)
		assert(lvl_foam != null, "Espuma costeira do nível %02d falhou ao gerar" % lvl)

		var col_body: StaticBody3D = StaticBody3D.new()
		IslandMeshBuilderScript.build_coastal_colliders(col_body, polys)
		assert(col_body.get_child_count() > 0, "Colisores da fase %02d não podem ser vazios" % lvl)
		col_body.free()

		total_polys += polys.size()
		for p in polys:
			total_verts += p.size()

	print("✔ Teste 5: Todos os 20 níveis validados com malha, espuma e colisão perfeitas! (%d polígonos, %d vértices de contorno)" % [total_polys, total_verts])

	print("==================================================")
	print("   TODOS OS TESTES DO ISLAND MESH BUILDER PASSARAM! ")
	print("==================================================")
	quit()
