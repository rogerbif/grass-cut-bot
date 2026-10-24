extends Control

const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")
const BrushPatterns = preload("res://scripts/editor/brush_patterns.gd")

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
signal brush_size_changed(new_size: int)
signal rotate_requested()
signal toggle_camera_view_requested()

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
var terrain_buttons: Dictionary = {}
var grass_buttons: Dictionary = {}
var object_buttons: Dictionary = {}

var lbl_brush_size: Label
var btn_rotate: Button
var btn_cam_view: Button
var lbl_status: Label

var lbl_active_layer_banner: Label
var _goal_checkboxes: Dictionary = {}
var _goal_spinboxes: Dictionary = {}
var _goal_total_labels: Dictionary = {}
var _goal_manually_edited: Dictionary = { "grass": false, "wheat": false, "flower": false }
var _last_detected_counts: Dictionary = { "grass": 0, "wheat": 0, "flower": 0 }
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
	spin_width.max_value = 36
	spin_width.step = 1
	spin_width.value = 12
	spin_width.tooltip_text = "Largura da Grade (colunas de 0.8m)"
	spin_width.custom_minimum_size = Vector2(68, 32)
	hbox.add_child(spin_width)

	var lbl_x: Label = Label.new()
	lbl_x.text = "x"
	hbox.add_child(lbl_x)

	spin_height = SpinBox.new()
	spin_height.min_value = 4
	spin_height.max_value = 36
	spin_height.step = 1
	spin_height.value = 8
	spin_height.tooltip_text = "Altura da Grade (linhas de 0.8m)"
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

	# 4. Tamanho do Pincel e Rotação
	var hbox_size: HBoxContainer = HBoxContainer.new()
	hbox_size.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox_size.add_theme_constant_override("separation", 8)
	vbox.add_child(hbox_size)

	var btn_sz_minus: Button = _create_styled_button("➖ [", Color(0.5, 0.7, 0.9), Vector2(56, 32))
	btn_sz_minus.pressed.connect(func() -> void: brush_size_changed.emit(-1))
	hbox_size.add_child(btn_sz_minus)

	lbl_brush_size = Label.new()
	lbl_brush_size.text = "Escala: 1"
	lbl_brush_size.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl_brush_size.custom_minimum_size = Vector2(95, 28)
	hbox_size.add_child(lbl_brush_size)

	var btn_sz_plus: Button = _create_styled_button("➕ ]", Color(0.5, 0.7, 0.9), Vector2(56, 32))
	btn_sz_plus.pressed.connect(func() -> void: brush_size_changed.emit(1))
	hbox_size.add_child(btn_sz_plus)

	btn_rotate = _create_styled_button("🔄 Girar Tile [R]: 0°", Color(0.35, 0.85, 0.75), Vector2(0, 34))
	btn_rotate.pressed.connect(func() -> void: rotate_requested.emit())
	vbox.add_child(btn_rotate)

	btn_cam_view = _create_styled_button("🎥 Câmera [V]: Isométrica 3D", Color(0.55, 0.68, 0.95), Vector2(0, 34))
	btn_cam_view.pressed.connect(func() -> void: toggle_camera_view_requested.emit())
	vbox.add_child(btn_cam_view)

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
	right_panel.offset_left = -326
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
	lbl_active_layer_banner.add_theme_font_size_override("font_size", 13)
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
	grid_terrain.add_theme_constant_override("h_separation", 6)
	grid_terrain.add_theme_constant_override("v_separation", 6)
	section_terrain.add_child(grid_terrain)

	for item in TilePaletteDB.TERRAIN_ITEMS:
		var t_id: String = String(item["id"])
		var b: Button = _create_styled_button("%s %s" % [String(item["icon"]), String(item["name"])], item["color"] as Color, Vector2(144, 34))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
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
	grid_grass.add_theme_constant_override("h_separation", 6)
	grid_grass.add_theme_constant_override("v_separation", 6)
	section_grass.add_child(grid_grass)

	for item in TilePaletteDB.GRASS_ITEMS:
		var g_id: String = String(item["id"])
		if g_id == "wheat":
			continue
		var b: Button = _create_styled_button("%s %s" % [String(item["icon"]), String(item["name"])], item["color"] as Color, Vector2(144, 34))
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.add_theme_font_size_override("font_size", 13)
		b.pressed.connect(func() -> void: grass_item_selected.emit(g_id))
		grid_grass.add_child(b)
		grass_buttons[g_id] = b

	section_grass.add_child(HSeparator.new())

	var lbl_w_pal: Label = Label.new()
	lbl_w_pal.text = "🌾 VEGETAÇÃO DE META (2x HP - 3 MOEDAS)"
	lbl_w_pal.add_theme_font_size_override("font_size", 13)
	lbl_w_pal.add_theme_color_override("font_color", Color(1.0, 0.82, 0.28))
	section_grass.add_child(lbl_w_pal)

	var wheat_item: Variant = TilePaletteDB.get_item_by_id("wheat")
	if wheat_item != null and wheat_item is Dictionary:
		var w_dict: Dictionary = wheat_item as Dictionary
		var b_wheat: Button = _create_styled_button(
			"%s %s" % [String(w_dict["icon"]), String(w_dict["name"])],
			w_dict["color"] as Color,
			Vector2(294, 36)
		)
		b_wheat.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b_wheat.add_theme_font_size_override("font_size", 13)
		b_wheat.pressed.connect(func() -> void: grass_item_selected.emit("wheat"))
		section_grass.add_child(b_wheat)
		grass_buttons["wheat"] = b_wheat

	var btn_convert: Button = _create_styled_button(
		"🔄 Converter Grama Amarela ➔ Trigo",
		Color(0.85, 0.65, 0.25),
		Vector2(294, 32)
	)
	btn_convert.alignment = HORIZONTAL_ALIGNMENT_CENTER
	btn_convert.add_theme_font_size_override("font_size", 12)
	btn_convert.tooltip_text = "Converte polígonos de Grama Amarela no mapa em Trigo Maduro (para contagem de metas)"
	btn_convert.pressed.connect(func() -> void: convert_yellow_to_wheat_requested.emit())
	section_grass.add_child(btn_convert)

	# 3. Seção de Objetos no Tile (0.80m)
	section_objects = VBoxContainer.new()
	section_objects.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section_objects.add_theme_constant_override("separation", 6)
	vbox.add_child(section_objects)

	var lbl_o_pal: Label = Label.new()
	lbl_o_pal.text = "🪨 OBJETOS NO TILE (0.8m)"
	lbl_o_pal.add_theme_font_size_override("font_size", 13)
	lbl_o_pal.add_theme_color_override("font_color", Color(1.0, 0.75, 0.35))
	section_objects.add_child(lbl_o_pal)

	var grid_objects: GridContainer = GridContainer.new()
	grid_objects.columns = 3
	grid_objects.add_theme_constant_override("h_separation", 6)
	grid_objects.add_theme_constant_override("v_separation", 6)
	section_objects.add_child(grid_objects)

	for item in TilePaletteDB.OBJECT_ITEMS:
		var o_id: String = String(item["id"])
		var b: Button = _create_styled_button("%s %s" % [String(item["icon"]), String(item["name"])], item["color"] as Color, Vector2(94, 34))
		b.alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.add_theme_font_size_override("font_size", 12)
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

	var goals_meta: Array[Dictionary] = [
		{ "key": "grass", "name": "🌿 Grama", "color": Color(0.35, 0.90, 0.45) },
		{ "key": "wheat", "name": "🌾 Trigo", "color": Color(1.0, 0.82, 0.28) },
		{ "key": "flower", "name": "🌸 Flores", "color": Color(1.0, 0.50, 0.75) }
	]

	for gm in goals_meta:
		var g_key: String = String(gm["key"])
		var g_name: String = String(gm["name"])
		var g_color: Color = gm["color"] as Color

		var card: PanelContainer = PanelContainer.new()
		card.add_theme_stylebox_override("panel", _make_panel_style(Color(0.11, 0.15, 0.20, 0.9), g_color.darkened(0.5), 6))
		parent_box.add_child(card)

		var hbox: HBoxContainer = HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 6)
		card.add_child(hbox)

		var chk: CheckBox = CheckBox.new()
		chk.text = g_name
		chk.button_pressed = true
		chk.focus_mode = Control.FOCUS_NONE
		chk.add_theme_font_size_override("font_size", 13)
		chk.add_theme_color_override("font_color", g_color)
		chk.tooltip_text = "Marque se colher este item é obrigatório para vencer a fase"
		hbox.add_child(chk)
		_goal_checkboxes[g_key] = chk

		var lbl_slash: Label = Label.new()
		lbl_slash.text = "/ 0"
		lbl_slash.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl_slash.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		lbl_slash.add_theme_font_size_override("font_size", 12)
		lbl_slash.add_theme_color_override("font_color", Color(0.7, 0.8, 0.85))
		lbl_slash.tooltip_text = "Total deste item presente no mapa atualmente"
		hbox.add_child(lbl_slash)
		_goal_total_labels[g_key] = lbl_slash

		var spin: SpinBox = SpinBox.new()
		spin.min_value = 1
		spin.max_value = 9999
		spin.step = 1
		spin.value = 1
		spin.custom_minimum_size = Vector2(72, 30)
		spin.tooltip_text = "Quantidade necessária para bater a meta da fase"
		hbox.add_child(spin)
		_goal_spinboxes[g_key] = spin

		chk.toggled.connect(func(toggled_on: bool) -> void:
			spin.editable = toggled_on
			spin.modulate.a = 1.0 if toggled_on else 0.4
			if toggled_on and not _goal_manually_edited[g_key]:
				var detected: int = int(_last_detected_counts.get(g_key, 0))
				if detected > 0:
					spin.value = detected
		)

		spin.value_changed.connect(func(_val: float) -> void:
			_goal_manually_edited[g_key] = true
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
	lbl_status.text = "Célula: [0, 0]  |  Clique Esq: Pintar  |  Clique Dir: Borracha  |  WASD / Botão Meio: Mover Câmera  |  Scroll: Zoom  |  [R]: Girar  |  [F1]: Testar Fase"
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
	is_top_down: bool
) -> void:
	set_active_layer(active_layer)

	_set_button_selected(btn_layer_terrain, active_layer == 0, Color(0.28, 0.78, 0.45))
	_set_button_selected(btn_layer_grass, active_layer == 1, Color(0.30, 0.82, 0.95))
	_set_button_selected(btn_layer_objects, active_layer == 2, Color(0.85, 0.65, 0.35))

	var tool_colors: Dictionary = {
		0: Color(0.25, 0.88, 0.52),
		1: Color(0.95, 0.38, 0.38),
		2: Color(0.98, 0.78, 0.22),
		3: Color(0.95, 0.85, 0.25)
	}
	for t_id in tool_buttons:
		var tid: int = int(t_id)
		_set_button_selected(tool_buttons[tid] as Button, active_tool == tid, tool_colors[tid] as Color)

	for s_id in shape_buttons:
		var sid: int = int(s_id)
		_set_button_selected(shape_buttons[sid] as Button, active_shape == sid, Color(0.45, 0.75, 0.98))

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
		lbl_brush_size.text = "Escala: %d" % brush_size
	if btn_rotate != null:
		if active_layer == 0:
			btn_rotate.text = "🔄 Girar Tile [R]: %d° (+90°)" % rot_deg
		else:
			btn_rotate.text = "🔄 Girar Pincel [R]: %d° (+5°)" % rot_deg
	if btn_cam_view != null:
		btn_cam_view.text = "🎥 Câmera [V]: Top-Down Ortogonal" if is_top_down else "🎥 Câmera [V]: Isométrica 3D"

