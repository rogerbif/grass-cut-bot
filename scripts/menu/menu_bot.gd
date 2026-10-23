extends Node3D

## Robô Apresentador do Menu Principal (Aba Home)
## Possui locomoção autônoma (avanço de meio metro, marcha à ré e curvas),
## articulação expressiva da cabeça, apoio firme no solo e expressões randômicas de LED.

enum BotState {
	IDLE,
	MOVE_FORWARD,
	LOOK_AROUND,
	MOVE_BACKWARD,
	RESET_ALIGN
}

const TELEPORT_SHADER: Shader = preload("res://shaders/teleport_effect.gdshader")

@export var blade_rotation_speed: float = 75.0 # Graus por segundo de rotação suave da lâmina
@export var move_distance: float = 0.50          # Distância máxima de avanço frontal (meio metro)
@export var drive_speed: float = 0.42           # Velocidade de deslocamento suave na ilha (m/s)

var current_state: BotState = BotState.IDLE
var base_position: Vector3 = Vector3.ZERO
var current_drive_offset: float = 0.0
var target_drive_offset: float = 0.0

# Teleporte entre ilhas
var is_teleporting: bool = false
var _teleport_tween: Tween = null
var _teleport_materials: Array[ShaderMaterial] = []
var _mesh_surface_targets: Array[Dictionary] = []
var teleport_progress: float = 0.0:
	set(value):
		teleport_progress = value
		for mat: ShaderMaterial in _teleport_materials:
			mat.set_shader_parameter("progress", value)

# Temporizadores de máquina de estados
var _state_timer: float = 0.0
var _turn_target_yaw: float = 0.0

# Articulação da cabeça
var _head_timer: float = 0.0
var _target_head_yaw: float = 0.0
var _target_head_pitch: float = 0.0

# Expressões randômicas
var _expression_timer: float = 0.0

@onready var visual_pivot: Node3D = $VisualPivot if has_node("VisualPivot") else self
@onready var robot_body: Node3D = get_node_or_null("VisualPivot/GrassBot/Robot/Body") as Node3D
@onready var head_node: Node3D = get_node_or_null("VisualPivot/GrassBot/Robot/Body/head") as Node3D
@onready var wheel_mesh: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/Body/wheel") as MeshInstance3D
@onready var blade_spinner: Node3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner") as Node3D
@onready var robot_eyes: RobotEyes = get_node_or_null("RobotEyes") as RobotEyes

@onready var blade_tier_1: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_1") as MeshInstance3D
@onready var blade_tier_2: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_2") as MeshInstance3D
@onready var blade_tier_3: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_3") as MeshInstance3D
@onready var blade_tier_4: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_4") as MeshInstance3D

func _ready() -> void:
	base_position = position
	if robot_body != null:
		robot_body.rotation.y = 0.0 # Rosto e serra voltados para a câmera do menu

	_setup_eyes()
	update_blade_tier()
	_reset_state_timer(randf_range(2.0, 3.5))
	_reset_head_timer(randf_range(1.0, 2.5))
	_reset_expression_timer(randf_range(3.0, 6.0))

	if UpgradeManager != null:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)

func _setup_eyes() -> void:
	if robot_eyes == null:
		return

	var screen_mesh: MeshInstance3D = null
	if head_node != null:
		screen_mesh = head_node.find_child("screen_display*", true, false) as MeshInstance3D
	if screen_mesh == null and visual_pivot != null:
		screen_mesh = visual_pivot.find_child("screen_display*", true, false) as MeshInstance3D

	if screen_mesh != null:
		var eye_mat: Material = preload("res://shaders/eye_display_material.tres")
		screen_mesh.set_surface_override_material(0, eye_mat)
		robot_eyes.screen_mesh = screen_mesh
		robot_eyes._ready()
		robot_eyes.set_expression(RobotEyes.EyeExpression.NORMAL)

