extends Node
## Cena de benchmark: carrega uma fase real (padrão: fase 20) pelo mesmo caminho do jogo (main.tscn).
## Uso: abrir scenes/tools/perf_test.tscn no editor e apertar F6.
##
## Teclas: 1/2/3 = densidade de tufos visíveis (100% / 50% / 25%)
##         G = liga/desliga toda a vegetação (baseline sem grama)
##         S = liga/desliga sombras
##         R = alterna scaling_3d (1.0 / 0.85 / 0.7 / 0.5)
##         V = liga/desliga VSync (desligado mostra o FPS máximo real, sem o teto do monitor)

const PerfProbeScript = preload("res://scripts/tools/perf_probe.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SCALE_STEPS: Array[float] = [1.0, 0.85, 0.7, 0.5]

@export var test_level: int = 20

var _prev_current_level: int = 1
var _prev_last_played: int = 1
var _main_node: Node3D = null
var _probe: CanvasLayer = null
var _plants: Array[Node3D] = []
var _load_ms: float = 0.0
var _density_step: int = 1
var _vegetation_on: bool = true
var _scale_index: int = 0

func _ready() -> void:
	# Quando esta cena é a principal, os _ready dos autoloads (SaveManager restaura a última fase)
	# rodam depois do _enter_tree dela. Por isso a fase de teste é definida aqui, ANTES de
	# instanciar main.tscn (cujo LevelController lê GameManager.current_level no seu _ready).
	if GameManager != null:
		_prev_current_level = GameManager.current_level
		GameManager.current_level = test_level
	if SaveManager != null:
		_prev_last_played = SaveManager.get_last_played_level()

	var t0: int = Time.get_ticks_usec()
	_main_node = MAIN_SCENE.instantiate() as Node3D
	add_child(_main_node)
	_load_ms = float(Time.get_ticks_usec() - t0) / 1000.0

	# Impede vitória/derrota durante o benchmark: tempo longo e nenhuma meta registrada.
	GameManager.time_limit = 9999.0
	GameManager.time_left = 9999.0
	GameManager.goals = {}

	var container: Node = _main_node.get_node_or_null("LevelController/PlantsContainer")
	if container != null:
		for child in container.get_children():
			var plant: Node3D = child as Node3D
			if plant != null:
				_plants.append(plant)

	_probe = PerfProbeScript.new() as CanvasLayer
	add_child(_probe)
	_refresh_extra()
	print("[perf_test] fase %d carregada em %.1f ms | tufos: %d" % [test_level, _load_ms, _plants.size()])

func _exit_tree() -> void:
	# Restaura o estado para não poluir o save do jogador.
	if GameManager != null:
		GameManager.current_level = _prev_current_level
	if SaveManager != null:
		SaveManager.set_last_played_level(_prev_last_played)

func _unhandled_key_input(event: InputEvent) -> void:
	var key_event: InputEventKey = event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return
	match key_event.keycode:
		KEY_1:
			_set_density(1)
		KEY_2:
			_set_density(2)
		KEY_3:
			_set_density(4)
		KEY_G:
			_vegetation_on = not _vegetation_on
			_apply_visibility()
		KEY_S:
			var light: DirectionalLight3D = _main_node.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
			if light != null:
				light.shadow_enabled = not light.shadow_enabled
		KEY_V:
			var vs: int = DisplayServer.window_get_vsync_mode()
			if vs == DisplayServer.VSYNC_DISABLED:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		KEY_R:
			_scale_index = (_scale_index + 1) % SCALE_STEPS.size()
			get_viewport().scaling_3d_scale = SCALE_STEPS[_scale_index]
	_refresh_extra()

func _set_density(step: int) -> void:
	_density_step = step
	_apply_visibility()

func _apply_visibility() -> void:
	for i in range(_plants.size()):
		var plant: Node3D = _plants[i]
		if is_instance_valid(plant):
			plant.visible = _vegetation_on and (i % _density_step == 0)

func _refresh_extra() -> void:
	if _probe == null:
		return
	var light: DirectionalLight3D = _main_node.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var shadows: bool = light != null and light.shadow_enabled
	_probe.set("extra_text", "Fase %d | load %.0f ms | tufos %d | dens 1/%d | veg %s | sombra %s | escala %.2f\n[1/2/3] densidade [G] grama [S] sombra [R] escala 3D [V] vsync" % [
		test_level, _load_ms, _plants.size(), _density_step,
		"ON" if _vegetation_on else "OFF", "ON" if shadows else "OFF", SCALE_STEPS[_scale_index]
	])
