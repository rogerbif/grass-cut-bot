class_name RobotEyes
extends Node

## Controlador de Expressões e Animação do Display de Olhos de LED (Cutter Bit)
## Gerencia as 10 expressões digitais, piscar procedural, reação a impactos e olhar dinâmico.

enum EyeExpression {
	NORMAL = 0,
	HAPPY = 1,
	SAD = 2,
	ANGRY = 3,
	ALERT = 4,
	SLEEPING = 5,
	GLITCH = 6,
	WINK = 7,
	VICTORY = 8,
	OFF = 9
}

const COLOR_CYAN: Color = Color(0.17, 0.89, 1.0, 1.0)
const COLOR_RED_ANGRY: Color = Color(1.0, 0.18, 0.12, 1.0)
const COLOR_YELLOW_ALERT: Color = Color(1.0, 0.82, 0.15, 1.0)

@export var screen_mesh: MeshInstance3D
@export var auto_blink_enabled: bool = true
@export var blink_min_interval: float = 3.0
@export var blink_max_interval: float = 6.0

var current_expression: EyeExpression = EyeExpression.NORMAL
var default_expression: EyeExpression = EyeExpression.NORMAL

var _material: ShaderMaterial
var _blink_timer: float = 0.0
var _temporary_timer: float = 0.0
var _is_blinking: bool = false
var _target_look_offset: Vector2 = Vector2.ZERO
var _current_look_offset: Vector2 = Vector2.ZERO
var _blink_tween: Tween
var _color_tween: Tween
var _glitch_tween: Tween

func _ready() -> void:
	_init_screen_material()
	_reset_blink_timer()
	set_expression(EyeExpression.NORMAL)

func _init_screen_material() -> void:
	if screen_mesh == null:
		return
	
	# Obtém ou instancia o ShaderMaterial para permitir tweens independentes
	var mat: Material = screen_mesh.get_surface_override_material(0)
	if mat == null:
		mat = screen_mesh.material_override
	if mat == null and screen_mesh.mesh != null and screen_mesh.mesh.get_surface_count() > 0:
		mat = screen_mesh.mesh.surface_get_material(0)
	
	if mat is ShaderMaterial:
		_material = (mat as ShaderMaterial).duplicate() as ShaderMaterial
		screen_mesh.set_surface_override_material(0, _material)

func _process(delta: float) -> void:
	if _material == null:
		return

	# Suavização da direção do olhar (eye tracking)
	_current_look_offset = _current_look_offset.lerp(_target_look_offset, delta * 10.0)
	_material.set_shader_parameter("look_offset", _current_look_offset)

	# Temporizador de expressão temporária (ex.: após choque ou combo rápido)
	if _temporary_timer > 0.0:
		_temporary_timer -= delta
		if _temporary_timer <= 0.0:
			set_expression(default_expression)

	# Temporizador do piscar autônomo
	if auto_blink_enabled and current_expression != EyeExpression.SLEEPING and current_expression != EyeExpression.OFF:
		_blink_timer -= delta
		if _blink_timer <= 0.0 and not _is_blinking:
			play_blink()
			_reset_blink_timer()

func _reset_blink_timer() -> void:
	_blink_timer = randf_range(blink_min_interval, blink_max_interval)

## Altera a expressão atual dos olhos
func set_expression(expr: EyeExpression, custom_color: Color = Color.TRANSPARENT, duration: float = 0.0) -> void:
	current_expression = expr
	if duration > 0.0:
		_temporary_timer = duration
	else:
		default_expression = expr
		_temporary_timer = 0.0

	if _material == null:
		return

	_material.set_shader_parameter("expression_index", int(expr))

	# Define a cor apropriada para a expressão
	var target_color: Color = COLOR_CYAN
	if custom_color != Color.TRANSPARENT:
		target_color = custom_color
	elif expr == EyeExpression.ANGRY:
		target_color = COLOR_RED_ANGRY
	elif expr == EyeExpression.ALERT:
		target_color = COLOR_YELLOW_ALERT

	_animate_color(target_color, 0.15)

## Executa o piscar de olhos orgânico via interpolação do parâmetro de shader UV
func play_blink(duration: float = 0.16) -> void:
	if _material == null or _is_blinking:
		return
	_is_blinking = true

	if _blink_tween != null and _blink_tween.is_valid():
		_blink_tween.kill()

	_blink_tween = create_tween()
	var half_dur: float = duration * 0.5
	_blink_tween.tween_method(
		func(val: float) -> void: _material.set_shader_parameter("blink", val),
		0.0, 1.0, half_dur
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_blink_tween.tween_method(
		func(val: float) -> void: _material.set_shader_parameter("blink", val),
		1.0, 0.0, half_dur
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_blink_tween.finished.connect(func() -> void: _is_blinking = false)

## Define a direção para onde os olhos estão olhando (ex.: vetor do joystick)
func set_look_direction(direction: Vector2) -> void:
	# Limita o deslocamento máximo em UV para não cortar as pupilas da moldura
	var max_offset: float = 0.035
	_target_look_offset = Vector2(direction.x, -direction.y) * max_offset

## Dispara a reação de impacto com rocha / obstáculo rígido
func trigger_obstacle_reaction() -> void:
	if _material == null:
		return

	# Expressão Bravo com modo de ataque em vermelho vivo
	set_expression(EyeExpression.ANGRY, COLOR_RED_ANGRY, 0.75)

	# Efeito de tremor/glitch elétrico no display
	if _glitch_tween != null and _glitch_tween.is_valid():
		_glitch_tween.kill()

	_material.set_shader_parameter("glitch_intensity", 0.85)
	_glitch_tween = create_tween()
	_glitch_tween.tween_method(
		func(val: float) -> void: _material.set_shader_parameter("glitch_intensity", val),
		0.85, 0.0, 0.65
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

## Dispara reação de vitória (Estrelas e Coração) com pulso de brilho
func trigger_victory_reaction() -> void:
	set_expression(EyeExpression.VICTORY, COLOR_CYAN)
	if _material == null:
		return
	
	var pulse_tween: Tween = create_tween()
	pulse_tween.tween_method(
		func(energy: float) -> void: _material.set_shader_parameter("emission_energy", energy),
		2.0, 3.5, 0.3
	).set_trans(Tween.TRANS_SINE)
	pulse_tween.tween_method(
		func(energy: float) -> void: _material.set_shader_parameter("emission_energy", energy),
		3.5, 2.0, 0.4
	).set_trans(Tween.TRANS_SINE)

## Desliga a tela (para menu de pausa ou sem bateria)
func set_screen_off(is_off: bool) -> void:
	if is_off:
		set_expression(EyeExpression.OFF)
	else:
		set_expression(EyeExpression.NORMAL)

func _animate_color(new_color: Color, duration: float) -> void:
	if _material == null:
		return
	if _color_tween != null and _color_tween.is_valid():
		_color_tween.kill()

	var current_color: Color = _material.get_shader_parameter("eye_color")
	_color_tween = create_tween()
	_color_tween.tween_method(
		func(c: Color) -> void: _material.set_shader_parameter("eye_color", c),
		current_color, new_color, duration
	)
