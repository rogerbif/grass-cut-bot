class_name DefeatModal
extends Control

## Tela de Derrota Flutuante Cyber-Mecha (Tempo Esgotado & Robô Quebrado).
## Mantém o centro da tela 100% livre para exibir o close-up 3D do robô cabisbaixo soltando fumaça,
## com 3 placas superiores (Título de Alerta, Progresso do Corte e Metas X/Y) e barra inferior
## simétrica (MENU, PEGAR MAIS TEMPO / CONSERTAR ROBÔ e botão heroico verde REINICIAR).
## Roda com process_mode = PROCESS_MODE_ALWAYS e constrói tudo programaticamente (Guardrail 13).

signal retry_requested
signal extra_time_requested
signal repair_robot_requested
signal menu_requested

const EXTRA_TIME_SECONDS: float = 15.0

const TEX_BANNER_TITLE: Texture2D = preload("res://assets/ui/defeat/banner_defeat_title.svg")
const TEX_BANNER_PROGRESS: Texture2D = preload("res://assets/ui/defeat/banner_defeat_progress.svg")
const TEX_BANNER_GOALS: Texture2D = preload("res://assets/ui/defeat/banner_defeat_goals.svg")

const TEX_BTN_MENU_N: Texture2D = preload("res://assets/ui/victory/btn_menu_secondary.svg")
const TEX_BTN_MENU_P: Texture2D = preload("res://assets/ui/victory/btn_menu_secondary_pressed.svg")
const TEX_BTN_EXTRA_N: Texture2D = preload("res://assets/ui/victory/btn_repeat_secondary.svg")
const TEX_BTN_EXTRA_P: Texture2D = preload("res://assets/ui/victory/btn_repeat_secondary_pressed.svg")
const TEX_BTN_RETRY_N: Texture2D = preload("res://assets/ui/victory/btn_next_level.svg")
const TEX_BTN_RETRY_P: Texture2D = preload("res://assets/ui/victory/btn_next_level_pressed.svg")

const TEX_ICON_STOPWATCH: Texture2D = preload("res://assets/ui/defeat/icon_stopwatch_red.svg")
const TEX_ICON_ROBOT_BROKEN: Texture2D = preload("res://assets/ui/defeat/icon_robot_broken_red.svg")
const TEX_ICON_ALERT: Texture2D = preload("res://assets/ui/defeat/icon_alert_triangle_red.svg")
const TEX_ICON_TV: Texture2D = preload("res://assets/ui/defeat/icon_tv_play_cyan.svg")
const TEX_ICON_HOME: Texture2D = preload("res://assets/ui/victory/icon_home_cyan.svg")
const TEX_ICON_REFRESH_DARK: Texture2D = preload("res://assets/ui/defeat/icon_refresh_dark.svg")
const TEX_ICON_HEART: Texture2D = preload("res://assets/icons/icon_heart.svg")

const COL_WHITE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COL_TITLE_RED: Color = Color(1.0, 0.31, 0.34, 1.0)
const COL_PERCENT: Color = Color(1.0, 0.85, 0.28, 1.0)
const COL_DARK_PETROL: Color = Color(0.027, 0.11, 0.16, 1.0)
const COL_GOAL_DONE: Color = Color(0.35, 1.0, 0.58, 1.0)
const COL_LIFE_LOST: Color = Color(1.0, 0.45, 0.52, 1.0)

var _font: SystemFont = null
var _touch_Catcher: Control = null
var _top_cluster: VBoxContainer = null
var _bottom_bar: VBoxContainer = null

var _left_title_icon: TextureRect = null
var _title_lbl: Label = null
var _cut_prog_lbl: Label = null
var _percent_lbl: Label = null
var _progress_fill: Panel = null
var _progress_track: Panel = null
var _goals_hbox: HBoxContainer = null
var _life_lost_lbl: Label = null

var _menu_btn: TextureButton = null
var _menu_lbl: Label = null
var _extra_btn: TextureButton = null
var _extra_lbl: Label = null
var _retry_btn: TextureButton = null
var _retry_lbl: Label = null

var _current_reason: String = "time_up"
var _current_progress: float = 0.0
var _anim_tween: Tween = null
var _is_closing: bool = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_retranslate_ui()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe UI", "Arial Black", "Montserrat", "sans-serif"])
	_font.font_weight = 900

	_build_ui()


