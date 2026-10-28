extends Node3D

enum PlantType { GRASS, WHEAT, FLOWER }

const POOL_SIZE: int = 36
const FLOWER_STEM_COLOR: Color = Color(0.20, 0.72, 0.28, 1.0)

static var _triangle_mesh: ArrayMesh = null
static var _square_mesh: ArrayMesh = null
static var _circle_mesh: ArrayMesh = null

static var _particle_pool: Array[CPUParticles3D] = []
static var _pool_idx: int = 0
static var _particle_materials: Dictionary = {}
static var _scale_curve: Curve = null
static var _fallback_material: StandardMaterial3D = null
static var _detach_meshes: Dictionary = {}

# Peças desprendíveis da Flor Silvestre no Hit 1 (2 pétalas + 1 folha)
const DETACH_PIECES_MODEL_PATH: String = "res://assets/models/flower_detach_pieces.glb"
## Posição local (espaço Godot, pivô no solo) do centro de cada peça no modelo flower_01.glb
const DETACH_PIECE_OFFSETS: Dictionary = {
	"Piece_Petal_A": Vector3(-0.3427, 0.9842, 0.1109),
	"Piece_Petal_B": Vector3(-0.0622, 1.0329, 0.3303),
	"Piece_Leaf": Vector3(-0.1326, 0.343, -0.2266),
}
const DETACH_UP_SPEED_MIN: float = 4.0
const DETACH_UP_SPEED_MAX: float = 5.0

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
	elif type == PlantType.FLOWER:
		# Flores com +30% de escala visual (0.48~0.58 * 1.30 = 0.624~0.754)
		var flower_scale: float = randf_range(0.624, 0.754)
		visual_mesh.scale = Vector3(flower_scale, flower_scale, flower_scale)
	else:
		# Trigo aumentado em 100% (+100% de escala visual: 0.48~0.58 -> 0.96~1.16)
		var random_scale: float = randf_range(0.96, 1.16)
		visual_mesh.scale = Vector3(random_scale, random_scale, random_scale)

static func _ensure_particle_meshes() -> void:
	if _triangle_mesh == null:
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n: Vector3 = Vector3(0.0, 0.0, 1.0)
		st.set_normal(n); st.set_uv(Vector2(0.5, 0.0)); st.add_vertex(Vector3(0.0, 0.055, 0.0))
		st.set_normal(n); st.set_uv(Vector2(0.0, 1.0)); st.add_vertex(Vector3(-0.045, -0.035, 0.0))
		st.set_normal(n); st.set_uv(Vector2(1.0, 1.0)); st.add_vertex(Vector3(0.045, -0.035, 0.0))
		_triangle_mesh = st.commit()

	if _square_mesh == null:
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n: Vector3 = Vector3(0.0, 0.0, 1.0)
		var s: float = 0.038
		st.set_normal(n); st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-s, -s, 0.0))
		st.set_normal(n); st.set_uv(Vector2(1, 0)); st.add_vertex(Vector3(s, -s, 0.0))
		st.set_normal(n); st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(s, s, 0.0))

		st.set_normal(n); st.set_uv(Vector2(0, 0)); st.add_vertex(Vector3(-s, -s, 0.0))
		st.set_normal(n); st.set_uv(Vector2(1, 1)); st.add_vertex(Vector3(s, s, 0.0))
		st.set_normal(n); st.set_uv(Vector2(0, 1)); st.add_vertex(Vector3(-s, s, 0.0))
		_square_mesh = st.commit()

	if _circle_mesh == null:
		var st: SurfaceTool = SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var n: Vector3 = Vector3(0.0, 0.0, 1.0)
		var r: float = 0.045
		var segments: int = 10
		for i: int in range(segments):
			var a0: float = float(i) * TAU / float(segments)
			var a1: float = float(i + 1) * TAU / float(segments)
			st.set_normal(n); st.set_uv(Vector2(0.5, 0.5)); st.add_vertex(Vector3.ZERO)
			st.set_normal(n); st.set_uv(Vector2(0.5 + 0.5 * cos(a0), 0.5 + 0.5 * sin(a0))); st.add_vertex(Vector3(cos(a0) * r, sin(a0) * r, 0.0))
			st.set_normal(n); st.set_uv(Vector2(0.5 + 0.5 * cos(a1), 0.5 + 0.5 * sin(a1))); st.add_vertex(Vector3(cos(a1) * r, sin(a1) * r, 0.0))
		_circle_mesh = st.commit()

