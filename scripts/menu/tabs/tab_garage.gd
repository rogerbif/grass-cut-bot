extends Control

@onready var blade_tier_label: Label = $Panel/Scroll/VBox/BladeBanner/VBox/TierNameLabel
@onready var coins_label: Label = $Panel/Scroll/VBox/CoinsBanner/CoinsValLabel

@onready var radius_lvl_label: Label = $Panel/Scroll/VBox/RadiusCard/Info/LevelLabel
@onready var radius_buy_btn: Button = $Panel/Scroll/VBox/RadiusCard/BuyBtn

@onready var power_lvl_label: Label = $Panel/Scroll/VBox/PowerCard/Info/LevelLabel
@onready var power_buy_btn: Button = $Panel/Scroll/VBox/PowerCard/BuyBtn

@onready var speed_lvl_label: Label = $Panel/Scroll/VBox/SpeedCard/Info/LevelLabel
@onready var speed_buy_btn: Button = $Panel/Scroll/VBox/SpeedCard/BuyBtn

@onready var mult_lvl_label: Label = $Panel/Scroll/VBox/MultCard/Info/LevelLabel
@onready var mult_buy_btn: Button = $Panel/Scroll/VBox/MultCard/BuyBtn

func _ready() -> void:
	if radius_buy_btn != null:
		radius_buy_btn.pressed.connect(func() -> void: _try_buy("radius"))
	if power_buy_btn != null:
		power_buy_btn.pressed.connect(func() -> void: _try_buy("power"))
	if speed_buy_btn != null:
		speed_buy_btn.pressed.connect(func() -> void: _try_buy("speed"))
	if mult_buy_btn != null:
		mult_buy_btn.pressed.connect(func() -> void: _try_buy("multiplier"))

	if UpgradeManager != null:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
		UpgradeManager.coins_changed.connect(_on_coins_changed)

	refresh_ui()

func refresh_ui() -> void:
	if UpgradeManager == null:
		return

	if coins_label != null:
		coins_label.text = "%d Moedas" % UpgradeManager.total_coins

	if blade_tier_label != null:
		blade_tier_label.text = "Lâmina Atual: %s (Tier %d)" % [UpgradeManager.get_blade_tier_name(), UpgradeManager.get_blade_tier()]

	_update_card("radius", radius_lvl_label, radius_buy_btn, "+0.10m Raio")
	_update_card("power", power_lvl_label, power_buy_btn, "+1 Dano/Golpe")
	_update_card("speed", speed_lvl_label, speed_buy_btn, "+0.45m/s Vel.")
	_update_card("multiplier", mult_lvl_label, mult_buy_btn, "+1x Moedas")

func _update_card(upgrade_name: String, lvl_lbl: Label, btn: Button, stat_bonus: String) -> void:
	if lvl_lbl == null or btn == null or UpgradeManager == null:
		return

	var lvl: int = UpgradeManager.get_level(upgrade_name)
	var cost: int = UpgradeManager.get_upgrade_cost(upgrade_name)
	lvl_lbl.text = "Nível %d  •  %s" % [lvl, stat_bonus]
	btn.text = "%d 🪙" % cost
	btn.disabled = (UpgradeManager.total_coins < cost)

func _try_buy(upgrade_name: String) -> void:
	if UpgradeManager != null:
		if UpgradeManager.buy_upgrade(upgrade_name):
			refresh_ui()
			if GameManager != null:
				GameManager.trigger_haptic_cut()

func _on_upgrade_purchased(_u_name: String, _new_lvl: int) -> void:
	refresh_ui()

func _on_coins_changed(_new_val: int) -> void:
	refresh_ui()
