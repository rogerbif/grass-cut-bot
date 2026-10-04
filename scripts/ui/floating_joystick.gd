extends Control

signal joystick_moved(direction: Vector2)

@export var max_radius: float = 75.0
@export var dead_zone: float = 12.0
@export var base_color: Color = Color(1.0, 1.0, 1.0, 0.25)
@export var stick_color: Color = Color(1.0, 1.0, 1.0, 0.65)
@export var base_radius: float = 65.0
@export var stick_radius: float = 28.0

var is_active: bool = false
var touch_origin: Vector2 = Vector2.ZERO
var stick_position: Vector2 = Vector2.ZERO
var output_vector: Vector2 = Vector2.ZERO
var touch_pointer_id: int = -1

func _ready() -> void:
	# Cobrir a área inferior da tela
	anchor_left = 0.0
	anchor_top = 0.4
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	queue_redraw()

func _input(event: InputEvent) -> void:
	# Suporte a toque e mouse
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)
	elif event is InputEventMouseButton:
		_handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		_handle_mouse_motion(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	if event.pressed:
		var local_pos = get_global_transform().affine_inverse() * event.position
		if get_rect().has_point(event.position) and not is_active:
			touch_pointer_id = event.index
			is_active = true
			touch_origin = local_pos
			stick_position = local_pos
			output_vector = Vector2.ZERO
			queue_redraw()
	elif event.index == touch_pointer_id:
		_reset_joystick()

func _handle_drag(event: InputEventScreenDrag) -> void:
	if is_active and event.index == touch_pointer_id:
		var local_pos = get_global_transform().affine_inverse() * event.position
		_update_stick_position(local_pos)

func _handle_mouse_button(event: InputEventMouseButton) -> void:
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var local_pos = get_global_transform().affine_inverse() * event.position
			if get_rect().has_point(event.position) and not is_active:
				is_active = true
				touch_pointer_id = 999
				touch_origin = local_pos
				stick_position = local_pos
				output_vector = Vector2.ZERO
				queue_redraw()
		elif touch_pointer_id == 999:
			_reset_joystick()

func _handle_mouse_motion(event: InputEventMouseMotion) -> void:
	if is_active and touch_pointer_id == 999:
		var local_pos = get_global_transform().affine_inverse() * event.position
		_update_stick_position(local_pos)

func _update_stick_position(current_pos: Vector2) -> void:
	var delta_vec: Vector2 = current_pos - touch_origin
	var dist: float = delta_vec.length()

	if dist > max_radius:
		stick_position = touch_origin + delta_vec.normalized() * max_radius
	else:
		stick_position = current_pos

	if dist < dead_zone:
		output_vector = Vector2.ZERO
	else:
		var normalized_magnitude: float = clampf((dist - dead_zone) / (max_radius - dead_zone), 0.0, 1.0)
		output_vector = delta_vec.normalized() * normalized_magnitude

	joystick_moved.emit(output_vector)
	queue_redraw()

func _reset_joystick() -> void:
	is_active = false
	touch_pointer_id = -1
	output_vector = Vector2.ZERO
	joystick_moved.emit(Vector2.ZERO)
	queue_redraw()

func _process(_delta: float) -> void:
	# Fallback para teclado (WASD / Setas) se o joystick não estiver ativo
	if not is_active:
		var keyboard_dir: Vector2 = Vector2.ZERO
		if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
			keyboard_dir.x += 1.0
		if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
			keyboard_dir.x -= 1.0
		if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
			keyboard_dir.y += 1.0
		if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
			keyboard_dir.y -= 1.0

		if keyboard_dir != Vector2.ZERO:
			output_vector = keyboard_dir.normalized()
			joystick_moved.emit(output_vector)
		elif output_vector != Vector2.ZERO:
			output_vector = Vector2.ZERO
			joystick_moved.emit(Vector2.ZERO)

func _draw() -> void:
	if is_active:
		# Desenha base circular com anel externo
		draw_circle(touch_origin, base_radius, base_color)
		draw_arc(touch_origin, base_radius, 0, TAU, 32, Color(1, 1, 1, 0.4), 2.5, true)
		# Desenha thumb/stick circular com destaque central
		draw_circle(stick_position, stick_radius, stick_color)
		draw_arc(stick_position, stick_radius, 0, TAU, 24, Color(1, 1, 1, 0.8), 2.0, true)
