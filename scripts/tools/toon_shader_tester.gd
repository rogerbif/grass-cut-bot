extends Node3D

# Shader Customizado com Gradientes e Rim Light (inspirado em MinionsArt)
const GRADIENT_SHADER: Shader = preload("res://shaders/tools/toon_gradient_custom.gdshader")
const OUTLINE_SHADER: Shader = preload("res://shaders/tools/toon_lab_outline.gdshader")

# Modelos do Projeto
const MODEL_BOT: PackedScene = preload("res://assets/models/grass_bot.glb")
const MODEL_GRASS: PackedScene = preload("res://assets/models/grass_01.glb")
const MODEL_WHEAT: PackedScene = preload("res://assets/models/wheat_01.glb")
const MODEL_FLOWER_01: PackedScene = preload("res://assets/models/flower_01.glb")
const MODEL_FLOWER_ROSE: PackedScene = preload("res://assets/models/flower_02_rose.glb")
const MODEL_FLOWER_DAISY: PackedScene = preload("res://assets/models/flower_03_daisy.glb")
const MODEL_FLOWER_SUNFLOWER: PackedScene = preload("res://assets/models/flower_04_sunflower.glb")
const MODEL_ROCK: PackedScene = preload("res://assets/models/rock.glb")

enum TargetModel {
	GRASS = 0,
	WHEAT = 1,
	FLOWER_ROSE = 2,
	FLOWER_DAISY = 3,
	FLOWER_SUNFLOWER = 4,
	ROCK = 5,
	ROBOT = 6,
	DIORAMA = 7
}

enum OutlineMode {
	NONE = 0,
	THIN = 1,
	MEDIUM = 2
}

# Referências de Nós 3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var turntable: Node3D = $Turntable
@onready var model_mount: Node3D = $Turntable/ModelMount
@onready var pedestal: MeshInstance3D = $Pedestal

# UI - TopBar e Toast
@onready var top_bar: HBoxContainer = $CanvasLayer/Control/TopBar
@onready var lbl_fps: Label = %LblFPS
@onready var toast_label: Label = %ToastLabel

# UI - Painéis Laterais
@onready var left_panel: PanelContainer = $CanvasLayer/Control/LeftPanel
@onready var right_panel: PanelContainer = $CanvasLayer/Control/RightPanel

# UI - Painel Esquerdo: Modelos
@onready var btn_mod_grass: Button = %BtnModGrass
@onready var btn_mod_wheat: Button = %BtnModWheat
@onready var btn_mod_rose: Button = %BtnModRose
@onready var btn_mod_daisy: Button = %BtnModDaisy
@onready var btn_mod_sunflower: Button = %BtnModSunflower
@onready var btn_mod_rock: Button = %BtnModRock
@onready var btn_mod_robot: Button = %BtnModRobot
@onready var btn_mod_diorama: Button = %BtnModDiorama

# UI - Painel Esquerdo: Luz & Sol
@onready var slider_sun_energy: HSlider = %SliderSunEnergy
@onready var lbl_sun_energy: Label = %LblSunEnergy

@onready var slider_ambient_energy: HSlider = %SliderAmbientEnergy
@onready var lbl_ambient_energy: Label = %LblAmbientEnergy

@onready var slider_sun_pitch: HSlider = %SliderSunPitch
@onready var lbl_sun_pitch: Label = %LblSunPitch

@onready var slider_sun_yaw: HSlider = %SliderSunYaw
@onready var lbl_sun_yaw: Label = %LblSunYaw

@onready var check_rotate_sun: CheckBox = %CheckRotateSun

# UI - Painel Esquerdo: Câmera & Alinhamento
@onready var lbl_cam_info: Label = %LblCamInfo
@onready var btn_align_game: Button = %BtnAlignGame
@onready var btn_align_sun_cam: Button = %BtnAlignSunCam
@onready var btn_copy_cam_sun: Button = %BtnCopyCamSun
@onready var btn_reset_cam: Button = %BtnResetCam
@onready var slider_cam_zoom: HSlider = %SliderCamZoom
@onready var check_turntable: CheckBox = %CheckTurntable

# UI - Painel Direito: Presets
@onready var btn_preset_grass: Button = %BtnPresetGrass
@onready var btn_preset_wheat: Button = %BtnPresetWheat
@onready var btn_preset_rose: Button = %BtnPresetRose
@onready var btn_preset_rock: Button = %BtnPresetRock
@onready var btn_preset_minions: Button = %BtnPresetMinions

