extends SceneTree

var _timer: float = 0.0
var _captured: bool = false
var _main_scene: Node3D = null

func _init() -> void:
	print("--- Teste Close-Up: Grama Verde e Amarela com Gradiente Base Escura ---")

func _process(delta: float) -> bool:
	_timer += delta
	if _main_scene == null:
		_main_scene = Node3D.new()
		root.add_child(_main_scene)

		var light = DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45.0, 30.0, 0.0)
		light.light_color = Color(1.0, 0.98, 0.95, 1.0)
		light.light_energy = 1.15
		_main_scene.add_child(light)

		var floor_mi = MeshInstance3D.new()
		var plane_mesh = PlaneMesh.new()
		plane_mesh.size = Vector2(10.0, 10.0)
		floor_mi.mesh = plane_mesh
		var floor_mat = StandardMaterial3D.new()
		floor_mat.albedo_color = Color(0.24, 0.76, 0.32, 1.0)
		floor_mat.roughness = 0.9
		floor_mi.material_override = floor_mat
		floor_mi.position = Vector3(0.0, -0.01, 0.0)
		_main_scene.add_child(floor_mi)

		var model_scene = load("res://assets/models/grass_01.glb") as PackedScene
		var mat_green = load("res://shaders/interactive_grass_material.tres") as Material
		var mat_yellow = load("res://shaders/interactive_grass_yellow_material.tres") as Material

		# Grama verde à esquerda
		for x in [-0.55, -0.35, -0.7]:
			for z in [-0.4, 0.0, 0.4]:
				var inst = model_scene.instantiate()
				inst.position = Vector3(x, 0.0, z)
				var mi = inst.find_child("*", true, false) as MeshInstance3D
				if mi:
					mi.material_override = mat_green
				_main_scene.add_child(inst)

		# Grama amarela à direita
		for x in [0.35, 0.55, 0.7]:
			for z in [-0.4, 0.0, 0.4]:
				var inst = model_scene.instantiate()
				inst.position = Vector3(x, 0.0, z)
				var mi = inst.find_child("*", true, false) as MeshInstance3D
				if mi:
					mi.material_override = mat_yellow
				_main_scene.add_child(inst)

		# Câmera próxima em ângulo similar ao print do usuário
		var cam = Camera3D.new()
		cam.position = Vector3(0.0, 1.35, 1.85)
		_main_scene.add_child(cam)
		cam.look_at(Vector3(0.0, 0.35, 0.0), Vector3.UP)
		return false

	if _timer > 0.4 and not _captured:
		_captured = true
		var vp: Viewport = root.get_viewport()
		var img: Image = vp.get_texture().get_image()
		var out_path: String = "C:/Users/User/.gemini/antigravity/brain/4f80e1fe-994e-4f54-8908-a19dbda5cbb9/showcase_grass_gradient_closeup.png"
		img.save_png(out_path)
		print("Screenshot capturada em: ", out_path)
		quit()
		return true

	return false
