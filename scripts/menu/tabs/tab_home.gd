extends Control

signal play_level_requested(level_number: int)
signal toggle_view_requested

@onready var play_btn: Button = $BottomAction/HBox/PlayBtn as Button
@onready var play_label: Label = $BottomAction/HBox/PlayBtn/HBoxPlay/LevelLabel
@onready var toggle_btn: Button = $BottomAction/HBox/ToggleViewBtn
@onready var toggle_label: Label = $BottomAction/HBox/ToggleViewBtn/HBoxToggle/ToggleLabel
@onready var toggle_icon: TextureRect = $BottomAction/HBox/ToggleViewBtn/HBoxToggle/ToggleIcon

const ICON_PLAY: Texture2D = preload("res://assets/icons/icon_play.svg")
const ICON_MAP: Texture2D = preload("res://assets/icons/icon_map_banner.svg")

var current_level_selected: int = 1
var is_map_mode: bool = false

func _ready() -> void:
	if play_btn != null:
		play_btn.pressed.connect(_on_play_pressed)
	if toggle_btn != null:
		toggle_btn.pressed.connect(_on_toggle_pressed)
	update_level_display(current_level_selected)

func update_level_display(lvl: int) -> void:
	current_level_selected = lvl
	if play_btn != null and play_btn.has_method("set_level_number"):
		play_btn.call("set_level_number", current_level_selected)
	elif play_label != null:
		play_label.text = "JOGAR - Fase %d" % current_level_selected

func set_view_mode(map_view: bool) -> void:
	is_map_mode = map_view
	if toggle_label != null and toggle_icon != null:
		if is_map_mode:
			toggle_icon.visible = false
			toggle_label.text = "BOT"
		else:
			toggle_icon.visible = true
			toggle_icon.texture = ICON_MAP
			toggle_label.text = "MAPA"
	update_level_display(current_level_selected)

func _on_play_pressed() -> void:
	# Efeito de pulso rápido no botão
	if play_btn != null:
		var tw: Tween = create_tween()
		tw.tween_property(play_btn, "scale", Vector2(0.96, 0.96), 0.08)
		tw.tween_property(play_btn, "scale", Vector2(1.0, 1.0), 0.08)
	play_level_requested.emit(current_level_selected)

func _on_toggle_pressed() -> void:
	if AudioManager != null:
		AudioManager.play_sfx("confirm")
	toggle_view_requested.emit()
