extends Node3D

const WATER_MAT_PATH: String = "res://shaders/toon_water_material.tres"
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

@onready var cam: Camera3D = $Camera3D
@onready var water_mesh: MeshInstance3D = $WaterMesh
@onready var island_container: Node3D = $IslandContainer

# UI References
@onready var slider_world_scale: HSlider = %SliderWorldScale
@onready var lbl_world_scale: Label = %LblWorldScale

@onready var slider_beer: HSlider = %SliderBeer
@onready var lbl_beer: Label = %LblBeer

@onready var slider_noise_cutoff: HSlider = %SliderNoiseCutoff
@onready var lbl_noise_cutoff: Label = %LblNoiseCutoff

@onready var slider_distortion: HSlider = %SliderDistortion
@onready var lbl_distortion: Label = %LblDistortion

@onready var slider_scroll_speed: HSlider = %SliderScrollSpeed
@onready var lbl_scroll_speed: Label = %LblScrollSpeed

@onready var slider_foam_dist: HSlider = %SliderFoamDist
@onready var lbl_foam_dist: Label = %LblFoamDist

@onready var slider_roughness: HSlider = %SliderRoughness
@onready var lbl_roughness: Label = %LblRoughness

@onready var picker_shallow: ColorPickerButton = %PickerShallow
@onready var picker_deep: ColorPickerButton = %PickerDeep
@onready var picker_foam: ColorPickerButton = %PickerFoam

@onready var btn_coords_toggle: Button = %BtnCoordsToggle
@onready var btn_copy: Button = %BtnCopy
@onready var btn_save: Button = %BtnSave
@onready var btn_cam_toggle: Button = %BtnCamToggle
@onready var btn_level_toggle: Button = %BtnLevelToggle
@onready var toast_label: Label = %ToastLabel
@onready var panel_container: PanelContainer = $CanvasLayer/Control/PanelContainer

var water_material: ShaderMaterial = null
var current_level: int = 2
var is_map_camera: bool = false
var _use_world_coords: bool = true
var _active_veg_grid: Node3D = null

func _ready() -> void:
	if ResourceLoader.exists(WATER_MAT_PATH):
		water_material = load(WATER_MAT_PATH) as ShaderMaterial
	if water_material != null and water_mesh != null:
		water_mesh.material_override = water_material

	_load_island(current_level)
	_sync_ui_from_material()
	_connect_signals()
	_set_camera_mode(false)

func _load_island(lvl: int) -> void:
	for c: Node in island_container.get_children():
		c.queue_free()
	_active_veg_grid = null

	var json_path: String = "res://data/levels/level_%02d.json" % lvl
	if not FileAccess.file_exists(json_path):
		json_path = "res://data/levels/level_01.json"
	var data: Dictionary = LevelJsonLoader.load_json_file(json_path)

	var veg_grid: Node3D = VegetationGridScript.new() as Node3D
	veg_grid.name = "WaterTunerVegGrid"
	island_container.add_child(veg_grid)
	_active_veg_grid = veg_grid

	var dummy_obstacles: Node3D = Node3D.new()
	island_container.add_child(dummy_obstacles)
	veg_grid.call("build_from_level_json", data, dummy_obstacles, null)

	var internal_water: Node = veg_grid.get_node_or_null("WaterOcean")
	if internal_water != null:
		internal_water.queue_free()

