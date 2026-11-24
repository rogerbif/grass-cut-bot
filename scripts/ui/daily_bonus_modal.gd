class_name DailyBonusModal
extends Control

## Modal de Bônus Diário de 7 Dias com estética Cyber-Mecha Neon.
## Constrói toda a UI programaticamente para garantir compatibilidade em builds exportadas.

signal bonus_claimed(day_num: int, coins: int)
signal modal_closed

const TEX_CARD_BG: Texture2D = preload("res://assets/ui/pause/card_pause_bg.svg")
const TEX_DAY_BG: Texture2D = preload("res://assets/ui/collection/card_species_bg.svg")
const TEX_BTN_CLAIM: Texture2D = preload("res://assets/ui/collection/btn_claim_cyber.svg")
const TEX_ICON_COIN: Texture2D = preload("res://assets/icons/icon_coin.svg")
const TEX_ICON_HEART: Texture2D = preload("res://assets/icons/icon_heart.svg")
const TEX_ICON_GIFT: Texture2D = preload("res://assets/icons/icon_gift.svg")
const TEX_ICON_CLOSE_X: Texture2D = preload("res://assets/ui/pause/btn_close_x.svg")

const CARD_W: float = 610.0
const CARD_H: float = 690.0

var _font: SystemFont = null
var _backdrop: ColorRect = null
var _card_panel: PanelContainer = null
var _close_x_btn: TextureButton = null
var _title_lbl: Label = null
var _subtitle_lbl: Label = null
var _claim_btn: Button = null
var _day_cards: Array[Dictionary] = []

var _fade_tween: Tween = null
var _pulse_tween: Tween = null
var _is_closing: bool = false
var _timer_accum: float = 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_ui()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	_font = SystemFont.new()
	_font.font_names = PackedStringArray(["Segoe UI", "Arial Black", "Montserrat", "sans-serif"])
	_font.font_weight = 900

	_build_ui()
	_refresh_ui()

func _process(delta: float) -> void:
	if not visible or _is_closing:
		return
	_timer_accum += delta
	if _timer_accum >= 1.0:
		_timer_accum = 0.0
		_update_claim_button_state()

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
	_timer_accum = 0.0
	_refresh_ui()

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr != null and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "confirm")

	_card_panel.pivot_offset = Vector2(CARD_W * 0.5, CARD_H * 0.5)
	_card_panel.scale = Vector2(0.86, 0.86)
	_card_panel.modulate = Color(1.0, 1.0, 1.0, 0.0)
	_backdrop.modulate = Color(1.0, 1.0, 1.0, 0.0)

	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_backdrop, "modulate:a", 1.0, 0.18)
	_fade_tween.tween_property(_card_panel, "modulate:a", 1.0, 0.18)
	_fade_tween.tween_property(_card_panel, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close() -> void:
	if _is_closing or not visible:
		return
	_is_closing = true

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()

	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr != null and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "button")

	_fade_tween = create_tween()
	_fade_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	_fade_tween.set_parallel(true)
	_fade_tween.tween_property(_backdrop, "modulate:a", 0.0, 0.15)
	_fade_tween.tween_property(_card_panel, "modulate:a", 0.0, 0.15)
	_fade_tween.tween_property(_card_panel, "scale", Vector2(0.90, 0.90), 0.15)
	_fade_tween.chain().tween_callback(func() -> void:
		visible = false
		_is_closing = false
		modal_closed.emit()
	)

