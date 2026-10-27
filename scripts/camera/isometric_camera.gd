extends Camera3D

@export var target_path: NodePath
@export var base_canonical_offset: Vector3 = Vector3(0.0, 7.7511, 9.1619) # 100% canônico (12.0m no Lv 6 MAX)
@export var follow_speed: float = 8.0

const MIN_DISTANCE_RATIO: float = 0.50 # 50% de distância no Lv 1 (6.0m)
const MAX_DISTANCE_RATIO: float = 1.00 # 100% de distância no Lv 6 MAX (12.0m)
const ZOOM_TWEEN_DURATION: float = 0.75

const VICTORY_OFFSET: Vector3 = Vector3(0.0, 1.25, 4.0)
const VICTORY_ROTATION: Vector3 = Vector3(-8.0, 0.0, 0.0)

var target: Node3D
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

var _in_victory_cam: bool = false
var _current_gameplay_offset: Vector3 = Vector3(0.0, 3.8756, 4.5809)
var _victory_offset: Vector3 = Vector3(0.0, 1.25, 4.0)
var _current_rotation: Vector3 = Vector3.ZERO
var _victory_tween: Tween = null
var _zoom_tween: Tween = null

# Alias para compatibilidade reversa com inspeção externa
var offset: Vector3:
	get:
		return _current_gameplay_offset
	set(v):
		base_canonical_offset = v
		_current_gameplay_offset = v

func _ready() -> void:
	if has_node(target_path):
		target = get_node(target_path) as Node3D

	var init_lvl: int = 1
	if UpgradeManager != null:
		init_lvl = UpgradeManager.blade_level
		UpgradeManager.blade_level_changed.connect(_on_blade_level_changed)

	_apply_blade_level_zoom(init_lvl, false)

	if GameManager != null:
		GameManager.camera_shake_requested.connect(_on_shake_requested)
		GameManager.level_won.connect(_on_level_won)
		GameManager.state_changed.connect(_on_state_changed)

	# Configura e trava a orientacao isometrica inicial
	if target:
		global_position = target.global_position + _current_gameplay_offset
		look_at_from_position(global_position, target.global_position, Vector3.UP)
	else:
		look_at_from_position(global_position, global_position - _current_gameplay_offset, Vector3.UP)
	_current_rotation = rotation_degrees

func get_target_offset_for_level(lvl: int) -> Vector3:
	var t: float = clampf(float(lvl - 1) / 5.0, 0.0, 1.0)
	var ratio: float = lerpf(MIN_DISTANCE_RATIO, MAX_DISTANCE_RATIO, t)
	return base_canonical_offset * ratio

func _apply_blade_level_zoom(lvl: int, animate: bool = true) -> void:
	var target_off: Vector3 = get_target_offset_for_level(lvl)
	if not animate:
		if _zoom_tween != null and _zoom_tween.is_valid():
			_zoom_tween.kill()
		_current_gameplay_offset = target_off
		return

	if _in_victory_cam:
		_current_gameplay_offset = target_off
		return

	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()

	_zoom_tween = create_tween()
	_zoom_tween.tween_property(self, "_current_gameplay_offset", target_off, ZOOM_TWEEN_DURATION).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _on_blade_level_changed(new_level: int, _is_max: bool) -> void:
	_apply_blade_level_zoom(new_level, true)

func _on_state_changed(new_state: int) -> void:
	if new_state == GameManager.GameState.PLAYING:
		reset_cam()

func _on_level_won(_coins: int, _stars: int) -> void:
	transition_to_victory_cam()

func transition_to_victory_cam() -> void:
	if _in_victory_cam or target == null:
		return
	_in_victory_cam = true
	
	if _victory_tween != null and _victory_tween.is_valid():
		_victory_tween.kill()
	if _zoom_tween != null and _zoom_tween.is_valid():
		_zoom_tween.kill()

	_victory_offset = global_position - target.global_position
	_current_rotation = rotation_degrees

	_victory_tween = create_tween().set_parallel(true)
	# Transiciona com suavidade cubica para o enquadramento e angulacao exatos da tela Home
	_victory_tween.tween_property(self, "_victory_offset", VICTORY_OFFSET, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_victory_tween.tween_property(self, "_current_rotation", VICTORY_ROTATION, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func reset_cam() -> void:
	_in_victory_cam = false
	if _victory_tween != null and _victory_tween.is_valid():
		_victory_tween.kill()
	var lvl: int = UpgradeManager.blade_level if UpgradeManager != null else 1
	_apply_blade_level_zoom(lvl, false)
	if target:
		look_at_from_position(target.global_position + _current_gameplay_offset, target.global_position, Vector3.UP)
	else:
		look_at_from_position(global_position, global_position - _current_gameplay_offset, Vector3.UP)
	_current_rotation = rotation_degrees

func _on_shake_requested(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _physics_process(delta: float) -> void:
	if not target:
		return

	if _in_victory_cam:
		# Enquadramento heroico identico a visao do bot na tela Home (offset 0, 1.25, 4.0 e pitch -8 deg)
		global_position = target.global_position + _victory_offset
		rotation_degrees = _current_rotation
		return

	# Translada suavemente em sincronia com o physics_process do cortador para eliminar micro-travamentos
	var follow_factor: float = clampf(follow_speed * delta, 0.0, 1.0)
	var desired_x: float = target.global_position.x + _current_gameplay_offset.x
	var desired_z: float = target.global_position.z + _current_gameplay_offset.z
	var desired_y: float = target.global_position.y + _current_gameplay_offset.y

	var new_x: float = lerpf(global_position.x, desired_x, follow_factor)
	var new_z: float = lerpf(global_position.z, desired_z, follow_factor)
	var new_y: float = lerpf(global_position.y, desired_y, follow_factor)

	# Aplica camera shake apenas como perturbacao de translacao
	var shake_x: float = 0.0
	var shake_z: float = 0.0
	if shake_duration > 0.0:
		shake_duration -= delta
		shake_x = randf_range(-shake_intensity, shake_intensity)
		shake_z = randf_range(-shake_intensity, shake_intensity)
		if shake_duration <= 0.0:
			shake_intensity = 0.0

	global_position = Vector3(new_x + shake_x, new_y, new_z + shake_z)
