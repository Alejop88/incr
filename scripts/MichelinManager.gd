extends Node

signal stars_changed(new_stars: int)
signal counter_capacity_bonus_changed(new_bonus: int)

var stars: int = 5
var bought_upgrades: Dictionary = {}
var selected_upgrades: Array[String] = []
var counter_capacity_bonus: int = 0
var cook_speed_bonus: int = 0
var vip_spawn_bonus: int = 0
var max_vip_group_size: int = 1
var upgrade_costs: Dictionary = {
	"counter_capacity_1": 1,
	"counter_capacity_2": 3,
	"cook_speed_1": 2,
	"vip_spawn_1": 2,
	"vip_spawn_2": 4,
	"vip_group_2": 3,
	"vip_group_3": 5,
	"vip_group_4": 8
}
var upgrade_descriptions: Dictionary = {
	"counter_capacity_1": "Añade +1 espacio para platos preparados.",
	"counter_capacity_2": "Añade +2 espacios para platos preparados.",
	"cook_speed_1": "Aumenta la velocidad de cocina.",
	"vip_spawn_1": "Aumenta la probabilidad de aparición de clientes VIP.",
	"vip_spawn_2": "Aumenta todavía más la probabilidad de aparición de clientes VIP.",
	"vip_group_2": "Permite que los clientes VIP puedan aparecer en pareja.",
	"vip_group_3": "Permite que los clientes VIP puedan aparecer en grupos de tres.",
	"vip_group_4": "Permite que los clientes VIP puedan aparecer en grupos de cuatro."
}
var upgrade_names: Dictionary = {
	"counter_capacity_1": "Mostrador ampliado",
	"counter_capacity_2": "Mostrador ampliado II",
	"cook_speed_1": "Cocinero más rápido",
	"vip_spawn_1": "Más clientes VIP",
	"vip_spawn_2": "Más clientes VIP II",
	"vip_group_2": "VIP en pareja",
	"vip_group_3": "VIP en trío",
	"vip_group_4": "VIP en grupo de cuatro"
}
var upgrade_requirements: Dictionary = {
	"counter_capacity_1": [],
	"counter_capacity_2": ["counter_capacity_1"],
	"cook_speed_1": [],
	"vip_spawn_1": [],
	"vip_spawn_2": ["vip_spawn_1"],
	"vip_group_2": ["vip_spawn_1"],
	"vip_group_3": ["vip_group_2"],
	"vip_group_4": ["vip_group_3"]
}
var upgrade_counter_capacity_bonus: Dictionary = {
	"counter_capacity_1": 1,
	"counter_capacity_2": 2
}
var upgrade_cook_speed_bonus: Dictionary = {
	"cook_speed_1": 1
}
var upgrade_vip_spawn_bonus: Dictionary = {
	"vip_spawn_1": 1,
	"vip_spawn_2": 1
}
var upgrade_vip_group_size: Dictionary = {
	"vip_group_2": 2,
	"vip_group_3": 3,
	"vip_group_4": 4
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

func get_save_data() -> Dictionary:
	var purchased_upgrade_ids: Array[String] = []
	for upgrade_id in bought_upgrades:
		if is_upgrade_bought(upgrade_id):
			purchased_upgrade_ids.append(upgrade_id)

	return {
		"stars": stars,
		"bought_upgrades": purchased_upgrade_ids
	}

func load_save_data(data: Dictionary) -> void:
	stars = int(data["stars"])
	selected_upgrades.clear()
	bought_upgrades.clear()
	counter_capacity_bonus = 0
	cook_speed_bonus = 0
	vip_spawn_bonus = 0
	max_vip_group_size = 1
	for upgrade_id in data["bought_upgrades"]:
		if not upgrade_costs.has(upgrade_id) or is_upgrade_bought(upgrade_id):
			continue
		bought_upgrades[upgrade_id] = true
		counter_capacity_bonus += int(upgrade_counter_capacity_bonus.get(upgrade_id, 0))
		cook_speed_bonus += int(upgrade_cook_speed_bonus.get(upgrade_id, 0))
		vip_spawn_bonus += int(upgrade_vip_spawn_bonus.get(upgrade_id, 0))
		max_vip_group_size = maxi(max_vip_group_size, int(upgrade_vip_group_size.get(upgrade_id, 1)))

func buy_upgrade(upgrade_id: String) -> bool:
	if not are_upgrade_requirements_met(upgrade_id):
		return false

	if upgrade_counter_capacity_bonus.has(upgrade_id):
		return _buy_counter_capacity_upgrade(upgrade_id)

	if upgrade_cook_speed_bonus.has(upgrade_id):
		return _buy_cook_speed_upgrade(upgrade_id)

	if upgrade_vip_spawn_bonus.has(upgrade_id):
		return _buy_vip_spawn_upgrade(upgrade_id)

	if upgrade_vip_group_size.has(upgrade_id):
		return _buy_vip_group_upgrade(upgrade_id)
	return false
func _buy_counter_capacity_upgrade(upgrade_id: String) -> bool:
	if is_upgrade_bought(upgrade_id):
		return false

	var cost: int = upgrade_costs[upgrade_id]

	if not spend_stars(cost):
		return false

	bought_upgrades[upgrade_id] = true

	counter_capacity_bonus += upgrade_counter_capacity_bonus[upgrade_id]

	counter_capacity_bonus_changed.emit(counter_capacity_bonus)

	return true
func _buy_cook_speed_upgrade(upgrade_id: String) -> bool:
	if is_upgrade_bought(upgrade_id):
		return false

	var cost: int = upgrade_costs[upgrade_id]

	if not spend_stars(cost):
		return false

	bought_upgrades[upgrade_id] = true

	cook_speed_bonus += upgrade_cook_speed_bonus[upgrade_id]

	return true
func _buy_vip_spawn_upgrade(upgrade_id: String) -> bool:
	if is_upgrade_bought(upgrade_id):
		return false

	var cost: int = upgrade_costs[upgrade_id]

	if not spend_stars(cost):
		return false

	bought_upgrades[upgrade_id] = true

	vip_spawn_bonus += upgrade_vip_spawn_bonus[upgrade_id]

	return true
func _buy_vip_group_upgrade(upgrade_id: String) -> bool:
	if is_upgrade_bought(upgrade_id):
		return false

	var cost: int = upgrade_costs[upgrade_id]

	if not spend_stars(cost):
		return false

	bought_upgrades[upgrade_id] = true

	max_vip_group_size = max(
		max_vip_group_size,
		upgrade_vip_group_size[upgrade_id]
	)

	return true
func is_upgrade_bought(upgrade_id: String) -> bool:
	return bought_upgrades.get(upgrade_id, false)
func get_upgrade_cost(upgrade_id: String) -> int:
	return upgrade_costs.get(upgrade_id, 0)
func get_upgrade_description(upgrade_id: String) -> String:
	return upgrade_descriptions.get(upgrade_id, "")
func get_upgrade_name(upgrade_id: String) -> String:
	return upgrade_names.get(upgrade_id, "")
func are_upgrade_requirements_met(upgrade_id: String, include_selected: bool = false) -> bool:
	var requirements: Array = upgrade_requirements.get(upgrade_id, [])

	for required_upgrade_id in requirements:
		if not is_upgrade_bought(required_upgrade_id) \
				and not (include_selected and required_upgrade_id in selected_upgrades):
			return false

	return true

func toggle_selection(upgrade_id: String) -> void:
	if not upgrade_costs.has(upgrade_id) or is_upgrade_bought(upgrade_id):
		return
	if upgrade_id in selected_upgrades:
		selected_upgrades.erase(upgrade_id)
		# Removing one prerequisite can invalidate several levels of descendants.
		var changed: bool = true
		while changed:
			changed = false
			for selected_id in selected_upgrades.duplicate():
				if not are_upgrade_requirements_met(selected_id, true):
					selected_upgrades.erase(selected_id)
					changed = true
	elif are_upgrade_requirements_met(upgrade_id, true):
		selected_upgrades.append(upgrade_id)

func get_selected_cost() -> int:
	var total: int = 0
	for upgrade_id in selected_upgrades:
		total += get_upgrade_cost(upgrade_id)
	return total

func get_selected_purchase_data() -> Dictionary:
	# Preview only: do not spend stars or apply any bonus until the reset is saved.
	if selected_upgrades.is_empty() or get_selected_cost() > stars:
		return {}
	var seen: Dictionary = {}
	for upgrade_id in selected_upgrades:
		if not upgrade_costs.has(upgrade_id) or is_upgrade_bought(upgrade_id) \
				or seen.has(upgrade_id) or not are_upgrade_requirements_met(upgrade_id, true):
			return {}
		seen[upgrade_id] = true
	var result: Dictionary = get_save_data()
	result["stars"] = stars - get_selected_cost()
	result["bought_upgrades"].append_array(selected_upgrades)
	return result