func _sync_ui_from_material() -> void:
	if water_material == null:
		return

	var w_scale: float = float(water_material.get_shader_parameter("world_scale"))
	var beer: float = float(water_material.get_shader_parameter("beer_factor"))
	var cutoff: float = float(water_material.get_shader_parameter("surface_noise_cutoff"))
	var dist: float = float(water_material.get_shader_parameter("surface_distortion_amount"))
	var scr_v: Variant = water_material.get_shader_parameter("surface_noise_scroll")
	var scr_spd: float = (scr_v as Vector3).x if scr_v is Vector3 else 0.04
	var foam_d: float = float(water_material.get_shader_parameter("foam_max_distance"))
	var rgh: float = float(water_material.get_shader_parameter("roughness"))
	var coords_param: Variant = water_material.get_shader_parameter("use_world_coords")
	_use_world_coords = bool(coords_param) if coords_param != null else true

	var c_sh: Variant = water_material.get_shader_parameter("_DepthGradientShallow")
	var c_dp: Variant = water_material.get_shader_parameter("_DepthGradientDeep")
	var c_fm: Variant = water_material.get_shader_parameter("foam_color")

	if slider_world_scale != null:
		slider_world_scale.set_value_no_signal(w_scale)
		lbl_world_scale.text = "%.3f" % w_scale
	if slider_beer != null:
		slider_beer.set_value_no_signal(beer)
		lbl_beer.text = "%.2f" % beer
	if slider_noise_cutoff != null:
		slider_noise_cutoff.set_value_no_signal(cutoff)
		lbl_noise_cutoff.text = "%.3f" % cutoff
	if slider_distortion != null:
		slider_distortion.set_value_no_signal(dist)
		lbl_distortion.text = "%.2f" % dist
	if slider_scroll_speed != null:
		slider_scroll_speed.set_value_no_signal(scr_spd)
		lbl_scroll_speed.text = "%.3f" % scr_spd
	if slider_foam_dist != null:
		slider_foam_dist.set_value_no_signal(foam_d)
		lbl_foam_dist.text = "%.2f" % foam_d
	if slider_roughness != null:
		slider_roughness.set_value_no_signal(rgh)
		lbl_roughness.text = "%.2f" % rgh

	if picker_shallow != null and c_sh is Color:
		picker_shallow.color = c_sh as Color
	if picker_deep != null and c_dp is Color:
		picker_deep.color = c_dp as Color
	if picker_foam != null and c_fm is Color:
		picker_foam.color = c_fm as Color

	_update_coords_button()

func _update_coords_button() -> void:
	if btn_coords_toggle != null:
		btn_coords_toggle.text = "🌐 Mapeamento: %s" % ("Coordenadas de Mundo (XZ)" if _use_world_coords else "UV da Malha (Local)")

func _connect_signals() -> void:
	slider_world_scale.value_changed.connect(func(v: float) -> void:
		lbl_world_scale.text = "%.3f" % v
		_set_param("world_scale", v)
	)
	slider_beer.value_changed.connect(func(v: float) -> void:
		lbl_beer.text = "%.2f" % v
		_set_param("beer_factor", v)
	)
	slider_noise_cutoff.value_changed.connect(func(v: float) -> void:
		lbl_noise_cutoff.text = "%.3f" % v
		_set_param("surface_noise_cutoff", v)
	)
	slider_distortion.value_changed.connect(func(v: float) -> void:
		lbl_distortion.text = "%.2f" % v
		_set_param("surface_distortion_amount", v)
	)
	slider_scroll_speed.value_changed.connect(func(v: float) -> void:
		lbl_scroll_speed.text = "%.3f" % v
		_set_param("surface_noise_scroll", Vector3(v, v, 0.0))
	)
	slider_foam_dist.value_changed.connect(func(v: float) -> void:
		lbl_foam_dist.text = "%.2f" % v
		_set_param("foam_max_distance", v)
	)
	slider_roughness.value_changed.connect(func(v: float) -> void:
		lbl_roughness.text = "%.2f" % v
		_set_param("roughness", v)
	)

	picker_shallow.color_changed.connect(func(c: Color) -> void: _set_param("_DepthGradientShallow", c))
	picker_deep.color_changed.connect(func(c: Color) -> void: _set_param("_DepthGradientDeep", c))
	picker_foam.color_changed.connect(func(c: Color) -> void: _set_param("foam_color", c))

	btn_coords_toggle.pressed.connect(_on_btn_coords_toggle_pressed)
	btn_copy.pressed.connect(_on_btn_copy_pressed)
	btn_save.pressed.connect(_on_btn_save_pressed)
	btn_cam_toggle.pressed.connect(_on_btn_cam_toggle_pressed)
	btn_level_toggle.pressed.connect(_on_btn_level_toggle_pressed)

func _set_param(param_name: String, val: Variant) -> void:
	if water_material != null:
		water_material.set_shader_parameter(param_name, val)

func _on_btn_coords_toggle_pressed() -> void:
	_use_world_coords = not _use_world_coords
	_set_param("use_world_coords", _use_world_coords)
	_update_coords_button()
	_show_toast("Mapeamento alterado para: %s" % ("Mundo" if _use_world_coords else "UV"))