# UI - Painel Direito: Pickers de Cor
@onready var picker_color_light: ColorPickerButton = %PickerColorLight
@onready var picker_color_base: ColorPickerButton = %PickerColorBase
@onready var picker_color_shadow: ColorPickerButton = %PickerColorShadow
@onready var picker_color_rim: ColorPickerButton = %PickerColorRim

# UI - Painel Direito: Sliders de Gradiente
@onready var slider_ramp_offset: HSlider = %SliderRampOffset
@onready var lbl_ramp_offset: Label = %LblRampOffset

@onready var slider_ramp_smooth: HSlider = %SliderRampSmooth
@onready var lbl_ramp_smooth: Label = %LblRampSmooth

@onready var slider_vert_grad: HSlider = %SliderVertGrad
@onready var lbl_vert_grad: Label = %LblVertGrad

@onready var slider_rim_power: HSlider = %SliderRimPower
@onready var lbl_rim_power: Label = %LblRimPower

@onready var slider_rim_brightness: HSlider = %SliderRimBrightness
@onready var lbl_rim_brightness: Label = %LblRimBrightness

@onready var slider_roughness: HSlider = %SliderRoughness
@onready var lbl_roughness: Label = %LblRoughness

# UI - Painel Direito: Outlines e Toggles
@onready var btn_out_none: Button = %BtnOutNone
@onready var btn_out_thin: Button = %BtnOutThin
@onready var btn_out_med: Button = %BtnOutMed
@onready var check_rim: CheckBox = %CheckRim
@onready var check_spec: CheckBox = %CheckSpec

# UI - Painel Direito: Copiar Parâmetros
@onready var btn_copy_params: Button = %BtnCopyParams

# Estado Atual
var current_model: TargetModel = TargetModel.GRASS
var current_outline: OutlineMode = OutlineMode.NONE
var is_turntable_active: bool = false
var is_rotating_sun: bool = false
var _active_material: ShaderMaterial = null

# Cache de Malhas do Modelo Ativo
var active_mesh_instances: Array[MeshInstance3D] = []
var blade_spinner_nodes: Array[Node3D] = []

# Câmera e Mouse Orbit
var is_dragging_mouse: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO
var cam_rot_x: float = -20.0
var cam_rot_y: float = 30.0
var cam_distance: float = 3.2

# Sol Rotação Atual
var sun_pitch: float = -45.0
var sun_yaw: float = -35.0

# Timer de Toast
var _toast_timer: float = 0.0

func _ready() -> void:
	_setup_desktop_window()
	_init_active_material()
	_setup_signals()
	_apply_preset("grass")
	_load_model(current_model)
	_sync_ui_from_material()
	_sync_lighting_ui()
	_update_model_materials()
	_update_ui_state()

func _setup_desktop_window() -> void:
	var win: Window = get_window()
	if OS.has_feature("pc") or OS.has_feature("windows") or OS.has_feature("macos") or OS.has_feature("linux"):
		win.content_scale_size = Vector2i(1920, 1080)
		win.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		var screen_rect: Rect2i = DisplayServer.screen_get_usable_rect()
		var target_w: int = mini(1600, int(float(screen_rect.size.x) * 0.95))
		var target_h: int = mini(920, int(float(screen_rect.size.y) * 0.90))
		var target_size: Vector2i = Vector2i(target_w, target_h)
		DisplayServer.window_set_size(target_size)
		var centered_pos: Vector2i = Vector2i(
			int(float(screen_rect.size.x - target_size.x) / 2.0),
			int(float(screen_rect.size.y - target_size.y) / 2.0)
		)
		DisplayServer.window_set_position(centered_pos)

func _init_active_material() -> void:
	_active_material = ShaderMaterial.new()
	_active_material.shader = GRADIENT_SHADER

func _process(delta: float) -> void:
	var fps: float = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / maxf(fps, 1.0)
	lbl_fps.text = "FPS: %d (%.1f ms)" % [int(fps), frame_ms]

	# Rotação da lâmina do robô
	for spinner: Node3D in blade_spinner_nodes:
		if is_instance_valid(spinner):
			spinner.rotate_y(deg_to_rad(720.0 * delta))

	# Turntable 360°
	if is_turntable_active and turntable != null:
		turntable.rotate_y(deg_to_rad(24.0 * delta))

	# Rotação contínua do Sol
	if is_rotating_sun and sun_light != null:
		sun_yaw = wrapf(sun_yaw + 24.0 * delta, -180.0, 180.0)
		_apply_sun_rotation()
		if slider_sun_yaw != null:
			slider_sun_yaw.value = sun_yaw

	# Atualiza rótulo de câmera/sol
	_update_cam_info_label()

	# Timer do Toast
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and toast_label != null:
			toast_label.visible = false

