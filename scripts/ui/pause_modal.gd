class_name PauseModal
extends Control

## Modal de Pausa Ingame com Estética Cyberpunk Neon.
## Pausa e despausa a árvore de nós da engine mantendo process_mode = PROCESS_MODE_ALWAYS.
## Inclui botões temáticos chanfrados, botão [X], fechamento ao tocar no backdrop,
## animação Grow + Fade In / Shrink + Fade Out e cards de toggles rápidos.

signal resume_requested
signal restart_requested
signal menu_requested

const TEX_CARD_BG: Texture2D = preload("res://assets/ui/pause/card_pause_bg.svg")
const TEX_BTN_RESUME_N: Texture2D = preload("res://assets/ui/pause/btn_resume_normal.svg")
const TEX_BTN_RESUME_P: Texture2D = preload("res://assets/ui/pause/btn_resume_pressed.svg")
const TEX_BTN_RESTART_N: Texture2D = preload("res://assets/ui/pause/btn_restart_normal.svg")
const TEX_BTN_RESTART_P: Texture2D = preload("res://assets/ui/pause/btn_restart_pressed.svg")
const TEX_BTN_MENU_N: Texture2D = preload("res://assets/ui/pause/btn_menu_normal.svg")
const TEX_BTN_MENU_P: Texture2D = preload("res://assets/ui/pause/btn_menu_pressed.svg")

const TEX_CARD_TOGGLE: Texture2D = preload("res://assets/ui/pause/card_toggle_bg.svg")
const TEX_TOGGLE_ON: Texture2D = preload("res://assets/ui/pause/toggle_pill_on.svg")
const TEX_TOGGLE_OFF: Texture2D = preload("res://assets/ui/pause/toggle_pill_off.svg")

const TEX_ICON_PAUSE: Texture2D = preload("res://assets/ui/pause/icon_pause_cyan.svg")
const TEX_ICON_PLAY: Texture2D = preload("res://assets/ui/pause/icon_play_triangle_green.svg")
const TEX_ICON_REFRESH: Texture2D = preload("res://assets/ui/pause/icon_restart_cyber.svg")
const TEX_ICON_HOME: Texture2D = preload("res://assets/icons/navbar/nav_icon_home.svg")
const TEX_ICON_CLOSE_X: Texture2D = preload("res://assets/ui/pause/btn_close_x.svg")

const TEX_ICON_SFX: Texture2D = preload("res://assets/ui/pause/icon_speaker_cyan.svg")
const TEX_ICON_MUSIC: Texture2D = preload("res://assets/ui/pause/icon_music_cyan.svg")
const TEX_ICON_VIB: Texture2D = preload("res://assets/ui/settings/icon_settings_vibration.svg")

const COL_WHITE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COL_CYAN_TITLE: Color = Color(0.90, 0.96, 1.0, 1.0)
const COL_GREEN_ON: Color = Color(0.0, 0.96, 0.46, 1.0)
const COL_GRAY_OFF: Color = Color(0.48, 0.56, 0.64, 1.0)
const COL_LABEL_TITLE: Color = Color(0.92, 0.95, 1.0, 1.0)

const CARD_W: float = 440.0
const CARD_H: float = 470.0

var _font: SystemFont = null
var _backdrop: ColorRect = null
var _card_panel: PanelContainer = null
var _close_x_btn: TextureButton = null

var _resume_btn: Button = null
var _restart_btn: Button = null
var _menu_btn: Button = null

var _toggle_sfx_btn: Button = null
var _toggle_sfx_icon: TextureRect = null
var _toggle_sfx_status: Label = null

var _toggle_music_btn: Button = null
var _toggle_music_icon: TextureRect = null
var _toggle_music_status: Label = null

var _toggle_vib_btn: Button = null
var _toggle_vib_icon: TextureRect = null
var _toggle_vib_status: Label = null

var _fade_tween: Tween = null
var _is_closing: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe UI", "Arial Black", "Montserrat", "sans-serif"])
	_font.font_weight = 900

	_build_ui()
	_sync_toggles_state()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or _is_closing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		_on_resume_pressed()


func open() -> void:
	visible = true
	_is_closing = false
	_sync_toggles_state()

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	# Configura pivô central e estado inicial da animação
	_card_panel.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	_card_panel.scale = Vector2(0.85, 0.85)
	_card_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_backdrop, "modulate:a", 1.0, 0.18)
	_fade_tween.tween_property(_card_panel, "modulate:a", 1.0, 0.18)
	_fade_tween.tween_property(_card_panel, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close() -> void:
	if _is_closing:
		return
	_is_closing = true

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	_card_panel.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_backdrop, "modulate:a", 0.0, 0.14)
	_fade_tween.tween_property(_card_panel, "modulate:a", 0.0, 0.14)
	_fade_tween.tween_property(_card_panel, "scale", Vector2(0.85, 0.85), 0.14).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_fade_tween.chain().tween_callback(func() -> void:
		visible = false
		_is_closing = false
	)


