extends Control

const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")

const GOALS_CATALOG: Array[Dictionary] = [
	{ "key": "grass_green", "name": "🌿 Grama Verde", "color": Color(0.36, 0.78, 0.41), "unit": "tufos" },
	{ "key": "grass_yellow", "name": "🌼 Grama Amarela", "color": Color(0.95, 0.83, 0.35), "unit": "tufos" },
	{ "key": "grass_blue", "name": "💠 Grama Azul", "color": Color(0.39, 0.74, 0.96), "unit": "tufos" },
	{ "key": "grass_purple", "name": "🔮 Grama Violeta", "color": Color(0.76, 0.46, 0.92), "unit": "tufos" },
	{ "key": "grass_white", "name": "🤍 Grama Branca", "color": Color(0.92, 0.94, 0.98), "unit": "tufos" },
	{ "key": "grass_red", "name": "❤️ Grama Vermelha", "color": Color(0.95, 0.37, 0.38), "unit": "tufos" },
	{ "key": "grass_black", "name": "🖤 Grama Preta", "color": Color(0.48, 0.48, 0.55), "unit": "tufos" },
	{ "key": "wheat", "name": "🌾 Trigo Maduro", "color": Color(1.0, 0.82, 0.28), "unit": "trigos" },
	{ "key": "flower", "name": "🌸 Flor Silvestre", "color": Color(1.0, 0.18, 0.65), "unit": "flores" },
	{ "key": "flower_rose", "name": "🌹 Rosa Nobre", "color": Color(1.0, 0.08, 0.35), "unit": "rosas" },
	{ "key": "flower_daisy", "name": "🌼 Margarida", "color": Color(1.0, 1.0, 1.0), "unit": "margaridas" },
	{ "key": "flower_sunflower", "name": "🌻 Girassol", "color": Color(1.0, 0.88, 0.0), "unit": "girassóis" },
	{ "key": "flower_bell", "name": "🔔 Flor Sino", "color": Color(0.12, 0.65, 1.0), "unit": "sinos" },
	{ "key": "flower_corolla", "name": "🏵️ Cravo Corola", "color": Color(1.0, 0.50, 0.05), "unit": "cravos" },
	{ "key": "flower_tulip", "name": "🌷 Tulipa Imperial", "color": Color(1.0, 0.08, 0.24), "unit": "tulipas" },
	{ "key": "flower_bed", "name": "🪻 Canteiro Florido", "color": Color(0.88, 0.30, 1.0), "unit": "canteiros" }
]

signal level_load_requested(level_id: int)
signal grid_resize_requested(new_width: int, new_height: int)
signal time_limit_changed(new_time: float)
signal generate_base_island_requested()
signal clear_objects_requested()
signal clear_all_requested()
signal undo_requested()
signal redo_requested()
signal save_json_requested()
signal bake_tscn_requested()
signal playtest_toggled()
signal exit_to_game_requested()

signal layer_changed(layer_idx: int)
signal tool_changed(tool_idx: int)
signal brush_shape_changed(shape_idx: int)
signal corner_radius_changed(radius: float)
signal brush_size_changed(new_size: int)
signal rotate_requested()
signal rotate_step_requested(direction: int, is_shift: bool)
signal adjust_mode_changed(mode: int)
signal toggle_camera_view_requested()
signal toggle_mirror_mode_requested()

signal terrain_tile_selected(tile_id: String)
signal grass_item_selected(grass_id: String)
signal object_item_selected(obj_id: String)
signal convert_yellow_to_wheat_requested()

var spin_level: SpinBox
var spin_width: SpinBox
var spin_height: SpinBox
var spin_time: SpinBox

var btn_layer_terrain: Button
var btn_layer_grass: Button
var btn_layer_objects: Button
var tool_buttons: Dictionary = {}
var shape_buttons: Dictionary = {}
var corner_radius_container: VBoxContainer
var spin_corner_radius: SpinBox
var terrain_buttons: Dictionary = {}
var grass_buttons: Dictionary = {}
var object_buttons: Dictionary = {}

var panel_scale_box: PanelContainer
var panel_rotate_box: PanelContainer
var lbl_brush_size: Label
var btn_sz_minus: Button
var btn_sz_plus: Button
var btn_rotate: Button
var btn_rot_left: Button
var btn_rot_right: Button
var btn_cam_view: Button
var btn_mirror: Button
var lbl_status: Label

var lbl_active_layer_banner: Label
var _goal_checkboxes: Dictionary = {}
var _goal_spinboxes: Dictionary = {}
var _goal_total_labels: Dictionary = {}
var _goal_manually_edited: Dictionary = {}
var _goal_manually_unchecked: Dictionary = {}
var _last_detected_counts: Dictionary = {}
var lbl_world_metrics: Label

var section_terrain: VBoxContainer
var section_grass: VBoxContainer
var section_objects: VBoxContainer

var editor_panels_root: Control
var playtest_bar: PanelContainer
var lbl_playtest_info: Label
var toast_container: VBoxContainer

var _interactive_panels: Array[Control] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_ui()

func is_mouse_over_ui(mouse_pos: Vector2) -> bool:
	if editor_panels_root != null and editor_panels_root.visible:
		for panel in _interactive_panels:
			if panel != null and panel.visible and panel.get_global_rect().has_point(mouse_pos):
				return true
	if playtest_bar != null and playtest_bar.visible and playtest_bar.get_global_rect().has_point(mouse_pos):
		return true
	var hovered: Control = get_viewport().gui_get_hovered_control()
	return hovered != null and hovered != self

func has_text_focus() -> bool:
	var focus_owner: Control = get_viewport().gui_get_focus_owner()
	if focus_owner == null:
		return false
	return (focus_owner is LineEdit) or (focus_owner is SpinBox)

func _build_ui() -> void:
	editor_panels_root = Control.new()
	editor_panels_root.name = "EditorPanelsRoot"
	editor_panels_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	editor_panels_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(editor_panels_root)

	_build_top_bar()
	_build_left_panel()
	_build_right_panel()
	_build_bottom_bar()
	_build_playtest_bar()
	_build_toast_container()

func _make_panel_style(bg: Color, border: Color, radius: int = 10) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 8
	s.content_margin_bottom = 8
	return s

func _make_btn_style(bg: Color, border: Color, radius: int = 7) -> StyleBoxFlat:
	var s: StyleBoxFlat = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(radius)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 5
	s.content_margin_bottom = 5
	return s

func _create_styled_button(text_str: String, accent: Color, min_size: Vector2 = Vector2(0, 34)) -> Button:
	var b: Button = Button.new()
	b.text = text_str
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_font_size_override("font_size", 14)
	b.add_theme_color_override("font_color", Color.WHITE)
	b.add_theme_stylebox_override("normal", _make_btn_style(Color(0.14, 0.18, 0.22, 0.95), accent.darkened(0.25)))
	b.add_theme_stylebox_override("hover", _make_btn_style(accent.darkened(0.55), accent.lightened(0.2)))
	b.add_theme_stylebox_override("pressed", _make_btn_style(accent.darkened(0.35), Color.WHITE))
	return b

