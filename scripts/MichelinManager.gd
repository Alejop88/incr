extends Node

signal stars_changed(new_stars: int)
signal counter_capacity_bonus_changed(new_bonus: int)

var stars: int = 0
var bought_upgrades: Dictionary = {}
var counter_capacity_bonus: int = 0

var upgrade_costs: Dictionary = {
	"counter_capacity_1": 1
}
var upgrade_descriptions: Dictionary = {
	"counter_capacity_1": "Añade +1 espacio para platos preparados."
}
var upgrade_names: Dictionary = {
	"counter_capacity_1": "Mostrador ampliado"
}

func add_stars(amount: int) -> void:
	stars += amount
	stars_changed.emit(stars)
func spend_stars(amount: int) -> bool:
	if stars < amount:
		return false

	stars -= amount
	stars_changed.emit(stars)
	return true
func get_stars() -> int:
	return stars
func _buy_counter_capacity_1() -> bool:
	if is_upgrade_bought("counter_capacity_1"):
		return false
	if not spend_stars(upgrade_costs["counter_capacity_1"]):
		return false
	bought_upgrades["counter_capacity_1"] = true
	counter_capacity_bonus += 1
	counter_capacity_bonus_changed.emit(counter_capacity_bonus)
	return true
func buy_upgrade(upgrade_id: String) -> bool:
	match upgrade_id:
		"counter_capacity_1":
			return _buy_counter_capacity_1()

	return false

func is_upgrade_bought(upgrade_id: String) -> bool:
	return bought_upgrades.get(upgrade_id, false)
func get_upgrade_cost(upgrade_id: String) -> int:
	return upgrade_costs.get(upgrade_id, 0)
func get_upgrade_description(upgrade_id: String) -> String:
	return upgrade_descriptions.get(upgrade_id, "")
func get_upgrade_name(upgrade_id: String) -> String:
	return upgrade_names.get(upgrade_id, "")
