extends Node3D

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")

func _ready() -> void:
	print("--- TEST WHEAT LEVEL START ---")
	var data: Dictionary = LevelJsonLoader.load_json_file("res://data/levels/level_03.json")
	assert(not data.is_empty(), "level_03.json should not be empty")

	var vg: Node3D = VegetationGridScript.new() as Node3D
	add_child(vg)

	var goals: Dictionary = vg.call("build_from_level_json", data, null, null) as Dictionary
	print("Goals loaded from Level 03: ", goals)
	assert(goals.has("wheat"), "Goals must contain wheat")
	var initial_wheat: int = int(goals["wheat"])
	print("Wheat goal detected: ", initial_wheat)
	assert(initial_wheat > 0, "Wheat goal must be greater than 0")

	# Start level in GameManager to test cut progression
	GameManager.start_level(3, goals, 90.0)
	print("GameManager initial wheat goal: ", GameManager.get_remaining_goal("wheat"))
	assert(GameManager.get_remaining_goal("wheat") == initial_wheat, "Initial remaining wheat must match")

	# Simulate cutting 1 wheat tuft
	GameManager.register_cut("wheat", 3, Vector3.ZERO)
	print("After 1 cut, remaining wheat: ", GameManager.get_remaining_goal("wheat"))
	assert(GameManager.get_remaining_goal("wheat") == initial_wheat - 1, "Remaining wheat must decrement by 1")

	# Simulate cutting all remaining wheat tufts
	for i in range(initial_wheat - 1):
		GameManager.register_cut("wheat", 3, Vector3.ZERO)

	print("After all cuts, remaining wheat: ", GameManager.get_remaining_goal("wheat"))
	assert(GameManager.get_remaining_goal("wheat") == 0, "Remaining wheat must be 0")
	assert(GameManager.goals["wheat"]["current"] == GameManager.goals["wheat"]["target"], "Wheat current must reach target")

	print("--- TEST WHEAT LEVEL SUCCESS! ---")
	get_tree().quit(0)