func _is_mouse_in_central_area(pos: Vector2) -> bool:
	# O mouse só orbita se estiver no vão central livre (entre os dois painéis)
	if top_bar != null and pos.y <= 60.0:
		return false
	if left_panel != null and pos.x <= left_panel.global_position.x + left_panel.size.x + 8.0:
		return false
	if right_panel != null and pos.x >= right_panel.global_position.x - 8.0:
		return false
	return true

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if _is_mouse_in_central_area(mb.position):
					is_dragging_mouse = true
					last_mouse_pos = mb.position
			else:
				is_dragging_mouse = false

		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _is_mouse_in_central_area(mb.position):
				cam_distance = clampf(cam_distance - 0.2, 0.8, 7.5)
				_update_camera_transform()
				if slider_cam_zoom != null:
					slider_cam_zoom.value = cam_distance

		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _is_mouse_in_central_area(mb.position):
				cam_distance = clampf(cam_distance + 0.2, 0.8, 7.5)
				_update_camera_transform()
				if slider_cam_zoom != null:
					slider_cam_zoom.value = cam_distance

	elif event is InputEventMouseMotion and is_dragging_mouse:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var diff: Vector2 = mm.position - last_mouse_pos
		last_mouse_pos = mm.position
		cam_rot_y -= diff.x * 0.35
		cam_rot_x = clampf(cam_rot_x - diff.y * 0.35, -80.0, 15.0)
		_update_camera_transform()

func _update_camera_transform() -> void:
	if camera_pivot == null or camera == null:
		return
	camera_pivot.rotation_degrees = Vector3(cam_rot_x, cam_rot_y, 0.0)
	camera.position = Vector3(0.0, 0.0, cam_distance)
	_update_cam_info_label()

func _apply_sun_rotation() -> void:
	if sun_light == null:
		return
	sun_light.rotation_degrees = Vector3(sun_pitch, sun_yaw, 0.0)
	if lbl_sun_pitch != null:
		lbl_sun_pitch.text = "Elevação do Sol (Pitch): %.1f°" % sun_pitch
	if lbl_sun_yaw != null:
		lbl_sun_yaw.text = "Azimute do Sol (Yaw): %.1f°" % sun_yaw
	_update_cam_info_label()

func _update_cam_info_label() -> void:
	if lbl_cam_info == null:
		return
	lbl_cam_info.text = "📷 Câmera: Pitch %.1f° | Yaw %.1f°\n☀️ Sol: Pitch %.1f° | Yaw %.1f°" % [
		cam_rot_x, cam_rot_y, sun_pitch, sun_yaw
	]

