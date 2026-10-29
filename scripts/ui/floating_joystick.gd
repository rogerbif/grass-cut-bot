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
var _is_mobile: bool = false

func _ready() -> void:
	_is_mobile = OS.has_feature("mobile")
	# Cobrir a área inferior da tela
	anchor_left = 0.0
	anchor_top = 0.4
	anchor_right = 1.0
	anchor_bottom = 1.0
	mouse_filter = Control.MOUSE_FILTER_STOP
	if GameManager != null:
		GameManager.state_changed.connect(_on_game_state_changed)
	queue_redraw()

func _on_game_state_changed(new_state: int) -> void:
	if new_state != GameManager.GameState.PLAYING:
		_reset_joystick()
		visible = false
	else:
		visible = true

func _input(event: InputEvent) -> void:
	# Ignora completamente entradas quando a fase terminou ou está em modal
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
		if is_active:
			_reset_joystick()
		return

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
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
		if output_vector != Vector2.ZERO:
			output_vector = Vector2.ZERO
			joystick_moved.emit(Vector2.ZERO)
		return

	# Se o joystick virtual de toque/mouse estiver ativo, ele tem prioridade
	if is_active:
		return

	# 1. Leitura de Gamepad / Joystick físico (Analógico esquerdo)
	var joy_x: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_X)
	var joy_y: float = Input.get_joy_axis(0, JOY_AXIS_LEFT_Y)
	var joy_vec: Vector2 = Vector2(joy_x, joy_y)

	# 2. Leitura de D-Pad físico (caso o analógico esteja na zona morta)
	if joy_vec.length_squared() < 0.04:
		var dpad_vec: Vector2 = Vector2.ZERO
		if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_RIGHT):
			dpad_vec.x += 1.0
		if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_LEFT):
			dpad_vec.x -= 1.0
		if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_DOWN):
			dpad_vec.y += 1.0
		if Input.is_joy_button_pressed(0, JOY_BUTTON_DPAD_UP):
			dpad_vec.y -= 1.0
		if dpad_vec != Vector2.ZERO:
			joy_vec = dpad_vec.normalized()

	# Aplica deadzone de 0.15 no gamepad físico
	const JOY_DEADZONE: float = 0.15
	var joy_len: float = joy_vec.length()
	if joy_len > JOY_DEADZONE:
		var norm_mag: float = clampf((joy_len - JOY_DEADZONE) / (1.0 - JOY_DEADZONE), 0.0, 1.0)
		output_vector = joy_vec.normalized() * norm_mag
		joystick_moved.emit(output_vector)
		return

	# 3. Fallback para teclado (WASD / Setas) fora do mobile
	if not _is_mobile:
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
			return

	# 4. Sem entrada ativa: reseta para repouso se havia vetor anterior
	if output_vector != Vector2.ZERO:
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
