extends RefCounted

const DEFAULT_CELL_SIZE: float = 0.80

const WATER_OCEAN_SCENE: PackedScene = preload("res://scenes/level/water_ocean.tscn")

const FLOWER_VARIATION_MATERIALS: Dictionary = {
	"flower": preload("res://shaders/interactive_flower_material.tres"),
	"flower_blue": preload("res://shaders/interactive_flower_blue_material.tres"),
	"flower_sunset": preload("res://shaders/interactive_flower_sunset_material.tres"),
	"flower_purple": preload("res://shaders/interactive_flower_purple_material.tres"),
	"flower_white": preload("res://shaders/interactive_flower_white_material.tres"),
	"flower_turquoise": preload("res://shaders/interactive_flower_turquoise_material.tres"),
	"flower_rose": preload("res://shaders/flower_rose_material.tres"),
	"flower_rose_white": preload("res://shaders/flower_rose_white_material.tres"),
	"flower_rose_yellow": preload("res://shaders/flower_rose_yellow_material.tres"),
	"flower_rose_blue": preload("res://shaders/flower_rose_blue_material.tres"),
	"flower_rose_wine": preload("res://shaders/flower_rose_wine_material.tres"),
	"flower_rose_black": preload("res://shaders/flower_rose_black_material.tres"),
	"flower_rose_peach": preload("res://shaders/flower_rose_peach_material.tres"),
	"flower_daisy_blue": preload("res://shaders/flower_daisy_blue_material.tres"),
	"flower_daisy_orange": preload("res://shaders/flower_daisy_orange_material.tres"),
	"flower_daisy_yellow": preload("res://shaders/flower_daisy_yellow_material.tres"),
	"flower_daisy_red": preload("res://shaders/flower_daisy_red_material.tres"),
	"flower_daisy_pink": preload("res://shaders/flower_daisy_pink_material.tres"),
	"flower_daisy_bicolor": preload("res://shaders/flower_daisy_bicolor_material.tres")
}

const OBJECT_SCENES: Dictionary = {
	"grass_green": preload("res://scenes/plants/grass_tuft.tscn"),
	"grass_yellow": preload("res://scenes/plants/grass_yellow.tscn"),
	"grass_blue": preload("res://scenes/plants/grass_blue.tscn"),
	"grass_purple": preload("res://scenes/plants/grass_purple.tscn"),
	"grass_white": preload("res://scenes/plants/grass_white.tscn"),
	"grass_red": preload("res://scenes/plants/grass_red.tscn"),
	"grass_black": preload("res://scenes/plants/grass_black.tscn"),
	"wheat": preload("res://scenes/plants/wheat_tuft.tscn"),
	"flower": preload("res://scenes/plants/flower_tuft.tscn"),
	"flower_blue": preload("res://scenes/plants/flower_tuft.tscn"),
	"flower_sunset": preload("res://scenes/plants/flower_tuft.tscn"),
	"flower_purple": preload("res://scenes/plants/flower_tuft.tscn"),
	"flower_white": preload("res://scenes/plants/flower_tuft.tscn"),
	"flower_turquoise": preload("res://scenes/plants/flower_tuft.tscn"),
	"flower_rose": preload("res://scenes/plants/flower_rose.tscn"),
	"flower_rose_white": preload("res://scenes/plants/flower_rose.tscn"),
	"flower_rose_yellow": preload("res://scenes/plants/flower_rose.tscn"),
	"flower_rose_blue": preload("res://scenes/plants/flower_rose.tscn"),
	"flower_rose_wine": preload("res://scenes/plants/flower_rose.tscn"),
	"flower_rose_black": preload("res://scenes/plants/flower_rose.tscn"),
	"flower_rose_peach": preload("res://scenes/plants/flower_rose.tscn"),
	"flower_daisy": preload("res://scenes/plants/flower_daisy.tscn"),
	"flower_daisy_blue": preload("res://scenes/plants/flower_daisy.tscn"),
	"flower_daisy_orange": preload("res://scenes/plants/flower_daisy.tscn"),
	"flower_daisy_yellow": preload("res://scenes/plants/flower_daisy.tscn"),
	"flower_daisy_red": preload("res://scenes/plants/flower_daisy.tscn"),
	"flower_daisy_pink": preload("res://scenes/plants/flower_daisy.tscn"),
	"flower_daisy_bicolor": preload("res://scenes/plants/flower_daisy.tscn"),
	"flower_sunflower": preload("res://scenes/plants/flower_sunflower.tscn"),
	"flower_tulip": preload("res://scenes/plants/flower_tulip.tscn"),
	"flower_tulip_yellow": preload("res://scenes/plants/flower_tulip.tscn"),
	"flower_tulip_purple": preload("res://scenes/plants/flower_tulip.tscn"),
	"flower_tulip_orange": preload("res://scenes/plants/flower_tulip.tscn"),
	"flower_bed": preload("res://scenes/plants/flower_bed.tscn"),
	"flower_bed_blue": preload("res://scenes/plants/flower_bed.tscn"),
	"flower_bed_white": preload("res://scenes/plants/flower_bed.tscn"),
	"rock": preload("res://scenes/obstacles/rock.tscn"),
	"rock_slate": preload("res://scenes/obstacles/rock.tscn"),
	"rock_moss": preload("res://scenes/obstacles/rock_moss.tscn"),
	"rock_spire": preload("res://scenes/obstacles/rock_spire.tscn"),
	"rock_moss_spire": preload("res://scenes/obstacles/rock_moss_spire.tscn"),
	"rock_sandstone": preload("res://scenes/obstacles/rock_sandstone.tscn"),
	"rock_boulder": preload("res://scenes/obstacles/rock_boulder.tscn")
}

