class_name FloatingCoinManager
extends Node3D

## Gerencia o pool de números flutuantes cartoon 3D (+1, +3, +5).
## Estilo cel-shaded cartoon com contorno preto grosso e rastro dinâmico.

const POOL_SIZE: int = 32

const COLOR_GRASS: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_WHEAT: Color = Color(1.0, 0.90, 0.20, 1.0)
const COLOR_FLOWER: Color = Color(1.0, 0.40, 0.85, 1.0)

var _pool: Array[Label3D] = []
var _tweens: Array[Tween] = []
var _next_index: int = 0


func _ready() -> void:
	_init_pool()
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


func _on_coin_popup_requested(world_pos: Vector3, amount: int, plant_type: String) -> void:
	if _pool.is_empty():
		return

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
	label.modulate = base_color
	label.visible = true

	# Posição inicial com leve variação horizontal para efeito orgânico de rastro
	var jitter_x: float = randf_range(-0.06, 0.06)
	var jitter_z: float = randf_range(-0.06, 0.06)
	label.global_position = world_pos + Vector3(jitter_x, 0.30, jitter_z)
	label.scale = Vector3(0.5, 0.5, 0.5)

	var tween: Tween = create_tween()
	_tweens[idx] = tween

	# 1. Pop elástico de escala (0.5 -> 1.25 -> 1.0)
	tween.tween_property(label, "scale", Vector3(1.25, 1.25, 1.25), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector3(1.0, 1.0, 1.0), 0.06).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# 2. Subida vertical constante de +0.72m durante 0.65s (em paralelo)
	var target_y: float = label.global_position.y + 0.72
	tween.parallel().tween_property(label, "global_position:y", target_y, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Fade out transparente mantendo opaco no início do rastro (em paralelo)
	tween.parallel().tween_property(label, "modulate:a", 1.0, 0.35)
	tween.tween_property(label, "modulate:a", 0.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 4. Oculta ao finalizar
	tween.tween_callback(func() -> void:
		label.visible = false
	)
