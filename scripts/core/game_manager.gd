extends Node

const TilePaletteDB = preload("res://scripts/editor/tile_palette_db.gd")

signal state_changed(new_state: int)
signal time_updated(time_left: float)
signal goal_updated(plant_type: String, remaining: int, target: int)
signal goal_completed(plant_type: String)
signal level_won(coins_earned: int, stars_earned: int)
signal level_lost(reason: String)
signal game_paused(is_paused: bool)
signal camera_shake_requested(intensity: float, duration: float)
signal coin_popup_requested(world_pos: Vector3, amount: int, plant_type: String)
signal goal_item_collected(plant_type: String, world_pos: Vector3)

enum GameState { READY, PLAYING, PAUSED, VICTORY, GAME_OVER }

const DEFEAT_REASON_TIME_UP: String = "time_up"
const DEFEAT_REASON_ROBOT_BROKEN: String = "robot_broken"

# Gerenciamento de Taxa de Quadros & Economia de Bateria Mobile
const FPS_PLAYING: int = 60
const FPS_PAUSED: int = 30
const FPS_BACKGROUND: int = 15

var current_state: GameState = GameState.READY
var current_level: int = 1

var time_limit: float = 90.0
var time_left: float = 90.0
var level_coins: int = 0
var _is_victory_pending: bool = false
var _extra_time_used: bool = false
var last_defeat_reason: String = DEFEAT_REASON_TIME_UP

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
	Engine.max_fps = FPS_PLAYING
	get_tree().node_added.connect(_on_scene_node_added)
	_scan_and_connect_buttons(get_tree().root)
	call_deferred("_init_graphics_quality")

func _notification(what: int) -> void:
	# Pausa automaticamente se o aplicativo perder o foco ou for minimizado pelo SO (ex: ligação, home)
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if current_state == GameState.PLAYING:
			toggle_pause()
		Engine.max_fps = FPS_BACKGROUND
	elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
		if current_state == GameState.PAUSED:
			Engine.max_fps = FPS_PAUSED
		else:
			Engine.max_fps = FPS_PLAYING

func _init_graphics_quality() -> void:
	if SaveManager != null:
		var profile: String = String(SaveManager.get_setting("graphics_quality", "balanced"))
		apply_graphics_quality(profile)

func apply_graphics_quality(profile: String) -> void:
	var vp: Viewport = get_viewport()
	if vp == null:
		return
	vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_BILINEAR
	match profile:
		"high":
			vp.scaling_3d_scale = 1.0
		"balanced":
			vp.scaling_3d_scale = 0.85
		"eco":
			vp.scaling_3d_scale = 0.70
		_:
			vp.scaling_3d_scale = 0.85

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
			_check_game_over(DEFEAT_REASON_TIME_UP)
		else:
			time_updated.emit(time_left)

func start_level(level_index: int, level_goals: Dictionary, duration_seconds: float) -> void:
	current_level = level_index
	_is_victory_pending = false
	_extra_time_used = false
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
	Engine.max_fps = FPS_PLAYING
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

	# Atualiza metas (suporta tanto espécie específica de flor quanto variações cromáticas, chave base e chave genérica)
	var goal_key: String = plant_type
	if not goals.has(goal_key):
		var base_id: String = TilePaletteDB.get_base_id_for_variant(plant_type)
		if goals.has(base_id):
			goal_key = base_id
		elif plant_type.begins_with("flower") and goals.has("flower"):
			goal_key = "flower"
		elif plant_type.begins_with("grass") and goals.has("grass"):
			goal_key = "grass"

	if goals.has(goal_key):
		var goal_info: Dictionary = goals[goal_key]
		var was_completed: bool = int(goal_info["current"]) >= int(goal_info["target"])
		goal_info["current"] += 1
		var remaining: int = maxi(0, int(goal_info["target"]) - int(goal_info["current"]))
		goal_updated.emit(goal_key, remaining, goal_info["target"])
		if not was_completed and cut_pos != Vector3.ZERO:
			goal_item_collected.emit(goal_key, cut_pos)

		# Dispara som e evento de meta concluída estritamente na transição (apenas 1 vez)
		if not was_completed and remaining == 0:
			goal_completed.emit(goal_key)
			if AudioManager != null:
				AudioManager.play_sfx("goal_completed")

		_check_victory()

## Retorna a quantidade restante para bater a meta (target - current). Se não houver meta ou já concluída, retorna 0.
func get_remaining_goal(plant_type: String) -> int:
	var goal_key: String = plant_type
	if not goals.has(goal_key):
		var base_id: String = TilePaletteDB.get_base_id_for_variant(plant_type)
		if goals.has(base_id):
			goal_key = base_id
		elif plant_type.begins_with("flower") and goals.has("flower"):
			goal_key = "flower"
		elif plant_type.begins_with("grass") and goals.has("grass"):
			goal_key = "grass"
	if goals.has(goal_key):
		var goal_info: Dictionary = goals[goal_key]
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

	# Gravação atômica imediata da vitória para persistência garantida
	var stars: int = 1
	if SaveManager != null:
		stars = SaveManager.record_level_victory(current_level, time_left, time_limit, level_coins)

	if AudioManager != null:
		AudioManager.stop_countdown_alert()
		AudioManager.play_sfx("level_completed")

	level_won.emit(level_coins, stars)
	state_changed.emit(current_state)

