extends CharacterBody3D

@export var base_speed: float = 3.25
@export var acceleration: float = 24.0
@export var friction: float = 18.0
@export var rotation_speed: float = 600.0 # Graus por segundo de rotação da serra em velocidade máxima (em movimento)
@export var idle_rotation_speed: float = 90.0 # Graus por segundo de rotação suave da serra quando parado (marcha lenta)
@export var knockback_force: float = 4.75 # Afastamento/ricochete calibrado ao colidir a lâmina com rochas

@export_group("Procedural Motion")
@export var max_pitch_deg: float = 6.0         # Inclinação máxima para frente/trás (graus)
@export var max_roll_deg: float = 4.5          # Inclinação máxima lateral em curvas (graus)
@export var tilt_responsiveness: float = 9.0   # Responsividade do chassi ao inclinar
@export var suspension_bob_amp: float = 0.022  # Amplitude do bobbing vertical da suspensão (metros)
@export var suspension_frequency: float = 14.0 # Frequência de oscilação pelo rolamento da roda
@export var head_lag_factor: float = 0.28      # Sensibilidade do atraso inercial da cabeça

@onready var visual_pivot: Node3D = $VisualPivot
@onready var robot_body: Node3D = $VisualPivot/GrassBot/Robot/Body if has_node("VisualPivot/GrassBot/Robot/Body") else null
@onready var wheel_mesh: MeshInstance3D = $VisualPivot/GrassBot/Robot/Body/wheel if has_node("VisualPivot/GrassBot/Robot/Body/wheel") else null
@onready var blade_spinner: Node3D = $VisualPivot/GrassBot/Robot/BladeSpinner if has_node("VisualPivot/GrassBot/Robot/BladeSpinner") else null
@onready var blade_tier_1: MeshInstance3D = $VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_1 if has_node("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_1") else null
@onready var blade_tier_2: MeshInstance3D = $VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_2 if has_node("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_2") else null
@onready var blade_tier_3: MeshInstance3D = $VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_3 if has_node("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_3") else null
@onready var blade_tier_4: MeshInstance3D = $VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_4 if has_node("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_4") else null

@onready var head_node: Node3D = $VisualPivot/GrassBot/Robot/Body/head if has_node("VisualPivot/GrassBot/Robot/Body/head") else null
@onready var neck_node: Node3D = $VisualPivot/GrassBot/Robot/Body/neck if has_node("VisualPivot/GrassBot/Robot/Body/neck") else null
@onready var low_arm_node: Node3D = $VisualPivot/GrassBot/Robot/Body/low_arm if has_node("VisualPivot/GrassBot/Robot/Body/low_arm") else null
@onready var up_arm_node: Node3D = $VisualPivot/GrassBot/Robot/Body/up_arm if has_node("VisualPivot/GrassBot/Robot/Body/up_arm") else null

@onready var blade_area: Area3D = $BladeArea
@onready var blade_shape: CollisionShape3D = $BladeArea/CollisionShape3D
@onready var spark_particles: CPUParticles3D = $SparkParticles
@onready var confetti_particles: CPUParticles3D = $ConfettiParticles if has_node("ConfettiParticles") else null
@onready var fireworks_particles: CPUParticles3D = $FireworksParticles if has_node("FireworksParticles") else null
@onready var defeat_puff_particles: CPUParticles3D = $DefeatPuffParticles if has_node("DefeatPuffParticles") else null
@onready var robot_eyes: RobotEyes = $RobotEyes if has_node("RobotEyes") else null

var input_direction: Vector2 = Vector2.ZERO
var is_stunned: bool = false
var stun_timer: float = 0.0
var _shock_cooldown: float = 0.0
var idle_eyes_timer: float = 0.0
var current_blade_speed: float = 90.0
var vegetation_grid: Node3D = null

var _is_celebrating: bool = false
var _is_defeated: bool = false
var _celebration_tween: Tween = null
var _defeat_tween: Tween = null

var _victory_idle_active: bool = false
var _victory_head_timer: float = 0.0
var _victory_target_head_yaw: float = 0.0
var _victory_target_head_pitch: float = 0.0
var _victory_expression_timer: float = 0.0

var current_pitch: float = 0.0
var current_roll: float = 0.0
var suspension_phase: float = 0.0
var shock_compression: float = 0.0
var last_body_yaw: float = 0.0
var head_yaw_lag: float = 0.0
var initial_body_y: float = 0.0
var initial_wheel_y: float = 0.0

var _cached_blade_radius: float = 0.90
var _cached_cutter_speed: float = 3.25
var _cached_cutter_power: int = 1
var _last_shader_pos: Vector3 = Vector3(99999.0, 99999.0, 99999.0)
var _last_shader_radius: float = -1.0
var _last_cut_pos: Vector3 = Vector3(99999.0, 99999.0, 99999.0)
var _last_cut_radius: float = -1.0
var _overlapping_vegetation: Array[Area3D] = []

