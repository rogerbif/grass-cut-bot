extends SceneTree

## Garante que os manifestos canônicos (fallback para builds exportadas)
## existem em disco e cobrem exatamente o conteúdo das pastas data-driven.

func _check(label: String, manifest: PackedStringArray, dir_path: String) -> int:
	var errors: int = 0
	for p: String in manifest:
		if not ResourceLoader.exists(p):
			printerr("[FALHA] %s: manifesto aponta para arquivo inexistente: %s" % [label, p])
			errors += 1
	var dir: DirAccess = DirAccess.open(dir_path)
	if dir != null:
		for f: String in dir.get_files():
			var clean: String = f.trim_suffix(".remap")
			if clean.ends_with(".tres") and not manifest.has("%s/%s" % [dir_path, clean]):
				printerr("[FALHA] %s: arquivo fora do manifesto: %s" % [label, clean])
				errors += 1
	print("%s: %d itens no manifesto, %d erros" % [label, manifest.size(), errors])
	return errors

func _init() -> void:
	var errors: int = 0
	errors += _check("Espécies", PlantDatabase.CANONICAL_SPECIES_PATHS, "res://data/species")
	errors += _check("Obstáculos", ObstacleDatabase.CANONICAL_OBSTACLE_PATHS, "res://data/obstacles")
	errors += _check("Temas", ThemeDatabase.CANONICAL_THEME_PATHS, "res://data/themes")
	quit(1 if errors > 0 else 0)
