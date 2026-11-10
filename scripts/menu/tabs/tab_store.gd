extends Control

const ICON_HEART: Texture2D = preload("res://assets/icons/icon_heart.svg")
const ICON_COIN: Texture2D = preload("res://assets/icons/icon_coin.svg")
const TEX_CARD_BG: Texture2D = preload("res://assets/ui/collection/card_species_bg.svg")
const TEX_BTN_BG: Texture2D = preload("res://assets/ui/collection/btn_claim_cyber.svg")

const LIFE_REFILL_COST: int = 1000

@onready var scroll_vbox: VBoxContainer = $Panel/Scroll/VBox
@onready var title_label: Label = $Panel/Scroll/VBox/Title
@onready var welcome_header: Label = $Panel/Scroll/VBox/BannerPack/VBox/Header
@onready var welcome_desc: Label = $Panel/Scroll/VBox/BannerPack/VBox/Desc
@onready var buy_pack_btn: Button = $Panel/Scroll/VBox/BannerPack/VBox/BuyBtn

@onready var coins_section_label: Label = $Panel/Scroll/VBox/CoinsSectionLabel
@onready var pack1_name: Label = $Panel/Scroll/VBox/Pack1/HBox/Info/Name
@onready var pack1_btn: Button = $Panel/Scroll/VBox/Pack1/HBox/Btn
@onready var pack2_name: Label = $Panel/Scroll/VBox/Pack2/HBox/Info/Name
@onready var pack2_btn: Button = $Panel/Scroll/VBox/Pack2/HBox/Btn

var _is_pack_claimed: bool = false
var _lives_card: PanelContainer = null
var _lives_title_lbl: Label = null
var _lives_status_lbl: Label = null
var _buy_lives_btn: Button = null
var _timer_accum: float = 0.0

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_texts()

func _ready() -> void:
	if buy_pack_btn != null:
		buy_pack_btn.pressed.connect(_on_free_pack_pressed)
	_build_lives_refill_card()
	if SaveManager != null and SaveManager.has_signal("lives_changed"):
		SaveManager.lives_changed.connect(func(_c: int, _m: int) -> void: _update_lives_card())
	if UpgradeManager != null:
		UpgradeManager.coins_changed.connect(func(_c: int) -> void: _update_lives_card())
	_refresh_texts()

func _process(delta: float) -> void:
	if not visible:
		return
	_timer_accum += delta
	if _timer_accum >= 1.0:
		_timer_accum = 0.0
		_update_lives_card()

func refresh_ui() -> void:
	_refresh_texts()
	_update_lives_card()

func _build_lives_refill_card() -> void:
	if scroll_vbox == null or _lives_card != null:
		return

	_lives_card = PanelContainer.new()
	_lives_card.name = "LivesRefillCard"
	var card_sb: StyleBoxTexture = StyleBoxTexture.new()
	card_sb.texture = TEX_CARD_BG
	card_sb.texture_margin_left = 20.0
	card_sb.texture_margin_top = 20.0
	card_sb.texture_margin_right = 20.0
	card_sb.texture_margin_bottom = 20.0
	card_sb.content_margin_left = 16.0
	card_sb.content_margin_top = 14.0
	card_sb.content_margin_right = 16.0
	card_sb.content_margin_bottom = 14.0
	card_sb.modulate_color = Color(1.12, 0.90, 0.96, 1.0)
	_lives_card.add_theme_stylebox_override("panel", card_sb)

	var hbox: HBoxContainer = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	_lives_card.add_child(hbox)

	var icon_rect: TextureRect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(40, 40)
	icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	icon_rect.texture = ICON_HEART
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hbox.add_child(icon_rect)

	var info_vbox: VBoxContainer = VBoxContainer.new()
	info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_vbox.add_theme_constant_override("separation", 4)
	hbox.add_child(info_vbox)

	_lives_title_lbl = Label.new()
	_lives_title_lbl.add_theme_font_size_override("font_size", 17)
	_lives_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.45, 0.55, 1.0))
	info_vbox.add_child(_lives_title_lbl)

	_lives_status_lbl = Label.new()
	_lives_status_lbl.add_theme_font_size_override("font_size", 13)
	_lives_status_lbl.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0, 1.0))
	info_vbox.add_child(_lives_status_lbl)

	_buy_lives_btn = Button.new()
	_buy_lives_btn.custom_minimum_size = Vector2(124, 44)
	_buy_lives_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_buy_lives_btn.focus_mode = Control.FOCUS_NONE
	_buy_lives_btn.add_theme_constant_override("icon_max_width", 20)
	_buy_lives_btn.pressed.connect(_on_buy_lives_pressed)
	hbox.add_child(_buy_lives_btn)

	scroll_vbox.add_child(_lives_card)
	# Posiciona logo após o BannerPack (índice 2)
	scroll_vbox.move_child(_lives_card, mini(2, scroll_vbox.get_child_count() - 1))

