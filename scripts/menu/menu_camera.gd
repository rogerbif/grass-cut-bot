extends Camera3D

signal view_mode_changed(is_map_view: bool)
signal island_snapped(level_number: int)

enum CameraMode { BOT_VIEW, MAP_VIEW }

@export var bot_offset: Vector3 = Vector3(0, 1.15, 3.8)
@export var bot_pitch_deg: float = -6.0

@export var map_height: float = 16.5
@export var map_z_offset: float = 9.8
@export var map_pitch_deg: float = -58.0

@export var z_spacing: float = 7.2
@export var total_levels: int = 20
@export var swipe_velocity_threshold: float = 6.0

var current_mode: CameraMode = CameraMode.BOT_VIEW
var target_bot_pos: Vector3 = Vector3.ZERO
var island_waypoints: Array[Vector3] = []

# Limites do mapa
var min_z: float = -144.0 # Fim das nuvens
var max_z: float = 0.0    # Fase 1
var target_scroll_z: float = 0.0
var current_scroll_z: float = 0.0
var current_snapped_level: int = 1

var is_dragging: bool = false
var last_touch_pos: Vector2 = Vector2.ZERO
var last_touch_time: float = 0.0
var flick_velocity: float = 0.0
var is_transitioning: bool = false
var active_tween: Tween = null
var snap_tween: Tween = null

func _ready() -> void:
	current_scroll_z = target_bot_pos.z
	target_scroll_z = current_scroll_z
	_apply_bot_view_instant()

func _process(delta: float) -> void:
	if is_transitioning:
		return

	if current_mode == CameraMode.MAP_VIEW:
		if is_dragging:
			# Enquanto arrasta com o dedo, acompanha diretamente sem inércia artificial
			current_scroll_z = clampf(target_scroll_z, min_z - 1.5, max_z + 1.5)
		else:
			# Decaimento suave da velocidade
			flick_velocity = lerp(flick_velocity, 0.0, delta * 8.0)

		# Centraliza a câmera no X da ilha que estiver na reta
		var cam_x: float = get_camera_x_at_z(current_scroll_z)
		global_position = Vector3(cam_x, map_height, current_scroll_z + map_z_offset)
		rotation_degrees = Vector3(map_pitch_deg, 0, 0)

func set_island_positions(positions: Array[Vector3]) -> void:
	island_waypoints = positions.duplicate()

func get_camera_x_at_z(scroll_z: float) -> float:
	if island_waypoints.is_empty():
		return 0.0

	# Se estiver antes da primeira ilha
	if scroll_z >= island_waypoints[0].z:
		return island_waypoints[0].x

	# Se estiver depois da última
	var last_idx: int = island_waypoints.size() - 1
	if scroll_z <= island_waypoints[last_idx].z:
		return island_waypoints[last_idx].x

	# Encontra os dois waypoints vizinhos
	for i in range(last_idx):
		var p_curr: Vector3 = island_waypoints[i]
		var p_next: Vector3 = island_waypoints[i + 1]
		# Z é estritamente decrescente
		if scroll_z <= p_curr.z and scroll_z >= p_next.z:
			var seg_len: float = p_curr.z - p_next.z
			if seg_len < 0.001:
				return p_curr.x
			var t: float = (p_curr.z - scroll_z) / seg_len
			# Curva cúbica suave (Hermite / Smoothstep) para serpenteamento elegante
			var s: float = t * t * (3.0 - 2.0 * t)
			return lerpf(p_curr.x, p_next.x, s)

	return 0.0

func get_ground_z(screen_pos: Vector2) -> float:
	var ray_from: Vector3 = project_ray_origin(screen_pos)
	var ray_dir: Vector3 = project_ray_normal(screen_pos)
	if abs(ray_dir.y) < 0.0001:
		return 0.0
	var t: float = -ray_from.y / ray_dir.y
	return ray_from.z + ray_dir.z * t

