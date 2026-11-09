extends SceneTree

const LevelEditorScene: PackedScene = preload("res://scenes/editor/level_editor.tscn")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

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

	# 1. Verifica que o nível inicia limpo (is_dirty == false) e fica dirty após edição
	if bool(editor.get("is_dirty")):
		push_error("FAIL 1a: Editor não deveria iniciar com is_dirty == true")
		failures += 1

	editor.set("active_layer", 1) # GRASS
	editor.set("active_grass_id", "grass_purple")
	editor.call("_push_undo_snapshot")
	editor.call("_apply_box_fill", Vector2i(cx - 2, cz - 2), Vector2i(cx + 2, cz + 2))
	if not bool(editor.get("is_dirty")):
		push_error("FAIL 1b: Editor deveria marcar is_dirty == true após _push_undo_snapshot")
		failures += 1

	# 2. Testa Pipeta (_pick_at_cursor) para Grama, Objeto e Spawn
	editor.set("active_grass_id", "grass_green")
	editor.set("active_tool", 1) # ERASER
	var picked_grass: bool = bool(editor.call("_pick_at_cursor", Vector2i(cx - 1, cz), Vector2(-0.4, 0.0)))
	if not picked_grass or String(editor.get("active_grass_id")) != "grass_purple" or int(editor.get("active_tool")) != 0:
		push_error("FAIL 2a: Pipeta não capturou grass_purple em (-0.4, 0.0)")
		failures += 1

	# Adiciona uma Rosa Azul em (cx + 4, cz) e testa Pipeta
	var obj_grid: Dictionary = editor.get("object_grid") as Dictionary
	var rose_cell: Vector2i = Vector2i(cx + 4, cz)
	obj_grid[rose_cell] = { "type": "flower_rose_blue", "rot": 25 }
	var rose_wp: Vector3 = LevelJsonLoader.grid_to_world(rose_cell.x, rose_cell.y, gw, gh, 0.40)
	var picked_obj: bool = bool(editor.call("_pick_at_cursor", rose_cell, Vector2(rose_wp.x, rose_wp.z)))
	if not picked_obj or String(editor.get("active_object_id")) != "flower_rose_blue" or int(editor.get("active_layer")) != 2:
		push_error("FAIL 2b: Pipeta não capturou flower_rose_blue na célula do objeto")
		failures += 1

	# Testa Pipeta no Spawn
	var sp_cell: Vector2i = editor.get("spawn_cell") as Vector2i
	var picked_sp: bool = bool(editor.call("_pick_at_cursor", sp_cell, Vector2.ZERO))
	if not picked_sp or int(editor.get("active_tool")) != 3:
		push_error("FAIL 2c: Pipeta não selecionou ToolMode.SPAWN ao clicar na célula de spawn")
		failures += 1

	# 3. Testa Cálculo Automático de Tempo (Abordagem 3 + 10%)
	editor.call("apply_auto_calculated_time")
	var calc_t: float = float(editor.get("time_limit"))
	if calc_t < 20.0 or calc_t > 240.0 or int(calc_t) % 5 != 0:
		push_error("FAIL 3: Tempo auto-calculado inválido: %.1f" % calc_t)
		failures += 1

	# 4. Testa Visibilidade por Camada (👁️)
	var plants_cont: Node3D = editor.get("plants_container") as Node3D
	editor.call("toggle_layer_visibility", 1) # Oculta Grama
	if plants_cont.visible:
		push_error("FAIL 4a: plants_container deveria estar oculto após toggle_layer_visibility(1)")
		failures += 1
	editor.call("toggle_layer_visibility", 1) # Mostra Grama novamente
	if not plants_cont.visible:
		push_error("FAIL 4b: plants_container deveria voltar a ficar visível")
		failures += 1

	# 5. Testa Toggle de Preview 3D dos Tufos (🌿 3D)
	editor.call("toggle_3d_grass_preview")
	if not bool(editor.get("preview_3d_grass")):
		push_error("FAIL 5a: preview_3d_grass deveria ser true após toggle_3d_grass_preview()")
		failures += 1
	var preview_vg: Node = plants_cont.get_node_or_null("EditorPreviewVegGrid")
	if preview_vg == null:
		push_error("FAIL 5b: EditorPreviewVegGrid não foi instanciado em plants_container no modo 3D")
		failures += 1
	editor.call("toggle_3d_grass_preview") # Desliga de volta para modo rápido

	# 6. Verifica limite de fases até 200 na UI
	var ui_node: Control = editor.get("ui") as Control
	var spin_lvl: SpinBox = ui_node.get("spin_level") as SpinBox
	if int(spin_lvl.max_value) < 200:
		push_error("FAIL 6: spin_level.max_value deveria ser >= 200")
		failures += 1

	root.remove_child(editor)
	editor.free()
	await process_frame

	if failures == 0:
		print("ALL TESTS PASSED (test_editor_pacote2: 6/6)")
		quit(0)
	else:
		push_error("TESTS FAILED: %d" % failures)
		quit(1)