func _update_lives_card() -> void:
	if _lives_card == null:
		return
	var cur_lives: int = 5
	var secs_next: int = 0
	if SaveManager != null:
		if SaveManager.has_method("get_lives"):
			cur_lives = SaveManager.get_lives()
		if SaveManager.has_method("get_seconds_to_next_life"):
			secs_next = SaveManager.get_seconds_to_next_life()

	if _lives_title_lbl != null:
		_lives_title_lbl.text = tr("STORE_REFILL_LIVES_TITLE")

	if _lives_status_lbl != null:
		if cur_lives >= 5:
			_lives_status_lbl.text = tr("LIVES_FULL")
		else:
			var mins: int = floori(float(secs_next) / 60.0)
			var secs: int = secs_next % 60
			_lives_status_lbl.text = tr("STORE_LIVES_REGEN_FMT") % [cur_lives, 5, mins, secs]

	if _buy_lives_btn != null:
		if cur_lives >= 5:
			_buy_lives_btn.icon = null
			_buy_lives_btn.text = "5 / 5"
			_buy_lives_btn.disabled = true
		else:
			_buy_lives_btn.icon = ICON_COIN
			_buy_lives_btn.text = str(LIFE_REFILL_COST)
			var can_afford: bool = (UpgradeManager != null and UpgradeManager.total_coins >= LIFE_REFILL_COST)
			_buy_lives_btn.disabled = not can_afford

func _on_buy_lives_pressed() -> void:
	if SaveManager == null or UpgradeManager == null:
		return
	if SaveManager.get_lives() >= 5:
		return
	if UpgradeManager.spend_coins(LIFE_REFILL_COST):
		SaveManager.refill_lives_full()
		_update_lives_card()
		if AudioManager != null:
			AudioManager.play_sfx("buy")
			AudioManager.play_sfx("power_up")
		if GameManager != null:
			GameManager.trigger_haptic_cut()
	else:
		if AudioManager != null:
			AudioManager.play_sfx("denied")

func _refresh_texts() -> void:
	if title_label != null:
		title_label.text = tr("STORE_TITLE")
	if welcome_header != null:
		welcome_header.text = tr("STORE_WELCOME_HEADER")
	if welcome_desc != null:
		welcome_desc.text = tr("STORE_WELCOME_DESC")
	if coins_section_label != null:
		coins_section_label.text = tr("STORE_COIN_PACKS_SECTION")
	if pack1_name != null:
		pack1_name.text = tr("STORE_PACK_BAG_TITLE")
	if pack1_btn != null:
		pack1_btn.text = tr("STORE_COMING_SOON")
	if pack2_name != null:
		pack2_name.text = tr("STORE_PACK_CHEST_TITLE")
	if pack2_btn != null:
		pack2_btn.text = tr("STORE_COMING_SOON")

	if buy_pack_btn != null:
		if _is_pack_claimed:
			buy_pack_btn.text = tr("STORE_CLAIMED")
		else:
			buy_pack_btn.text = tr("STORE_CLAIM_FREE")

	_update_lives_card()

func _on_free_pack_pressed() -> void:
	if UpgradeManager != null:
		UpgradeManager.add_coins(250)
		_is_pack_claimed = true
		if buy_pack_btn != null:
			buy_pack_btn.text = tr("STORE_CLAIMED")
			buy_pack_btn.icon = preload("res://assets/icons/icon_checkmark.svg")
			buy_pack_btn.disabled = true
		_update_lives_card()
		if AudioManager != null:
			AudioManager.play_sfx("buy")
		if GameManager != null:
			GameManager.trigger_haptic_cut()
