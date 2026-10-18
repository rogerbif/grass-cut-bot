extends Node3D

enum BotState { IDLE_GROUND, DRONE_CARRIED }

@export var idle_bob_amplitude: float = 0.05
@export var idle_bob_frequency: float = 2.4
@export var blade_rotation_speed: float = 60.0 # Graus por segundo de rotação suave da lâmina

var current_state: BotState = BotState.IDLE_GROUND
var time_passed: float = 0.0
var base_y: float = 0.0

@onready var visual_pivot: Node3D = $VisualPivot if has_node("VisualPivot") else self
@onready var blade_spinner: Node3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner") as Node3D
@onready var robot_body: Node3D = get_node_or_null("VisualPivot/GrassBot/Robot/Body") as Node3D
@onready var blade_tier_1: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_1") as MeshInstance3D
@onready var blade_tier_2: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_2") as MeshInstance3D
@onready var blade_tier_3: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_3") as MeshInstance3D
@onready var blade_tier_4: MeshInstance3D = get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_4") as MeshInstance3D

func _ready() -> void:
	base_y = position.y
	if robot_body != null:
		robot_body.rotation.y = 0.0 # Rosto e olhos voltados para a câmera

	update_blade_tier()
	if UpgradeManager != null:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)

func _process(delta: float) -> void:
	time_passed += delta

	# Rotação suave contínua da lâmina
	if blade_spinner != null:
		blade_spinner.rotate_y(deg_to_rad(blade_rotation_speed * delta))

	if current_state == BotState.IDLE_GROUND:
		# Flutuação senoidal vertical suave (hover bobbing)
		var bob_offset: float = sin(time_passed * idle_bob_frequency) * idle_bob_amplitude
		position.y = base_y + bob_offset

		# Respiração/inclinação sutil do chassi
		if visual_pivot != null:
			visual_pivot.rotation.z = sin(time_passed * 1.8) * 0.02
			visual_pivot.rotation.x = cos(time_passed * 1.5) * 0.015

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
	position = new_pos
	base_y = new_pos.y
