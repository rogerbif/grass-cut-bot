extends SceneTree
## Teste headless: Flor Silvestre em 3 partes + desprendimento de 2 pétalas e 1 folha no 1º hit.
## Execução: godot --headless --path . --script res://tests/test_flower_detach.gd

var _frames: int = 0
var _elapsed: float = 0.0
var _flower: Node3D = null
var _spawned_max: int = 0
var _hit_done: bool = false
var _ok: bool = true


func _initialize() -> void:
	var packed: PackedScene = load("res://scenes/plants/flower_tuft.tscn") as PackedScene
	_flower = packed.instantiate() as Node3D
	root.add_child(_flower)
	current_scene = _flower
	var model: Node = _flower.get_node("VisualMesh/FlowerModel")
	for part: String in ["Flower_Stem", "Flower_Leaves", "Flower_Petals"]:
		var found: bool = model.get_node_or_null(part) != null
		print("PARTE ", part, " -> ", found)
		if not found:
			_ok = false


func _count_pieces() -> int:
	var n: int = 0
	for c: Node in _flower.get_children():
		if c is FlowerDetachPiece:
			n += 1
	return n


func _process(delta: float) -> bool:
	_frames += 1
	_elapsed += delta
	if _frames == 2 and not _hit_done:
		_flower.call("cut", 1)
		_hit_done = true
	if _hit_done:
		_spawned_max = maxi(_spawned_max, _count_pieces())
	# Aguarda 3s de tempo de jogo acumulado
	if _elapsed > 3.0:
		var remaining: int = _count_pieces()
		print("PECAS MAX=", _spawned_max, " RESTANTES=", remaining, " HP=", _flower.get("health"))
		if _spawned_max != 3 or remaining != 0:
			_ok = false
		print("RESULTADO: ", "OK" if _ok else "FALHA")
		quit(0 if _ok else 1)
	return false
