extends Control

@onready var blade_tier_label: Label = $Panel/Scroll/VBox/BladeBanner/VBox/TierNameLabel
@onready var coins_label: Label = $Panel/Scroll/VBox/CoinsBanner/CoinsValLabel

@onready var blade_lvl_label: Label = $Panel/Scroll/VBox/BladeCard/Info/LevelLabel
@onready var blade_buy_btn: Button = $Panel/Scroll/VBox/BladeCard/BuyBtn

func _ready() -> void:
	if blade_buy_btn != null:
		blade_buy_btn.pressed.connect(_on_buy_blade_pressed)

	if UpgradeManager != null:
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
		UpgradeManager.coins_changed.connect(_on_coins_changed)
		UpgradeManager.blade_level_changed.connect(_on_blade_level_changed)

	refresh_ui()

func refresh_ui() -> void:
	if UpgradeManager == null:
		return

	if coins_label != null:
		coins_label.text = "%d Moedas" % UpgradeManager.total_coins

	var lvl: int = UpgradeManager.blade_level
	if blade_tier_label != null:
		var tier_name: String = UpgradeManager.get_blade_tier_name()
		var tier_num: int = UpgradeManager.get_blade_tier()
		if lvl >= 6:
			blade_tier_label.text = "Lâmina Atual: %s (Tier %d - MAX)" % [tier_name, tier_num]
		else:
			blade_tier_label.text = "Lâmina Atual: %s (Tier %d)" % [tier_name, tier_num]

	if blade_lvl_label != null and blade_buy_btn != null:
		var radius: float = UpgradeManager.get_blade_radius()
		var speed: float = UpgradeManager.get_cutter_speed()

		if lvl >= 6:
			blade_lvl_label.text = "Nível MAX (6) • Raio: %.2fm • Vel: %.2fm/s" % [radius, speed]
			blade_buy_btn.text = "MAX"
			blade_buy_btn.icon = preload("res://assets/icons/icon_checkmark.svg")
			blade_buy_btn.disabled = true
		elif lvl >= 5:
			blade_lvl_label.text = "Nível %d • Raio: %.2fm • Vel: %.2fm/s\n(Próximo nível somente por corte na partida)" % [lvl, radius, speed]
			blade_buy_btn.text = "MÁX LOJA"
			blade_buy_btn.icon = null
			blade_buy_btn.disabled = true
		else:
			var cost: int = UpgradeManager.get_blade_upgrade_cost()
			blade_lvl_label.text = "Nível %d -> %d • Raio: %.2fm • Vel: %.2fm/s" % [lvl, lvl + 1, radius + 0.10, speed + 0.30]
			blade_buy_btn.text = "%d" % cost
			blade_buy_btn.icon = preload("res://assets/icons/icon_coin.svg")
			blade_buy_btn.add_theme_constant_override("icon_max_width", 20)
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
