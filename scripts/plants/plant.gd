extends Node3D

enum PlantType { GRASS, WHEAT, FLOWER }

@export var type: PlantType = PlantType.GRASS
@export var max_health: int = 1
@export var coin_reward: int = 1
@export var plant_key: String = "grass" # Usado para sincronizar com as metas do HUD

var health: int = 1
var is_cut: bool = false

@onready var visual_mesh: Node3D = $VisualMesh
@onready var cut_particles: CPUParticles3D = $CutParticles
@onready var area: Area3D = $Area3D
@onready var area_shape: CollisionShape3D = $Area3D/CollisionShape3D

func _ready() -> void:
	health = max_health
	# Leve variação aleatória de escala e rotação para aspecto natural Low Poly
	var random_rot: float = randf_range(0.0, TAU)
	var random_scale: float = randf_range(0.85, 1.15)
	visual_mesh.rotation.y = random_rot
	visual_mesh.scale = Vector3(random_scale, random_scale, random_scale)

func cut(power: int) -> void:
	if is_cut:
		return

	health -= power
	if health <= 0:
		_perform_cut()
	else:
		# Feedback de dano para plantas resistentes
		var tween = create_tween()
		tween.tween_property(visual_mesh, "scale", visual_mesh.scale * 1.25, 0.05)
		tween.tween_property(visual_mesh, "scale", visual_mesh.scale, 0.05)

func _perform_cut() -> void:
	is_cut = true
	if area_shape:
		area_shape.set_deferred("disabled", true)

	# Lança partículas em arco parabólico
	if cut_particles:
		cut_particles.restart()

	# Notifica o GameManager
	if GameManager != null:
		GameManager.register_cut(plant_key, coin_reward)

	# Efeito visual de colheita rápida
	var tween = create_tween()
	tween.tween_property(visual_mesh, "scale", Vector3(1.3, 0.2, 1.3), 0.06)
	tween.tween_property(visual_mesh, "scale", Vector3.ZERO, 0.08)
	tween.tween_callback(func():
		visual_mesh.visible = false
	)

	# Destrói o nó após o término das partículas
	get_tree().create_timer(1.2).timeout.connect(func():
		queue_free()
	)
