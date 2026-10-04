extends Camera3D

@export var target_path: NodePath
@export var offset: Vector3 = Vector3(0.0, 11.0, 7.5)
@export var follow_speed: float = 8.0

var target: Node3D
var shake_intensity: float = 0.0
var shake_duration: float = 0.0

func _ready() -> void:
	if has_node(target_path):
		target = get_node(target_path) as Node3D

	if GameManager != null:
		GameManager.camera_shake_requested.connect(_on_shake_requested)

	# Configura orientação isométrica elevada
	look_at_from_position(global_position, global_position - offset, Vector3.UP)

func _on_shake_requested(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_duration = duration

func _process(delta: float) -> void:
	if not target:
		return

	var desired_pos = target.global_position + offset
	global_position = global_position.lerp(desired_pos, follow_speed * delta)

	# Aplica camera shake se ativo
	if shake_duration > 0.0:
		shake_duration -= delta
		var shake_offset = Vector3(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity) * 0.5,
			randf_range(-shake_intensity, shake_intensity)
		)
		global_position += shake_offset
		if shake_duration <= 0.0:
			shake_intensity = 0.0

	# Mantém a rotação focada no ponto à frente do cortador
	var look_target = target.global_position + Vector3(0, 0, -0.5)
	look_at(look_target, Vector3.UP)
