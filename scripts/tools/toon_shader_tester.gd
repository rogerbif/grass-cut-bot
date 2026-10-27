extends Node3D

# Materiais e Shaders Canônicos do Jogo
const GRASS_MATERIAL: ShaderMaterial = preload("res://shaders/interactive_grass_material.tres")
const OUTLINE_SHADER: Shader = preload("res://shaders/tools/toon_lab_outline.gdshader")

# Carregadores de Nível e Entidades
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const CUTTER_SCENE: PackedScene = preload("res://scenes/cutter/cutter.tscn")

# Modelos Avulsos para o Modo Estúdio
const MODEL_BOT: PackedScene = preload("res://assets/models/grass_bot.glb")
const MODEL_GRASS: PackedScene = preload("res://assets/models/grass_01.glb")
const MODEL_WHEAT: PackedScene = preload("res://assets/models/wheat_01.glb")
const MODEL_FLOWER_ROSE: PackedScene = preload("res://assets/models/flower_02_rose.glb")
const MODEL_FLOWER_DAISY: PackedScene = preload("res://assets/models/flower_03_daisy.glb")
const MODEL_FLOWER_SUNFLOWER: PackedScene = preload("res://assets/models/flower_04_sunflower.glb")
const MODEL_ROCK: PackedScene = preload("res://assets/models/rock.glb")

enum TargetModel {
	FULL_LEVEL = 0,
	GRASS = 1,
	WHEAT = 2,
	FLOWER_ROSE = 3,
	FLOWER_DAISY = 4,
	FLOWER_SUNFLOWER = 5,
	ROCK = 6,
	ROBOT = 7,
	DIORAMA = 8
}

enum OutlineMode {
	NONE = 0,
	THIN = 1,
	MEDIUM = 2
}

# Referências de Nós 3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var level_container: Node3D = $LevelContainer
@onready var ground_mesh: MeshInstance3D = $GroundMesh
@onready var pedestal: MeshInstance3D = $Pedestal
@onready var turntable: Node3D = $Turntable
@onready var model_mount: Node3D = $Turntable/ModelMount
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D

# UI - TopBar e Toast
@onready var top_bar: HBoxContainer = $CanvasLayer/Control/TopBar
@onready var lbl_fps: Label = %LblFPS
@onready var toast_label: Label = %ToastLabel

# UI - Painéis Laterais
@onready var left_panel: PanelContainer = $CanvasLayer/Control/LeftPanel
@onready var right_panel: PanelContainer = $CanvasLayer/Control/RightPanel

# UI - Painel Esquerdo: Modo de Exibição & Níveis
@onready var btn_mod_level: Button = %BtnModLevel
@onready var btn_level_prev: Button = %BtnLevelPrev
@onready var btn_level_next: Button = %BtnLevelNext
@onready var lbl_current_level: Label = %LblCurrentLevel

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

# UI - Painel Direito: Pickers de Cor da Vegetação
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

# UI - Painel Direito: Solo da Ilha (Chão)
@onready var picker_color_ground: ColorPickerButton = %PickerColorGround
@onready var slider_ground_brightness: HSlider = %SliderGroundBrightness
@onready var lbl_ground_brightness: Label = %LblGroundBrightness
@onready var check_ground_pedestal: CheckBox = %CheckGroundPedestal
@onready var check_ground_toon: CheckBox = %CheckGroundToon
@onready var btn_ground_preset_dark: Button = %BtnGroundPresetDark
@onready var btn_ground_preset_light: Button = %BtnGroundPresetLight

# UI - Painel Direito: Outlines e Toggles
@onready var btn_out_none: Button = %BtnOutNone
@onready var btn_out_thin: Button = %BtnOutThin
@onready var btn_out_med: Button = %BtnOutMed
@onready var check_rim: CheckBox = %CheckRim
@onready var check_spec: CheckBox = %CheckSpec

# UI - Painel Direito: Salvar & Copiar Parâmetros
@onready var btn_save_to_game: Button = %BtnSaveToGame
@onready var btn_copy_params: Button = %BtnCopyParams

# Estado Atual
var current_model: TargetModel = TargetModel.FULL_LEVEL
var current_level_num: int = 1
var current_outline: OutlineMode = OutlineMode.NONE
var is_turntable_active: bool = false
var is_rotating_sun: bool = false
var _active_material: ShaderMaterial = null

