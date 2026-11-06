class_name ExitModal
extends Control

## Modal de Confirmação de Saída com Estética Cyberpunk Neon.
## Pergunta ao jogador se deseja sair do aplicativo ao pressionar o botão Voltar na tela inicial.
## Constrói a interface programaticamente (Guardrail 13: Zero Overrides em .scn).

signal cancel_requested
signal quit_requested

const TEX_CARD_BG: Texture2D = preload("res://assets/ui/pause/card_pause_bg.svg")
const TEX_BTN_RESUME_N: Texture2D = preload("res://assets/ui/pause/btn_resume_normal.svg")
const TEX_BTN_RESUME_P: Texture2D = preload("res://assets/ui/pause/btn_resume_pressed.svg")
const TEX_BTN_DANGER_N: Texture2D = preload("res://assets/ui/settings/btn_danger_cyber.svg")
const TEX_BTN_DANGER_P: Texture2D = preload("res://assets/ui/settings/btn_danger_cyber_pressed.svg")
const TEX_ICON_PLAY: Texture2D = preload("res://assets/ui/pause/icon_play_triangle_green.svg")
const TEX_ICON_ALERT: Texture2D = preload("res://assets/ui/defeat/icon_alert_triangle_red.svg")
const TEX_ICON_CLOSE_X: Texture2D = preload("res://assets/ui/pause/btn_close_x.svg")

const COL_WHITE: Color = Color(1.0, 1.0, 1.0, 1.0)
const COL_CYAN_TITLE: Color = Color(0.90, 0.96, 1.0, 1.0)
const COL_SUBTITLE: Color = Color(0.80, 0.88, 0.98, 0.90)

const CARD_W: float = 440.0
const CARD_H: float = 360.0

var _font: SystemFont = null
var _backdrop: ColorRect = null
var _card_panel: PanelContainer = null
var _close_x_btn: TextureButton = null
var _resume_btn: Button = null
var _quit_btn: Button = null

var _fade_tween: Tween = null
var _is_closing: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe UI", "Arial Black", "Montserrat", "sans-serif"])
	_font.font_weight = 900

	_build_ui()

func is_open() -> bool:
	return visible and not _is_closing

func _unhandled_input(event: InputEvent) -> void:
	if not visible or _is_closing:
		return
	if event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()

func open() -> void:
	visible = true
	_is_closing = false

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	if AudioManager != null:
		AudioManager.play_sfx("confirm")

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

	if AudioManager != null:
		AudioManager.play_sfx("close")

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
		cancel_requested.emit()
	)

func _on_quit_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	if SaveManager != null:
		SaveManager.save_game()
	quit_requested.emit()
	get_tree().quit()

func _build_ui() -> void:
	# Backdrop escuro semi-transparente
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.02, 0.05, 0.10, 0.72)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(_on_backdrop_gui_input)
	add_child(_backdrop)

	# Card centralizado
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
	card_sb.content_margin_left = 22.0
	card_sb.content_margin_right = 22.0
	card_sb.content_margin_top = 22.0
	card_sb.content_margin_bottom = 20.0
	_card_panel.add_theme_stylebox_override("panel", card_sb)
	add_child(_card_panel)

	var main_vbox: VBoxContainer = VBoxContainer.new()
	main_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_theme_constant_override("separation", 16)
	_card_panel.add_child(main_vbox)

	# 1. Cabeçalho com Ícone de Alerta, Título e Botão [X]
	var header_hbox: HBoxContainer = HBoxContainer.new()
	header_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_theme_constant_override("separation", 10)
	main_vbox.add_child(header_hbox)

	var alert_icon: TextureRect = TextureRect.new()
	alert_icon.texture = TEX_ICON_ALERT
	alert_icon.custom_minimum_size = Vector2(30.0, 30.0)
	alert_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	alert_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	alert_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	alert_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header_hbox.add_child(alert_icon)

	var title_lbl: Label = _make_label("SAIR DO JOGO?", 26, COL_CYAN_TITLE)
	title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_hbox.add_child(title_lbl)

	_close_x_btn = TextureButton.new()
	_close_x_btn.texture_normal = TEX_ICON_CLOSE_X
	_close_x_btn.custom_minimum_size = Vector2(32.0, 32.0)
	_close_x_btn.ignore_texture_size = true
	_close_x_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_close_x_btn.focus_mode = Control.FOCUS_NONE
	_close_x_btn.pressed.connect(close)
	header_hbox.add_child(_close_x_btn)

	# 2. Mensagem Explicativa de Progresso Salvo
	var body_lbl: Label = Label.new()
	body_lbl.text = "Seu progresso e moedas estão salvos.\nDeseja realmente fechar o Grass Cut Bot?"
	body_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	body_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body_lbl.add_theme_font_override("font", _font)
	body_lbl.add_theme_font_size_override("font_size", 17)
	body_lbl.add_theme_color_override("font_color", COL_SUBTITLE)
	body_lbl.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.5))
	body_lbl.add_theme_constant_override("shadow_offset_y", 1)
	main_vbox.add_child(body_lbl)

	# Espaçador sutil
	var spacer: Control = Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 6.0)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_vbox.add_child(spacer)

	# 3. Botão Primário: CONTINUAR JOGANDO (Verde Neon)
	_resume_btn = _make_action_button("CONTINUAR JOGANDO", TEX_ICON_PLAY, Vector2(24.0, 24.0), TEX_BTN_RESUME_N, TEX_BTN_RESUME_P)
	_resume_btn.pressed.connect(close)
	main_vbox.add_child(_resume_btn)

	# 4. Botão Secundário: SAIR DO JOGO (Vermelho Cyber)
	_quit_btn = _make_action_button("SAIR DO APLICATIVO", TEX_ICON_ALERT, Vector2(22.0, 22.0), TEX_BTN_DANGER_N, TEX_BTN_DANGER_P)
	_quit_btn.pressed.connect(_on_quit_pressed)
	main_vbox.add_child(_quit_btn)

func _make_action_button(txt: String, icon_tex: Texture2D, icon_sz: Vector2, tex_n: Texture2D, tex_p: Texture2D) -> Button:
	var btn: Button = Button.new()
	btn.custom_minimum_size = Vector2(0.0, 56.0)
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

	var lbl: Label = _make_label(txt, 20, COL_WHITE)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hbox.add_child(lbl)

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

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if _is_closing:
		return
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			close()
	elif event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			close()
