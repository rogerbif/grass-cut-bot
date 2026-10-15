extends Node

signal coins_changed(new_amount: int)
signal upgrade_purchased(upgrade_name: String, new_level: int)

var total_coins: int = 0:
	set(val):
		total_coins = val
		coins_changed.emit(total_coins)

# Níveis de Upgrade
var radius_level: int = 1
var power_level: int = 1
var speed_level: int = 1
var multiplier_level: int = 1

# Custos base e multiplicadores
const BASE_COST: Dictionary = {
	"radius": 50,
	"power": 100,
	"speed": 60,
	"multiplier": 150
}

func add_coins(amount: int) -> void:
	total_coins += amount

func spend_coins(amount: int) -> bool:
	if total_coins >= amount:
		total_coins -= amount
		return true
	return false

func get_upgrade_cost(upgrade_name: String) -> int:
	var level: int = 1
	match upgrade_name:
		"radius": level = radius_level
		"power": level = power_level
		"speed": level = speed_level
		"multiplier": level = multiplier_level
	var base: int = BASE_COST.get(upgrade_name, 50)
	return int(base * pow(1.6, level - 1))

func buy_upgrade(upgrade_name: String) -> bool:
	var cost := get_upgrade_cost(upgrade_name)
	if spend_coins(cost):
		match upgrade_name:
			"radius": radius_level += 1
			"power": power_level += 1
			"speed": speed_level += 1
			"multiplier": multiplier_level += 1
		upgrade_purchased.emit(upgrade_name, get_level(upgrade_name))
		return true
	return false

func get_level(upgrade_name: String) -> int:
	match upgrade_name:
		"radius": return radius_level
		"power": return power_level
		"speed": return speed_level
		"multiplier": return multiplier_level
	return 1

# Getters para valores no gameplay
func get_blade_radius() -> float:
	# Raio base de 1.18m + 0.15m a cada upgrade
	return 1.18 + (radius_level - 1) * 0.15

func get_cutter_speed() -> float:
	# Velocidade base de 6.5m/s + 0.75m/s por nível
	return 6.5 + (speed_level - 1) * 0.75

func get_cutter_power() -> int:
	return power_level

func get_coin_multiplier() -> int:
	return multiplier_level

func get_blade_tier() -> int:
	var max_lvl: int = maxi(radius_level, power_level)
	if max_lvl >= 7:
		return 4
	elif max_lvl >= 5:
		return 3
	elif max_lvl >= 3:
		return 2
	return 1

func get_blade_tier_name() -> String:
	match get_blade_tier():
		1: return "Lâmina Estelar Tripla"
		2: return "Lâmina Estelar Quádrupla"
		3: return "Lâmina Estelar de Titânio"
		4: return "Lâmina Estelar Hexagonal"
	return "Lâmina Básica"