# Estado do Solo
var ground_base_color: Color = Color(0.14, 0.59, 0.22, 1.0)
var ground_brightness: float = 0.80
var apply_ground_to_pedestal: bool = true
var use_ground_toon: bool = true
var _ground_material: StandardMaterial3D = null

# Cache de Malhas e Nós Dinâmicos
var active_mesh_instances: Array[MeshInstance3D] = []
var blade_spinner_nodes: Array[Node3D] = []
var _cached_island_mi: MeshInstance3D = null
var _cached_island_polys: Array[PackedVector2Array] = []

# Câmera Orbit e Pan
var is_dragging_mouse: bool = false
var is_panning_mouse: bool = false
var last_mouse_pos: Vector2 = Vector2.ZERO
var cam_rot_x: float = -40.3
var cam_rot_y: float = 0.0
var cam_distance: float = 7.4
var cam_target: Vector3 = Vector3.ZERO

# Sol Rotação Atual
var sun_pitch: float = -37.0
var sun_yaw: float = 40.0

# Timer de Toast
var _toast_timer: float = 0.0

func _ready() -> void:
	_setup_desktop_window()
	_init_active_material()
	_init_ground_material()
	_setup_signals()
	_sync_lighting_ui()
	_sync_ground_ui()
	_sync_ui_from_material()
	_load_model(current_model)
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
	_active_material = GRASS_MATERIAL

func _init_ground_material() -> void:
	ground_base_color = IslandMeshBuilder.ground_base_color
	ground_brightness = IslandMeshBuilder.ground_brightness
	use_ground_toon = IslandMeshBuilder.ground_diffuse_toon
	_ground_material = IslandMeshBuilder.get_island_material()
	_update_ground_material()

func _update_ground_material() -> void:
	IslandMeshBuilder.ground_base_color = ground_base_color
	IslandMeshBuilder.ground_brightness = ground_brightness
	IslandMeshBuilder.ground_diffuse_toon = use_ground_toon

	if _ground_material != null:
		_ground_material.diffuse_mode = BaseMaterial3D.DIFFUSE_TOON if use_ground_toon else BaseMaterial3D.DIFFUSE_BURLEY
		_ground_material.roughness = 0.90

	if pedestal != null and apply_ground_to_pedestal:
		pedestal.material_override = _ground_material

func _reload_island_mesh_only() -> void:
	if _cached_island_mi != null and not _cached_island_polys.is_empty():
		var new_mesh: ArrayMesh = IslandMeshBuilder.build_island_mesh(_cached_island_polys)
		if new_mesh != null:
			_cached_island_mi.mesh = new_mesh

func _process(delta: float) -> void:
	var fps: float = Engine.get_frames_per_second()
	var frame_ms: float = 1000.0 / maxf(fps, 1.0)
	lbl_fps.text = "FPS: %d (%.1f ms)" % [int(fps), frame_ms]

	for spinner: Node3D in blade_spinner_nodes:
		if is_instance_valid(spinner):
			spinner.rotate_y(deg_to_rad(720.0 * delta))

	if is_turntable_active and turntable != null:
		turntable.rotate_y(deg_to_rad(24.0 * delta))

	if is_rotating_sun and sun_light != null:
		sun_yaw = wrapf(sun_yaw + 24.0 * delta, -180.0, 180.0)
		_apply_sun_rotation()
		if slider_sun_yaw != null:
			slider_sun_yaw.value = sun_yaw

	_update_cam_info_label()

	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0 and toast_label != null:
			toast_label.visible = false

func _is_mouse_in_central_area(pos: Vector2) -> bool:
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

		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if mb.pressed:
				if _is_mouse_in_central_area(mb.position):
					is_panning_mouse = true
					last_mouse_pos = mb.position
			else:
				is_panning_mouse = false

		elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			if _is_mouse_in_central_area(mb.position):
				cam_distance = clampf(cam_distance - 0.4, 1.5, 25.0)
				_update_camera_transform()
				if slider_cam_zoom != null:
					slider_cam_zoom.value = cam_distance

		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			if _is_mouse_in_central_area(mb.position):
				cam_distance = clampf(cam_distance + 0.4, 1.5, 25.0)
				_update_camera_transform()
				if slider_cam_zoom != null:
					slider_cam_zoom.value = cam_distance

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var diff: Vector2 = mm.position - last_mouse_pos
		last_mouse_pos = mm.position

		if is_dragging_mouse:
			cam_rot_y -= diff.x * 0.35
			cam_rot_x = clampf(cam_rot_x - diff.y * 0.35, -85.0, 15.0)
			_update_camera_transform()

		elif is_panning_mouse and camera != null:
			var cam_basis: Basis = camera.global_transform.basis
			var right_vec: Vector3 = cam_basis.x
			var up_vec: Vector3 = cam_basis.y
			var pan_speed: float = 0.0035 * (cam_distance / 5.0)
			cam_target -= (right_vec * diff.x - up_vec * diff.y) * pan_speed
			_update_camera_transform()