func _set_button_selected(btn: Button, selected: bool, accent: Color) -> void:
	if btn == null:
		return
	if selected:
		btn.add_theme_stylebox_override("normal", _make_btn_style(accent.darkened(0.35), Color.WHITE))
		btn.add_theme_stylebox_override("hover", _make_btn_style(accent.darkened(0.25), Color.WHITE))
	else:
		btn.add_theme_stylebox_override("normal", _make_btn_style(Color(0.14, 0.18, 0.22, 0.95), accent.darkened(0.35)))
		btn.add_theme_stylebox_override("hover", _make_btn_style(accent.darkened(0.6), accent.lightened(0.15)))

func _build_top_bar() -> void:
	var top_panel: PanelContainer = PanelContainer.new()
	top_panel.set_anchors_preset(Control.PRESET_TOP_WIDE)
	top_panel.offset_left = 12
	top_panel.offset_top = 10
	top_panel.offset_right = -12
	top_panel.offset_bottom = 64
	top_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	top_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.09, 0.12, 0.16, 0.94), Color(0.25, 0.65, 0.85, 0.8)))
	editor_panels_root.add_child(top_panel)
	_interactive_panels.append(top_panel)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 8)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_panel.add_child(hbox)

	var title_lbl: Label = Label.new()
	title_lbl.text = "🏝️ EDITOR DE FASES"
	title_lbl.add_theme_font_size_override("font_size", 16)
	title_lbl.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
	hbox.add_child(title_lbl)

	hbox.add_child(VSeparator.new())

	var lbl_lvl: Label = Label.new()
	lbl_lvl.text = "Fase:"
	hbox.add_child(lbl_lvl)

	spin_level = SpinBox.new()
	spin_level.min_value = 1
	spin_level.max_value = 50
	spin_level.step = 1
	spin_level.value = 1
	spin_level.custom_minimum_size = Vector2(70, 32)
	spin_level.get_line_edit().text_submitted.connect(func(_text: String) -> void:
		get_viewport().gui_release_focus()
		level_load_requested.emit(int(spin_level.value))
	)
	hbox.add_child(spin_level)

	var btn_load: Button = _create_styled_button("📂 Abrir", Color(0.3, 0.75, 0.95))
	btn_load.pressed.connect(func() -> void:
		get_viewport().gui_release_focus()
		level_load_requested.emit(int(spin_level.value))
	)
	hbox.add_child(btn_load)

	hbox.add_child(VSeparator.new())

	var lbl_grid: Label = Label.new()
	lbl_grid.text = "Grade:"
	hbox.add_child(lbl_grid)

	spin_width = SpinBox.new()
	spin_width.min_value = 4
	spin_width.max_value = 100
	spin_width.step = 1
	spin_width.value = 12
	spin_width.tooltip_text = "Largura da Grade (colunas de 0.4m)"
	spin_width.custom_minimum_size = Vector2(68, 32)
	hbox.add_child(spin_width)

	var lbl_x: Label = Label.new()
	lbl_x.text = "x"
	hbox.add_child(lbl_x)

	spin_height = SpinBox.new()
	spin_height.min_value = 4
	spin_height.max_value = 100
	spin_height.step = 1
	spin_height.value = 8
	spin_height.tooltip_text = "Altura da Grade (linhas de 0.4m)"
	spin_height.custom_minimum_size = Vector2(68, 32)
	hbox.add_child(spin_height)

	var btn_resize: Button = _create_styled_button("📐 Redimensionar", Color(0.4, 0.7, 0.9))
	btn_resize.pressed.connect(func() -> void:
		get_viewport().gui_release_focus()
		grid_resize_requested.emit(int(spin_width.value), int(spin_height.value))
	)
	hbox.add_child(btn_resize)

	hbox.add_child(VSeparator.new())

	var lbl_t: Label = Label.new()
	lbl_t.text = "⏱️(s):"
	hbox.add_child(lbl_t)

	spin_time = SpinBox.new()
	spin_time.min_value = 15
	spin_time.max_value = 600
	spin_time.step = 5
	spin_time.value = 90
	spin_time.custom_minimum_size = Vector2(74, 32)
	spin_time.value_changed.connect(func(v: float) -> void:
		time_limit_changed.emit(v)
	)
	var le_time: LineEdit = spin_time.get_line_edit()
	le_time.text_changed.connect(func(new_text: String) -> void:
		if new_text.is_valid_float():
			var val: float = float(new_text)
			time_limit_changed.emit(val)
	)
	le_time.text_submitted.connect(func(_new_text: String) -> void:
		spin_time.apply()
		time_limit_changed.emit(spin_time.value)
	)
	le_time.focus_exited.connect(func() -> void:
		spin_time.apply()
		time_limit_changed.emit(spin_time.value)
	)
	hbox.add_child(spin_time)

	hbox.add_child(VSeparator.new())

	var btn_island: Button = _create_styled_button("🏝️ Gerar Ilha Base", Color(0.28, 0.80, 0.45))
	btn_island.tooltip_text = "Preenche a grade com uma ilha 3D completa com falésias e bordas"
	btn_island.pressed.connect(func() -> void: generate_base_island_requested.emit())
	hbox.add_child(btn_island)

	var btn_undo: Button = _create_styled_button("↩️ Undo", Color(0.65, 0.65, 0.75))
	btn_undo.tooltip_text = "Desfazer (Ctrl+Z)"
	btn_undo.pressed.connect(func() -> void: undo_requested.emit())
	hbox.add_child(btn_undo)

	var btn_redo: Button = _create_styled_button("↪️ Redo", Color(0.65, 0.65, 0.75))
	btn_redo.tooltip_text = "Refazer (Ctrl+Y)"
	btn_redo.pressed.connect(func() -> void: redo_requested.emit())
	hbox.add_child(btn_redo)

	hbox.add_child(VSeparator.new())

	var btn_save: Button = _create_styled_button("💾 Salvar [Ctrl+S]", Color(0.2, 0.85, 0.45))
	btn_save.pressed.connect(func() -> void: save_json_requested.emit())
	hbox.add_child(btn_save)

	var btn_bake: Button = _create_styled_button("📦 Bake .tscn", Color(0.65, 0.45, 0.95))
	btn_bake.tooltip_text = "Exporta também como cena nativa res://scenes/levels/level_XX.tscn"
	btn_bake.pressed.connect(func() -> void: bake_tscn_requested.emit())
	hbox.add_child(btn_bake)

	var btn_play: Button = _create_styled_button("▶️ Testar [F1]", Color(1.0, 0.75, 0.15))
	btn_play.pressed.connect(func() -> void: playtest_toggled.emit())
	hbox.add_child(btn_play)

	var btn_exit: Button = _create_styled_button("🚪 Jogo", Color(0.92, 0.35, 0.35))
	btn_exit.tooltip_text = "Voltar ao Jogo Mobile (Portrait)"
	btn_exit.pressed.connect(func() -> void: exit_to_game_requested.emit())
	hbox.add_child(btn_exit)