func _build_ui() -> void:
	# Fundo Backdrop escuro (detecta toque fora do card para fechar)
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.02, 0.05, 0.10, 0.72)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_gui_input)
	add_child(_backdrop)

	# Card central de pausa
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
	card_sb.content_margin_top = 18.0
	card_sb.content_margin_bottom = 14.0
	_card_panel.add_theme_stylebox_override("panel", card_sb)
	add_child(_card_panel)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 14)
	_card_panel.add_child(main_vbox)

	# 1. Cabeçalho: [||] Jogo Pausado ............ [X]
	var header_hbox: HBoxContainer = HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	header_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header_hbox)

	var pause_icon: TextureRect = TextureRect.new()
	pause_icon.texture = TEX_ICON_PAUSE
	pause_icon.custom_minimum_size = Vector2(24.0, 24.0)
	pause_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	pause_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pause_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pause_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(pause_icon)

	var title_lbl: Label = _make_label("Jogo Pausado", 28, COL_CYAN_TITLE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	# Botão de fechar [X] no topo direito
	_close_x_btn = TextureButton.new()
	_close_x_btn.texture_normal = TEX_ICON_CLOSE_X
	_close_x_btn.custom_minimum_size = Vector2(30.0, 30.0)
	_close_x_btn.ignore_texture_size = true
	_close_x_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_close_x_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_close_x_btn.focus_mode = Control.FOCUS_NONE
	_close_x_btn.pressed.connect(_on_resume_pressed)
	header_hbox.add_child(_close_x_btn)

	# 2. Botão Principal: Continuar
	_resume_btn = _make_action_button("Continuar", TEX_ICON_PLAY, Vector2(24.0, 24.0), TEX_BTN_RESUME_N, TEX_BTN_RESUME_P)
	_resume_btn.pressed.connect(_on_resume_pressed)
	main_vbox.add_child(_resume_btn)

	# 3. Botão Secundário 1: Reiniciar Fase
	_restart_btn = _make_action_button("Reiniciar Fase", TEX_ICON_REFRESH, Vector2(24.0, 24.0), TEX_BTN_RESTART_N, TEX_BTN_RESTART_P)
	_restart_btn.pressed.connect(_on_restart_pressed)
	main_vbox.add_child(_restart_btn)

	# 4. Botão Secundário 2: Menu Inicial
	_menu_btn = _make_action_button("Menu Inicial", TEX_ICON_HOME, Vector2(24.0, 24.0), TEX_BTN_MENU_N, TEX_BTN_MENU_P)
	_menu_btn.pressed.connect(_on_menu_pressed)
	main_vbox.add_child(_menu_btn)

	# 5. Trio de Mini-Cards Inferiores (FX | Música | Vibrar)
	var toggles_hbox: HBoxContainer = HBoxContainer.new()
	toggles_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toggles_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	toggles_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(toggles_hbox)

	# Mini-card FX
	var sfx_card: Control = _build_toggle_card(
		"FX", TEX_ICON_SFX,
		func(btn: Button, icon: TextureRect, status: Label) -> void:
			_toggle_sfx_btn = btn
			_toggle_sfx_icon = icon
			_toggle_sfx_status = status
			btn.pressed.connect(_on_toggle_sfx_pressed)
	)
	toggles_hbox.add_child(sfx_card)

	# Mini-card Música
	var music_card: Control = _build_toggle_card(
		"Música", TEX_ICON_MUSIC,
		func(btn: Button, icon: TextureRect, status: Label) -> void:
			_toggle_music_btn = btn
			_toggle_music_icon = icon
			_toggle_music_status = status
			btn.pressed.connect(_on_toggle_music_pressed)
	)
	toggles_hbox.add_child(music_card)

	# Mini-card Vibrar
	var vib_card: Control = _build_toggle_card(
		"Vibrar", TEX_ICON_VIB,
		func(btn: Button, icon: TextureRect, status: Label) -> void:
			_toggle_vib_btn = btn
			_toggle_vib_icon = icon
			_toggle_vib_status = status
			btn.pressed.connect(_on_toggle_vib_pressed)
	)
	toggles_hbox.add_child(vib_card)


func _make_action_button(txt: String, icon_tex: Texture2D, icon_sz: Vector2, tex_n: Texture2D, tex_p: Texture2D) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0.0, 58.0)
	btn.focus_mode = Control.FOCUS_NONE

	var sb_n: StyleBoxTexture = StyleBoxTexture.new()
	sb_n.texture = tex_n
	sb_n.texture_margin_left = 18.0
	sb_n.texture_margin_right = 18.0
	sb_n.texture_margin_top = 18.0
	sb_n.texture_margin_bottom = 18.0
	sb_n.content_margin_left = 14.0
	sb_n.content_margin_right = 14.0

	var sb_p: StyleBoxTexture = StyleBoxTexture.new()
	sb_p.texture = tex_p
	sb_p.texture_margin_left = 18.0
	sb_p.texture_margin_right = 18.0
	sb_p.texture_margin_top = 18.0
	sb_p.texture_margin_bottom = 18.0
	sb_p.content_margin_left = 14.0
	sb_p.content_margin_right = 14.0

	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_n)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_stylebox_override("focus", sb_n)

	# Layout interno: Ícone + Label agrupados e centralizados (distância justa de 12px)
	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_theme_constant_override("separation", 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(hbox)

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.custom_minimum_size = icon_sz
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hbox.add_child(icon_rect)

	var lbl: Label = _make_label(txt, 22, COL_WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

	return btn


func _build_toggle_card(card_title: String, icon_tex: Texture2D, register_cb: Callable) -> Control:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(122.0, 130.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.focus_mode = Control.FOCUS_NONE

	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = TEX_CARD_TOGGLE
	sb.texture_margin_left = 16.0
	sb.texture_margin_right = 16.0
	sb.texture_margin_top = 16.0
	sb.texture_margin_bottom = 16.0
	sb.content_margin_left = 6.0
	sb.content_margin_right = 6.0
	sb.content_margin_top = 8.0
	sb.content_margin_bottom = 8.0

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_stylebox_override("focus", sb)

	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 5)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vbox)

	# Ícone do recurso
	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.texture = icon_tex
	icon_rect.custom_minimum_size = Vector2(28.0, 28.0)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_rect)

	# Switch Toggle tipo pílula
	var toggle_switch: TextureRect = TextureRect.new()
	toggle_switch.texture = TEX_TOGGLE_ON
	toggle_switch.custom_minimum_size = Vector2(50.0, 22.0)
	toggle_switch.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	toggle_switch.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	toggle_switch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	toggle_switch.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(toggle_switch)

	# Nome do Recurso ("FX", "Música", "Vibrar")
	var name_lbl: Label = _make_label(card_title, 17, COL_LABEL_TITLE)
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_lbl)

	# Status ("Ligado" / "Desligado")
	var status_lbl: Label = _make_label("Ligado", 14, COL_GREEN_ON)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(status_lbl)

	register_cb.call(btn, toggle_switch, status_lbl)
	return btn


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


