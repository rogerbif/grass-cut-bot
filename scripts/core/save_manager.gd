extends Node

signal save_completed(success: bool)
signal save_loaded
signal save_reset

const SAVE_PATH: String = "user://savegame.json"
const TEMP_PATH: String = "user://savegame.tmp"
const BAK_PATH: String = "user://savegame.bak"
const CURRENT_SAVE_VERSION: String = "1.0"

var save_data: Dictionary = {}
var is_initialized: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_game()
	is_initialized = true

func _notification(what: int) -> void:
	# Persiste estado ao sair ou pausar no Android/Desktop
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if is_initialized:
			save_game()

func get_default_save() -> Dictionary:
	return {
		"version": CURRENT_SAVE_VERSION,
		"game_version": GameVersion.get_version_string(),
		"game_version_code": GameVersion.get_version_code(),
		"saved_at": int(Time.get_unix_time_from_system()),
		"settings": {
			"music_enabled": true,
			"sfx_enabled": true,
			"vib_enabled": true,
			"graphics_quality": "balanced"
		},
		"player": {
			"total_coins": 0,
			"max_unlocked_level": 1,
			"last_played_level": 1
		},
		"upgrades": {
			"blade_level": 1,
			"blade_xp": 0.0,
			"radius_level": 1,
			"power_level": 1,
			"speed_level": 1,
			"multiplier_level": 1
		},
		"levels": {}
	}

func load_game() -> bool:
	var path_to_load: String = SAVE_PATH
	if not FileAccess.file_exists(path_to_load):
		if FileAccess.file_exists(BAK_PATH):
			path_to_load = BAK_PATH
		else:
			# Primeiro acesso: gera dados limpos e grava em disco
			save_data = get_default_save()
			save_game()
			save_loaded.emit()
			return true

	var file: FileAccess = FileAccess.open(path_to_load, FileAccess.READ)
	if file == null:
		save_data = get_default_save()
		save_game()
		save_loaded.emit()
		return false

	var content: String = file.get_as_text()
	file.close()

	var test_json_conv: JSON = JSON.new()
	var parse_err: Error = test_json_conv.parse(content)
	if parse_err != OK or not (test_json_conv.data is Dictionary):
		# Arquivo corrompido: tenta recuperar do backup
		if path_to_load != BAK_PATH and FileAccess.file_exists(BAK_PATH):
			var bak_file: FileAccess = FileAccess.open(BAK_PATH, FileAccess.READ)
			if bak_file != null:
				var bak_content: String = bak_file.get_as_text()
				bak_file.close()
				var bak_json: JSON = JSON.new()
				if bak_json.parse(bak_content) == OK and (bak_json.data is Dictionary):
					save_data = _merge_with_defaults(bak_json.data as Dictionary)
					save_game()
					_apply_loaded_data_to_systems()
					save_loaded.emit()
					return true

		# Backup inexistente ou inválido: restaura padrão
		save_data = get_default_save()
		save_game()
		_apply_loaded_data_to_systems()
		save_loaded.emit()
		return false

	save_data = _merge_with_defaults(test_json_conv.data as Dictionary)
	_apply_loaded_data_to_systems()
	save_loaded.emit()
	return true

func _merge_with_defaults(loaded: Dictionary) -> Dictionary:
	var def: Dictionary = get_default_save()
	var merged: Dictionary = def.duplicate(true)

	if loaded.has("version"):
		merged["version"] = loaded["version"]
	if loaded.has("game_version"):
		merged["game_version"] = loaded["game_version"]
	if loaded.has("game_version_code"):
		merged["game_version_code"] = loaded["game_version_code"]
	if loaded.has("saved_at"):
		merged["saved_at"] = loaded["saved_at"]

	if loaded.has("settings") and loaded["settings"] is Dictionary:
		var st: Dictionary = loaded["settings"] as Dictionary
		var def_st: Dictionary = merged["settings"] as Dictionary
		for k in def_st:
			if st.has(k):
				def_st[k] = st[k]

	if loaded.has("player") and loaded["player"] is Dictionary:
		var pl: Dictionary = loaded["player"] as Dictionary
		var def_pl: Dictionary = merged["player"] as Dictionary
		for k in def_pl:
			if pl.has(k):
				def_pl[k] = pl[k]

	if loaded.has("upgrades") and loaded["upgrades"] is Dictionary:
		var up: Dictionary = loaded["upgrades"] as Dictionary
		var def_up: Dictionary = merged["upgrades"] as Dictionary
		for k in def_up:
			if up.has(k):
				def_up[k] = up[k]

	if loaded.has("levels") and loaded["levels"] is Dictionary:
		merged["levels"] = loaded["levels"]

	return merged

func _apply_loaded_data_to_systems() -> void:
	if UpgradeManager != null:
		var up_dict: Dictionary = save_data.get("upgrades", {}) as Dictionary
		var pl_dict: Dictionary = save_data.get("player", {}) as Dictionary
		var coins: int = int(pl_dict.get("total_coins", 0))
		if UpgradeManager.has_method("load_from_dict"):
			UpgradeManager.load_from_dict(up_dict, coins)

	if GameManager != null:
		var pl_dict: Dictionary = save_data.get("player", {}) as Dictionary
		var last_lvl: int = int(pl_dict.get("last_played_level", 1))
		GameManager.current_level = maxi(1, last_lvl)

