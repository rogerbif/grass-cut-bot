extends Camera3D

signal view_mode_changed(is_map_view: bool)

enum CameraMode { BOT_VIEW, MAP_VIEW }

@export var bot_offset: Vector3 = Vector3(0, 1.15, 3.8)
@export var bot_pitch_deg: float = -6.0

@export var map_height: float = 16.5
@export var map_z_offset: float = 9.8
@export var map_pitch_deg: float = -58.0

@export var scroll_sensitivity: float = 0.024
@export var scroll_damping: float = 10.0

var current_mode: CameraMode = CameraMode.BOT_VIEW
var target_bot_pos: Vector3 = Vector3.ZERO

# Limites do mapa
var min_z: float = 0.0
var max_z: float = 20.0
var target_scroll_z: float = 0.0
var current_scroll_z: float = 0.0

var is_dragging: bool = false
var last_touch_y: float = 0.0
var drag_velocity: float = 0.0
var is_transitioning: bool = false
var active_tween: Tween = null

func _ready() -> void:
	current_scroll_z = target_bot_pos.z
	target_scroll_z = current_scroll_z
	_apply_bot_view_instant()

func _process(delta: float) -> void:
	if is_transitioning:
		return

	if current_mode == CameraMode.MAP_VIEW:
		# Aplica inércia de arraste
		if not is_dragging and abs(drag_velocity) > 0.01:
			target_scroll_z += drag_velocity * delta
			drag_velocity = lerp(drag_velocity, 0.0, delta * 6.0)

		# Clamp estrito nos limites das fases e nuvens
		target_scroll_z = clampf(target_scroll_z, min_z, max_z)
		current_scroll_z = lerp(current_scroll_z, target_scroll_z, delta * scroll_damping)

		global_position = Vector3(0, map_height, current_scroll_z + map_z_offset)
		rotation_degrees = Vector3(map_pitch_deg, 0, 0)

func _input(event: InputEvent) -> void:
	if current_mode != CameraMode.MAP_VIEW or is_transitioning:
		return

	# Suporte a toque touchscreen / mouse drag
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_dragging = true
				last_touch_y = mb.position.y
				drag_velocity = 0.0
			else:
				is_dragging = false
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_scroll_z += 1.8
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_scroll_z -= 1.8

	elif event is InputEventMouseMotion and is_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var delta_y: float = mm.position.y - last_touch_y
		last_touch_y = mm.position.y
		var movement: float = -delta_y * scroll_sensitivity * 1.5
		target_scroll_z += movement
		drag_velocity = movement * 30.0

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		var movement: float = -sd.relative.y * scroll_sensitivity * 1.5
		target_scroll_z += movement
		drag_velocity = movement * 30.0

func set_bot_target(bot_pos: Vector3) -> void:
	target_bot_pos = bot_pos
	if current_mode == CameraMode.BOT_VIEW and not is_transitioning:
		_apply_bot_view_instant()

func set_scroll_bounds(z_start: float, z_end: float) -> void:
	min_z = minf(z_start, z_end) - 1.5
	max_z = maxf(z_start, z_end) + 1.5

func toggle_mode() -> void:
	if current_mode == CameraMode.BOT_VIEW:
		switch_to_map_view()
	else:
		switch_to_bot_view()

func switch_to_map_view() -> void:
	if current_mode == CameraMode.MAP_VIEW or is_transitioning:
		return
	current_mode = CameraMode.MAP_VIEW
	is_transitioning = true

	target_scroll_z = target_bot_pos.z
	current_scroll_z = target_scroll_z
	var dest_pos: Vector3 = Vector3(0, map_height, current_scroll_z + map_z_offset)
	var dest_rot: Vector3 = Vector3(map_pitch_deg, 0, 0)

	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(self, "global_position", dest_pos, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "rotation_degrees", dest_rot, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.chain().tween_callback(_on_transition_finished)

	view_mode_changed.emit(true)

func switch_to_bot_view() -> void:
	if current_mode == CameraMode.BOT_VIEW or is_transitioning:
		return
	current_mode = CameraMode.BOT_VIEW
	is_transitioning = true

	var dest_pos: Vector3 = target_bot_pos + bot_offset
	var dest_rot: Vector3 = Vector3(bot_pitch_deg, 0, 0)

	if active_tween != null and active_tween.is_valid():
		active_tween.kill()

	active_tween = create_tween()
	active_tween.set_parallel(true)
	active_tween.tween_property(self, "global_position", dest_pos, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "rotation_degrees", dest_rot, 0.65).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	active_tween.chain().tween_callback(_on_transition_finished)

	view_mode_changed.emit(false)

func _on_transition_finished() -> void:
	is_transitioning = false

func _apply_bot_view_instant() -> void:
	global_position = target_bot_pos + bot_offset
	rotation_degrees = Vector3(bot_pitch_deg, 0, 0)