func _build_left_panel() -> void:
	var left_panel: PanelContainer = PanelContainer.new()
	left_panel.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	left_panel.offset_left = 12
	left_panel.offset_top = 70
	left_panel.offset_right = 292
	left_panel.offset_bottom = -52
	left_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	left_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.09, 0.12, 0.16, 0.94), Color(0.25, 0.65, 0.85, 0.75)))
	editor_panels_root.add_child(left_panel)
	_interactive_panels.append(left_panel)

	var scroll_left: ScrollContainer = ScrollContainer.new()
	scroll_left.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_left.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_panel.add_child(scroll_left)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll_left.add_child(vbox)

	# 1. Seletor de Camada
	var lbl_layer: Label = Label.new()
	lbl_layer.text = "CAMADA DE EDIÇÃO"
	lbl_layer.add_theme_font_size_override("font_size", 13)
	lbl_layer.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	vbox.add_child(lbl_layer)

	btn_layer_terrain = _create_styled_button("🏝️ Camada 0: Terreno (0.8m)", Color(0.28, 0.78, 0.45), Vector2(0, 34))
	btn_layer_terrain.pressed.connect(func() -> void: layer_changed.emit(0))
	vbox.add_child(btn_layer_terrain)

	btn_layer_grass = _create_styled_button("🌿 Camada 1: Grama (0.2m)", Color(0.30, 0.82, 0.95), Vector2(0, 34))
	btn_layer_grass.pressed.connect(func() -> void: layer_changed.emit(1))
	vbox.add_child(btn_layer_grass)

	btn_layer_objects = _create_styled_button("🪨 Camada 2: Objetos (0.8m)", Color(0.85, 0.65, 0.35), Vector2(0, 34))
	btn_layer_objects.pressed.connect(func() -> void: layer_changed.emit(2))
	vbox.add_child(btn_layer_objects)

	vbox.add_child(HSeparator.new())

	# 2. Ferramentas
	var lbl_tools: Label = Label.new()
	lbl_tools.text = "FERRAMENTAS [1..4]"
	lbl_tools.add_theme_font_size_override("font_size", 13)
	lbl_tools.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	vbox.add_child(lbl_tools)

	var tools_meta: Array[Dictionary] = [
		{ "id": 0, "name": "🖌️ [1] Pincel / Carimbo", "color": Color(0.25, 0.88, 0.52) },
		{ "id": 1, "name": "🧽 [2] Borracha (Apagar)", "color": Color(0.95, 0.38, 0.38) },
		{ "id": 2, "name": "🔲 [3] Retângulo (Box Fill)", "color": Color(0.98, 0.78, 0.22) },
		{ "id": 3, "name": "🤖 [4] Posicionar Spawn", "color": Color(0.95, 0.85, 0.25) }
	]

	for tm in tools_meta:
		var t_id: int = int(tm["id"])
		var b: Button = _create_styled_button(String(tm["name"]), tm["color"] as Color, Vector2(0, 34))
		b.pressed.connect(func() -> void: tool_changed.emit(t_id))
		vbox.add_child(b)
		tool_buttons[t_id] = b

	vbox.add_child(HSeparator.new())

	# 3. Formatos de Pincel / Carimbo
	var lbl_shapes: Label = Label.new()
	lbl_shapes.text = "FORMATO DO PINCEL / CARIMBO"
	lbl_shapes.add_theme_font_size_override("font_size", 13)
	lbl_shapes.add_theme_color_override("font_color", Color(0.55, 0.88, 1.0))
	vbox.add_child(lbl_shapes)

	var grid_shapes: GridContainer = GridContainer.new()
	grid_shapes.columns = 2
	grid_shapes.add_theme_constant_override("h_separation", 6)
	grid_shapes.add_theme_constant_override("v_separation", 6)
	vbox.add_child(grid_shapes)

	for sh in BrushPatterns.SHAPE_INFO:
		var s_id: int = int(sh["id"])
		var s_btn: Button = _create_styled_button("%s %s" % [String(sh["icon"]), String(sh["name"])], Color(0.45, 0.75, 0.98), Vector2(120, 34))
		s_btn.pressed.connect(func() -> void: brush_shape_changed.emit(s_id))
		grid_shapes.add_child(s_btn)
		shape_buttons[s_id] = s_btn

	# 3.1 Opção de Corner Radius para a ferramenta de Quadrado
	corner_radius_container = VBoxContainer.new()
	corner_radius_container.add_theme_constant_override("separation", 4)
	vbox.add_child(corner_radius_container)

	var hbox_cr: HBoxContainer = HBoxContainer.new()
	hbox_cr.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_cr.add_theme_constant_override("separation", 6)
	corner_radius_container.add_child(hbox_cr)

	var lbl_cr: Label = Label.new()
	lbl_cr.text = "📐 Quina (R):"
	lbl_cr.add_theme_font_size_override("font_size", 12)
	lbl_cr.add_theme_color_override("font_color", Color(0.9, 0.85, 0.55))
	hbox_cr.add_child(lbl_cr)

	spin_corner_radius = SpinBox.new()
	spin_corner_radius.min_value = 0.0
	spin_corner_radius.max_value = 0.80
	spin_corner_radius.step = 0.02
	spin_corner_radius.value = 0.28
	spin_corner_radius.suffix = "m"
	spin_corner_radius.custom_minimum_size = Vector2(85, 30)
	spin_corner_radius.value_changed.connect(func(v: float) -> void:
		corner_radius_changed.emit(v)
	)
	hbox_cr.add_child(spin_corner_radius)

	var hbox_cr_presets: HBoxContainer = HBoxContainer.new()
	hbox_cr_presets.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_cr_presets.add_theme_constant_override("separation", 4)
	corner_radius_container.add_child(hbox_cr_presets)

	var btn_cr_0: Button = _create_styled_button("0m (Reto)", Color(0.65, 0.65, 0.70), Vector2(75, 24))
	btn_cr_0.add_theme_font_size_override("font_size", 11)
	btn_cr_0.pressed.connect(func() -> void:
		spin_corner_radius.value = 0.0
		corner_radius_changed.emit(0.0)
	)
	hbox_cr_presets.add_child(btn_cr_0)

	var btn_cr_def: Button = _create_styled_button("0.28m (Padrão)", Color(0.35, 0.85, 0.60), Vector2(95, 24))
	btn_cr_def.add_theme_font_size_override("font_size", 11)
	btn_cr_def.pressed.connect(func() -> void:
		spin_corner_radius.value = 0.28
		corner_radius_changed.emit(0.28)
	)
	hbox_cr_presets.add_child(btn_cr_def)

	var btn_cr_max: Button = _create_styled_button("0.40m", Color(0.55, 0.75, 0.95), Vector2(65, 24))
	btn_cr_max.add_theme_font_size_override("font_size", 11)
	btn_cr_max.pressed.connect(func() -> void:
		spin_corner_radius.value = 0.40
		corner_radius_changed.emit(0.40)
	)
	hbox_cr_presets.add_child(btn_cr_max)

	# 4. Tamanho do Pincel e Rotação
	panel_scale_box = PanelContainer.new()
	panel_scale_box.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.11, 0.16, 0.8), Color(0.2, 0.35, 0.5, 0.4), 8))
	vbox.add_child(panel_scale_box)

	var hbox_size: HBoxContainer = HBoxContainer.new()
	hbox_size.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_size.add_theme_constant_override("separation", 6)
	panel_scale_box.add_child(hbox_size)

	btn_sz_minus = _create_styled_button("➖ [", Color(0.5, 0.7, 0.9), Vector2(56, 32))
	btn_sz_minus.pressed.connect(func() -> void:
		adjust_mode_changed.emit(1)
		brush_size_changed.emit(-5 if Input.is_key_pressed(KEY_SHIFT) else -1)
	)
	hbox_size.add_child(btn_sz_minus)

	lbl_brush_size = Label.new()
	lbl_brush_size.text = "Escala [S]: 1"
	lbl_brush_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_brush_size.custom_minimum_size = Vector2(95, 28)
	lbl_brush_size.mouse_filter = Control.MOUSE_FILTER_STOP
	lbl_brush_size.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			adjust_mode_changed.emit(1)
	)
	hbox_size.add_child(lbl_brush_size)

	btn_sz_plus = _create_styled_button("➕ ]", Color(0.5, 0.7, 0.9), Vector2(56, 32))
	btn_sz_plus.pressed.connect(func() -> void:
		adjust_mode_changed.emit(1)
		brush_size_changed.emit(5 if Input.is_key_pressed(KEY_SHIFT) else 1)
	)
	hbox_size.add_child(btn_sz_plus)

	panel_rotate_box = PanelContainer.new()
	panel_rotate_box.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.11, 0.16, 0.8), Color(0.2, 0.35, 0.5, 0.4), 8))
	vbox.add_child(panel_rotate_box)

	var hbox_rot: HBoxContainer = HBoxContainer.new()
	hbox_rot.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_rot.add_theme_constant_override("separation", 6)
	panel_rotate_box.add_child(hbox_rot)

	btn_rot_left = _create_styled_button("◀ [-]", Color(0.35, 0.85, 0.75), Vector2(46, 34))
	btn_rot_left.pressed.connect(func() -> void:
		adjust_mode_changed.emit(0)
		rotate_step_requested.emit(-1, Input.is_key_pressed(KEY_SHIFT))
	)
	hbox_rot.add_child(btn_rot_left)

	btn_rotate = _create_styled_button("🔄 Girar [R]: 0°", Color(0.35, 0.85, 0.75), Vector2(0, 34))
	btn_rotate.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_rotate.clip_text = true
	btn_rotate.pressed.connect(func() -> void:
		adjust_mode_changed.emit(0)
		rotate_step_requested.emit(1, Input.is_key_pressed(KEY_SHIFT))
	)
	hbox_rot.add_child(btn_rotate)

	btn_rot_right = _create_styled_button("[+] ▶", Color(0.35, 0.85, 0.75), Vector2(46, 34))
	btn_rot_right.pressed.connect(func() -> void:
		adjust_mode_changed.emit(0)
		rotate_step_requested.emit(1, Input.is_key_pressed(KEY_SHIFT))
	)
	hbox_rot.add_child(btn_rot_right)

	btn_cam_view = _create_styled_button("🎥 Câmera [V]: Isométrica 3D", Color(0.55, 0.68, 0.95), Vector2(0, 34))
	btn_cam_view.pressed.connect(func() -> void: toggle_camera_view_requested.emit())
	vbox.add_child(btn_cam_view)

	btn_mirror = _create_styled_button("🪞 Espelho [X]: Desligado", Color(0.70, 0.55, 0.95), Vector2(0, 34))
	btn_mirror.pressed.connect(func() -> void: toggle_mirror_mode_requested.emit())
	vbox.add_child(btn_mirror)

	vbox.add_child(HSeparator.new())

	# 5. Ações Rápidas de Limpeza
	var lbl_clean: Label = Label.new()
	lbl_clean.text = "LIMPEZA RÁPIDA"
	lbl_clean.add_theme_font_size_override("font_size", 12)
	lbl_clean.add_theme_color_override("font_color", Color(0.85, 0.65, 0.65))
	vbox.add_child(lbl_clean)

	var btn_clear_obj: Button = _create_styled_button("🌿 Limpar Só Plantas/Pedras", Color(0.90, 0.55, 0.25), Vector2(0, 32))
	btn_clear_obj.pressed.connect(func() -> void: clear_objects_requested.emit())
	vbox.add_child(btn_clear_obj)

	var btn_clear_all: Button = _create_styled_button("🌊 Afundar Tudo (Mar Vazio)", Color(0.90, 0.30, 0.30), Vector2(0, 32))
	btn_clear_all.pressed.connect(func() -> void: clear_all_requested.emit())
	vbox.add_child(btn_clear_all)

