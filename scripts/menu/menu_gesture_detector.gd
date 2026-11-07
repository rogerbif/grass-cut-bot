class_name MenuGestureDetector
extends RefCounted

## Detector modular de gestos de swipe com discriminação estrita de eixo
## e prevenção de conflitos diagonais para o Menu Principal.
## Suporta touch no celular e mouse no PC.

signal swipe_horizontal(direction: int) # -1 = esquerda (próxima aba), +1 = direita (aba anterior)
signal swipe_vertical(direction: int)   # +1 = baixo (próxima fase - Opção B), -1 = cima (fase anterior)

const MIN_SWIPE_DISTANCE: float = 45.0
const FLICK_VELOCITY_THRESHOLD: float = 380.0 # px/s
const AXIS_DOMINANCE_RATIO: float = 1.30
const MAX_SWIPE_DURATION_SEC: float = 0.85

var enabled: bool = true
var allow_vertical: bool = true   # Ativo somente na Home em BOT_VIEW
var allow_horizontal: bool = true # Ativo em todas as abas

var _tracking: bool = false
var _start_pos: Vector2 = Vector2.ZERO
var _last_pos: Vector2 = Vector2.ZERO
var _start_time: float = 0.0
var _touch_index: int = -1


func reset() -> void:
	_tracking = false
	_touch_index = -1
	_start_pos = Vector2.ZERO
	_last_pos = Vector2.ZERO


## Processa eventos de entrada enviados pelo main_menu._input.
## Retorna true se um swipe válido foi consumido no release.
func process_input(event: InputEvent) -> bool:
	if not enabled:
		if _tracking:
			reset()
		return false

	# 1. Toque em tela (Mobile)
	if event is InputEventScreenTouch:
		var st: InputEventScreenTouch = event as InputEventScreenTouch
		if st.pressed:
			if not _tracking:
				_start_tracking(st.position, st.index)
		elif _tracking and st.index == _touch_index:
			return _end_tracking(st.position)

	elif event is InputEventScreenDrag:
		var sd: InputEventScreenDrag = event as InputEventScreenDrag
		if _tracking and sd.index == _touch_index:
			_last_pos = sd.position

	# 2. Mouse (PC / Desenvolvimento no Editor)
	elif event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if not _tracking:
					_start_tracking(mb.position, -999)
			elif _tracking and _touch_index == -999:
				return _end_tracking(mb.position)

	elif event is InputEventMouseMotion:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		if _tracking and _touch_index == -999:
			_last_pos = mm.position

	return false


func _start_tracking(pos: Vector2, touch_id: int) -> void:
	_tracking = true
	_touch_index = touch_id
	_start_pos = pos
	_last_pos = pos
	_start_time = Time.get_ticks_msec() / 1000.0


func _end_tracking(end_pos: Vector2) -> bool:
	if not _tracking:
		return false

	var delta: Vector2 = end_pos - _start_pos
	var now: float = Time.get_ticks_msec() / 1000.0
	var duration: float = maxf(0.001, now - _start_time)
	var dist: float = delta.length()
	var velocity: float = dist / duration
	reset()

	# Rejeita toques muito lentos (arrastos prolongados estáticos)
	if duration > MAX_SWIPE_DURATION_SEC:
		return false

	# Verifica se atingiu distância mínima ou velocidade de flick
	var has_distance: bool = dist >= MIN_SWIPE_DISTANCE
	var is_flick: bool = (dist >= (MIN_SWIPE_DISTANCE * 0.55)) and (velocity >= FLICK_VELOCITY_THRESHOLD)
	if not (has_distance or is_flick):
		return false

	var abs_x: float = absf(delta.x)
	var abs_y: float = absf(delta.y)

	# Discriminação polar de eixos (evita diagonais ambíguas)
	# Eixo Horizontal (Troca de abas)
	if abs_x >= (abs_y * AXIS_DOMINANCE_RATIO):
		if not allow_horizontal:
			return false
		var dir: int = -1 if delta.x < 0.0 else 1
		swipe_horizontal.emit(dir)
		return true

	# Eixo Vertical (Troca de fases - Opção B: baixo = +1, cima = -1)
	if abs_y >= (abs_x * AXIS_DOMINANCE_RATIO):
		if not allow_vertical:
			return false
		var dir: int = 1 if delta.y > 0.0 else -1
		swipe_vertical.emit(dir)
		return true

	return false
