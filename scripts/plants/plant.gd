extends Node3D

enum PlantType { GRASS, WHEAT, FLOWER }
enum GrassVariation { GREEN, YELLOW, BLUE, PURPLE, RANDOM }

@export var type: PlantType = PlantType.GRASS
@export var grass_variation: GrassVariation = GrassVariation.GREEN
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
	_apply_grass_variation()
	# Leve variação aleatória de escala e rotação para aspecto natural Low Poly
	var random_rot: float = randf_range(0.0, TAU)
	var random_scale: float = randf_range(0.85, 1.15)
	visual_mesh.rotation.y = random_rot
	visual_mesh.scale = Vector3(random_scale, random_scale, random_scale)

const GRASS_MAT_GREEN: ShaderMaterial = preload("res://shaders/interactive_grass_material.tres")
const GRASS_MAT_YELLOW: ShaderMaterial = preload("res://shaders/interactive_grass_yellow_material.tres")
const GRASS_MAT_BLUE: ShaderMaterial = preload("res://shaders/interactive_grass_blue_material.tres")
const GRASS_MAT_PURPLE: ShaderMaterial = preload("res://shaders/interactive_grass_purple_material.tres")

func _apply_grass_variation() -> void:
	if type != PlantType.GRASS:
		return

	var model: Node3D = visual_mesh.get_node_or_null("Grass01") as Node3D
	if model == null:
		return

	var chosen_variant: GrassVariation = grass_variation
	if chosen_variant == GrassVariation.RANDOM:
		var rand_idx: int = randi() % 4
		chosen_variant = rand_idx as GrassVariation

	var blue_node: Node3D = model.get_node_or_null("grass_blue") as Node3D
	var green_node: Node3D = model.get_node_or_null("grass_green") as Node3D
	var purple_node: Node3D = model.get_node_or_null("grass_purple") as Node3D
	var yellow_node: Node3D = model.get_node_or_null("grass_yellow") as Node3D

	if blue_node:
		blue_node.visible = (chosen_variant == GrassVariation.BLUE)
		if blue_node is MeshInstance3D:
			(blue_node as MeshInstance3D).material_override = GRASS_MAT_BLUE
	if green_node:
		green_node.visible = (chosen_variant == GrassVariation.GREEN)
		if green_node is MeshInstance3D:
			(green_node as MeshInstance3D).material_override = GRASS_MAT_GREEN
	if purple_node:
		purple_node.visible = (chosen_variant == GrassVariation.PURPLE)
		if purple_node is MeshInstance3D:
			(purple_node as MeshInstance3D).material_override = GRASS_MAT_PURPLE
	if yellow_node:
		yellow_node.visible = (chosen_variant == GrassVariation.YELLOW)
		if yellow_node is MeshInstance3D:
			(yellow_node as MeshInstance3D).material_override = GRASS_MAT_YELLOW

	if cut_particles and chosen_variant != GrassVariation.GREEN and cut_particles.mesh:
		var base_mat: StandardMaterial3D = cut_particles.mesh.material as StandardMaterial3D
		if base_mat:
			var custom_mat: StandardMaterial3D = base_mat.duplicate() as StandardMaterial3D
			match chosen_variant:
				GrassVariation.YELLOW: custom_mat.albedo_color = Color(0.95, 0.75, 0.15, 1.0)
				GrassVariation.BLUE: custom_mat.albedo_color = Color(0.20, 0.60, 0.95, 1.0)
				GrassVariation.PURPLE: custom_mat.albedo_color = Color(0.65, 0.25, 0.95, 1.0)
			var box: BoxMesh = cut_particles.mesh.duplicate() as BoxMesh
			box.material = custom_mat
			cut_particles.mesh = box

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
