extends SceneTree

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

func _init() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	var editor_scene: PackedScene = load("res://scenes/editor/level_editor.tscn") as PackedScene
	assert(editor_scene != null, "Failed to load level_editor.tscn")
	var editor: Node3D = editor_scene.instantiate() as Node3D
	root.add_child(editor)
	await process_frame
	await process_frame

	var ui: Control = editor.get("ui") as Control
	assert(ui != null, "UI should be initialized")

	# 1. Verificar botões da UI do Pacote 3 (Balde [5], Templates de Ilha e Duplicar/Salvar Como)
	var tool_btns: Dictionary = ui.get("tool_buttons") as Dictionary
	assert(tool_btns.has(4), "FAIL 1a: Botão [5] Balde (id=4) deve existir em tool_buttons")
	assert(ui.get("menu_island_templates") != null, "FAIL 1b: MenuButton de Templates de Ilha deve existir")
	assert(ui.get("btn_save_as") != null, "FAIL 1c: Botão Duplicar/Salvar Como deve existir")
	assert(ui.get("save_as_dialog") != null, "FAIL 1d: Modal save_as_dialog deve existir")

	# 2. Testar os 6 Templates de Ilha
	var templates: Array[String] = ["retangulo", "atol", "gemeas", "cruz_4", "estrela", "meia_lua"]
	for tpl_id: String in templates:
		editor.call("apply_island_template", tpl_id)
		var vt: RefCounted = editor.get("vector_terrain") as RefCounted
		assert(vt != null and not bool(vt.call("is_empty")), "FAIL 2a: Template '%s' deve gerar terreno não vazio" % tpl_id)
		var outer_polys: Array = vt.call("get_outer_polygons") as Array
		assert(outer_polys.size() >= 1, "FAIL 2b: Template '%s' deve possuir pelo menos 1 polígono externo" % tpl_id)
		if tpl_id == "atol":
			var holes_arr: Array = vt.call("get_holes") as Array
			assert(holes_arr.size() == 1, "FAIL 2c: Template 'atol' deve possuir 1 lagoa interna (hole)")

		var sp_cell: Vector2i = editor.get("spawn_cell") as Vector2i
		var gw: int = int(editor.get("grid_width"))
		var gh: int = int(editor.get("grid_height"))
		var cs: float = float(editor.get("CELL_SIZE"))
		var sp_world: Vector3 = LevelJsonLoader.grid_to_world(sp_cell.x, sp_cell.y, gw, gh, cs)
		var on_land: bool = bool(vt.call("is_point_on_land", Vector2(sp_world.x, sp_world.z)))
		assert(on_land, "FAIL 2d: Spawn do template '%s' deve estar sobre terra firme" % tpl_id)

	# 3. Testar Balde de Tinta na Camada 0 (Terreno) fechando o lago interno do Atol em 1 clique
	editor.call("apply_island_template", "atol")
	var vt_atol: RefCounted = editor.get("vector_terrain") as RefCounted
	assert((vt_atol.call("get_holes") as Array).size() == 1, "Atol deve iniciar com 1 furo no centro")
	assert(not bool(vt_atol.call("is_point_on_land", Vector2.ZERO)), "Centro (0,0) do Atol deve ser água")

	editor.set("active_layer", 0) # EditLayer.TERRAIN
	editor.set("active_tool", 4) # ToolMode.FLOOD_FILL
	var center_cell: Vector2i = Vector2i(int(editor.get("grid_width")) / 2, int(editor.get("grid_height")) / 2)
	editor.call("_apply_flood_fill_at", center_cell, Vector2.ZERO, false)
	assert((vt_atol.call("get_holes") as Array).is_empty(), "FAIL 3a: Balde de Terreno deve fechar o furo clicado")
	assert(bool(vt_atol.call("is_point_on_land", Vector2.ZERO)), "FAIL 3b: Centro (0,0) deve passar a ser terra firme após fechar furo")

	# 4. Testar Balde de Tinta na Camada 1 (Grama): Preencher ilha vazia e Recolorir mancha
	var obj_grid: Dictionary = editor.get("object_grid") as Dictionary
	obj_grid.clear()
	var vg: RefCounted = editor.get("vector_grass") as RefCounted
	vg.call("clear")
	assert((vg.call("get_shapes") as Array).is_empty(), "Grama deve estar vazia antes do Balde")

	editor.set("active_layer", 1) # EditLayer.GRASS
	editor.set("active_grass_id", "grass_blue")
	var sample_pt: Vector2 = Vector2(-2.0, 0.0)
	var sample_cell: Vector2i = LevelJsonLoader.world_to_grid(Vector3(sample_pt.x, 0.0, sample_pt.y), int(editor.get("grid_width")), int(editor.get("grid_height")), float(editor.get("CELL_SIZE")))
	editor.call("_apply_flood_fill_at", sample_cell, sample_pt, false)
	assert(String(vg.call("get_type_at_point", sample_pt)) == "grass_blue", "FAIL 4a: Balde deve preencher o solo livre com grass_blue")

	# Agora seleciona grass_yellow e clica com o Balde sobre a mancha de grass_blue para recolori-la
	editor.set("active_grass_id", "grass_yellow")
	editor.call("_apply_flood_fill_at", sample_cell, sample_pt, false)
	assert(String(vg.call("get_type_at_point", sample_pt)) == "grass_yellow", "FAIL 4b: Balde deve recolorir a mancha clicada de grass_blue para grass_yellow")

	# 5. Testar Balde de Tinta na Camada 2 (Objetos): Substituir tipo em lote
	editor.set("active_layer", 2) # EditLayer.OBJECTS
	obj_grid.clear()
	var c1: Vector2i = Vector2i(4, 4)
	var c2: Vector2i = Vector2i(6, 4)
	obj_grid[c1] = { "type": "flower_rose_red", "rot": 0 }
	obj_grid[c2] = { "type": "flower_rose_red", "rot": 0 }
	editor.set("active_object_id", "flower_rose_blue")
	editor.call("_apply_flood_fill_at", c1, Vector2.ZERO, false)
	assert(String((obj_grid[c1] as Dictionary)["type"]) == "flower_rose_blue" and String((obj_grid[c2] as Dictionary)["type"]) == "flower_rose_blue", "FAIL 5: Balde na Camada 2 deve substituir todas as ocorrências do mesmo tipo")

	# 6. Testar Duplicar / Salvar Como (save_level_as) em slot temporário (199)
	var temp_lvl_id: int = 199
	var temp_path: String = "res://data/levels/level_%d.json" % temp_lvl_id
	editor.call("save_level_as", temp_lvl_id)
	assert(int(editor.get("current_level_id")) == temp_lvl_id, "FAIL 6a: current_level_id deve atualizar para %d" % temp_lvl_id)
	assert(FileAccess.file_exists(temp_path), "FAIL 6b: Arquivo %s deve ser criado pelo save_level_as" % temp_path)
	assert(bool(editor.get("is_dirty")) == false, "FAIL 6c: is_dirty deve ser limpo após save_level_as")

	# Remove o arquivo temporário de teste
	var abs_temp: String = ProjectSettings.globalize_path(temp_path)
	if FileAccess.file_exists(temp_path):
		DirAccess.remove_absolute(abs_temp)

	editor.free()
	print("ALL TESTS PASSED (test_editor_pacote3: 6/6)")
	quit(0)