func _setup_signals() -> void:
	# Modelos (Painel Esquerdo)
	btn_mod_grass.pressed.connect(func() -> void: _set_target_model(TargetModel.GRASS))
	btn_mod_wheat.pressed.connect(func() -> void: _set_target_model(TargetModel.WHEAT))
	btn_mod_rose.pressed.connect(func() -> void: _set_target_model(TargetModel.FLOWER_ROSE))
	btn_mod_daisy.pressed.connect(func() -> void: _set_target_model(TargetModel.FLOWER_DAISY))
	btn_mod_sunflower.pressed.connect(func() -> void: _set_target_model(TargetModel.FLOWER_SUNFLOWER))
	btn_mod_rock.pressed.connect(func() -> void: _set_target_model(TargetModel.ROCK))
	btn_mod_robot.pressed.connect(func() -> void: _set_target_model(TargetModel.ROBOT))
	btn_mod_diorama.pressed.connect(func() -> void: _set_target_model(TargetModel.DIORAMA))

	# Luz & Sol (Painel Esquerdo)
	slider_sun_energy.value_changed.connect(func(v: float) -> void:
		if sun_light != null:
			sun_light.light_energy = v
		lbl_sun_energy.text = "Intensidade do Sol: %.2f" % v
	)
	slider_ambient_energy.value_changed.connect(func(v: float) -> void:
		if world_environment != null and world_environment.environment != null:
			world_environment.environment.ambient_light_energy = v
		lbl_ambient_energy.text = "Intensidade Luz Ambiente: %.2f" % v
	)
	slider_sun_pitch.value_changed.connect(func(v: float) -> void:
		sun_pitch = v
		_apply_sun_rotation()
	)
	slider_sun_yaw.value_changed.connect(func(v: float) -> void:
		sun_yaw = v
		_apply_sun_rotation()
	)
	check_rotate_sun.toggled.connect(func(t: bool) -> void:
		is_rotating_sun = t
	)

	# Câmera & Alinhamento (Painel Esquerdo)
	btn_align_game.pressed.connect(_align_camera_to_game)
	btn_align_sun_cam.pressed.connect(_align_sun_to_camera)
	btn_copy_cam_sun.pressed.connect(_copy_camera_and_sun_info)
	btn_reset_cam.pressed.connect(_reset_camera_default)
	slider_cam_zoom.value_changed.connect(func(v: float) -> void:
		cam_distance = v
		_update_camera_transform()
	)
	check_turntable.toggled.connect(func(t: bool) -> void:
		is_turntable_active = t
	)

	# Presets (Painel Direito)
	btn_preset_grass.pressed.connect(func() -> void: _apply_preset("grass"))
	btn_preset_wheat.pressed.connect(func() -> void: _apply_preset("wheat"))
	btn_preset_rose.pressed.connect(func() -> void: _apply_preset("rose"))
	btn_preset_rock.pressed.connect(func() -> void: _apply_preset("rock"))
	btn_preset_minions.pressed.connect(func() -> void: _apply_preset("minions"))

	# Cores (Painel Direito)
	picker_color_light.color_changed.connect(func(c: Color) -> void:
		_active_material.set_shader_parameter("color_light", c)
	)
	picker_color_base.color_changed.connect(func(c: Color) -> void:
		_active_material.set_shader_parameter("color_base", c)
	)
	picker_color_shadow.color_changed.connect(func(c: Color) -> void:
		_active_material.set_shader_parameter("color_shadow", c)
	)
	picker_color_rim.color_changed.connect(func(c: Color) -> void:
		_active_material.set_shader_parameter("rim_color", c)
	)

	# Sliders de Gradiente (Painel Direito)
	slider_ramp_offset.value_changed.connect(func(v: float) -> void:
		_active_material.set_shader_parameter("toon_ramp_offset", v)
		lbl_ramp_offset.text = "Offset do Corte: %.2f" % v
	)
	slider_ramp_smooth.value_changed.connect(func(v: float) -> void:
		_active_material.set_shader_parameter("toon_ramp_smoothness", v)
		lbl_ramp_smooth.text = "Suavidade do Gradiente: %.2f" % v
	)
	slider_vert_grad.value_changed.connect(func(v: float) -> void:
		_active_material.set_shader_parameter("vertical_gradient_mix", v)
		lbl_vert_grad.text = "Gradiente Vertical (Base-Topo): %.2f" % v
	)
	slider_rim_power.value_changed.connect(func(v: float) -> void:
		_active_material.set_shader_parameter("rim_power", v)
		lbl_rim_power.text = "Foco Rim Light (Potência): %.1f" % v
	)
	slider_rim_brightness.value_changed.connect(func(v: float) -> void:
		_active_material.set_shader_parameter("rim_brightness", v)
		lbl_rim_brightness.text = "Brilho Rim Light: %.2f" % v
	)
	slider_roughness.value_changed.connect(func(v: float) -> void:
		_active_material.set_shader_parameter("roughness", v)
		lbl_roughness.text = "Rugosidade Fosca: %.2f" % v
	)

	# Toggles (Painel Direito)
	check_rim.toggled.connect(func(t: bool) -> void:
		_active_material.set_shader_parameter("use_rim", t)
	)
	check_spec.toggled.connect(func(t: bool) -> void:
		_active_material.set_shader_parameter("use_specular", t)
	)

	# Outlines (Painel Direito)
	btn_out_none.pressed.connect(func() -> void: _set_outline_mode(OutlineMode.NONE))
	btn_out_thin.pressed.connect(func() -> void: _set_outline_mode(OutlineMode.THIN))
	btn_out_med.pressed.connect(func() -> void: _set_outline_mode(OutlineMode.MEDIUM))

	# Copiar Parâmetros do Shader (Painel Direito)
	btn_copy_params.pressed.connect(_on_btn_copy_pressed)

func _align_camera_to_game() -> void:
	# Ângulo canônico do Grass Cut Bot: pitch de -40.3°, yaw de 0°, sol em -45° pitch / -35° yaw
	cam_rot_x = -40.3
	cam_rot_y = 0.0
	cam_distance = 3.4
	sun_pitch = -45.0
	sun_yaw = -35.0
	if turntable != null:
		turntable.rotation_degrees = Vector3.ZERO
	_update_camera_transform()
	_apply_sun_rotation()
	if slider_cam_zoom != null:
		slider_cam_zoom.value = cam_distance
	if slider_sun_pitch != null:
		slider_sun_pitch.value = sun_pitch
	if slider_sun_yaw != null:
		slider_sun_yaw.value = sun_yaw
	_show_toast("🎮 Ângulo Canônico do Jogo Aplicado!")