func _update_camera_transform() -> void:
	if camera_pivot == null or camera == null:
		return
	camera_pivot.position = cam_target
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
	lbl_cam_info.text = "📷 Câmera: Pitch %.1f° | Yaw %.1f° | Dist %.2fm\n☀️ Sol: Pitch %.1f° | Yaw %.1f°" % [
		cam_rot_x, cam_rot_y, cam_distance, sun_pitch, sun_yaw
	]

func _setup_signals() -> void:
	# Modo Fase Completa & Seleção de Níveis
	btn_mod_level.pressed.connect(func() -> void: _set_target_model(TargetModel.FULL_LEVEL))
	btn_level_prev.pressed.connect(_on_level_prev)
	btn_level_next.pressed.connect(_on_level_next)

	# Modelos Isolados (Painel Esquerdo)
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
	btn_reset_cam.pressed.connect(_align_camera_to_game)
	slider_cam_zoom.value_changed.connect(func(v: float) -> void:
		cam_distance = v
		_update_camera_transform()
	)
	check_turntable.toggled.connect(func(t: bool) -> void:
		is_turntable_active = t
	)

	# Presets de Vegetação (Painel Direito)
	btn_preset_grass.pressed.connect(func() -> void: _apply_preset("grass"))
	btn_preset_wheat.pressed.connect(func() -> void: _apply_preset("wheat"))
	btn_preset_rose.pressed.connect(func() -> void: _apply_preset("rose"))
	btn_preset_rock.pressed.connect(func() -> void: _apply_preset("rock"))
	btn_preset_minions.pressed.connect(func() -> void: _apply_preset("minions"))

	# Cores da Vegetação (Painel Direito)
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

	# Sliders de Gradiente da Vegetação
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

	# Solo da Ilha (Painel Direito)
	picker_color_ground.color_changed.connect(func(c: Color) -> void:
		ground_base_color = c
		_update_ground_material()
		_reload_island_mesh_only()
	)
	slider_ground_brightness.value_changed.connect(func(v: float) -> void:
		ground_brightness = v
		lbl_ground_brightness.text = "Brilho do Solo: %.2f" % v
		_update_ground_material()
		_reload_island_mesh_only()
	)
	check_ground_pedestal.toggled.connect(func(t: bool) -> void:
		apply_ground_to_pedestal = t
		_update_ground_material()
	)
	check_ground_toon.toggled.connect(func(t: bool) -> void:
		use_ground_toon = t
		_update_ground_material()
	)
	btn_ground_preset_dark.pressed.connect(func() -> void:
		ground_base_color = Color(0.18, 0.40, 0.22, 1.0)
		ground_brightness = 0.90
		_sync_ground_ui()
		_update_ground_material()
		_reload_island_mesh_only()
	)
	btn_ground_preset_light.pressed.connect(func() -> void:
		ground_base_color = Color(0.14, 0.59, 0.22, 1.0)
		ground_brightness = 0.80
		_sync_ground_ui()
		_update_ground_material()
		_reload_island_mesh_only()
	)

	# Toggles
	check_rim.toggled.connect(func(t: bool) -> void:
		_active_material.set_shader_parameter("use_rim", t)
	)
	check_spec.toggled.connect(func(t: bool) -> void:
		_active_material.set_shader_parameter("use_specular", t)
	)

	# Outlines
	btn_out_none.pressed.connect(func() -> void: _set_outline_mode(OutlineMode.NONE))
	btn_out_thin.pressed.connect(func() -> void: _set_outline_mode(OutlineMode.THIN))
	btn_out_med.pressed.connect(func() -> void: _set_outline_mode(OutlineMode.MEDIUM))

	# Salvar e Copiar
	btn_save_to_game.pressed.connect(_on_btn_save_to_game_pressed)
	btn_copy_params.pressed.connect(_on_btn_copy_pressed)

func _on_level_prev() -> void:
	current_level_num = maxi(1, current_level_num - 1)
	lbl_current_level.text = "Fase %02d" % current_level_num
	btn_mod_level.text = "🏝️ Fase %02d (Completa)" % current_level_num
	if current_model == TargetModel.FULL_LEVEL:
		_load_level(current_level_num)

