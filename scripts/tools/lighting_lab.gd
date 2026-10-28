extends Node3D

## Laboratório Canônico de Iluminação, Shaders e Game Feel (Grass Cut Bot)
## Permite calibrar em tempo real Sol, Luz Ambiente, Céu, Toon Ramp, Rim Light,
## Solo da Ilha, Falésias e Água com inspeção em órbita 360° ou jogabilidade com o Cutter.

const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const IslandMeshBuilder = preload("res://scripts/level/island_mesh_builder.gd")
const CUTTER_SCENE: PackedScene = preload("res://scenes/cutter/cutter.tscn")
const WATER_MATERIAL: ShaderMaterial = preload("res://shaders/toon_water_material.tres")

# Modelos Avulsos para o Modo Estúdio
const MODEL_BOT: PackedScene = preload("res://assets/models/grass_bot.glb")
const MODEL_GRASS: PackedScene = preload("res://assets/models/grass_01.glb")
const MODEL_WHEAT: PackedScene = preload("res://assets/models/wheat_01.glb")
const MODEL_FLOWER_ROSE: PackedScene = preload("res://assets/models/flower_02_rose.glb")
const MODEL_FLOWER_DAISY: PackedScene = preload("res://assets/models/flower_03_daisy.glb")
const MODEL_FLOWER_SUNFLOWER: PackedScene = preload("res://assets/models/flower_04_sunflower.glb")
const MODEL_FLOWER_BELL: PackedScene = preload("res://assets/models/flower_05_bell.glb")
const MODEL_FLOWER_TULIP: PackedScene = preload("res://assets/models/flower_07_tulip.glb")
const MODEL_ROCK: PackedScene = preload("res://assets/models/rock.glb")

enum DisplayMode {
	LEVEL = 0,
	STUDIO = 1
}

enum StudioModel {
	ROBOT = 0,
	GRASS = 1,
	WHEAT = 2,
	FLOWER_ROSE = 3,
	FLOWER_DAISY = 4,
	FLOWER_SUNFLOWER = 5,
	FLOWER_BELL = 6,
	FLOWER_TULIP = 7,
	ROCK = 8
}

const STUDIO_MODEL_NAMES: Array[String] = [
	"Robô Cutter Bit",
	"Tufo de Grama (grass_01)",
	"Trigo Dourado (wheat_01)",
	"Rosa Vermelha",
	"Margarida",
	"Girassol",
	"Campânula Azul",
	"Tulipa",
	"Rocha Natural"
]

const GRASS_KEYS: Array[String] = [
	"grass_green",
	"grass_yellow",
	"grass_blue",
	"grass_purple",
	"grass_white",
	"grass_red",
	"grass_black",
	"wheat"
]

const GRASS_DISPLAY_NAMES: Array[String] = [
	"Grama Verde (Esmeralda)",
	"Grama Amarela (Solar)",
	"Grama Azul (Celeste)",
	"Grama Roxa (Mística)",
	"Grama Branca (Nevada)",
	"Grama Vermelha (Rubi)",
	"Grama Preta (Vulcânica)",
	"Trigo (Dourado)"
]

# Referências de Nós 3D
@onready var world_environment: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var ocean_mesh: MeshInstance3D = $OceanMesh
@onready var pedestal: MeshInstance3D = $Pedestal
@onready var studio_mount: Node3D = $StudioMount
@onready var level_container: Node3D = $LevelContainer

# Câmeras
@onready var free_camera_pivot: Node3D = $FreeCameraPivot
@onready var free_camera: Camera3D = $FreeCameraPivot/FreeCamera
@onready var game_camera: Camera3D = $GameCamera

# UI
@onready var ui_canvas: CanvasLayer = $CanvasLayer
@onready var ui_root: Control = $CanvasLayer/Control
@onready var top_bar: HBoxContainer = $CanvasLayer/Control/TopBar
@onready var drawer_panel: PanelContainer = $CanvasLayer/Control/DrawerPanel
@onready var tab_container: TabContainer = $CanvasLayer/Control/DrawerPanel/VBoxDrawer/TabContainer
@onready var toast_label: Label = %ToastLabel
@onready var btn_toggle_ui: Button = %BtnToggleUI
@onready var btn_toggle_drawer: Button = %BtnToggleDrawer
@onready var lbl_mode_status: Label = %LblModeStatus
@onready var btn_cam_mode: Button = %BtnCamMode
@onready var btn_disp_mode: Button = %BtnDispMode
@onready var btn_prev_item: Button = %BtnPrevItem
@onready var btn_next_item: Button = %BtnNextItem
@onready var btn_save_game: Button = %BtnSaveGame
@onready var btn_copy_code: Button = %BtnCopyCode

# Controles Aba Sol
@onready var slider_sun_energy: HSlider = %SliderSunEnergy
@onready var lbl_sun_energy: Label = %LblSunEnergy
@onready var slider_sun_pitch: HSlider = %SliderSunPitch
@onready var lbl_sun_pitch: Label = %LblSunPitch
@onready var slider_sun_yaw: HSlider = %SliderSunYaw
@onready var lbl_sun_yaw: Label = %LblSunYaw
@onready var picker_sun_color: ColorPickerButton = %PickerSunColor
@onready var check_sun_shadows: CheckBox = %CheckSunShadows
@onready var check_sun_rotate: CheckBox = %CheckSunRotate

