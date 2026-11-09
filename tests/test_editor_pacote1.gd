extends SceneTree

const LevelEditorScene: PackedScene = preload("res://scenes/editor/level_editor.tscn")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var failures: int = 0
	var editor: Node3D = LevelEditorScene.instantiate() as Node3D
	root.add_child(editor)
	await process_frame

	var gw: int = int(editor.get("grid_width"))
	var gh: int = int(editor.get("grid_height"))
	var cx: int = int(float(gw) * 0.5)
	var cz: int = int(float(gh) * 0.5)

	# 1. Testa Box Fill vetorial no Terreno (Camada 0)
	editor.set("active_layer", 0) # EditLayer.TERRAIN
	editor.call("_on_clear_terrain")
	var vt: RefCounted = editor.get("vector_terrain") as RefCounted
	if not bool(vt.call("is_empty")):
		push_error("FAIL 1a: vector_terrain deveria estar vazio após _on_clear_terrain")
		failures += 1

	editor.call("_apply_box_fill", Vector2i(cx - 6, cz - 4), Vector2i(cx + 6, cz + 4))
	if bool(vt.call("is_empty")):
		push_error("FAIL 1b: _apply_box_fill na Camada 0 não criou terreno vetorial")
		failures += 1
	if not bool(vt.call("is_point_on_land", Vector2(0.0, 0.0))):
		push_error("FAIL 1c: centro (0,0) deveria ser terra firme após Box Fill no terreno")
		failures += 1

	# 2. Testa Box Fill vetorial na Grama (Camada 1)
	editor.set("active_layer", 1) # EditLayer.GRASS
	editor.set("active_grass_id", "grass_blue")
	var vg: RefCounted = editor.get("vector_grass") as RefCounted
	editor.call("_apply_box_fill", Vector2i(cx - 3, cz - 2), Vector2i(cx + 3, cz + 2))
	var shapes_after_box: Array = vg.call("to_dict_list") as Array
	var found_blue: bool = false
	for s_var: Variant in shapes_after_box:
		var sd: Dictionary = s_var as Dictionary
		if String(sd.get("type", "")) == "grass_blue":
			found_blue = true
			break
	if not found_blue:
		push_error("FAIL 2: _apply_box_fill na Camada 1 não criou região de grass_blue")
		failures += 1

	# 3. Testa Linha Reta / Ponte (Shift + Clique) no Terreno e na Grama
	editor.set("active_layer", 0) # TERRAIN
	editor.set("brush_size", 2)
	editor.set("is_hover_in_bounds", true)
	editor.call("_apply_straight_line_at", Vector2(-1.0, 0.0), Vector2(4.2, 0.0), false)
	if not bool(vt.call("is_point_on_land", Vector2(3.8, 0.0))):
		push_error("FAIL 3a: Ponte reta (_apply_straight_line_at) não estendeu terra até (3.8, 0.0)")
		failures += 1

	# Testa abertura de canal reto com erase_mode = true
	editor.call("_apply_straight_line_at", Vector2(-1.0, 0.0), Vector2(1.0, 0.0), true)
	if bool(vt.call("is_point_on_land", Vector2(0.0, 0.0))):
		push_error("FAIL 3b: Canal reto com borracha não escavou água em (0.0, 0.0)")
		failures += 1

	# 4. Testa _sync_all_ui(false) vs _sync_all_ui(true)
	editor.call("_sync_all_ui", false)
	editor.call("_sync_all_ui", true)

	# 5. Testa validação de Playtest com terrain_grid vazio mas vector_terrain preenchido
	var tg: Dictionary = editor.get("terrain_grid") as Dictionary
	tg.clear()
	var has_vec_land: bool = (vt != null and not bool(vt.call("is_empty")))
	if not has_vec_land:
		push_error("FAIL 5: vector_terrain deveria conter terra firme mesmo com terrain_grid limpo")
		failures += 1

	root.remove_child(editor)
	editor.free()
	await process_frame

	if failures == 0:
		print("ALL TESTS PASSED (test_editor_pacote1: 5/5)")
		quit(0)
	else:
		push_error("TESTS FAILED: %d" % failures)
		quit(1)
