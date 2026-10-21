extends Node
## Cena de benchmark: carrega uma fase real (padrão: fase 20) pelo mesmo caminho do jogo (main.tscn).
## Uso no PC: abrir scenes/tools/perf_test.tscn no editor e apertar F6.
## Uso no Celular: tocar nos botões de debug no topo da tela (ou iniciar pelo botão no Menu).
##
## Teclas (PC): T = reseta os tufos da fase para testar novamente
##              1/2/3 = densidade de tufos visíveis (100% / 50% / 25%)
##              G = liga/desliga toda a vegetação (baseline sem grama)
##              L ou F = liga/desliga sombras (evita conflito com S do WASD)
##              R = alterna scaling_3d (1.0 / 0.85 / 0.7 / 0.5)
##              V = liga/desliga VSync (desligado mostra o FPS máximo real, sem o teto do monitor)

const PerfProbeScript = preload("res://scripts/tools/perf_probe.gd")
const MAIN_SCENE: PackedScene = preload("res://scenes/main.tscn")
const SCALE_STEPS: Array[float] = [1.0, 0.85, 0.7, 0.5]

@export var test_level: int = 20

var _prev_current_level: int = 1
var _prev_last_played: int = 1
var _main_node: Node3D = null
var _probe: CanvasLayer = null
var _veg_grid: Node3D = null
var _total_tufts: int = 0
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

	var level_ctrl: Node = _main_node.get_node_or_null("LevelController")
	if level_ctrl != null:
		_veg_grid = level_ctrl.get("current_level_node") as Node3D
		if _veg_grid == null:
			_veg_grid = level_ctrl.find_child("VegetationGrid*", false, false) as Node3D

	if _veg_grid != null and _veg_grid.has_method("get_total_tufts"):
		_total_tufts = int(_veg_grid.call("get_total_tufts"))

	# Impede vitória/derrota durante o benchmark: tempo longo e nenhuma meta registrada.
	GameManager.time_limit = 9999.0
	GameManager.time_left = 9999.0
	GameManager.goals = {}

	_probe = PerfProbeScript.new() as CanvasLayer
	add_child(_probe)
	if _probe.has_signal("action_triggered"):
		_probe.connect("action_triggered", _on_probe_action)
	_refresh_extra()
	print("[perf_test] fase %d carregada em %.1f ms | tufos: %d" % [
		test_level, _load_ms, _total_tufts
	])

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
		KEY_T:
			_on_probe_action("reset_level")
		KEY_1:
			_on_probe_action("dens_1")
		KEY_2:
			_on_probe_action("dens_2")
		KEY_3:
			_on_probe_action("dens_4")
		KEY_G:
			_on_probe_action("toggle_veg")
		KEY_L, KEY_F:
			_on_probe_action("toggle_shadow")
		KEY_V:
			_on_probe_action("toggle_vsync")
		KEY_R:
			_on_probe_action("cycle_scale")
		KEY_M:
			_on_probe_action("back_menu")

func _on_probe_action(action_id: String) -> void:
	match action_id:
		"reset_level":
			if _veg_grid != null and is_instance_valid(_veg_grid) and _veg_grid.has_method("reset_all_plants"):
				_veg_grid.call("reset_all_plants")
				GameManager.time_limit = 9999.0
				GameManager.time_left = 9999.0
				GameManager.goals = {}
		"dens_1":
			_set_density(1)
		"dens_2":
			_set_density(2)
		"dens_4":
			_set_density(4)
		"toggle_veg":
			_vegetation_on = not _vegetation_on
			_apply_visibility()
		"toggle_shadow":
			var light: DirectionalLight3D = _main_node.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
			if light != null:
				light.shadow_enabled = not light.shadow_enabled
		"toggle_vsync":
			var vs: int = DisplayServer.window_get_vsync_mode()
			if vs == DisplayServer.VSYNC_DISABLED:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
			else:
				DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		"cycle_scale":
			_scale_index = (_scale_index + 1) % SCALE_STEPS.size()
			get_viewport().scaling_3d_scale = SCALE_STEPS[_scale_index]
		"back_menu":
			get_tree().change_scene_to_file("res://scenes/menu/main_menu.tscn")
			return
	_refresh_extra()

func _set_density(step: int) -> void:
	_density_step = step
	_apply_visibility()

func _apply_visibility() -> void:
	if _veg_grid != null and is_instance_valid(_veg_grid) and _veg_grid.has_method("set_benchmark_visibility"):
		_veg_grid.call("set_benchmark_visibility", _vegetation_on, _density_step)

func _refresh_extra() -> void:
	if _probe == null:
		return
	var light: DirectionalLight3D = _main_node.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var shadows: bool = light != null and light.shadow_enabled
	var vs_on: bool = DisplayServer.window_get_vsync_mode() != DisplayServer.VSYNC_DISABLED
	_probe.set("extra_text", "Fase %d | load %.1f ms | tufos %d | dens 1/%d | veg %s | sombra %s | esc %.2f | vsync %s" % [
		test_level, _load_ms, _total_tufts, _density_step,
		"ON" if _vegetation_on else "OFF", "ON" if shadows else "OFF", SCALE_STEPS[_scale_index],
		"ON" if vs_on else "OFF"
	])
