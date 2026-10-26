extends Node3D

enum PlantType { GRASS, WHEAT, FLOWER }

const POOL_SIZE: int = 16
const LEAF_MESH: ArrayMesh = preload("res://assets/models/cut_leaf_piece.obj")
static var _petal_mesh: Mesh = null

static var _particle_pool: Array[CPUParticles3D] = []
static var _pool_idx: int = 0
static var _particle_materials: Dictionary = {}
static var _scale_curve: Curve = null
static var _fallback_material: StandardMaterial3D = null

@export var type: PlantType = PlantType.GRASS
@export var max_health: int = 1
@export var coin_reward: int = 1
@export var plant_key: String = "grass" # Usado para sincronizar com as metas do HUD
@export var custom_material: Material
@export var particle_color: Color = Color(0.25, 0.75, 0.3, 1.0)

var health: int = 1
var is_cut: bool = false
var _last_hit_time: float = -10.0

@onready var visual_mesh: Node3D = $VisualMesh
@onready var area: Area3D = $Area3D
@onready var area_shape: CollisionShape3D = $Area3D/CollisionShape3D

func _ready() -> void:
	health = max_health
	# Variação proporcional de rotação e escala para gramado contínuo e denso sem folga livre
	var random_rot: float = randf_range(0.0, TAU)
	visual_mesh.rotation.y = random_rot

	# Garante que todo MeshInstance3D tenha sombra desligada e receba o material configurado
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

static func _get_petal_mesh() -> Mesh:
	if _petal_mesh == null:
		var scene: PackedScene = load("res://assets/models/cut_petal_piece.glb")
		if scene != null:
			var inst: Node = scene.instantiate()
			var mi: MeshInstance3D = inst.find_child("*", true, false) as MeshInstance3D
			if mi != null:
				_petal_mesh = mi.mesh
			inst.free()
		if _petal_mesh == null:
			_petal_mesh = LEAF_MESH
	return _petal_mesh

func _apply_visual_material(target: Node) -> void:
	if target == null:
		return
	if target is MeshInstance3D:
		var mi: MeshInstance3D = target as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if type == PlantType.FLOWER:
			# Para flores com 2 slots (0: Caule Verde, 1: Pétalas Customizáveis)
			if custom_material != null:
				mi.set_surface_override_material(1, custom_material)
		else:
			if custom_material != null:
				if mi.material_override != custom_material:
					mi.material_override = custom_material
			elif mi.material_override == null and mi.get_active_material(0) == null:
				if _fallback_material == null:
					_fallback_material = StandardMaterial3D.new()
					_fallback_material.albedo_color = Color(0.22, 0.68, 0.24, 1.0)
					_fallback_material.roughness = 0.9
				mi.material_override = _fallback_material
	for child in target.get_children():
		_apply_visual_material(child)

func cut(power: int) -> void:
	if is_cut:
		return

	var now_sec: float = float(Time.get_ticks_msec()) * 0.001
	if max_health > 1 and (now_sec - _last_hit_time) < 1.0:
		return
	_last_hit_time = now_sec

	health -= power
	if health <= 0:
		_perform_cut()
	else:
		if type == PlantType.FLOWER:
			_apply_flower_damage_stage(health)

		# Feedback de dano para plantas resistentes
		var tween: Tween = create_tween()
		tween.tween_property(visual_mesh, "scale", visual_mesh.scale * 1.25, 0.05)
		tween.tween_property(visual_mesh, "scale", visual_mesh.scale, 0.05)

func _apply_flower_damage_stage(remaining_hp: int) -> void:
	var stage: float = 1.0 if remaining_hp == 2 else 2.0
	_set_flower_stage_recursive(visual_mesh, stage)
	_spawn_petal_burst(6)

func _set_flower_stage_recursive(target: Node, stage: float) -> void:
	if target is GeometryInstance3D:
		(target as GeometryInstance3D).set_instance_shader_parameter("instance_hit_stage", stage)
	for child in target.get_children():
		_set_flower_stage_recursive(child, stage)