# Controles Aba Ambiente
@onready var slider_ambient_energy: HSlider = %SliderAmbientEnergy
@onready var lbl_ambient_energy: Label = %LblAmbientEnergy
@onready var picker_ambient_color: ColorPickerButton = %PickerAmbientColor
@onready var picker_sky_color: ColorPickerButton = %PickerSkyColor
@onready var opt_tonemap: OptionButton = %OptTonemap
@onready var slider_exposure: HSlider = %SliderExposure
@onready var lbl_exposure: Label = %LblExposure

# Controles Aba Toon Shader
@onready var opt_grass_material: OptionButton = %OptGrassMaterial
@onready var picker_color_light: ColorPickerButton = %PickerColorLight
@onready var picker_color_shadow: ColorPickerButton = %PickerColorShadow
@onready var picker_color_base: ColorPickerButton = %PickerColorBase
@onready var slider_ramp_offset: HSlider = %SliderRampOffset
@onready var lbl_ramp_offset: Label = %LblRampOffset
@onready var slider_ramp_smooth: HSlider = %SliderRampSmooth
@onready var lbl_ramp_smooth: Label = %LblRampSmooth
@onready var slider_vert_grad: HSlider = %SliderVertGrad
@onready var lbl_vert_grad: Label = %LblVertGrad
@onready var check_rim_light: CheckBox = %CheckRimLight
@onready var picker_rim_color: ColorPickerButton = %PickerRimColor
@onready var slider_rim_power: HSlider = %SliderRimPower
@onready var lbl_rim_power: Label = %LblRimPower
@onready var slider_rim_bright: HSlider = %SliderRimBright
@onready var lbl_rim_bright: Label = %LblRimBright
@onready var slider_roughness: HSlider = %SliderRoughness
@onready var lbl_roughness: Label = %LblRoughness

# Controles Aba Solo & Mar
@onready var picker_ground_color: ColorPickerButton = %PickerGroundColor
@onready var slider_ground_bright: HSlider = %SliderGroundBright
@onready var lbl_ground_bright: Label = %LblGroundBright
@onready var check_ground_toon: CheckBox = %CheckGroundToon
@onready var picker_cliff_color: ColorPickerButton = %PickerCliffColor
@onready var check_ocean_visible: CheckBox = %CheckOceanVisible
@onready var picker_water_shallow: ColorPickerButton = %PickerWaterShallow
@onready var picker_water_deep: ColorPickerButton = %PickerWaterDeep

# Controles Aba Presets
@onready var btn_preset_canonical: Button = %BtnPresetCanonical
@onready var btn_preset_current: Button = %BtnPresetCurrent
@onready var btn_preset_golden: Button = %BtnPresetGolden
@onready var btn_preset_pop: Button = %BtnPresetPop
@onready var btn_preset_dusk: Button = %BtnPresetDusk
@onready var btn_preset_reset: Button = %BtnPresetReset

# Estado Interno
var current_display_mode: DisplayMode = DisplayMode.LEVEL
var current_studio_model: StudioModel = StudioModel.ROBOT
var current_level_num: int = 1
var is_game_camera_active: bool = false
var is_drawer_open: bool = true
var is_ui_visible: bool = true

# Órbita da Câmera Livre
var _orbit_pitch: float = -38.0
var _orbit_yaw: float = 30.0
var _orbit_distance: float = 11.0
var _is_dragging_orbit: bool = false
var _is_panning: bool = false
var _last_mouse_pos: Vector2 = Vector2.ZERO
var _pan_target_offset: Vector3 = Vector3.ZERO

# Rotação do Sol e Turntable
var sun_pitch: float = -38.0
var sun_yaw: float = 40.0
var sun_rotate_speed: float = 12.0
var turntable_speed: float = 25.0
var check_turntable_model: bool = false

# Entidade Cortador Ativa
var active_cutter: CharacterBody3D = null
var _blade_spinner: Node3D = null
var _toast_timer: float = 0.0

# Material de Vegetação Ativo Selecionado
var _active_mat_key: String = "grass_green"
var _active_material: ShaderMaterial = null

# Cache de Polígonos de Ilha e MeshInstance
var _cached_island_mi: MeshInstance3D = null
var _cached_island_polys: Array[PackedVector2Array] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_init_grass_materials()
	_setup_options()
	_connect_signals()

	# Aplica preset canônico inicial
	_apply_preset_canonical()

	# Carrega o nível 1 por padrão
	_set_display_mode(DisplayMode.LEVEL)

	# Inicia com Câmera Livre para inspeção
	_set_camera_mode(false)

	_show_toast("Bem-vindo ao Laboratório de Iluminação! (F6 OK)")

func _init_grass_materials() -> void:
	if VegetationGridScript.GRASS_MATERIALS.has("grass_green"):
		_active_material = VegetationGridScript.GRASS_MATERIALS["grass_green"] as ShaderMaterial
	elif ResourceLoader.exists("res://shaders/interactive_grass_material.tres"):
		_active_material = load("res://shaders/interactive_grass_material.tres") as ShaderMaterial

