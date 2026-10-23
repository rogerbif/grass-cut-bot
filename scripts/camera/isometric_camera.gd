extends Camera3D

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0.0, 7.2, 8.5)
@export var follow_speed: float = 8.0

var target: Node3D
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

var _in_victory_cam: bool = false
var _current_offset: Vector3 = Vector3(0.0, 7.2, 8.5)
var _victory_tween: Tween = null

func _ready() -> void:
	_current_offset = offset
	if has_node(target_path):
		target = get_node(target_path) as Node3D

	if GameManager != null:
		GameManager.camera_shake_requested.connect(_on_shake_requested)
		GameManager.level_won.connect(_on_level_won)
		GameManager.state_changed.connect(_on_state_changed)

	# Configura e trava a orientacao isometrica inicial
	if target:
		global_position = target.global_position + offset
		look_at_from_position(global_position, target.global_position, Vector3.UP)
	else:
		look_at_from_position(global_position, global_position - offset, Vector3.UP)

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

	_victory_tween = create_tween().set_parallel(true)
	# Sobe um pouco a câmera e afasta suavemente para enquadramento heroico perfeito
	var target_victory_offset: Vector3 = Vector3(0.0, 1.85, 2.85)
	_victory_tween.tween_property(self, "_current_offset", target_victory_offset, 0.85).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func reset_cam() -> void:
	_in_victory_cam = false
	if _victory_tween != null and _victory_tween.is_valid():
		_victory_tween.kill()
	_current_offset = offset
	if target:
		look_at_from_position(target.global_position + offset, target.global_position, Vector3.UP)

func _on_shake_requested(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _physics_process(delta: float) -> void:
	if not target:
		return

	if _in_victory_cam:
		# Enquadramento suave em close frontal no herói
		var look_target: Vector3 = target.global_position + Vector3(0.0, 0.42, 0.0)
		var desired_pos: Vector3 = target.global_position + _current_offset
		global_position = global_position.lerp(desired_pos, clampf(follow_speed * delta * 2.0, 0.0, 1.0))
		look_at(look_target, Vector3.UP)
		return

	# Translada suavemente em sincronia com o physics_process do cortador para eliminar micro-travamentos
	var follow_factor: float = clampf(follow_speed * delta, 0.0, 1.0)
	var desired_x: float = target.global_position.x + offset.x
	var desired_z: float = target.global_position.z + offset.z
	var desired_y: float = target.global_position.y + offset.y

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
