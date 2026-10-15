extends Node3D

@export var level_number: int = 1
@export var time_limit: float = 90.0
@export var auto_detect_goals: bool = true
@export var custom_goals: Dictionary = {}

@onready var plants_container: Node3D = $Plants if has_node("Plants") else null
@onready var obstacles_container: Node3D = $Obstacles if has_node("Obstacles") else null
@onready var cutter_spawn: Marker3D = $CutterSpawn if has_node("CutterSpawn") else null

func _ready() -> void:
	# Se o level for executado diretamente no editor (F6), redireciona para a Main com o nível ativo
	if get_parent() == get_tree().root:
		if GameManager != null:
			GameManager.current_level = level_number
		get_tree().change_scene_to_file("res://scenes/main.tscn")

func get_spawn_position() -> Vector3:
	if cutter_spawn:
		return cutter_spawn.global_position
	return Vector3(0.0, 0.1, 0.0)

func get_goals() -> Dictionary:
	if not auto_detect_goals and not custom_goals.is_empty():
		return custom_goals.duplicate()

	var detected_goals: Dictionary = {}
	if plants_container:
		for child in plants_container.get_children():
			if "plant_key" in child:
				var key: String = String(child.plant_key)
				detected_goals[key] = detected_goals.get(key, 0) + 1

	return detected_goals
