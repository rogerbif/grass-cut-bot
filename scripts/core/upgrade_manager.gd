extends Node

signal coins_changed(new_amount: int)
signal upgrade_purchased(upgrade_name: String, new_level: int)
signal blade_level_changed(new_level: int, is_max: bool)
signal blade_leveled_up(new_level: int, is_max: bool)
signal blade_xp_changed(current_xp: float, max_xp: float, progress_ratio: float)
signal blade_penalized(new_level: int)

var total_coins: int = 0:
	set(val):
		total_coins = val
		coins_changed.emit(total_coins)

# Nível e experiência da lâmina (1 a 6 / MAX)
var blade_level: int = 1
var blade_xp: float = 0.0

# Aliases para compatibilidade reversa
var radius_level: int:
	get:
		return blade_level
	set(v):
		blade_level = clampi(v, 1, 6)

var power_level: int = 1
var speed_level: int:
	get:
		return blade_level
	set(_v):
		pass

var multiplier_level: int = 1

# Requisitos de XP por nível (Lv 1->2: 50, Lv 2->3: 100, Lv 3->4: 180, Lv 4->5: 280, Lv 5->6: 400, Lv 6: MAX)
const XP_REQUIREMENTS: Array[float] = [50.0, 100.0, 180.0, 280.0, 400.0, 0.0]

# Custos de compra na Garagem (até Nível 5)
const BLADE_COSTS: Dictionary = {
	2: 75,
	3: 150,
	4: 300,
	5: 550
}

func _ready() -> void:
	if SaveManager != null and SaveManager.save_data.has("upgrades"):
		var up: Dictionary = SaveManager.save_data.get("upgrades", {}) as Dictionary
		var pl: Dictionary = SaveManager.save_data.get("player", {}) as Dictionary
		load_from_dict(up, int(pl.get("total_coins", 0)))

func load_from_dict(upgrades: Dictionary, coins: int) -> void:
	total_coins = coins
	var raw_lvl: int = int(upgrades.get("blade_level", upgrades.get("radius_level", 1)))
	blade_level = clampi(raw_lvl, 1, 6)
	blade_xp = maxf(0.0, float(upgrades.get("blade_xp", 0.0)))
	if blade_level >= 6:
		blade_xp = 0.0
	coins_changed.emit(total_coins)
	blade_level_changed.emit(blade_level, blade_level >= 6)
	blade_xp_changed.emit(blade_xp, get_xp_required_for_next_level(), get_progress_ratio())

func export_to_dict() -> Dictionary:
	return {
		"blade_level": blade_level,
		"blade_xp": blade_xp,
		"radius_level": blade_level,
		"power_level": 1,
		"speed_level": blade_level,
		"multiplier_level": 1
	}

func add_coins(amount: int) -> void:
	total_coins += amount

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		return true
	return false

# XP e Progressão Dinâmica por Corte
func get_xp_required_for_next_level() -> float:
	if blade_level >= 6:
		return 0.0
	return XP_REQUIREMENTS[blade_level - 1]

func get_progress_ratio() -> float:
	if blade_level >= 6:
		return 1.0
	var req: float = get_xp_required_for_next_level()
	if req <= 0.0:
		return 1.0
	return clampf(blade_xp / req, 0.0, 1.0)

func add_blade_xp(amount: float) -> void:
	if blade_level >= 6:
		return
	blade_xp += amount
	var req: float = get_xp_required_for_next_level()
	var leveled_up: bool = false
	while blade_level < 6 and req > 0.0 and blade_xp >= req:
		blade_xp -= req
		blade_level += 1
		leveled_up = true
		blade_level_changed.emit(blade_level, blade_level >= 6)
		blade_leveled_up.emit(blade_level, blade_level >= 6)
		if AudioManager != null:
			AudioManager.play_sfx("power_up")
		if blade_level >= 6:
			blade_xp = 0.0
			break
		req = get_xp_required_for_next_level()

	blade_xp_changed.emit(blade_xp, get_xp_required_for_next_level(), get_progress_ratio())
	if leveled_up and SaveManager != null:
		SaveManager.save_game()

