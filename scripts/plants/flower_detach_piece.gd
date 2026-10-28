class_name FlowerDetachPiece
extends Node3D
## Peça-detrito da Flor Silvestre (pétala ou folha) que se desprende no 1º hit:
## sobe com impulso vertical, gira, cai sob gravidade, encolhe ao tocar o solo e desaparece.

const GRAVITY: float = 14.0
const GROUND_CLEARANCE: float = 0.03
const SHRINK_SEC: float = 0.4
const MAX_FLIGHT_SEC: float = 2.0

var _velocity: Vector3 = Vector3.ZERO
var _spin_axis: Vector3 = Vector3.UP
var _spin_speed: float = 0.0
var _ground_y: float = 0.0
var _base_scale: float = 1.0
var _rot_basis: Basis = Basis.IDENTITY
var _landed: bool = false
var _shrink_timer: float = 0.0
var _flight_timer: float = 0.0


## Configura a peça a partir da transformação da flor de origem e inicia o voo.
func launch(
	start_pos: Vector3,
	base_basis: Basis,
	velocity: Vector3,
	spin_axis: Vector3,
	spin_speed: float,
	ground_y: float
) -> void:
	_velocity = velocity
	_spin_axis = spin_axis.normalized()
	_spin_speed = spin_speed
	_ground_y = ground_y
	_base_scale = maxf(base_basis.get_scale().x, 0.001)
	_rot_basis = base_basis.orthonormalized()
	global_position = start_pos
	basis = _rot_basis.scaled(Vector3.ONE * _base_scale)


func _process(delta: float) -> void:
	if _landed:
		_shrink_timer += delta
		var k: float = clampf(1.0 - _shrink_timer / SHRINK_SEC, 0.0, 1.0)
		basis = _rot_basis.scaled(Vector3.ONE * (_base_scale * k))
		if _shrink_timer >= SHRINK_SEC:
			queue_free()
		return

	_flight_timer += delta
	_velocity.y -= GRAVITY * delta
	global_position += _velocity * delta
	_rot_basis = (Basis(_spin_axis, _spin_speed * delta) * _rot_basis).orthonormalized()
	basis = _rot_basis.scaled(Vector3.ONE * _base_scale)

	# Toca o solo (somente na descida) ou estourou o tempo máximo de voo
	if (_velocity.y < 0.0 and global_position.y <= _ground_y + GROUND_CLEARANCE) or _flight_timer >= MAX_FLIGHT_SEC:
		global_position.y = maxf(global_position.y, _ground_y + GROUND_CLEARANCE)
		_landed = true