func _sync_toggles_state() -> void:
	# FX
	var sfx_on: bool = true
	if AudioManager != null:
		sfx_on = AudioManager.is_sfx_enabled()
	elif SaveManager != null:
		sfx_on = bool(SaveManager.get_setting("sfx_enabled", true))
	_update_toggle_item(_toggle_sfx_icon, _toggle_sfx_status, sfx_on)

	# Música
	var music_on: bool = true
	if AudioManager != null:
		music_on = AudioManager.is_music_enabled()
	elif SaveManager != null:
		music_on = bool(SaveManager.get_setting("music_enabled", true))
	_update_toggle_item(_toggle_music_icon, _toggle_music_status, music_on)

	# Vibrar
	var vib_on: bool = true
	if SaveManager != null:
		vib_on = bool(SaveManager.get_setting("vib_enabled", true))
	_update_toggle_item(_toggle_vib_icon, _toggle_vib_status, vib_on)


func _update_toggle_item(icon_rect: TextureRect, status_lbl: Label, is_on: bool) -> void:
	if icon_rect != null:
		icon_rect.texture = TEX_TOGGLE_ON if is_on else TEX_TOGGLE_OFF
	if status_lbl != null:
		status_lbl.text = "Ligado" if is_on else "Desligado"
		status_lbl.add_theme_color_override("font_color", COL_GREEN_ON if is_on else COL_GRAY_OFF)


func _on_backdrop_gui_input(event: InputEvent) -> void:
	if _is_closing:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_on_resume_pressed()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			get_viewport().set_input_as_handled()
			_on_resume_pressed()


func _on_resume_pressed() -> void:
	close()
	resume_requested.emit()


func _on_restart_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	close()
	restart_requested.emit()


func _on_menu_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
		AudioManager.stop_engine()
	close()
	menu_requested.emit()


func _on_toggle_sfx_pressed() -> void:
	var cur: bool = true
	if AudioManager != null:
		cur = AudioManager.is_sfx_enabled()
	var new_val: bool = not cur
	if AudioManager != null:
		AudioManager.set_sfx_enabled(new_val)
	if SaveManager != null:
		SaveManager.set_setting("sfx_enabled", new_val)
	_sync_toggles_state()
	if new_val and AudioManager != null:
		AudioManager.play_sfx("confirm")


func _on_toggle_music_pressed() -> void:
	var cur: bool = true
	if AudioManager != null:
		cur = AudioManager.is_music_enabled()
	var new_val: bool = not cur
	if AudioManager != null:
		AudioManager.set_music_enabled(new_val)
	if SaveManager != null:
		SaveManager.set_setting("music_enabled", new_val)
	_sync_toggles_state()
	if AudioManager != null:
		AudioManager.play_sfx("confirm")


func _on_toggle_vib_pressed() -> void:
	var cur: bool = true
	if SaveManager != null:
		cur = bool(SaveManager.get_setting("vib_enabled", true))
	var new_val: bool = not cur
	if SaveManager != null:
		SaveManager.set_setting("vib_enabled", new_val)
	_sync_toggles_state()
	if new_val and Input.has_method("vibrate_handheld"):
		Input.vibrate_handheld(25)
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