# Cache pré-calculado de obstáculos (Tarefa 1.1)
var _obstacle_positions_2d: PackedVector2Array = PackedVector2Array()
var _obstacle_radii: PackedFloat32Array = PackedFloat32Array()
var _obstacle_bounds: Rect2 = Rect2()
var _has_obstacles: bool = false

func _ready() -> void:
	add_to_group("cutter")
	current_blade_speed = idle_rotation_speed
	_cached_cutter_speed = base_speed
	if blade_spinner != null and robot_body != null:
		blade_spinner.reparent(robot_body, true)
		for child: Node in blade_spinner.get_children():
			if child is GeometryInstance3D:
				(child as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if robot_body:
		robot_body.rotation.y = 0.0 # Virado de frente para a câmera (+Z)
		initial_body_y = robot_body.position.y
		last_body_yaw = 0.0
	if wheel_mesh:
		initial_wheel_y = wheel_mesh.position.y
	if spark_particles != null:
		spark_particles.top_level = true
		spark_particles.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	if blade_area != null:
		if not blade_area.area_entered.is_connected(_on_blade_area_entered):
			blade_area.area_entered.connect(_on_blade_area_entered)
		if not blade_area.area_exited.is_connected(_on_blade_area_exited):
			blade_area.area_exited.connect(_on_blade_area_exited)
		call_deferred("_sync_initial_overlaps")
	_setup_eyes()
	update_upgrades()
	_update_shader_globals()
	reset_orientation_to_camera()
	call_deferred("rebuild_obstacles_cache")
	if UpgradeManager != null:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	if GameManager != null:
		GameManager.state_changed.connect(_on_game_state_changed)
	if AudioManager != null:
		AudioManager.start_engine()

func _exit_tree() -> void:
	if AudioManager != null:
		AudioManager.stop_engine()
	RenderingServer.global_shader_parameter_set("global_cutter_pos", Vector3(0.0, -9999.0, 0.0))
	RenderingServer.global_shader_parameter_set("global_cutter_interact_radius", 0.0)

func _setup_eyes() -> void:
	if robot_eyes == null:
		return
	var screen_mesh: MeshInstance3D = null
	if head_node:
		screen_mesh = head_node.find_child("screen_display*", true, false) as MeshInstance3D
	if screen_mesh == null and visual_pivot:
		screen_mesh = visual_pivot.find_child("screen_display*", true, false) as MeshInstance3D

	if screen_mesh:
		var eye_mat: Material = preload("res://shaders/eye_display_material.tres")
		screen_mesh.set_surface_override_material(0, eye_mat)
		robot_eyes.screen_mesh = screen_mesh
		robot_eyes._ready()

func _on_game_state_changed(new_state: int) -> void:
	if new_state != GameManager.GameState.PLAYING:
		velocity = Vector3.ZERO
		input_direction = Vector2.ZERO
		if AudioManager != null:
			AudioManager.stop_engine()
	else:
		_is_celebrating = false
		_is_defeated = false
		if _celebration_tween != null and _celebration_tween.is_valid():
			_celebration_tween.kill()
		if _defeat_tween != null and _defeat_tween.is_valid():
			_defeat_tween.kill()
		if visual_pivot != null:
			visual_pivot.scale = Vector3(0.62, 0.62, 0.62)
			visual_pivot.position = Vector3.ZERO
		if AudioManager != null:
			AudioManager.start_engine()

	if new_state == GameManager.GameState.PAUSED:
		if robot_eyes != null:
			robot_eyes.set_screen_off(true)
	elif new_state == GameManager.GameState.VICTORY:
		play_victory_celebration()
	elif new_state == GameManager.GameState.GAME_OVER:
		play_defeat_reaction()
	elif new_state == GameManager.GameState.PLAYING:
		reset_orientation_to_camera()
		if robot_eyes != null:
			robot_eyes.set_screen_off(false)

## Reseta a orientação e postura para olhar de frente para a câmera (+Z)
func reset_orientation_to_camera() -> void:
	_victory_idle_active = false
	_is_celebrating = false
	velocity = Vector3.ZERO
	input_direction = Vector2.ZERO
	if visual_pivot != null:
		visual_pivot.rotation = Vector3.ZERO
		visual_pivot.position = Vector3.ZERO
		visual_pivot.scale = Vector3(0.62, 0.62, 0.62)
	if robot_body != null:
		robot_body.rotation.y = 0.0 # Frente para a câmera (+Z)
		robot_body.rotation.x = 0.0
		robot_body.rotation.z = 0.0
		last_body_yaw = 0.0
	if head_node != null:
		head_node.rotation = Vector3.ZERO
	if neck_node != null:
		neck_node.rotation = Vector3.ZERO
	current_pitch = 0.0
	current_roll = 0.0
	shock_compression = 0.0

func play_victory_celebration() -> void:
	if _is_celebrating:
		return
	_is_celebrating = true
	_victory_idle_active = false
	velocity = Vector3.ZERO
	input_direction = Vector2.ZERO

	if robot_eyes != null:
		robot_eyes.trigger_victory_reaction()

	# Gira o corpo suavemente para a frente da câmera (+Z) e nivela pitch/roll para não cortar o solo
	current_pitch = 0.0
	current_roll = 0.0
	shock_compression = 0.0
	if robot_body != null:
		var turn_tween: Tween = create_tween().set_parallel(true)
		turn_tween.tween_property(robot_body, "rotation:y", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		turn_tween.tween_property(robot_body, "rotation:x", 0.0, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		turn_tween.tween_property(robot_body, "rotation:z", 0.0, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		turn_tween.tween_property(robot_body, "position:y", initial_body_y, 0.30).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Dispara confetes e fogos de artifício
	if confetti_particles != null:
		confetti_particles.restart()
		confetti_particles.emitting = true
	if fireworks_particles != null:
		fireworks_particles.restart()
		fireworks_particles.emitting = true

	# Rotina de saltos de comemoração com squash & stretch
	if _celebration_tween != null and _celebration_tween.is_valid():
		_celebration_tween.kill()

	if visual_pivot != null:
		_celebration_tween = create_tween()
		var base_scale: Vector3 = Vector3(0.62, 0.62, 0.62)
		var squash_prep: Vector3 = Vector3(0.68, 0.52, 0.68)
		var stretch_air: Vector3 = Vector3(0.56, 0.70, 0.56)
		var squash_land: Vector3 = Vector3(0.70, 0.50, 0.70)

		# Salto 1: Antecipação rápida (squash)
		_celebration_tween.tween_property(visual_pivot, "scale", squash_prep, 0.12).set_trans(Tween.TRANS_QUAD)
		_celebration_tween.parallel().tween_property(visual_pivot, "position:y", -0.04, 0.12).set_trans(Tween.TRANS_QUAD)

		# Subida triunfal
		_celebration_tween.chain().tween_property(visual_pivot, "scale", stretch_air, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_celebration_tween.parallel().tween_property(visual_pivot, "position:y", 0.42, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

		# Queda
		_celebration_tween.chain().tween_property(visual_pivot, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_celebration_tween.parallel().tween_property(visual_pivot, "scale", base_scale, 0.22)

		# Aterrissagem com squash elástico
		_celebration_tween.chain().tween_property(visual_pivot, "scale", squash_land, 0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		_celebration_tween.chain().tween_property(visual_pivot, "scale", base_scale, 0.14).set_trans(Tween.TRANS_SINE)

		# Salto 2 (Pequeno pulinho rítmico secundário de alegria)
		_celebration_tween.chain().tween_property(visual_pivot, "position:y", 0.22, 0.20).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_celebration_tween.parallel().tween_property(visual_pivot, "scale", Vector3(0.58, 0.66, 0.58), 0.15)
		_celebration_tween.chain().tween_property(visual_pivot, "position:y", 0.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		_celebration_tween.parallel().tween_property(visual_pivot, "scale", base_scale, 0.18)

		# Ao finalizar os saltos, transiciona para o comportamento vivo da Home (cabeça olhando em volta e expressões)
		_celebration_tween.finished.connect(func() -> void:
			_victory_idle_active = true
			_victory_head_timer = 0.5
			_victory_expression_timer = 1.0
		)

	# Aceno feliz de cabeça no final
	if head_node != null:
		var head_tween: Tween = create_tween()
		head_tween.tween_interval(0.3)
		head_tween.tween_property(head_node, "rotation:x", deg_to_rad(-14.0), 0.2)
		head_tween.tween_property(head_node, "rotation:x", deg_to_rad(10.0), 0.2)
		head_tween.tween_property(head_node, "rotation:x", 0.0, 0.2)

func _process_victory_idle_behavior(delta: float) -> void:
	if not _victory_idle_active:
		return

	# 1. Articulação expressiva e autônoma da cabeça (igual à cena da Home)
	if head_node != null:
		_victory_head_timer -= delta
		if _victory_head_timer <= 0.0:
			_victory_target_head_yaw = deg_to_rad(randf_range(-22.0, 22.0))
			_victory_target_head_pitch = deg_to_rad(randf_range(-12.0, 8.0))
			_victory_head_timer = randf_range(1.8, 3.2)
			if robot_eyes != null:
				var look_vec: Vector2 = Vector2(_victory_target_head_yaw * 1.5, _victory_target_head_pitch * 2.0)
				robot_eyes.set_look_direction(look_vec)

		head_node.rotation.y = lerp_angle(head_node.rotation.y, _victory_target_head_yaw, delta * 4.0)
		head_node.rotation.x = lerp_angle(head_node.rotation.x, _victory_target_head_pitch, delta * 4.0)

	# 2. Alternância de expressões alegres e vivas nos olhos
	if robot_eyes != null:
		_victory_expression_timer -= delta
		if _victory_expression_timer <= 0.0:
			var joy_expressions: Array[RobotEyes.EyeExpression] = [
				RobotEyes.EyeExpression.VICTORY,
				RobotEyes.EyeExpression.HAPPY,
				RobotEyes.EyeExpression.WINK
			]
			var next_expr: RobotEyes.EyeExpression = joy_expressions[randi() % joy_expressions.size()]
			robot_eyes.set_expression(next_expr, Color.TRANSPARENT, randf_range(2.0, 3.5))
			_victory_expression_timer = randf_range(3.5, 6.0)

func play_defeat_reaction() -> void:
	if _is_defeated:
		return
	_is_defeated = true
	velocity = Vector3.ZERO
	input_direction = Vector2.ZERO

	if robot_eyes != null:
		robot_eyes.trigger_defeat_reaction()

	if defeat_puff_particles != null:
		defeat_puff_particles.restart()
		defeat_puff_particles.emitting = true

	# Desacelera a lâmina suavemente até parar
	var blade_decel_tween: Tween = create_tween()
	blade_decel_tween.tween_property(self, "current_blade_speed", 0.0, 1.2).set_trans(Tween.TRANS_SINE)

	# Postura cabisbaixa: inclina para a frente, abaixa suspensão e pende a cabeça
	if _defeat_tween != null and _defeat_tween.is_valid():
		_defeat_tween.kill()

	_defeat_tween = create_tween().set_parallel(true)
	if robot_body != null:
		_defeat_tween.tween_property(robot_body, "rotation:x", deg_to_rad(10.0), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_defeat_tween.tween_property(robot_body, "position:y", initial_body_y - 0.05, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if head_node != null:
		_defeat_tween.tween_property(head_node, "rotation:x", deg_to_rad(18.0), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _update_shader_globals() -> void:
	var interact_radius: float = _cached_blade_radius + 0.95
	if global_position.distance_squared_to(_last_shader_pos) <= 0.0004 and absf(interact_radius - _last_shader_radius) <= 0.001:
		return
	_last_shader_pos = global_position
	_last_shader_radius = interact_radius

	RenderingServer.global_shader_parameter_set("global_cutter_pos", global_position)
	RenderingServer.global_shader_parameter_set("global_cutter_interact_radius", interact_radius)

func _on_upgrade_purchased(upgrade_name: String, _level: int) -> void:
	if upgrade_name == "radius" or upgrade_name == "speed" or upgrade_name == "power":
		update_upgrades()

func update_upgrades() -> void:
	if UpgradeManager == null:
		_cached_blade_radius = 0.90
		_cached_cutter_speed = base_speed
		_cached_cutter_power = 1
		return
	
	_cached_blade_radius = UpgradeManager.get_blade_radius()
	_cached_cutter_speed = UpgradeManager.get_cutter_speed()
	_cached_cutter_power = UpgradeManager.get_cutter_power()

	# Atualiza raio da área física de corte
	var radius: float = _cached_blade_radius
	if blade_shape.shape is CylinderShape3D:
		blade_shape.shape.radius = radius
	elif blade_shape.shape is SphereShape3D:
		blade_shape.shape.radius = radius
	
	# Escala da malha visual da serra 1:1 com o raio físico (compensando VisualPivot 0.62 * 1.66m = 1.03m)
	var visual_scale: float = radius / 1.03
	if blade_spinner:
		blade_spinner.scale = Vector3(visual_scale, 1.0, visual_scale)
	
	_update_blade_tier_visual()
	_update_shader_globals()

func _update_blade_tier_visual() -> void:
	var tier: int = 1
	if UpgradeManager != null and UpgradeManager.has_method("get_blade_tier"):
		tier = UpgradeManager.get_blade_tier()
	
	if blade_tier_1:
		blade_tier_1.visible = (tier == 1)
	if blade_tier_2:
		blade_tier_2.visible = (tier == 2)
	if blade_tier_3:
		blade_tier_3.visible = (tier == 3)
	if blade_tier_4:
		blade_tier_4.visible = (tier == 4)

func set_input_direction(dir: Vector2) -> void:
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
		input_direction = Vector2.ZERO
		return
	input_direction = dir

func _physics_process(delta: float) -> void:
	if _shock_cooldown > 0.0:
		_shock_cooldown = maxf(0.0, _shock_cooldown - delta)

	# Desativa completamente rotação, movimento e corte se não estiver em gameplay ativo (ex: modal de fim de fase)
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
		velocity = Vector3.ZERO
		input_direction = Vector2.ZERO
		if _is_celebrating:
			current_blade_speed = idle_rotation_speed
			if blade_spinner != null:
				blade_spinner.rotate_y(deg_to_rad(current_blade_speed * delta))
			_process_victory_idle_behavior(delta)
		else:
			current_blade_speed = 0.0
		_process_procedural_motion(delta, 1.0)
		return

	# Rotação da serra circular: rotação acelerada durante deslocamento e marcha lenta suave quando parado
	var is_moving: bool = velocity.length_squared() > 0.01 or input_direction.length_squared() > 0.01
	var target_blade_speed: float = rotation_speed if is_moving else idle_rotation_speed
	var blade_accel: float = 12.0 if is_moving else 3.5
	current_blade_speed = lerp(current_blade_speed, target_blade_speed, blade_accel * delta)

	if blade_spinner:
		blade_spinner.rotate_y(deg_to_rad(current_blade_speed * delta))

	# Atualiza o olhar do robô e o ciclo de sono em idle
	if robot_eyes:
		robot_eyes.set_look_direction(input_direction)
		if is_moving:
			if idle_eyes_timer > 5.0 and robot_eyes.current_expression == RobotEyes.EyeExpression.SLEEPING:
				robot_eyes.set_expression(RobotEyes.EyeExpression.NORMAL)
			idle_eyes_timer = 0.0
		else:
			idle_eyes_timer += delta
			if idle_eyes_timer > 5.5 and robot_eyes.current_expression == RobotEyes.EyeExpression.NORMAL:
				robot_eyes.set_expression(RobotEyes.EyeExpression.SLEEPING)

	var target_speed: float = _cached_cutter_speed

	# Gerenciamento de choque / ricochete
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
		# Aplica atrito durante o recuo
		velocity = velocity.move_toward(Vector3.ZERO, friction * 2.0 * delta)
		move_and_slide()
		if vegetation_grid != null and is_instance_valid(vegetation_grid) and vegetation_grid.has_method("resolve_rigid_plant_collision"):
			var col_result: Dictionary = vegetation_grid.call("resolve_rigid_plant_collision", global_position, velocity, 0.30, 0.18)
			global_position = col_result["position"]
			velocity = col_result["velocity"]
		_process_procedural_motion(delta, target_speed)
		_check_obstacle_collisions()
		_update_shader_globals()
		return

	# Movimento omnidirecional responsivo baseado na entrada
	# Converte a direção 2D (da tela isométrica) para coordenadas de mundo 3D
	var move_dir: Vector3 = Vector3(input_direction.x, 0.0, input_direction.y)
	if move_dir.length_squared() > 0.001:
		var target_vel: Vector3 = move_dir * target_speed
		velocity = velocity.move_toward(target_vel, acceleration * delta)
		
		# Orientação suave do chassi do robô na direção do movimento (frente alinhada)
		if robot_body:
			var target_rot_y: float = atan2(move_dir.x, move_dir.z)
			robot_body.rotation.y = lerp_angle(robot_body.rotation.y, target_rot_y, 14.0 * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)

	# Rotação física da mono-wheel baseada no deslocamento linear
	if wheel_mesh and velocity.length_squared() > 0.01:
		var linear_speed: float = velocity.length()
		var effective_radius: float = 0.45 * 0.7 # Raio do pneu com a escala visual
		wheel_mesh.rotate_x(linear_speed / effective_radius * delta)

	# Atualiza a física procedural de suspensão, inclinação e movimentos da cabeça
	_process_procedural_motion(delta, target_speed)

	move_and_slide()
	if vegetation_grid != null and is_instance_valid(vegetation_grid) and vegetation_grid.has_method("resolve_rigid_plant_collision"):
		var col_result: Dictionary = vegetation_grid.call("resolve_rigid_plant_collision", global_position, velocity, 0.30, 0.18)
		global_position = col_result["position"]
		velocity = col_result["velocity"]

	if AudioManager != null and GameManager != null and GameManager.current_state == GameManager.GameState.PLAYING:
		var speed_ratio: float = velocity.length() / maxf(1.0, _cached_cutter_speed)
		AudioManager.update_engine_speed(speed_ratio)
	_check_obstacle_collisions()
	_process_cutting()
	_update_shader_globals()

func _process_procedural_motion(delta: float, target_speed: float) -> void:
	if robot_body == null:
		return

	# Se não estiver jogando, interpola tudo suavemente de volta ao repouso (a não ser que esteja comemorando ou derrotado)
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
		if _is_celebrating or _is_defeated:
			return
		current_pitch = lerp(current_pitch, 0.0, 8.0 * delta)
		current_roll = lerp(current_roll, 0.0, 8.0 * delta)
		shock_compression = move_toward(shock_compression, 0.0, 3.0 * delta)
		robot_body.rotation.x = current_pitch
		robot_body.rotation.z = current_roll
		robot_body.position.y = initial_body_y + shock_compression
		if wheel_mesh:
			wheel_mesh.position.y = initial_wheel_y
		if head_node:
			head_node.rotation = head_node.rotation.lerp(Vector3.ZERO, 8.0 * delta)
		if neck_node:
			neck_node.rotation = neck_node.rotation.lerp(Vector3.ZERO, 8.0 * delta)
		return

	# --- 1. Dinâmica de Inclinação (Pitch & Roll / Lean) ---
	# Limite geométrico seguro para que a ponta da serra jamais penetre o solo (Y <= 0.0) em raios grandes
	var max_safe_tilt_rad: float = atan2(0.055, maxf(0.90, _cached_blade_radius))
	var eff_max_pitch_rad: float = minf(deg_to_rad(max_pitch_deg), max_safe_tilt_rad)
	var eff_max_roll_rad: float = minf(deg_to_rad(max_roll_deg), max_safe_tilt_rad)

	# Direção frontal do robô (no glTF, +Z local com rotation.y atual)
	var forward_dir := Vector3(sin(robot_body.rotation.y), 0.0, cos(robot_body.rotation.y))
	var forward_speed := velocity.dot(forward_dir)
	var speed_ratio := clampf(forward_speed / maxf(target_speed, 0.1), -1.0, 1.0)
	var target_pitch := speed_ratio * eff_max_pitch_rad

	# Taxa angular de curva (Yaw delta) para calcular o Roll lateral
	var yaw_delta := angle_difference(last_body_yaw, robot_body.rotation.y)
	last_body_yaw = robot_body.rotation.y
	var turn_rate := yaw_delta / maxf(delta, 0.0001)
	var target_roll := clampf(turn_rate * 0.025, -eff_max_roll_rad, eff_max_roll_rad)

	# Interpolação suave com amortecimento
	current_pitch = lerp(current_pitch, target_pitch, tilt_responsiveness * delta)
	current_roll = lerp(current_roll, target_roll, tilt_responsiveness * delta)

	robot_body.rotation.x = current_pitch
	robot_body.rotation.z = current_roll

	# --- 2. Suspensão Vertical & Amortecedores ---
	var linear_speed := velocity.length()
	if linear_speed > 0.05:
		suspension_phase += linear_speed * delta * suspension_frequency

	# Relaxamento suave do impacto
	shock_compression = move_toward(shock_compression, 0.0, 4.5 * delta)
	var bob := sin(suspension_phase) * suspension_bob_amp if linear_speed > 0.05 else 0.0
	var total_suspension := bob + shock_compression

	# Chassi sobe/desce suavemente com o terreno
	robot_body.position.y = initial_body_y + total_suspension

	# Roda contra-reage para absorver o relevo
	if wheel_mesh:
		wheel_mesh.position.y = initial_wheel_y - total_suspension * 0.7

	# Braços articulados (low_arm e up_arm) rotacionam sutilmente em X com o curso da suspensão
	var arm_rot_x := -total_suspension * 1.8
	if low_arm_node:
		low_arm_node.rotation.x = arm_rot_x
	if up_arm_node:
		up_arm_node.rotation.x = -arm_rot_x * 0.75

	# --- 3. Movimento Secundário de Cabeça e Pescoço ---
	# O pescoço absorve o pitch compensando levemente para manter visão horizontal
	if neck_node:
		neck_node.rotation.x = lerp_angle(neck_node.rotation.x, -current_pitch * 0.35, 10.0 * delta)
		neck_node.rotation.z = lerp_angle(neck_node.rotation.z, -current_roll * 0.3, 10.0 * delta)

	# A cabeça tem leve inércia/antecipação no Yaw ao curvar
	var target_head_yaw := clampf(-turn_rate * 0.03 * head_lag_factor, -deg_to_rad(6.0), deg_to_rad(6.0))
	head_yaw_lag = lerp_angle(head_yaw_lag, target_head_yaw, 8.0 * delta)
	if head_node:
		head_node.rotation.y = head_yaw_lag
		head_node.rotation.x = lerp_angle(head_node.rotation.x, -current_pitch * 0.25, 12.0 * delta)

## Reconstrói o cache contíguo de obstáculos da fase para eliminar buscas dinâmicas na SceneTree a cada physics tick.
func rebuild_obstacles_cache() -> void:
	_obstacle_positions_2d.clear()
	_obstacle_radii.clear()
	_has_obstacles = false

	var tree: SceneTree = get_tree()
	if tree == null:
		_obstacle_bounds = Rect2()
		return

	var obstacles: Array[Node] = tree.get_nodes_in_group("obstacles")
	if obstacles.is_empty():
		_obstacle_bounds = Rect2()
		return

	var min_pos := Vector2(INF, INF)
	var max_pos := Vector2(-INF, -INF)
	var max_radius: float = 0.18

	for obs: Node in obstacles:
		var obs_3d: Node3D = obs as Node3D
		if obs_3d == null or not is_instance_valid(obs_3d):
			continue

		var obs_pos_2d: Vector2 = Vector2(obs_3d.global_position.x, obs_3d.global_position.z)
		var obs_radius: float = 0.18
		var col_shape: CollisionShape3D = obs_3d.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if col_shape != null:
			if col_shape.shape is CylinderShape3D:
				obs_radius = (col_shape.shape as CylinderShape3D).radius
			elif col_shape.shape is SphereShape3D:
				obs_radius = (col_shape.shape as SphereShape3D).radius

		_obstacle_positions_2d.append(obs_pos_2d)
		_obstacle_radii.append(obs_radius)
		max_radius = maxf(max_radius, obs_radius)

		min_pos.x = minf(min_pos.x, obs_pos_2d.x)
		min_pos.y = minf(min_pos.y, obs_pos_2d.y)
		max_pos.x = maxf(max_pos.x, obs_pos_2d.x)
		max_pos.y = maxf(max_pos.y, obs_pos_2d.y)

	_has_obstacles = not _obstacle_positions_2d.is_empty()
	if _has_obstacles:
		# Expande o bounding box pelo raio máximo mais margem segura da lâmina (3.0m)
		var margin: float = max_radius + 3.0
		_obstacle_bounds = Rect2(min_pos - Vector2(margin, margin), (max_pos - min_pos) + Vector2(margin * 2.0, margin * 2.0))
	else:
		_obstacle_bounds = Rect2()

func _check_obstacle_collisions() -> void:
	if not _has_obstacles:
		_check_slide_collisions()
		return

	var cutter_pos_2d := Vector2(global_position.x, global_position.z)

	# 1. Early-exit espacial se o robô estiver fora da área que contém rochas
	if not _obstacle_bounds.has_point(cutter_pos_2d):
		_check_slide_collisions()
		return

	# 2. Verificação direta em memória contígua (zero alocações no heap, zero lookups na SceneTree)
	var count: int = _obstacle_positions_2d.size()
	for i: int in range(count):
		var obs_pos_2d: Vector2 = _obstacle_positions_2d[i]
		var obs_radius: float = _obstacle_radii[i]
		var blade_reach: float = _cached_blade_radius + obs_radius
		var blade_reach_sq: float = blade_reach * blade_reach

		var diff_2d: Vector2 = cutter_pos_2d - obs_pos_2d
		var dist_sq: float = diff_2d.length_squared()

		if dist_sq < blade_reach_sq:
			var dist: float = sqrt(dist_sq)
			var normal_2d: Vector2 = Vector2(0.0, 1.0)
			if dist > 0.001:
				normal_2d = diff_2d / dist
			elif velocity.length_squared() > 0.001:
				normal_2d = -Vector2(velocity.x, velocity.z).normalized()

			var normal_3d: Vector3 = Vector3(normal_2d.x, 0.0, normal_2d.y)
			var spark_pt: Vector3 = global_position - normal_3d * (_cached_blade_radius * 0.85)
			spark_pt.y = global_position.y + 0.15

			# Bloqueio elástico instantâneo para impedir que a lâmina penetre a malha da rocha
			var overlap: float = blade_reach - dist
			if overlap > 0.0:
				global_position += normal_3d * overlap

			# Dispara choque e ricochete com arremesso ampliado se não estiver em cooldown
			if _shock_cooldown <= 0.0:
				_trigger_obstacle_shock(normal_3d, spark_pt)
			return

	# 3. Salvaguarda corporal física via slide_collision
	_check_slide_collisions()

func _check_slide_collisions() -> void:
	var count: int = get_slide_collision_count()
	for i in range(count):
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider and collider.is_in_group("obstacles"):
			if _shock_cooldown <= 0.0:
				_trigger_obstacle_shock(collision.get_normal(), collision.get_position())
			break

func _trigger_obstacle_shock(normal: Vector3, spark_pos: Vector3 = Vector3.ZERO) -> void:
	is_stunned = true
	stun_timer = 0.18 # Duração do choque calibrada com o afastamento reduzido
	_shock_cooldown = 0.25 # Cooldown defensivo para evitar múltiplos choques consecutivos
	velocity = normal * knockback_force # Força calibrada (4.75 m/s) para afastamento curto
	shock_compression = -0.045 # Afundamento elástico proporcional da suspensão
	
	# Dispara expressão brava com olhos vermelhos e faíscas elétricas
	if robot_eyes:
		robot_eyes.trigger_obstacle_reaction()

	# Efeito de faíscas metálicas no ponto de contato dente-de-serra contra rocha
	if spark_particles:
		spark_particles.emitting = false
		if spark_pos != Vector3.ZERO:
			spark_particles.global_position = spark_pos
		else:
			spark_particles.global_position = global_position - normal * (_cached_blade_radius * 0.85)
		spark_particles.reset_physics_interpolation()
		spark_particles.restart()

	# Vibração de impacto no celular e tremor de câmera
	if GameManager != null:
		GameManager.trigger_haptic_impact()

	# Efeito sonoro do choque da lâmina com a rocha
	if AudioManager != null:
		AudioManager.play_sfx("slap_rock")

func _sync_initial_overlaps() -> void:
	if blade_area == null or not blade_area.monitoring:
		return
	var initial_areas: Array[Area3D] = blade_area.get_overlapping_areas()
	for area in initial_areas:
		_on_blade_area_entered(area)

func _on_blade_area_entered(area: Area3D) -> void:
	if area == null or not is_instance_valid(area) or not area.is_in_group("vegetation"):
		return
	var fully_cut: bool = _cut_vegetation_area(area)
	if not fully_cut and not _overlapping_vegetation.has(area):
		_overlapping_vegetation.append(area)

func _on_blade_area_exited(area: Area3D) -> void:
	var idx: int = _overlapping_vegetation.find(area)
	if idx != -1:
		_overlapping_vegetation.remove_at(idx)

func _cut_vegetation_area(area: Area3D) -> bool:
	if area == null or not is_instance_valid(area):
		return true
	var plant: Node = area.get_parent()
	if plant == null or not is_instance_valid(plant):
		return true
	if bool(plant.get("is_cut")):
		return true
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
		return false
	if plant.has_method("cut"):
		plant.call("cut", _cached_cutter_power)
	return bool(plant.get("is_cut"))

func _process_cutting() -> void:
	if vegetation_grid != null and is_instance_valid(vegetation_grid):
		if global_position.distance_squared_to(_last_cut_pos) < 0.0004 and absf(_cached_blade_radius - _last_cut_radius) < 0.001:
			return
		_last_cut_pos = global_position
		_last_cut_radius = _cached_blade_radius
		vegetation_grid.call("cut_in_circle", global_position, _cached_blade_radius, _cached_cutter_power)
		return
	if _overlapping_vegetation.is_empty():
		return
	for i in range(_overlapping_vegetation.size() - 1, -1, -1):
		var area: Area3D = _overlapping_vegetation[i]
		if area == null or not is_instance_valid(area):
			_overlapping_vegetation.remove_at(i)
			continue
		var fully_cut: bool = _cut_vegetation_area(area)
		if fully_cut:
			_overlapping_vegetation.remove_at(i)

## Calcula o deslocamento local 3D estritamente ao lado do corpo do robô (Esquerda, Centro ou Direita)
## garantindo que os números flutuantes brotem sempre próximos ao chassi mecânico.
func get_body_side_local_offset(cut_pos: Vector3) -> Vector3:
	var yaw: float = robot_body.rotation.y if robot_body != null else rotation.y
	var forward: Vector3 = Vector3(sin(yaw), 0.0, cos(yaw))
	var right: Vector3 = Vector3(cos(yaw), 0.0, -sin(yaw))

	var to_cut: Vector3 = cut_pos - global_position
	to_cut.y = 0.0
	var lateral_dot: float = to_cut.dot(right)

	# Posiciona estritamente ao lado do corpo do robô (chassi/paralamas)
	var sector_offset: Vector3 = Vector3.ZERO
	if lateral_dot < -0.16:
		# Setor Esquerda: imediatamente à esquerda do corpo
		sector_offset = forward * 0.14 - right * 0.42
	elif lateral_dot > 0.16:
		# Setor Direita: imediatamente à direita do corpo
		sector_offset = forward * 0.14 + right * 0.42
	else:
		# Setor Centro: frente ao bico do chassi
		sector_offset = forward * 0.44

	var jitter_x: float = randf_range(-0.025, 0.025)
	var jitter_z: float = randf_range(-0.025, 0.025)
	return sector_offset + Vector3(jitter_x, 0.45, jitter_z)


## Calcula a coordenada 3D global imediatamente ao lado do corpo do robô.
func get_inner_blade_point(cut_pos: Vector3) -> Vector3:
	return global_position + get_body_side_local_offset(cut_pos)

