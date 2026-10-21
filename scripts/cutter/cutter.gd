extends CharacterBody3D

@export var base_speed: float = 3.25
@export var acceleration: float = 24.0
@export var friction: float = 18.0
@export var rotation_speed: float = 1200.0 # Graus por segundo de rotação da serra em velocidade máxima (em movimento)
@export var idle_rotation_speed: float = 90.0 # Graus por segundo de rotação suave da serra quando parado (marcha lenta)
@export var knockback_force: float = 5.0

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
@onready var robot_eyes: RobotEyes = $RobotEyes if has_node("RobotEyes") else null

var input_direction: Vector2 = Vector2.ZERO
var is_stunned: bool = false
var stun_timer: float = 0.0
var idle_eyes_timer: float = 0.0
var current_blade_speed: float = 90.0
var vegetation_grid: Node3D = null

var current_pitch: float = 0.0
var current_roll: float = 0.0
var suspension_phase: float = 0.0
var shock_compression: float = 0.0
var last_body_yaw: float = PI
var head_yaw_lag: float = 0.0
var initial_body_y: float = 0.0
var initial_wheel_y: float = 0.0

var _cached_blade_radius: float = 0.90
var _cached_cutter_speed: float = 3.25
var _cached_cutter_power: int = 1
var _last_shader_pos: Vector3 = Vector3(99999.0, 99999.0, 99999.0)
var _last_shader_radius: float = -1.0
var _overlapping_vegetation: Array[Area3D] = []

func _ready() -> void:
	current_blade_speed = idle_rotation_speed
	_cached_cutter_speed = base_speed
	if robot_body:
		robot_body.rotation.y = PI
		initial_body_y = robot_body.position.y
		last_body_yaw = robot_body.rotation.y
	if wheel_mesh:
		initial_wheel_y = wheel_mesh.position.y
	if blade_area != null:
		if not blade_area.area_entered.is_connected(_on_blade_area_entered):
			blade_area.area_entered.connect(_on_blade_area_entered)
		if not blade_area.area_exited.is_connected(_on_blade_area_exited):
			blade_area.area_exited.connect(_on_blade_area_exited)
		call_deferred("_sync_initial_overlaps")
	_setup_eyes()
	update_upgrades()
	_update_shader_globals()
	if UpgradeManager != null:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	if GameManager != null:
		GameManager.state_changed.connect(_on_game_state_changed)

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
	if robot_eyes != null:
		if new_state == GameManager.GameState.PAUSED:
			robot_eyes.set_screen_off(true)
		elif new_state == GameManager.GameState.VICTORY:
			robot_eyes.trigger_victory_reaction()
		elif new_state == GameManager.GameState.PLAYING:
			robot_eyes.set_screen_off(false)

const GRASS_MAT: ShaderMaterial = preload("res://shaders/interactive_grass_material.tres")
const GRASS_YELLOW_MAT: ShaderMaterial = preload("res://shaders/interactive_grass_yellow_material.tres")
const GRASS_BLUE_MAT: ShaderMaterial = preload("res://shaders/interactive_grass_blue_material.tres")
const GRASS_PURPLE_MAT: ShaderMaterial = preload("res://shaders/interactive_grass_purple_material.tres")
const WHEAT_MAT: ShaderMaterial = preload("res://shaders/interactive_wheat_material.tres")
const FLOWER_MAT: ShaderMaterial = preload("res://shaders/interactive_flower_material.tres")

