extends Control

@onready var buy_pack_btn: Button = $Panel/Scroll/VBox/BannerPack/VBox/BuyBtn

func _ready() -> void:
	if buy_pack_btn != null:
		buy_pack_btn.pressed.connect(_on_free_pack_pressed)

func _on_free_pack_pressed() -> void:
	if UpgradeManager != null:
		UpgradeManager.add_coins(250)
		buy_pack_btn.text = "COLETADO ✔"
		buy_pack_btn.disabled = true
		if GameManager != null:
			GameManager.trigger_haptic_cut()