static func get_flower_colors(flower_type: String) -> Dictionary:
	var petal_col: Color = Color(1.0, 0.18, 0.65, 1.0)
	var center_col: Color = Color(1.0, 0.85, 0.05, 1.0)
	match flower_type:
		"flower_rose":
			petal_col = Color(1.0, 0.08, 0.35, 1.0)
			center_col = Color(0.80, 0.02, 0.18, 1.0)
		"flower_daisy":
			petal_col = Color(1.0, 1.0, 1.0, 1.0)
			center_col = Color(1.0, 0.85, 0.0, 1.0)
		"flower_sunflower":
			petal_col = Color(1.0, 0.88, 0.0, 1.0)
			center_col = Color(0.48, 0.22, 0.05, 1.0)
		"flower_bell":
			petal_col = Color(0.12, 0.65, 1.0, 1.0)
			center_col = Color(0.05, 0.38, 0.92, 1.0)
		"flower_corolla":
			petal_col = Color(1.0, 0.50, 0.05, 1.0)
			center_col = Color(0.95, 0.15, 0.05, 1.0)
		"flower_tulip":
			petal_col = Color(1.0, 0.08, 0.24, 1.0)
			center_col = Color(0.68, 0.05, 0.15, 1.0)
		"flower_bed":
			petal_col = Color(0.88, 0.30, 1.0, 1.0)
			center_col = Color(0.55, 0.08, 0.80, 1.0)
		_:
			petal_col = Color(1.0, 0.18, 0.65, 1.0)
			center_col = Color(1.0, 0.85, 0.05, 1.0)
	return { "petal": petal_col, "center": center_col }

func _apply_visual_material(target: Node) -> void:
	if target == null:
		return
	if target is MeshInstance3D:
		var mi: MeshInstance3D = target as MeshInstance3D
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		if type == PlantType.FLOWER:
			# Para flores com 2 slots (0: Caule Verde, 1: Pétalas Customizáveis)
			# Flor Silvestre dividida em 3 malhas (Flower_Stem, Flower_Leaves, Flower_Petals): somente as
			# pétalas (slot único 0) recebem o material customizável; caule e folhas permanecem verdes.
			if custom_material != null:
				if mi.name == &"Flower_Petals":
					mi.set_surface_override_material(0, custom_material)
				elif mi.mesh != null and mi.mesh.get_surface_count() > 1:
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
	var scene_root: Node = get_tree().current_scene if get_tree() != null else null
	if scene_root != null:
		spawn_flower_petal_burst(scene_root, global_position + Vector3(0.0, 0.25, 0.0), plant_key)
		if remaining_hp == 2:
			spawn_flower_detach_pieces(scene_root, visual_mesh.global_transform, plant_key)

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
	var scene_root: Node = get_tree().current_scene if get_tree() != null else null
	if scene_root != null:
		if type == PlantType.FLOWER:
			spawn_flower_cut_particles(scene_root, global_position + Vector3(0.0, 0.15, 0.0), plant_key)
		else:
			spawn_grass_cut_particles(scene_root, global_position + Vector3(0.0, 0.15, 0.0), _resolve_particle_color())

	# Notifica o GameManager
	var gm: Node = get_node_or_null("/root/GameManager")
	if gm != null and gm.has_method("register_cut"):
		gm.call("register_cut", plant_key, coin_reward, global_position)

	# Registra a colheita no SaveManager para o Herbário
	var sm_node: Node = get_node_or_null("/root/SaveManager")
	if sm_node != null and sm_node.has_method("record_plant_harvest"):
		sm_node.call("record_plant_harvest", plant_key, 1)

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
		var col_light: Variant = sm.get_shader_parameter("color_light")
		if col_light is Color:
			return col_light as Color
		var col_variant: Variant = sm.get_shader_parameter("color_top")
		if col_variant is Color:
			return col_variant as Color
	if type == PlantType.WHEAT:
		return Color(0.98, 0.78, 0.14, 1.0)
	if type == PlantType.FLOWER:
		return Color(1.0, 0.18, 0.65, 1.0)
	return particle_color

