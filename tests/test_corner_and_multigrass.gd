extends SceneTree

const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const VectorGrassFieldScript = preload("res://scripts/level/vector_grass_field.gd")

func _init() -> void:
	print("==================================================")
	print("   TEST: CORNER RADIUS & MULTI-GRASS GOALS        ")
	print("==================================================")

	# 1. Teste de Corner Radius no Quadrado
	var sharp_poly: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
		BrushPatterns.ShapeType.SQUARE, 1, Vector2.ZERO, 0.0, 0.0
	)
	assert(sharp_poly.size() == 4, "Quadrado reto com corner_radius=0 deve ter exatamente 4 vértices")
	print("✔ Teste 1.1: Quadrado reto (corner_radius = 0.0) gerou 4 vértices.")

	var rounded_poly: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
		BrushPatterns.ShapeType.SQUARE, 1, Vector2.ZERO, 0.0, 0.28
	)
	assert(rounded_poly.size() == 24, "Quadrado arredondado com corner_radius=0.28 deve ter 24 vértices")
	var tris: PackedInt32Array = Geometry2D.triangulate_polygon(rounded_poly)
	assert(not tris.is_empty(), "Quadrado arredondado deve ser triangulável")
	print("✔ Teste 1.2: Quadrado arredondado (corner_radius = 0.28m padrão) gerou 24 vértices e triangulou com sucesso.")

	# 2. Teste de Metas de Grama Unificada (Apenas Grama Verde)
	var single_vfield: RefCounted = VectorGrassFieldScript.new()
	var poly_a: PackedVector2Array = PackedVector2Array([
		Vector2(-2.0, -2.0),
		Vector2(2.0, -2.0),
		Vector2(2.0, 2.0),
		Vector2(-2.0, 2.0)
	])
	single_vfield.call("add_shape", "grass_green", poly_a)

	var single_data: Dictionary = {
		"grid": { "width": 8, "height": 8, "cell_size": 0.80 },
		"grass_vectors": single_vfield.call("to_dict_list"),
		"terrain": [],
		"objects": []
	}

	var vg_single: Node3D = VegetationGridScript.new() as Node3D
	var single_goals: Dictionary = vg_single.call("build_from_level_json", single_data, null, null) as Dictionary
	print("Metas geradas com 1 única cor de grama (verde):", single_goals)
	assert(single_goals.has("grass"), "Grama de cor única verde deve manter a meta canônica 'grass'")
	assert(not single_goals.has("grass_green"), "Não deve duplicar chave quando for grama única verde")
	vg_single.free()
	print("✔ Teste 2: Retrocompatibilidade de grama única verde com chave 'grass' mantida.")

	# 3. Teste de Metas de Grama Multicores (Verde + Amarela)
	var multi_vfield: RefCounted = VectorGrassFieldScript.new()
	var poly_green: PackedVector2Array = PackedVector2Array([
		Vector2(-3.0, -3.0),
		Vector2(-0.5, -3.0),
		Vector2(-0.5, 3.0),
		Vector2(-3.0, 3.0)
	])
	var poly_yellow: PackedVector2Array = PackedVector2Array([
		Vector2(0.5, -3.0),
		Vector2(3.0, -3.0),
		Vector2(3.0, 3.0),
		Vector2(0.5, 3.0)
	])
	multi_vfield.call("add_shape", "grass_green", poly_green)
	multi_vfield.call("add_shape", "grass_yellow", poly_yellow)

	var multi_data: Dictionary = {
		"grid": { "width": 10, "height": 10, "cell_size": 0.80 },
		"grass_vectors": multi_vfield.call("to_dict_list"),
		"terrain": [],
		"objects": []
	}

	var vg_multi: Node3D = VegetationGridScript.new() as Node3D
	var multi_goals: Dictionary = vg_multi.call("build_from_level_json", multi_data, null, null) as Dictionary
	print("Metas geradas com múltiplas cores de grama:", multi_goals)
	assert(multi_goals.has("grass_green"), "Metas devem conter 'grass_green' separada")
	assert(multi_goals.has("grass_yellow"), "Metas devem conter 'grass_yellow' separada")
	assert(not multi_goals.has("grass"), "Não deve existir meta genérica 'grass' quando há cores distintas")
	assert(int(multi_goals["grass_green"]) > 0, "grass_green deve ter valor > 0")
	assert(int(multi_goals["grass_yellow"]) > 0, "grass_yellow deve ter valor > 0")
	vg_multi.free()
	print("✔ Teste 3: Gramas de cores diferentes contabilizadas e separadas com sucesso.")

	print("==================================================")
	print("   TODOS OS TESTES PASSARAM COM SUCESSO!         ")
	print("==================================================")
	quit()
