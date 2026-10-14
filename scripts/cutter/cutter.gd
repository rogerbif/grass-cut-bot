extends CharacterBody3D

@export var base_speed: float = 6.5
@export var acceleration: float = 24.0
@export var friction: float = 18.0
@export var rotation_speed: float = 1200.0 # Graus por segundo de rotação da serra
@export var knockback_force: float = 5.0

@onready var visual_pivot: Node3D = $VisualPivot
@onready var saw_mesh: Node3D = $VisualPivot/SawMesh
@onready var blade_area: Area3D = $BladeArea
@onready var blade_shape: CollisionShape3D = $BladeArea/CollisionShape3D
@onready var spark_particles: CPUParticles3D = $SparkParticles

var input_direction: Vector2 = Vector2.ZERO
var is_stunned: bool = false
var stun_timer: float = 0.0

func _ready() -> void:
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
	var blade_radius: float = 0.65
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
	if upgrade_name == "radius" or upgrade_name == "speed":
		update_upgrades()

func update_upgrades() -> void:
	if UpgradeManager == null:
		return
	
	# Atualiza raio da lâmina
	var radius := UpgradeManager.get_blade_radius()
	if blade_shape.shape is CylinderShape3D:
		blade_shape.shape.radius = radius
	elif blade_shape.shape is SphereShape3D:
		blade_shape.shape.radius = radius
	
	# Escala sutil da malha visual da lâmina para refletir o upgrade
	var visual_scale = radius / 0.65
	if saw_mesh:
		saw_mesh.scale = Vector3(visual_scale, 1.0, visual_scale)

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
	if saw_mesh:
		saw_mesh.rotate_y(deg_to_rad(rotation_speed * delta))

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
	var target_speed = base_speed
	if UpgradeManager != null:
		target_speed = UpgradeManager.get_cutter_speed()

	# Converte a direção 2D (da tela isométrica) para coordenadas de mundo 3D
	# Ajustamos para a perspectiva isométrica (diagonal suave ou direta)
	var move_dir = Vector3(input_direction.x, 0.0, input_direction.y)
	if move_dir.length_squared() > 0.001:
		var target_vel = move_dir * target_speed
		velocity = velocity.move_toward(target_vel, acceleration * delta)
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)

	move_and_slide()
	_check_obstacle_collisions()
	_process_cutting()

func _check_obstacle_collisions() -> void:
	var count = get_slide_collision_count()
	for i in range(count):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()
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
	
	var cutting_power = 1
	if UpgradeManager != null:
		cutting_power = UpgradeManager.get_cutter_power()

	var overlapping_areas = blade_area.get_overlapping_areas()
	for area in overlapping_areas:
		if area.is_in_group("vegetation"):
			var plant = area.get_parent()
			if plant and plant.has_method("cut"):
				plant.cut(cutting_power)
