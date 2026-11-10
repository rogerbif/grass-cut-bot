extends Node3D

const OUTPUT_PATH: String = "C:/Users/User/.gemini/antigravity/brain/4f80e1fe-994e-4f54-8908-a19dbda5cbb9/showcase_tropical_rocks_godot.png"

var _frames: int = 0

func _ready() -> void:
	print("--- SHOWCASE 3D DE ROCHAS TROPICAIS NA ENGINE GODOT 4 ---")

	var env: WorldEnvironment = WorldEnvironment.new()
	var env_res: Environment = Environment.new()
	env_res.background_mode = Environment.BG_COLOR
	env_res.background_color = Color(0.35, 0.68, 0.92) # Céu azul caribe
	env_res.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env_res.ambient_light_color = Color(0.92, 0.95, 1.0)
	env_res.ambient_light_energy = 0.95
	env.environment = env_res
	add_child(env)

	var sun: DirectionalLight3D = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42.0, 32.0, 0.0)
	sun.light_color = Color(1.0, 0.98, 0.92)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

	# Chão da ilha verde relva
	var ground: MeshInstance3D = MeshInstance3D.new()
	var plane: PlaneMesh = PlaneMesh.new()
	plane.size = Vector2(20.0, 15.0)
	var g_mat: StandardMaterial3D = StandardMaterial3D.new()
	g_mat.albedo_color = Color(0.24, 0.64, 0.28) # Verde ilha fosco
	g_mat.roughness = 0.88
	ground.mesh = plane
	ground.material_override = g_mat
	add_child(ground)

	var cam: Camera3D = Camera3D.new()
	cam.current = true
	cam.position = Vector3(0.0, 2.6, 3.2)
	add_child(cam)
	cam.look_at(Vector3(0.0, 0.35, 0.0))

	# Fileira de trás (Z = -0.55):
	_place("res://scenes/obstacles/rock.tscn", Vector3(-0.95, 0.0, -0.55))
	_place("res://scenes/obstacles/rock_moss.tscn", Vector3(0.0, 0.0, -0.55))
	_place("res://scenes/obstacles/rock_spire.tscn", Vector3(0.95, 0.0, -0.55))

	# Fileira da frente (Z = 0.45):
	_place("res://scenes/obstacles/rock_moss_spire.tscn", Vector3(-0.95, 0.0, 0.45))
	_place("res://scenes/obstacles/rock_sandstone.tscn", Vector3(0.0, 0.0, 0.45))
	_place("res://scenes/obstacles/rock_boulder.tscn", Vector3(0.95, 0.0, 0.45))

func _place(scene_path: String, pos: Vector3) -> Node3D:
	var sc: PackedScene = load(scene_path)
	if sc == null:
		print("Erro ao carregar cena: ", scene_path)
		return null
	var inst: Node3D = sc.instantiate() as Node3D
	inst.position = pos
	add_child(inst)
	print("Placed ", scene_path, " at ", pos)
	for c in inst.find_children("*", "MeshInstance3D"):
		var mi: MeshInstance3D = c as MeshInstance3D
		print("  -> MeshInstance: ", mi.name, " mat_override: ", mi.material_override, " visible: ", mi.visible)
	return inst

func _process(_delta: float) -> void:
	_frames += 1
	if _frames == 10:
		var viewport: Viewport = get_viewport()
		var img: Image = viewport.get_texture().get_image()
		if img != null:
			img.save_png(OUTPUT_PATH)
			print("✅ SCREENSHOT SALVO: ", OUTPUT_PATH)
		get_tree().quit(0)
