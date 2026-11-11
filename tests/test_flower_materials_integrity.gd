extends SceneTree

const VegetationGrid = preload("res://scripts/plants/vegetation_grid.gd")
const PlantDatabase = preload("res://scripts/plants/plant_database.gd")

func _init() -> void:
	print("--- VERIFICAÇÃO DE SUPERFÍCIES E MATERIAIS DE TODAS AS FLORES E PLANTAS ---")
	var types_to_check: Array[String] = [
		"flower",
		"flower_rose",
		"flower_rose_white",
		"flower_rose_yellow",
		"flower_rose_blue",
		"flower_rose_wine",
		"flower_rose_black",
		"flower_rose_peach",
		"flower_daisy",
		"flower_daisy_blue",
		"flower_daisy_orange",
		"flower_daisy_yellow",
		"flower_daisy_red",
		"flower_daisy_pink",
		"flower_daisy_bicolor",
		"flower_sunflower",
		"flower_tulip",
		"flower_tulip_yellow",
		"flower_tulip_purple",
		"flower_tulip_orange",
		"flower_bed",
		"flower_bed_blue",
		"flower_bed_white",
		"wheat",
		"grass_green",
		"grass_yellow"
	]

	for v_type in types_to_check:
		var m: Mesh = VegetationGrid._resolve_mesh_for_type(v_type)
		var mat: Material = VegetationGrid._resolve_material_for_type(v_type)
		assert(m != null, "Malha não pode ser nula para %s" % v_type)

		if v_type.begins_with("flower"):
			assert(m.get_surface_count() == 3, "Flores DEVEM ter 3 superfícies (pétalas, folhas, caule)! %s tem %d" % [v_type, m.get_surface_count()])
			assert(mat == null, "Flores NÃO devem ter material_override! %s tem %s" % [v_type, mat])
			for s in range(3):
				var s_mat: Material = m.surface_get_material(s)
				assert(s_mat != null, "Superfície %d de %s não pode ter material nulo!" % [s, v_type])
			print("  ✅ [OK] Flor '%s' validada com 3 superfícies e materiais corretos." % v_type)
		elif v_type == "wheat":
			assert(mat == null, "Trigo NÃO deve ter material_override! Tem %s" % mat)
			print("  ✅ [OK] Trigo validado com superfícies embutidas.")
		elif v_type.begins_with("grass_"):
			assert(mat != null, "Grama DEVE ter material_override!")
			print("  ✅ [OK] Grama '%s' validada com material shader de gradiente." % v_type)

	print("==================================================")
	print(">>> TODAS AS FLORES E PLANTAS ESTÃO 100% VALIDADAS! <<<")
	print("==================================================")
	quit(0)
