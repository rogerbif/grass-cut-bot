extends Node

const LevelEditor = preload("res://scripts/editor/level_editor.gd")

func _ready() -> void:
	call_deferred("_run_tests")

func _run_tests() -> void:
	print("--- TESTES DE UNIDADE: SELEÇÃO, MOVER E DUPLICAR (CTRL+D / CTRL+C / CTRL+V) ---")

	var editor_scene: PackedScene = load("res://scenes/editor/level_editor.tscn")
	var editor: Node = editor_scene.instantiate()
	add_child(editor)

	await get_tree().process_frame
	await get_tree().process_frame

	# Teste 1: Validação do Enum ToolMode.SELECT
	print("[Teste 1] ToolMode.SELECT...")
	assert(editor.get("ToolMode").get("SELECT") == 5, "ToolMode.SELECT deve ter valor 5")
	print("  -> OK: ToolMode.SELECT catalogado com índice 5.")

	# Configura dados iniciais na grade:
	# Ilha e margaridas em (3, 3) e (3, 4)
	editor.set("terrain_grid", {
		Vector2i(3, 3): { "tile_id": "island_center", "rot": 0, "auto": true },
		Vector2i(3, 4): { "tile_id": "island_center", "rot": 0, "auto": true }
	})
	editor.set("object_grid", {
		Vector2i(3, 3): { "type": "flower_daisy", "rot": 0 },
		Vector2i(3, 4): { "type": "flower_daisy", "rot": 0 }
	})

	# Teste 2: Seleção Múltipla via Bounding Box
	print("[Teste 2] Seleção Múltipla (Bounding Box de [3,3] até [4,5])...")
	editor.set("active_tool", 5) # SELECT
	editor.set("selection_rect", Rect2i(3, 3, 2, 3))
	editor.set("has_selection", true)
	editor.call("copy_selection")

	var clip: Dictionary = editor.get("selection_clipboard") as Dictionary
	assert(not clip.is_empty(), "Clipboard não pode estar vazio após copiar seleção")
	var t_clip: Dictionary = clip.get("terrain", {}) as Dictionary
	var o_clip: Dictionary = clip.get("objects", {}) as Dictionary
	assert(t_clip.size() == 2, "Clipboard deve conter 2 blocos de terreno")
	assert(o_clip.size() == 2, "Clipboard deve conter 2 flores")
	print("  -> OK: Seleção capturou 2 blocos e 2 flores com coordenadas relativas.")

	# Teste 3: Duplicação (Duplicate / Ctrl+D) e Colagem em [7, 7]
	print("[Teste 3] Duplicação via apply_paste_at em [7, 7]...")
	editor.call("apply_paste_at", Vector2i(7, 7))

	var terr: Dictionary = editor.get("terrain_grid") as Dictionary
	var objs: Dictionary = editor.get("object_grid") as Dictionary

	# Origem ainda deve existir (pois foi cópia/duplicação, não corte)
	assert(terr.has(Vector2i(3, 3)) and terr.has(Vector2i(3, 4)), "Posições de origem devem continuar intactas")
	assert(objs.has(Vector2i(3, 3)) and objs.has(Vector2i(3, 4)), "Flores de origem devem continuar intactas")

	# Destino duplicado em [7,7] e [7,8] deve conter os dados clonados
	assert(terr.has(Vector2i(7, 7)) and terr.has(Vector2i(7, 8)), "Destino duplicado deve conter blocos de terreno")
	assert(objs.has(Vector2i(7, 7)) and objs.has(Vector2i(7, 8)), "Destino duplicado deve conter flores clonadas")
	assert(String((objs[Vector2i(7, 7)] as Dictionary).get("type", "")) == "flower_daisy", "Tipo de flor duplicada deve ser daisy")
	print("  -> OK: Duplicação estamparam flores e terreno em [7, 7] com 100% de fidelidade.")

	# Teste 4: Movimentação da Seleção (Move & Commit)
	print("[Teste 4] Movimentação da seleção de [7, 7] para [9, 9]...")
	editor.set("selection_rect", Rect2i(7, 7, 2, 2))
	editor.set("has_selection", true)
	editor.call("copy_selection")
	editor.set("move_offset", Vector2i(2, 2)) # Desloca +2 em X e +2 em Z -> [9, 9]
	editor.call("commit_move_selection")

	terr = editor.get("terrain_grid") as Dictionary
	objs = editor.get("object_grid") as Dictionary

	# A posição antiga [7,7] e [7,8] foi movida, logo deve ser limpa
	assert(not terr.has(Vector2i(7, 7)) and not terr.has(Vector2i(7, 8)), "Posição anterior deve ser limpa após mover")
	assert(not objs.has(Vector2i(7, 7)) and not objs.has(Vector2i(7, 8)), "Flores anteriores devem ser limpas após mover")

	# Nova posição [9,9] e [9,10] deve conter os elementos
	assert(terr.has(Vector2i(9, 9)) and terr.has(Vector2i(9, 10)), "Nova posição deve conter os blocos movidos")
	assert(objs.has(Vector2i(9, 9)) and objs.has(Vector2i(9, 10)), "Nova posição deve conter as flores movidas")
	print("  -> OK: Seleção movida de [7,7] para [9,9] com limpeza da posição de origem.")

	# Teste 5: Deletar Seleção (Delete / Backspace)
	print("[Teste 5] Deletar área selecionada em [9, 9]...")
	editor.call("delete_selection")

	terr = editor.get("terrain_grid") as Dictionary
	objs = editor.get("object_grid") as Dictionary
	assert(not terr.has(Vector2i(9, 9)) and not terr.has(Vector2i(9, 10)), "Blocos em [9,9] devem ser deletados")
	assert(not objs.has(Vector2i(9, 9)) and not objs.has(Vector2i(9, 10)), "Flores em [9,9] devem ser deletadas")
	print("  -> OK: Área selecionada deletada com sucesso.")

	# Teste 6: Desfazer (Ctrl+Z) restaura o que foi deletado
	print("[Teste 6] Undo (Ctrl+Z) após deleção...")
	editor.call("perform_undo")
	terr = editor.get("terrain_grid") as Dictionary
	objs = editor.get("object_grid") as Dictionary
	assert(terr.has(Vector2i(9, 9)) and terr.has(Vector2i(9, 10)), "Undo deve restaurar os blocos deletados")
	assert(objs.has(Vector2i(9, 9)) and objs.has(Vector2i(9, 10)), "Undo deve restaurar as flores deletadas")
	print("  -> OK: Ctrl+Z restaurou perfeitamente os elementos.")

	editor.queue_free()
	print("--- TODOS OS TESTES PASSARAM COM 100% DE SUCESSO! ---")
	get_tree().quit(0)
