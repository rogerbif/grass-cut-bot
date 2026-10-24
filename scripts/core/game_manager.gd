extends Node

signal state_changed(new_state: int)
signal time_updated(time_left: float)
signal goal_updated(plant_type: String, remaining: int, target: int)
signal goal_completed(plant_type: String)
signal level_won(coins_earned: int, stars_earned: int)
signal level_lost(reason: String)
signal game_paused(is_paused: bool)
signal camera_shake_requested(intensity: float, duration: float)
signal coin_popup_requested(world_pos: Vector3, amount: int, plant_type: String)

enum GameState { READY, PLAYING, PAUSED, VICTORY, GAME_OVER }

var current_state: GameState = GameState.READY
var current_level: int = 1

var time_limit: float = 90.0
var time_left: float = 90.0
var level_coins: int = 0
var _is_victory_pending: bool = false

# Estrutura de metas: { "grass": {"target": 60, "current": 0}, "flower": ... }
var goals: Dictionary = {}

const HAPTIC_CUT_COOLDOWN_MS: int = 40
const HAPTIC_CUT_DURATION_MS: int = 40
const HAPTIC_CUT_AMPLITUDE: float = 0.25 # 25% conforme solicitado

const HAPTIC_IMPACT_DURATION_MS: int = 80
const HAPTIC_IMPACT_AMPLITUDE: float = 0.80 # 80% conforme solicitado

const HAPTIC_UI_COOLDOWN_MS: int = 50
const HAPTIC_UI_DURATION_MS: int = 25
const HAPTIC_UI_AMPLITUDE: float = 0.35 # Feedback sutil para botões da UI

var _last_cut_haptic_time: int = 0
var _last_ui_haptic_time: int = 0

func _enter_tree() -> void:
	# Registro defensivo dos Global Shader Parameters apenas se executado dentro do editor
	if Engine.is_editor_hint() and RenderingServer.has_method("global_shader_parameter_get_list"):
		var existing: PackedStringArray = RenderingServer.global_shader_parameter_get_list()
		if not existing.has("global_cutter_pos"):
			RenderingServer.global_shader_parameter_add(&"global_cutter_pos", RenderingServer.GLOBAL_VAR_TYPE_VEC3, Vector3(0.0, -9999.0, 0.0))
		if not existing.has("global_cutter_interact_radius"):
			RenderingServer.global_shader_parameter_add(&"global_cutter_interact_radius", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 1.6)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().node_added.connect(_on_scene_node_added)
	_scan_and_connect_buttons(get_tree().root)
	call_deferred("_init_graphics_quality")

func _init_graphics_quality() -> void:
	if SaveManager != null:
		var profile: String = String(SaveManager.get_setting("graphics_quality", "balanced"))
		apply_graphics_quality(profile)

func apply_graphics_quality(profile: String) -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR
	match profile:
		"high":
			vp.scaling_3d_scale = 1.0
			vp.fsr_sharpness = 0.2
		"balanced":
			vp.scaling_3d_scale = 0.85
			vp.fsr_sharpness = 0.2
		"eco":
			vp.scaling_3d_scale = 0.70
			vp.fsr_sharpness = 0.3
		_:
			vp.scaling_3d_scale = 0.85
			vp.fsr_sharpness = 0.2

func _on_scene_node_added(node: Node) -> void:
	if node is BaseButton:
		if not node.pressed.is_connected(trigger_haptic_ui):
			node.pressed.connect(trigger_haptic_ui)

func _scan_and_connect_buttons(node: Node) -> void:
	if node is BaseButton:
		if not node.pressed.is_connected(trigger_haptic_ui):
			node.pressed.connect(trigger_haptic_ui)
	for child: Node in node.get_children():
		_scan_and_connect_buttons(child)

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING and not _is_victory_pending:
		time_left -= delta
		if time_left < 0.0:
			time_left = 0.0
			time_updated.emit(time_left)
			_check_game_over("Tempo esgotado!")
		else:
			time_updated.emit(time_left)

func start_level(level_index: int, level_goals: Dictionary, duration_seconds: float) -> void:
	current_level = level_index
	_is_victory_pending = false
	if SaveManager != null:
		SaveManager.set_last_played_level(current_level)

	time_limit = duration_seconds
	time_left = duration_seconds
	level_coins = 0
	goals = {}

	for plant_type in level_goals:
		goals[plant_type] = {
			"target": level_goals[plant_type],
			"current": 0
		}

	current_state = GameState.PLAYING
	get_tree().paused = false
	state_changed.emit(current_state)
	time_updated.emit(time_left)

	for plant_type in goals:
		var target: int = goals[plant_type]["target"]
		goal_updated.emit(plant_type, target, target)

	if AudioManager != null:
		AudioManager.play_gameplay_music()

