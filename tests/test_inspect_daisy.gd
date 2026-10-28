extends Node3D

func _ready() -> void:
	print("--- TEST FLOWER DAISY COMBINED MESH AND SHADER ---")
	var vg_script = load("res://scripts/plants/vegetation_grid.gd")
	vg_script.call("_ensure_static_meshes")
	var daisy_mesh: ArrayMesh = vg_script.get("_flower_daisy_mesh") as ArrayMesh
	assert(daisy_mesh != null, "ERROR: _flower_daisy_mesh is null!")
	assert(daisy_mesh.get_surface_count() == 3, "ERROR: Surface count should be 3!")

	var leaves_mat: Material = daisy_mesh.surface_get_material(0)
	var petals_mat: Material = daisy_mesh.surface_get_material(1)
	var stem_mat: Material = daisy_mesh.surface_get_material(2)

	assert(leaves_mat is ShaderMaterial, "ERROR: Surface 0 leaves material should be ShaderMaterial!")
	assert(petals_mat is ShaderMaterial, "ERROR: Surface 1 petals material should be ShaderMaterial!")
	assert(stem_mat is ShaderMaterial, "ERROR: Surface 2 stem material should be ShaderMaterial!")

	var sm_petals: ShaderMaterial = petals_mat as ShaderMaterial
	var petal_color: Variant = sm_petals.get_shader_parameter("petal_color")
	print("Petal Color: ", petal_color)
	assert(petal_color == Color(1.0, 1.0, 1.0, 1.0), "ERROR: Petal color must be white Color(1, 1, 1, 1)!")

	var center_color: Variant = sm_petals.get_shader_parameter("center_color")
	print("Center Color: ", center_color)
	assert(center_color == Color(1.0, 0.85, 0.0, 1.0), "ERROR: Center color must be yellow Color(1, 0.85, 0, 1)!")

	print("SUCESSO: Margarida configurada com pétalas brancas e materiais canônicos!")
	get_tree().quit(0)
