extends SceneTree

const VectorTerrainField = preload("res://scripts/level/vector_terrain_field.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const IslandMeshBuilder = preload("res://scripts/level/island_mesh_builder.gd")

func _init() -> void:
	print("==================================================")
	print("TEST: Terreno Vetorial - Curvatura do Mapa e Furos")
	print("==================================================")

	# 1. Pincel Quadrado sempre reto
	print("[1/6] Verificando se o pincel quadrado e sempre reto...")
	var square_poly: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
		BrushPatterns.ShapeType.SQUARE, 2, Vector2(5.0, 5.0), 0.0, 0.28
	)
	assert(square_poly.size() == 4, "Pincel quadrado deve ter exatamente 4 vertices retos!")
	print("  -> OK: Pincel quadrado possui 4 vertices retos (corner_radius ignorado no pincel).")

	# 2. Curvatura dinamica do mapa (convexa)
	print("[2/6] Verificando curvatura angular convexa do mapa...")
	var terrain: VectorTerrainField = VectorTerrainField.new()
	terrain.set_corner_radius(0.0)
	terrain.add_land(square_poly)
	assert(terrain.get_base_outer_polygons().size() == 1)
	assert(terrain.get_base_outer_polygons()[0].size() == 4)
	assert(terrain.get_outer_polygons()[0].size() == 4, "Curvatura 0 deve manter 4 vertices!")

	terrain.set_corner_radius(0.28)
	assert(terrain.get_outer_polygons()[0].size() > 4, "Curvatura 0.28m deve arredondar cantos angulares!")
	var count_cr_028: int = terrain.get_outer_polygons()[0].size()
	print("  -> OK: Curvatura 0.28m gerou ", count_cr_028, " vertices nos cantos arredondados.")

	# Idempotencia: chamar set_corner_radius novamente com o mesmo valor deve gerar a mesma contagem
	terrain.set_corner_radius(0.28)
	assert(terrain.get_outer_polygons()[0].size() == count_cr_028)
	print("  -> OK: Curvatura e idempotente (nao infla nem degrada cantos ja arredondados).")

	# 3. Curvatura angular interna (negativa / concava)
	print("[3/6] Verificando curvatura angular interna (negativa/concava) do mapa...")
	var l_shaped_terrain: VectorTerrainField = VectorTerrainField.new()
	l_shaped_terrain.set_corner_radius(0.0)
	# Polígono em L: 5 cantos convexos + 1 canto concavo/interno em (5,5)
	var l_poly: PackedVector2Array = PackedVector2Array([
		Vector2(0, 0), Vector2(10, 0), Vector2(10, 5),
		Vector2(5, 5), Vector2(5, 10), Vector2(0, 10)
	])
	l_shaped_terrain.add_land(l_poly)
	assert(l_shaped_terrain.get_outer_polygons()[0].size() == 6)

	l_shaped_terrain.set_corner_radius(0.5)
	var rounded_l_poly: PackedVector2Array = l_shaped_terrain.get_outer_polygons()[0]
	# Todos os 6 cantos (5 convexos e 1 côncavo) devem ser arredondados com 6 vértices cada: 6 * 6 = 36 vértices
	assert(rounded_l_poly.size() == 36, "Todos os 6 cantos (incluindo o canto concavo interno) devem ser arredondados!")
	var found_concave_rounded: bool = false
	for pt: Vector2 in rounded_l_poly:
		# Ponto do arco côncavo perto de (5,5)
		if pt.x > 5.05 and pt.x < 5.95 and pt.y > 5.05 and pt.y < 5.95:
			found_concave_rounded = true
			break
	assert(found_concave_rounded, "Vertice do canto concavo/interno deve ser arredondado suavemente!")
	print("  -> OK: Curvatura interna (negativa) aplicada com sucesso a cantos concavos (36 vertices).")

	# 4. Criacao e expansao de furos com a ferramenta deletar (carve_water)
	print("[4/6] Verificando criacao de furo (lago) no terreno...")
	terrain.clear()
	terrain.set_corner_radius(0.0)
	var big_land: PackedVector2Array = PackedVector2Array([
		Vector2(0, 0), Vector2(10, 0), Vector2(10, 10), Vector2(0, 10)
	])
	terrain.add_land(big_land)

	# Furo no meio: [4,4] a [6,6]
	var eraser1: PackedVector2Array = PackedVector2Array([
		Vector2(4, 4), Vector2(6, 4), Vector2(6, 6), Vector2(4, 6)
	])
	terrain.carve_water(eraser1)
	assert(terrain.get_base_outer_polygons().size() == 1, "Perimetro externo deve permanecer intacto!")
	assert(terrain.get_base_holes().size() == 1, "Deve criar exatamente 1 furo interno!")
	assert(terrain.get_holes().size() == 1)
	print("  -> OK: Furo interno criado com sucesso!")

	# Expansao do furo sobrepondo a borda do furo existente
	var eraser2: PackedVector2Array = PackedVector2Array([
		Vector2(5, 5), Vector2(7, 5), Vector2(7, 7), Vector2(5, 7)
	])
	terrain.carve_water(eraser2)
	assert(terrain.get_base_outer_polygons().size() == 1)
	assert(terrain.get_base_holes().size() == 1, "Furos sobrepostos devem se fundir em 1 unico furo maior!")
	print("  -> OK: Expansao e fusao de furo interno funcionando perfeitamente!")

	# 5. Abertura de canal ate o oceano -> Furo se torna baia
	print("[5/6] Verificando abertura de canal ate o oceano (transformacao em baia)...")
	var canal: PackedVector2Array = PackedVector2Array([
		Vector2(-1, 5), Vector2(6, 5), Vector2(6, 6), Vector2(-1, 6)
	])
	terrain.carve_water(canal)
	assert(terrain.get_base_outer_polygons().size() == 1, "Ilha permanece 1 poligono perimetral contorno!")
	assert(terrain.get_base_holes().size() == 0, "Ao conectar com o mar, o furo deixa de ser interno e se torna baia!")
	print("  -> OK: Canal conectado ao mar remove furo interno e esculpe baia.")

	# 6. Persistencia JSON to_dict / from_dict
	print("[6/6] Verificando serializacao e desserializacao to_dict / from_dict...")
	terrain.clear()
	terrain.set_corner_radius(0.35)
	terrain.add_land(big_land)
	terrain.carve_water(eraser1) # cria 1 furo
	var dict_data: Dictionary = terrain.to_dict()
	assert(dict_data.has("corner_radius") and is_equal_approx(float(dict_data["corner_radius"]), 0.35))
	assert(dict_data.has("island_polygons") and (dict_data["island_polygons"] as Array).size() == 1)
	assert(dict_data.has("island_holes") and (dict_data["island_holes"] as Array).size() == 1)

	var loaded_terrain: VectorTerrainField = VectorTerrainField.new()
	loaded_terrain.from_dict(dict_data)
	assert(is_equal_approx(loaded_terrain.get_corner_radius(), 0.35))
	assert(loaded_terrain.get_outer_polygons().size() == 1)
	assert(loaded_terrain.get_holes().size() == 1)
	print("  -> OK: Serializacao e desserializacao preservam curvatura, poligonos e furos.")

	print("\n>>> TODOS OS 6 TESTES FORAM CONCLUIDOS COM SUCESSO! <<<\n")
	quit(0)
