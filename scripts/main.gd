extends Node3D

@onready var joystick: Control = $CanvasLayer/FloatingJoystick
@onready var cutter: CharacterBody3D = $LevelController/Cutter
@onready var sun_light: DirectionalLight3D = $DirectionalLight3D
@onready var world_env: WorldEnvironment = $WorldEnvironment

func _ready() -> void:
	if sun_light != null:
		sun_light.rotation_degrees = Vector3(-37.0, 40.0, 0.0)
		sun_light.light_energy = 1.30
	if world_env != null and world_env.environment != null:
		world_env.environment.ambient_light_energy = 0.20
	if joystick and cutter:
		joystick.joystick_moved.connect(_on_joystick_moved)

func _on_joystick_moved(direction: Vector2) -> void:
	if cutter:
		cutter.set_input_direction(direction)
