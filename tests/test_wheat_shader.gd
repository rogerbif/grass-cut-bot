extends SceneTree

func _init() -> void:
	print("--- TEST WHEAT SHADER ANCHOR & SWAY ---")
	var mat: ShaderMaterial = load("res://shaders/interactive_wheat_material.tres")
	if mat == null:
		push_error("Failed to load interactive_wheat_material.tres")
		quit(1)
		return
	
	var invert: Variant = mat.get_shader_parameter("invert_height")
	print("interactive_wheat_material.tres invert_height = ", invert)
	if invert != true:
		push_error("invert_height is not true in wheat material!")
		quit(1)
		return
		
	var grass_mat: ShaderMaterial = load("res://shaders/interactive_grass_material.tres")
	var grass_invert: Variant = grass_mat.get_shader_parameter("invert_height")
	print("interactive_grass_material.tres invert_height = ", grass_invert)
	if grass_invert == true:
		push_error("invert_height should not be true in grass material!")
		quit(1)
		return

	# Load wheat scene/mesh
	var wheat_scene: PackedScene = load("res://assets/models/wheat_01.glb")
	var wheat_node: Node3D = wheat_scene.instantiate() as Node3D
	var mesh_inst: MeshInstance3D = null
	for child in wheat_node.get_children():
		if child is MeshInstance3D:
			mesh_inst = child
			break
	
	if mesh_inst == null:
		push_error("Could not find MeshInstance3D in wheat_01.glb")
		quit(1)
		return
		
	var mesh: Mesh = mesh_inst.mesh
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	
	var min_y: float = 999.0
	var max_y: float = -999.0
	var min_y_uv_v: float = 0.0
	var max_y_uv_v: float = 0.0
	
	for i in range(verts.size()):
		var v: Vector3 = verts[i]
		var uv: Vector2 = uvs[i]
		if v.y < min_y:
			min_y = v.y
			min_y_uv_v = uv.y
		if v.y > max_y:
			max_y = v.y
			max_y_uv_v = uv.y
			
	print("Wheat mesh min_y: ", min_y, " (UV.y = ", min_y_uv_v, ")")
	print("Wheat mesh max_y: ", max_y, " (UV.y = ", max_y_uv_v, ")")
	
	# Simulate shader math for base and tip
	var base_raw_h: float = 1.0 - min_y_uv_v
	var base_h: float = clampf(base_raw_h, 0.0, 1.0)
	var base_bend: float = smoothstep(0.06, 1.0, base_h)
	base_bend = base_bend * base_bend
	
	var tip_raw_h: float = 1.0 - max_y_uv_v
	var tip_h: float = clampf(tip_raw_h, 0.0, 1.0)
	var tip_bend: float = smoothstep(0.06, 1.0, tip_h)
	tip_bend = tip_bend * tip_bend
	
	print("Base bend_factor (root at ground): ", base_bend)
	print("Tip bend_factor (ear at top): ", tip_bend)
	
	if base_bend != 0.0:
		push_error("Base bend factor must be 0.0 at the ground!")
		quit(1)
		return
		
	if tip_bend < 0.6:
		push_error("Tip bend factor must be high at the ear tip!")
		quit(1)
		return
		
	print("PASSED! Wheat root is 100% firmly anchored at ground, wheat ear sways fully at top.")
	wheat_node.free()
	quit(0)
