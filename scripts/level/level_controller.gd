extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

@onready var plants_container: Node3D = $PlantsContainer
@onready var obstacles_container: Node3D = $ObstaclesContainer
@onready var cutter: CharacterBody3D = $Cutter

var current_level_node: Node3D = null
@onready var default_terrain: Node3D = get_node_or_null("../Terrain") as Node3D


func _ready() -> void:
	generate_level(GameManager.current_level)


func generate_level(level_num: int) -> void:
	if current_level_node != null:
		if current_level_node.get_parent() == self:
			remove_child(current_level_node)
		current_level_node.queue_free()
		current_level_node = null

	if plants_container != null:
		for child: Node in plants_container.get_children():
			plants_container.remove_child(child)
			child.queue_free()

	if obstacles_container != null:
		for child: Node in obstacles_container.get_children():
			obstacles_container.remove_child(child)
			child.queue_free()

	if default_terrain != null:
		default_terrain.visible = false
		default_terrain.process_mode = Node.PROCESS_MODE_DISABLED

	var json_path: String = "res://data/levels/level_%02d.json" % level_num
	if not FileAccess.file_exists(json_path):
		json_path = "res://data/levels/level_01.json"

	var data: Dictionary = LevelJsonLoader.load_json_file(json_path)

	var veg_grid: Node3D = VegetationGridScript.new() as Node3D
	veg_grid.name = "VegetationGrid_Level_%02d" % level_num
	add_child(veg_grid)
	current_level_node = veg_grid

	var goals: Dictionary = veg_grid.build_from_level_json(data, obstacles_container, cutter) as Dictionary

	if cutter != null:
		var blade_area: Area3D = cutter.get_node_or_null("BladeArea") as Area3D
		if blade_area != null:
			blade_area.monitoring = false
		if cutter.has_method("rebuild_obstacles_cache"):
			cutter.call("rebuild_obstacles_cache")

	var time_limit: float = float(data.get("time_limit", 90.0))
	GameManager.start_level(level_num, goals, time_limit)


func get_vegetation_grid() -> Node3D:
	return current_level_node