func update_level_header(level_id: int, width: int, height: int, time_limit: float) -> void:
	if spin_level != null:
		spin_level.set_value_no_signal(float(level_id))
	if spin_width != null:
		spin_width.set_value_no_signal(float(width))
	if spin_height != null:
		spin_height.set_value_no_signal(float(height))
	if spin_time != null:
		spin_time.set_value_no_signal(time_limit)

func update_goals_summary(
	terrain_count: int,
	object_grid: Dictionary,
	veg_field: RefCounted = null,
	vector_field: RefCounted = null
) -> void:
	var grass_tufts: int = 0
	var wheat_tufts: int = 0
	var flower_c: int = 0
	var rock_c: int = 0

	if vector_field != null and vector_field.has_method("sample_all_tufts"):
		var tufts: Array = vector_field.call("sample_all_tufts") as Array
		for item: Variant in tufts:
			if item is Dictionary:
				var td: Dictionary = item as Dictionary
				var t_type: String = String(td.get("type", "grass_green"))
				if t_type == "wheat":
					wheat_tufts += 1
				elif t_type == "flower":
					flower_c += 1
				else:
					grass_tufts += 1
	elif veg_field != null:
		var cols: int = int(veg_field.get("cols"))
		var rows: int = int(veg_field.get("rows"))
		for r: int in range(rows):
			for c: int in range(cols):
				var tid: int = int(veg_field.call("get_cell", c, r))
				if tid >= 1 and tid <= 7:
					grass_tufts += 1
				elif tid == 8:
					wheat_tufts += 1

	for k: Variant in object_grid:
		var entry: Dictionary = object_grid[k] as Dictionary
		var t: String = String(entry.get("type", ""))
		if t == "flower":
			flower_c += 1
		elif t == "wheat":
			wheat_tufts += 1
		elif t == "rock":
			rock_c += 1

	_last_detected_counts["grass"] = grass_tufts
	_last_detected_counts["wheat"] = wheat_tufts
	_last_detected_counts["flower"] = flower_c

	var counts_map: Dictionary = {
		"grass": grass_tufts,
		"wheat": wheat_tufts,
		"flower": flower_c
	}

	for k: String in ["grass", "wheat", "flower"]:
		var cnt: int = int(counts_map[k])
		if _goal_total_labels.has(k) and _goal_total_labels[k] != null:
			(_goal_total_labels[k] as Label).text = "/ %d" % cnt
		if _goal_spinboxes.has(k) and _goal_spinboxes[k] != null:
			var spin: SpinBox = _goal_spinboxes[k] as SpinBox
			if not _goal_manually_edited.get(k, false):
				if cnt > 0:
					spin.set_value_no_signal(float(cnt))
				else:
					spin.set_value_no_signal(1.0)

	if lbl_world_metrics != null:
		lbl_world_metrics.text = "🪨 Rochas: %d  |  🏝️ Blocos Ilha: %d" % [rock_c, terrain_count]

