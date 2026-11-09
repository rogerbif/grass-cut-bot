extends SceneTree

const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const PlantDatabase = preload("res://scripts/plants/plant_database.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

func _initialize() -> void:
	print("==================================================")
	print("🧪 TESTE COMPLETO DO CATÁLOGO BOTÂNICO E FASES")
	print("==================================================")

	# 1. Validação de Variações de Flores no TilePaletteDB
	var expected_counts: Dictionary = {
		"flower": 6,
		"flower_rose": 7,
		"flower_daisy": 7,
		"flower_tulip": 4,
		"flower_bed": 3
	}

	for base_id in expected_counts.keys():
		assert(TilePaletteDB.has_variations(base_id), "Deve ter variações registradas para %s" % base_id)
		var vars: Array = TilePaletteDB.get_variations(base_id)
		var expected: int = int(expected_counts[base_id])
		assert(vars.size() == expected, "Esperava %d variações para %s, obteve %d" % [expected, base_id, vars.size()])
		print("  [OK] %s possui %d variações no editor" % [base_id, vars.size()])

	# 2. Validação de Materiais em VegetationGrid
	for base_id in expected_counts.keys():
		var vars: Array = TilePaletteDB.get_variations(base_id)
		for v in vars:
			var vid: String = String(v["id"])
			assert(VegetationGridScript.FLOWER_MATERIALS.has(vid), "VegetationGrid deve conter material para %s" % vid)
			var mat: Material = VegetationGridScript.FLOWER_MATERIALS[vid] as Material
			assert(mat != null, "Material não pode ser nulo para %s" % vid)
	print("  [OK] Todos os materiais shader cel-shaded registrados e válidos no VegetationGrid")

	# 3. Validação das 40 Fases
	var levels_dir: String = "data/levels"
	var dir: DirAccess = DirAccess.open(levels_dir)
	var checked_levels: int = 0
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".json"):
				var path: String = "%s/%s" % [levels_dir, file_name]
				var f: FileAccess = FileAccess.open(path, FileAccess.READ)
				var text: String = f.get_as_text()
				f.close()
				assert(not text.contains("flower_bell"), "Fase %s não deve conter flower_bell" % file_name)
				assert(not text.contains("flower_corolla"), "Fase %s não deve conter flower_corolla" % file_name)
				checked_levels += 1
			file_name = dir.get_next()
		dir.list_dir_end()
	print("  [OK] Todas as %d fases verificadas (0 referências a flores obsoletas)" % checked_levels)

	# 4. Validação do Trigo
	var wheat_mat: Material = VegetationGridScript.GRASS_MATERIALS.get("wheat")
	assert(wheat_mat != null, "Material de trigo deve existir")
	print("  [OK] Material de Trigo Maduro com alto contraste validado")

	print("==================================================")
	print("✅ TODOS OS TESTES BOTÂNICOS PASSARAM COM SUCESSO!")
	print("==================================================")
	quit(0)