func _process(delta: float) -> void:
	# 1. Rotação suave contínua da lâmina em marcha lenta
	if blade_spinner != null:
		blade_spinner.rotate_y(deg_to_rad(blade_rotation_speed * delta))

	if is_teleporting:
		return

	# 2. Condução física e máquina de estados de locomoção
	_process_locomotion(delta)

	# 3. Articulação expressiva autônoma da cabeça
	_process_head_motion(delta)

	# 4. Alternância randômica de humores e expressões nos olhos de LED
	_process_random_expressions(delta)

func _process_locomotion(delta: float) -> void:
	_state_timer -= delta

	var effective_wheel_radius: float = 0.45 * 0.62 # Raio com a escala visual 0.62x
	var previous_offset: float = current_drive_offset

	match current_state:
		BotState.IDLE:
			target_drive_offset = 0.0
			current_drive_offset = move_toward(current_drive_offset, target_drive_offset, drive_speed * delta)
			if _state_timer <= 0.0:
				current_state = BotState.MOVE_FORWARD
				target_drive_offset = move_distance
				_reset_state_timer(randf_range(3.0, 4.5))

		BotState.MOVE_FORWARD:
			current_drive_offset = move_toward(current_drive_offset, target_drive_offset, drive_speed * delta)
			if is_equal_approx(current_drive_offset, target_drive_offset) or _state_timer <= 0.0:
				current_state = BotState.LOOK_AROUND
				_turn_target_yaw = deg_to_rad(randf_range(-22.0, 22.0))
				_reset_state_timer(randf_range(2.5, 4.0))
				if robot_eyes != null:
					robot_eyes.set_expression(RobotEyes.EyeExpression.HAPPY, Color.TRANSPARENT, 2.0)

		BotState.LOOK_AROUND:
			# Gira suavemente o chassi explorando os lados da ilha
			if robot_body != null:
				robot_body.rotation.y = lerp_angle(robot_body.rotation.y, _turn_target_yaw, delta * 3.0)
			if _state_timer <= 0.0:
				current_state = BotState.MOVE_BACKWARD
				target_drive_offset = 0.0
				_reset_state_timer(randf_range(3.0, 4.5))

		BotState.MOVE_BACKWARD:
			# Retorna de ré para a posição base
			if robot_body != null:
				robot_body.rotation.y = lerp_angle(robot_body.rotation.y, 0.0, delta * 4.0)
			current_drive_offset = move_toward(current_drive_offset, target_drive_offset, drive_speed * 0.85 * delta)
			if is_equal_approx(current_drive_offset, target_drive_offset) or _state_timer <= 0.0:
				current_state = BotState.RESET_ALIGN
				_reset_state_timer(1.2)

		BotState.RESET_ALIGN:
			if robot_body != null:
				robot_body.rotation.y = lerp_angle(robot_body.rotation.y, 0.0, delta * 5.0)
			if _state_timer <= 0.0:
				current_state = BotState.IDLE
				_reset_state_timer(randf_range(3.5, 6.0))

	# Aplica deslocamento frontal sem flutuar (Y permanece estritamente fixo no piso da ilha)
	position = base_position + Vector3(0.0, 0.0, current_drive_offset)

	# Rotação física da mono-wheel correspondente ao deslocamento real
	var delta_dist: float = current_drive_offset - previous_offset
	if wheel_mesh != null and absf(delta_dist) > 0.0001:
		var roll_angle: float = delta_dist / effective_wheel_radius
		wheel_mesh.rotate_x(roll_angle)

	# Pitch e Roll inerciais no chassi ao acelerar ou frear
	if robot_body != null:
		var target_pitch: float = 0.0
		if current_state == BotState.MOVE_FORWARD:
			target_pitch = deg_to_rad(3.5) # Leve inclinação para frente
		elif current_state == BotState.MOVE_BACKWARD:
			target_pitch = deg_to_rad(-2.8) # Leve inclinação para trás na ré
		robot_body.rotation.x = lerp(robot_body.rotation.x, target_pitch, delta * 6.0)

