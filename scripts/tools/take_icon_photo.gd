extends Node3D

## Estúdio Fotográfico do Cutter Bit
## Captura a foto do robô sorrindo em 1024x1024 com expressão HAPPY e iluminação 3-pontos.

@onready var menu_bot: Node3D = $MenuBot
@onready var camera: Camera3D = $Camera3D

var _frame_count: int = 0
var _captured: bool = false

func _ready() -> void:
	print("[ICON_STUDIO] Inicializando Estúdio Fotográfico...")
	get_window().size = Vector2i(1024, 1024)
	_setup_bot_pose()

func _setup_bot_pose() -> void:
	if menu_bot == null:
		print("[ICON_STUDIO] ERRO: MenuBot não encontrado!")
		return

	# Desativa locomoção e rotação autônoma do menu_bot
	menu_bot.set_process(false)

	var robot_body: Node3D = menu_bot.get_node_or_null("VisualPivot/GrassBot/Robot/Body") as Node3D
	var head_node: Node3D = menu_bot.get_node_or_null("VisualPivot/GrassBot/Robot/Body/head") as Node3D
	var blade_spinner: Node3D = menu_bot.get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner") as Node3D
	var robot_eyes: RobotEyes = menu_bot.get_node_or_null("RobotEyes") as RobotEyes

	var b1: MeshInstance3D = menu_bot.get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_1") as MeshInstance3D
	var b2: MeshInstance3D = menu_bot.get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_2") as MeshInstance3D
	var b3: MeshInstance3D = menu_bot.get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_3") as MeshInstance3D
	var b4: MeshInstance3D = menu_bot.get_node_or_null("VisualPivot/GrassBot/Robot/BladeSpinner/blade_tier_4") as MeshInstance3D

	if b1 != null: b1.visible = false
	if b2 != null: b2.visible = true
	if b3 != null: b3.visible = false
	if b4 != null: b4.visible = false

	if robot_body != null:
		robot_body.rotation_degrees = Vector3(0.0, -18.0, 0.0)

	if head_node != null:
		head_node.rotation_degrees = Vector3(5.0, 10.0, -5.0)

	if blade_spinner != null:
		blade_spinner.rotation_degrees = Vector3(0.0, 30.0, 0.0)

	if robot_eyes != null:
		robot_eyes.auto_blink_enabled = false
		var screen_mesh: MeshInstance3D = null
		if head_node != null:
			screen_mesh = head_node.find_child("screen_display*", true, false) as MeshInstance3D
		if screen_mesh == null:
			screen_mesh = menu_bot.find_child("screen_display*", true, false) as MeshInstance3D

		if screen_mesh != null:
			var eye_mat: Material = preload("res://shaders/eye_display_material.tres")
			screen_mesh.set_surface_override_material(0, eye_mat)
			robot_eyes.screen_mesh = screen_mesh
			robot_eyes._ready()
			robot_eyes.set_expression(RobotEyes.EyeExpression.HAPPY)

			var mat: Material = screen_mesh.get_surface_override_material(0)
			if mat is ShaderMaterial:
				(mat as ShaderMaterial).set_shader_parameter("emission_energy", 2.2)

	# Calibra iluminação para evitar superexposição no branco e amarelo
	var world_env: WorldEnvironment = get_node_or_null("WorldEnvironment") as WorldEnvironment
	if world_env != null and world_env.environment != null:
		world_env.environment.ambient_light_energy = 0.35
		world_env.environment.tonemap_exposure = 1.0

	var key_light: DirectionalLight3D = get_node_or_null("KeySunLight") as DirectionalLight3D
	if key_light != null:
		key_light.light_energy = 1.0
		key_light.light_color = Color(1.0, 0.97, 0.93)

	var rim_light: DirectionalLight3D = get_node_or_null("RimBackLight") as DirectionalLight3D
	if rim_light != null:
		rim_light.light_energy = 0.80

	var fill_light: DirectionalLight3D = get_node_or_null("FillLight") as DirectionalLight3D
	if fill_light != null:
		fill_light.light_energy = 0.35

	var backdrop: MeshInstance3D = get_node_or_null("BackdropMesh") as MeshInstance3D

	if camera != null and head_node != null:
		var head_pos: Vector3 = head_node.global_position
		print("[ICON_STUDIO] Head global pos: ", head_pos)
		
		if backdrop != null:
			backdrop.position = Vector3(head_pos.x * 0.3, head_pos.y, -2.2)

		# Ponto focal centrado perfeitamente no Cutter Bit com margens harmônicas
		var focal_point: Vector3 = Vector3(head_pos.x * 0.15 + 0.05, head_pos.y - 0.20, 0.0)
		# Câmera com ângulo 3/4 clássico elevado (+17°), recuo para enquadrar ombros e cabeça inteira
		camera.position = focal_point + Vector3(0.06, 0.52, 2.65)
		camera.look_at(focal_point, Vector3.UP)
		camera.fov = 32.0

func _process(_delta: float) -> void:
	_frame_count += 1
	if _frame_count == 25 and not _captured:
		_captured = true
		_capture_and_save_icon()

func _capture_and_save_icon() -> void:
	print("[ICON_STUDIO] Capturando fotografia do viewport...")
	var img: Image = get_viewport().get_texture().get_image()
	if img == null or img.is_empty():
		print("[ICON_STUDIO] ERRO: Imagem vazia!")
		get_tree().quit(1)
		return

	# Garante que o master esteja exatamente em 1024x1024
	if img.get_width() != 1024 or img.get_height() != 1024:
		img.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)

	var dir: DirAccess = DirAccess.open("res://")
	if dir != null and not dir.dir_exists("res://assets/brand"):
		dir.make_dir_recursive("res://assets/brand")

	# 1. Master 1024x1024
	var path_1024: String = "res://assets/brand/icon_1024.png"
	img.save_png(path_1024)
	print("[ICON_STUDIO] Salvo: %s" % path_1024)

	# 2. Raiz do projeto res://icon.png
	var path_root: String = "res://icon.png"
	img.save_png(path_root)
	print("[ICON_STUDIO] Salvo: %s" % path_root)

	# 3. Versão 512x512
	var img_512: Image = Image.new()
	img_512.copy_from(img)
	img_512.resize(512, 512, Image.INTERPOLATE_LANCZOS)
	img_512.save_png("res://assets/brand/icon_512.png")
	print("[ICON_STUDIO] Salvo: res://assets/brand/icon_512.png")

	# 4. Versão 432x432 (Adaptive Icon Foreground Android)
	var img_432: Image = Image.new()
	img_432.copy_from(img)
	img_432.resize(432, 432, Image.INTERPOLATE_LANCZOS)
	img_432.save_png("res://assets/brand/icon_432.png")
	print("[ICON_STUDIO] Salvo: res://assets/brand/icon_432.png")

	# 5. Versão 192x192 (Launcher Icon Mobile)
	var img_192: Image = Image.new()
	img_192.copy_from(img)
	img_192.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	img_192.save_png("res://assets/brand/icon_192.png")
	print("[ICON_STUDIO] Salvo: res://assets/brand/icon_192.png")

	print("[ICON_STUDIO] SUCESSO: Todas as imagens foram gravadas!")
	get_tree().quit(0)