func _align_sun_to_camera() -> void:
	# Ajusta o sol para incidir diretamente do mesmo ponto de vista da câmera
	sun_pitch = cam_rot_x
	sun_yaw = cam_rot_y
	_apply_sun_rotation()
	if slider_sun_pitch != null:
		slider_sun_pitch.value = sun_pitch
	if slider_sun_yaw != null:
		slider_sun_yaw.value = sun_yaw
	_show_toast("☀️ Luz do Sol Alinhada com a Câmera!")

func _reset_camera_default() -> void:
	cam_rot_x = -20.0
	cam_rot_y = 30.0
	cam_distance = 3.2
	if turntable != null:
		turntable.rotation_degrees = Vector3.ZERO
	_update_camera_transform()
	if slider_cam_zoom != null:
		slider_cam_zoom.value = cam_distance
	_show_toast("↺ Câmera Resetada!")

func _copy_camera_and_sun_info() -> void:
	var cam_dir: Vector3 = -camera.global_transform.basis.z.normalized()
	var sun_dir: Vector3 = -sun_light.global_transform.basis.z.normalized()
	var sun_nrg: float = sun_light.light_energy
	var amb_nrg: float = world_environment.environment.ambient_light_energy if (world_environment and world_environment.environment) else 0.32

	var snippet: String = """# Transform & Iluminação (Godot 4)
camera_rotation_deg = Vector3(%.1f, %.1f, 0.0)
camera_distance = %.2f
camera_view_direction = Vector3(%.3f, %.3f, %.3f)

sun_rotation_deg = Vector3(%.1f, %.1f, 0.0)
sun_direction = Vector3(%.3f, %.3f, %.3f)
sun_energy = %.2f
ambient_energy = %.2f
""" % [
		cam_rot_x, cam_rot_y, cam_distance,
		cam_dir.x, cam_dir.y, cam_dir.z,
		sun_pitch, sun_yaw,
		sun_dir.x, sun_dir.y, sun_dir.z,
		sun_nrg, amb_nrg
	]

	DisplayServer.clipboard_set(snippet)
	_show_toast("📋 Ângulos da Câmera e Sol Copiados!")

func _sync_lighting_ui() -> void:
	if sun_light != null:
		sun_pitch = sun_light.rotation_degrees.x
		sun_yaw = sun_light.rotation_degrees.y
		slider_sun_energy.value = sun_light.light_energy
		lbl_sun_energy.text = "Intensidade do Sol: %.2f" % sun_light.light_energy
		slider_sun_pitch.value = sun_pitch
		lbl_sun_pitch.text = "Elevação do Sol (Pitch): %.1f°" % sun_pitch
		slider_sun_yaw.value = sun_yaw
		lbl_sun_yaw.text = "Azimute do Sol (Yaw): %.1f°" % sun_yaw

	if world_environment != null and world_environment.environment != null:
		var amb: float = world_environment.environment.ambient_light_energy
		slider_ambient_energy.value = amb
		lbl_ambient_energy.text = "Intensidade Luz Ambiente: %.2f" % amb

	_update_cam_info_label()

func _set_target_model(mod: TargetModel) -> void:
	current_model = mod
	_load_model(current_model)
	_update_model_materials()
	_update_ui_state()

func _set_outline_mode(o: OutlineMode) -> void:
	current_outline = o
	_update_model_materials()
	_update_ui_state()

