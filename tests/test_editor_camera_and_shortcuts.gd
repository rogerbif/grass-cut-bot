extends Node

const LevelEditorScene = preload("res://scenes/editor/level_editor.tscn")
const IsometricCameraScript = preload("res://scripts/camera/isometric_camera.gd")

func _ready() -> void:
	print("==================================================")
	print("🧪 TESTES AUTOMATIZADOS: CÂMERA F1 & ATALHOS S/R")
	print("==================================================")

	var failed: int = 0
	failed += test_playtest_game_camera_presence()
	failed += test_scale_shortcuts_and_clamping()
	failed += test_rotation_step_and_shift()
	failed += test_rotation_negative_wrap()
	failed += test_bracket_keys_universal_and_flower_rotation()

	print("==================================================")
	if failed == 0:
		print("✅ TODOS OS TESTES PASSARAM COM SUCESSO! (0 falhas)")
		get_tree().quit(0)
	else:
		printerr("❌ FALHA EM %d TESTES!" % failed)
		get_tree().quit(1)

func test_playtest_game_camera_presence() -> int:
	print("\n--- Teste 1: Presença e Paridade da Câmera Playtest F1 ---")
	var editor: Node3D = LevelEditorScene.instantiate() as Node3D
	add_child(editor)

	var playtest_cam: Camera3D = editor.get_node_or_null("PlaytestGameCamera") as Camera3D
	if playtest_cam == null:
		printerr("FAIL: Nó PlaytestGameCamera não encontrado em level_editor.tscn!")
		editor.queue_free()
		return 1

	if absf(playtest_cam.fov - 48.0) > 0.01:
		printerr("FAIL: FOV de PlaytestGameCamera esperado 48.0, obtido %f" % playtest_cam.fov)
		editor.queue_free()
		return 1

	if not (playtest_cam.get_script() == IsometricCameraScript):
		printerr("FAIL: PlaytestGameCamera não possui o script canônico IsometricCamera!")
		editor.queue_free()
		return 1

	print("PASS: PlaytestGameCamera configurada com sucesso com FOV 48.0 e script canônico IsometricCamera.")
	editor.queue_free()
	return 0

func test_scale_shortcuts_and_clamping() -> int:
	print("\n--- Teste 2: Ajuste de Escala (Atalho S, +/- com e sem Shift) ---")
	var editor: Node3D = LevelEditorScene.instantiate() as Node3D
	add_child(editor)

	editor.brush_size = 1
	# Teste +1 sem Shift
	editor.call("_adjust_scale", 1)
	if editor.brush_size != 2:
		printerr("FAIL: brush_size esperado 2, obtido %d" % editor.brush_size)
		editor.queue_free()
		return 1

	# Teste +5 com Shift
	editor.call("_adjust_scale", 5)
	if editor.brush_size != 7:
		printerr("FAIL: brush_size com Shift (+5) esperado 7, obtido %d" % editor.brush_size)
		editor.queue_free()
		return 1

	# Teste -5 com Shift
	editor.call("_adjust_scale", -5)
	if editor.brush_size != 2:
		printerr("FAIL: brush_size com Shift (-5) esperado 2, obtido %d" % editor.brush_size)
		editor.queue_free()
		return 1

	# Teste Clamping mínimo (1) e máximo (20)
	editor.call("_adjust_scale", -10)
	if editor.brush_size != 1:
		printerr("FAIL: brush_size mínimo clamped esperado 1, obtido %d" % editor.brush_size)
		editor.queue_free()
		return 1

	editor.call("_adjust_scale", 30)
	if editor.brush_size != 20:
		printerr("FAIL: brush_size máximo clamped esperado 20, obtido %d" % editor.brush_size)
		editor.queue_free()
		return 1

	print("PASS: Ajuste de escala por 1 e 5 (Shift) e clamping [1..20] validados perfeitamente.")
	editor.queue_free()
	return 0

func test_rotation_step_and_shift() -> int:
	print("\n--- Teste 3: Rotação Padrão (5°) e com Shift (25°) ---")
	var editor: Node3D = LevelEditorScene.instantiate() as Node3D
	add_child(editor)

	editor.active_layer = 1 # EditLayer.GRASS
	editor.current_rot_deg = 0

	# Giro horário sem shift (+5°)
	editor.call("_rotate_active_step_dir", 1, false)
	if editor.current_rot_deg != 5:
		printerr("FAIL: Rotação horária (+5°) esperada 5°, obtida %d°" % editor.current_rot_deg)
		editor.queue_free()
		return 1

	# Giro horário com shift (+25°) -> 5 + 25 = 30°
	editor.call("_rotate_active_step_dir", 1, true)
	if editor.current_rot_deg != 30:
		printerr("FAIL: Rotação horária com Shift (+25°) esperada 30°, obtida %d°" % editor.current_rot_deg)
		editor.queue_free()
		return 1

	print("PASS: Incrementos de 5° padrão e 25° com Shift validados perfeitamente.")
	editor.queue_free()
	return 0