## Abre a tela de derrota flutuante com suporte a "time_up" e "robot_broken".
func open(reason_or_progress: Variant = "time_up", progress_or_goals: Variant = 0.0, goals_or_extend: Variant = [], can_extend_opt: bool = true) -> void:
	visible = true
	_is_closing = false

	# Compatibilidade flexível de assinatura:
	# open(reason: String, progress: float, goals_summary: Array, can_extend: bool)
	# ou legado open(progress: float, remaining_goals: Dictionary, can_extend: bool)
	var goals_data: Variant = []
	var can_extend: bool = true

	if typeof(reason_or_progress) == TYPE_STRING:
		_current_reason = String(reason_or_progress)
		_current_progress = clampf(float(progress_or_goals), 0.0, 1.0)
		goals_data = goals_or_extend
		can_extend = can_extend_opt
	else:
		_current_reason = "time_up"
		_current_progress = clampf(float(reason_or_progress), 0.0, 1.0)
		goals_data = progress_or_goals
		can_extend = bool(goals_or_extend)

	_update_reason_visuals()

	var pct: int = roundi(_current_progress * 100.0)
	if _percent_lbl != null:
		_percent_lbl.text = "%d%%" % pct
	_update_progress_bar_width(_current_progress)

	if _extra_btn != null:
		_extra_btn.visible = can_extend

	_populate_goals(goals_data)
	_update_life_lost_badge()

	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()

	_top_cluster.modulate.a = 0.0
	_top_cluster.offset_top = 12.0
	_top_cluster.offset_bottom = 352.0

	_bottom_bar.modulate.a = 0.0
	_bottom_bar.offset_top = -110.0
	_bottom_bar.offset_bottom = 86.0

	_anim_tween = create_tween()
	_anim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_anim_tween.set_parallel(true)
	_anim_tween.tween_property(_top_cluster, "modulate:a", 1.0, 0.24)
	_anim_tween.tween_property(_top_cluster, "offset_top", 54.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(_top_cluster, "offset_bottom", 394.0, 0.38).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	_anim_tween.tween_property(_bottom_bar, "modulate:a", 1.0, 0.24)
	_anim_tween.tween_property(_bottom_bar, "offset_top", -228.0, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_anim_tween.tween_property(_bottom_bar, "offset_bottom", -32.0, 0.42).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var vib_on: bool = true
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr != null and save_mgr.has_method("get_setting"):
		vib_on = bool(save_mgr.call("get_setting", "vib_enabled", true))
	if vib_on and (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		Input.vibrate_handheld(40)


func close() -> void:
	if _is_closing or not visible:
		return
	_is_closing = true

	if _anim_tween != null and _anim_tween.is_valid():
		_anim_tween.kill()

	_anim_tween = create_tween()
	_anim_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_anim_tween.set_parallel(true)
	_anim_tween.tween_property(_top_cluster, "modulate:a", 0.0, 0.15)
	_anim_tween.tween_property(_bottom_bar, "modulate:a", 0.0, 0.15)
	_anim_tween.chain().tween_callback(func() -> void:
		visible = false
		_is_closing = false
	)


func _build_ui() -> void:
	# Camada transparente que bloqueia cliques no cenário durante a tela de derrota,
	# mantendo o robô 3D totalmente visível e sem escurecimento opaco.
	_touch_Catcher = Control.new()
	_touch_Catcher.set_anchors_preset(Control.PRESET_FULL_RECT)
	_touch_Catcher.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_touch_Catcher)

	# ==========================================================================
	# 1. CLUSTER SUPERIOR FLUTUANTE (3 PLACAS CYBER-MECHA)
	# ==========================================================================
	_top_cluster = VBoxContainer.new()
	_top_cluster.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_top_cluster.offset_left = -310.0
	_top_cluster.offset_top = 54.0
	_top_cluster.offset_right = 310.0
	_top_cluster.offset_bottom = 394.0
	_top_cluster.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_top_cluster.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_cluster.alignment = BoxContainer.ALIGNMENT_BEGIN
	_top_cluster.add_theme_constant_override("separation", 12)
	add_child(_top_cluster)

	# --- Placa 1: Banner de Título (TEMPO ESGOTADO! / ROBÔ QUEBRADO!) ---
	var title_banner: Control = Control.new()
	title_banner.custom_minimum_size = Vector2(600.0, 90.0)
	title_banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	title_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_cluster.add_child(title_banner)

	var title_bg: TextureRect = TextureRect.new()
	title_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_bg.texture = TEX_BANNER_TITLE
	title_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title_bg.stretch_mode = TextureRect.STRETCH_SCALE
	title_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_banner.add_child(title_bg)

	var title_hbox: HBoxContainer = HBoxContainer.new()
	title_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	title_hbox.add_theme_constant_override("separation", 14)
	title_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	title_banner.add_child(title_hbox)

	_left_title_icon = _make_icon(TEX_ICON_STOPWATCH, Vector2(52.0, 52.0))
	title_hbox.add_child(_left_title_icon)

	_title_lbl = _make_label(tr("HUD_DEFEAT_TITLE"), 29, COL_TITLE_RED)
	_title_lbl.add_theme_constant_override("outline_size", 8)
	_title_lbl.add_theme_color_override("font_outline_color", Color(0.08, 0.02, 0.05, 0.95))
	title_hbox.add_child(_title_lbl)

	title_hbox.add_child(_make_icon(TEX_ICON_ALERT, Vector2(36.0, 36.0)))

	# --- Placa 2: Progresso do Corte ---
	var prog_banner: Control = Control.new()
	prog_banner.custom_minimum_size = Vector2(612.0, 114.0)
	prog_banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	prog_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_cluster.add_child(prog_banner)

	var prog_bg: TextureRect = TextureRect.new()
	prog_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	prog_bg.texture = TEX_BANNER_PROGRESS
	prog_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	prog_bg.stretch_mode = TextureRect.STRETCH_SCALE
	prog_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prog_banner.add_child(prog_bg)

	var prog_vbox: VBoxContainer = VBoxContainer.new()
	prog_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	prog_vbox.offset_left = 74.0
	prog_vbox.offset_right = -74.0
	prog_vbox.offset_top = 24.0
	prog_vbox.offset_bottom = -22.0
	prog_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	prog_vbox.add_theme_constant_override("separation", 10)
	prog_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prog_banner.add_child(prog_vbox)

	var prog_header_hbox: HBoxContainer = HBoxContainer.new()
	prog_header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	prog_header_hbox.add_theme_constant_override("separation", 6)
	prog_header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prog_vbox.add_child(prog_header_hbox)

	_cut_prog_lbl = _make_label(tr("DEFEAT_CUT_PROGRESS").to_upper(), 18, COL_WHITE)
	prog_header_hbox.add_child(_cut_prog_lbl)

	_percent_lbl = _make_label("0%", 19, COL_PERCENT)
	prog_header_hbox.add_child(_percent_lbl)

	# Trilho arredondado da barra de progresso com partículas/pontos digitais
	_progress_track = Panel.new()
	_progress_track.custom_minimum_size = Vector2(464.0, 20.0)
	_progress_track.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_progress_track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var track_sb: StyleBoxFlat = StyleBoxFlat.new()
	track_sb.bg_color = Color(0.08, 0.11, 0.22, 0.95)
	track_sb.set_corner_radius_all(10)
	_progress_track.add_theme_stylebox_override("panel", track_sb)
	prog_vbox.add_child(_progress_track)

	# Pontos digitais decorativos no trilho (fiéis à imagem de referência)
	var dot_offsets: Array[Vector2] = [
		Vector2(180.0, 12.0), Vector2(212.0, 6.0), Vector2(220.0, 13.0),
		Vector2(268.0, 13.0), Vector2(315.0, 7.0), Vector2(338.0, 13.0),
		Vector2(350.0, 13.0), Vector2(396.0, 11.0)
	]
	for d_pos: Vector2 in dot_offsets:
		var dot: ColorRect = ColorRect.new()
		dot.size = Vector2(4.0, 3.0)
		dot.position = d_pos
		dot.color = Color(1.0, 0.28, 0.52, 0.65)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_progress_track.add_child(dot)

	_progress_fill = Panel.new()
	_progress_fill.position = Vector2.ZERO
	_progress_fill.size = Vector2(0.0, 20.0)
	_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill_sb: StyleBoxFlat = StyleBoxFlat.new()
	fill_sb.bg_color = Color(1.0, 0.30, 0.44, 1.0)
	fill_sb.set_corner_radius_all(10)
	_progress_fill.add_theme_stylebox_override("panel", fill_sb)
	_progress_track.add_child(_progress_fill)

	# --- Placa 3: Metas da Fase (54 / 60   88 / 100   55 / 70) ---
	var goals_banner: Control = Control.new()
	goals_banner.custom_minimum_size = Vector2(616.0, 74.0)
	goals_banner.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	goals_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_cluster.add_child(goals_banner)

	var goals_bg: TextureRect = TextureRect.new()
	goals_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	goals_bg.texture = TEX_BANNER_GOALS
	goals_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	goals_bg.stretch_mode = TextureRect.STRETCH_SCALE
	goals_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goals_banner.add_child(goals_bg)

	_goals_hbox = HBoxContainer.new()
	_goals_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	_goals_hbox.offset_top = 4.0
	_goals_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_goals_hbox.add_theme_constant_override("separation", 34)
	_goals_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	goals_banner.add_child(_goals_hbox)

	# --- Feedback de Vida Perdida (-1 ❤️) ---
	var life_hbox: HBoxContainer = HBoxContainer.new()
	life_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	life_hbox.add_theme_constant_override("separation", 8)
	life_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_top_cluster.add_child(life_hbox)

	life_hbox.add_child(_make_icon(TEX_ICON_HEART, Vector2(22.0, 22.0)))
	_life_lost_lbl = _make_label("-1", 17, COL_LIFE_LOST)
	_life_lost_lbl.add_theme_constant_override("outline_size", 6)
	_life_lost_lbl.add_theme_color_override("font_outline_color", Color(0.04, 0.06, 0.12, 0.95))
	life_hbox.add_child(_life_lost_lbl)

	# ==========================================================================
	# 2. BARRA INFERIOR DE AÇÕES (MENU | PEGAR MAIS TEMPO / CONSERTAR | REINICIAR)
	# ==========================================================================
	_bottom_bar = VBoxContainer.new()
	_bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_bottom_bar.offset_left = 36.0
	_bottom_bar.offset_top = -228.0
	_bottom_bar.offset_right = -36.0
	_bottom_bar.offset_bottom = -32.0
	_bottom_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_bottom_bar.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_bottom_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_bottom_bar.add_theme_constant_override("separation", 12)
	add_child(_bottom_bar)

	var secondary_hbox: HBoxContainer = HBoxContainer.new()
	secondary_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	secondary_hbox.add_theme_constant_override("separation", 20)
	_bottom_bar.add_child(secondary_hbox)

	# Botão Esquerdo: MENU
	_menu_btn = _make_secondary_button(TEX_BTN_MENU_N, TEX_BTN_MENU_P, TEX_ICON_HOME, tr("BTN_MENU").to_upper(), 21)
	_menu_lbl = _menu_btn.get_meta("label") as Label
	_menu_btn.pressed.connect(_on_menu_pressed)
	secondary_hbox.add_child(_menu_btn)

	# Botão Direito: PEGAR MAIS TEMPO / CONSERTAR ROBÔ
	_extra_btn = _make_secondary_button(TEX_BTN_EXTRA_N, TEX_BTN_EXTRA_P, TEX_ICON_TV, tr("DEFEAT_BTN_EXTRA_TIME").to_upper(), 18)
	_extra_lbl = _extra_btn.get_meta("label") as Label
	_extra_btn.pressed.connect(_on_extra_pressed)
	secondary_hbox.add_child(_extra_btn)

	# Botão Principal Inferior: REINICIAR ↻
	_retry_btn = TextureButton.new()
	_retry_btn.custom_minimum_size = Vector2(648.0, 106.0)
	_retry_btn.focus_mode = Control.FOCUS_NONE
	_retry_btn.texture_normal = TEX_BTN_RETRY_N
	_retry_btn.texture_pressed = TEX_BTN_RETRY_P
	_retry_btn.ignore_texture_size = true
	_retry_btn.stretch_mode = TextureButton.STRETCH_SCALE
	_retry_btn.pressed.connect(_on_retry_pressed)
	_bottom_bar.add_child(_retry_btn)

	var retry_box: HBoxContainer = HBoxContainer.new()
	retry_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	retry_box.offset_bottom = -8.0
	retry_box.alignment = BoxContainer.ALIGNMENT_CENTER
	retry_box.add_theme_constant_override("separation", 12)
	retry_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_retry_btn.add_child(retry_box)

	_retry_lbl = _make_label(tr("HUD_RETRY").to_upper(), 28, COL_DARK_PETROL)
	_retry_lbl.add_theme_color_override("font_shadow_color", Color(1.0, 1.0, 1.0, 0.25))
	retry_box.add_child(_retry_lbl)

	retry_box.add_child(_make_icon(TEX_ICON_REFRESH_DARK, Vector2(30.0, 30.0)))


func _make_secondary_button(tex_n: Texture2D, tex_p: Texture2D, icon_tex: Texture2D, txt: String, font_size: int) -> TextureButton:
	var btn: TextureButton = TextureButton.new()
	btn.custom_minimum_size = Vector2(314.0, 82.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE
	btn.texture_normal = tex_n
	btn.texture_pressed = tex_p
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_SCALE

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.offset_left = 12.0
	hbox.offset_right = -12.0
	hbox.offset_bottom = -4.0
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 10)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	hbox.add_child(_make_icon(icon_tex, Vector2(26.0, 26.0)))
	var lbl: Label = _make_label(txt, font_size, COL_WHITE)
	hbox.add_child(lbl)
	btn.set_meta("label", lbl)
	return btn


func _update_reason_visuals() -> void:
	var is_broken: bool = (_current_reason == "robot_broken")
	if _left_title_icon != null:
		_left_title_icon.texture = TEX_ICON_ROBOT_BROKEN if is_broken else TEX_ICON_STOPWATCH
	if _title_lbl != null:
		_title_lbl.text = tr("HUD_DEFEAT_ROBOT_BROKEN") if is_broken else tr("HUD_DEFEAT_TITLE")
	if _extra_lbl != null:
		_extra_lbl.text = (tr("DEFEAT_BTN_REPAIR_ROBOT") if is_broken else tr("DEFEAT_BTN_EXTRA_TIME")).to_upper()


func _update_progress_bar_width(ratio: float) -> void:
	if _progress_fill == null or _progress_track == null:
		return
	var max_w: float = 464.0
	var fill_w: float = clampf(ratio, 0.0, 1.0) * max_w
	if ratio > 0.0 and fill_w < 20.0:
		fill_w = 20.0
	_progress_fill.size = Vector2(fill_w, 20.0)


func _populate_goals(goals_data: Variant) -> void:
	if _goals_hbox == null:
		return
	for child: Node in _goals_hbox.get_children():
		_goals_hbox.remove_child(child)
		child.queue_free()

	if goals_data is Array:
		var arr: Array = goals_data as Array
		for entry: Variant in arr:
			if entry is Dictionary:
				var d: Dictionary = entry as Dictionary
				var p_type: String = String(d.get("plant_type", "grass_green"))
				var cur: int = int(d.get("current", 0))
				var tgt: int = int(d.get("target", 0))
				_add_goal_item(p_type, cur, tgt)
	elif goals_data is Dictionary:
		var dict: Dictionary = goals_data as Dictionary
		for key: Variant in dict.keys():
			var rem: int = int(dict[key])
			_add_goal_item(String(key), 0, rem)


func _add_goal_item(plant_type: String, current_val: int, target_val: int) -> void:
	var item: HBoxContainer = HBoxContainer.new()
	item.mouse_filter = Control.MOUSE_FILTER_IGNORE
	item.alignment = BoxContainer.ALIGNMENT_CENTER
	item.add_theme_constant_override("separation", 8)

	item.add_child(GoalIconFactory.build_goal_icon(plant_type, 36.0))

	var is_done: bool = (target_val > 0 and current_val >= target_val)
	var col: Color = COL_GOAL_DONE if is_done else COL_WHITE
	var lbl: Label = _make_label("%d / %d" % [current_val, target_val], 21, col)
	lbl.add_theme_constant_override("outline_size", 6)
	lbl.add_theme_color_override("font_outline_color", Color(0.03, 0.06, 0.14, 0.95))
	item.add_child(lbl)

	_goals_hbox.add_child(item)


func _update_life_lost_badge() -> void:
	if _life_lost_lbl == null:
		return
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	var cur_lives: int = 5
	var max_lives: int = 5
	if save_mgr != null and save_mgr.has_method("get_lives"):
		cur_lives = int(save_mgr.call("get_lives"))
	_life_lost_lbl.text = "-1  (%d/%d)" % [cur_lives, max_lives]


func _retranslate_ui() -> void:
	_update_reason_visuals()
	if _cut_prog_lbl != null:
		_cut_prog_lbl.text = tr("DEFEAT_CUT_PROGRESS").to_upper()
	if _menu_lbl != null:
		_menu_lbl.text = tr("BTN_MENU").to_upper()
	if _retry_lbl != null:
		_retry_lbl.text = tr("HUD_RETRY").to_upper()


func _make_icon(tex: Texture2D, icon_size: Vector2) -> TextureRect:
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = tex
	icon_rect.custom_minimum_size = icon_size
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon_rect


func _make_label(txt: String, font_size: int, color: Color) -> Label:
	var lbl: Label = Label.new()
	lbl.text = txt
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", _font)
	lbl.add_theme_font_size_override("font_size", font_size)
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.55))
	lbl.add_theme_constant_override("shadow_offset_y", 2)
	return lbl


func _on_retry_pressed() -> void:
	if _is_closing:
		return
	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr != null and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "confirm")
	close()
	retry_requested.emit()


func _on_extra_pressed() -> void:
	if _is_closing:
		return
	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr != null and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "confirm")
	close()
	if _current_reason == "robot_broken":
		repair_robot_requested.emit()
	else:
		extra_time_requested.emit()


func _on_menu_pressed() -> void:
	if _is_closing:
		return
	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr != null and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "confirm")
	close()
	menu_requested.emit()