func _on_level_next() -> void:
	current_level_num = mini(20, current_level_num + 1)
	lbl_current_level.text = "Fase %02d" % current_level_num
	btn_mod_level.text = "🏝️ Fase %02d (Completa)" % current_level_num
	if current_model == TargetModel.FULL_LEVEL:
		_load_level(current_level_num)

func _align_camera_to_game() -> void:
	cam_rot_x = -40.3
	cam_rot_y = 0.0
	cam_distance = 7.4
	cam_target = Vector3.ZERO
	sun_pitch = -37.0
	sun_yaw = 40.0
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

func _align_sun_to_camera() -> void:
	sun_pitch = cam_rot_x
	sun_yaw = cam_rot_y
	_apply_sun_rotation()
	if slider_sun_pitch != null:
		slider_sun_pitch.value = sun_pitch
	if slider_sun_yaw != null:
		slider_sun_yaw.value = sun_yaw
	_show_toast("☀️ Sol alinhado com a Câmera!")

func _copy_camera_and_sun_info() -> void:
	var cam_dir: Vector3 = -camera.global_transform.basis.z.normalized() if camera != null else Vector3.ZERO
	var sun_dir: Vector3 = -sun_light.global_transform.basis.z.normalized() if sun_light != null else Vector3.ZERO
	var sun_nrg: float = sun_light.light_energy if sun_light != null else 1.0
	var amb_nrg: float = 0.2
	if world_environment != null and world_environment.environment != null:
		amb_nrg = world_environment.environment.ambient_light_energy

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

func _sync_ground_ui() -> void:
	if picker_color_ground != null:
		picker_color_ground.color = ground_base_color
	if slider_ground_brightness != null:
		slider_ground_brightness.value = ground_brightness
		lbl_ground_brightness.text = "Brilho do Solo: %.2f" % ground_brightness
	if check_ground_pedestal != null:
		check_ground_pedestal.button_pressed = apply_ground_to_pedestal
	if check_ground_toon != null:
		check_ground_toon.button_pressed = use_ground_toon

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

	if target == TargetModel.FULL_LEVEL:
		_load_level(current_level_num)
		return

	# Modo Estúdio com Pedestal
	if level_container != null:
		level_container.visible = false
	if pedestal != null:
		pedestal.visible = true
	if ground_mesh != null:
		ground_mesh.visible = true
	if turntable != null:
		turntable.visible = true

	cam_distance = 3.4
	_update_camera_transform()

	match target:
		TargetModel.GRASS:
			var g: Node3D = MODEL_GRASS.instantiate() as Node3D
			g.scale = Vector3(1.6, 1.6, 1.6)
			model_mount.add_child(g)

		TargetModel.WHEAT:
			var w: Node3D = MODEL_WHEAT.instantiate() as Node3D
			w.scale = Vector3(1.5, 1.5, 1.5)
			model_mount.add_child(w)

		TargetModel.FLOWER_ROSE:
			var r: Node3D = MODEL_FLOWER_ROSE.instantiate() as Node3D
			r.scale = Vector3(1.4, 1.4, 1.4)
			model_mount.add_child(r)

		TargetModel.FLOWER_DAISY:
			var d: Node3D = MODEL_FLOWER_DAISY.instantiate() as Node3D
			d.scale = Vector3(1.4, 1.4, 1.4)
			model_mount.add_child(d)

		TargetModel.FLOWER_SUNFLOWER:
			var s: Node3D = MODEL_FLOWER_SUNFLOWER.instantiate() as Node3D
			s.scale = Vector3(1.4, 1.4, 1.4)
			model_mount.add_child(s)

		TargetModel.ROCK:
			var rk: Node3D = MODEL_ROCK.instantiate() as Node3D
			rk.scale = Vector3(1.2, 1.2, 1.2)
			model_mount.add_child(rk)

		TargetModel.ROBOT:
			var bot: Node3D = MODEL_BOT.instantiate() as Node3D
			bot.scale = Vector3(1.0, 1.0, 1.0)
			model_mount.add_child(bot)
			var blade: Node3D = bot.find_child("BladeSpinner", true, false) as Node3D
			if blade != null:
				blade_spinner_nodes.append(blade)

		TargetModel.DIORAMA:
			var bot: Node3D = MODEL_BOT.instantiate() as Node3D
			bot.position = Vector3(0.0, 0.0, 0.0)
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