func penalize_blade_hit() -> bool:
	# Opção A: Perde 1 nível completo imediatamente (Lv. 3 -> Lv. 2 com barra zerada). Se estiver no Lv. 1, barra zera em 0%.
	if blade_level > 1:
		blade_level -= 1
		blade_xp = 0.0
		blade_level_changed.emit(blade_level, false)
		blade_penalized.emit(blade_level)
	else:
		blade_xp = 0.0
		blade_penalized.emit(blade_level)

	blade_xp_changed.emit(0.0, get_xp_required_for_next_level(), 0.0)
	if SaveManager != null:
		SaveManager.save_game()
	return true

# Valores de Gameplay Calibrados
const MAX_BLADE_RADIUS: float = 1.40

static func get_max_blade_radius() -> float:
	return MAX_BLADE_RADIUS

func get_blade_radius() -> float:
	# Raio base de 0.90m + 0.10m por nível (Lv 1 = 0.90m ... Lv 6 = 1.40m)
	return 0.90 + float(blade_level - 1) * 0.10

func get_cutter_speed() -> float:
	# Velocidade base de 3.25m/s + 0.30m/s por nível (Lv 1 = 3.25m/s ... Lv 6 = 4.75m/s)
	return 3.25 + float(blade_level - 1) * 0.30

func get_cutter_power() -> int:
	return 1

func get_coin_multiplier() -> int:
	return 1

func get_blade_tier() -> int:
	if blade_level >= 6:
		return 4
	elif blade_level >= 5:
		return 3
	elif blade_level >= 3:
		return 2
	return 1

func get_blade_tier_name() -> String:
	match get_blade_tier():
		1: return "Lâmina Estelar Tripla"
		2: return "Lâmina Estelar Quádrupla"
		3: return "Lâmina Estelar de Titânio"
		4: return "Lâmina Estelar Hexagonal"
	return "Lâmina Básica"

# Loja / Garagem: Compra de Nível até Nível 5
func get_blade_upgrade_cost() -> int:
	if blade_level >= 5:
		return -1 # Nível máximo permitido para compra direta com moedas
	var next_lvl: int = blade_level + 1
	return int(BLADE_COSTS.get(next_lvl, -1))

func can_buy_blade_upgrade() -> bool:
	if blade_level >= 5:
		return false
	var cost: int = get_blade_upgrade_cost()
	return cost > 0 and total_coins >= cost

func buy_blade_upgrade() -> bool:
	if not can_buy_blade_upgrade():
		if AudioManager != null:
			AudioManager.play_sfx("denied")
		return false

	var cost: int = get_blade_upgrade_cost()
	if spend_coins(cost):
		blade_level += 1
		blade_xp = 0.0
		upgrade_purchased.emit("blade", blade_level)
		blade_level_changed.emit(blade_level, blade_level >= 6)
		blade_leveled_up.emit(blade_level, blade_level >= 6)
		blade_xp_changed.emit(0.0, get_xp_required_for_next_level(), 0.0)
		if AudioManager != null:
			AudioManager.play_sfx("buy")
			AudioManager.play_sfx("power_up")
		if SaveManager != null:
			SaveManager.save_game()
		return true

	if AudioManager != null:
		AudioManager.play_sfx("denied")
	return false

# Compatibilidade com chamadas genéricas
func get_upgrade_cost(upgrade_name: String) -> int:
	if upgrade_name == "radius" or upgrade_name == "blade":
		return get_blade_upgrade_cost()
	return -1

func buy_upgrade(upgrade_name: String) -> bool:
	if upgrade_name == "radius" or upgrade_name == "blade":
		return buy_blade_upgrade()
	return false

func get_level(upgrade_name: String) -> int:
	if upgrade_name == "radius" or upgrade_name == "blade" or upgrade_name == "speed":
		return blade_level
	return 1
