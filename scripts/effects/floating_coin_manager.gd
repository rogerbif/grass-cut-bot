class_name FloatingCoinManager
extends Node3D

## Gerencia o pool de números flutuantes cartoon 3D (+1, +3, +5).
## Ancorado diretamente ao espaço local do cortador com physics_interpolation desativado
## para impedir qualquer flash fantasma no centro da fase ou rastro escuro distante.

const POOL_SIZE: int = 64
const MAX_LOCAL_RADIUS_XZ: float = 0.48

const COLOR_GRASS: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_WHEAT: Color = Color(1.0, 0.90, 0.20, 1.0)
const COLOR_FLOWER: Color = Color(1.0, 0.40, 0.85, 1.0)

@export var cutter_path: NodePath = NodePath("../LevelController/Cutter")

var _pool: Array[Label3D] = []
var _tweens: Array[Tween] = []
var _next_index: int = 0
var _cached_cutter: CharacterBody3D = null


func _ready() -> void:
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	_init_pool()
	_sync_to_cutter()
	if GameManager:
		GameManager.coin_popup_requested.connect(_on_coin_popup_requested)


func _process(_delta: float) -> void:
	_sync_to_cutter()


func _physics_process(_delta: float) -> void:
	_sync_to_cutter()


func _sync_to_cutter() -> CharacterBody3D:
	var cutter: CharacterBody3D = _get_cutter()
	if cutter != null and is_instance_valid(cutter):
		global_position = cutter.global_position
		reset_physics_interpolation()
	return cutter


func _init_pool() -> void:
	_pool.clear()
	_tweens.clear()
	for i in range(POOL_SIZE):
		var label: Label3D = Label3D.new()
		label.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		label.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.no_depth_test = true
		label.render_priority = 25
		label.font_size = 56
		label.pixel_size = 0.005
		label.outline_size = 14
		label.modulate = Color(1.0, 1.0, 1.0, 0.0)
		label.outline_modulate = Color(0.0, 0.0, 0.0, 0.0)
		label.shaded = false
		label.double_sided = true
		label.position = Vector3(0.0, 0.45, 0.0)
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

	# Sincroniza imediatamente a origem do manager com o chassi do robô
	var cutter: CharacterBody3D = _sync_to_cutter()
	if cutter == null or not is_instance_valid(cutter):
		return

	var local_offset: Vector3
	if cutter.has_method("get_body_side_local_offset"):
		local_offset = cutter.get_body_side_local_offset(world_pos)
	elif cutter.has_method("get_inner_blade_point"):
		local_offset = cutter.get_inner_blade_point(world_pos) - cutter.global_position
	else:
		local_offset = Vector3(0.0, 0.45, 0.44)

	# Trava matemática de segurança: jamais permite offset horizontal maior que MAX_LOCAL_RADIUS_XZ
	var horiz: Vector2 = Vector2(local_offset.x, local_offset.z)
	if horiz.length() > MAX_LOCAL_RADIUS_XZ:
		horiz = horiz.normalized() * MAX_LOCAL_RADIUS_XZ
		local_offset.x = horiz.x
		local_offset.z = horiz.y

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
	label.outline_modulate = Color(0.0, 0.0, 0.0, 0.0)
	label.scale = Vector3(0.35, 0.35, 0.35)
	label.position = local_offset
	label.reset_physics_interpolation()
	label.visible = true

	var tween: Tween = create_tween().set_parallel(true)
	_tweens[idx] = tween

	# 1. Subida vertical contínua em espaço local (+0.42m durante toda a vida útil de 0.26s)
	var target_local_y: float = local_offset.y + 0.42
	tween.tween_property(label, "position:y", target_local_y, 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 2. Fade-in simultâneo do preenchimento e do contorno preto (0.0 -> 1.0 em 0.03s)
	tween.tween_property(label, "modulate:a", 1.0, 0.03).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "outline_modulate:a", 1.0, 0.03).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 3. Pop elástico de escala (0.35 -> 1.25 em 0.05s, depois 1.25 -> 1.0 em 0.04s)
	tween.tween_property(label, "scale", Vector3(1.25, 1.25, 1.25), 0.05).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(label, "scale", Vector3(1.0, 1.0, 1.0), 0.04).set_delay(0.05).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# 4. Fade-out simultâneo do preenchimento E do contorno preto (inicia em 0.16s, dura 0.10s)
	tween.tween_property(label, "modulate:a", 0.0, 0.10).set_delay(0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(label, "outline_modulate:a", 0.0, 0.10).set_delay(0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# 5. Oculta e reseta ao finalizar em 0.26s
	tween.tween_callback(func() -> void:
		label.visible = false
		label.modulate.a = 0.0
		label.outline_modulate.a = 0.0
		label.position = Vector3(0.0, 0.45, 0.0)
	).set_delay(0.26)