func _setup_options() -> void:
	# Popula OptionButton de Materiais de Grama
	opt_grass_material.clear()
	for i: int in range(GRASS_KEYS.size()):
		opt_grass_material.add_item(GRASS_DISPLAY_NAMES[i], i)

	# Popula OptionButton de Tonemap
	opt_tonemap.clear()
	opt_tonemap.add_item("Linear (Padrão)", 0)
	opt_tonemap.add_item("Reinhard (Suave)", 1)
	opt_tonemap.add_item("Filmic (Cinematográfico)", 2)
	opt_tonemap.add_item("ACES (Alto Contraste Toon)", 3)
	opt_tonemap.selected = 2 # Filmic padrão

func _connect_signals() -> void:
	# TopBar
	btn_toggle_ui.pressed.connect(_toggle_ui_visibility)
	btn_toggle_drawer.pressed.connect(_toggle_drawer)
	btn_cam_mode.pressed.connect(_toggle_camera_mode)
	btn_disp_mode.pressed.connect(_toggle_display_mode)
	btn_prev_item.pressed.connect(_on_prev_item_pressed)
	btn_next_item.pressed.connect(_on_next_item_pressed)
	btn_save_game.pressed.connect(_on_btn_save_game_pressed)
	btn_copy_code.pressed.connect(_on_btn_copy_code_pressed)

	# Sol
	slider_sun_energy.value_changed.connect(_on_sun_energy_changed)
	slider_sun_pitch.value_changed.connect(_on_sun_pitch_changed)
	slider_sun_yaw.value_changed.connect(_on_sun_yaw_changed)
	picker_sun_color.color_changed.connect(_on_sun_color_changed)
	check_sun_shadows.toggled.connect(_on_sun_shadows_toggled)

	# Ambiente
	slider_ambient_energy.value_changed.connect(_on_ambient_energy_changed)
	picker_ambient_color.color_changed.connect(_on_ambient_color_changed)
	picker_sky_color.color_changed.connect(_on_sky_color_changed)
	opt_tonemap.item_selected.connect(_on_tonemap_selected)
	slider_exposure.value_changed.connect(_on_exposure_changed)

	# Toon Shader
	opt_grass_material.item_selected.connect(_on_grass_material_selected)
	picker_color_light.color_changed.connect(_on_shader_color_light_changed)
	picker_color_shadow.color_changed.connect(_on_shader_color_shadow_changed)
	picker_color_base.color_changed.connect(_on_shader_color_base_changed)
	slider_ramp_offset.value_changed.connect(_on_shader_ramp_offset_changed)
	slider_ramp_smooth.value_changed.connect(_on_shader_ramp_smooth_changed)
	slider_vert_grad.value_changed.connect(_on_shader_vert_grad_changed)
	check_rim_light.toggled.connect(_on_shader_rim_toggled)
	picker_rim_color.color_changed.connect(_on_shader_rim_color_changed)
	slider_rim_power.value_changed.connect(_on_shader_rim_power_changed)
	slider_rim_bright.value_changed.connect(_on_shader_rim_bright_changed)
	slider_roughness.value_changed.connect(_on_shader_roughness_changed)

	# Solo & Mar
	picker_ground_color.color_changed.connect(_on_ground_color_changed)
	slider_ground_bright.value_changed.connect(_on_ground_bright_changed)
	check_ground_toon.toggled.connect(_on_ground_toon_toggled)
	picker_cliff_color.color_changed.connect(_on_cliff_color_changed)
	check_ocean_visible.toggled.connect(_on_ocean_visible_toggled)
	picker_water_shallow.color_changed.connect(_on_water_shallow_changed)
	picker_water_deep.color_changed.connect(_on_water_deep_changed)

	# Presets
	btn_preset_canonical.pressed.connect(_apply_preset_canonical)
	btn_preset_current.pressed.connect(_apply_preset_current)
	btn_preset_golden.pressed.connect(_apply_preset_golden)
	btn_preset_pop.pressed.connect(_apply_preset_pop)
	btn_preset_dusk.pressed.connect(_apply_preset_dusk)
	btn_preset_reset.pressed.connect(_apply_preset_canonical)

