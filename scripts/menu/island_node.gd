extends Node3D

signal island_selected(level_number: int)

@export var level_number: int = 1
@export var is_unlocked: bool = true
@export var stars_earned: int = 0 # 0 a 3

@onready var bot_anchor: Marker3D = $BotAnchor
@onready var pin_root: Node3D = $PinPoint
@onready var level_label: Label3D = $PinPoint/LevelLabel
@onready var stars_label: Label3D = $PinPoint/StarsLabel
@onready var status_badge: MeshInstance3D = $PinPoint/BadgeMesh

var is_hovered: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	update_visuals()

func _process(delta: float) -> void:
	time_passed += delta
	# Flutuação e pulso suave no pino da fase
	if pin_root != null:
		pin_root.position.y = 1.35 + sin(time_passed * 2.8 + level_number) * 0.08

func setup_island(lvl: int, unlocked: bool, stars: int) -> void:
	level_number = lvl
	is_unlocked = unlocked
	stars_earned = stars
	update_visuals()

func update_visuals() -> void:
	if level_label == null or stars_label == null:
		return

	if is_unlocked:
		level_label.text = str(level_number)
		if stars_earned > 0:
			var stars_str: String = ""
			for i in range(stars_earned):
				stars_str += "⭐"
			stars_label.text = stars_str
			stars_label.visible = true
		else:
			stars_label.text = "ATUAL"
			stars_label.visible = true
	else:
		level_label.text = "🔒"
		stars_label.visible = false

	# Cor do badge
	if status_badge != null:
		var mat: StandardMaterial3D = status_badge.get_active_material(0) as StandardMaterial3D
		if mat != null:
			var new_mat: StandardMaterial3D = mat.duplicate() as StandardMaterial3D
			if is_unlocked:
				new_mat.albedo_color = Color(0.2, 0.6, 0.95, 1.0) # Azul vibrante
			else:
				new_mat.albedo_color = Color(0.5, 0.55, 0.6, 1.0) # Cinza bloqueado
			status_badge.material_override = new_mat

func set_pin_visible(is_vis: bool) -> void:
	if pin_root != null:
		pin_root.visible = is_vis

func get_bot_position() -> Vector3:
	if bot_anchor != null:
		return bot_anchor.global_position
	return global_position + Vector3(0, 0.2, 0)

func _on_click_area_input_event(_camera: Camera3D, event: InputEvent, _event_position: Vector3, _normal: Vector3, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed:
			island_selected.emit(level_number)