func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.name = "Backdrop"
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.02, 0.04, 0.08, 0.78)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	_backdrop.gui_input.connect(func(ev: InputEvent) -> void:
		if ev is InputEventMouseButton and ev.pressed and (ev as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			close()
	)
	add_child(_backdrop)

	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)

	_card_panel = PanelContainer.new()
	_card_panel.name = "CardPanel"
	_card_panel.custom_minimum_size = Vector2(CARD_W, CARD_H)
	_card_panel.mouse_filter = Control.MOUSE_FILTER_STOP

	var card_sb: StyleBoxTexture = StyleBoxTexture.new()
	card_sb.texture = TEX_CARD_BG
	card_sb.texture_margin_left = 40.0
	card_sb.texture_margin_top = 40.0
	card_sb.texture_margin_right = 40.0
	card_sb.texture_margin_bottom = 40.0
	card_sb.content_margin_left = 26.0
	card_sb.content_margin_top = 24.0
	card_sb.content_margin_right = 26.0
	card_sb.content_margin_bottom = 24.0
	_card_panel.add_theme_stylebox_override("panel", card_sb)
	center.add_child(_card_panel)

	var root_vbox: VBoxContainer = VBoxContainer.new()
	root_vbox.add_theme_constant_override("separation", 14)
	_card_panel.add_child(root_vbox)

	# Header Row
	var header_hbox: HBoxContainer = HBoxContainer.new()
	header_hbox.add_theme_constant_override("separation", 10)
	root_vbox.add_child(header_hbox)

	var gift_icon: TextureRect = TextureRect.new()
	gift_icon.texture = TEX_ICON_GIFT
	gift_icon.custom_minimum_size = Vector2(40, 40)
	gift_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	gift_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header_hbox.add_child(gift_icon)

	_title_lbl = Label.new()
	_title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title_lbl.add_theme_font_override("font", _font)
	_title_lbl.add_theme_font_size_override("font_size", 28)
	_title_lbl.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0, 1.0))
	_title_lbl.add_theme_color_override("font_outline_color", Color(0.03, 0.07, 0.14, 1.0))
	_title_lbl.add_theme_constant_override("outline_size", 6)
	header_hbox.add_child(_title_lbl)

	_close_x_btn = TextureButton.new()
	_close_x_btn.custom_minimum_size = Vector2(44, 44)
	_close_x_btn.focus_mode = Control.FOCUS_NONE
	_close_x_btn.texture_normal = TEX_ICON_CLOSE_X
	_close_x_btn.ignore_texture_size = true
	_close_x_btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	_close_x_btn.pressed.connect(close)
	header_hbox.add_child(_close_x_btn)

	_subtitle_lbl = Label.new()
	_subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_subtitle_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_subtitle_lbl.add_theme_font_override("font", _font)
	_subtitle_lbl.add_theme_font_size_override("font_size", 15)
	_subtitle_lbl.add_theme_color_override("font_color", Color(0.76, 0.88, 1.0, 0.92))
	root_vbox.add_child(_subtitle_lbl)

	# Dias 1 a 6 em Grade 3x2
	var grid: GridContainer = GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	root_vbox.add_child(grid)

	_day_cards.clear()
	for day_num: int in range(1, 7):
		var card_info: Dictionary = _create_day_card(day_num, false)
		grid.add_child(card_info["panel"] as Control)
		_day_cards.append(card_info)

	# Dia 7 (Grande Prêmio em destaque)
	var day7_info: Dictionary = _create_day_card(7, true)
	root_vbox.add_child(day7_info["panel"] as Control)
	_day_cards.append(day7_info)

	# Botão Principal de Coleta
	_claim_btn = Button.new()
	_claim_btn.custom_minimum_size = Vector2(0, 64)
	_claim_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_claim_btn.focus_mode = Control.FOCUS_NONE
	_claim_btn.add_theme_font_override("font", _font)
	_claim_btn.add_theme_font_size_override("font_size", 22)
	_claim_btn.add_theme_color_override("font_color", Color.WHITE)
	_claim_btn.add_theme_color_override("font_disabled_color", Color(0.72, 0.80, 0.90, 0.85))
	_claim_btn.add_theme_color_override("font_outline_color", Color(0.05, 0.14, 0.08, 1.0))
	_claim_btn.add_theme_constant_override("outline_size", 5)

	var btn_sb_n: StyleBoxTexture = StyleBoxTexture.new()
	btn_sb_n.texture = TEX_BTN_CLAIM
	btn_sb_n.texture_margin_left = 18.0
	btn_sb_n.texture_margin_top = 14.0
	btn_sb_n.texture_margin_right = 18.0
	btn_sb_n.texture_margin_bottom = 14.0
	var btn_sb_d: StyleBoxTexture = btn_sb_n.duplicate() as StyleBoxTexture
	btn_sb_d.modulate_color = Color(0.45, 0.48, 0.55, 0.85)
	_claim_btn.add_theme_stylebox_override("normal", btn_sb_n)
	_claim_btn.add_theme_stylebox_override("hover", btn_sb_n)
	_claim_btn.add_theme_stylebox_override("pressed", btn_sb_n)
	_claim_btn.add_theme_stylebox_override("disabled", btn_sb_d)

	_claim_btn.pressed.connect(_on_claim_pressed)
	root_vbox.add_child(_claim_btn)

