extends Button
class_name CyberPlayButton

## Botão Arcade/Cyber estilizado para a tela Home do Grass Cut Bot.
## Reproduz a estética com corte angular à esquerda, ponta chevron à direita,
## base 3D extrudada com compressão mecânica tátil e feedback háptico.

@onready var bg_normal: TextureRect = $BgNormal
@onready var bg_pressed: TextureRect = $BgPressed
@onready var hbox_play: HBoxContainer = $HBoxPlay
@onready var level_label: Label = $HBoxPlay/LevelLabel
@onready var play_icon: TextureRect = $HBoxPlay/PlayIcon

var is_down: bool = false

func _ready() -> void:
	button_down.connect(_on_btn_down)
	button_up.connect(_on_btn_up)
	pressed.connect(_on_btn_pressed)
	
	if bg_normal != null:
		bg_normal.visible = true
	if bg_pressed != null:
		bg_pressed.visible = false

func set_level_text(new_text: String) -> void:
	if level_label != null:
		level_label.text = new_text

func set_level_number(lvl: int) -> void:
	if level_label != null:
		level_label.text = "JOGAR - Fase %d" % lvl

func _on_btn_down() -> void:
	is_down = true
	if bg_normal != null:
		bg_normal.visible = false
	if bg_pressed != null:
		bg_pressed.visible = true
	if hbox_play != null:
		hbox_play.position.y += 4.0

func _on_btn_up() -> void:
	if not is_down:
		return
	is_down = false
	if bg_normal != null:
		bg_normal.visible = true
	if bg_pressed != null:
		bg_pressed.visible = false
	if hbox_play != null:
		hbox_play.position.y -= 4.0

func _on_btn_pressed() -> void:
	# Mandamento 8: Feedback Háptico e Sensorial Contínuo
	Input.vibrate_handheld(15)
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