func get_configured_goals() -> Dictionary:
	var res: Dictionary = {}
	for k: String in ["grass", "wheat", "flower"]:
		var chk: CheckBox = _goal_checkboxes.get(k, null) as CheckBox
		var spin: SpinBox = _goal_spinboxes.get(k, null) as SpinBox
		if chk != null and chk.button_pressed and spin != null:
			res[k] = int(spin.value)
	return res

func set_configured_goals(goals: Dictionary) -> void:
	if not goals.is_empty():
		for k: String in ["grass", "wheat", "flower"]:
			var chk: CheckBox = _goal_checkboxes.get(k, null) as CheckBox
			var spin: SpinBox = _goal_spinboxes.get(k, null) as SpinBox
			if chk == null or spin == null:
				continue
			if goals.has(k):
				chk.set_pressed_no_signal(true)
				spin.editable = true
				spin.modulate.a = 1.0
				spin.set_value_no_signal(float(goals[k]))
				_goal_manually_edited[k] = true
			else:
				chk.set_pressed_no_signal(false)
				spin.editable = false
				spin.modulate.a = 0.4
				_goal_manually_edited[k] = false
	else:
		for k: String in ["grass", "wheat", "flower"]:
			_goal_manually_edited[k] = false
			var chk: CheckBox = _goal_checkboxes.get(k, null) as CheckBox
			var spin: SpinBox = _goal_spinboxes.get(k, null) as SpinBox
			var detected: int = int(_last_detected_counts.get(k, 0))
			if chk != null:
				chk.set_pressed_no_signal(detected > 0)
			if spin != null:
				spin.editable = (detected > 0)
				spin.modulate.a = 1.0 if (detected > 0) else 0.4
				spin.set_value_no_signal(float(maxi(1, detected)))

func update_status_bar(cell: Vector2i, in_bounds: bool, world_pos: Vector3) -> void:
	if lbl_status == null:
		return
	var cell_str: String = "[%d, %d]" % [cell.x, cell.y] if in_bounds else "[Fora da Grade]"
	lbl_status.text = "Célula: %s  |  Pos: (%.1f, %.1f)  |  Esq: Pintar  |  Dir: Borracha  |  WASD/Meio: Câmera  |  Scroll: Zoom  |  [R]: Girar  |  [F1]: Playtest" % [
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
		var icon: String = "🌿"
		if String(k) == "wheat":
			icon = "🌾"
		elif String(k) == "flower":
			icon = "🌸"
		parts.append("%s %d" % [icon, rem])
	var goals_str: String = "  ".join(parts) if not parts.is_empty() else "Livre"
	lbl_playtest_info.text = "🎮 PLAYTEST — ⏱️ %d:%02d  |  Metas: %s  |  (WASD / Setas / Mouse)" % [mins, secs, goals_str]