func _load_model(target: TargetModel) -> void:
	for c: Node in model_mount.get_children():
		model_mount.remove_child(c)
		c.queue_free()
	active_mesh_instances.clear()
	blade_spinner_nodes.clear()

	match target:
		TargetModel.GRASS:
			var g: Node3D = MODEL_GRASS.instantiate() as Node3D
			g.scale = Vector3(1.6, 1.6, 1.6)
			model_mount.add_child(g)
			_active_material.set_shader_parameter("model_height_scale", 1.2)

		TargetModel.WHEAT:
			var w: Node3D = MODEL_WHEAT.instantiate() as Node3D
			w.scale = Vector3(1.5, 1.5, 1.5)
			model_mount.add_child(w)
			_active_material.set_shader_parameter("model_height_scale", 1.4)

		TargetModel.FLOWER_ROSE:
			var r: Node3D = MODEL_FLOWER_ROSE.instantiate() as Node3D
			r.scale = Vector3(1.4, 1.4, 1.4)
			model_mount.add_child(r)
			_active_material.set_shader_parameter("model_height_scale", 1.3)

		TargetModel.FLOWER_DAISY:
			var d: Node3D = MODEL_FLOWER_DAISY.instantiate() as Node3D
			d.scale = Vector3(1.4, 1.4, 1.4)
			model_mount.add_child(d)
			_active_material.set_shader_parameter("model_height_scale", 1.3)

		TargetModel.FLOWER_SUNFLOWER:
			var s: Node3D = MODEL_FLOWER_SUNFLOWER.instantiate() as Node3D
			s.scale = Vector3(1.3, 1.3, 1.3)
			model_mount.add_child(s)
			_active_material.set_shader_parameter("model_height_scale", 1.5)

		TargetModel.ROCK:
			var rk: Node3D = MODEL_ROCK.instantiate() as Node3D
			rk.scale = Vector3(1.4, 1.4, 1.4)
			model_mount.add_child(rk)
			_active_material.set_shader_parameter("model_height_scale", 1.6)

		TargetModel.ROBOT:
			var bot: Node3D = MODEL_BOT.instantiate() as Node3D
			bot.scale = Vector3(0.9, 0.9, 0.9)
			bot.position = Vector3(0.0, 0.05, 0.0)
			model_mount.add_child(bot)
			_active_material.set_shader_parameter("model_height_scale", 1.8)
			var blade: Node3D = bot.find_child("BladeSpinner", true, false) as Node3D
			if blade != null:
				blade_spinner_nodes.append(blade)

		TargetModel.DIORAMA:
			var bot: Node3D = MODEL_BOT.instantiate() as Node3D
			bot.scale = Vector3(0.75, 0.75, 0.75)
			bot.position = Vector3(0.0, 0.05, -0.1)
			model_mount.add_child(bot)
			var blade: Node3D = bot.find_child("BladeSpinner", true, false) as Node3D
			if blade != null:
				blade_spinner_nodes.append(blade)

			var g1: Node3D = MODEL_GRASS.instantiate() as Node3D
			g1.position = Vector3(-1.0, 0.0, 0.7)
			g1.scale = Vector3(1.1, 1.1, 1.1)
			model_mount.add_child(g1)

			var w1: Node3D = MODEL_WHEAT.instantiate() as Node3D
			w1.position = Vector3(1.0, 0.0, 0.6)
			w1.scale = Vector3(1.1, 1.1, 1.1)
			model_mount.add_child(w1)

			var f1: Node3D = MODEL_FLOWER_ROSE.instantiate() as Node3D
			f1.position = Vector3(0.8, 0.0, -0.9)
			f1.scale = Vector3(1.1, 1.1, 1.1)
			model_mount.add_child(f1)

			var r1: Node3D = MODEL_ROCK.instantiate() as Node3D
			r1.position = Vector3(-0.9, 0.0, -0.8)
			r1.scale = Vector3(0.85, 0.85, 0.85)
			model_mount.add_child(r1)

	_collect_meshes(model_mount)

func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		active_mesh_instances.append(node as MeshInstance3D)
	for c: Node in node.get_children():
		_collect_meshes(c)

func _update_model_materials() -> void:
	for mi: MeshInstance3D in active_mesh_instances:
		if not is_instance_valid(mi):
			continue

		if current_outline != OutlineMode.NONE:
			var out_mat: ShaderMaterial = ShaderMaterial.new()
			out_mat.shader = OUTLINE_SHADER
			var thick: float = 0.015 if current_outline == OutlineMode.THIN else 0.030
			out_mat.set_shader_parameter("outline_thickness", thick)
			var cur_shadow: Color = _active_material.get_shader_parameter("color_shadow") as Color
			out_mat.set_shader_parameter("outline_color", Color(cur_shadow.r * 0.4, cur_shadow.g * 0.4, cur_shadow.b * 0.45, 1.0))
			_active_material.next_pass = out_mat
		else:
			_active_material.next_pass = null

		mi.material_override = _active_material

