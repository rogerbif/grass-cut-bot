class_name DefeatModal
extends Control

## Modal de Derrota (Game Over) com Estética Cyberpunk Neon.
## Exibe o progresso do corte, as metas restantes e três ações: Repetir Fase,
## Pegar Mais Tempo (placeholder de anúncio recompensado, 1 uso por tentativa) e Menu Inicial.
## Roda com process_mode = PROCESS_MODE_ALWAYS e constrói tudo programaticamente (Guardrail 13).

signal retry_requested
signal extra_time_requested
signal menu_requested

const EXTRA_TIME_SECONDS: float = 15.0
const NEAR_WIN_THRESHOLD: float = 0.70

const TEX_CARD_BG: Texture2D = preload("res://assets/ui/defeat/card_defeat_bg.svg")
const TEX_BTN_RETRY_N: Texture2D = preload("res://assets/ui/defeat/btn_retry_normal.svg")
const TEX_BTN_RETRY_P: Texture2D = preload("res://assets/ui/defeat/btn_retry_pressed.svg")
const TEX_BTN_EXTRA_N: Texture2D = preload("res://assets/ui/defeat/btn_extra_time_normal.svg")
const TEX_BTN_EXTRA_P: Texture2D = preload("res://assets/ui/defeat/btn_extra_time_pressed.svg")
const TEX_BTN_MENU_N: Texture2D = preload("res://assets/ui/pause/btn_menu_normal.svg")
const TEX_BTN_MENU_P: Texture2D = preload("res://assets/ui/pause/btn_menu_pressed.svg")

const TEX_ICON_STOPWATCH: Texture2D = preload("res://assets/ui/defeat/icon_stopwatch_red.svg")
const TEX_ICON_ALERT: Texture2D = preload("res://assets/ui/defeat/icon_alert_triangle_red.svg")
const TEX_ICON_TV: Texture2D = preload("res://assets/ui/defeat/icon_tv_play_cyan.svg")
const TEX_ICON_RETRY: Texture2D = preload("res://assets/ui/defeat/icon_restart_orange.svg")
const TEX_ICON_HOME: Texture2D = preload("res://assets/icons/navbar/nav_icon_home.svg")

const COL_WHITE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COL_TITLE_RED: Color = Color(1.0, 0.30, 0.32, 1.0)
const COL_SUBTITLE: Color = Color(0.86, 0.92, 1.0, 1.0)
const COL_PERCENT: Color = Color(1.0, 0.86, 0.30, 1.0)
const COL_GLOW_RED: Color = Color(1.0, 0.25, 0.30, 1.0)

const CARD_W: float = 440.0
const CARD_H: float = 488.0

var _font: SystemFont = null
var _backdrop: ColorRect = null
var _card_panel: PanelContainer = null
var _title_lbl: Label = null
var _subtitle_lbl: Label = null
var _cut_prog_lbl: Label = null
var _percent_lbl: Label = null
var _progress_bar: TextureProgressBar = null
var _goals_hbox: HBoxContainer = null
var _retry_btn: Button = null
var _extra_btn: Button = null
var _menu_btn: Button = null

var _fade_tween: Tween = null
var _glow_tween: Tween = null
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