func test_rotation_negative_wrap() -> int:
	print("\n--- Teste 4: Rotação Anti-horária (Esquerda) e Normalização [0..359°] ---")
	var editor: Node3D = LevelEditorScene.instantiate() as Node3D
	add_child(editor)

	editor.active_layer = 1 # EditLayer.GRASS
	editor.current_rot_deg = 0

	# Giro anti-horário (-5°) a partir de 0° -> deve normalizar para 355°
	editor.call("_rotate_active_step_dir", -1, false)
	if editor.current_rot_deg != 355:
		printerr("FAIL: Giro anti-horário (-5°) esperado 355°, obtido %d°" % editor.current_rot_deg)
		editor.queue_free()
		return 1

	# Giro anti-horário com shift (-25°) a partir de 0° -> deve normalizar para 335°
	editor.current_rot_deg = 0
	editor.call("_rotate_active_step_dir", -1, true)
	if editor.current_rot_deg != 335:
		printerr("FAIL: Giro anti-horário com Shift (-25°) esperado 335°, obtido %d°" % editor.current_rot_deg)
		editor.queue_free()
		return 1

	# Terreno (Camada 0): giro de 90° em 90°
	editor.active_layer = 0 # EditLayer.TERRAIN
	editor.current_rot_deg = 0
	editor.call("_rotate_active_step_dir", -1, false)
	if editor.current_rot_deg != 270:
		printerr("FAIL: Terreno giro anti-horário esperado 270°, obtido %d°" % editor.current_rot_deg)
		editor.queue_free()
		return 1

	editor.call("_rotate_active_step_dir", 1, false)
	if editor.current_rot_deg != 0:
		printerr("FAIL: Terreno giro horário esperado 0°, obtido %d°" % editor.current_rot_deg)
		editor.queue_free()
		return 1

	print("PASS: Rotação anti-horária (esquerda) e normalização circular modular 360° validadas com sucesso.")
	editor.queue_free()
	return 0

func test_bracket_keys_universal_and_flower_rotation() -> int:
	print("\n--- Teste 5: Teclas [ e ] Universais (Escala vs Rotação) & Flores Rotação Padrão ---")
	var editor: Node3D = LevelEditorScene.instantiate() as Node3D
	add_child(editor)

	# 1. Por padrão, a ferramenta selecionada é Escala
	if editor.active_adjust_mode != 1: # QuickAdjustMode.SCALE
		printerr("FAIL: active_adjust_mode padrão esperado SCALE (1), obtido %d" % editor.active_adjust_mode)
		editor.queue_free()
		return 1

	editor.brush_size = 3
	# Simula evento [ em modo Escala
	var ev_bracket_left: InputEventKey = InputEventKey.new()
	ev_bracket_left.keycode = KEY_BRACKETLEFT
	ev_bracket_left.pressed = true
	editor.call("_input", ev_bracket_left)
	if editor.brush_size != 2:
		printerr("FAIL: [ em modo Escala deveria reduzir brush_size para 2, obtido %d" % editor.brush_size)
		editor.queue_free()
		return 1

	# Simula evento ] em modo Escala
	var ev_bracket_right: InputEventKey = InputEventKey.new()
	ev_bracket_right.keycode = KEY_BRACKETRIGHT
	ev_bracket_right.pressed = true
	editor.call("_input", ev_bracket_right)
	if editor.brush_size != 3:
		printerr("FAIL: ] em modo Escala deveria aumentar brush_size para 3, obtido %d" % editor.brush_size)
		editor.queue_free()
		return 1

	# 2. Pressiona tecla R para mudar para modo Rotação
	var ev_r: InputEventKey = InputEventKey.new()
	ev_r.keycode = KEY_R
	ev_r.pressed = true
	editor.call("_input", ev_r)
	if editor.active_adjust_mode != 0: # QuickAdjustMode.ROTATION
		printerr("FAIL: Tecla R deveria ativar ROTATION (0), obtido %d" % editor.active_adjust_mode)
		editor.queue_free()
		return 1

	# Em modo Rotação, [ e ] devem girar
	editor.active_layer = 1 # GRASS
	var rot_start: int = editor.current_rot_deg
	editor.call("_input", ev_bracket_right)
	if editor.current_rot_deg != posmod(rot_start + 5, 360):
		printerr("FAIL: ] em modo Rotação deveria girar +5°, obtido %d°" % editor.current_rot_deg)
		editor.queue_free()
		return 1

	editor.call("_input", ev_bracket_left)
	if editor.current_rot_deg != rot_start:
		printerr("FAIL: [ em modo Rotação deveria girar -5° de volta para %d°, obtido %d°" % [rot_start, editor.current_rot_deg])
		editor.queue_free()
		return 1

	# 3. Pressiona tecla S para voltar para modo Escala
	var ev_s: InputEventKey = InputEventKey.new()
	ev_s.keycode = KEY_S
	ev_s.pressed = true
	editor.call("_input", ev_s)
	if editor.active_adjust_mode != 1: # QuickAdjustMode.SCALE
		printerr("FAIL: Tecla S deveria reativar SCALE (1), obtido %d" % editor.active_adjust_mode)
		editor.queue_free()
		return 1

	# 4. Verifica rotação padrão de flor (voltada para a câmera = 0°)
	editor.active_layer = 2 # OBJECTS
	editor.active_object_id = "flower_daisy"
	var test_cell: Vector2i = Vector2i(2, 2)
	editor.call("_modify_single_cell", test_cell, false)
	var placed_obj: Dictionary = editor.object_grid.get(test_cell, {}) as Dictionary
	if int(placed_obj.get("rot", -1)) != 0:
		printerr("FAIL: Flor inserida em modo padrão deveria ter rot = 0 (frente para câmera), obtido %d" % int(placed_obj.get("rot", -1)))
		editor.queue_free()
		return 1

	print("PASS: Teclas [ e ] universais (Escala vs Rotação) e flor com rotação 0° padrão validadas com sucesso.")
	editor.queue_free()
	return 0