func _build_right_panel() -> void:
	var right_panel: PanelContainer = PanelContainer.new()
	right_panel.set_anchors_preset(Control.PRESET_RIGHT_WIDE)
	right_panel.offset_left = -376
	right_panel.offset_top = 70
	right_panel.offset_right = -12
	right_panel.offset_bottom = -52
	right_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	right_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.09, 0.12, 0.16, 0.94), Color(0.25, 0.65, 0.85, 0.75)))
	editor_panels_root.add_child(right_panel)
	_interactive_panels.append(right_panel)

	var scroll_right: ScrollContainer = ScrollContainer.new()
	scroll_right.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll_right.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_panel.add_child(scroll_right)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 8)
	scroll_right.add_child(vbox)

	# 0. Banner de Contexto da Camada Ativa
	lbl_active_layer_banner = Label.new()
	lbl_active_layer_banner.text = "🏝️ PALETA: TERRENO DA ILHA (0.8m)"
	lbl_active_layer_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_active_layer_banner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl_active_layer_banner.clip_text = true
	lbl_active_layer_banner.add_theme_font_size_override("font_size", 12)
	lbl_active_layer_banner.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
	var banner_style: StyleBoxFlat = _make_panel_style(Color(0.12, 0.18, 0.22, 0.85), Color(0.3, 0.75, 0.5), 6)
	banner_style.content_margin_top = 5
	banner_style.content_margin_bottom = 5
	lbl_active_layer_banner.add_theme_stylebox_override("normal", banner_style)
	vbox.add_child(lbl_active_layer_banner)

	# 1. Seção de Terreno (0.80m)
	section_terrain = VBoxContainer.new()
	section_terrain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_terrain.add_theme_constant_override("separation", 6)
	vbox.add_child(section_terrain)

	var lbl_t_pal: Label = Label.new()
	lbl_t_pal.text = "🏝️ BLOCOS DE ILHA (TERRENO 0.8m)"
	lbl_t_pal.add_theme_font_size_override("font_size", 13)
	lbl_t_pal.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
	section_terrain.add_child(lbl_t_pal)

	var grid_terrain: GridContainer = GridContainer.new()
	grid_terrain.columns = 2
	grid_terrain.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_terrain.add_theme_constant_override("h_separation", 6)
	grid_terrain.add_theme_constant_override("v_separation", 6)
	section_terrain.add_child(grid_terrain)

	for item in TilePaletteDB.TERRAIN_ITEMS:
		var t_id: String = String(item["id"])
		var b: Button = _create_styled_button("%s %s" % [String(item["icon"]), String(item["name"])], item["color"] as Color, Vector2(0, 34))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.clip_text = true
		b.tooltip_text = String(item.get("desc", ""))
		b.pressed.connect(func() -> void: terrain_tile_selected.emit(t_id))
		grid_terrain.add_child(b)
		terrain_buttons[t_id] = b

	# 2. Seção de Grama Orgânica (0.20m)
	section_grass = VBoxContainer.new()
	section_grass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_grass.add_theme_constant_override("separation", 6)
	vbox.add_child(section_grass)

	var lbl_g_pal: Label = Label.new()
	lbl_g_pal.text = "🌿 GRAMA COMUM (1x HP - CAMPO 0.2m)"
	lbl_g_pal.add_theme_font_size_override("font_size", 13)
	lbl_g_pal.add_theme_color_override("font_color", Color(0.35, 0.90, 1.0))
	section_grass.add_child(lbl_g_pal)

	var grid_grass: GridContainer = GridContainer.new()
	grid_grass.columns = 2
	grid_grass.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_grass.add_theme_constant_override("h_separation", 6)
	grid_grass.add_theme_constant_override("v_separation", 6)
	section_grass.add_child(grid_grass)

	for item in TilePaletteDB.GRASS_ITEMS:
		var g_id: String = String(item["id"])
		var b: Button = _create_styled_button("%s %s" % [String(item["icon"]), String(item["name"])], item["color"] as Color, Vector2(0, 34))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.clip_text = true
		b.pressed.connect(func() -> void: grass_item_selected.emit(g_id))
		grid_grass.add_child(b)
		grass_buttons[g_id] = b

	# 3. Seção de Objetos no Tile (0.80m)
	section_objects = VBoxContainer.new()
	section_objects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_objects.add_theme_constant_override("separation", 6)
	vbox.add_child(section_objects)

	var lbl_o_pal: Label = Label.new()
	lbl_o_pal.text = "🪨 OBJETOS E PLANTAS NO TILE (0.8m)"
	lbl_o_pal.add_theme_font_size_override("font_size", 13)
	lbl_o_pal.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
	section_objects.add_child(lbl_o_pal)

	var grid_objects: GridContainer = GridContainer.new()
	grid_objects.columns = 2
	grid_objects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_objects.add_theme_constant_override("h_separation", 6)
	grid_objects.add_theme_constant_override("v_separation", 6)
	section_objects.add_child(grid_objects)

	for item in TilePaletteDB.OBJECT_ITEMS:
		var o_id: String = String(item["id"])
		var b: Button = _create_styled_button("%s %s" % [String(item["icon"]), String(item["name"])], item["color"] as Color, Vector2(0, 34))
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 12)
		b.clip_text = true
		b.pressed.connect(func() -> void: object_item_selected.emit(o_id))
		grid_objects.add_child(b)
		object_buttons[o_id] = b

	vbox.add_child(HSeparator.new())

	# 4. Seção de Metas & Métricas da Fase com Checkboxes e SpinBoxes
	_build_goals_metric_section(vbox)

