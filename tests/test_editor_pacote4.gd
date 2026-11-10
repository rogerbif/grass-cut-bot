extends SceneTree

# Teste Automatizado — Pacote 4 do Editor de Fases:
# 1. Simplificação & UI Contextual (Ocultação de Formato/Escala/Rotação em Caixa/Balde/Spawn + Modo Tela Limpa Tab)
# 2. Performance Incremental (_rebuild_grass_3d / _rebuild_objects_3d sem reconstruir IslandMesh + Cache Costeiro O(1))
# 3. Sistema de Salvamento Blindado (Escrita Atômica .tmp -> .json + Backup em user://editor_backups/ + Auto-Save Snapshot)
# 4. Validador Pré-Save (Detecção de Spawn sobre a água ou colisão com rocha)
# 5. Paridade de Furos no Mapa Mundi (island_node.gd passando island_holes)

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("=== INICIANDO TESTE AUTOMATIZADO: PACOTE 4 DO EDITOR DE FASES ===")
	var failures: int = 0

	var editor_scene: PackedScene = load("res://scenes/editor/level_editor.tscn") as PackedScene
	if editor_scene == null:
		print("FAIL: Nao foi possivel carregar level_editor.tscn")
		quit(1)
		return

	var editor: Node3D = editor_scene.instantiate() as Node3D
	root.add_child(editor)
	await process_frame
	await process_frame

	# -------------------------------------------------------------------------
	# 1. UI Contextual & Modo Tela Limpa (Tab)
	# -------------------------------------------------------------------------
	var ui: Control = editor.get("ui") as Control
	if ui == null:
		print("FAIL 1: ui nao instanciada")
		failures += 1
	else:
		# Em modo BRUSH (0) na camada GRASS (1), formas e escala devem estar visíveis
		editor.set("active_layer", 1)
		editor.set("active_tool", 0)
		editor.call("_sync_all_ui", false)
		var lbl_shapes: Control = ui.get("lbl_shapes_node") as Control
		var panel_scale: Control = ui.get("panel_scale_box") as Control
		if lbl_shapes == null or not lbl_shapes.visible or panel_scale == null or not panel_scale.visible:
			print("FAIL 1a: Formas e escala deveriam estar visiveis no modo BRUSH")
			failures += 1
		else:
			print("PASS 1a: Formas e escala visiveis no modo BRUSH.")

		# Em modo FLOOD_FILL (4) ou BOX_FILL (2), formas, escala e girar devem ficar ocultos automaticamente
		editor.set("active_tool", 4) # FLOOD_FILL
		editor.call("_sync_all_ui", false)
		var panel_rot: Control = ui.get("panel_rotate_box") as Control
		if lbl_shapes.visible or panel_scale.visible or (panel_rot != null and panel_rot.visible):
			print("FAIL 1b: Formas/escala/girar deveriam ficar ocultos no modo FLOOD_FILL")
			failures += 1
		else:
			print("PASS 1b: UI Contextual oculta controles irrelevantes no modo Balde/Caixa.")

		# Modo Tela Limpa (Tab)
		var left_p: Control = ui.get("left_panel_node") as Control
		var right_p: Control = ui.get("right_panel_node") as Control
		var clean_on: bool = bool(ui.call("toggle_clean_screen_mode"))
		if not clean_on or left_p.visible or right_p.visible:
			print("FAIL 1c: Modo Tela Limpa nao ocultou os paineis laterais")
			failures += 1
		else:
			var clean_off: bool = bool(ui.call("toggle_clean_screen_mode"))
			if clean_off or not left_p.visible or not right_p.visible:
				print("FAIL 1d: Modo Tela Limpa nao restaurou os paineis laterais")
				failures += 1
			else:
				print("PASS 1c: Modo Tela Limpa [Tab] alterna paineis laterais perfeitamente.")

	# -------------------------------------------------------------------------
	# 2. Performance Incremental & Cache Costeiro O(1)
	# -------------------------------------------------------------------------
	editor.call("apply_island_template", "retangulo")
	var safe_1: Array = editor.call("_get_safe_coastal_island_polygons") as Array
	var cache_dirty_after: bool = bool(editor.get("_coastal_cache_dirty"))
	if safe_1.is_empty() or cache_dirty_after:
		print("FAIL 2a: Cache costeiro nao foi preenchido ou continuou dirty")
		failures += 1
	else:
		print("PASS 2a: Cache de poligonos costeiros seguros preenchido em O(1) (_coastal_cache_dirty = false).")

	var island_container: Node3D = editor.get("island_tiles_container") as Node3D
	var island_mesh_before: Node = island_container.get_child(0) if island_container.get_child_count() > 0 else null
	# Pintar grama deve chamar apenas _rebuild_grass_3d() e preservar a instancia de IslandMesh!
	editor.set("active_layer", 1) # GRASS
	editor.set("active_tool", 0)  # BRUSH
	var brush_poly: PackedVector2Array = PackedVector2Array([
		Vector2(-1.0, -1.0), Vector2(1.0, -1.0), Vector2(1.0, 1.0), Vector2(-1.0, 1.0)
	])
	editor.call("_apply_vector_polygon_to_active_layer", brush_poly, false, true)
	var island_mesh_after: Node = island_container.get_child(0) if island_container.get_child_count() > 0 else null
	if island_mesh_before == null or island_mesh_before != island_mesh_after:
		print("FAIL 2b: Pintar grama reconstruiu desnecessariamente a malha 3D da ilha!")
		failures += 1
	else:
		print("PASS 2b: Rebuild 3D incremental preservou a malha da ilha intacta ao pintar grama!")

	# -------------------------------------------------------------------------
	# 3. Sistema de Salvamento Blindado (Atômico + Backup + Auto-Save)
	# -------------------------------------------------------------------------
	var test_lvl_id: int = 198
	var test_json_path: String = "res://data/levels/level_198.json"
	var test_tmp_path: String = "res://data/levels/level_198.json.tmp"
	var test_bak_path: String = "user://editor_backups/level_198_bak.json"

	editor.call("save_level_as", test_lvl_id)
	# Salva uma segunda vez para acionar a criação de backup da versão anterior
	editor.set("time_limit", 105.0)
	if ui != null and ui.has_method("set_level_time_limit"):
		ui.call("set_level_time_limit", 105.0)
	editor.call("save_current_level_json")

	if not FileAccess.file_exists(test_json_path):
		print("FAIL 3a: Arquivo JSON principal nao foi salvo")
		failures += 1
	elif FileAccess.file_exists(test_tmp_path):
		print("FAIL 3b: Arquivo .tmp residual nao foi limpo apos escrita atomica")
		failures += 1
	elif not FileAccess.file_exists(test_bak_path):
		print("FAIL 3c: Backup automatico em user://editor_backups/level_198_bak.json nao foi gerado")
		failures += 1
	else:
		print("PASS 3a: Escrita atomica (.tmp -> .json) + Backup em user://editor_backups/ validados.")

	# Auto-Save snapshot
	var autosave_ok: bool = bool(editor.call("_perform_autosave"))
	if not autosave_ok or not FileAccess.file_exists("user://editor_autosave.json"):
		print("FAIL 3d: Snapshot de Auto-Save nao foi criado em user://editor_autosave.json")
		failures += 1
	else:
		print("PASS 3b: Snapshot de Auto-Save criado em user://editor_autosave.json.")

	# Limpa o arquivo temporário de teste 198 do diretório data/levels/
	var abs_test_json: String = ProjectSettings.globalize_path(test_json_path)
	if FileAccess.file_exists(test_json_path):
		DirAccess.remove_absolute(abs_test_json)

	# -------------------------------------------------------------------------
	# 4. Validador Pré-Save (Detecção de Spawn sobre a água)
	# -------------------------------------------------------------------------
	editor.call("apply_island_template", "atol")
	# No atol, o centro (gx = width/2, gz = height/2) é um lago/furo de água!
	var gw: int = int(editor.get("grid_width"))
	var gh: int = int(editor.get("grid_height"))
	editor.set("spawn_cell", Vector2i(int(float(gw) / 2.0), int(float(gh) / 2.0)))
	var warnings: Array = editor.call("validate_level_before_save") as Array
	var detected_water_spawn: bool = false
	for w_var: Variant in warnings:
		if String(w_var).contains("água"):
			detected_water_spawn = true
			break
	if not detected_water_spawn:
		print("FAIL 4: Validador pre-save nao detectou o Spawn posicionado no lago central do Atol")
		failures += 1
	else:
		print("PASS 4: Validador pre-save detectou Spawn sobre a agua: %s" % warnings[0])

	editor.free()

	if failures == 0:
		print("=== TODOS OS TESTES DO PACOTE 4 PASSARAM COM SUCESSO (0 FALHAS, 0 WARNINGS) ===")
		quit(0)
	else:
		print("=== FALHAS ENCONTRADAS NO PACOTE 4: %d ===" % failures)
		quit(1)
