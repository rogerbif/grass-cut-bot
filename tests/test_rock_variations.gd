extends SceneTree

const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

func _init() -> void:
	print("--- TESTE DE DIVERSIDADE DE ROCHAS TROPICAIS ---")

	# 1. Validar TilePaletteDB
	assert(TilePaletteDB.has_variations("rock"), "TilePaletteDB deve ter variações para 'rock'")
	var rock_vars: Array = TilePaletteDB.get_variations("rock")
	print("Total de variações registradas na paleta: ", rock_vars.size())
	assert(rock_vars.size() == 6, "Devem existir exatamente 6 variações de rocha!")

	var expected_ids: Array[String] = [
		"rock",
		"rock_moss",
		"rock_spire",
		"rock_moss_spire",
		"rock_sandstone",
		"rock_boulder"
	]

	for i in range(expected_ids.size()):
		var v_data: Dictionary = rock_vars[i] as Dictionary
		var exp_id: String = expected_ids[i]
		assert(String(v_data.get("id", "")) == exp_id, "ID incorreto na posição %d" % i)
		assert(String(v_data.get("category", "")) == "obstacle", "Categoria deve ser obstacle!")
		print("  ✅ Variante %d validada: %s (%s)" % [i + 1, v_data.get("name"), exp_id])

	# 2. Validar carregamento no LevelJsonLoader e integridade de cenas
	for rock_id in expected_ids:
		assert(LevelJsonLoader.OBJECT_SCENES.has(rock_id), "LevelJsonLoader deve conter cena para '%s'" % rock_id)
		var node: Node3D = LevelJsonLoader.instantiate_object_node(rock_id, 0)
		assert(node != null, "Falha ao instanciar cena da rocha '%s'" % rock_id)
		assert(node.is_in_group("obstacles"), "A rocha '%s' deve estar no grupo 'obstacles'" % rock_id)
		if node is CollisionObject3D:
			var col_obj: CollisionObject3D = node as CollisionObject3D
			assert(col_obj.collision_layer == 8, "A rocha '%s' deve ter collision_layer == 8 (Layer 4)!" % rock_id)
		var col_shape: CollisionShape3D = node.get_node_or_null("CollisionShape3D") as CollisionShape3D
		assert(col_shape != null, "A rocha '%s' deve ter CollisionShape3D!" % rock_id)
		assert(col_shape.shape is CylinderShape3D, "A rocha '%s' deve usar CylinderShape3D!" % rock_id)
		print("  ✅ Cena '%s' instanciada e validada no grupo 'obstacles' com Layer 8 e colisor!" % rock_id)
		node.free()

	print("--- TODOS OS TESTES DE ROCHAS PASSARAM COM SUCESSO! ---")
	quit(0)