func _load_level(level_num: int) -> void:
	if level_container == null:
		return

	for c: Node in level_container.get_children():
		level_container.remove_child(c)
		c.queue_free()

	active_mesh_instances.clear()
	blade_spinner_nodes.clear()
	_cached_island_mi = null
	_cached_island_polys.clear()

	var json_path: String = "res://data/levels/level_%02d.json" % level_num
	if not FileAccess.file_exists(json_path):
		json_path = "res://data/levels/level_01.json"
	var data: Dictionary = LevelJsonLoader.load_json_file(json_path)

	var veg_grid: Node3D = VegetationGridScript.new() as Node3D
	veg_grid.name = "VegetationGrid_Level_%02d" % level_num
	level_container.add_child(veg_grid)

	var obstacles_container: Node3D = Node3D.new()
	obstacles_container.name = "Obstacles"
	level_container.add_child(obstacles_container)

	var cutter: CharacterBody3D = CUTTER_SCENE.instantiate() as CharacterBody3D
	level_container.add_child(cutter)

	veg_grid.build_from_level_json(data, obstacles_container, cutter)

	# Registra a lâmina do robô para rotação contínua
	var blade: Node3D = cutter.find_child("BladeSpinner", true, false) as Node3D
	if blade != null:
		blade_spinner_nodes.append(blade)

	# Cache do IslandMesh e polígonos para atualizações live do solo
	_cached_island_polys = LevelJsonLoader.get_island_polygons(data)
	var found_island: Node = veg_grid.find_child("IslandMesh", true, false)
	if found_island is MeshInstance3D:
		_cached_island_mi = found_island as MeshInstance3D

	# Alterna visibilidade para focar na fase completa
	if pedestal != null:
		pedestal.visible = false
	if ground_mesh != null:
		ground_mesh.visible = false
	if turntable != null:
		turntable.visible = false
	level_container.visible = true

	_align_camera_to_game()
	_collect_meshes(level_container)

func _collect_meshes(node: Node) -> void:
	if node is MeshInstance3D:
		active_mesh_instances.append(node as MeshInstance3D)
	for c: Node in node.get_children():
		_collect_meshes(c)

func _update_model_materials() -> void:
	# No modo estúdio, garante que a malha do modelo receba o shader ativo
	if current_model != TargetModel.FULL_LEVEL:
		for mi: MeshInstance3D in active_mesh_instances:
			if not is_instance_valid(mi):
				continue
			if current_outline != OutlineMode.NONE:
				var out_mat: ShaderMaterial = ShaderMaterial.new()
				out_mat.shader = OUTLINE_SHADER
				var thickness: float = 0.012 if current_outline == OutlineMode.THIN else 0.024
				out_mat.set_shader_parameter("outline_thickness", thickness)
				out_mat.set_shader_parameter("outline_color", Color(0.08, 0.08, 0.08, 1.0))
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
			_active_material.set_shader_parameter("toon_ramp_offset", 0.97)
			_active_material.set_shader_parameter("toon_ramp_smoothness", 1.00)
			_active_material.set_shader_parameter("vertical_gradient_mix", 0.81)
			_active_material.set_shader_parameter("rim_power", 1.00)
			_active_material.set_shader_parameter("rim_brightness", 1.00)
			_active_material.set_shader_parameter("roughness", 0.90)

		"wheat":
			_active_material.set_shader_parameter("color_light", Color(0.98, 0.78, 0.22, 1.0))
			_active_material.set_shader_parameter("color_base", Color(0.55, 0.32, 0.08, 1.0))
			_active_material.set_shader_parameter("color_shadow", Color(0.68, 0.45, 0.12, 1.0))
			_active_material.set_shader_parameter("rim_color", Color(1.0, 0.95, 0.70, 1.0))
			_active_material.set_shader_parameter("toon_ramp_offset", 0.55)
			_active_material.set_shader_parameter("toon_ramp_smoothness", 0.20)
			_active_material.set_shader_parameter("vertical_gradient_mix", 0.60)
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

	if _active_material.get_shader_parameter("color_light") != null:
		picker_color_light.color = _active_material.get_shader_parameter("color_light") as Color
	if _active_material.get_shader_parameter("color_base") != null:
		picker_color_base.color = _active_material.get_shader_parameter("color_base") as Color
	if _active_material.get_shader_parameter("color_shadow") != null:
		picker_color_shadow.color = _active_material.get_shader_parameter("color_shadow") as Color
	if _active_material.get_shader_parameter("rim_color") != null:
		picker_color_rim.color = _active_material.get_shader_parameter("rim_color") as Color

	if _active_material.get_shader_parameter("toon_ramp_offset") != null:
		var v: float = float(_active_material.get_shader_parameter("toon_ramp_offset"))
		slider_ramp_offset.value = v
		lbl_ramp_offset.text = "Offset do Corte: %.2f" % v

	if _active_material.get_shader_parameter("toon_ramp_smoothness") != null:
		var v: float = float(_active_material.get_shader_parameter("toon_ramp_smoothness"))
		slider_ramp_smooth.value = v
		lbl_ramp_smooth.text = "Suavidade do Gradiente: %.2f" % v

	if _active_material.get_shader_parameter("vertical_gradient_mix") != null:
		var v: float = float(_active_material.get_shader_parameter("vertical_gradient_mix"))
		slider_vert_grad.value = v
		lbl_vert_grad.text = "Gradiente Vertical (Base-Topo): %.2f" % v

	if _active_material.get_shader_parameter("rim_power") != null:
		var v: float = float(_active_material.get_shader_parameter("rim_power"))
		slider_rim_power.value = v
		lbl_rim_power.text = "Foco Rim Light (Potência): %.1f" % v

	if _active_material.get_shader_parameter("rim_brightness") != null:
		var v: float = float(_active_material.get_shader_parameter("rim_brightness"))
		slider_rim_brightness.value = v
		lbl_rim_brightness.text = "Brilho Rim Light: %.2f" % v

	if _active_material.get_shader_parameter("roughness") != null:
		var v: float = float(_active_material.get_shader_parameter("roughness"))
		slider_roughness.value = v
		lbl_roughness.text = "Rugosidade Fosca: %.2f" % v

	if _active_material.get_shader_parameter("use_rim") != null:
		check_rim.button_pressed = bool(_active_material.get_shader_parameter("use_rim"))