## Abre o modal com os dados da derrota.
func open(progress: float, remaining_goals: Dictionary, can_extend: bool) -> void:
	visible = true
	_is_closing = false

	var pct: int = roundi(clampf(progress, 0.0, 1.0) * 100.0)
	_percent_lbl.text = "%d%%" % pct
	_progress_bar.value = float(pct)
	_subtitle_lbl.text = tr("DEFEAT_SUBTITLE_CLOSE") if progress >= NEAR_WIN_THRESHOLD else tr("DEFEAT_SUBTITLE_TRY_AGAIN")
	_extra_btn.visible = can_extend
	_populate_goals(remaining_goals)

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	_card_panel.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	_card_panel.scale = Vector2(0.85, 0.85)
	_card_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_backdrop, "modulate:a", 1.0, 0.20)
	_fade_tween.tween_property(_card_panel, "modulate:a", 1.0, 0.20)
	_fade_tween.tween_property(_card_panel, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Pulso sutil de brilho vermelho no card (leve para mobile)
	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
	_glow_tween = create_tween()
	_glow_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_glow_tween.set_loops()
	_glow_tween.tween_property(_card_panel, "self_modulate", Color(1.12, 0.92, 0.92, 1.0), 0.9).set_trans(Tween.TRANS_SINE)
	_glow_tween.tween_property(_card_panel, "self_modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_SINE)

	var vib_on: bool = true
	if SaveManager != null:
		vib_on = bool(SaveManager.get_setting("vib_enabled", true))
	if vib_on:
		Input.vibrate_handheld(40)


## Fecha o modal com Shrink + Fade Out.
func close() -> void:
	if _is_closing or not visible:
		return
	_is_closing = true

	if _glow_tween != null and _glow_tween.is_valid():
		_glow_tween.kill()
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_backdrop, "modulate:a", 0.0, 0.14)
	_fade_tween.tween_property(_card_panel, "modulate:a", 0.0, 0.14)
	_fade_tween.tween_property(_card_panel, "scale", Vector2(0.85, 0.85), 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_fade_tween.chain().tween_callback(func() -> void:
		visible = false
		_is_closing = false
		_card_panel.self_modulate = Color.WHITE
	)


func _build_ui() -> void:
	# Backdrop escuro: absorve toques (derrota exige decisão, não fecha ao tocar fora)
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.03, 0.02, 0.06, 0.72)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_card_panel = PanelContainer.new()
	_card_panel.set_anchors_preset(Control.PRESET_CENTER)
	_card_panel.offset_left = -CARD_W * 0.5
	_card_panel.offset_top = -CARD_H * 0.5
	_card_panel.offset_right = CARD_W * 0.5
	_card_panel.offset_bottom = CARD_H * 0.5
	_card_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_card_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_card_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var card_sb: StyleBoxTexture = StyleBoxTexture.new()
	card_sb.texture = TEX_CARD_BG
	card_sb.texture_margin_left = 36.0
	card_sb.texture_margin_right = 36.0
	card_sb.texture_margin_top = 40.0
	card_sb.texture_margin_bottom = 40.0
	card_sb.content_margin_left = 20.0
	card_sb.content_margin_right = 20.0
	card_sb.content_margin_top = 22.0
	card_sb.content_margin_bottom = 14.0
	_card_panel.add_theme_stylebox_override("panel", card_sb)
	add_child(_card_panel)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 12)
	_card_panel.add_child(main_vbox)

	# 1. Cabeçalho: [cronômetro] Tempo Esgotado! [alerta]
	var header_hbox: HBoxContainer = HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header_hbox)

	header_hbox.add_child(_make_icon(TEX_ICON_STOPWATCH, Vector2(58.0, 58.0)))

	_title_lbl = _make_label(tr("HUD_DEFEAT_TITLE"), 28, COL_TITLE_RED)
	_title_lbl.add_theme_constant_override("line_spacing", -4)
	header_hbox.add_child(_title_lbl)

	header_hbox.add_child(_make_icon(TEX_ICON_ALERT, Vector2(38.0, 38.0)))

	# 2. Subtítulo dinâmico
	_subtitle_lbl = _make_label("", 17, COL_SUBTITLE)
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_vbox.add_child(_subtitle_lbl)

	# 3. Painel de progresso do corte
	var prog_panel: PanelContainer = PanelContainer.new()
	prog_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var prog_sb: StyleBoxFlat = StyleBoxFlat.new()
	prog_sb.bg_color = Color(0.05, 0.08, 0.16, 0.85)
	prog_sb.set_corner_radius_all(12)
	prog_sb.set_border_width_all(1)
	prog_sb.border_color = Color(0.35, 0.40, 0.65, 0.45)
	prog_sb.content_margin_left = 16.0
	prog_sb.content_margin_right = 16.0
	prog_sb.content_margin_top = 10.0
	prog_sb.content_margin_bottom = 10.0
	prog_panel.add_theme_stylebox_override("panel", prog_sb)
	main_vbox.add_child(prog_panel)

	var prog_vbox: VBoxContainer = VBoxContainer.new()
	prog_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prog_vbox.add_theme_constant_override("separation", 8)
	prog_panel.add_child(prog_vbox)

	var prog_title_hbox: HBoxContainer = HBoxContainer.new()
	prog_title_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	prog_title_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	prog_title_hbox.add_theme_constant_override("separation", 6)
	prog_vbox.add_child(prog_title_hbox)
	_cut_prog_lbl = _make_label(tr("DEFEAT_CUT_PROGRESS"), 16, COL_WHITE)
	prog_title_hbox.add_child(_cut_prog_lbl)
	_percent_lbl = _make_label("0%", 17, COL_PERCENT)
	prog_title_hbox.add_child(_percent_lbl)

	_progress_bar = _make_progress_bar()
	prog_vbox.add_child(_progress_bar)

	_goals_hbox = HBoxContainer.new()
	_goals_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_goals_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_goals_hbox.add_theme_constant_override("separation", 28)
	prog_vbox.add_child(_goals_hbox)

	# 4. Botões de ação
	_retry_btn = _make_action_button(tr("HUD_RETRY"), TEX_ICON_RETRY, TEX_BTN_RETRY_N, TEX_BTN_RETRY_P, 22)
	_retry_btn.pressed.connect(_on_retry_pressed)
	main_vbox.add_child(_retry_btn)

	_extra_btn = _make_action_button(tr("DEFEAT_BTN_EXTRA_TIME"), TEX_ICON_TV, TEX_BTN_EXTRA_N, TEX_BTN_EXTRA_P, 20)
	_extra_btn.pressed.connect(_on_extra_pressed)
	main_vbox.add_child(_extra_btn)

	_menu_btn = _make_action_button(tr("HUD_MAIN_MENU"), TEX_ICON_HOME, TEX_BTN_MENU_N, TEX_BTN_MENU_P, 22)
	_menu_btn.pressed.connect(_on_menu_pressed)
	main_vbox.add_child(_menu_btn)


