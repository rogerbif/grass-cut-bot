extends SceneTree

var _timer: float = 0.0
var _captured: bool = false
var _main_scene: Node3D = null

func _init() -> void:
	print("--- Teste Visual de Gradiente de Base Escura em Todas as Gramas ---")

func _process(delta: float) -> bool:
	_timer += delta
	if _main_scene == null:
		_main_scene = Node3D.new()
		root.add_child(_main_scene)

		# Luz direcional suave estilo jogo
		var light = DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-45.0, 30.0, 0.0)
		light.light_color = Color(1.0, 0.98, 0.95, 1.0)
		light.light_energy = 1.15
		_main_scene.add_child(light)

		# Chão verde suave neutro para contraste
		var floor_mi = MeshInstance3D.new()
		var plane_mesh = PlaneMesh.new()
		plane_mesh.size = Vector2(20.0, 20.0)
		floor_mi.mesh = plane_mesh
		var floor_mat = StandardMaterial3D.new()
		floor_mat.albedo_color = Color(0.24, 0.76, 0.32, 1.0)
		floor_mat.roughness = 0.9
		floor_mi.material_override = floor_mat
		floor_mi.position = Vector3(0.0, -0.01, 0.0)
		_main_scene.add_child(floor_mi)

		# Tipos de grama e seus materiais
		var grass_types = [
			{"name": "Grama Verde", "mat": "res://shaders/interactive_grass_material.tres", "pos": Vector3(-3.0, 0.0, -1.0)},
			{"name": "Grama Amarela", "mat": "res://shaders/interactive_grass_yellow_material.tres", "pos": Vector3(-1.0, 0.0, -1.0)},
			{"name": "Grama Azul", "mat": "res://shaders/interactive_grass_blue_material.tres", "pos": Vector3(1.0, 0.0, -1.0)},
			{"name": "Grama Vermelha", "mat": "res://shaders/interactive_grass_red_material.tres", "pos": Vector3(3.0, 0.0, -1.0)},
			{"name": "Grama Roxa", "mat": "res://shaders/interactive_grass_purple_material.tres", "pos": Vector3(-2.0, 0.0, 1.2)},
			{"name": "Grama Branca", "mat": "res://shaders/interactive_grass_white_material.tres", "pos": Vector3(0.0, 0.0, 1.2)},
			{"name": "Grama Preta", "mat": "res://shaders/interactive_grass_black_material.tres", "pos": Vector3(2.0, 0.0, 1.2)},
		]

		var model_scene = load("res://assets/models/grass_01.glb") as PackedScene
		for info in grass_types:
			var mat = load(info.mat) as Material
			# Instancia um tufo central + 2 adjacentes para formar um pequeno canteiro
			for off in [Vector3.ZERO, Vector3(-0.25, 0.0, 0.2), Vector3(0.25, 0.0, -0.15)]:
				var inst = model_scene.instantiate()
				inst.position = info.pos + off
				var mi = inst.find_child("*", true, false) as MeshInstance3D
				if mi:
					mi.material_override = mat
				_main_scene.add_child(inst)

		# Câmera isométrica em 3/4 similar à câmera do jogo
		var cam = Camera3D.new()
		cam.position = Vector3(0.0, 3.8, 4.2)
		_main_scene.add_child(cam)
		cam.look_at(Vector3(0.0, 0.4, 0.0), Vector3.UP)
		return false

	if _timer > 0.4 and not _captured:
		_captured = true
		var vp: Viewport = root.get_viewport()
		var img: Image = vp.get_texture().get_image()
		var out_path: String = "C:/Users/User/.gemini/antigravity/brain/4f80e1fe-994e-4f54-8908-a19dbda5cbb9/showcase_grass_gradient_all.png"
		img.save_png(out_path)
		print("Screenshot capturada em: ", out_path)
		quit()
		return true

	return false