const SCENE_MAP: Dictionary = OBJECT_SCENES

static func grid_to_world(gx: int, gz: int, width: int, height: int, cell_size: float = DEFAULT_CELL_SIZE) -> Vector3:
	var offset_x: float = -(float(width) * cell_size) / 2.0 + (cell_size / 2.0)
	var offset_z: float = -(float(height) * cell_size) / 2.0 + (cell_size / 2.0)
	return Vector3(
		offset_x + float(gx) * cell_size,
		0.0,
		offset_z + float(gz) * cell_size
	)

static func world_to_grid(world_pos: Vector3, width: int, height: int, cell_size: float = DEFAULT_CELL_SIZE) -> Vector2i:
	var offset_x: float = -(float(width) * cell_size) / 2.0 + (cell_size / 2.0)
	var offset_z: float = -(float(height) * cell_size) / 2.0 + (cell_size / 2.0)
	var gx: int = roundi((world_pos.x - offset_x) / cell_size)
	var gz: int = roundi((world_pos.z - offset_z) / cell_size)
	return Vector2i(gx, gz)

static func load_json_file(path: String) -> Dictionary:
	var target_path: String = path
	if not FileAccess.file_exists(target_path):
		var glob_p: String = ProjectSettings.globalize_path(path)
		if FileAccess.file_exists(glob_p):
			target_path = glob_p
		else:
			return {}
	var file: FileAccess = FileAccess.open(target_path, FileAccess.READ)
	if file == null:
		var glob_p: String = ProjectSettings.globalize_path(target_path)
		file = FileAccess.open(glob_p, FileAccess.READ)
	if file == null:
		return {}
	var text: String = file.get_as_text()
	file.close()
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed as Dictionary
	return {}

static func get_island_polygons(data: Dictionary) -> Array[PackedVector2Array]:
	if data.has("island_polygons") and data["island_polygons"] is Array:
		var raw_list: Array = data["island_polygons"] as Array
		var result: Array[PackedVector2Array] = []
		for item: Variant in raw_list:
			if item is Array:
				var pts: PackedVector2Array = PackedVector2Array()
				for pt_var: Variant in (item as Array):
					if pt_var is Array and (pt_var as Array).size() >= 2:
						var pt_arr: Array = pt_var as Array
						pts.append(Vector2(float(pt_arr[0]), float(pt_arr[1])))
				if pts.size() >= 3:
					result.append(pts)
		if not result.is_empty():
			return result

	var terrain_arr: Array = data.get("terrain", []) as Array
	var grid_info: Dictionary = data.get("grid", {}) as Dictionary
	var width: int = int(grid_info.get("width", 12))
	var height: int = int(grid_info.get("height", 8))
	var cell_size: float = float(grid_info.get("cell_size", DEFAULT_CELL_SIZE))
	return IslandMeshBuilder.convert_tile_grid_to_polygons(terrain_arr, width, height, cell_size)


static func get_island_holes(data: Dictionary) -> Array[PackedVector2Array]:
	if data.has("island_holes") and data["island_holes"] is Array:
		var raw_list: Array = data["island_holes"] as Array
		var result: Array[PackedVector2Array] = []
		for item: Variant in raw_list:
			if item is Array:
				var pts: PackedVector2Array = PackedVector2Array()
				for pt_var: Variant in (item as Array):
					if pt_var is Array and (pt_var as Array).size() >= 2:
						var pt_arr: Array = pt_var as Array
						pts.append(Vector2(float(pt_arr[0]), float(pt_arr[1])))
				if pts.size() >= 3:
					result.append(pts)
		return result
	return []

static func instantiate_object_node(obj_type: String, rot_deg: int = 0) -> Node3D:
	if not OBJECT_SCENES.has(obj_type):
		return null
	var packed: PackedScene = OBJECT_SCENES[obj_type] as PackedScene
	if packed == null:
		return null
	var node: Node3D = packed.instantiate() as Node3D
	if node != null:
		if rot_deg != 0:
			node.rotation_degrees.y = float(rot_deg)
		if FLOWER_VARIATION_MATERIALS.has(obj_type):
			node.set("custom_material", FLOWER_VARIATION_MATERIALS[obj_type])
		if "plant_key" in node:
			node.set("plant_key", obj_type)
	return node
