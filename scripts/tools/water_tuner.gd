extends Node3D

const WATER_MAT_PATH: String = "res://shaders/wind_waker_water_material.tres"
const VegetationGridScript = preload("res://scripts/plants/vegetation_grid.gd")
const LevelJsonLoader = preload("res://scripts/level/level_json_loader.gd")

@onready var cam: Camera3D = $Camera3D
@onready var water_mesh: MeshInstance3D = $WaterMesh
@onready var island_container: Node3D = $IslandContainer

# UI References
@onready var slider_uv_scale: HSlider = %SliderUvScale
@onready var lbl_uv_scale: Label = %LblUvScale
@onready var slider_speed: HSlider = %SliderSpeed
@onready var lbl_speed: Label = %LblSpeed
@onready var slider_strength: HSlider = %SliderStrength
@onready var lbl_strength: Label = %LblStrength
@onready var slider_foam: HSlider = %SliderFoam
@onready var lbl_foam: Label = %LblFoam
@onready var slider_roughness: HSlider = %SliderRoughness
@onready var lbl_roughness: Label = %LblRoughness

@onready var picker_water1: ColorPickerButton = %PickerWater1
@onready var picker_water2: ColorPickerButton = %PickerWater2
@onready var picker_foam: ColorPickerButton = %PickerFoam

@onready var btn_copy: Button = %BtnCopy
@onready var btn_save: Button = %BtnSave
@onready var btn_cam_toggle: Button = %BtnCamToggle
@onready var btn_level_toggle: Button = %BtnLevelToggle
@onready var toast_label: Label = %ToastLabel
@onready var panel_container: PanelContainer = $CanvasLayer/Control/PanelContainer

var water_material: ShaderMaterial = null
var current_level: int = 2
var is_map_camera: bool = false
var _active_veg_grid: Node3D = null

func _ready() -> void:
	# Carrega ou instancia o material
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
	veg_grid.name = "TunerVegGrid"
	island_container.add_child(veg_grid)
	_active_veg_grid = veg_grid

	var dummy_obstacles: Node3D = Node3D.new()
	island_container.add_child(dummy_obstacles)
	veg_grid.call("build_from_level_json", data, dummy_obstacles, null)

	# Remove a água interna do VegetationGrid para não sobrepor a água do tuner
	var internal_water: Node = veg_grid.get_node_or_null("WaterOcean")
	if internal_water != null:
		internal_water.queue_free()

func _sync_ui_from_material() -> void:
	if water_material == null:
		return

	var uv_s: float = float(water_material.get_shader_parameter("uv_scale"))
	var spd: float = float(water_material.get_shader_parameter("distortion_speed"))
	var strg: float = float(water_material.get_shader_parameter("distortion_strength"))
	var foam: float = float(water_material.get_shader_parameter("foam_intensity"))
	var rgh: float = float(water_material.get_shader_parameter("roughness"))

	var c_w1: Variant = water_material.get_shader_parameter("water_color")
	var c_w2: Variant = water_material.get_shader_parameter("water2_color")
	var c_fm: Variant = water_material.get_shader_parameter("foam_color")

	if slider_uv_scale != null:
		slider_uv_scale.set_value_no_signal(uv_s)
		lbl_uv_scale.text = "%.3f" % uv_s
	if slider_speed != null:
		slider_speed.set_value_no_signal(spd)
		lbl_speed.text = "%.2f" % spd
	if slider_strength != null:
		slider_strength.set_value_no_signal(strg)
		lbl_strength.text = "%.3f" % strg
	if slider_foam != null:
		slider_foam.set_value_no_signal(foam)
		lbl_foam.text = "%.2f" % foam
	if slider_roughness != null:
		slider_roughness.set_value_no_signal(rgh)
		lbl_roughness.text = "%.2f" % rgh

	if picker_water1 != null and c_w1 is Color:
		picker_water1.color = c_w1 as Color
	if picker_water2 != null and c_w2 is Color:
		picker_water2.color = c_w2 as Color
	if picker_foam != null and c_fm is Color:
		picker_foam.color = c_fm as Color

func _connect_signals() -> void:
	slider_uv_scale.value_changed.connect(func(v: float) -> void:
		lbl_uv_scale.text = "%.3f" % v
		_set_param("uv_scale", v)
	)
	slider_speed.value_changed.connect(func(v: float) -> void:
		lbl_speed.text = "%.2f" % v
		_set_param("distortion_speed", v)
	)
	slider_strength.value_changed.connect(func(v: float) -> void:
		lbl_strength.text = "%.3f" % v
		_set_param("distortion_strength", v)
	)
	slider_foam.value_changed.connect(func(v: float) -> void:
		lbl_foam.text = "%.2f" % v
		_set_param("foam_intensity", v)
	)
	slider_roughness.value_changed.connect(func(v: float) -> void:
		lbl_roughness.text = "%.2f" % v
		_set_param("roughness", v)
	)

	picker_water1.color_changed.connect(func(c: Color) -> void: _set_param("water_color", c))
	picker_water2.color_changed.connect(func(c: Color) -> void: _set_param("water2_color", c))
	picker_foam.color_changed.connect(func(c: Color) -> void: _set_param("foam_color", c))

	btn_copy.pressed.connect(_on_btn_copy_pressed)
	btn_save.pressed.connect(_on_btn_save_pressed)
	btn_cam_toggle.pressed.connect(_on_btn_cam_toggle_pressed)
	btn_level_toggle.pressed.connect(_on_btn_level_toggle_pressed)

func _set_param(param_name: String, val: Variant) -> void:
	if water_material != null:
		water_material.set_shader_parameter(param_name, val)

func _set_camera_mode(map_mode: bool) -> void:
	is_map_camera = map_mode
	if cam == null:
		return
	if is_map_camera:
		# Visão aérea do Mapa de Fases
		cam.position = Vector3(0.0, 28.0, 17.5)
		cam.rotation_degrees = Vector3(-58.0, 0.0, 0.0)
		btn_cam_toggle.text = "🎥 Câmera: Mapa de Fases (Aérea)"
	else:
		# Visão isométrica das partidas de gameplay
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
	_show_toast("📋 Parâmetros copiados para a área de transferência!")

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
	var uv_s: float = float(water_material.get_shader_parameter("uv_scale"))
	var spd: float = float(water_material.get_shader_parameter("distortion_speed"))
	var strg: float = float(water_material.get_shader_parameter("distortion_strength"))
	var foam: float = float(water_material.get_shader_parameter("foam_intensity"))
	var rgh: float = float(water_material.get_shader_parameter("roughness"))
	var c_w1: Color = water_material.get_shader_parameter("water_color") as Color
	var c_w2: Color = water_material.get_shader_parameter("water2_color") as Color
	var c_fm: Color = water_material.get_shader_parameter("foam_color") as Color

	var txt: String = """PARÂMETROS DA ÁGUA (WIND WAKER):
uv_scale = %.3f
distortion_speed = %.2f
distortion_strength = %.3f
foam_intensity = %.2f
roughness = %.2f
water_color = Color(%.3f, %.3f, %.3f, 1.0) # #%s
water2_color = Color(%.3f, %.3f, %.3f, 1.0) # #%s
foam_color = Color(%.3f, %.3f, %.3f, 1.0) # #%s""" % [
		uv_s, spd, strg, foam, rgh,
		c_w1.r, c_w1.g, c_w1.b, c_w1.to_html(false),
		c_w2.r, c_w2.g, c_w2.b, c_w2.to_html(false),
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
