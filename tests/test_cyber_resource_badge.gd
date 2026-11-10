extends Node

func _ready() -> void:
	print("--- TESTE AUTOMATIZADO: CYBER RESOURCE BADGE ---")
	var badge_scene: PackedScene = load("res://scenes/ui/cyber_resource_badge.tscn")
	assert(badge_scene != null, "Falha ao carregar cyber_resource_badge.tscn")

	var badge: Control = badge_scene.instantiate() as Control
	assert(badge != null, "Falha ao instanciar badge")
	assert(badge is Button, "Badge deve estender Button")

	add_child(badge)
	if not badge.is_node_ready():
		await badge.ready

	var result: Dictionary = {"plus": false, "badge": false}
	badge.connect("plus_pressed", func() -> void: result["plus"] = true)
	badge.connect("badge_pressed", func() -> void: result["badge"] = true)

	# Simula clique no botão unificado
	(badge as Button).emit_signal("pressed")

	assert(result["plus"], "plus_pressed deve ser emitido no clique")
	assert(result["badge"], "badge_pressed deve ser emitido no clique")

	# Testa set_value_text
	if badge.has_method("set_value_text"):
		badge.call("set_value_text", "9999")
		var val_label: Label = badge.get_node_or_null("Margin/HBox/ValueLabel") as Label
		assert(val_label != null and val_label.text == "9999", "ValueLabel deve exibir 9999")

	# Testa que PlusIcon existe e não é mais TextureButton com container
	var plus_icon: TextureRect = badge.get_node_or_null("Margin/HBox/PlusIcon") as TextureRect
	assert(plus_icon != null, "PlusIcon deve existir como TextureRect integrado")
	assert(badge.get_node_or_null("Margin/HBox/BtnPlus") == null, "BtnPlus legado deve ter sido removido")

	badge.queue_free()
	print("✔ TODOS OS TESTES DO CYBER RESOURCE BADGE PASSARAM COM SUCESSO!")
	get_tree().quit(0)