## Retorna o progresso total das metas (0.0 a 1.0): soma dos cortes atuais sobre soma dos alvos.
func get_progress_ratio() -> float:
	var total_target: int = 0
	var total_current: int = 0
	for plant_type: Variant in goals.keys():
		var g: Dictionary = goals[plant_type] as Dictionary
		var tgt: int = int(g.get("target", 0))
		total_target += tgt
		total_current += mini(int(g.get("current", 0)), tgt)
	if total_target <= 0:
		return 0.0
	return clampf(float(total_current) / float(total_target), 0.0, 1.0)

## Retorna as metas ainda incompletas: { plant_type: restante }.
func get_remaining_goals() -> Dictionary:
	var result: Dictionary = {}
	for plant_type: Variant in goals.keys():
		var g: Dictionary = goals[plant_type] as Dictionary
		var rem: int = maxi(0, int(g.get("target", 0)) - int(g.get("current", 0)))
		if rem > 0:
			result[String(plant_type)] = rem
	return result

## Retorna o resumo de todas as metas da fase na ordem de exibição: [{"plant_type": key, "current": cur, "target": tgt}]
func get_goals_summary() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	for plant_type: Variant in goals.keys():
		var g: Dictionary = goals[plant_type] as Dictionary
		var tgt: int = int(g.get("target", 0))
		var cur: int = mini(int(g.get("current", 0)), tgt)
		list.append({
			"plant_type": String(plant_type),
			"current": cur,
			"target": tgt
		})
	return list

## Permite usar a ação de continuar ("Pegar Mais Tempo" ou "Consertar Robô") apenas uma vez por tentativa.
func can_grant_extra_time() -> bool:
	return current_state == GameState.GAME_OVER and not _extra_time_used

## Concede tempo extra e retoma a fase (restaurando a vida consumida na tentativa atual).
func grant_extra_time(seconds: float) -> void:
	if not can_grant_extra_time():
		return
	_extra_time_used = true
	if SaveManager != null:
		SaveManager.add_lives(1)
	time_left = seconds
	current_state = GameState.PLAYING
	get_tree().paused = false
	time_updated.emit(time_left)
	state_changed.emit(current_state)

## Conserta o robô quebrado no Nível 1 e retoma a fase (restaurando a vida consumida na tentativa atual).
func repair_robot_and_continue() -> void:
	if not can_grant_extra_time():
		return
	_extra_time_used = true
	if SaveManager != null:
		SaveManager.add_lives(1)
	if time_left < 5.0:
		time_left = 5.0
	current_state = GameState.PLAYING
	get_tree().paused = false
	time_updated.emit(time_left)
	state_changed.emit(current_state)

## Dispara derrota imediata quando o robô quebra a lâmina ao bater em uma pedra no Nível 1.
func trigger_robot_broken() -> void:
	if current_state != GameState.PLAYING or _is_victory_pending:
		return
	_check_game_over(DEFEAT_REASON_ROBOT_BROKEN)

func _check_game_over(reason: String) -> void:
	if current_state == GameState.GAME_OVER or current_state == GameState.VICTORY:
		return
	current_state = GameState.GAME_OVER
	last_defeat_reason = reason
	if SaveManager != null:
		SaveManager.consume_life()
	if AudioManager != null:
		AudioManager.stop_countdown_alert()
		AudioManager.play_sfx("defeat")
	level_lost.emit(reason)
	state_changed.emit(current_state)

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		current_state = GameState.PAUSED
		get_tree().paused = true
		Engine.max_fps = FPS_PAUSED
		if AudioManager != null:
			AudioManager.play_sfx("pause")
		game_paused.emit(true)
		state_changed.emit(current_state)
	elif current_state == GameState.PAUSED:
		current_state = GameState.PLAYING
		get_tree().paused = false
		Engine.max_fps = FPS_PLAYING
		if AudioManager != null:
			AudioManager.play_sfx("unpause")
		game_paused.emit(false)
		state_changed.emit(current_state)

var _cached_total_levels: int = -1

func get_total_levels() -> int:
	if _cached_total_levels > 0:
		return _cached_total_levels
	var count: int = 0
	for lvl: int in range(1, 101):
		var json_path: String = "res://data/levels/level_%02d.json" % lvl
		if FileAccess.file_exists(json_path):
			count = lvl
	_cached_total_levels = maxi(count, 40)
	return _cached_total_levels

func restart_level() -> void:
	get_tree().paused = false
	Engine.max_fps = FPS_PLAYING
	get_tree().reload_current_scene()

func next_level() -> void:
	get_tree().paused = false
	Engine.max_fps = FPS_PLAYING
	var total_lvls: int = get_total_levels()
	var next_idx: int = current_level + 1
	var next_json: String = "res://data/levels/level_%02d.json" % next_idx
	if not FileAccess.file_exists(next_json) or next_idx > total_lvls:
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

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event as InputEventKey
		if key_event.keycode == KEY_F11 or (key_event.alt_pressed and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER)):
			toggle_fullscreen()

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
