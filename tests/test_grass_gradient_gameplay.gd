extends SceneTree

var _timer: float = 0.0
var _captured: bool = false
var _main_scene: Node = null

func _init() -> void:
	print("Carregando gameplay real para avaliar novo gradiente de grama...")

func _process(delta: float) -> bool:
	_timer += delta
	if _main_scene == null:
		var scene_res = load("res://scenes/main.tscn")
		_main_scene = scene_res.instantiate()
		root.add_child(_main_scene)
		var lc = _main_scene.get_node_or_null("LevelController")
		if lc:
			lc.generate_level(5)
		return false

	if _timer > 0.45 and not _captured:
		_captured = true
		var vp: Viewport = root.get_viewport()
		var img: Image = vp.get_texture().get_image()
		var out_path: String = "C:/Users/User/.gemini/antigravity/brain/4f80e1fe-994e-4f54-8908-a19dbda5cbb9/gameplay_grass_gradient_level5.png"
		img.save_png(out_path)
		print("Screenshot capturada em: ", out_path)
		quit()
		return true

	return false
