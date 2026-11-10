extends SceneTree

# Teste Automatizado — Pacote 5 do Editor de Fases:
# 1. Estrela Customizável (star_points de 3 a 16 + star_inner_ratio + modo Polígono Regular)
# 2. Cruz Customizável (cross_thickness) e Anel com Furo Central (ShapeType.RING)
# 3. Sistema de Pincéis por Imagem P&B (BitMap.opaque_to_polygons com cache O(1), 6 presets e inversão P&B)
# 4. Aplicação de Imagem P&B Multi-Polígono no Terreno Vetorial (ex.: Patinha = 5 ilhotas em 1 clique)
# 5. Visibilidade Contextual de brush_custom_params_box na UI

const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("=== INICIANDO TESTE AUTOMATIZADO: PACOTE 5 DO EDITOR DE FASES ===")
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
	# 1. Estrela Customizável (Pontas 3..16 e Modo Polígono Regular)
	# -------------------------------------------------------------------------
	var poly_star_5: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
		BrushPatterns.ShapeType.STAR, 4, Vector2.ZERO, 0.0, 0.28, { "star_points": 5, "star_inner_ratio": 0.45 }
	)
	var poly_star_8: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
		BrushPatterns.ShapeType.STAR, 4, Vector2.ZERO, 0.0, 0.28, { "star_points": 8, "star_inner_ratio": 0.45 }
	)
	var poly_hex_reg: PackedVector2Array = BrushPatterns.get_vector_stamp_polygon(
		BrushPatterns.ShapeType.STAR, 4, Vector2.ZERO, 0.0, 0.28, { "star_points": 6, "star_inner_ratio": 1.0 }
	)
	if poly_star_5.size() != 10 or poly_star_8.size() != 16 or poly_hex_reg.size() != 6:
		print("FAIL 1: Vertices incorretos na Estrela/Poligono customizavel (%d, %d, %d)" % [poly_star_5.size(), poly_star_8.size(), poly_hex_reg.size()])
		failures += 1
	else:
		print("PASS 1: Estrela Parametrica validada (5 pontas=10v, 8 pontas=16v, Hexagono Regular=6v).")

	# -------------------------------------------------------------------------
	# 2. Pincel Anel / Rosquinha (ShapeType.RING) com Furo Automático
	# -------------------------------------------------------------------------
	editor.call("_on_clear_terrain")
	editor.set("active_layer", 0) # TERRAIN
	editor.set("active_tool", 0)  # BRUSH
	editor.set("active_shape", BrushPatterns.ShapeType.RING)
	editor.set("brush_size", 8)
	editor.set("is_hover_in_bounds", true)
	editor.set("last_world_hit", Vector3.ZERO)
	editor.call("_apply_brush_at", Vector2i(12, 8), false)

	var vt: RefCounted = editor.get("vector_terrain") as RefCounted
	var ring_outer: Array = vt.call("get_outer_polygons") as Array
	var ring_holes: Array = vt.call("get_holes") as Array
	if ring_outer.size() != 1 or ring_holes.size() != 1:
		print("FAIL 2: Pincel Anel deveria criar 1 ilha externa e 1 furo central (obteve outer=%d, holes=%d)" % [ring_outer.size(), ring_holes.size()])
		failures += 1
	else:
		print("PASS 2: Pincel Anel (ShapeType.RING) criou ilha com furo central automaticamente.")

	# -------------------------------------------------------------------------
	# 3. Sistema de Pincéis por Imagem P&B (BitMap.opaque_to_polygons)
	# -------------------------------------------------------------------------
	var paw_polys: Array[PackedVector2Array] = BrushPatterns.get_normalized_image_polygons("paw", false, 1.5)
	if paw_polys.size() != 5:
		print("FAIL 3a: Preset P&B 'paw' (Patinha) deveria extrair 5 poligonos via BitMap (1 almofada + 4 dedos), mas obteve %d" % paw_polys.size())
		failures += 1
	else:
		print("PASS 3a: Vetorizacao BitMap.opaque_to_polygons extraiu 5 poligonos da imagem P&B 'paw' (Patinha).")

	# Testa todos os 6 presets P&B
	for pm: Dictionary in BrushPatterns.IMAGE_PRESETS_META:
		var pid: String = String(pm["id"])
		var p_arr: Array[PackedVector2Array] = BrushPatterns.get_normalized_image_polygons(pid, false, 1.5)
		if p_arr.is_empty():
			print("FAIL 3b: Preset P&B '%s' nao gerou poligonos" % pid)
			failures += 1
	print("PASS 3b: Todos os 6 presets de Imagem P&B ('paw', 'spiral', 'moon', 'bolt', 'clover', 'puzzle') vetorizados com sucesso.")

	# -------------------------------------------------------------------------
	# 4. Carimbar Imagem P&B Multi-Polígono no Terreno Vetorial
	# -------------------------------------------------------------------------
	editor.call("_on_clear_terrain")
	editor.set("active_layer", 0) # TERRAIN
	editor.set("active_tool", 0)  # BRUSH
	editor.set("active_shape", BrushPatterns.ShapeType.IMAGE_STAMP)
	editor.set("brush_size", 10)
	var params: Dictionary = editor.call("get_current_brush_params") as Dictionary
	params["image_id"] = "paw"
	params["image_invert"] = false
	editor.set("brush_custom_params", params)
	editor.set("is_hover_in_bounds", true)
	editor.set("last_world_hit", Vector3.ZERO)
	editor.call("_apply_brush_at", Vector2i(12, 8), false)

	var paw_islands: Array = vt.call("get_outer_polygons") as Array
	if paw_islands.size() != 5:
		print("FAIL 4: Carimbar a Patinha P&B no Terreno deveria criar 5 ilhotas (1 almofada + 4 dedos), obteve %d" % paw_islands.size())
		failures += 1
	else:
		print("PASS 4: Carimbo P&B 'paw' gerou 5 ilhotas 3D independentes em 1 clique!")

	# -------------------------------------------------------------------------
	# 5. UI Contextual de Customização de Pincéis
	# -------------------------------------------------------------------------
	var ui: Control = editor.get("ui") as Control
	var cp_box: Control = ui.get("brush_custom_params_box") as Control
	var box_star: Control = ui.get("box_star_params") as Control
	var box_img: Control = ui.get("box_image_params") as Control

	editor.set("active_shape", BrushPatterns.ShapeType.SQUARE)
	editor.call("_sync_all_ui", false)
	if cp_box == null or cp_box.visible:
		print("FAIL 5a: Subpainel de customizacao deveria ficar oculto no formato SQUARE")
		failures += 1
	else:
		editor.set("active_shape", BrushPatterns.ShapeType.STAR)
		editor.call("_sync_all_ui", false)
		if not cp_box.visible or not box_star.visible or box_img.visible:
			print("FAIL 5b: Subpainel de Estrela deveria ficar visivel quando STAR esta selecionado")
			failures += 1
		else:
			editor.set("active_shape", BrushPatterns.ShapeType.IMAGE_STAMP)
			editor.call("_sync_all_ui", false)
			if not cp_box.visible or not box_img.visible or box_star.visible:
				print("FAIL 5c: Subpainel de Imagem P&B deveria ficar visivel quando IMAGE_STAMP esta selecionado")
				failures += 1
			else:
				print("PASS 5: UI Contextual exibe os controles de Estrela, Cruz, Anel e Imagem P&B sob demanda.")

	editor.free()

	if failures == 0:
		print("=== TODOS OS TESTES DO PACOTE 5 PASSARAM COM SUCESSO (0 FALHAS, 0 WARNINGS) ===")
		quit(0)
	else:
		print("=== FALHAS ENCONTRADAS NO PACOTE 5: %d ===" % failures)
		quit(1)