func _apply_preset(preset_name: String) -> void:
	match preset_name:
		"grass":
			_active_material.set_shader_parameter("color_light", Color(0.42, 0.88, 0.46, 1.0))
			_active_material.set_shader_parameter("color_base", Color(0.12, 0.35, 0.18, 1.0))
			_active_material.set_shader_parameter("color_shadow", Color(0.18, 0.48, 0.25, 1.0))
			_active_material.set_shader_parameter("rim_color", Color(0.85, 1.0, 0.65, 1.0))
			_active_material.set_shader_parameter("toon_ramp_offset", 0.46)
			_active_material.set_shader_parameter("toon_ramp_smoothness", 0.08)
			_active_material.set_shader_parameter("vertical_gradient_mix", 0.55)
			_active_material.set_shader_parameter("rim_power", 2.2)
			_active_material.set_shader_parameter("rim_brightness", 1.4)
			_active_material.set_shader_parameter("roughness", 0.90)

		"wheat":
			_active_material.set_shader_parameter("color_light", Color(0.98, 0.78, 0.22, 1.0))
			_active_material.set_shader_parameter("color_base", Color(0.55, 0.32, 0.08, 1.0))
			_active_material.set_shader_parameter("color_shadow", Color(0.68, 0.45, 0.12, 1.0))
			_active_material.set_shader_parameter("rim_color", Color(1.0, 0.95, 0.70, 1.0))
			_active_material.set_shader_parameter("toon_ramp_offset", 0.45)
			_active_material.set_shader_parameter("toon_ramp_smoothness", 0.10)
			_active_material.set_shader_parameter("vertical_gradient_mix", 0.55)
			_active_material.set_shader_parameter("rim_power", 1.8)
			_active_material.set_shader_parameter("rim_brightness", 1.6)
			_active_material.set_shader_parameter("roughness", 0.88)

		"rose":
			_active_material.set_shader_parameter("color_light", Color(0.95, 0.22, 0.45, 1.0))
			_active_material.set_shader_parameter("color_base", Color(0.42, 0.08, 0.18, 1.0))
			_active_material.set_shader_parameter("color_shadow", Color(0.58, 0.12, 0.25, 1.0))
			_active_material.set_shader_parameter("rim_color", Color(1.0, 0.75, 0.85, 1.0))
			_active_material.set_shader_parameter("toon_ramp_offset", 0.50)
			_active_material.set_shader_parameter("toon_ramp_smoothness", 0.14)
			_active_material.set_shader_parameter("vertical_gradient_mix", 0.45)
			_active_material.set_shader_parameter("rim_power", 2.0)
			_active_material.set_shader_parameter("rim_brightness", 1.5)
			_active_material.set_shader_parameter("roughness", 0.90)

		"rock":
			_active_material.set_shader_parameter("color_light", Color(0.55, 0.64, 0.72, 1.0))
			_active_material.set_shader_parameter("color_base", Color(0.20, 0.25, 0.32, 1.0))
			_active_material.set_shader_parameter("color_shadow", Color(0.26, 0.32, 0.40, 1.0))
			_active_material.set_shader_parameter("rim_color", Color(0.80, 0.88, 0.95, 1.0))
			_active_material.set_shader_parameter("toon_ramp_offset", 0.42)
			_active_material.set_shader_parameter("toon_ramp_smoothness", 0.04)
			_active_material.set_shader_parameter("vertical_gradient_mix", 0.35)
			_active_material.set_shader_parameter("rim_power", 3.0)
			_active_material.set_shader_parameter("rim_brightness", 1.1)
			_active_material.set_shader_parameter("roughness", 0.92)

		"minions":
			_active_material.set_shader_parameter("color_light", Color(0.90, 0.90, 0.90, 1.0))
			_active_material.set_shader_parameter("color_base", Color(0.40, 0.40, 0.45, 1.0))
			_active_material.set_shader_parameter("color_shadow", Color(0.30, 0.30, 0.40, 1.0))
			_active_material.set_shader_parameter("rim_color", Color(1.0, 1.0, 1.0, 1.0))
			_active_material.set_shader_parameter("toon_ramp_offset", 0.50)
			_active_material.set_shader_parameter("toon_ramp_smoothness", 0.05)
			_active_material.set_shader_parameter("vertical_gradient_mix", 0.0)
			_active_material.set_shader_parameter("rim_power", 1.0)
			_active_material.set_shader_parameter("rim_brightness", 2.0)
			_active_material.set_shader_parameter("roughness", 0.90)

	_sync_ui_from_material()
	_update_model_materials()
	_show_toast("Preset '%s' carregado!" % preset_name.capitalize())