func _create_day_card(day_num: int, is_day7: bool) -> Dictionary:
	var panel: PanelContainer = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.custom_minimum_size = Vector2(170, 120) if not is_day7 else Vector2(0, 96)

	var sb: StyleBoxTexture = StyleBoxTexture.new()
	sb.texture = TEX_DAY_BG
	sb.texture_margin_left = 18.0
	sb.texture_margin_top = 18.0
	sb.texture_margin_right = 18.0
	sb.texture_margin_bottom = 18.0
	sb.content_margin_left = 12.0
	sb.content_margin_top = 10.0
	sb.content_margin_right = 12.0
	sb.content_margin_bottom = 10.0
	panel.add_theme_stylebox_override("panel", sb)

	var day_lbl: Label = Label.new()
	day_lbl.add_theme_font_override("font", _font)
	day_lbl.add_theme_font_size_override("font_size", 15 if not is_day7 else 18)
	day_lbl.add_theme_color_override("font_color", Color(0.75, 0.90, 1.0, 1.0))

	var reward_lbl: Label = Label.new()
	reward_lbl.add_theme_font_override("font", _font)
	reward_lbl.add_theme_font_size_override("font_size", 20 if not is_day7 else 24)
	reward_lbl.add_theme_color_override("font_color", Color(1.0, 0.92, 0.35, 1.0))
	reward_lbl.add_theme_color_override("font_outline_color", Color(0.10, 0.06, 0.0, 1.0))
	reward_lbl.add_theme_constant_override("outline_size", 4)

	var status_lbl: Label = Label.new()
	status_lbl.add_theme_font_override("font", _font)
	status_lbl.add_theme_font_size_override("font_size", 12)
	status_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if not is_day7:
		var vb: VBoxContainer = VBoxContainer.new()
		vb.alignment = BoxContainer.ALIGNMENT_CENTER
		vb.add_theme_constant_override("separation", 4)
		panel.add_child(vb)

		day_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vb.add_child(day_lbl)

		var row: HBoxContainer = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER
		row.add_theme_constant_override("separation", 6)
		vb.add_child(row)

		var coin_icon: TextureRect = TextureRect.new()
		coin_icon.texture = TEX_ICON_COIN
		coin_icon.custom_minimum_size = Vector2(26, 26)
		coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		row.add_child(coin_icon)

		row.add_child(reward_lbl)
		vb.add_child(status_lbl)
	else:
		var hb: HBoxContainer = HBoxContainer.new()
		hb.alignment = BoxContainer.ALIGNMENT_CENTER
		hb.add_theme_constant_override("separation", 18)
		panel.add_child(hb)

		var gift_ic: TextureRect = TextureRect.new()
		gift_ic.texture = TEX_ICON_GIFT
		gift_ic.custom_minimum_size = Vector2(46, 46)
		gift_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		gift_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(gift_ic)

		var mid_vb: VBoxContainer = VBoxContainer.new()
		mid_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		mid_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mid_vb.add_theme_constant_override("separation", 2)
		hb.add_child(mid_vb)

		mid_vb.add_child(day_lbl)

		var rew_hb: HBoxContainer = HBoxContainer.new()
		rew_hb.add_theme_constant_override("separation", 8)
		mid_vb.add_child(rew_hb)

		var c_ic: TextureRect = TextureRect.new()
		c_ic.texture = TEX_ICON_COIN
		c_ic.custom_minimum_size = Vector2(28, 28)
		c_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rew_hb.add_child(c_ic)

		rew_hb.add_child(reward_lbl)

		var h_ic: TextureRect = TextureRect.new()
		h_ic.texture = TEX_ICON_HEART
		h_ic.custom_minimum_size = Vector2(24, 24)
		h_ic.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		h_ic.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rew_hb.add_child(h_ic)

		hb.add_child(status_lbl)

	return {
		"day": day_num,
		"is_day7": is_day7,
		"panel": panel,
		"style": sb,
		"day_lbl": day_lbl,
		"reward_lbl": reward_lbl,
		"status_lbl": status_lbl
	}

