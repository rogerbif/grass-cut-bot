class_name BladeProgressBar
extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var progress_bar: TextureProgressBar = $SubViewport/Control/TextureProgressBar
@onready var level_label: Label = $SubViewport/Control/LevelLabel
@onready var crown_icon: TextureRect = $SubViewport/Control.get_node_or_null("CrownIcon") as TextureRect
@onready var star_icon: TextureRect = $SubViewport/Control.get_node_or_null("StarIcon") as TextureRect
@onready var sprite_3d: Sprite3D = $Sprite3D

const TEXTURE_FILL_NORMAL: Texture2D = preload("res://assets/ui/cutter/blade_bar_fill_cyber.svg")
const TEXTURE_FILL_MAX: Texture2D = preload("res://assets/ui/cutter/blade_bar_fill_max.svg")

const COLOR_FLASH_DAMAGE: Color = Color(1.0, 0.35, 0.35, 1.0)
const COLOR_LABEL_NORMAL: Color = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_LABEL_MAX: Color = Color(1.0, 0.98, 0.70, 1.0)
const COLOR_OUTLINE_NORMAL: Color = Color(0.02, 0.06, 0.12, 0.95)
const COLOR_OUTLINE_MAX: Color = Color(0.24, 0.14, 0.02, 0.95)

# Offset no espaço global/câmera relativo ao bot (abaixo do bot na tela)
const SCREEN_OFFSET: Vector3 = Vector3(0.0, 0.15, 1.68)

var _target_node: Node3D = null
var _current_level: int = 1
var _is_max: bool = false
var _shake_tween: Tween = null
var _pulse_tween: Tween = null
var _fill_tween: Tween = null

func _ready() -> void:
	# Desacopla a rotação e herança direta de transformação do chassi do robô
	set_as_top_level(true)
	
	var parent_node: Node = get_parent()
	if parent_node is Node3D:
		_target_node = parent_node as Node3D
		global_position = _target_node.global_position + SCREEN_OFFSET

	_setup_styles()

	if UpgradeManager != null:
		_on_blade_level_changed(UpgradeManager.blade_level, UpgradeManager.blade_level >= 6)
		_on_blade_xp_changed(UpgradeManager.blade_xp, UpgradeManager.get_xp_required_for_next_level(), UpgradeManager.get_progress_ratio())
		UpgradeManager.blade_level_changed.connect(_on_blade_level_changed)
		UpgradeManager.blade_xp_changed.connect(_on_blade_xp_changed)
		UpgradeManager.blade_penalized.connect(_on_blade_penalized)

func _process(_delta: float) -> void:
	if _target_node != null and is_instance_valid(_target_node):
		# Mantém a barra posicionada fixa ao sul/abaixo do robô em coordenadas globais
		global_position = _target_node.global_position + SCREEN_OFFSET

	# Garante orientação de rotação estável alinhada à câmera isométrica (inclinada ~40 graus)
	# para que a barra repouse com perspectiva perfeita e sem nunca girar com o bot
	rotation_degrees = Vector3(-40.0, 0.0, 0.0)

func _setup_styles() -> void:
	if progress_bar == null:
		return
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0
	progress_bar.texture_progress = TEXTURE_FILL_NORMAL

	if level_label != null:
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level_label.add_theme_font_size_override("font_size", 28)
		level_label.add_theme_constant_override("outline_size", 8)
		level_label.add_theme_color_override("font_color", COLOR_LABEL_NORMAL)
		level_label.add_theme_color_override("font_outline_color", COLOR_OUTLINE_NORMAL)

func _on_blade_level_changed(new_level: int, is_max: bool) -> void:
	var prev_lvl: int = _current_level
	_current_level = new_level
	_is_max = is_max or (new_level >= 6)
	_update_visual_theme()
	if new_level > prev_lvl:
		play_level_up_reaction()

func _on_blade_xp_changed(_current_xp: float, _max_xp: float, progress_ratio: float) -> void:
	if _fill_tween != null and _fill_tween.is_valid():
		_fill_tween.kill()
	_fill_tween = create_tween()
	var target_val: float = 100.0 if (_is_max or _current_level >= 6) else (progress_ratio * 100.0)
	_fill_tween.tween_property(progress_bar, "value", target_val, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _on_blade_penalized(_new_level: int) -> void:
	play_penalty_reaction()

func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_update_visual_theme()

func _update_visual_theme() -> void:
	if progress_bar == null or level_label == null:
		return

	if _is_max:
		progress_bar.texture_progress = TEXTURE_FILL_MAX
		level_label.text = tr("BLADE_LEVEL_MAX")
		level_label.add_theme_color_override("font_color", COLOR_LABEL_MAX)
		level_label.add_theme_color_override("font_outline_color", COLOR_OUTLINE_MAX)
		if crown_icon != null:
			crown_icon.visible = true
		if star_icon != null:
			star_icon.visible = true
	else:
		progress_bar.texture_progress = TEXTURE_FILL_NORMAL
		level_label.text = tr("BLADE_LEVEL_FMT") % _current_level
		level_label.add_theme_color_override("font_color", COLOR_LABEL_NORMAL)
		level_label.add_theme_color_override("font_outline_color", COLOR_OUTLINE_NORMAL)
		if crown_icon != null:
			crown_icon.visible = false
		if star_icon != null:
			star_icon.visible = false

func play_level_up_reaction() -> void:
	if sprite_3d == null:
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(sprite_3d, "scale", Vector3(1.30, 1.30, 1.30), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(sprite_3d, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func play_penalty_reaction() -> void:
	if sprite_3d == null:
		return
	if _shake_tween != null and _shake_tween.is_valid():
		_shake_tween.kill()
	_shake_tween = create_tween()
	sprite_3d.modulate = COLOR_FLASH_DAMAGE
	_shake_tween.tween_property(sprite_3d, "modulate", Color.WHITE, 0.28)
	var base_x: float = 0.0
	_shake_tween.parallel().tween_property(sprite_3d, "position:x", base_x + 0.05, 0.04)
	_shake_tween.tween_property(sprite_3d, "position:x", base_x - 0.05, 0.04)
	_shake_tween.tween_property(sprite_3d, "position:x", base_x + 0.03, 0.04)
	_shake_tween.tween_property(sprite_3d, "position:x", base_x - 0.02, 0.04)
	_shake_tween.tween_property(sprite_3d, "position:x", base_x, 0.04)