func _build_goals_metric_section(parent_box: VBoxContainer) -> void:
	var lbl_meta_hdr: Label = Label.new()
	lbl_meta_hdr.text = "🎯 METAS DA FASE (OBJETIVOS)"
	lbl_meta_hdr.add_theme_font_size_override("font_size", 13)
	lbl_meta_hdr.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35))
	parent_box.add_child(lbl_meta_hdr)

	for gm in GOALS_CATALOG:
		var g_key: String = String(gm["key"])
		var g_name: String = String(gm["name"])
		var g_color: Color = gm["color"] as Color
		var g_unit: String = String(gm.get("unit", "tufos"))

		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.10, 0.14, 0.18, 0.9), g_color.darkened(0.55), 6))
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		parent_box.add_child(card)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.add_child(hbox)

		var chk: CheckBox = CheckBox.new()
		chk.text = g_name
		chk.button_pressed = false
		chk.focus_mode = Control.FOCUS_NONE
		chk.add_theme_font_size_override("font_size", 12)
		chk.add_theme_color_override("font_color", g_color)
		chk.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		chk.tooltip_text = "Ative para exigir a colheita desta espécie para vencer a fase"
		hbox.add_child(chk)
		_goal_checkboxes[g_key] = chk

		var lbl_total: Label = Label.new()
		lbl_total.text = "0 %s" % g_unit
		lbl_total.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_total.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_total.add_theme_font_size_override("font_size", 11)
		lbl_total.add_theme_color_override("font_color", Color(0.55, 0.65, 0.72))
		lbl_total.tooltip_text = "Total desta espécie presente no mapa atualmente"
		hbox.add_child(lbl_total)
		_goal_total_labels[g_key] = lbl_total

		var spin: SpinBox = SpinBox.new()
		spin.min_value = 1
		spin.max_value = 1
		spin.step = 1
		spin.value = 1
		spin.custom_minimum_size = Vector2(74, 28)
		spin.size_flags_horizontal = Control.SIZE_SHRINK_END
		spin.visible = false
		spin.tooltip_text = "Meta de colheita (deve ser entre 1 e o total presente na fase)"
		hbox.add_child(spin)
		_goal_spinboxes[g_key] = spin

		chk.toggled.connect(func(toggled_on: bool) -> void:
			var total: int = int(_last_detected_counts.get(g_key, 0))
			if toggled_on:
				if total <= 0:
					chk.set_pressed_no_signal(false)
					spin.visible = false
					return
				_goal_manually_unchecked.erase(g_key)
				spin.visible = true
				spin.min_value = 1
				spin.max_value = total
				if not _goal_manually_edited.get(g_key, false) or spin.value > total or spin.value < 1:
					spin.value = total
			else:
				_goal_manually_unchecked[g_key] = true
				spin.visible = false
		)

		spin.value_changed.connect(func(val: float) -> void:
			_goal_manually_edited[g_key] = true
			var total: int = int(_last_detected_counts.get(g_key, 0))
			if total > 0 and val > total:
				spin.set_value_no_signal(float(total))
			elif val < 1:
				spin.set_value_no_signal(1.0)
		)

		var le: LineEdit = spin.get_line_edit()
		if le != null:
			le.text_submitted.connect(func(_new_text: String) -> void:
				var total: int = int(_last_detected_counts.get(g_key, 0))
				if total > 0 and spin.value > total:
					spin.value = total
				elif spin.value < 1:
					spin.value = 1
			)

	# Métricas informativas de construção (rochas e solo)
	var card_world: PanelContainer = PanelContainer.new()
	card_world.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.11, 0.15, 0.85), Color(0.3, 0.45, 0.55, 0.6), 6))
	parent_box.add_child(card_world)

	lbl_world_metrics = Label.new()
	lbl_world_metrics.text = "🪨 Rochas: 0  |  🏝️ Blocos Ilha: 0"
	lbl_world_metrics.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_world_metrics.add_theme_font_size_override("font_size", 12)
	lbl_world_metrics.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
	card_world.add_child(lbl_world_metrics)

