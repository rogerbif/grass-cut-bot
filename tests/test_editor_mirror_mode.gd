extends Node

const LevelEditor = preload("res://scripts/editor/level_editor.gd")

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- TESTES DE UNIDADE: MODO DE ESPELHAMENTO / SIMETRIA (MIRROR MODE) ---")

	var editor_scene: PackedScene = load("res://scenes/editor/level_editor.tscn")
	var editor: Node = editor_scene.instantiate()
	add_child(editor)

	await get_tree().process_frame
	await get_tree().process_frame

	# Teste 1: Validação do Enum MirrorMode e Ciclo de Alternância
	print("[Teste 1] Alternância de MirrorMode...")
	assert(editor.get("MirrorMode").get("NONE") == 0, "MirrorMode.NONE deve ser 0")
	assert(editor.get("MirrorMode").get("HORIZONTAL_X") == 1, "MirrorMode.HORIZONTAL_X deve ser 1")
	assert(editor.get("MirrorMode").get("VERTICAL_Z") == 2, "MirrorMode.VERTICAL_Z deve ser 2")
	assert(editor.get("MirrorMode").get("QUAD_XZ") == 3, "MirrorMode.QUAD_XZ deve ser 3")

	assert(int(editor.get("mirror_mode")) == 0, "Modo inicial deve ser NONE (0)")
	editor.call("toggle_mirror_mode")
	assert(int(editor.get("mirror_mode")) == 1, "1º toggle deve ser HORIZONTAL_X (1)")
	editor.call("toggle_mirror_mode")
	assert(int(editor.get("mirror_mode")) == 2, "2º toggle deve ser VERTICAL_Z (2)")
	editor.call("toggle_mirror_mode")
	assert(int(editor.get("mirror_mode")) == 3, "3º toggle deve ser QUAD_XZ (3)")
	editor.call("toggle_mirror_mode")
	assert(int(editor.get("mirror_mode")) == 0, "4º toggle deve retornar para NONE (0)")
	print("  -> OK: Ciclo de alternância 0 -> 1 -> 2 -> 3 -> 0 validado.")

	var gw: int = int(editor.get("grid_width"))
	var gh: int = int(editor.get("grid_height"))

	# Teste 2: Espelhamento Horizontal (Eixo X)
	print("[Teste 2] Espelhamento Horizontal (X)...")
	editor.set("mirror_mode", 1) # HORIZONTAL_X
	editor.set("active_layer", 2) # OBJECTS
	editor.set("active_object_id", "flower_daisy")
	editor.set("brush_size", 1)
	editor.set("active_shape", 0) # SINGLE 1x1
	editor.set("is_hover_in_bounds", true)

	var p_orig: Vector2i = Vector2i(2, 2)
	var p_mirror_x: Vector2i = Vector2i((gw - 1) - 2, 2)

	editor.call("_apply_brush_at", p_orig, false)

	var objs: Dictionary = editor.get("object_grid") as Dictionary
	assert(objs.has(p_orig), "Objeto deve estar posicionado na célula original (2, 2)")
	assert(objs.has(p_mirror_x), "Objeto deve estar espelhado na célula oposta (%d, 2)" % p_mirror_x.x)
	assert(int((objs[p_orig] as Dictionary).get("rot", -1)) == 0, "Flor original deve ter rot = 0")
	assert(int((objs[p_mirror_x] as Dictionary).get("rot", -1)) == 0, "Flor espelhada deve manter rot = 0 (frente para a câmera)")
	print("  -> OK: Flores espelhadas em X com rotação voltada para a câmera (0°).")

	# Teste 3: Espelhamento Vertical (Eixo Z)
	print("[Teste 3] Espelhamento Vertical (Z)...")
	editor.set("mirror_mode", 2) # VERTICAL_Z
	var p_orig_z: Vector2i = Vector2i(3, 1)
	var p_mirror_z: Vector2i = Vector2i(3, (gh - 1) - 1)

	editor.call("_apply_brush_at", p_orig_z, false)
	objs = editor.get("object_grid") as Dictionary
	assert(objs.has(p_orig_z) and objs.has(p_mirror_z), "Objetos devem estar espelhados em Z")
	print("  -> OK: Flores espelhadas em Z com sucesso.")

	# Teste 4: Espelhamento Quádruplo (Eixos X e Z)
	print("[Teste 4] Espelhamento Quádruplo (X+Z)...")
	editor.set("mirror_mode", 3) # QUAD_XZ
	var p_corner: Vector2i = Vector2i(1, 1)
	var p_c_x: Vector2i = Vector2i((gw - 1) - 1, 1)
	var p_c_z: Vector2i = Vector2i(1, (gh - 1) - 1)
	var p_c_xz: Vector2i = Vector2i((gw - 1) - 1, (gh - 1) - 1)

	editor.call("_apply_brush_at", p_corner, false)
	objs = editor.get("object_grid") as Dictionary
	assert(objs.has(p_corner), "Canto 1 presente")
	assert(objs.has(p_c_x), "Canto 2 (Espelho X) presente")
	assert(objs.has(p_c_z), "Canto 3 (Espelho Z) presente")
	assert(objs.has(p_c_xz), "Canto 4 (Espelho XZ) presente")
	print("  -> OK: Quádruplo espelhamento criou simetria nos 4 quadrantes da ilha.")

	# Teste 5: Apagamento Simétrico (Borracha no modo espelho)
	print("[Teste 5] Borracha com Espelhamento Quádruplo...")
	editor.call("_apply_brush_at", p_corner, true) # Erase mode
	objs = editor.get("object_grid") as Dictionary
	assert(not objs.has(p_corner), "Canto 1 apagado")
	assert(not objs.has(p_c_x), "Canto 2 apagado")
	assert(not objs.has(p_c_z), "Canto 3 apagado")
	assert(not objs.has(p_c_xz), "Canto 4 apagado")
	print("  -> OK: Borracha apagou todos os 4 cantos simétricos simultaneamente.")

	editor.queue_free()
	print("--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---")
	get_tree().quit(0)
