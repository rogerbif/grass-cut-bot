extends Button
class_name CyberResourceBadge

## Badge de Recurso (Moedas / Vidas) para a TopBar no padrão Atomic Design.
## O card externo unificado atua como a área de toque completa, apresentando fundo
## chanfrado cyber, ícone do recurso, texto quantitativo e o símbolo '+' integrado.
## Ao ser pressionado, oferece feedback háptico, sonoro e elástico, navegando para a Loja.

signal plus_pressed
signal badge_pressed

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
@onready var plus_icon: TextureRect = $Margin/HBox.get_node_or_null("PlusIcon") as TextureRect

var _is_down: bool = false

func _ready() -> void:
	focus_mode = Control.FOCUS_NONE
	flat = true

	if icon_texture != null and icon_rect != null:
		icon_rect.texture = icon_texture
	if bg_texture != null and bg_rect != null:
		bg_rect.texture = bg_texture
	if value_label != null:
		value_label.text = initial_text

	button_down.connect(_on_btn_down)
	button_up.connect(_on_btn_up)
	pressed.connect(_on_btn_pressed)

func _pressed() -> void:
	_on_btn_pressed()

func set_value_text(new_text: String) -> void:
	if value_label != null:
		value_label.text = new_text

func _on_btn_down() -> void:
	_is_down = true
	pivot_offset = size * 0.5
	modulate = Color(0.85, 0.90, 1.0, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(0.96, 0.96), 0.05).set_trans(Tween.TRANS_SINE)

func _on_btn_up() -> void:
	if not _is_down:
		return
	_is_down = false
	modulate = Color(1.0, 1.0, 1.0, 1.0)
	var tw: Tween = create_tween()
	tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_btn_pressed() -> void:
	Input.vibrate_handheld(15)
	var audio_mgr: Node = get_node_or_null("/root/AudioManager")
	if audio_mgr != null and audio_mgr.has_method("play_sfx"):
		audio_mgr.call("play_sfx", "confirm")
	plus_pressed.emit()
	badge_pressed.emit()
