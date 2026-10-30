extends PanelContainer
class_name CyberResourceBadge

## Badge de Recurso (Moedas / Vidas) para a TopBar no padrão Atomic Design.
## Apresenta fundo chamfrado cyber, ícone do recurso, texto quantitativo e
## um botão de '+' integrado que navega para a loja ao ser clicado.

signal plus_pressed

@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		if icon_rect != null:
			icon_rect.texture = val

@export var bg_texture: Texture2D:
	set(val):
		bg_texture = val
		if bg_rect != null:
			bg_rect.texture = val

@export var initial_text: String = "0":
	set(val):
		initial_text = val
		if value_label != null:
			value_label.text = val

@onready var bg_rect: TextureRect = $Background
@onready var icon_rect: TextureRect = $Margin/HBox/Icon
@onready var value_label: Label = $Margin/HBox/ValueLabel
@onready var btn_plus: TextureButton = $Margin/HBox/BtnPlus

func _ready() -> void:
	if icon_texture != null and icon_rect != null:
		icon_rect.texture = icon_texture
	if bg_texture != null and bg_rect != null:
		bg_rect.texture = bg_texture
	if value_label != null:
		value_label.text = initial_text

	if btn_plus != null:
		btn_plus.pressed.connect(_on_plus_pressed)

func set_value_text(new_text: String) -> void:
	if value_label != null:
		value_label.text = new_text

func _on_plus_pressed() -> void:
	Input.vibrate_handheld(15)
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	plus_pressed.emit()