func _process_head_motion(delta: float) -> void:
	if head_node == null:
		return

	_head_timer -= delta
	if _head_timer <= 0.0:
		# Sorteia novo ângulo horizontal (yaw: olhar para os lados)
		_target_head_yaw = deg_to_rad(randf_range(-26.0, 26.0))
		# Sorteia inclinação vertical (pitch: olhar para cima ou para baixo)
		_target_head_pitch = deg_to_rad(randf_range(-14.0, 10.0))
		_reset_head_timer(randf_range(1.8, 3.8))

		# Informa o controlador de olhos para mover as pupilas na direção do olhar
		if robot_eyes != null:
			var look_vec: Vector2 = Vector2(_target_head_yaw * 1.5, _target_head_pitch * 2.0)
			robot_eyes.set_look_direction(look_vec)

	head_node.rotation.y = lerp_angle(head_node.rotation.y, _target_head_yaw, delta * 4.5)
	head_node.rotation.x = lerp_angle(head_node.rotation.x, _target_head_pitch, delta * 4.5)

func _process_random_expressions(delta: float) -> void:
	if robot_eyes == null:
		return

	_expression_timer -= delta
	if _expression_timer <= 0.0:
		var expressions_pool: Array[RobotEyes.EyeExpression] = [
			RobotEyes.EyeExpression.NORMAL,
			RobotEyes.EyeExpression.HAPPY,
			RobotEyes.EyeExpression.ALERT,
			RobotEyes.EyeExpression.WINK,
			RobotEyes.EyeExpression.VICTORY
		]
		var next_expr: RobotEyes.EyeExpression = expressions_pool[randi() % expressions_pool.size()]
		var dur: float = randf_range(2.0, 4.0)
		robot_eyes.set_expression(next_expr, Color.TRANSPARENT, dur)
		_reset_expression_timer(randf_range(4.5, 8.5))

func _reset_state_timer(seconds: float) -> void:
	_state_timer = seconds

func _reset_head_timer(seconds: float) -> void:
	_head_timer = seconds

func _reset_expression_timer(seconds: float) -> void:
	_expression_timer = seconds

func update_blade_tier() -> void:
	var active_tier: int = 1
	if UpgradeManager != null:
		active_tier = UpgradeManager.get_blade_tier()

	if blade_tier_1 != null:
		blade_tier_1.visible = (active_tier == 1)
	if blade_tier_2 != null:
		blade_tier_2.visible = (active_tier == 2)
	if blade_tier_3 != null:
		blade_tier_3.visible = (active_tier == 3)
	if blade_tier_4 != null:
		blade_tier_4.visible = (active_tier == 4)

func _on_upgrade_purchased(_upgrade_name: String, _new_level: int) -> void:
	update_blade_tier()

func set_base_position(new_pos: Vector3) -> void:
	base_position = new_pos
	position = new_pos

# -----------------------------------------------------------------------------
# Efeito de Teleporte (Spatial Shader Bidirecional de Desintegração / Materialização)
# -----------------------------------------------------------------------------

func _set_teleport_mode(m: int) -> void:
	for mat: ShaderMaterial in _teleport_materials:
		mat.set_shader_parameter("mode", m)

func _set_teleport_world_y(y: float) -> void:
	for mat: ShaderMaterial in _teleport_materials:
		mat.set_shader_parameter("bot_world_y", y)

func _collect_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var list: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		list.append(node as MeshInstance3D)
	for child: Node in node.get_children():
		list.append_array(_collect_mesh_instances(child))
	return list