func register_cut(plant_type: String, base_coins: int = 1, cut_pos: Vector3 = Vector3.ZERO) -> void:
	if current_state != GameState.PLAYING or _is_victory_pending:
		return

	# Incrementa moedas da fase
	var multiplier := 1
	if UpgradeManager != null:
		multiplier = UpgradeManager.get_coin_multiplier()
	var earned := base_coins * multiplier
	level_coins += earned

	# Dispara evento para números flutuantes 3D no local do corte
	if cut_pos != Vector3.ZERO:
		coin_popup_requested.emit(cut_pos, earned, plant_type)

	# Dispara feedback háptico leve
	trigger_haptic_cut()

	# Dispara efeito sonoro limpo de corte de vegetação (sem moeda, com som padrão de grama)
	if AudioManager != null:
		AudioManager.play_cut_sfx(false)

	# Atualiza metas
	if goals.has(plant_type):
		var goal_info: Dictionary = goals[plant_type]
		goal_info["current"] += 1
		var remaining: int = maxi(0, int(goal_info["target"]) - int(goal_info["current"]))
		goal_updated.emit(plant_type, remaining, goal_info["target"])

		if remaining == 0:
			goal_completed.emit(plant_type)
			if AudioManager != null:
				AudioManager.play_sfx("goal_completed")

		_check_victory()

## Retorna a quantidade restante para bater a meta (target - current). Se não houver meta ou já concluída, retorna 0.
func get_remaining_goal(plant_type: String) -> int:
	if goals.has(plant_type):
		var goal_info: Dictionary = goals[plant_type]
		return maxi(0, int(goal_info.get("target", 0)) - int(goal_info.get("current", 0)))
	return 0

func _check_victory() -> void:
	if _is_victory_pending or current_state != GameState.PLAYING:
		return

	for plant_type in goals:
		var g: Dictionary = goals[plant_type]
		if int(g.get("current", 0)) < int(g.get("target", 0)):
			return # Ainda há metas incompletas

	# Todas as metas batidas! Trava o temporizador e aguarda 1.0s de antecipação
	_is_victory_pending = true
	get_tree().create_timer(1.0, false).timeout.connect(_trigger_victory_celebration)

func _trigger_victory_celebration() -> void:
	if current_state != GameState.PLAYING and current_state != GameState.VICTORY:
		return

	current_state = GameState.VICTORY
	_is_victory_pending = false
	if UpgradeManager != null:
		UpgradeManager.add_coins(level_coins)

	var stars: int = 1
	if SaveManager != null:
		stars = SaveManager.record_level_victory(current_level, time_left, time_limit, level_coins)

	if AudioManager != null:
		AudioManager.play_sfx("level_completed")

	level_won.emit(level_coins, stars)
	state_changed.emit(current_state)

func _check_game_over(reason: String) -> void:
	current_state = GameState.GAME_OVER
	if AudioManager != null:
		AudioManager.play_sfx("defeat")
	level_lost.emit(reason)
	state_changed.emit(current_state)

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		if AudioManager != null:
			AudioManager.play_sfx("pause")
		game_paused.emit(true)
		state_changed.emit(current_state)
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		if AudioManager != null:
			AudioManager.play_sfx("unpause")
		game_paused.emit(false)
		state_changed.emit(current_state)

func restart_level() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func next_level() -> void:
	get_tree().paused = false
	var next_idx: int = current_level + 1
	var next_json: String = "res://data/levels/level_%02d.json" % next_idx
	if not FileAccess.file_exists(next_json) and next_idx > 20:
		current_level = 1
	else:
		current_level = next_idx

	if SaveManager != null:
		SaveManager.set_last_played_level(current_level)

	get_tree().reload_current_scene()

func trigger_haptic_cut() -> void:
	var vib_enabled: bool = true
	if SaveManager != null:
		vib_enabled = bool(SaveManager.get_setting("vib_enabled", true))

	if not vib_enabled:
		return

	if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		return

	var now: int = Time.get_ticks_msec()
	if now - _last_cut_haptic_time < HAPTIC_CUT_COOLDOWN_MS:
		return
	_last_cut_haptic_time = now

	Input.vibrate_handheld(HAPTIC_CUT_DURATION_MS, HAPTIC_CUT_AMPLITUDE)

func trigger_haptic_impact() -> void:
	var vib_enabled: bool = true
	if SaveManager != null:
		vib_enabled = bool(SaveManager.get_setting("vib_enabled", true))

	if vib_enabled and (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		Input.vibrate_handheld(HAPTIC_IMPACT_DURATION_MS, HAPTIC_IMPACT_AMPLITUDE)
	camera_shake_requested.emit(0.35, 0.2)

func trigger_haptic_ui() -> void:
	var vib_enabled: bool = true
	if SaveManager != null:
		vib_enabled = bool(SaveManager.get_setting("vib_enabled", true))

	if not vib_enabled:
		return

	if not (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		return

	var now: int = Time.get_ticks_msec()
	if now - _last_ui_haptic_time < HAPTIC_UI_COOLDOWN_MS:
		return
	_last_ui_haptic_time = now

	Input.vibrate_handheld(HAPTIC_UI_DURATION_MS, HAPTIC_UI_AMPLITUDE)
