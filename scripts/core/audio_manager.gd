extends Node

# Autoload AudioManager: Centralizador de Áudio e Sonoplastia para o Grass Cut Bot
# Gerencia trilhas musicais (Menu e Gameplay), pool de efeitos sonoros,
# controle de motor elétrico contínuo, barramentos de áudio e mitigação de estalos (throttling).

# Constantes de Trilha Sonora (Music)
const MUSIC_MENU: AudioStream = preload("res://assets/audio/music/Dance By Yourself - Dyalla.mp3")
const MUSIC_GAMEPLAY: AudioStream = preload("res://assets/audio/music/Groove - Dyalla.mp3")

# Constantes de Efeitos Sonoros (SFX)
const SFX_GRASS_CUT: AudioStream = preload("res://assets/audio/sfx/Grass-cut.ogg")
const SFX_CUT_FRUIT: AudioStream = preload("res://assets/audio/sfx/CutFruit.wav")
const SFX_SLAP_ROCK: AudioStream = preload("res://assets/audio/sfx/Slap_rock.wav")
const SFX_ELECTRIC_ENGINE: AudioStream = preload("res://assets/audio/sfx/Electric_Engine.wav")
const SFX_COIN_PICKUP: AudioStream = preload("res://assets/audio/sfx/coin_pickup.wav")
const SFX_TIMER_COUNTDOWN: AudioStream = preload("res://assets/audio/sfx/Timer_Countdown.wav")
const SFX_GOAL_COMPLETED: AudioStream = preload("res://assets/audio/sfx/goal_completed.wav")
const SFX_STAR_WIN: AudioStream = preload("res://assets/audio/sfx/Star_win.mp3")
const SFX_STAR_POP: AudioStream = preload("res://assets/audio/sfx/Star_pop.wav")
const SFX_MACHINE_POWER_OFF: AudioStream = preload("res://assets/audio/sfx/MachinePowerOff.ogg")
const SFX_PAUSE: AudioStream = preload("res://assets/audio/sfx/Pause.wav")
const SFX_UNPAUSE: AudioStream = preload("res://assets/audio/sfx/Unpause.wav")
const SFX_CONFIRM: AudioStream = preload("res://assets/audio/sfx/Confirm.wav")
const SFX_CLOSE: AudioStream = preload("res://assets/audio/sfx/Close.wav")
const SFX_BUY_SELL: AudioStream = preload("res://assets/audio/sfx/Buy_sell.wav")
const SFX_POWER_UP: AudioStream = preload("res://assets/audio/sfx/Power_up.mp3")
const SFX_DENIED: AudioStream = preload("res://assets/audio/sfx/Denied.wav")
const SFX_FAST_FORWARD: AudioStream = preload("res://assets/audio/sfx/Fast_foward.mp3")
const SFX_USE_ITEM: AudioStream = preload("res://assets/audio/sfx/Use_item.wav")
const SFX_WATER_SPLASH: AudioStream = preload("res://assets/audio/sfx/Water_splash.wav")

const SFX_POOL_SIZE: int = 8
const CUT_COOLDOWN_MS: int = 40
const COIN_COOLDOWN_MS: int = 45
const COUNTDOWN_COOLDOWN_MS: int = 800

var _sfx_map: Dictionary = {}
var _music_player: AudioStreamPlayer
var _engine_player: AudioStreamPlayer
var _countdown_player: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _pool_index: int = 0

var _music_bus_idx: int = -1
var _sfx_bus_idx: int = -1

var _music_enabled: bool = true
var _sfx_enabled: bool = true

var _last_cut_time: int = 0
var _last_coin_time: int = 0
var _last_countdown_time: int = 0
var _music_tween: Tween = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	_music_bus_idx = AudioServer.get_bus_index("Music")
	_sfx_bus_idx = AudioServer.get_bus_index("SFX")

	_init_sfx_map()
	_create_audio_players()
	_sync_settings_from_save()