func _make_progress_bar() -> TextureProgressBar:
	var bar: TextureProgressBar = TextureProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.step = 1.0
	bar.custom_minimum_size = Vector2(0.0, 12.0)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.nine_patch_stretch = true
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var under_grad: Gradient = Gradient.new()
	under_grad.set_color(0, Color(0.10, 0.12, 0.22, 1.0))
	under_grad.set_color(1, Color(0.10, 0.12, 0.22, 1.0))
	var under_tex: GradientTexture2D = GradientTexture2D.new()
	under_tex.gradient = under_grad
	under_tex.width = 64
	under_tex.height = 12

	var fill_grad: Gradient = Gradient.new()
	fill_grad.set_color(0, Color(1.0, 0.22, 0.50, 1.0))
	fill_grad.set_color(1, Color(1.0, 0.85, 0.25, 1.0))
	var fill_tex: GradientTexture2D = GradientTexture2D.new()
	fill_tex.gradient = fill_grad
	fill_tex.width = 256
	fill_tex.height = 12
	fill_tex.fill_from = Vector2(0.0, 0.5)
	fill_tex.fill_to = Vector2(1.0, 0.5)

	bar.texture_under = under_tex
	bar.texture_progress = fill_tex
	return bar


func _populate_goals(remaining_goals: Dictionary) -> void:
	for child: Node in _goals_hbox.get_children():
		_goals_hbox.remove_child(child)
		child.queue_free()
	for key: Variant in remaining_goals.keys():
		var item: HBoxContainer = HBoxContainer.new()
		item.mouse_filter = Control.MOUSE_FILTER_IGNORE
		item.add_theme_constant_override("separation", 6)
		item.add_child(GoalIconFactory.build_goal_icon(String(key), 30.0))
		item.add_child(_make_label(str(int(remaining_goals[key])), 16, COL_WHITE))
		_goals_hbox.add_child(item)
	_goals_hbox.visible = not remaining_goals.is_empty()


func _make_action_button(txt: String, icon_tex: Texture2D, tex_n: Texture2D, tex_p: Texture2D, font_size: int, icon_tint: Color = Color.WHITE) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0.0, 58.0)
	btn.focus_mode = Control.FOCUS_NONE

	var sb_n: StyleBoxTexture = _make_btn_style(tex_n)
	var sb_p: StyleBoxTexture = _make_btn_style(tex_p)
	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_n)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_stylebox_override("focus", sb_n)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var btn_icon: TextureRect = _make_icon(icon_tex, Vector2(26.0, 26.0))
	btn_icon.modulate = icon_tint
	hbox.add_child(btn_icon)
	var lbl: Label = _make_label(txt, font_size, COL_WHITE)
	hbox.add_child(lbl)
	btn.set_meta("label", lbl)
	return btn

func _retranslate_ui() -> void:
	if _title_lbl != null:
		_title_lbl.text = tr("HUD_DEFEAT_TITLE")
	if _cut_prog_lbl != null:
		_cut_prog_lbl.text = tr("DEFEAT_CUT_PROGRESS")
	if _retry_btn != null and _retry_btn.has_meta("label"):
		(_retry_btn.get_meta("label") as Label).text = tr("HUD_RETRY")
	if _extra_btn != null and _extra_btn.has_meta("label"):
		(_extra_btn.get_meta("label") as Label).text = tr("DEFEAT_BTN_EXTRA_TIME")
	if _menu_btn != null and _menu_btn.has_meta("label"):
		(_menu_btn.get_meta("label") as Label).text = tr("HUD_MAIN_MENU")
	if _subtitle_lbl != null and visible:
		_subtitle_lbl.text = tr("DEFEAT_SUBTITLE_CLOSE") if (_progress_bar != null and _progress_bar.value >= NEAR_WIN_THRESHOLD * 100.0) else tr("DEFEAT_SUBTITLE_TRY_AGAIN")


func _make_btn_style(tex: Texture2D) -> StyleBoxTexture:
	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = 18.0
	sb.texture_margin_right = 18.0
	sb.texture_margin_top = 18.0
	sb.texture_margin_bottom = 18.0
	sb.content_margin_left = 14.0
	sb.content_margin_right = 14.0
	return sb


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
	lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	return lbl


func _on_retry_pressed() -> void:
	if _is_closing:
		return
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	close()
	retry_requested.emit()


func _on_extra_pressed() -> void:
	if _is_closing:
		return
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	close()
	extra_time_requested.emit()


func _on_menu_pressed() -> void:
	if _is_closing:
		return
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	close()
	menu_requested.emit()