func _build_bottom_bar() -> void:
	var bot_panel: PanelContainer = PanelContainer.new()
	bot_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bot_panel.offset_left = 12
	bot_panel.offset_top = -46
	bot_panel.offset_right = -12
	bot_panel.offset_bottom = -8
	bot_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	bot_panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.11, 0.15, 0.92), Color(0.22, 0.55, 0.75, 0.7), 8))
	editor_panels_root.add_child(bot_panel)
	_interactive_panels.append(bot_panel)

	lbl_status = Label.new()
	lbl_status.text = "Célula: [0, 0]  |  Esq: Pintar  |  Dir: Borracha  |  Setas/Meio: Câmera  |  [S]: Escala (+/-)  |  [R]: Girar (±5°/±25°)  |  [X]: Espelho  |  [Alt+Esq/5]: Pipeta  |  [6/M]: Seleção  |  [F1]: Playtest"
	lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_status.add_theme_font_size_override("font_size", 13)
	lbl_status.add_theme_color_override("font_color", Color(0.85, 0.92, 0.98))
	bot_panel.add_child(lbl_status)

func _build_playtest_bar() -> void:
	playtest_bar = PanelContainer.new()
	playtest_bar.visible = false
	playtest_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	playtest_bar.offset_left = -360
	playtest_bar.offset_top = 14
	playtest_bar.offset_right = 360
	playtest_bar.offset_bottom = 68
	playtest_bar.mouse_filter = Control.MOUSE_FILTER_STOP
	playtest_bar.add_theme_stylebox_override("panel", _make_panel_style(Color(0.10, 0.16, 0.12, 0.95), Color(0.3, 0.95, 0.45), 12))
	add_child(playtest_bar)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 18)
	playtest_bar.add_child(hbox)

	lbl_playtest_info = Label.new()
	lbl_playtest_info.text = "🎮 MODO PLAYTEST ATIVO (Use WASD / Setas ou Mouse)"
	lbl_playtest_info.add_theme_font_size_override("font_size", 16)
	lbl_playtest_info.add_theme_color_override("font_color", Color(0.45, 1.0, 0.55))
	hbox.add_child(lbl_playtest_info)

	var btn_stop: Button = _create_styled_button("⏹ Voltar ao Editor [F1 / ESC]", Color(0.95, 0.35, 0.35), Vector2(210, 36))
	btn_stop.pressed.connect(func() -> void: playtest_toggled.emit())
	hbox.add_child(btn_stop)

func _build_toast_container() -> void:
	toast_container = VBoxContainer.new()
	toast_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast_container.offset_left = -250
	toast_container.offset_top = 78
	toast_container.offset_right = 250
	toast_container.offset_bottom = 260
	toast_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast_container.add_theme_constant_override("separation", 6)
	add_child(toast_container)

func show_toast(message: String, border_color: Color = Color(0.3, 0.9, 0.55)) -> void:
	if toast_container == null:
		return
	var panel: PanelContainer = PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.12, 0.16, 0.95), border_color, 8))

	var lbl: Label = Label.new()
	lbl.text = message
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 15)
	lbl.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(lbl)
	toast_container.add_child(panel)

	panel.modulate.a = 0.0
	var tw: Tween = create_tween()
	tw.tween_property(panel, "modulate:a", 1.0, 0.15)
	tw.tween_interval(2.2)
	tw.tween_property(panel, "modulate:a", 0.0, 0.3)
	tw.tween_callback(panel.queue_free)

func set_active_layer(layer_idx: int) -> void:
	if section_terrain != null:
		section_terrain.visible = (layer_idx == 0)
	if section_grass != null:
		section_grass.visible = (layer_idx == 1)
	if section_objects != null:
		section_objects.visible = (layer_idx == 2)
	if lbl_active_layer_banner != null:
		match layer_idx:
			0:
				lbl_active_layer_banner.text = "🏝️ PALETA: TERRENO DA ILHA (0.8m)"
				lbl_active_layer_banner.add_theme_color_override("font_color", Color(0.45, 0.95, 0.65))
			1:
				lbl_active_layer_banner.text = "🌿 PALETA: GRAMAS VETORIAIS (0.2m)"
				lbl_active_layer_banner.add_theme_color_override("font_color", Color(0.35, 0.90, 1.0))
			2:
				lbl_active_layer_banner.text = "🪨 PALETA: OBJETOS NO TILE (0.8m)"
				lbl_active_layer_banner.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))

