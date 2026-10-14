extends CharacterBody3D

@export var base_speed: float = 6.5
@export var acceleration: float = 24.0
@export var friction: float = 18.0
@export var rotation_speed: float = 1200.0 # Graus por segundo de rotação da serra
@export var knockback_force: float = 5.0

@onready var visual_pivot: Node3D = $VisualPivot
@onready var robot_body: Node3D = $VisualPivot/GrassBot/Robot/Body if has_node("VisualPivot/GrassBot/Robot/Body") else null
@onready var wheel_mesh: MeshInstance3D = $VisualPivot/GrassBot/Robot/Body/wheel if has_node("VisualPivot/GrassBot/Robot/Body/wheel") else null
@onready var blade_spinner: Node3D = $VisualPivot/GrassBot/Robot/BladeSpinner if has_node("VisualPivot/GrassBot/Robot/BladeSpinner") else null
@onready var blade_tier_1: MeshInstance3D = $VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_1 if has_node("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_1") else null
@onready var blade_tier_2: MeshInstance3D = $VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_2 if has_node("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_2") else null
@onready var blade_tier_3: MeshInstance3D = $VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_3 if has_node("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_3") else null

@onready var blade_area: Area3D = $BladeArea
@onready var blade_shape: CollisionShape3D = $BladeArea/CollisionShape3D
@onready var spark_particles: CPUParticles3D = $SparkParticles

var input_direction: Vector2 = Vector2.ZERO
var is_stunned: bool = false
var stun_timer: float = 0.0

func _ready() -> void:
	if robot_body:
		robot_body.rotation.y = PI
	update_upgrades()
	_update_shader_globals()
	if UpgradeManager != null:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
	if GameManager != null:
		GameManager.state_changed.connect(_on_game_state_changed)

func _on_game_state_changed(new_state: int) -> void:
	if new_state != GameManager.GameState.PLAYING:
		velocity = Vector3.ZERO
		input_direction = Vector2.ZERO

func _process(_delta: float) -> void:
	_update_shader_globals()

const GRASS_MAT: ShaderMaterial = preload("res://shaders/interactive_grass_material.tres")
const WHEAT_MAT: ShaderMaterial = preload("res://shaders/interactive_wheat_material.tres")
const FLOWER_MAT: ShaderMaterial = preload("res://shaders/interactive_flower_material.tres")

func _update_shader_globals() -> void:
	var blade_radius: float = 1.18
	if UpgradeManager != null:
		blade_radius = UpgradeManager.get_blade_radius()
	var interact_radius: float = blade_radius + 0.95

	if GRASS_MAT:
		GRASS_MAT.set_shader_parameter("cutter_pos", global_position)
		GRASS_MAT.set_shader_parameter("cutter_interact_radius", interact_radius)
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
		return
	
	# Atualiza raio da área física de corte
	var radius: float = UpgradeManager.get_blade_radius()
	if blade_shape.shape is CylinderShape3D:
		blade_shape.shape.radius = radius
	elif blade_shape.shape is SphereShape3D:
		blade_shape.shape.radius = radius
	
	# Escala da malha visual da serra para refletir o upgrade de raio (base 1.18m)
	var visual_scale: float = radius / 1.18
	if blade_spinner:
		blade_spinner.scale = Vector3(visual_scale, 1.0, visual_scale)
	
	_update_blade_tier_visual()

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
		return

	# Rotação contínua de alta velocidade da serra circular (eixo Y)
	if blade_spinner:
		blade_spinner.rotate_y(deg_to_rad(rotation_speed * delta))

	# Gerenciamento de choque / ricochete
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0.0:
			is_stunned = false
		# Aplica atrito durante o recuo
		velocity = velocity.move_toward(Vector3.ZERO, friction * 2.0 * delta)
		move_and_slide()
		_check_obstacle_collisions()
		return

	# Movimento omnidirecional responsivo baseado na entrada
	var target_speed: float = base_speed
	if UpgradeManager != null:
		target_speed = UpgradeManager.get_cutter_speed()

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

	move_and_slide()
	_check_obstacle_collisions()
	_process_cutting()

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
	
	# Efeito de faíscas
	if spark_particles:
		spark_particles.global_position = global_position - normal * 0.4
		spark_particles.restart()

	# Vibração de impacto
	if GameManager != null:
		GameManager.trigger_haptic_impact()

func _process_cutting() -> void:
	if blade_area == null:
		return
	
	var cutting_power: int = 1
	if UpgradeManager != null:
		cutting_power = UpgradeManager.get_cutter_power()

	var overlapping_areas: Array[Area3D] = blade_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("vegetation"):
			var plant: Node = area.get_parent()
			if plant and plant.has_method("cut"):
				plant.cut(cutting_power)
