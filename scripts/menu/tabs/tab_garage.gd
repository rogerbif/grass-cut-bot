extends Control

@onready var title_label: Label = $Panel/Scroll/VBox/TitleBar/TitleLabel
@onready var blade_equipped_header: Label = $Panel/Scroll/VBox/BladeBanner/VBox/Title
@onready var blade_tier_label: Label = $Panel/Scroll/VBox/BladeBanner/VBox/TierNameLabel
@onready var coins_label: Label = $Panel/Scroll/VBox/CoinsBanner/CoinsValLabel

@onready var blade_card_name: Label = $Panel/Scroll/VBox/BladeCard/Info/Name
@onready var blade_lvl_label: Label = $Panel/Scroll/VBox/BladeCard/Info/LevelLabel
@onready var blade_buy_btn: Button = $Panel/Scroll/VBox/BladeCard/BuyBtn
@onready var buy_btn_icon: TextureRect = $Panel/Scroll/VBox/BladeCard/BuyBtn/HBox/BtnIcon
@onready var buy_btn_label: Label = $Panel/Scroll/VBox/BladeCard/BuyBtn/HBox/BtnLabel
@onready var tip_label: Label = $Panel/Scroll/VBox/TipLabel

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		refresh_ui()

func _ready() -> void:
	if blade_buy_btn != null:
		blade_buy_btn.pressed.connect(_on_buy_blade_pressed)

	if UpgradeManager != null:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
		UpgradeManager.coins_changed.connect(_on_coins_changed)
		UpgradeManager.blade_level_changed.connect(_on_blade_level_changed)

	refresh_ui()

func refresh_ui() -> void:
	if title_label != null:
		title_label.text = tr("GARAGE_TITLE_HEADER")
	if blade_equipped_header != null:
		blade_equipped_header.text = tr("GARAGE_BANNER_EQUIPPED")
	if blade_card_name != null:
		blade_card_name.text = tr("GARAGE_BLADE_UPGRADE_TITLE")
	if tip_label != null:
		tip_label.text = tr("GARAGE_TIP")

	if UpgradeManager == null:
		return

	if coins_label != null:
		coins_label.text = tr("GARAGE_COINS_FMT") % UpgradeManager.total_coins

	var lvl: int = UpgradeManager.blade_level
	if blade_tier_label != null:
		var tier_name: String = UpgradeManager.get_blade_tier_name()
		var tier_num: int = UpgradeManager.get_blade_tier()
		if lvl >= 10:
			blade_tier_label.text = tr("GARAGE_TIER_MAX_FMT") % [tier_name, tier_num]
		else:
			blade_tier_label.text = tr("GARAGE_TIER_FMT") % [tier_name, tier_num]

	if blade_lvl_label != null and blade_buy_btn != null:
		var radius: float = UpgradeManager.get_blade_radius()
		var speed: float = UpgradeManager.get_cutter_speed()

		if lvl >= 10:
			blade_lvl_label.text = tr("GARAGE_STATS_MAX_FMT") % [radius, speed]
			if buy_btn_label != null:
				buy_btn_label.text = tr("UPGRADE_MAX_LEVEL")
			if buy_btn_icon != null:
				buy_btn_icon.texture = preload("res://assets/icons/icon_checkmark.svg")
				buy_btn_icon.visible = true
			blade_buy_btn.disabled = true
		elif lvl >= 8:
			blade_lvl_label.text = tr("GARAGE_STATS_INGAME_FMT") % [lvl, radius, speed]
			if buy_btn_label != null:
				buy_btn_label.text = tr("GARAGE_BTN_STORE_MAX")
			if buy_btn_icon != null:
				buy_btn_icon.visible = false
			blade_buy_btn.disabled = true
		else:
			var cost: int = UpgradeManager.get_blade_upgrade_cost()
			var next_radius: float = 0.90 + float(lvl) * (0.50 / 9.0)
			var next_speed: float = 1.95 + float(lvl) * 0.18
			blade_lvl_label.text = tr("GARAGE_STATS_NEXT_FMT") % [lvl, lvl + 1, next_radius, next_speed]
			if buy_btn_label != null:
				buy_btn_label.text = "%d" % cost
			if buy_btn_icon != null:
				buy_btn_icon.texture = preload("res://assets/icons/icon_coin.svg")
				buy_btn_icon.visible = true
			blade_buy_btn.disabled = (UpgradeManager.total_coins < cost)

func _on_buy_blade_pressed() -> void:
	if UpgradeManager != null:
		if UpgradeManager.buy_blade_upgrade():
			refresh_ui()
			if GameManager != null:
				GameManager.trigger_haptic_cut()

func _on_upgrade_purchased(_u_name: String, _new_lvl: int) -> void:
	refresh_ui()

func _on_blade_level_changed(_new_lvl: int, _is_max: bool) -> void:
	refresh_ui()

func _on_coins_changed(_new_val: int) -> void:
	refresh_ui()