func _apply_teleport_materials() -> void:
	_clear_teleport_materials()
	var meshes: Array[MeshInstance3D] = _collect_mesh_instances(visual_pivot)
	for mesh_inst: MeshInstance3D in meshes:
		if mesh_inst.mesh == null:
			continue
		var surf_count: int = mesh_inst.mesh.get_surface_count()
		for s: int in range(surf_count):
			var active_mat: Material = mesh_inst.get_active_material(s)
			var sm: ShaderMaterial = ShaderMaterial.new()
			sm.shader = TELEPORT_SHADER
			if active_mat is StandardMaterial3D:
				var std: StandardMaterial3D = active_mat as StandardMaterial3D
				sm.set_shader_parameter("albedo_color", std.albedo_color)
				if std.albedo_texture != null:
					sm.set_shader_parameter("albedo_texture", std.albedo_texture)
					sm.set_shader_parameter("use_texture", true)
				sm.set_shader_parameter("metallic", std.metallic)
				sm.set_shader_parameter("roughness", std.roughness)
				sm.set_shader_parameter("emission_color", std.emission)
				sm.set_shader_parameter("emission_energy", std.emission_energy_multiplier)
			elif active_mat is ShaderMaterial:
				# Ex: tela de LED dos olhos
				sm.set_shader_parameter("albedo_color", Color(0.17, 0.89, 1.0, 1.0))
				sm.set_shader_parameter("emission_color", Color(0.17, 0.89, 1.0, 1.0))
				sm.set_shader_parameter("emission_energy", 2.2)
			else:
				sm.set_shader_parameter("albedo_color", Color.WHITE)
				sm.set_shader_parameter("roughness", 0.85)

			mesh_inst.set_surface_override_material(s, sm)
			_teleport_materials.append(sm)
			_mesh_surface_targets.append({
				"mesh": mesh_inst,
				"surface": s
			})

func _clear_teleport_materials() -> void:
	for rec: Dictionary in _mesh_surface_targets:
		var m: MeshInstance3D = rec.get("mesh", null) as MeshInstance3D
		var s: int = int(rec.get("surface", 0))
		if is_instance_valid(m):
			m.set_surface_override_material(s, null)
	_teleport_materials.clear()
	_mesh_surface_targets.clear()
	_setup_eyes()

func teleport_to_position(target_pos: Vector3, on_complete: Callable = Callable()) -> void:
	# Se já estiver praticamente na mesma posição e não estiver no meio de um teleporte, ignora
	if not is_teleporting and position.distance_squared_to(target_pos) < 0.04:
		if on_complete.is_valid():
			on_complete.call()
		return

	if _teleport_tween != null and _teleport_tween.is_valid():
		_teleport_tween.kill()

	is_teleporting = true
	current_state = BotState.IDLE
	current_drive_offset = 0.0
	target_drive_offset = 0.0

	# Alinha suavemente o corpo e a cabeça para frente durante o teleporte
	if robot_body != null:
		robot_body.rotation.y = 0.0
		robot_body.rotation.x = 0.0
	if head_node != null:
		head_node.rotation.y = 0.0
		head_node.rotation.x = 0.0

	_apply_teleport_materials()
	_set_teleport_world_y(global_position.y)
	_set_teleport_mode(0) # 0 = Desaparecendo de cima para baixo
	teleport_progress = 0.0

	if AudioManager != null:
		AudioManager.play_sfx("fast_forward")

	_teleport_tween = create_tween()
	# 1. Desaparece de cima para baixo
	_teleport_tween.tween_property(self, "teleport_progress", 1.0, 0.36).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	# 2. Transição instantânea enquanto 100% invisível
	_teleport_tween.tween_callback(func() -> void:
		set_base_position(target_pos)
		_set_teleport_world_y(target_pos.y)
		_set_teleport_mode(1) # 1 = Aparecendo de baixo para cima
		teleport_progress = 0.0
		if AudioManager != null:
			AudioManager.play_sfx("power_up")
	)

	# 3. Aparece de baixo para cima na nova ilha
	_teleport_tween.tween_property(self, "teleport_progress", 1.0, 0.40).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# 4. Finalização e restauração dos materiais e estado
	_teleport_tween.tween_callback(func() -> void:
		_clear_teleport_materials()
		is_teleporting = false
		_reset_state_timer(randf_range(2.0, 3.5))
		if on_complete.is_valid():
			on_complete.call()
	)
