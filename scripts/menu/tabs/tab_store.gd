extends Control

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

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_refresh_texts()

func _ready() -> void:
	if buy_pack_btn != null:
		buy_pack_btn.pressed.connect(_on_free_pack_pressed)
	_refresh_texts()

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

func _on_free_pack_pressed() -> void:
	if UpgradeManager != null:
		UpgradeManager.add_coins(250)
		_is_pack_claimed = true
		if buy_pack_btn != null:
			buy_pack_btn.text = tr("STORE_CLAIMED")
			buy_pack_btn.icon = preload("res://assets/icons/icon_checkmark.svg")
			buy_pack_btn.disabled = true
		if AudioManager != null:
			AudioManager.play_sfx("buy")
		if GameManager != null:
			GameManager.trigger_haptic_cut()
