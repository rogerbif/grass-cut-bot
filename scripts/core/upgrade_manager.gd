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

# Nível e experiência da lâmina (1 a 10 / MAX)
const MAX_BLADE_LEVEL: int = 10
const BLADE_ROCK_PENALTY_XP: float = 1000.0

var blade_level: int = 1
var blade_xp: float = 0.0

# Aliases para compatibilidade reversa
var radius_level: int:
	get:
		return blade_level
	set(v):
		blade_level = clampi(v, 1, MAX_BLADE_LEVEL)

var power_level: int = 1
var speed_level: int:
	get:
		return blade_level
	set(_v):
		pass

var multiplier_level: int = 1

# Requisitos de XP por nível (totalizando exatamente 12.000 XP acumulado no Lv 10 MAX)
# Lv 1->2: 200, 2->3: 350, 3->4: 550, 4->5: 800, 5->6: 1200, 6->7: 1700, 7->8: 2400, 8->9: 3300, 9->10: 1500 (ou 4800) -> 12k acumulado
const XP_REQUIREMENTS: Array[float] = [
	200.0, 350.0, 550.0, 800.0, 1200.0, 1700.0, 2400.0, 3300.0, 1500.0, 0.0
]

# Custos de compra progressivos na Garagem (até Nível 8)
const BLADE_COSTS: Dictionary = {
	2: 100,
	3: 250,
	4: 500,
	5: 900,
	6: 1500,
	7: 2400,
	8: 3800
}

func _ready() -> void:
	if SaveManager != null and SaveManager.save_data.has("upgrades"):
		var up: Dictionary = SaveManager.save_data.get("upgrades", {}) as Dictionary
		var pl: Dictionary = SaveManager.save_data.get("player", {}) as Dictionary
		load_from_dict(up, int(pl.get("total_coins", 0)))

func load_from_dict(upgrades: Dictionary, coins: int) -> void:
	total_coins = coins
	var raw_lvl: int = int(upgrades.get("blade_level", upgrades.get("radius_level", 1)))
	blade_level = clampi(raw_lvl, 1, MAX_BLADE_LEVEL)
	blade_xp = maxf(0.0, float(upgrades.get("blade_xp", 0.0)))
	if blade_level >= MAX_BLADE_LEVEL:
		blade_xp = 0.0
	coins_changed.emit(total_coins)
	blade_level_changed.emit(blade_level, blade_level >= MAX_BLADE_LEVEL)
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
	if blade_level >= MAX_BLADE_LEVEL:
		return 0.0
	return XP_REQUIREMENTS[blade_level - 1]

func get_progress_ratio() -> float:
	if blade_level >= MAX_BLADE_LEVEL:
		return 1.0
	var req: float = get_xp_required_for_next_level()
	if req <= 0.0:
		return 1.0
	return clampf(blade_xp / req, 0.0, 1.0)

func add_blade_xp(amount: float) -> void:
	if blade_level >= MAX_BLADE_LEVEL:
		return
	blade_xp += amount
	var req: float = get_xp_required_for_next_level()
	var leveled_up: bool = false
	while blade_level < MAX_BLADE_LEVEL and req > 0.0 and blade_xp >= req:
		blade_xp -= req
		blade_level += 1
		leveled_up = true
		blade_level_changed.emit(blade_level, blade_level >= MAX_BLADE_LEVEL)
		blade_leveled_up.emit(blade_level, blade_level >= MAX_BLADE_LEVEL)
		if AudioManager != null:
			AudioManager.play_sfx("power_up")
		if blade_level >= MAX_BLADE_LEVEL:
			blade_xp = 0.0
			break
		req = get_xp_required_for_next_level()

	blade_xp_changed.emit(blade_xp, get_xp_required_for_next_level(), get_progress_ratio())
	if leveled_up and SaveManager != null:
		SaveManager.save_game()

func penalize_blade_hit(penalty_amount: float = BLADE_ROCK_PENALTY_XP) -> bool:
	var remaining_penalty: float = penalty_amount
	var old_level: int = blade_level

	# Se estiver no nível máximo (10), transiciona para o nível 9 com barra cheia antes de descontar
	if blade_level >= MAX_BLADE_LEVEL:
		blade_level = MAX_BLADE_LEVEL - 1
		blade_xp = get_xp_required_for_next_level()

	while remaining_penalty > 0.0:
		if blade_xp >= remaining_penalty:
			blade_xp -= remaining_penalty
			remaining_penalty = 0.0
		else:
			remaining_penalty -= blade_xp
			blade_xp = 0.0
			if blade_level > 1:
				blade_level -= 1
				blade_xp = get_xp_required_for_next_level()
			else:
				# Nível 1 com XP esgotado, cessa dedução
				blade_xp = 0.0
				remaining_penalty = 0.0

	if blade_level != old_level:
		blade_level_changed.emit(blade_level, false)
	blade_penalized.emit(blade_level)
	blade_xp_changed.emit(blade_xp, get_xp_required_for_next_level(), get_progress_ratio())

	if SaveManager != null:
		SaveManager.save_game()
	return true

# Valores de Gameplay Calibrados
const MAX_BLADE_RADIUS: float = 1.40

static func get_max_blade_radius() -> float:
	return MAX_BLADE_RADIUS

func get_blade_radius() -> float:
	# Raio base de 0.90m no Lv 1 até 1.40m no Lv 10 (passo suave de ~0.0556m por nível)
	return 0.90 + float(blade_level - 1) * (0.50 / 9.0)

func get_cutter_speed() -> float:
	# Velocidade base de 1.95m/s + 0.18m/s por nível (Lv 1 = 1.95m/s ... Lv 10 = 3.57m/s)
	return 1.95 + float(blade_level - 1) * 0.18

func get_cutter_power() -> int:
	return 1

func get_coin_multiplier() -> int:
	return 1

func get_blade_tier() -> int:
	if blade_level >= 9:
		return 4 # Hexagonal
	elif blade_level >= 7:
		return 3 # Titânio
	elif blade_level >= 4:
		return 2 # Quádrupla
	return 1 # Tripla

func get_blade_tier_name() -> String:
	match get_blade_tier():
		1: return tr("BLADE_TIER_1")
		2: return tr("BLADE_TIER_2")
		3: return tr("BLADE_TIER_3")
		4: return tr("BLADE_TIER_4")
	return tr("BLADE_TIER_DEFAULT")

# Loja / Garagem: Compra de Nível até Nível 8
func get_blade_upgrade_cost() -> int:
	if blade_level >= 8:
		return -1 # Nível máximo permitido para compra direta com moedas
	var next_lvl: int = blade_level + 1
	return int(BLADE_COSTS.get(next_lvl, -1))

func can_buy_blade_upgrade() -> bool:
	if blade_level >= 8:
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
		blade_level_changed.emit(blade_level, blade_level >= MAX_BLADE_LEVEL)
		blade_leveled_up.emit(blade_level, blade_level >= MAX_BLADE_LEVEL)
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