func save_game() -> bool:
	if save_data.is_empty():
		save_data = get_default_save()

	save_data["saved_at"] = int(Time.get_unix_time_from_system())
	save_data["game_version"] = GameVersion.get_version_string()
	save_data["game_version_code"] = GameVersion.get_version_code()

	# Sincroniza estado ativo dos singletons se existirem
	if UpgradeManager != null:
		var pl: Dictionary = save_data.get("player", {}) as Dictionary
		pl["total_coins"] = UpgradeManager.total_coins
		save_data["player"] = pl

		if UpgradeManager.has_method("export_to_dict"):
			save_data["upgrades"] = UpgradeManager.export_to_dict()
		else:
			save_data["upgrades"] = {
				"radius_level": UpgradeManager.radius_level,
				"power_level": UpgradeManager.power_level,
				"speed_level": UpgradeManager.speed_level,
				"multiplier_level": UpgradeManager.multiplier_level
			}

	if GameManager != null:
		var pl: Dictionary = save_data.get("player", {}) as Dictionary
		pl["last_played_level"] = GameManager.current_level
		save_data["player"] = pl

	var json_str: String = JSON.stringify(save_data, "\t")

	# 1. Grava no arquivo temporário atômico
	var tmp_file: FileAccess = FileAccess.open(TEMP_PATH, FileAccess.WRITE)
	if tmp_file == null:
		save_completed.emit(false)
		return false

	tmp_file.store_string(json_str)
	tmp_file.close()

	# 2. Se o save atual já existe, copia para backup de segurança (.bak)
	if FileAccess.file_exists(SAVE_PATH):
		var cur_file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if cur_file != null:
			var cur_content: String = cur_file.get_as_text()
			cur_file.close()
			var bak_file: FileAccess = FileAccess.open(BAK_PATH, FileAccess.WRITE)
			if bak_file != null:
				bak_file.store_string(cur_content)
				bak_file.close()

	# 3. Transfere arquivo temporário para o save principal
	var save_file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if save_file == null:
		save_completed.emit(false)
		return false
	save_file.store_string(json_str)
	save_file.close()

	# Limpa o temporário
	if FileAccess.file_exists(TEMP_PATH):
		DirAccess.remove_absolute(TEMP_PATH)

	save_completed.emit(true)
	return true

func record_level_victory(level_num: int, time_left: float, time_limit: float, coins_earned: int) -> int:
	var ratio: float = time_left / maxf(time_limit, 1.0)
	var stars: int = 1
	if ratio >= 0.50:
		stars = 3
	elif ratio >= 0.25:
		stars = 2
	else:
		stars = 1

	var levels: Dictionary = save_data.get("levels", {}) as Dictionary
	var key: String = str(level_num)
	var prev_data: Dictionary = levels.get(key, {}) as Dictionary

	var prev_stars: int = int(prev_data.get("stars", 0))
	var final_stars: int = maxi(stars, prev_stars)
	var prev_best_time: float = float(prev_data.get("best_time_left", 0.0))
	var final_best_time: float = maxf(time_left, prev_best_time)
	var prev_high_coins: int = int(prev_data.get("high_score_coins", 0))
	var final_high_coins: int = maxi(coins_earned, prev_high_coins)

	levels[key] = {
		"completed": true,
		"stars": final_stars,
		"best_time_left": final_best_time,
		"high_score_coins": final_high_coins
	}
	save_data["levels"] = levels

	# Desbloqueia próximo nível
	var pl: Dictionary = save_data.get("player", {}) as Dictionary
	var cur_max: int = int(pl.get("max_unlocked_level", 1))
	pl["max_unlocked_level"] = maxi(cur_max, level_num + 1)
	pl["last_played_level"] = level_num
	save_data["player"] = pl

	save_game()
	return final_stars

func is_level_unlocked(level_num: int) -> bool:
	if level_num <= 1:
		return true
	var pl: Dictionary = save_data.get("player", {}) as Dictionary
	var max_unlocked: int = int(pl.get("max_unlocked_level", 1))
	return level_num <= max_unlocked

func get_level_stars(level_num: int) -> int:
	var levels: Dictionary = save_data.get("levels", {}) as Dictionary
	var key: String = str(level_num)
	if levels.has(key) and levels[key] is Dictionary:
		return int(levels[key].get("stars", 0))
	return 0

func get_max_unlocked_level() -> int:
	var pl: Dictionary = save_data.get("player", {}) as Dictionary
	return int(pl.get("max_unlocked_level", 1))

func get_last_played_level() -> int:
	var pl: Dictionary = save_data.get("player", {}) as Dictionary
	return int(pl.get("last_played_level", 1))

func set_last_played_level(lvl: int) -> void:
	var pl: Dictionary = save_data.get("player", {}) as Dictionary
	pl["last_played_level"] = lvl
	save_data["player"] = pl
	save_game()

func get_setting(key: String, default_val: Variant) -> Variant:
	var st: Dictionary = save_data.get("settings", {}) as Dictionary
	return st.get(key, default_val)

func set_setting(key: String, val: Variant) -> void:
	var st: Dictionary = save_data.get("settings", {}) as Dictionary
	st[key] = val
	save_data["settings"] = st
	save_game()

func reset_to_defaults() -> void:
	save_data = get_default_save()

	if UpgradeManager != null:
		if UpgradeManager.has_method("load_from_dict"):
			UpgradeManager.load_from_dict(save_data["upgrades"], 0)
		else:
			UpgradeManager.total_coins = 0
			UpgradeManager.blade_level = 1
			UpgradeManager.blade_xp = 0.0
			UpgradeManager.radius_level = 1
			UpgradeManager.power_level = 1
			UpgradeManager.speed_level = 1
			UpgradeManager.multiplier_level = 1

	if GameManager != null:
		GameManager.current_level = 1

	save_game()
	save_reset.emit()
