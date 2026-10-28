extends SceneTree
## Teste headless: 8 Espécies de Flores em 3 partes + desprendimento de 2 pétalas e 1 folha no 1º hit.
## Execução: godot --headless --path . --script res://tests/test_flower_detach.gd

const FLOWER_SCENES: Array[String] = [
	"res://scenes/plants/flower_tuft.tscn",
	"res://scenes/plants/flower_rose.tscn",
	"res://scenes/plants/flower_daisy.tscn",
	"res://scenes/plants/flower_sunflower.tscn",
	"res://scenes/plants/flower_bell.tscn",
	"res://scenes/plants/flower_corolla.tscn",
	"res://scenes/plants/flower_tulip.tscn",
	"res://scenes/plants/flower_bed.tscn",
]

var _scene_idx: int = 0
var _current_flower: Node3D = null
var _frames: int = 0
var _elapsed: float = 0.0
var _spawned_max: int = 0
var _hit_done: bool = false
var _all_ok: bool = true


func _initialize() -> void:
	_load_next_flower()


func _load_next_flower() -> void:
	if _current_flower != null:
		_current_flower.queue_free()
		_current_flower = null

	if _scene_idx >= FLOWER_SCENES.size():
		print("\n==========================================")
		print("RESULTADO FINAL 8 FLORES: ", "OK" if _all_ok else "FALHA")
		print("==========================================")
		quit(0 if _all_ok else 1)
		return

	var path: String = FLOWER_SCENES[_scene_idx]
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		print("ERRO ao carregar ", path)
		_all_ok = false
		_scene_idx += 1
		_load_next_flower()
		return

	_current_flower = packed.instantiate() as Node3D
	root.add_child(_current_flower)
	current_scene = _current_flower

	var f_key: String = _current_flower.get("plant_key") as String
	print("\n--- Testando [", _scene_idx + 1, "/", FLOWER_SCENES.size(), "] ", f_key, " (", path.get_file(), ") ---")

	var model: Node = _current_flower.get_node_or_null("VisualMesh/FlowerModel")
	if model == null:
		print("ERRO: FlowerModel não encontrado em ", path)
		_all_ok = false
	else:
		for part: String in ["Flower_Stem", "Flower_Leaves", "Flower_Petals"]:
			var found: bool = model.get_node_or_null(part) != null
			print("  Parte ", part, " -> ", "OK" if found else "AUSENTE")
			if not found:
				_all_ok = false

	_frames = 0
	_elapsed = 0.0
	_spawned_max = 0
	_hit_done = false


func _count_pieces() -> int:
	if _current_flower == null:
		return 0
	var n: int = 0
	for c: Node in _current_flower.get_children():
		if c is FlowerDetachPiece:
			n += 1
	return n


func _process(delta: float) -> bool:
	if _current_flower == null:
		return false

	_frames += 1
	_elapsed += delta

	if _frames == 2 and not _hit_done:
		_current_flower.call("cut", 1)
		_hit_done = true

	if _hit_done:
		_spawned_max = maxi(_spawned_max, _count_pieces())

	# Aguarda 2.5s para as peças subirem, tocarem o solo, encolherem e sumirem
	if _elapsed > 2.5:
		var remaining: int = _count_pieces()
		var hp: int = int(_current_flower.get("health"))
		var f_key: String = _current_flower.get("plant_key") as String
		print("  Status ", f_key, ": max_pecas=", _spawned_max, " restantes=", remaining, " hp=", hp)
		if _spawned_max != 3 or remaining != 0 or hp != 2:
			print("  FALHA em ", f_key, "! (esperado: max 3 peças, 0 restantes, hp 2)")
			_all_ok = false
		else:
			print("  SUCESSO: 2 pétalas + 1 folha soltas e removidas.")

		_scene_idx += 1
		_load_next_flower()

	return false