func _process(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			toast_label.visible = false

	# Rotação contínua do Sol (Ciclo do Dia)
	if check_sun_rotate.button_pressed:
		sun_yaw = fmod(sun_yaw + sun_rotate_speed * delta, 360.0)
		slider_sun_yaw.value = sun_yaw
		_update_sun_orientation()

	# Rotação suave do modelo de estúdio
	if current_display_mode == DisplayMode.STUDIO and studio_mount != null:
		studio_mount.rotation_degrees.y += turntable_speed * delta

	# Animação contínua da lâmina do Cutter
	if _blade_spinner != null and is_instance_valid(_blade_spinner):
		_blade_spinner.rotation.y += 24.0 * delta

	# Movimento do Cutter no Modo Jogo
	if is_game_camera_active and active_cutter != null and is_instance_valid(active_cutter):
		_handle_gameplay_input()

	# Atualiza posição da Câmera Livre
	_update_free_camera_transform()

func _handle_gameplay_input() -> void:
	var dir: Vector2 = Vector2.ZERO
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		dir.y += 1.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		dir.x += 1.0

	if dir.length_squared() > 0.001:
		dir = dir.normalized()

	if active_cutter.has_method("set_input_direction"):
		active_cutter.set_input_direction(dir)

func _unhandled_input(event: InputEvent) -> void:
	# Atalhos rápidos de Teclado
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		var key: Key = event.keycode
		match key:
			KEY_TAB, KEY_H:
				_toggle_ui_visibility()
				get_viewport().set_input_as_handled()
			KEY_SPACE:
				_toggle_camera_mode()
				get_viewport().set_input_as_handled()
			KEY_R:
				_reset_camera()
				get_viewport().set_input_as_handled()
			KEY_1:
				_apply_preset_canonical()
			KEY_2:
				_apply_preset_current()
			KEY_3:
				_apply_preset_golden()
			KEY_4:
				_apply_preset_pop()
			KEY_5:
				_apply_preset_dusk()

	# Controles de Mouse para a Câmera Livre (Órbita e Zoom)
	if not is_game_camera_active:
		if event is InputEventMouseButton:
			var mb: InputEventMouseButton = event as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				_is_dragging_orbit = mb.pressed
				_last_mouse_pos = mb.position
			elif mb.button_index == MOUSE_BUTTON_RIGHT:
				_is_panning = mb.pressed
				_last_mouse_pos = mb.position
			elif mb.button_index == MOUSE_BUTTON_WHEEL_UP:
				_orbit_distance = clampf(_orbit_distance - 0.75, 2.5, 30.0)
			elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				_orbit_distance = clampf(_orbit_distance + 0.75, 2.5, 30.0)

		elif event is InputEventMouseMotion:
			var mm: InputEventMouseMotion = event as InputEventMouseMotion
			if _is_dragging_orbit:
				var diff: Vector2 = mm.position - _last_mouse_pos
				_orbit_yaw = fmod(_orbit_yaw - diff.x * 0.4, 360.0)
				_orbit_pitch = clampf(_orbit_pitch - diff.y * 0.4, -85.0, 5.0)
				_last_mouse_pos = mm.position
			elif _is_panning:
				var diff_pan: Vector2 = mm.position - _last_mouse_pos
				var forward: Vector3 = -free_camera.global_transform.basis.z
				var right: Vector3 = free_camera.global_transform.basis.x
				_pan_target_offset -= (right * diff_pan.x * 0.015 - Vector3.UP * diff_pan.y * 0.015)
				_last_mouse_pos = mm.position

func _update_free_camera_transform() -> void:
	if is_game_camera_active or free_camera_pivot == null or free_camera == null:
		return

	free_camera_pivot.position = _pan_target_offset
	free_camera_pivot.rotation_degrees = Vector3(_orbit_pitch, _orbit_yaw, 0.0)
	free_camera.position = Vector3(0.0, 0.0, _orbit_distance)

func _reset_camera() -> void:
	_orbit_pitch = -38.0
	_orbit_yaw = 30.0
	_orbit_distance = 11.0
	_pan_target_offset = Vector3.ZERO
	_show_toast("Câmera resetada!")

# ==============================================================================
# 🎮 CONTROLE DE EXIBIÇÃO & NÍVEIS
# ==============================================================================

func _set_display_mode(mode: DisplayMode) -> void:
	current_display_mode = mode
	if current_display_mode == DisplayMode.LEVEL:
		pedestal.visible = false
		studio_mount.visible = false
		level_container.visible = true
		btn_disp_mode.text = "Modo: 🎮 Nível (%02d)" % current_level_num
		_load_level(current_level_num)
	else:
		level_container.visible = false
		pedestal.visible = true
		studio_mount.visible = true
		btn_disp_mode.text = "Modo: 🌾 Estúdio"
		_load_studio_model(current_studio_model)

	_update_header_status()

func _toggle_display_mode() -> void:
	if current_display_mode == DisplayMode.LEVEL:
		_set_display_mode(DisplayMode.STUDIO)
	else:
		_set_display_mode(DisplayMode.LEVEL)

func _load_level(lvl: int) -> void:
	current_level_num = clampi(lvl, 1, 20)
	if level_container == null:
		return

	for c: Node in level_container.get_children():
		level_container.remove_child(c)
		c.queue_free()

	active_cutter = null
	_blade_spinner = null
	_cached_island_mi = null
	_cached_island_polys.clear()

	var json_path: String = "res://data/levels/level_%02d.json" % current_level_num
	if not FileAccess.file_exists(json_path):
		json_path = "res://data/levels/level_01.json"
	var data: Dictionary = LevelJsonLoader.load_json_file(json_path)

	var veg_grid: Node3D = VegetationGridScript.new() as Node3D
	veg_grid.name = "VegetationGrid_Level_%02d" % current_level_num
	level_container.add_child(veg_grid)

	var obstacles_container: Node3D = Node3D.new()
	obstacles_container.name = "Obstacles"
	level_container.add_child(obstacles_container)

	var cutter: CharacterBody3D = CUTTER_SCENE.instantiate() as CharacterBody3D
	level_container.add_child(cutter)
	active_cutter = cutter

	veg_grid.build_from_level_json(data, obstacles_container, cutter)

	# Localiza spinner da lâmina para girar
	_blade_spinner = cutter.find_child("BladeSpinner", true, false) as Node3D

	# Conecta câmera de jogo ao Cutter
	if game_camera != null and game_camera.has_method("reset_cam"):
		game_camera.set("target_path", game_camera.get_path_to(cutter))
		game_camera.call("reset_cam")

	# Armazena cache do IslandMesh para atualizar o solo em tempo real
	_cached_island_polys = LevelJsonLoader.get_island_polygons(data)
	var found_island: Node = veg_grid.find_child("IslandMesh", true, false)
	if found_island is MeshInstance3D:
		_cached_island_mi = found_island as MeshInstance3D

	_update_header_status()

func _load_studio_model(model_enum: StudioModel) -> void:
	current_studio_model = model_enum
	if studio_mount == null:
		return

	for c: Node in studio_mount.get_children():
		studio_mount.remove_child(c)
		c.queue_free()

	_blade_spinner = null
	active_cutter = null

	var scene_to_instantiate: PackedScene = null
	var target_scale: Vector3 = Vector3.ONE

	match model_enum:
		StudioModel.ROBOT:
			scene_to_instantiate = MODEL_BOT
			target_scale = Vector3(1.2, 1.2, 1.2)
		StudioModel.GRASS:
			scene_to_instantiate = MODEL_GRASS
			target_scale = Vector3(1.4, 1.4, 1.4)
		StudioModel.WHEAT:
			scene_to_instantiate = MODEL_WHEAT
			target_scale = Vector3(1.3, 1.3, 1.3)
		StudioModel.FLOWER_ROSE:
			scene_to_instantiate = MODEL_FLOWER_ROSE
			target_scale = Vector3(1.2, 1.2, 1.2)
		StudioModel.FLOWER_DAISY:
			scene_to_instantiate = MODEL_FLOWER_DAISY
			target_scale = Vector3(1.2, 1.2, 1.2)
		StudioModel.FLOWER_SUNFLOWER:
			scene_to_instantiate = MODEL_FLOWER_SUNFLOWER
			target_scale = Vector3(1.2, 1.2, 1.2)
		StudioModel.FLOWER_BELL:
			scene_to_instantiate = MODEL_FLOWER_BELL
			target_scale = Vector3(1.2, 1.2, 1.2)
		StudioModel.FLOWER_TULIP:
			scene_to_instantiate = MODEL_FLOWER_TULIP
			target_scale = Vector3(1.2, 1.2, 1.2)
		StudioModel.ROCK:
			scene_to_instantiate = MODEL_ROCK
			target_scale = Vector3(1.2, 1.2, 1.2)

	if scene_to_instantiate != null:
		var inst: Node3D = scene_to_instantiate.instantiate() as Node3D
		inst.scale = target_scale
		studio_mount.add_child(inst)

		_blade_spinner = inst.find_child("BladeSpinner", true, false) as Node3D

	_update_header_status()

func _on_prev_item_pressed() -> void:
	if current_display_mode == DisplayMode.LEVEL:
		var prev: int = current_level_num - 1
		if prev < 1:
			prev = 20
		_load_level(prev)
	else:
		var prev_m: int = int(current_studio_model) - 1
		if prev_m < 0:
			prev_m = StudioModel.size() - 1
		_load_studio_model(prev_m as StudioModel)

func _on_next_item_pressed() -> void:
	if current_display_mode == DisplayMode.LEVEL:
		var next: int = current_level_num + 1
		if next > 20:
			next = 1
		_load_level(next)
	else:
		var next_m: int = int(current_studio_model) + 1
		if next_m >= StudioModel.size():
			next_m = 0
		_load_studio_model(next_m as StudioModel)

func _update_header_status() -> void:
	if current_display_mode == DisplayMode.LEVEL:
		lbl_mode_status.text = "Fase %02d / 20" % current_level_num
	else:
		var idx: int = int(current_studio_model)
		if idx >= 0 and idx < STUDIO_MODEL_NAMES.size():
			lbl_mode_status.text = STUDIO_MODEL_NAMES[idx]

# ==============================================================================
# 🎥 CÂMERA & VISIBILIDADE DE UI
# ==============================================================================

func _set_camera_mode(game_cam: bool) -> void:
	is_game_camera_active = game_cam
	if is_game_camera_active:
		if active_cutter != null and is_instance_valid(active_cutter):
			game_camera.current = true
			free_camera.current = false
			btn_cam_mode.text = "Câmera: 🎮 Jogo (WASD)"
			_show_toast("Modo Jogo: Use WASD para andar e cortar!")
		else:
			# Se não tiver cortador ativo, força câmera livre
			is_game_camera_active = false
			free_camera.current = true
			game_camera.current = false
			btn_cam_mode.text = "Câmera: 🎥 Livre (Órbita)"
			_show_toast("Modo Estúdio ativo: Câmera Livre mantida.")
	else:
		free_camera.current = true
		game_camera.current = false
		btn_cam_mode.text = "Câmera: 🎥 Livre (Órbita)"
		_show_toast("Câmera Livre: Arraste com mouse para orbitar!")

func _toggle_camera_mode() -> void:
	_set_camera_mode(not is_game_camera_active)

func _toggle_ui_visibility() -> void:
	is_ui_visible = not is_ui_visible
	ui_root.visible = is_ui_visible

func _toggle_drawer() -> void:
	is_drawer_open = not is_drawer_open
	tab_container.visible = is_drawer_open
	btn_toggle_drawer.text = "▼ Recolher Controles" if is_drawer_open else "▲ Expandir Controles"

# ==============================================================================
# ☀️ CONTROLE DO SOL & LUZ
# ==============================================================================

func _update_sun_orientation() -> void:
	if sun_light == null:
		return
	sun_light.rotation_degrees = Vector3(sun_pitch, sun_yaw, 0.0)
	lbl_sun_pitch.text = "Altura Zenital (Pitch): %.1f°" % sun_pitch
	lbl_sun_yaw.text = "Azimute Solar (Yaw): %.1f°" % sun_yaw

func _on_sun_energy_changed(v: float) -> void:
	if sun_light != null:
		sun_light.light_energy = v
	lbl_sun_energy.text = "Energia do Sol: %.2f" % v

func _on_sun_pitch_changed(v: float) -> void:
	sun_pitch = v
	_update_sun_orientation()

func _on_sun_yaw_changed(v: float) -> void:
	sun_yaw = v
	_update_sun_orientation()

func _on_sun_color_changed(c: Color) -> void:
	if sun_light != null:
		sun_light.light_color = c

func _on_sun_shadows_toggled(pressed: bool) -> void:
	if sun_light != null:
		sun_light.shadow_enabled = pressed

# ==============================================================================
# 🌌 AMBIENTE & CÉU
# ==============================================================================

func _on_ambient_energy_changed(v: float) -> void:
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.ambient_light_energy = v
	lbl_ambient_energy.text = "Luz Ambiente: %.2f" % v

func _on_ambient_color_changed(c: Color) -> void:
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.ambient_light_color = c

func _on_sky_color_changed(c: Color) -> void:
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.background_color = c

func _on_tonemap_selected(idx: int) -> void:
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.tonemap_mode = idx as Environment.ToneMapper

func _on_exposure_changed(v: float) -> void:
	if world_environment != null and world_environment.environment != null:
		world_environment.environment.tonemap_exposure = v
	lbl_exposure.text = "Exposição: %.2f" % v

# ==============================================================================
# 🎨 TOON SHADER DA VEGETAÇÃO
# ==============================================================================

func _on_grass_material_selected(idx: int) -> void:
	if idx >= 0 and idx < GRASS_KEYS.size():
		_active_mat_key = GRASS_KEYS[idx]
		if VegetationGridScript.GRASS_MATERIALS.has(_active_mat_key):
			_active_material = VegetationGridScript.GRASS_MATERIALS[_active_mat_key] as ShaderMaterial
			_sync_ui_from_material()

func _sync_ui_from_material() -> void:
	if _active_material == null:
		return

	if _active_material.get_shader_parameter("color_light") != null:
		picker_color_light.color = _active_material.get_shader_parameter("color_light") as Color
	if _active_material.get_shader_parameter("color_shadow") != null:
		picker_color_shadow.color = _active_material.get_shader_parameter("color_shadow") as Color
	if _active_material.get_shader_parameter("color_base") != null:
		picker_color_base.color = _active_material.get_shader_parameter("color_base") as Color
	if _active_material.get_shader_parameter("toon_ramp_offset") != null:
		var v: float = float(_active_material.get_shader_parameter("toon_ramp_offset"))
		slider_ramp_offset.value = v
		lbl_ramp_offset.text = "Degrau Toon (Offset): %.2f" % v
	if _active_material.get_shader_parameter("toon_ramp_smoothness") != null:
		var v: float = float(_active_material.get_shader_parameter("toon_ramp_smoothness"))
		slider_ramp_smooth.value = v
		lbl_ramp_smooth.text = "Suavidade Cel (Smoothness): %.2f" % v
	if _active_material.get_shader_parameter("vertical_gradient_mix") != null:
		var v: float = float(_active_material.get_shader_parameter("vertical_gradient_mix"))
		slider_vert_grad.value = v
		lbl_vert_grad.text = "Gradiente Vertical: %.2f" % v
	if _active_material.get_shader_parameter("use_rim") != null:
		check_rim_light.button_pressed = bool(_active_material.get_shader_parameter("use_rim"))
	if _active_material.get_shader_parameter("rim_color") != null:
		picker_rim_color.color = _active_material.get_shader_parameter("rim_color") as Color
	if _active_material.get_shader_parameter("rim_power") != null:
		var v: float = float(_active_material.get_shader_parameter("rim_power"))
		slider_rim_power.value = v
		lbl_rim_power.text = "Potência Rim Light: %.1f" % v
	if _active_material.get_shader_parameter("rim_brightness") != null:
		var v: float = float(_active_material.get_shader_parameter("rim_brightness"))
		slider_rim_bright.value = v
		lbl_rim_bright.text = "Brilho Rim Light: %.2f" % v
	if _active_material.get_shader_parameter("roughness") != null:
		var v: float = float(_active_material.get_shader_parameter("roughness"))
		slider_roughness.value = v
		lbl_roughness.text = "Rugosidade Fosca: %.2f" % v

func _on_shader_color_light_changed(c: Color) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("color_light", c)

func _on_shader_color_shadow_changed(c: Color) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("color_shadow", c)

func _on_shader_color_base_changed(c: Color) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("color_base", c)

func _on_shader_ramp_offset_changed(v: float) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("toon_ramp_offset", v)
	lbl_ramp_offset.text = "Degrau Toon (Offset): %.2f" % v

func _on_shader_ramp_smooth_changed(v: float) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("toon_ramp_smoothness", v)
	lbl_ramp_smooth.text = "Suavidade Cel (Smoothness): %.2f" % v

func _on_shader_vert_grad_changed(v: float) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("vertical_gradient_mix", v)
	lbl_vert_grad.text = "Gradiente Vertical: %.2f" % v

func _on_shader_rim_toggled(pressed: bool) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("use_rim", pressed)

func _on_shader_rim_color_changed(c: Color) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("rim_color", c)

func _on_shader_rim_power_changed(v: float) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("rim_power", v)
	lbl_rim_power.text = "Potência Rim Light: %.1f" % v

func _on_shader_rim_bright_changed(v: float) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("rim_brightness", v)
	lbl_rim_bright.text = "Brilho Rim Light: %.2f" % v

func _on_shader_roughness_changed(v: float) -> void:
	if _active_material != null:
		_active_material.set_shader_parameter("roughness", v)
	lbl_roughness.text = "Rugosidade Fosca: %.2f" % v

# ==============================================================================
# 🏝️ SOLO DA ILHA, FALÉSIAS & MAR
# ==============================================================================

func _on_ground_color_changed(c: Color) -> void:
	IslandMeshBuilder.ground_base_color = c
	_reload_island_mesh()

func _on_ground_bright_changed(v: float) -> void:
	IslandMeshBuilder.ground_brightness = v
	lbl_ground_bright.text = "Brilho do Solo: %.2f" % v
	_reload_island_mesh()

func _on_ground_toon_toggled(pressed: bool) -> void:
	IslandMeshBuilder.ground_diffuse_toon = pressed
	_reload_island_mesh()

func _on_cliff_color_changed(_c: Color) -> void:
	# Como CLIFF_COLOR é constante no builder, podemos forçar rebuild
	_reload_island_mesh()

func _reload_island_mesh() -> void:
	if _cached_island_mi != null and not _cached_island_polys.is_empty():
		var new_mesh: ArrayMesh = IslandMeshBuilder.build_island_mesh(_cached_island_polys)
		if new_mesh != null:
			_cached_island_mi.mesh = new_mesh

func _on_ocean_visible_toggled(pressed: bool) -> void:
	if ocean_mesh != null:
		ocean_mesh.visible = pressed

func _on_water_shallow_changed(c: Color) -> void:
	if WATER_MATERIAL != null:
		WATER_MATERIAL.set_shader_parameter("_DepthGradientShallow", c)

func _on_water_deep_changed(c: Color) -> void:
	if WATER_MATERIAL != null:
		WATER_MATERIAL.set_shader_parameter("_DepthGradientDeep", c)

# ==============================================================================
# ⚡ PRESETS DE ILUMINAÇÃO
# ==============================================================================

func _apply_preset_canonical() -> void:
	# ☀️ Sol
	sun_pitch = -38.0
	sun_yaw = 40.0
	slider_sun_energy.value = 1.30
	slider_sun_pitch.value = sun_pitch
	slider_sun_yaw.value = sun_yaw
	picker_sun_color.color = Color(1.0, 0.98, 0.92, 1.0)
	check_sun_shadows.button_pressed = true
	check_sun_rotate.button_pressed = false
	_update_sun_orientation()

	# 🌌 Ambiente
	slider_ambient_energy.value = 0.35
	picker_ambient_color.color = Color(0.85, 0.92, 0.95, 1.0)
	picker_sky_color.color = Color(0.68, 0.85, 0.94, 1.0)
	opt_tonemap.selected = 2 # Filmic
	slider_exposure.value = 1.0
	_on_tonemap_selected(2)

	# 🎨 Toon Shader
	slider_ramp_offset.value = 0.50
	slider_ramp_smooth.value = 0.28
	slider_vert_grad.value = 0.85
	check_rim_light.button_pressed = false
	slider_rim_power.value = 1.5
	slider_rim_bright.value = 0.5
	slider_roughness.value = 0.90

	# 🏝️ Solo
	picker_ground_color.color = Color(0.14, 0.45, 0.19, 1.0)
	slider_ground_bright.value = 0.80
	check_ground_toon.button_pressed = true

	_show_toast("☀️ Preset Canônico Equilibrado Aplicado!")

func _apply_preset_current() -> void:
	# 🎮 Valores exatos de scenes/main.tscn
	sun_pitch = -45.0
	sun_yaw = 30.0
	slider_sun_energy.value = 1.0
	slider_sun_pitch.value = sun_pitch
	slider_sun_yaw.value = sun_yaw
	picker_sun_color.color = Color.WHITE
	check_sun_shadows.button_pressed = true
	check_sun_rotate.button_pressed = false
	_update_sun_orientation()

	slider_ambient_energy.value = 0.85
	picker_ambient_color.color = Color(0.85, 0.92, 0.88, 1.0)
	picker_sky_color.color = Color(0.68, 0.85, 0.9, 1.0)
	opt_tonemap.selected = 2
	slider_exposure.value = 1.0
	_on_tonemap_selected(2)

	_show_toast("🎮 Preset Produção Atual (main.tscn) Aplicado!")

func _apply_preset_golden() -> void:
	# 🌅 Pôr do Sol Dourado Tropical
	sun_pitch = -24.0
	sun_yaw = 65.0
	slider_sun_energy.value = 1.45
	slider_sun_pitch.value = sun_pitch
	slider_sun_yaw.value = sun_yaw
	picker_sun_color.color = Color(1.0, 0.82, 0.55, 1.0)
	check_sun_shadows.button_pressed = true
	_update_sun_orientation()

	slider_ambient_energy.value = 0.40
	picker_ambient_color.color = Color(0.95, 0.78, 0.70, 1.0)
	picker_sky_color.color = Color(0.92, 0.65, 0.55, 1.0)

	_show_toast("🌅 Preset Golden Hour Aplicado!")

func _apply_preset_pop() -> void:
	# 🏖️ Casual Pop Saturado (Estilo Brawl Stars / Top Charts)
	sun_pitch = -42.0
	sun_yaw = 35.0
	slider_sun_energy.value = 1.50
	slider_sun_pitch.value = sun_pitch
	slider_sun_yaw.value = sun_yaw
	picker_sun_color.color = Color(1.0, 1.0, 0.95, 1.0)
	check_sun_shadows.button_pressed = true
	_update_sun_orientation()

	slider_ambient_energy.value = 0.45
	picker_ambient_color.color = Color(0.80, 0.92, 1.0, 1.0)
	picker_sky_color.color = Color(0.50, 0.82, 0.98, 1.0)

	slider_ramp_offset.value = 0.46
	slider_ramp_smooth.value = 0.16

	_show_toast("🏖️ Preset Casual Pop Saturado Aplicado!")

func _apply_preset_dusk() -> void:
	# 🌙 Crepúsculo Estilizado
	sun_pitch = -16.0
	sun_yaw = 80.0
	slider_sun_energy.value = 0.75
	slider_sun_pitch.value = sun_pitch
	slider_sun_yaw.value = sun_yaw
	picker_sun_color.color = Color(0.85, 0.70, 0.95, 1.0)
	_update_sun_orientation()

	slider_ambient_energy.value = 0.28
	picker_ambient_color.color = Color(0.35, 0.45, 0.65, 1.0)
	picker_sky_color.color = Color(0.22, 0.28, 0.48, 1.0)

	_show_toast("🌙 Preset Crepúsculo Aplicado!")

# ==============================================================================
# 💾 SALVAR NO JOGO & EXPORTAÇÃO
# ==============================================================================

func _on_btn_save_game_pressed() -> void:
	# 1. Salva o material de vegetação ativo
	if _active_material != null:
		var path: String = _active_material.resource_path
		if path.begins_with("res://"):
			ResourceSaver.save(_active_material, path)

	# 2. Atualiza parâmetros estáticos de IslandMeshBuilder
	IslandMeshBuilder.ground_base_color = picker_ground_color.color
	IslandMeshBuilder.ground_brightness = slider_ground_bright.value
	IslandMeshBuilder.ground_diffuse_toon = check_ground_toon.button_pressed

	_show_toast("💾 Salvo Diretamente no Jogo com Sucesso!")

func _on_btn_copy_code_pressed() -> void:
	var code_snippet: String = """# Parâmetros Calibrados de Iluminação e Shaders (Grass Cut Bot)
# DirectionalLight3D
sun_energy = %.2f
sun_rotation = Vector3(%.1f, %.1f, 0.0)
sun_color = Color(%.2f, %.2f, %.2f)

# WorldEnvironment
ambient_energy = %.2f
ambient_color = Color(%.2f, %.2f, %.2f)
background_color = Color(%.2f, %.2f, %.2f)

# Solo da Ilha (IslandMeshBuilder)
ground_base_color = Color(%.2f, %.2f, %.2f)
ground_brightness = %.2f
ground_diffuse_toon = %s

# Toon Shader Vegetação (%s)
toon_ramp_offset = %.2f
toon_ramp_smoothness = %.2f
vertical_gradient_mix = %.2f
roughness = %.2f
""" % [
		slider_sun_energy.value,
		sun_pitch, sun_yaw,
		picker_sun_color.color.r, picker_sun_color.color.g, picker_sun_color.color.b,
		slider_ambient_energy.value,
		picker_ambient_color.color.r, picker_ambient_color.color.g, picker_ambient_color.color.b,
		picker_sky_color.color.r, picker_sky_color.color.g, picker_sky_color.color.b,
		IslandMeshBuilder.ground_base_color.r, IslandMeshBuilder.ground_base_color.g, IslandMeshBuilder.ground_base_color.b,
		IslandMeshBuilder.ground_brightness,
		str(IslandMeshBuilder.ground_diffuse_toon),
		_active_mat_key,
		slider_ramp_offset.value,
		slider_ramp_smooth.value,
		slider_vert_grad.value,
		slider_roughness.value
	]

	DisplayServer.clipboard_set(code_snippet)
	_show_toast("📋 Parâmetros Copiados para o Clipboard!")

func _show_toast(msg: String) -> void:
	if toast_label != null:
		toast_label.text = msg
		toast_label.visible = true
		_toast_timer = 3.0
