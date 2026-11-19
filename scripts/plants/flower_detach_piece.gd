class_name FlowerDetachPiece
extends Node3D
## Peça-detrito da Flor Silvestre (pétala ou folha) que se desprende no 1º hit:
## sobe com impulso vertical, gira, cai sob gravidade, encolhe ao tocar o solo e retorna ao pool.

const GRAVITY: float = 14.0
const GROUND_CLEARANCE: float = 0.03
const SHRINK_SEC: float = 0.4
const MAX_FLIGHT_SEC: float = 2.0
const POOL_MAX_SIZE: int = 24
const POOL_HOST_NAME: StringName = &"FlowerDetachPoolHost"

static var _pool: Array[FlowerDetachPiece] = []

var mesh_instance: MeshInstance3D = null

var _velocity: Vector3 = Vector3.ZERO
var _spin_axis: Vector3 = Vector3.UP
var _spin_speed: float = 0.0
var _ground_y: float = 0.0
var _base_scale: float = 1.0
var _rot_basis: Basis = Basis.IDENTITY
var _landed: bool = false
var _shrink_timer: float = 0.0
var _flight_timer: float = 0.0


static func _get_or_create_pool_host(tree: SceneTree) -> Node3D:
	if tree == null or tree.root == null:
		return null
	var existing: Node3D = tree.root.get_node_or_null(NodePath(POOL_HOST_NAME)) as Node3D
	if is_instance_valid(existing):
		return existing
	var host: Node3D = Node3D.new()
	host.name = POOL_HOST_NAME
	host.visible = false
	host.process_mode = Node.PROCESS_MODE_DISABLED
	tree.root.add_child(host)
	return host


## Adquire uma peça do pool estático ou cria uma nova instância com MeshInstance3D acoplado.
static func acquire() -> FlowerDetachPiece:
	while not _pool.is_empty():
		var candidate: FlowerDetachPiece = _pool.pop_back() as FlowerDetachPiece
		if not is_instance_valid(candidate) or candidate.mesh_instance == null:
			continue
		var cur_parent: Node = candidate.get_parent()
		if cur_parent != null:
			cur_parent.remove_child(candidate)
		return candidate

	var piece: FlowerDetachPiece = FlowerDetachPiece.new()
	piece.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var mi: MeshInstance3D = MeshInstance3D.new()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	piece.add_child(mi)
	piece.mesh_instance = mi
	return piece


## Devolve uma peça para o pool estático (ou libera caso o limite tenha sido atingido).
static func release(piece: FlowerDetachPiece) -> void:
	if piece == null or not is_instance_valid(piece):
		return
	var host: Node3D = _get_or_create_pool_host(piece.get_tree())
	var cur_parent: Node = piece.get_parent()
	if cur_parent != null:
		cur_parent.remove_child(piece)
	if _pool.size() < POOL_MAX_SIZE and not _pool.has(piece) and host != null:
		host.add_child(piece)
		_pool.append(piece)
	else:
		piece.queue_free()


## Configura a peça a partir da transformação da flor de origem e inicia o voo.
func launch(
	start_pos: Vector3,
	base_basis: Basis,
	velocity: Vector3,
	spin_axis: Vector3,
	spin_speed: float,
	ground_y: float
) -> void:
	_landed = false
	_shrink_timer = 0.0
	_flight_timer = 0.0
	_velocity = velocity
	_spin_axis = spin_axis.normalized()
	_spin_speed = spin_speed
	_ground_y = ground_y
	_base_scale = maxf(base_basis.get_scale().x, 0.001)
	_rot_basis = base_basis.orthonormalized()
	visible = true
	set_process(true)
	global_position = start_pos
	basis = _rot_basis.scaled(Vector3.ONE * _base_scale)
	if is_inside_tree():
		reset_physics_interpolation()


func _recycle() -> void:
	set_process(false)
	visible = false
	release(self)


func _process(delta: float) -> void:
	if _landed:
		_shrink_timer += delta
		var k: float = clampf(1.0 - _shrink_timer / SHRINK_SEC, 0.0, 1.0)
		basis = _rot_basis.scaled(Vector3.ONE * (_base_scale * k))
		if _shrink_timer >= SHRINK_SEC:
			_recycle()
		return

	_flight_timer += delta
	_velocity.y -= GRAVITY * delta
	global_position += _velocity * delta
	_rot_basis = Basis(_spin_axis, _spin_speed * delta) * _rot_basis
	basis = _rot_basis.scaled(Vector3.ONE * _base_scale)

	# Toca o solo (somente na descida) ou estourou o tempo máximo de voo
	if (_velocity.y < 0.0 and global_position.y <= _ground_y + GROUND_CLEARANCE) or _flight_timer >= MAX_FLIGHT_SEC:
		global_position.y = maxf(global_position.y, _ground_y + GROUND_CLEARANCE)
		_landed = true