func _update_shader_globals() -> void:
	var interact_radius: float = _cached_blade_radius + 0.95
	if global_position.distance_squared_to(_last_shader_pos) <= 0.0004 and absf(interact_radius - _last_shader_radius) <= 0.001:
		return
	_last_shader_pos = global_position
	_last_shader_radius = interact_radius

	if GRASS_MAT:
		GRASS_MAT.set_shader_parameter("cutter_pos", global_position)
		GRASS_MAT.set_shader_parameter("cutter_interact_radius", interact_radius)
	if GRASS_YELLOW_MAT:
		GRASS_YELLOW_MAT.set_shader_parameter("cutter_pos", global_position)
		GRASS_YELLOW_MAT.set_shader_parameter("cutter_interact_radius", interact_radius)
	if GRASS_BLUE_MAT:
		GRASS_BLUE_MAT.set_shader_parameter("cutter_pos", global_position)
		GRASS_BLUE_MAT.set_shader_parameter("cutter_interact_radius", interact_radius)
	if GRASS_PURPLE_MAT:
		GRASS_PURPLE_MAT.set_shader_parameter("cutter_pos", global_position)
		GRASS_PURPLE_MAT.set_shader_parameter("cutter_interact_radius", interact_radius)
	if WHEAT_MAT:
		WHEAT_MAT.set_shader_parameter("cutter_pos", global_position)
		WHEAT_MAT.set_shader_parameter("cutter_interact_radius", interact_radius)
	if FLOWER_MAT:
		FLOWER_MAT.set_shader_parameter("cutter_pos", global_position)
		FLOWER_MAT.set_shader_parameter("cutter_interact_radius", interact_radius)

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
	
	# Escala da malha visual da serra para refletir o upgrade de raio (base 1.18m)
	var visual_scale: float = radius / 1.18
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
	# Desativa completamente rotação, movimento e corte se não estiver em gameplay ativo (ex: modal de fim de fase)
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
		velocity = Vector3.ZERO
		input_direction = Vector2.ZERO
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
	_check_obstacle_collisions()
	_process_cutting()
	_update_shader_globals()

func _process_procedural_motion(delta: float, target_speed: float) -> void:
	if robot_body == null:
		return

	# Se não estiver jogando, interpola tudo suavemente de volta ao repouso
	if GameManager != null and GameManager.current_state != GameManager.GameState.PLAYING:
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
	# Direção frontal do robô (no glTF, +Z local com rotation.y atual)
	var forward_dir := Vector3(sin(robot_body.rotation.y), 0.0, cos(robot_body.rotation.y))
	var forward_speed := velocity.dot(forward_dir)
	var speed_ratio := clampf(forward_speed / maxf(target_speed, 0.1), -1.0, 1.0)
	var target_pitch := speed_ratio * deg_to_rad(max_pitch_deg)

	# Taxa angular de curva (Yaw delta) para calcular o Roll lateral
	var yaw_delta := angle_difference(last_body_yaw, robot_body.rotation.y)
	last_body_yaw = robot_body.rotation.y
	var turn_rate := yaw_delta / maxf(delta, 0.0001)
	var target_roll := clampf(turn_rate * 0.025, -deg_to_rad(max_roll_deg), deg_to_rad(max_roll_deg))

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

func _check_obstacle_collisions() -> void:
	var count: int = get_slide_collision_count()
	for i in range(count):
		var collision: KinematicCollision3D = get_slide_collision(i)
		var collider: Object = collision.get_collider()
		if collider and collider.is_in_group("obstacles"):
			# Colisão direta com obstáculo sólido!
			_trigger_obstacle_shock(collision.get_normal())
			break

func _trigger_obstacle_shock(normal: Vector3) -> void:
	is_stunned = true
	stun_timer = 0.18
	velocity = normal * knockback_force
	shock_compression = -0.045
	
	# Dispara expressão brava com olhos vermelhos e faíscas elétricas
	if robot_eyes:
		robot_eyes.trigger_obstacle_reaction()

	# Efeito de faíscas
	if spark_particles:
		spark_particles.global_position = global_position - normal * 0.4
		spark_particles.restart()

	# Vibração de impacto
	if GameManager != null:
		GameManager.trigger_haptic_impact()

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
		vegetation_grid.call("cut_in_circle", global_position, _cached_blade_radius, _cached_cutter_power)
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