func sync_state(
	active_layer: int,
	active_tool: int,
	active_shape: int,
	brush_size: int,
	rot_deg: int,
	active_terrain_id: String,
	active_grass_id: String,
	active_object_id: String,
	is_top_down: bool,
	adjust_mode: int = 0,
	mirror_mode: int = 0
) -> void:
	set_active_layer(active_layer)

	_set_button_selected(btn_layer_terrain, active_layer == 0, Color(0.28, 0.78, 0.45))
	_set_button_selected(btn_layer_grass, active_layer == 1, Color(0.30, 0.82, 0.95))
	_set_button_selected(btn_layer_objects, active_layer == 2, Color(0.85, 0.65, 0.35))

	var tool_colors: Dictionary = {
		0: Color(0.25, 0.88, 0.52),
		1: Color(0.95, 0.38, 0.38),
		2: Color(0.98, 0.78, 0.22),
		3: Color(0.95, 0.85, 0.25),
		4: Color(0.40, 0.85, 1.0),
		5: Color(0.88, 0.55, 0.98)
	}
	for t_id in tool_buttons:
		var tid: int = int(t_id)
		_set_button_selected(tool_buttons[tid] as Button, active_tool == tid, tool_colors[tid] as Color)

	for s_id in shape_buttons:
		var sid: int = int(s_id)
		_set_button_selected(shape_buttons[sid] as Button, active_shape == sid, Color(0.45, 0.75, 0.98))

	if corner_radius_container != null:
		corner_radius_container.visible = (active_shape == BrushPatterns.ShapeType.SQUARE)

	for item in TilePaletteDB.TERRAIN_ITEMS:
		var tid_str: String = String(item["id"])
		if terrain_buttons.has(tid_str):
			_set_button_selected(terrain_buttons[tid_str] as Button, active_layer == 0 and active_terrain_id == tid_str, item["color"] as Color)

	for item in TilePaletteDB.GRASS_ITEMS:
		var gid_str: String = String(item["id"])
		if grass_buttons.has(gid_str):
			_set_button_selected(grass_buttons[gid_str] as Button, active_layer == 1 and active_grass_id == gid_str, item["color"] as Color)

	for item in TilePaletteDB.OBJECT_ITEMS:
		var oid_str: String = String(item["id"])
		if object_buttons.has(oid_str):
			_set_button_selected(object_buttons[oid_str] as Button, active_layer == 2 and active_object_id == oid_str, item["color"] as Color)

	if lbl_brush_size != null:
		lbl_brush_size.text = "Escala [S]: %d" % brush_size
	if btn_rotate != null:
		if active_layer == 0:
			btn_rotate.text = "🔄 Girar [R]: %d° (±90°)" % rot_deg
		else:
			btn_rotate.text = "🔄 Girar [R]: %d° (±5° / Shift: ±25°)" % rot_deg

	if adjust_mode == 1: # SCALE ativo (padrão)
		if btn_sz_minus != null:
			btn_sz_minus.text = "➖ ["
		if btn_sz_plus != null:
			btn_sz_plus.text = "➕ ]"
		if btn_rot_left != null:
			btn_rot_left.text = "◀"
		if btn_rot_right != null:
			btn_rot_right.text = "▶"
	else: # ROTATION ativo ([R] pressionado)
		if btn_sz_minus != null:
			btn_sz_minus.text = "➖"
		if btn_sz_plus != null:
			btn_sz_plus.text = "➕"
		if btn_rot_left != null:
			btn_rot_left.text = "◀ ["
		if btn_rot_right != null:
			btn_rot_right.text = "] ▶"

	if panel_scale_box != null:
		var is_scale: bool = (adjust_mode == 1)
		var border_col: Color = Color(0.25, 0.95, 0.5, 0.9) if is_scale else Color(0.2, 0.35, 0.5, 0.4)
		panel_scale_box.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.11, 0.16, 0.8), border_col, 8))

	if panel_rotate_box != null:
		var is_rot: bool = (adjust_mode == 0)
		var border_col: Color = Color(0.25, 0.95, 0.5, 0.9) if is_rot else Color(0.2, 0.35, 0.5, 0.4)
		panel_rotate_box.add_theme_stylebox_override("panel", _make_panel_style(Color(0.08, 0.11, 0.16, 0.8), border_col, 8))

	if btn_cam_view != null:
		btn_cam_view.text = "🎥 Câmera [V]: Top-Down Ortogonal" if is_top_down else "🎥 Câmera [V]: Isométrica 3D"

	if btn_mirror != null:
		match mirror_mode:
			0:
				btn_mirror.text = "🪞 Espelho [X]: Desligado"
				_set_button_selected(btn_mirror, false, Color(0.70, 0.55, 0.95))
			1:
				btn_mirror.text = "🪞 Espelho [X]: Horizontal (X)"
				_set_button_selected(btn_mirror, true, Color(0.35, 0.95, 0.75))
			2:
				btn_mirror.text = "🪞 Espelho [X]: Vertical (Z)"
				_set_button_selected(btn_mirror, true, Color(0.35, 0.95, 0.75))
			3:
				btn_mirror.text = "🪞 Espelho [X]: Quádruplo (X+Z)"
				_set_button_selected(btn_mirror, true, Color(0.95, 0.85, 0.35))

func update_level_header(level_id: int, width: int, height: int, time_limit: float, force_time_sync: bool = false) -> void:
	if spin_level != null:
		spin_level.set_value_no_signal(float(level_id))
	if spin_width != null:
		spin_width.set_value_no_signal(float(width))
	if spin_height != null:
		spin_height.set_value_no_signal(float(height))
	if spin_time != null:
		var le: LineEdit = spin_time.get_line_edit()
		if force_time_sync or le == null or not le.has_focus():
			if force_time_sync and le != null:
				le.release_focus()
			spin_time.set_value_no_signal(time_limit)
			if le != null and (force_time_sync or not le.has_focus()):
				le.text = str(int(time_limit)) if is_equal_approx(time_limit, roundf(time_limit)) else str(time_limit)

func set_level_time_limit(new_time: float) -> void:
	if spin_time != null:
		var le: LineEdit = spin_time.get_line_edit()
		if le != null:
			le.release_focus()
			le.text = str(int(new_time)) if is_equal_approx(new_time, roundf(new_time)) else str(new_time)
		spin_time.set_value_no_signal(new_time)

func get_configured_time_limit() -> float:
	if spin_time != null:
		var le: LineEdit = spin_time.get_line_edit()
		if le != null and le.has_focus() and not le.text.is_empty():
			if le.text.is_valid_float():
				return clampf(float(le.text), float(spin_time.min_value), float(spin_time.max_value))
		return float(spin_time.value)
	return 90.0

