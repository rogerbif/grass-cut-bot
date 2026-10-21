extends CanvasLayer
## Sonda de performance e barra de ferramentas touch (debug/teste):
## Exibe FPS, nós, draw calls, tempos de frame e botões clicáveis para PC e Mobile.

signal action_triggered(action_id: String)

const REFRESH_INTERVAL: float = 0.5

var extra_text: String = ""

var _label: Label
var _btn_box: HFlowContainer
var _accum: float = 0.0
var _frames: int = 0
var _min_fps: float = 9999.0
var _worst_frame_ms: float = 0.0

func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	var root_vbox := VBoxContainer.new()
	root_vbox.position = Vector2(12.0, 86.0)
	root_vbox.size = Vector2(696.0, 220.0)
	root_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_vbox)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.add_theme_font_size_override("font_size", 17)
	_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4, 1.0))
	_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_label.add_theme_constant_override("outline_size", 6)
	root_vbox.add_child(_label)

	_btn_box = HFlowContainer.new()
	_btn_box.add_theme_constant_override("h_separation", 6)
	_btn_box.add_theme_constant_override("v_separation", 6)
	root_vbox.add_child(_btn_box)

	_create_action_button("Modo [B]", "toggle_mode")
	_create_action_button("Reset [T]", "reset_level")
	_create_action_button("100% [1]", "dens_1")
	_create_action_button("50% [2]", "dens_2")
	_create_action_button("25% [3]", "dens_4")
	_create_action_button("Grama [G]", "toggle_veg")
	_create_action_button("Sombra [L]", "toggle_shadow")
	_create_action_button("Escala [R]", "cycle_scale")
	_create_action_button("VSync [V]", "toggle_vsync")
	_create_action_button("Menu [M]", "back_menu")

func _create_action_button(title: String, action_id: String) -> void:
	var btn := Button.new()
	btn.text = title
	btn.custom_minimum_size = Vector2(92.0, 38.0)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_font_size_override("font_size", 14)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.16, 0.22, 0.88)
	style.border_color = Color(0.35, 0.85, 0.45, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 8.0
	style.content_margin_right = 8.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0

	var style_pressed := style.duplicate() as StyleBoxFlat
	style_pressed.bg_color = Color(0.25, 0.55, 0.32, 0.95)

	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style_pressed)
	btn.pressed.connect(func() -> void: action_triggered.emit(action_id))
	_btn_box.add_child(btn)

func _process(delta: float) -> void:
	_accum += delta
	_frames += 1
	_worst_frame_ms = maxf(_worst_frame_ms, delta * 1000.0)
	if delta > 0.0:
		_min_fps = minf(_min_fps, 1.0 / delta)
	if _accum < REFRESH_INTERVAL:
		return

	var avg_fps: float = float(_frames) / _accum
	var nodes: int = int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))
	var draw_calls: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var prims: int = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var t_process: float = Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
	var t_physics: float = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	var mem_mb: float = Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0

	var txt: String = "FPS %.1f (min %.1f) | pior frame %.1f ms\n" % [avg_fps, _min_fps, _worst_frame_ms]
	txt += "Nós %d | Draw calls %d | Prims %d\n" % [nodes, draw_calls, prims]
	txt += "Process %.2f ms | Physics %.2f ms | Mem %.0f MB" % [t_process, t_physics, mem_mb]
	if extra_text != "":
		txt += "\n" + extra_text
	_label.text = txt

	_accum = 0.0
	_frames = 0
	_min_fps = 9999.0
	_worst_frame_ms = 0.0
