extends Button
class_name CyberToggleButton

## Botão Arcade/Cyber estilizado para alternar visualização (Mapa/Bot) na Home.
## Reproduz a estética com corte angular à esquerda, ponta chevron à direita,
## base 3D azul cobalto com compressão mecânica tátil e moldura cyber estática.

@onready var bg_normal: TextureRect = $BgNormal
@onready var bg_pressed: TextureRect = $BgPressed
@onready var hbox_toggle: HBoxContainer = $HBoxToggle
@onready var toggle_label: Label = $HBoxToggle/ToggleLabel
@onready var toggle_icon: TextureRect = $HBoxToggle/ToggleIcon

const PRESS_SINK_OFFSET: float = 7.0

var is_down: bool = false

func _ready() -> void:
	button_down.connect(_on_btn_down)
	button_up.connect(_on_btn_up)
	pressed.connect(_on_btn_pressed)
	
	if bg_normal != null:
		bg_normal.visible = true
	if bg_pressed != null:
		bg_pressed.visible = false

func set_toggle_text(new_text: String) -> void:
	if toggle_label != null:
		toggle_label.text = new_text

func set_toggle_icon(tex: Texture2D) -> void:
	if toggle_icon != null:
		toggle_icon.texture = tex
		toggle_icon.visible = (tex != null)

func _on_btn_down() -> void:
	is_down = true
	if bg_normal != null:
		bg_normal.visible = false
	if bg_pressed != null:
		bg_pressed.visible = true
	if hbox_toggle != null:
		hbox_toggle.position.y += PRESS_SINK_OFFSET

func _on_btn_up() -> void:
	if not is_down:
		return
	is_down = false
	if bg_normal != null:
		bg_normal.visible = true
	if bg_pressed != null:
		bg_pressed.visible = false
	if hbox_toggle != null:
		hbox_toggle.position.y -= PRESS_SINK_OFFSET

func _on_btn_pressed() -> void:
	# Mandamento 8: Feedback Háptico e Sensorial Contínuo
	Input.vibrate_handheld(15)
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
