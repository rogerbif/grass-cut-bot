extends Button
class_name CyberNavButton

## Botão modular para a Navbar no estilo Cyber Arcade do Grass Cut Bot.
## É um componente Molecule no padrão Atomic Design: possui badge elevado,
## indicador neon e transição suave de estado ativo/inativo.

signal nav_button_pressed(tab_id: int)

@export var tab_id: int = 0
@export var title_text: String = "Home":
	set(val):
		title_text = val
		if label_title != null:
			label_title.text = val

@export var icon_texture: Texture2D:
	set(val):
		icon_texture = val
		if icon_rect != null:
			icon_rect.texture = val

@onready var active_badge: TextureRect = $ActiveBadge
@onready var content_box: VBoxContainer = $Content
@onready var icon_rect: TextureRect = $Content/Icon
@onready var label_title: Label = $Content/Label
@onready var active_indicator: TextureRect = $ActiveIndicator

const COLOR_ACTIVE: Color = Color(0.055, 0.98, 1.0, 1.0)   ## #0efaff (Ciano neon vibrante)
const COLOR_INACTIVE: Color = Color(0.42, 0.55, 0.72, 0.9)  ## #6b8cb8 (Azul-aço suave)
const SCALE_ACTIVE: Vector2 = Vector2(1.06, 1.06)
const SCALE_INACTIVE: Vector2 = Vector2(1.0, 1.0)
const TWEEN_DURATION: float = 0.18

var is_active: bool = false
var _current_tween: Tween = null

func _ready() -> void:
	focus_mode = FOCUS_NONE
	if icon_texture != null and icon_rect != null:
		icon_rect.texture = icon_texture
	if label_title != null:
		label_title.text = title_text
	pressed.connect(_on_pressed)
	set_active(is_active, false)

func set_active(active: bool, animated: bool = true) -> void:
	is_active = active
	if active_badge != null:
		active_badge.visible = active
	if active_indicator != null:
		active_indicator.visible = active

	var target_color: Color = COLOR_ACTIVE if active else COLOR_INACTIVE
	var target_scale: Vector2 = SCALE_ACTIVE if active else SCALE_INACTIVE

	if _current_tween != null and _current_tween.is_valid():
		_current_tween.kill()

	if animated and is_inside_tree():
		_current_tween = create_tween().set_parallel(true)
		_current_tween.tween_property(content_box, "modulate", target_color, TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_current_tween.tween_property(content_box, "scale", target_scale, TWEEN_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	else:
		if content_box != null:
			content_box.modulate = target_color
			content_box.scale = target_scale

func _on_pressed() -> void:
	# Mandamento 8: Feedback Háptico e Sensorial Contínuo
	Input.vibrate_handheld(15)
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	nav_button_pressed.emit(tab_id)
