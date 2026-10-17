extends Node3D

const EDITOR_SCENE_PATH: String = "res://scenes/editor/level_editor.tscn"

@onready var joystick: Control = $CanvasLayer/FloatingJoystick
@onready var cutter: CharacterBody3D = $LevelController/Cutter
@onready var canvas_layer: CanvasLayer = $CanvasLayer

func _ready() -> void:
	if joystick and cutter:
		joystick.joystick_moved.connect(_on_joystick_moved)

	if not OS.has_feature("mobile") and not OS.has_feature("android") and ResourceLoader.exists(EDITOR_SCENE_PATH):
		_create_pc_dev_editor_button()

func _on_joystick_moved(direction: Vector2) -> void:
	if cutter:
		cutter.set_input_direction(direction)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		var ke: InputEventKey = event as InputEventKey
		if ke.pressed and not ke.echo and ke.keycode == KEY_F2:
			_open_level_editor()

func _create_pc_dev_editor_button() -> void:
	if canvas_layer == null:
		return
	var btn: Button = Button.new()
	btn.name = "DevEditorBtn"
	btn.text = "🛠️ Editor [F2]"
	btn.focus_mode = Control.FOCUS_NONE
	btn.custom_minimum_size = Vector2(138, 38)
	btn.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	btn.offset_left = -152
	btn.offset_top = -50
	btn.offset_right = -14
	btn.offset_bottom = -12

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.14, 0.20, 0.88)
	style.border_color = Color(0.35, 0.85, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_font_size_override("font_size", 14)
	btn.add_theme_color_override("font_color", Color(0.85, 0.96, 1.0))
	btn.pressed.connect(_open_level_editor)
	canvas_layer.add_child(btn)

func _open_level_editor() -> void:
	if not OS.has_feature("mobile") and not OS.has_feature("android") and ResourceLoader.exists(EDITOR_SCENE_PATH):
		get_tree().paused = false
		get_tree().change_scene_to_file(EDITOR_SCENE_PATH)