func update_goals_summary(
	terrain_count: int,
	object_grid: Dictionary,
	veg_field: RefCounted = null,
	vector_field: RefCounted = null
) -> void:
	var grass_by_type: Dictionary = {}
	var flower_by_type: Dictionary = {}
	for gm in GOALS_CATALOG:
		var k_str: String = String(gm["key"])
		if k_str.begins_with("grass_"):
			grass_by_type[k_str] = 0
		elif k_str.begins_with("flower"):
			flower_by_type[k_str] = 0
	var wheat_tufts: int = 0
	var rock_c: int = 0

	if vector_field != null and vector_field.has_method("sample_all_tufts"):
		var tufts: Array = vector_field.call("sample_all_tufts") as Array
		for item: Variant in tufts:
			if item is Dictionary:
				var td: Dictionary = item as Dictionary
				var t_type: String = String(td.get("type", "grass_green"))
				if t_type == "wheat":
					wheat_tufts += 1
				elif flower_by_type.has(t_type):
					flower_by_type[t_type] = int(flower_by_type[t_type]) + 1
				elif t_type.begins_with("flower"):
					flower_by_type["flower"] = int(flower_by_type.get("flower", 0)) + 1
				elif grass_by_type.has(t_type):
					grass_by_type[t_type] = int(grass_by_type[t_type]) + 1
				else:
					grass_by_type["grass_green"] = int(grass_by_type.get("grass_green", 0)) + 1
	elif veg_field != null:
		var cols: int = int(veg_field.get("cols"))
		var rows: int = int(veg_field.get("rows"))
		for r: int in range(rows):
			for c: int in range(cols):
				var tid: int = int(veg_field.call("get_cell", c, r))
				if tid >= 1 and tid <= 7:
					grass_by_type["grass_green"] = int(grass_by_type.get("grass_green", 0)) + 1
				elif tid == 8:
					wheat_tufts += 1

	for k: Variant in object_grid:
		var entry: Dictionary = object_grid[k] as Dictionary
		var t: String = String(entry.get("type", ""))
		if flower_by_type.has(t):
			flower_by_type[t] = int(flower_by_type[t]) + 1
		elif t.begins_with("flower"):
			flower_by_type["flower"] = int(flower_by_type.get("flower", 0)) + 1
		elif t == "wheat":
			wheat_tufts += 1
		elif t == "rock":
			rock_c += 1

	for gm in GOALS_CATALOG:
		var g_key: String = String(gm["key"])
		var g_unit: String = String(gm.get("unit", "tufos"))
		var total_count: int = 0
		if g_key.begins_with("grass_"):
			total_count = int(grass_by_type.get(g_key, 0))
		elif g_key == "wheat":
			total_count = wheat_tufts
		elif flower_by_type.has(g_key):
			total_count = int(flower_by_type.get(g_key, 0))

		_last_detected_counts[g_key] = total_count

		if _goal_total_labels.has(g_key) and _goal_total_labels[g_key] != null:
			var lbl: Label = _goal_total_labels[g_key] as Label
			if total_count > 0:
				lbl.text = "%d %s" % [total_count, g_unit]
				lbl.add_theme_color_override("font_color", Color(0.75, 0.85, 0.95))
			else:
				lbl.text = "0 %s" % g_unit
				lbl.add_theme_color_override("font_color", Color(0.45, 0.50, 0.55))

		var chk: CheckBox = _goal_checkboxes.get(g_key, null) as CheckBox
		var spin: SpinBox = _goal_spinboxes.get(g_key, null) as SpinBox

		if chk != null:
			if total_count <= 0:
				chk.disabled = true
				if chk.button_pressed:
					chk.set_pressed_no_signal(false)
				_goal_manually_unchecked.erase(g_key)
			else:
				chk.disabled = false
				# Regra canônica: se há plantas no mapa e não foi desmarcado manualmente, fica ativo por padrão
				if not _goal_manually_unchecked.get(g_key, false) and not chk.button_pressed:
					chk.set_pressed_no_signal(true)

		if spin != null:
			if total_count > 0:
				spin.min_value = 1
				spin.max_value = total_count
				if not _goal_manually_edited.get(g_key, false):
					spin.set_value_no_signal(float(total_count))
				elif spin.value > total_count:
					spin.set_value_no_signal(float(total_count))
				elif spin.value < 1:
					spin.set_value_no_signal(1.0)
			else:
				spin.min_value = 1
				spin.max_value = 1
				spin.set_value_no_signal(1.0)
				_goal_manually_edited.erase(g_key)

			if chk != null:
				spin.visible = chk.button_pressed and total_count > 0

	if lbl_world_metrics != null:
		lbl_world_metrics.text = "🪨 Rochas: %d  |  🏝️ Blocos Ilha: %d" % [rock_c, terrain_count]

func get_configured_goals() -> Dictionary:
	var res: Dictionary = {}
	for gm in GOALS_CATALOG:
		var k: String = String(gm["key"])
		var chk: CheckBox = _goal_checkboxes.get(k, null) as CheckBox
		var spin: SpinBox = _goal_spinboxes.get(k, null) as SpinBox
		var total: int = int(_last_detected_counts.get(k, 0))
		if chk != null and chk.button_pressed and spin != null and total > 0:
			res[k] = clampi(int(spin.value), 1, total)
	return res

func set_configured_goals(goals: Dictionary) -> void:
	_goal_manually_edited.clear()
	_goal_manually_unchecked.clear()
	var has_saved_goals: bool = not goals.is_empty()
	for gm in GOALS_CATALOG:
		var k: String = String(gm["key"])
		var chk: CheckBox = _goal_checkboxes.get(k, null) as CheckBox
		var spin: SpinBox = _goal_spinboxes.get(k, null) as SpinBox
		if chk == null or spin == null:
			continue
		var total: int = int(_last_detected_counts.get(k, 0))
		var is_active: bool = false
		var goal_val: int = total

		if has_saved_goals:
			if goals.has(k):
				is_active = true
				goal_val = int(goals[k])
			elif k == "grass_green" and goals.has("grass"):
				is_active = true
				goal_val = int(goals["grass"])
			else:
				if total > 0:
					_goal_manually_unchecked[k] = true
		else:
			if total > 0:
				is_active = true
				goal_val = total

		if is_active and total > 0:
			chk.set_pressed_no_signal(true)
			spin.visible = true
			spin.min_value = 1
			spin.max_value = total
			spin.set_value_no_signal(float(clampi(goal_val, 1, total)))
			if has_saved_goals:
				_goal_manually_edited[k] = true
		else:
			chk.set_pressed_no_signal(false)
			spin.visible = false
			spin.min_value = 1
			spin.max_value = maxi(1, total)
			spin.set_value_no_signal(float(maxi(1, total)))

func update_status_bar(cell: Vector2i, in_bounds: bool, world_pos: Vector3) -> void:
	if lbl_status == null:
		return
	var cell_str: String = "[%d, %d]" % [cell.x, cell.y] if in_bounds else "[Fora da Grade]"
	lbl_status.text = "Célula: %s  |  Pos: (%.1f, %.1f)  |  Esq: Pintar  |  Dir: Borracha  |  Setas/Meio: Câmera  |  [S]: Escala (+/-)  |  [R]: Girar (±5°/±25°)  |  [X]: Espelho  |  [F1]: Playtest" % [
		cell_str, world_pos.x, world_pos.z
	]

func set_playtest_mode(active: bool) -> void:
	if editor_panels_root != null:
		editor_panels_root.visible = not active
	if playtest_bar != null:
		playtest_bar.visible = active

func update_playtest_hud(time_left: float, goals: Dictionary) -> void:
	if lbl_playtest_info == null:
		return
	var mins: int = int(time_left / 60.0)
	var secs: int = int(time_left) % 60
	var parts: PackedStringArray = PackedStringArray()
	for k in goals:
		var g: Dictionary = goals[k] as Dictionary
		var rem: int = maxi(0, int(g.get("target", 0)) - int(g.get("current", 0)))
		var k_str: String = String(k)
		var icon: String = "🌿"
		if k_str == "wheat":
			icon = "🌾"
		elif k_str == "flower_rose":
			icon = "🌹"
		elif k_str == "flower_daisy":
			icon = "🌼"
		elif k_str == "flower_sunflower":
			icon = "🌻"
		elif k_str == "flower_bell":
			icon = "🔔"
		elif k_str == "flower_corolla":
			icon = "🏵️"
		elif k_str == "flower_tulip":
			icon = "🌷"
		elif k_str == "flower_bed":
			icon = "🪻"
		elif k_str.begins_with("flower"):
			icon = "🌸"
		elif k_str == "grass_yellow":
			icon = "🌼"
		elif k_str == "grass_blue":
			icon = "💠"
		elif k_str == "grass_purple":
			icon = "🔮"
		elif k_str == "grass_white":
			icon = "🤍"
		elif k_str == "grass_red":
			icon = "❤️"
		elif k_str == "grass_black":
			icon = "🖤"
		parts.append("%s %d" % [icon, rem])
	var goals_str: String = "  ".join(parts) if not parts.is_empty() else "Livre"
	lbl_playtest_info.text = "🎮 PLAYTEST — ⏱️ %d:%02d  |  Metas: %s  |  (WASD / Setas / Mouse)" % [mins, secs, goals_str]