func _set_camera_mode(map_mode: bool) -> void:
	is_map_camera = map_mode
	if cam == null:
		return
	if is_map_camera:
		cam.position = Vector3(0.0, 28.0, 17.5)
		cam.rotation_degrees = Vector3(-58.0, 0.0, 0.0)
		btn_cam_toggle.text = "🎥 Câmera: Mapa de Fases (Aérea)"
	else:
		cam.position = Vector3(0.0, 7.2, 8.5)
		cam.rotation_degrees = Vector3(-40.0, 0.0, 0.0)
		btn_cam_toggle.text = "🎥 Câmera: Jogo / Partida (Isométrica)"

func _on_btn_cam_toggle_pressed() -> void:
	_set_camera_mode(not is_map_camera)

func _on_btn_level_toggle_pressed() -> void:
	var levels: Array[int] = [1, 2, 5, 6, 20]
	var next_idx: int = (levels.find(current_level) + 1) % levels.size()
	current_level = levels[next_idx]
	btn_level_toggle.text = "🏝️ Fase Testada: %02d" % current_level
	_load_island(current_level)

func _on_btn_copy_pressed() -> void:
	var export_text: String = _generate_parameters_text()
	DisplayServer.clipboard_set(export_text)
	_show_toast("📋 Parâmetros Toon Water copiados!")

func _on_btn_save_pressed() -> void:
	if water_material != null:
		var err: Error = ResourceSaver.save(water_material, WATER_MAT_PATH)
		if err == OK:
			_show_toast("💾 Salvo em %s com sucesso!" % WATER_MAT_PATH)
		else:
			_show_toast("❌ Erro ao salvar arquivo .tres (código %d)" % int(err))

func _generate_parameters_text() -> String:
	if water_material == null:
		return ""
	var w_scale: float = float(water_material.get_shader_parameter("world_scale"))
	var beer: float = float(water_material.get_shader_parameter("beer_factor"))
	var cutoff: float = float(water_material.get_shader_parameter("surface_noise_cutoff"))
	var dist: float = float(water_material.get_shader_parameter("surface_distortion_amount"))
	var scr_v: Variant = water_material.get_shader_parameter("surface_noise_scroll")
	var scr_spd: float = (scr_v as Vector3).x if scr_v is Vector3 else 0.04
	var foam_d: float = float(water_material.get_shader_parameter("foam_max_distance"))
	var rgh: float = float(water_material.get_shader_parameter("roughness"))
	var c_sh: Color = water_material.get_shader_parameter("_DepthGradientShallow") as Color
	var c_dp: Color = water_material.get_shader_parameter("_DepthGradientDeep") as Color
	var c_fm: Color = water_material.get_shader_parameter("foam_color") as Color

	var txt: String = """PARÂMETROS TOON WATER SHADER (ROYSTAN / HGOUVEIA):
world_scale = %.3f
beer_factor = %.2f
surface_noise_cutoff = %.3f
surface_distortion_amount = %.2f
surface_noise_scroll = Vector3(%.3f, %.3f, 0.0)
foam_max_distance = %.2f
roughness = %.2f
use_world_coords = %s
_DepthGradientShallow = Color(%.3f, %.3f, %.3f, 1.0) # #%s
_DepthGradientDeep = Color(%.3f, %.3f, %.3f, 1.0) # #%s
foam_color = Color(%.3f, %.3f, %.3f, 1.0) # #%s""" % [
		w_scale, beer, cutoff, dist, scr_spd, scr_spd, foam_d, rgh,
		str(_use_world_coords),
		c_sh.r, c_sh.g, c_sh.b, c_sh.to_html(false),
		c_dp.r, c_dp.g, c_dp.b, c_dp.to_html(false),
		c_fm.r, c_fm.g, c_fm.b, c_fm.to_html(false)
	]
	return txt

func _show_toast(msg: String) -> void:
	if toast_label == null:
		return
	toast_label.text = msg
	toast_label.visible = true
	toast_label.modulate.a = 1.0
	var tw: Tween = create_tween()
	tw.tween_interval(2.0)
	tw.tween_property(toast_label, "modulate:a", 0.0, 0.4)
	tw.tween_callback(func() -> void: toast_label.visible = false)

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey):
		return
	var key_event: InputEventKey = event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return

	match key_event.keycode:
		KEY_H:
			if panel_container != null:
				panel_container.visible = not panel_container.visible
				_show_toast("Painel: %s [H]" % ("Visível" if panel_container.visible else "Oculto"))
		KEY_C:
			_on_btn_copy_pressed()
		KEY_V:
			_on_btn_cam_toggle_pressed()
		KEY_TAB:
			_on_btn_level_toggle_pressed()
		KEY_S:
			_on_btn_save_pressed()