func _refresh_ui() -> void:
	if _title_lbl == null:
		return

	_title_lbl.text = tr("DAILY_BONUS_TITLE")
	_subtitle_lbl.text = tr("DAILY_BONUS_SUBTITLE")

	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	var can_claim: bool = true
	var eff_streak: int = 0
	var next_day: int = 1
	if save_mgr != null:
		can_claim = bool(save_mgr.call("can_claim_daily_bonus"))
		eff_streak = int(save_mgr.call("get_daily_bonus_effective_streak"))
		next_day = int(save_mgr.call("get_daily_bonus_next_day"))

	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()

	for card_info: Dictionary in _day_cards:
		var d: int = int(card_info["day"])
		var is_d7: bool = bool(card_info["is_day7"])
		var panel: PanelContainer = card_info["panel"] as PanelContainer
		var sb: StyleBoxTexture = card_info["style"] as StyleBoxTexture
		var d_lbl: Label = card_info["day_lbl"] as Label
		var r_lbl: Label = card_info["reward_lbl"] as Label
		var s_lbl: Label = card_info["status_lbl"] as Label

		var reward_val: int = 50
		if save_mgr != null:
			reward_val = int(save_mgr.call("get_daily_bonus_reward_for_day", d))

		d_lbl.text = tr("DAILY_BONUS_DAY") % d
		if is_d7:
			r_lbl.text = "+%d  %s" % [reward_val, tr("DAILY_BONUS_DAY7_EXTRA")]
		else:
			r_lbl.text = "+%d" % reward_val

		panel.scale = Vector2.ONE
		if d <= eff_streak:
			# Já resgatado neste ciclo
			sb.modulate_color = Color(0.45, 0.95, 0.62, 0.90)
			panel.modulate = Color(1.0, 1.0, 1.0, 0.72)
			s_lbl.text = "✔ " + tr("DAILY_BONUS_CLAIMED")
			s_lbl.add_theme_color_override("font_color", Color(0.35, 1.0, 0.58, 1.0))
		elif can_claim and d == next_day:
			# Disponível hoje!
			sb.modulate_color = Color(1.25, 1.08, 0.42, 1.0)
			panel.modulate = Color.WHITE
			s_lbl.text = "★"
			s_lbl.add_theme_color_override("font_color", Color(1.0, 0.90, 0.25, 1.0))
			panel.pivot_offset = panel.custom_minimum_size * 0.5
			_pulse_tween = create_tween()
			_pulse_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
			_pulse_tween.set_loops()
			_pulse_tween.tween_property(panel, "scale", Vector2(1.04, 1.04), 0.55).set_trans(Tween.TRANS_SINE)
			_pulse_tween.tween_property(panel, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_SINE)
		else:
			# Futuro
			sb.modulate_color = Color(0.65, 0.72, 0.86, 0.78)
			panel.modulate = Color(1.0, 1.0, 1.0, 0.68)
			s_lbl.text = ""

	_update_claim_button_state()

func _update_claim_button_state() -> void:
	if _claim_btn == null:
		return

	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr == null:
		return

	var can_claim: bool = bool(save_mgr.call("can_claim_daily_bonus"))
	if can_claim:
		var next_day: int = int(save_mgr.call("get_daily_bonus_next_day"))
		var reward: int = int(save_mgr.call("get_daily_bonus_reward_for_day", next_day))
		_claim_btn.disabled = false
		_claim_btn.text = tr("DAILY_BONUS_CLAIM") % reward
	else:
		var secs: int = int(save_mgr.call("get_seconds_until_next_daily_bonus"))
		var hrs: int = int(floor(float(secs) / 3600.0))
		var mins: int = int(floor(float(secs % 3600) / 60.0))
		var rem_s: int = secs % 60
		var time_str: String = "%02d:%02d:%02d" % [hrs, mins, rem_s]
		_claim_btn.disabled = true
		_claim_btn.text = tr("DAILY_BONUS_NEXT_IN") % time_str

func _on_claim_pressed() -> void:
	var save_mgr: Node = get_node_or_null("/root/SaveManager")
	if save_mgr == null:
		return

	var res: Dictionary = save_mgr.call("claim_daily_bonus") as Dictionary
	if not bool(res.get("success", false)):
		return

	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr != null and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "buy")

	var game_mgr: Node = get_node_or_null("/root/GameManager")
	if game_mgr != null and game_mgr.has_method("trigger_haptic_cut"):
		game_mgr.call("trigger_haptic_cut")

	var day_num: int = int(res.get("day", 1))
	var coins: int = int(res.get("coins", 0))
	bonus_claimed.emit(day_num, coins)
	_refresh_ui()
