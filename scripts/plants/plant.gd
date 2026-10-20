extends Node3D

enum PlantType { GRASS, WHEAT, FLOWER }

@export var type: PlantType = PlantType.GRASS
@export var max_health: int = 1
@export var coin_reward: int = 1
@export var plant_key: String = "grass" # Usado para sincronizar com as metas do HUD
@export var custom_material: Material

var health: int = 1
var is_cut: bool = false

@onready var visual_mesh: Node3D = $VisualMesh
@onready var cut_particles: CPUParticles3D = $CutParticles
@onready var area: Area3D = $Area3D
@onready var area_shape: CollisionShape3D = $Area3D/CollisionShape3D

func _ready() -> void:
	health = max_health
	# Variação proporcional de rotação e escala para gramado contínuo e denso sem folga livre
	var random_rot: float = randf_range(0.0, TAU)
	visual_mesh.rotation.y = random_rot

	# Garante que todo MeshInstance3D receba o material configurado ou fallback verde vivo
	_apply_visual_material(visual_mesh)

	if type == PlantType.GRASS:
		# Padrão de gramado condensado: diâmetro horizontal (X/Z) calibrado em 50% (0.40 ~ 0.45m)
		# para corresponder ao diâmetro exato da célula reduzida (0.40m),
		# eliminando qualquer folga livre entre as folhas e mantendo altura compacta (-25%: 0.53 ~ 0.64m).
		var scale_y: float = randf_range(0.53, 0.64)
		var scale_xz: float = randf_range(0.40, 0.45)
		visual_mesh.scale = Vector3(scale_xz, scale_y, scale_xz)
	else:
		# Flores e trigo proporcionais ao slot de célula de 0.40m
		var random_scale: float = randf_range(0.48, 0.58)
		visual_mesh.scale = Vector3(random_scale, random_scale, random_scale)

func _apply_visual_material(target: Node) -> void:
	if target == null:
		return
	if target is MeshInstance3D:
		var mi: MeshInstance3D = target as MeshInstance3D
		if custom_material != null:
			mi.material_override = custom_material
		elif mi.material_override == null:
			var fallback_mat: StandardMaterial3D = StandardMaterial3D.new()
			fallback_mat.albedo_color = Color(0.22, 0.68, 0.24, 1.0)
			fallback_mat.roughness = 0.9
			mi.material_override = fallback_mat
	for child in target.get_children():
		_apply_visual_material(child)

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

	# Fatiamento ágil e imediato: corte seco sem sensação de balão murchando
	var tween = create_tween()
	tween.tween_property(visual_mesh, "scale", visual_mesh.scale * Vector3(1.05, 0.05, 1.05), 0.04)
	tween.tween_callback(func():
		visual_mesh.visible = false
	)

	# Destrói o nó após o término das partículas
	get_tree().create_timer(1.0).timeout.connect(func():
		queue_free()
	)
