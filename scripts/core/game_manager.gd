extends Node

signal state_changed(new_state: int)
signal time_updated(time_left: float)
signal goal_updated(plant_type: String, remaining: int, target: int)
signal goal_completed(plant_type: String)
signal level_won(coins_earned: int, stars_earned: int)
signal level_lost(reason: String)
signal game_paused(is_paused: bool)
signal camera_shake_requested(intensity: float, duration: float)

enum GameState { READY, PLAYING, PAUSED, VICTORY, GAME_OVER }

var current_state: GameState = GameState.READY
var current_level: int = 1

var time_limit: float = 90.0
var time_left: float = 90.0
var level_coins: int = 0

# Estrutura de metas: { "grass": {"target": 60, "current": 0}, "flower": ... }
var goals: Dictionary = {}

const HAPTIC_CUT_COOLDOWN_MS: int = 35
const HAPTIC_CUT_DURATION_MS: int = 30
const HAPTIC_IMPACT_DURATION_MS: int = 65

var _last_cut_haptic_time: int = 0

func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		time_left -= delta
		if time_left < 0.0:
			time_left = 0.0
			time_updated.emit(time_left)
			_check_game_over("Tempo esgotado!")
		else:
			time_updated.emit(time_left)

func start_level(level_index: int, level_goals: Dictionary, duration_seconds: float) -> void:
	current_level = level_index
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

func register_cut(plant_type: String, base_coins: int = 1) -> void:
	if current_state != GameState.PLAYING:
		return

	# Incrementa moedas da fase
	var multiplier := 1
	if UpgradeManager != null:
		multiplier = UpgradeManager.get_coin_multiplier()
	var earned := base_coins * multiplier
	level_coins += earned

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

func _check_victory() -> void:
	for plant_type in goals:
		var g = goals[plant_type]
		if g["current"] < g["target"]:
			return # Ainda há metas incompletas

	# Todas as metas batidas!
	current_state = GameState.VICTORY
	if UpgradeManager != null:
		UpgradeManager.add_coins(level_coins)

	var stars: int = 1
	if SaveManager != null:
		stars = SaveManager.record_level_victory(current_level, time_left, time_limit, level_coins)

	if AudioManager != null:
		AudioManager.play_sfx("star_win")

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

	Input.vibrate_handheld(HAPTIC_CUT_DURATION_MS)

func trigger_haptic_impact() -> void:
	var vib_enabled: bool = true
	if SaveManager != null:
		vib_enabled = bool(SaveManager.get_setting("vib_enabled", true))

	if vib_enabled and (OS.has_feature("mobile") or OS.has_feature("android") or OS.has_feature("ios")):
		Input.vibrate_handheld(HAPTIC_IMPACT_DURATION_MS)
	camera_shake_requested.emit(0.35, 0.2)
