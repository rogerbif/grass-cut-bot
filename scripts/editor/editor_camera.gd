extends Camera3D

@export var pan_speed: float = 12.0
@export var drag_pan_sensitivity: float = 0.018
@export var zoom_step: float = 1.4
@export var min_distance: float = 5.5
@export var max_distance: float = 28.0

var focus_point: Vector3 = Vector3.ZERO
var target_distance: float = 14.5
var current_distance: float = 14.5
var is_top_down: bool = false
var is_panning_mouse: bool = false
var movement_enabled: bool = true
var follow_target: Node3D = null

var _saved_focus: Vector3 = Vector3.ZERO
var _saved_distance: float = 14.5

func _ready() -> void:
	# Como a câmera do editor é controlada suavemente via _process (render frame)
	# e por inputs de mouse/pan, desativa a interpolação física para evitar o aviso
	# de Camera3D interpolada disparada fora de physics_process.
	physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fov = 46.0
	_update_camera_transform(1.0)

func save_editor_view() -> void:
	_saved_focus = focus_point
	_saved_distance = target_distance

func restore_editor_view() -> void:
	follow_target = null
	focus_point = _saved_focus
	target_distance = _saved_distance
	current_distance = _saved_distance
	_update_camera_transform(1.0)

func toggle_top_down() -> bool:
	is_top_down = not is_top_down
	_update_camera_transform(1.0)
	return is_top_down

func center_on_origin() -> void:
	focus_point = Vector3.ZERO
	target_distance = 14.5

func handle_camera_input(event: InputEvent, ui_has_focus: bool, mouse_over_ui: bool) -> bool:
	if not movement_enabled or follow_target != null:
		is_panning_mouse = false
		return false

	# Ignora eventos sintéticos de touch gerados por emulate_touch_from_mouse
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		return false

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed and not mouse_over_ui:
				is_panning_mouse = true
				return mb.button_index == MOUSE_BUTTON_MIDDLE
			elif not mb.pressed:
				is_panning_mouse = false
		elif not mouse_over_ui and not ui_has_focus and not Input.is_key_pressed(KEY_ALT):
			if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
				target_distance = clampf(target_distance - zoom_step, min_distance, max_distance)
				return true
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
				target_distance = clampf(target_distance + zoom_step, min_distance, max_distance)
				return true

	elif event is InputEventMouseMotion and is_panning_mouse:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var scale_factor: float = current_distance * 0.0014
		focus_point.x -= mm.relative.x * scale_factor * 60.0 * drag_pan_sensitivity
		focus_point.z -= mm.relative.y * scale_factor * 60.0 * drag_pan_sensitivity
		focus_point.x = clampf(focus_point.x, -25.0, 25.0)
		focus_point.z = clampf(focus_point.z, -25.0, 25.0)
		return true

	return false

func _process(delta: float) -> void:
	if follow_target != null and is_instance_valid(follow_target):
		projection = Camera3D.PROJECTION_PERSPECTIVE
		fov = 46.0
		var play_offset: Vector3 = Vector3(0.0, 7.2, 8.5)
		var desired_pos: Vector3 = follow_target.global_position + play_offset
		global_position = global_position.lerp(desired_pos, clampf(8.0 * delta, 0.0, 1.0))
		look_at_from_position(global_position, follow_target.global_position, Vector3.UP)
		return

	if movement_enabled:
		var focus_owner: Control = get_viewport().gui_get_focus_owner()
		var typing_in_ui: bool = (focus_owner is LineEdit) or (focus_owner is SpinBox)
		if not typing_in_ui and not Input.is_key_pressed(KEY_CTRL):
			var move_vec: Vector2 = Vector2.ZERO
			if Input.is_key_pressed(KEY_UP):
				move_vec.y -= 1.0
			if Input.is_key_pressed(KEY_DOWN):
				move_vec.y += 1.0
			if Input.is_key_pressed(KEY_LEFT):
				move_vec.x -= 1.0
			if Input.is_key_pressed(KEY_RIGHT):
				move_vec.x += 1.0

			if move_vec.length_squared() > 0.001:
				move_vec = move_vec.normalized()
				var zoom_ratio: float = current_distance / 14.0
				focus_point.x += move_vec.x * pan_speed * zoom_ratio * delta
				focus_point.z += move_vec.y * pan_speed * zoom_ratio * delta
				focus_point.x = clampf(focus_point.x, -25.0, 25.0)
				focus_point.z = clampf(focus_point.z, -25.0, 25.0)

	_update_camera_transform(delta)

func _update_camera_transform(delta: float) -> void:
	current_distance = lerpf(current_distance, target_distance, clampf(12.0 * delta, 0.0, 1.0))
	if is_top_down:
		projection = Camera3D.PROJECTION_ORTHOGONAL
		size = current_distance * 0.85
		var cam_pos: Vector3 = focus_point + Vector3(0.0, 35.0, 0.0)
		transform = Transform3D(Basis.looking_at(Vector3.DOWN, Vector3.FORWARD), cam_pos)
	else:
		projection = Camera3D.PROJECTION_PERSPECTIVE
		fov = 46.0
		var pitch_rad: float = deg_to_rad(42.0)
		var offset_y: float = sin(pitch_rad) * current_distance
		var offset_z: float = cos(pitch_rad) * current_distance
		var cam_pos: Vector3 = focus_point + Vector3(0.0, offset_y, offset_z)
		look_at_from_position(cam_pos, focus_point, Vector3.UP)
