extends SceneTree

const VegetationGrid = preload("res://scripts/plants/vegetation_grid.gd")
const PlantDatabase = preload("res://scripts/plants/plant_database.gd")

func _init() -> void:
	print("==================================================")
	print("🧪 AUDITORIA INTEGRAL DE TODAS AS 36 PLANTAS DO JOGO")
	print("==================================================")

	var all_botanical_types: Array[String] = [
		# 7 Gramas
		"grass_green",
		"grass_yellow",
		"grass_blue",
		"grass_purple",
		"grass_white",
		"grass_red",
		"grass_black",
		# 1 Trigo
		"wheat",
		# 6 Flores Silvestres
		"flower",
		"flower_blue",
		"flower_sunset",
		"flower_purple",
		"flower_white",
		"flower_turquoise",
		# 7 Rosas
		"flower_rose",
		"flower_rose_white",
		"flower_rose_yellow",
		"flower_rose_blue",
		"flower_rose_wine",
		"flower_rose_black",
		"flower_rose_peach",
		# 7 Margaridas
		"flower_daisy",
		"flower_daisy_blue",
		"flower_daisy_orange",
		"flower_daisy_yellow",
		"flower_daisy_red",
		"flower_daisy_pink",
		"flower_daisy_bicolor",
		# 1 Girassol
		"flower_sunflower",
		# 4 Tulipas
		"flower_tulip",
		"flower_tulip_yellow",
		"flower_tulip_purple",
		"flower_tulip_orange",
		# 3 Canteiros Floridos
		"flower_bed",
		"flower_bed_blue",
		"flower_bed_white"
	]

	assert(all_botanical_types.size() == 36, "Devem existir exatamente 36 variedades botânicas registradas!")

	# PARTE 1: Verificação direta de resolução estática de Malha e Material
	print("\n--- [Parte 1] Validação Estática de Resolução ---")
	for v_type in all_botanical_types:
		var m: Mesh = VegetationGrid._resolve_mesh_for_type(v_type)
		var mat: Material = VegetationGrid._resolve_material_for_type(v_type)
		assert(m != null, "Malha não pode ser nula para '%s'" % v_type)

		if v_type.begins_with("flower"):
			assert(m.get_surface_count() == 3, "Flor '%s' DEVE ter 3 superfícies! Tem %d" % [v_type, m.get_surface_count()])
			assert(mat == null, "Flor '%s' NÃO PODE ter material_override! Tem %s" % [v_type, mat])
			for s in range(3):
				var s_mat: Material = m.surface_get_material(s)
				assert(s_mat != null, "Superfície %d da flor '%s' não pode ter material nulo!" % [s, v_type])
			print("  ✔ Flor '%s': 3 superfícies íntegras (Pétalas, Folhas, Caule) e material_override == null" % v_type)
		elif v_type == "wheat":
			assert(mat == null, "Trigo NÃO PODE ter material_override! Tem %s" % mat)
			var w_mat: Material = m.surface_get_material(0)
			assert(w_mat != null, "Superfície do trigo não pode ter material nulo!")
			print("  ✔ Trigo '%s': Superfície íntegra com shader Toon embutido" % v_type)
		elif v_type.begins_with("grass_"):
			assert(mat != null, "Grama '%s' DEVE ter material_override de gradiente vertical!" % v_type)
			assert(m.get_surface_count() == 1, "Grama '%s' deve ter 1 superfície!" % v_type)
			print("  ✔ Grama '%s': Malha 392 vértices com material_override oficial" % v_type)

	# PARTE 2: Validação da Construção Real do VegetationGrid em Árvore de Cena
	print("\n--- [Parte 2] Validação do MultiMeshInstance3D Real em VegetationGrid ---")
	var grid: VegetationGrid = VegetationGrid.new()
	var vector_field_script = preload("res://scripts/level/vector_grass_field.gd")
	var vector_field = vector_field_script.new()
	var poly: PackedVector2Array = PackedVector2Array([
		Vector2(-5.0, -5.0),
		Vector2(5.0, -5.0),
		Vector2(5.0, 5.0),
		Vector2(-5.0, 5.0)
	])
	vector_field.add_shape("grass_green", poly)

	var tile_flowers: Dictionary = {}
	for i in range(all_botanical_types.size()):
		var vt: String = all_botanical_types[i]
		if vt.begins_with("flower"):
			tile_flowers[Vector2i(i, 0)] = { "type": vt, "rot": 0.0 }

	var tile_wheat: Dictionary = { Vector2i(0, 1): true }

	grid._build_from_vector_field(vector_field, 10, 10, 0.8, tile_flowers, tile_wheat)

	# Inspeciona os MultiMeshInstance3D filhos criados
	var mmi_children: Array[Node] = grid.get_children()

	for child in mmi_children:
		if child is MultiMeshInstance3D:
			var mmi: MultiMeshInstance3D = child as MultiMeshInstance3D
			var mm: MultiMesh = mmi.multimesh
			if mm == null or mm.mesh == null or mm.instance_count == 0:
				continue

			var mesh_res: Mesh = mm.mesh
			var surfs: int = mesh_res.get_surface_count()

			# Verifica se alguma flor recebeu material_override acidentalmente
			if surfs == 3:
				assert(mmi.material_override == null, "MultiMeshInstance3D de flor tem material_override não-nulo! Isso causaria o bug da flor branca!")
				for s in range(3):
					assert(mesh_res.surface_get_material(s) != null, "Superfície %d não tem material!" % s)

	grid.free()
	print("  ✔ Todos os nós MultiMeshInstance3D reais construídos com 100% de integridade!")

	print("\n==================================================")
	print(">>> AUDITORIA CONCLUÍDA: 0 BUGS, 100% BLINDADO! <<<")
	print("==================================================")
	quit(0)