func _sync_ui_from_material() -> void:
	if _active_material == null:
		return

	var cl: Color = _active_material.get_shader_parameter("color_light") as Color
	var cb: Color = _active_material.get_shader_parameter("color_base") as Color
	var cs: Color = _active_material.get_shader_parameter("color_shadow") as Color
	var cr: Color = _active_material.get_shader_parameter("rim_color") as Color

	picker_color_light.color = cl
	picker_color_base.color = cb
	picker_color_shadow.color = cs
	picker_color_rim.color = cr

	var r_off: float = float(_active_material.get_shader_parameter("toon_ramp_offset"))
	var r_sm: float = float(_active_material.get_shader_parameter("toon_ramp_smoothness"))
	var v_gr: float = float(_active_material.get_shader_parameter("vertical_gradient_mix"))
	var r_pw: float = float(_active_material.get_shader_parameter("rim_power"))
	var r_br: float = float(_active_material.get_shader_parameter("rim_brightness"))
	var ro: float = float(_active_material.get_shader_parameter("roughness"))

	slider_ramp_offset.value = r_off
	lbl_ramp_offset.text = "Offset do Corte: %.2f" % r_off

	slider_ramp_smooth.value = r_sm
	lbl_ramp_smooth.text = "Suavidade do Gradiente: %.2f" % r_sm

	slider_vert_grad.value = v_gr
	lbl_vert_grad.text = "Gradiente Vertical (Base-Topo): %.2f" % v_gr

	slider_rim_power.value = r_pw
	lbl_rim_power.text = "Foco Rim Light (Potência): %.1f" % r_pw

	slider_rim_brightness.value = r_br
	lbl_rim_brightness.text = "Brilho Rim Light: %.2f" % r_br

	slider_roughness.value = ro
	lbl_roughness.text = "Rugosidade Fosca: %.2f" % ro

func _on_btn_copy_pressed() -> void:
	var cl: Color = _active_material.get_shader_parameter("color_light") as Color
	var cb: Color = _active_material.get_shader_parameter("color_base") as Color
	var cs: Color = _active_material.get_shader_parameter("color_shadow") as Color
	var cr: Color = _active_material.get_shader_parameter("rim_color") as Color
	var r_off: float = float(_active_material.get_shader_parameter("toon_ramp_offset"))
	var r_sm: float = float(_active_material.get_shader_parameter("toon_ramp_smoothness"))
	var v_gr: float = float(_active_material.get_shader_parameter("vertical_gradient_mix"))
	var r_pw: float = float(_active_material.get_shader_parameter("rim_power"))
	var r_br: float = float(_active_material.get_shader_parameter("rim_brightness"))
	var ro: float = float(_active_material.get_shader_parameter("roughness"))

	var code_snippet: String = """# Parâmetros Toon Shader Gradiente
color_light = Color(%.2f, %.2f, %.2f)
color_base = Color(%.2f, %.2f, %.2f)
color_shadow = Color(%.2f, %.2f, %.2f)
rim_color = Color(%.2f, %.2f, %.2f)
toon_ramp_offset = %.2f
toon_ramp_smoothness = %.2f
vertical_gradient_mix = %.2f
rim_power = %.2f
rim_brightness = %.2f
roughness = %.2f
""" % [
		cl.r, cl.g, cl.b,
		cb.r, cb.g, cb.b,
		cs.r, cs.g, cs.b,
		cr.r, cr.g, cr.b,
		r_off, r_sm, v_gr, r_pw, r_br, ro
	]

	DisplayServer.clipboard_set(code_snippet)
	_show_toast("✅ Parâmetros do Shader Copiados!")

func _show_toast(msg: String) -> void:
	if toast_label == null:
		return
	toast_label.text = msg
	toast_label.visible = true
	_toast_timer = 3.0

func _update_ui_state() -> void:
	_highlight_button(btn_mod_grass, current_model == TargetModel.GRASS)
	_highlight_button(btn_mod_wheat, current_model == TargetModel.WHEAT)
	_highlight_button(btn_mod_rose, current_model == TargetModel.FLOWER_ROSE)
	_highlight_button(btn_mod_daisy, current_model == TargetModel.FLOWER_DAISY)
	_highlight_button(btn_mod_sunflower, current_model == TargetModel.FLOWER_SUNFLOWER)
	_highlight_button(btn_mod_rock, current_model == TargetModel.ROCK)
	_highlight_button(btn_mod_robot, current_model == TargetModel.ROBOT)
	_highlight_button(btn_mod_diorama, current_model == TargetModel.DIORAMA)

	_highlight_button(btn_out_none, current_outline == OutlineMode.NONE)
	_highlight_button(btn_out_thin, current_outline == OutlineMode.THIN)
	_highlight_button(btn_out_med, current_outline == OutlineMode.MEDIUM)

func _highlight_button(btn: Button, active: bool) -> void:
	if btn == null:
		return
	if active:
		btn.modulate = Color(1.3, 1.25, 0.4, 1.0)
	else:
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