static func _emit_sub_burst(scene_root: Node, pos: Vector3, mesh: Mesh, col: Color, count: int) -> void:
	if scene_root == null or mesh == null:
		return
	if not scene_root.is_inside_tree():
		return
	if _particle_pool.is_empty() or not is_instance_valid(_particle_pool[0]) or not _particle_pool[0].is_inside_tree():
		_init_particle_pool(scene_root)
	if _particle_pool.is_empty():
		return

	var emitter: CPUParticles3D = _particle_pool[_pool_idx]
	_pool_idx = (_pool_idx + 1) % POOL_SIZE

	if not emitter.is_inside_tree():
		scene_root.add_child(emitter)

	emitter.mesh = mesh
	emitter.amount = count
	emitter.emitting = false
	emitter.material_override = _get_or_create_particle_material(col)
	if emitter.is_inside_tree():
		emitter.global_position = pos
		emitter.reset_physics_interpolation()
	else:
		emitter.position = pos
	emitter.restart()

## Emissão para Grama e Trigo: fragmentos geométricos de Triângulos e Quadrados da cor da vegetação
static func spawn_grass_cut_particles(scene_root: Node, world_pos: Vector3, col: Color) -> void:
	_ensure_particle_meshes()
	_emit_sub_burst(scene_root, world_pos + Vector3(0.0, 0.14, 0.0), _triangle_mesh, col, 8)
	_emit_sub_burst(scene_root, world_pos + Vector3(0.0, 0.14, 0.0), _square_mesh, col, 6)

## Emissão para Flores: Círculos das cores de pétala e miolo, mais pedaços verdes de caule (quadrados) e folhas (triângulos)
static func spawn_flower_cut_particles(scene_root: Node, world_pos: Vector3, flower_type: String) -> void:
	_ensure_particle_meshes()
	var cols: Dictionary = get_flower_colors(flower_type)
	var p_col: Color = cols["petal"] as Color
	var c_col: Color = cols["center"] as Color
	var s_col: Color = FLOWER_STEM_COLOR

	# Círculos das cores da flor (pétala e miolo)
	_emit_sub_burst(scene_root, world_pos + Vector3(0.0, 0.22, 0.0), _circle_mesh, p_col, 8)
	_emit_sub_burst(scene_root, world_pos + Vector3(0.0, 0.22, 0.0), _circle_mesh, c_col, 4)

	# Fragmentos verdes: caule (quadrado) e folha (triângulo)
	_emit_sub_burst(scene_root, world_pos + Vector3(0.0, 0.15, 0.0), _square_mesh, s_col, 3)
	_emit_sub_burst(scene_root, world_pos + Vector3(0.0, 0.15, 0.0), _triangle_mesh, s_col, 3)

## Explosão parcial de pétalas e folha para hits intermediários de flor
static func spawn_flower_petal_burst(scene_root: Node, world_pos: Vector3, flower_type: String) -> void:
	_ensure_particle_meshes()
	var cols: Dictionary = get_flower_colors(flower_type)
	_emit_sub_burst(scene_root, world_pos + Vector3(0.0, 0.25, 0.0), _circle_mesh, cols["petal"] as Color, 6)
	_emit_sub_burst(scene_root, world_pos + Vector3(0.0, 0.18, 0.0), _triangle_mesh, FLOWER_STEM_COLOR, 2)

## Carrega (uma única vez) as malhas das peças desprendíveis da Flor Silvestre
static func _ensure_detach_meshes() -> void:
	if not _detach_meshes.is_empty():
		return
	var packed: PackedScene = load(DETACH_PIECES_MODEL_PATH) as PackedScene
	if packed == null:
		return
	var inst: Node = packed.instantiate()
	for piece_name: String in DETACH_PIECE_OFFSETS.keys():
		var mi: MeshInstance3D = inst.find_child(piece_name, true, false) as MeshInstance3D
		if mi != null and mi.mesh != null:
			_detach_meshes[piece_name] = mi.mesh
	inst.free()