func _on_btn_save_to_game_pressed() -> void:
	if _active_material != null:
		ResourceSaver.save(_active_material, "res://shaders/interactive_grass_material.tres")

	IslandMeshBuilder.ground_base_color = ground_base_color
	IslandMeshBuilder.ground_brightness = ground_brightness
	IslandMeshBuilder.ground_diffuse_toon = use_ground_toon

	_show_toast("💾 Salvo Diretamente no Jogo com Sucesso!")

func _on_btn_copy_pressed() -> void:
	if _active_material == null:
		return

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
	var u_rim: bool = bool(_active_material.get_shader_parameter("use_rim"))

	var code_snippet: String = """# Parâmetros Toon Shader Vegetação
color_light = Color(%.2f, %.2f, %.2f)
color_base = Color(%.2f, %.2f, %.2f)
color_shadow = Color(%.2f, %.2f, %.2f)
rim_color = Color(%.2f, %.2f, %.2f)
toon_ramp_offset = %.2f
toon_ramp_smoothness = %.2f
vertical_gradient_mix = %.2f
use_rim = %s
rim_power = %.2f
rim_brightness = %.2f
roughness = %.2f

# Parâmetros Solo da Ilha
ground_color = Color(%.2f, %.2f, %.2f)
ground_brightness = %.2f
ground_diffuse_toon = %s

# Iluminação do Jogo
sun_energy = %.2f
sun_rotation = Vector3(%.1f, %.1f, 0.0)
ambient_energy = %.2f
""" % [
		cl.r, cl.g, cl.b,
		cb.r, cb.g, cb.b,
		cs.r, cs.g, cs.b,
		cr.r, cr.g, cr.b,
		r_off, r_sm, v_gr, str(u_rim), r_pw, r_br, ro,
		ground_base_color.r, ground_base_color.g, ground_base_color.b,
		ground_brightness,
		str(use_ground_toon),
		sun_light.light_energy if sun_light != null else 1.3,
		sun_pitch, sun_yaw,
		world_environment.environment.ambient_light_energy if (world_environment != null and world_environment.environment != null) else 0.2
	]

	DisplayServer.clipboard_set(code_snippet)
	_show_toast("📋 Parâmetros Completos Copiados!")

func _show_toast(msg: String) -> void:
	if toast_label == null:
		return
	toast_label.text = msg
	toast_label.visible = true
	_toast_timer = 3.0

func _update_ui_state() -> void:
	_highlight_button(btn_mod_level, current_model == TargetModel.FULL_LEVEL)
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