func get_pixel_to_ground_ratio() -> float:
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var center: Vector2 = vp_size / 2.0
	var z1: float = get_ground_z(center - Vector2(0, 50))
	var z2: float = get_ground_z(center + Vector2(0, 50))
	var ratio: float = abs(z2 - z1) / 100.0
	if ratio < 0.001 or ratio > 1.0:
		return 0.016 # Fallback seguro
	return ratio

func _input(event: InputEvent) -> void:
	if current_mode != CameraMode.MAP_VIEW or is_transitioning:
		return

	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_start_drag(mb.position)
			else:
				_end_drag()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			snap_to_level(current_snapped_level - 1)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			snap_to_level(current_snapped_level + 1)

	elif event is InputEventMouseMotion and is_dragging:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_process_drag(mm.position)

	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			_start_drag(st.position)
		else:
			_end_drag()

	elif event is InputEventScreenDrag and is_dragging:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		_process_drag(sd.position)

func _start_drag(screen_pos: Vector2) -> void:
	is_dragging = true
	last_touch_pos = screen_pos
	last_touch_time = Time.get_ticks_msec() / 1000.0
	flick_velocity = 0.0
	if snap_tween != null and snap_tween.is_valid():
		snap_tween.kill()

func _process_drag(current_screen_pos: Vector2) -> void:
	var now: float = Time.get_ticks_msec() / 1000.0
	var dt: float = maxf(0.001, now - last_touch_time)
	var delta_y: float = current_screen_pos.y - last_touch_pos.y

	# Cálculo de tracking 1:1 rigoroso com o dedo no plano do solo
	var ratio: float = get_pixel_to_ground_ratio()
	var movement_z: float = -delta_y * ratio

	target_scroll_z += movement_z
	current_scroll_z = clampf(target_scroll_z, min_z - 1.5, max_z + 1.5)

	# Atualiza estimativa de velocidade de flick (positivo = puxada para cima / avanço)
	var instant_v: float = movement_z / dt
	flick_velocity = lerp(flick_velocity, instant_v, 0.45)

	last_touch_pos = current_screen_pos
	last_touch_time = now

func _end_drag() -> void:
	if not is_dragging:
		return
	is_dragging = false

	# Detecção de gesto rápido (swap / flick) na direção do movimento
	if abs(flick_velocity) > swipe_velocity_threshold:
		if flick_velocity > 0: # Deslizada para cima -> volta para fase anterior
			snap_to_level(current_snapped_level - 1)
		else: # Deslizada para baixo -> avança para próxima fase
			snap_to_level(current_snapped_level + 1)
	else:
		# Soltura lenta -> encaixe magnético na ilha mais próxima
		var closest_lvl: int = find_closest_level(current_scroll_z)
		snap_to_level(closest_lvl)

func find_closest_level(scroll_z: float) -> int:
	var idx: int = roundi(-scroll_z / z_spacing) + 1
	return clampi(idx, 1, total_levels)

func snap_to_level(lvl: int, animated: bool = true) -> void:
	current_snapped_level = clampi(lvl, 1, total_levels)
	var target_z: float = -float(current_snapped_level - 1) * z_spacing
	target_scroll_z = target_z

	if snap_tween != null and snap_tween.is_valid():
		snap_tween.kill()

	if animated:
		snap_tween = create_tween()
		snap_tween.tween_property(self, "current_scroll_z", target_z, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		current_scroll_z = target_z

	island_snapped.emit(current_snapped_level)

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

	# Começa focado na fase atual do robô
	current_snapped_level = find_closest_level(target_bot_pos.z)
	target_scroll_z = -float(current_snapped_level - 1) * z_spacing
	current_scroll_z = target_scroll_z

	var cam_x: float = get_camera_x_at_z(current_scroll_z)
	var dest_pos: Vector3 = Vector3(cam_x, map_height, current_scroll_z + map_z_offset)
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