func _init_sfx_map() -> void:
	_sfx_map = {
		"grass_cut": SFX_GRASS_CUT,
		"cut_fruit": SFX_CUT_FRUIT,
		"slap_rock": SFX_SLAP_ROCK,
		"coin_pickup": SFX_COIN_PICKUP,
		"timer_countdown": SFX_TIMER_COUNTDOWN,
		"goal_completed": SFX_GOAL_COMPLETED,
		"star_win": SFX_STAR_WIN,
		"star_pop": SFX_STAR_POP,
		"defeat": SFX_MACHINE_POWER_OFF,
		"pause": SFX_PAUSE,
		"unpause": SFX_UNPAUSE,
		"confirm": SFX_CONFIRM,
		"close": SFX_CLOSE,
		"buy": SFX_BUY_SELL,
		"power_up": SFX_POWER_UP,
		"denied": SFX_DENIED,
		"fast_forward": SFX_FAST_FORWARD,
		"use_item": SFX_USE_ITEM,
		"water_splash": SFX_WATER_SPLASH
	}

func _create_audio_players() -> void:
	# Player de Música
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	_music_player.bus = "Music" if _music_bus_idx >= 0 else "Master"
	add_child(_music_player)

	# Player de Motor Contínuo
	_engine_player = AudioStreamPlayer.new()
	_engine_player.name = "EnginePlayer"
	_engine_player.bus = "SFX" if _sfx_bus_idx >= 0 else "Master"
	_engine_player.stream = SFX_ELECTRIC_ENGINE
	_engine_player.volume_db = -16.0
	_engine_player.pitch_scale = 0.9
	add_child(_engine_player)

	# Player dedicado para alerta de contagem regressiva
	_countdown_player = AudioStreamPlayer.new()
	_countdown_player.name = "CountdownPlayer"
	_countdown_player.bus = "SFX" if _sfx_bus_idx >= 0 else "Master"
	_countdown_player.stream = SFX_TIMER_COUNTDOWN
	_countdown_player.volume_db = -2.0
	add_child(_countdown_player)

	# Pool polifônico de efeitos sonoros
	_sfx_pool.clear()
	for i in range(SFX_POOL_SIZE):
		var p: AudioStreamPlayer = AudioStreamPlayer.new()
		p.name = "SFXPlayer_%d" % i
		p.bus = "SFX" if _sfx_bus_idx >= 0 else "Master"
		add_child(p)
		_sfx_pool.append(p)

func _sync_settings_from_save() -> void:
	if SaveManager != null:
		_music_enabled = bool(SaveManager.get_setting("music_enabled", true))
		_sfx_enabled = bool(SaveManager.get_setting("sfx_enabled", true))
	set_music_enabled(_music_enabled)
	set_sfx_enabled(_sfx_enabled)

# ---------------------------------------------------------
# Controle de Música (Menu vs Gameplay)
# ---------------------------------------------------------

func play_menu_music(fade_duration: float = 0.4) -> void:
	_switch_music_stream(MUSIC_MENU, -2.0, fade_duration)

func play_gameplay_music(fade_duration: float = 0.4) -> void:
	_switch_music_stream(MUSIC_GAMEPLAY, -2.5, fade_duration)

func stop_music(fade_duration: float = 0.4) -> void:
	if _music_player == null or not _music_player.playing:
		return
	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()
	_music_tween = create_tween()
	_music_tween.tween_property(_music_player, "volume_db", -50.0, fade_duration)
	_music_tween.tween_callback(func() -> void:
		_music_player.stop()
		_music_player.stream = null
	)

func _switch_music_stream(target_stream: AudioStream, target_volume_db: float, fade_duration: float) -> void:
	if _music_player == null:
		return
	if _music_player.playing and _music_player.stream == target_stream:
		return

	if _music_tween != null and _music_tween.is_valid():
		_music_tween.kill()

	if _music_player.playing:
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", -40.0, fade_duration * 0.5)
		_music_tween.tween_callback(func() -> void:
			_music_player.stream = target_stream
			_music_player.volume_db = -40.0
			_music_player.play()
		)
		_music_tween.tween_property(_music_player, "volume_db", target_volume_db, fade_duration * 0.5)
	else:
		_music_player.stream = target_stream
		_music_player.volume_db = -40.0
		_music_player.play()
		_music_tween = create_tween()
		_music_tween.tween_property(_music_player, "volume_db", target_volume_db, fade_duration)

# ---------------------------------------------------------
# Efeitos Sonoros Gerais & Pooling
# ---------------------------------------------------------

