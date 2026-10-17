extends Node3D

@onready var joystick: Control = $CanvasLayer/FloatingJoystick
@onready var cutter: CharacterBody3D = $LevelController/Cutter

func _ready() -> void:
	if joystick and cutter:
		joystick.joystick_moved.connect(_on_joystick_moved)

func _on_joystick_moved(direction: Vector2) -> void:
	if cutter:
		cutter.set_input_direction(direction)
