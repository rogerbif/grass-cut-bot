extends Node

const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")
const LevelEditor = preload("res://scripts/editor/level_editor.gd")

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- TESTES DE UNIDADE: PIPETA (CONTA-GOTAS) E ANEL CIRCULAR ---")

	# Teste 1: Validação do Enum e Metadados do Anel Circular
	print("[Teste 1] ShapeType.RING em BrushPatterns...")
	assert(BrushPatterns.ShapeType.RING == 7, "ShapeType.RING deve ter ID 7")
	var ring_found: bool = false
	for s in BrushPatterns.SHAPE_INFO:
		if int(s.get("id", -1)) == BrushPatterns.ShapeType.RING:
			ring_found = true
			assert(s.get("name") == "Anel Circular", "Nome da forma incorreto")
			assert(s.get("icon") == "⭕", "Ícone da forma incorreto")
			break
	assert(ring_found, "ShapeType.RING deve estar catalogado em SHAPE_INFO")
	print("  -> OK: ShapeType.RING catalogado corretamente.")

	# Teste 2: Cálculo dos offsets do Anel para Grade
	print("[Teste 2] Offsets de BrushPatterns.get_brush_offsets com RING...")
	var offsets_sz1: Array[Vector2i] = BrushPatterns.get_brush_offsets(BrushPatterns.ShapeType.RING, 1)
	assert(not offsets_sz1.is_empty(), "Offsets do anel tamanho 1 não devem estar vazios")
	assert(not offsets_sz1.has(Vector2i.ZERO), "O centro (0,0) deve estar vazio em um anel!")
	print("  -> OK: Anel tamanho 1 gerou %d células com centro oco." % offsets_sz1.size())

	var offsets_sz2: Array[Vector2i] = BrushPatterns.get_brush_offsets(BrushPatterns.ShapeType.RING, 2)
	assert(offsets_sz2.size() >= offsets_sz1.size(), "Anel de tamanho maior deve ter igual ou mais pontos")
	assert(not offsets_sz2.has(Vector2i.ZERO), "O centro do anel tamanho 2 deve estar oco")
	print("  -> OK: Anel tamanho 2 gerou %d células com centro oco." % offsets_sz2.size())

	# Teste 3: Polígonos de anel para grama vetorial
	print("[Teste 3] BrushPatterns.get_ring_polygons...")
	var ring_poly_dict: Dictionary = BrushPatterns.get_ring_polygons(Vector2.ZERO, 1.5, 0.5)
	assert(ring_poly_dict.has("outer") and ring_poly_dict.has("hole"), "Dicionário de anel deve conter outer e hole")
	var outer_p: PackedVector2Array = ring_poly_dict["outer"] as PackedVector2Array
	var hole_p: PackedVector2Array = ring_poly_dict["hole"] as PackedVector2Array
	assert(outer_p.size() >= 8, "Polígono externo deve ter no mínimo 8 vértices")
	assert(hole_p.size() >= 8, "Polígono do furo deve ter no mínimo 8 vértices")
	print("  -> OK: Polígonos do anel gerados com sucesso.")

	# Teste 4: Instanciação e teste da Pipeta (Conta-Gotas) no LevelEditor
	print("[Teste 4] Funcionamento da Pipeta no LevelEditor...")
	var editor_scene: PackedScene = load("res://scenes/editor/level_editor.tscn")
	var editor: Node = editor_scene.instantiate()
	add_child(editor)

	# Espera dois frames para inicialização completa
	await get_tree().process_frame
	await get_tree().process_frame

	assert(editor.get("ToolMode").get("PICKER") == 4, "ToolMode.PICKER deve ser 4")

	# Mock de dados: Terreno em (2, 2), Grama em (4, 4), Objeto flor em (3, 3)
	editor.set("terrain_grid", {
		Vector2i(2, 2): { "tile_id": "tile_sand", "rot": 90, "auto": false },
		Vector2i(3, 3): { "tile_id": "island_center", "rot": 0, "auto": true }
	})
	editor.set("object_grid", {
		Vector2i(3, 3): { "type": "flower_daisy", "rot": 0 }
	})

	# Pipeta em (3, 3) deve selecionar Objeto (flower_daisy)
	editor.call("_pick_at_hovered", Vector2i(3, 3), Vector2(0.0, 0.0))
	assert(int(editor.get("active_layer")) == 2, "Pipeta em (3,3) deve selecionar EditLayer.OBJECTS (2)")
	assert(String(editor.get("active_object_id")) == "flower_daisy", "Pipeta deve capturar flower_daisy")
	print("  -> OK: Pipeta capturou objeto flower_daisy com sucesso.")

	# Pipeta em (2, 2) deve selecionar Terreno (tile_sand, rot 90)
	editor.call("_pick_at_hovered", Vector2i(2, 2), Vector2(0.0, 0.0))
	assert(int(editor.get("active_layer")) == 0, "Pipeta em (2,2) deve selecionar EditLayer.TERRAIN (0)")
	assert(String(editor.get("active_terrain_id")) == "tile_sand", "Pipeta deve capturar tile_sand")
	assert(int(editor.get("current_rot_deg")) == 90, "Pipeta deve capturar rotação de 90° do terreno")
	print("  -> OK: Pipeta capturou terreno tile_sand e rotação 90° com sucesso.")

	# Teste de retorno automático de ferramenta após clique com ToolMode.PICKER
	editor.set("active_tool", 4) # ToolMode.PICKER
	editor.call("_pick_at_hovered", Vector2i(3, 3), Vector2(0.0, 0.0))
	assert(int(editor.get("active_tool")) == 0, "Pipeta deve retornar automaticamente para ToolMode.BRUSH (0) após captura")
	print("  -> OK: ToolMode.PICKER retornou para ToolMode.BRUSH após captura.")

	# Teste 5: Carimbo em Anel de Flores
	print("[Teste 5] Carimbo de Flores em Anel Circular...")
	editor.set("active_layer", 2) # OBJECTS
	editor.set("active_object_id", "flower_daisy")
	editor.set("active_shape", BrushPatterns.ShapeType.RING)
	editor.set("brush_size", 1)
	editor.set("is_hover_in_bounds", true)
	editor.call("_apply_brush_at", Vector2i(5, 5), false)

	var obj_grid: Dictionary = editor.get("object_grid") as Dictionary
	var flower_count: int = 0
	for pos in obj_grid:
		var item: Dictionary = obj_grid[pos] as Dictionary
		if String(item.get("type", "")) == "flower_daisy":
			flower_count += 1
			assert(int(item.get("rot", 0)) == 0, "Flores posicionadas no anel devem ter rot = 0 (frente para câmera)")
	assert(flower_count >= 6, "Anel tamanho 1 deve ter posicionado pelo menos 6 flores")
	assert(not obj_grid.has(Vector2i(5, 5)), "O centro do anel (5, 5) deve permanecer vazio")
	print("  -> OK: Anel de flores criado com %d flores voltadas para a câmera (0°) e centro oco." % flower_count)

	editor.queue_free()
	print("--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---")
	get_tree().quit(0)