func play_sfx(key: String, pitch_range: float = 0.0, volume_offset_db: float = 0.0) -> void:
	if not _sfx_enabled:
		return
	var stream: AudioStream = _sfx_map.get(key, null) as AudioStream
	if stream == null:
		return

	var player: AudioStreamPlayer = _get_next_sfx_player()
	player.stream = stream
	player.volume_db = volume_offset_db
	if pitch_range > 0.0:
		player.pitch_scale = 1.0 + randf_range(-pitch_range, pitch_range)
	else:
		player.pitch_scale = 1.0
	player.play()

func _get_next_sfx_player() -> AudioStreamPlayer:
	var player: AudioStreamPlayer = _sfx_pool[_pool_index]
	_pool_index = (_pool_index + 1) % _sfx_pool.size()
	return player

# ---------------------------------------------------------
# Efeitos Especiais de Gameplay com Throttling
# ---------------------------------------------------------

func play_cut_sfx(is_special: bool = false) -> void:
	if not _sfx_enabled:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_cut_time < CUT_COOLDOWN_MS:
		return
	_last_cut_time = now

	var player: AudioStreamPlayer = _get_next_sfx_player()
	if is_special:
		player.stream = SFX_CUT_FRUIT
		player.volume_db = 0.5
		player.pitch_scale = randf_range(0.95, 1.05)
	else:
		player.stream = SFX_GRASS_CUT
		player.volume_db = 0.0
		player.pitch_scale = randf_range(0.92, 1.08)
	player.play()

func play_coin_sfx() -> void:
	if not _sfx_enabled:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_coin_time < COIN_COOLDOWN_MS:
		return
	_last_coin_time = now

	var player: AudioStreamPlayer = _get_next_sfx_player()
	player.stream = SFX_COIN_PICKUP
	player.volume_db = -3.5
	player.pitch_scale = randf_range(0.96, 1.06)
	player.play()

func play_countdown_alert() -> void:
	if not _sfx_enabled or _countdown_player == null:
		return
	var now: int = Time.get_ticks_msec()
	if now - _last_countdown_time < COUNTDOWN_COOLDOWN_MS:
		return
	_last_countdown_time = now

	if not _countdown_player.playing:
		_countdown_player.play()

# ---------------------------------------------------------
# Motor Elétrico Contínuo (Engine Loop)
# ---------------------------------------------------------

func start_engine() -> void:
	if _engine_player == null:
		return
	if not _engine_player.playing:
		_engine_player.volume_db = -18.0
		_engine_player.pitch_scale = 0.85
		_engine_player.play()

func stop_engine() -> void:
	if _engine_player != null and _engine_player.playing:
		_engine_player.stop()

func update_engine_speed(speed_ratio: float) -> void:
	if _engine_player == null or not _engine_player.playing:
		return
	var clamped_ratio: float = clampf(speed_ratio, 0.0, 1.0)
	var target_pitch: float = lerpf(0.85, 1.25, clamped_ratio)
	var target_volume: float = lerpf(-18.0, -8.0, clamped_ratio)

	_engine_player.pitch_scale = lerpf(_engine_player.pitch_scale, target_pitch, 0.2)
	_engine_player.volume_db = lerpf(_engine_player.volume_db, target_volume, 0.2)

# ---------------------------------------------------------
# Configurações de Volume e Mute
# ---------------------------------------------------------

func set_music_enabled(enabled: bool) -> void:
	_music_enabled = enabled
	if _music_bus_idx >= 0:
		AudioServer.set_bus_mute(_music_bus_idx, not enabled)
	if not enabled and _music_player != null and _music_player.playing:
		_music_player.stop()
	elif enabled and _music_player != null and not _music_player.playing:
		if GameManager != null and GameManager.current_state == GameManager.GameState.PLAYING:
			play_gameplay_music(0.2)
		else:
			play_menu_music(0.2)

func set_sfx_enabled(enabled: bool) -> void:
	_sfx_enabled = enabled
	if _sfx_bus_idx >= 0:
		AudioServer.set_bus_mute(_sfx_bus_idx, not enabled)
	if not enabled and _engine_player != null:
		_engine_player.stop()
	elif enabled and _engine_player != null and GameManager != null and GameManager.current_state == GameManager.GameState.PLAYING:
		start_engine()

func is_music_enabled() -> bool:
	return _music_enabled

func is_sfx_enabled() -> bool:
	return _sfx_enabled
