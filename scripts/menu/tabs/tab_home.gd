extends Control

signal play_level_requested(level_number: int)
signal toggle_view_requested

@onready var play_btn: Button = $BottomAction/HBox/PlayBtn
@onready var toggle_btn: Button = $BottomAction/HBox/ToggleViewBtn

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
	if play_btn != null:
		if is_map_mode:
			play_btn.text = "JOGAR - Fase %d ▶" % current_level_selected
		else:
			play_btn.text = "Level %d ▶" % current_level_selected

func set_view_mode(map_view: bool) -> void:
	is_map_mode = map_view
	if toggle_btn != null:
		if is_map_mode:
			toggle_btn.text = "🤖 BOT"
		else:
			toggle_btn.text = "🗺️ MAP"
	update_level_display(current_level_selected)

func _on_play_pressed() -> void:
	# Efeito de pulso rápido no botão
	if play_btn != null:
		var tw: Tween = create_tween()
		tw.tween_property(play_btn, "scale", Vector2(0.94, 0.94), 0.08)
		tw.tween_property(play_btn, "scale", Vector2(1.0, 1.0), 0.08)
	play_level_requested.emit(current_level_selected)

func _on_toggle_pressed() -> void:
	toggle_view_requested.emit()
