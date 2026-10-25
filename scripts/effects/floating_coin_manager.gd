class_name FloatingCoinManager
extends Node3D

## Gerencia o pool de números flutuantes cartoon 3D (+1, +3, +5).
## Estilo cel-shaded cartoon com contorno preto grosso no círculo interno da lâmina.

const POOL_SIZE: int = 64

const COLOR_GRASS: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_WHEAT: Color = Color(1.0, 0.90, 0.20, 1.0)
const COLOR_FLOWER: Color = Color(1.0, 0.40, 0.85, 1.0)

@export var cutter_path: NodePath = NodePath("../LevelController/Cutter")

var _pool: Array[Label3D] = []
var _tweens: Array[Tween] = []
var _next_index: int = 0
var _cached_cutter: CharacterBody3D = null


func _ready() -> void:
	_init_pool()
	_get_cutter()
	if GameManager:
		GameManager.coin_popup_requested.connect(_on_coin_popup_requested)


func _init_pool() -> void:
	_pool.clear()
	_tweens.clear()
	for i in range(POOL_SIZE):
		var label: Label3D = Label3D.new()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 25
		label.font_size = 56
		label.pixel_size = 0.005
		label.outline_size = 14
		label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
		label.shaded = false
		label.double_sided = true
		label.visible = false
		add_child(label)
		_pool.append(label)
		_tweens.append(null)


func _get_cutter() -> CharacterBody3D:
	if _cached_cutter != null and is_instance_valid(_cached_cutter):
		return _cached_cutter
	if has_node(cutter_path):
		_cached_cutter = get_node(cutter_path) as CharacterBody3D
		if _cached_cutter != null:
			return _cached_cutter
	var tree: SceneTree = get_tree()
	if tree != null:
		_cached_cutter = tree.get_first_node_in_group("cutter") as CharacterBody3D
		if _cached_cutter == null and tree.current_scene != null:
			_cached_cutter = tree.current_scene.find_child("Cutter", true, false) as CharacterBody3D
	return _cached_cutter


func _on_coin_popup_requested(world_pos: Vector3, amount: int, plant_type: String) -> void:
	if _pool.is_empty():
		return

	# Garante que NUNCA spawna solto no chão ou no centro da fase:
	# O spawn ocorre estritamente ancorado às coordenadas relativas ao lado do corpo do robô.
	var cutter: CharacterBody3D = _get_cutter()
	if cutter == null or not is_instance_valid(cutter):
		return

	var spawn_pos: Vector3
	if cutter.has_method("get_inner_blade_point"):
		spawn_pos = cutter.get_inner_blade_point(world_pos)
	else:
		spawn_pos = cutter.global_position + Vector3(0.0, 0.45, 0.0)

	var idx: int = _next_index
	_next_index = (_next_index + 1) % POOL_SIZE

	var label: Label3D = _pool[idx]
	if _tweens[idx] != null and _tweens[idx].is_valid():
		_tweens[idx].kill()

	var base_color: Color = COLOR_GRASS
	match plant_type:
		"wheat":
			base_color = COLOR_WHEAT
		"flower":
			base_color = COLOR_FLOWER
		_:
			base_color = COLOR_GRASS

	label.text = "+" + str(amount)
	label.modulate = Color(base_color.r, base_color.g, base_color.b, 0.0)
	label.scale = Vector3(0.35, 0.35, 0.35)
	# Posiciona o label na coordenada do robô ANTES de torná-lo visível para evitar qualquer flash
	label.global_position = spawn_pos
	label.visible = true

	var tween: Tween = create_tween()
	_tweens[idx] = tween

	# 1. Aparecer em fase (Fade-in rápido: 0.0 -> 1.0 em 0.08s)
	tween.tween_property(label, "modulate:a", 1.0, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Crescer depois diminuir (Pop elástico: 0.35 -> 1.30 em 0.10s, depois 1.30 -> 1.0 em 0.08s)
	tween.parallel().tween_property(label, "scale", Vector3(1.30, 1.30, 1.30), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "scale", Vector3(1.0, 1.0, 1.0), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# 3. Subir verticalmente (+0.70m durante 0.60s)
	var target_y: float = spawn_pos.y + 0.70
	tween.parallel().tween_property(label, "global_position:y", target_y, 0.60).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 4. Desaparecer em fase (Fade-out transparente: sustentação inicial e fade 1.0 -> 0.0 em 0.28s)
	tween.chain().tween_interval(0.14)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 5. Oculta ao finalizar
	tween.tween_callback(func() -> void:
		label.visible = false
	)