## Hit 1 da Flor Silvestre: 2 pétalas + 1 folha saem para cima, caem, encolhem e somem
static func spawn_flower_detach_pieces(scene_root: Node, flower_xform: Transform3D, flower_type: String) -> void:
	if flower_type != "flower" or scene_root == null or not scene_root.is_inside_tree():
		return
	_ensure_particle_meshes()
	_ensure_detach_meshes()
	var cols: Dictionary = get_flower_colors(flower_type)
	for piece_name: String in DETACH_PIECE_OFFSETS.keys():
		if not _detach_meshes.has(piece_name):
			continue
		var is_leaf: bool = piece_name == "Piece_Leaf"
		var col: Color = FLOWER_STEM_COLOR if is_leaf else (cols["petal"] as Color)
		var local_off: Vector3 = DETACH_PIECE_OFFSETS[piece_name] as Vector3
		var start_pos: Vector3 = flower_xform * local_off

		var piece: FlowerDetachPiece = FlowerDetachPiece.new()
		piece.name = piece_name
		var mi: MeshInstance3D = MeshInstance3D.new()
		mi.mesh = _detach_meshes[piece_name] as Mesh
		mi.material_override = _get_or_create_particle_material(col)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		piece.add_child(mi)
		scene_root.add_child(piece)

		var lateral: Vector3 = Vector3(local_off.x, 0.0, local_off.z).normalized() * randf_range(0.5, 1.1)
		var vel: Vector3 = Vector3(lateral.x, randf_range(DETACH_UP_SPEED_MIN, DETACH_UP_SPEED_MAX), lateral.z)
		var axis: Vector3 = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0))
		if axis.length_squared() < 0.01:
			axis = Vector3.RIGHT
		piece.launch(start_pos, flower_xform.basis, vel, axis, randf_range(-9.0, 9.0), flower_xform.origin.y)

static func _get_or_create_particle_material(col: Color) -> StandardMaterial3D:
	var key: String = col.to_html(false)
	if _particle_materials.has(key):
		return _particle_materials[key] as StandardMaterial3D
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.85
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.22
	_particle_materials[key] = mat
	return mat

static func _init_particle_pool(scene_root: Node) -> void:
	_particle_pool.clear()
	_pool_idx = 0
	_ensure_particle_meshes()

	if _scale_curve == null:
		_scale_curve = Curve.new()
		_scale_curve.add_point(Vector2(0.0, 0.75))
		_scale_curve.add_point(Vector2(0.12, 1.15))
		_scale_curve.add_point(Vector2(0.65, 0.95))
		_scale_curve.add_point(Vector2(1.0, 0.0), -3.0, 0.0)

	for i: int in range(POOL_SIZE):
		var p: CPUParticles3D = CPUParticles3D.new()
		p.name = "PooledCutParticles_%d" % i
		p.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
		p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		p.emitting = false
		p.amount = 8
		p.lifetime = 0.52
		p.one_shot = true
		p.explosiveness = 0.95
		p.mesh = _triangle_mesh
		p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
		p.emission_sphere_radius = 0.12
		p.particle_flag_rotate_y = false # Rotação 3D livre / tumbling
		p.direction = Vector3(0.0, 1.0, 0.0)
		p.spread = 82.0
		p.gravity = Vector3(0.0, -14.0, 0.0) # Arco parabólico com queda firme
		p.initial_velocity_min = 3.2
		p.initial_velocity_max = 5.2
		p.angular_velocity_min = -720.0
		p.angular_velocity_max = 720.0
		p.angle_min = -180.0
		p.angle_max = 180.0
		p.radial_accel_min = 1.2
		p.radial_accel_max = 3.2
		p.tangential_accel_min = -2.5
		p.tangential_accel_max = 2.5
		p.damping_min = 1.2
		p.damping_max = 2.8
		p.scale_amount_min = 0.75
		p.scale_amount_max = 1.35
		p.scale_amount_curve = _scale_curve
		scene_root.add_child(p)
		_particle_pool.append(p)
