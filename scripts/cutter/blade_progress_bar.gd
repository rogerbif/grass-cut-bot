class_name BladeProgressBar
extends Node3D

@onready var sub_viewport: SubViewport = $SubViewport
@onready var progress_bar: ProgressBar = $SubViewport/Control/ProgressBar
@onready var level_label: Label = $SubViewport/Control/ProgressBar/LevelLabel
@onready var sprite_3d: Sprite3D = $Sprite3D

var _current_level: int = 1
var _is_max: bool = false
var _shake_tween: Tween = null
var _pulse_tween: Tween = null
var _fill_tween: Tween = null

const COLOR_FILL_NORMAL: Color = Color(0.29, 0.87, 0.50, 1.0) # Verde-lima vibrante
const COLOR_FILL_MAX: Color = Color(0.98, 0.75, 0.14, 1.0)    # Dourado radiante
const COLOR_FLASH_DAMAGE: Color = Color(1.0, 0.28, 0.28, 1.0) # Vermelho de choque

func _ready() -> void:
	_setup_styles()
	if UpgradeManager != null:
		_on_blade_level_changed(UpgradeManager.blade_level, UpgradeManager.blade_level >= 6)
		_on_blade_xp_changed(UpgradeManager.blade_xp, UpgradeManager.get_xp_required_for_next_level(), UpgradeManager.get_progress_ratio())
		UpgradeManager.blade_level_changed.connect(_on_blade_level_changed)
		UpgradeManager.blade_xp_changed.connect(_on_blade_xp_changed)
		UpgradeManager.blade_penalized.connect(_on_blade_penalized)

func _setup_styles() -> void:
	if progress_bar == null:
		return
	progress_bar.show_percentage = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 100.0

	var bg_style: StyleBoxFlat = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.10, 0.13, 0.16, 0.88)
	bg_style.set_corner_radius_all(6)
	bg_style.border_color = Color(0.22, 0.27, 0.32, 0.95)
	bg_style.set_border_width_all(1)
	progress_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style: StyleBoxFlat = StyleBoxFlat.new()
	fill_style.bg_color = COLOR_FILL_NORMAL
	fill_style.set_corner_radius_all(6)
	progress_bar.add_theme_stylebox_override("fill", fill_style)

	if level_label != null:
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		level_label.add_theme_color_override("font_color", Color.WHITE)
		level_label.add_theme_color_override("font_outline_color", Color.BLACK)
		level_label.add_theme_constant_override("outline_size", 2)
		level_label.add_theme_font_size_override("font_size", 13)

func _on_blade_level_changed(new_level: int, is_max: bool) -> void:
	var prev_lvl: int = _current_level
	_current_level = new_level
	_is_max = is_max
	_update_text()
	_update_fill_color()
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

func _update_text() -> void:
	if level_label == null:
		return
	if _is_max or _current_level >= 6:
		level_label.text = "MAX"
	else:
		level_label.text = "Lv. %d" % _current_level

func _update_fill_color() -> void:
	if progress_bar == null:
		return
	var fill_style: StyleBox = progress_bar.get_theme_stylebox("fill")
	if fill_style is StyleBoxFlat:
		(fill_style as StyleBoxFlat).bg_color = COLOR_FILL_MAX if (_is_max or _current_level >= 6) else COLOR_FILL_NORMAL

func play_level_up_reaction() -> void:
	if sprite_3d == null:
		return
	if _pulse_tween != null and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween()
	_pulse_tween.tween_property(sprite_3d, "scale", Vector3(1.35, 1.35, 1.35), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
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