func _perform_cut() -> void:
	is_cut = true
	if area_shape:
		area_shape.set_deferred("disabled", true)

	# Lança partículas em arco parabólico via Pool Estático Compartilhado
	_spawn_cut_particles()

	# Notifica o GameManager
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("register_cut"):
		gm.call("register_cut", plant_key, coin_reward, global_position)

	# Fatiamento ágil e imediato: corte seco e destruição imediata do nó
	var tween: Tween = create_tween()
	tween.tween_property(visual_mesh, "scale", visual_mesh.scale * Vector3(1.05, 0.05, 1.05), 0.04)
	tween.tween_callback(queue_free)

func _resolve_particle_color() -> Color:
	if custom_material is ShaderMaterial:
		var sm: ShaderMaterial = custom_material as ShaderMaterial
		var petal_variant: Variant = sm.get_shader_parameter("petal_color")
		if petal_variant is Color:
			return petal_variant as Color
		var col_variant: Variant = sm.get_shader_parameter("color_top")
		if col_variant is Color:
			return col_variant as Color
	if type == PlantType.WHEAT:
		return Color(0.96, 0.75, 0.15, 1.0)
	if type == PlantType.FLOWER:
		return Color(0.92, 0.22, 0.58, 1.0)
	return particle_color

func _spawn_petal_burst(amount: int = 6) -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return

	if _particle_pool.is_empty() or not is_instance_valid(_particle_pool[0]) or not _particle_pool[0].is_inside_tree():
		_init_particle_pool(scene_root)

	var emitter: CPUParticles3D = _particle_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE

	var col: Color = _resolve_particle_color()
	emitter.mesh = _get_petal_mesh()
	emitter.amount = amount
	emitter.emitting = false
	emitter.material_override = _get_or_create_particle_material(col)
	emitter.global_position = global_position + Vector3(0.0, 0.25, 0.0)
	emitter.reset_physics_interpolation()
	emitter.restart()

func _spawn_cut_particles() -> void:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return

	if _particle_pool.is_empty() or not is_instance_valid(_particle_pool[0]) or not _particle_pool[0].is_inside_tree():
		_init_particle_pool(scene_root)

	var emitter: CPUParticles3D = _particle_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE

	var col: Color = _resolve_particle_color()
	emitter.emitting = false
	emitter.material_override = _get_or_create_particle_material(col)
	emitter.global_position = global_position + Vector3(0.0, 0.15, 0.0)
	emitter.reset_physics_interpolation()
	emitter.restart()

static func _get_or_create_particle_material(col: Color) -> StandardMaterial3D:
	var key: String = col.to_html(false)
	if _particle_materials.has(key):
		return _particle_materials[key] as StandardMaterial3D
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.9
	mat.albedo_color = col
	_particle_materials[key] = mat
	return mat

static func _init_particle_pool(scene_root: Node) -> void:
	_particle_pool.clear()
	_pool_idx = 0

	if _scale_curve == null:
		_scale_curve = Curve.new()
		_scale_curve.add_point(Vector2(0.0, 0.8))
		_scale_curve.add_point(Vector2(0.15, 1.0))
		_scale_curve.add_point(Vector2(0.65, 1.0))
		_scale_curve.add_point(Vector2(1.0, 0.0), -3.0, 0.0)

	for i: int in range(POOL_SIZE):
		var p: CPUParticles3D = CPUParticles3D.new()
		p.name = "PooledCutParticles_%d" % i
		p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.emitting = false
		p.amount = 14
		p.lifetime = 0.42
		p.one_shot = true
		p.explosiveness = 0.95
		p.mesh = LEAF_MESH
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_RING
		p.emission_ring_axis = Vector3(0.0, 1.0, 0.0)
		p.emission_ring_height = 0.08
		p.emission_ring_radius = 0.18
		p.emission_ring_inner_radius = 0.0
		p.particle_flag_rotate_y = true
		p.direction = Vector3(0.0, 1.0, 0.0)
		p.spread = 85.0
		p.gravity = Vector3(0.0, -9.8, 0.0)
		p.initial_velocity_min = 2.0
		p.initial_velocity_max = 3.6
		p.angular_velocity_min = -540.0
		p.angular_velocity_max = 540.0
		p.angle_min = -180.0
		p.angle_max = 180.0
		p.tangential_accel_min = -3.0
		p.tangential_accel_max = 3.0
		p.damping_min = 1.0
		p.damping_max = 2.5
		p.scale_amount_min = 0.8
		p.scale_amount_max = 1.5
		p.scale_amount_curve = _scale_curve
		scene_root.add_child(p)
		_particle_pool.append(p)
