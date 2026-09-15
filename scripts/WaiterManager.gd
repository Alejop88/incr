extends Node

const MAX_HIRED_WAITERS: int = 1
const HIRE_COST: float = 100.0
const WAITER_SCENE = preload("res://scenes/restaurant/AutomaticWaiter.tscn")

@onready var restaurant: Node2D = get_parent()
var waiters: Array[CharacterBody2D] = []
# Each waiter reserves a prepared dish ID and a customer's current food round.
# The player can still take that dish or serve that customer first.
var assignments: Dictionary = {}
var payment_assignments: Dictionary = {}

func can_hire() -> bool:
	return waiters.size() < MAX_HIRED_WAITERS

func get_hired_count() -> int:
	return waiters.size()

func restore_hired_count(count: int) -> void:
	while waiters.size() < clampi(count, 0, MAX_HIRED_WAITERS):
		create_waiter()

func create_waiter() -> CharacterBody2D:
	var waiter: CharacterBody2D = WAITER_SCENE.instantiate()
	waiter.coordinator = self
	waiter.waiting_offset = Vector2(90 + waiters.size() * 35, 65)
	waiter.position = restaurant.kitchen_point.position + waiter.waiting_offset
	restaurant.add_child(waiter)
	waiters.append(waiter)
	return waiter

func release_assignment(waiter: CharacterBody2D) -> void:
	assignments.erase(waiter)
	payment_assignments.erase(waiter)

func reserve_payment(waiter: CharacterBody2D) -> bool:
	release_assignment(waiter)
	_clean_freed_waiters()
	var best: Dictionary = {}
	var nearest: float = INF
	for table in restaurant.tables:
		if table.state != table.State.WAITING_PAYMENT or not is_instance_valid(table.get_seated_customer()):
			continue
		if _is_payment_reserved(table):
			continue
		var distance: float = waiter.global_position.distance_squared_to(table.global_position)
		if distance < nearest:
			nearest = distance
			best = {"table": table, "customer": table.get_seated_customer(), "round": table.food_round}
	if best.is_empty():
		return false
	payment_assignments[waiter] = best
	return true

func is_payment_valid(waiter: CharacterBody2D) -> bool:
	return payment_assignments.has(waiter) and _is_payment_target_valid(payment_assignments[waiter])

func get_payment_position(waiter: CharacterBody2D) -> Vector2:
	return payment_assignments[waiter]["table"].global_position + Vector2(0, 45)

func collect_payment(waiter: CharacterBody2D) -> bool:
	if not is_payment_valid(waiter):
		release_assignment(waiter)
		return false
	var collected: bool = payment_assignments[waiter]["table"].collect_payment()
	release_assignment(waiter)
	return collected

func get_waiting_position(waiter: CharacterBody2D) -> Vector2:
	return restaurant.kitchen_point.global_position + waiter.waiting_offset

func reserve_pickup(waiter: CharacterBody2D) -> bool:
	release_assignment(waiter)
	_clean_freed_waiters()
	var kitchen: Node = restaurant.kitchen_point
	var ids: Array[int] = kitchen.get_ready_dish_ids()
	var dishes: Array = kitchen.get_ready_dishes()
	# Reverse order: the most recently cooked available plate goes first.
	for i in range(ids.size() - 1, -1, -1):
		if _is_plate_reserved(ids[i]):
			continue
		var target: Dictionary = _find_customer(waiter, dishes[i])
		if target.is_empty() and _has_waiting_customer(dishes[i]):
			# Other waiters already cover those orders; don't take a spare plate.
			continue
		target["dish_id"] = ids[i]
		target["dish"] = dishes[i]
		assignments[waiter] = target
		return true
	return false

func pickup(waiter: CharacterBody2D) -> DishTypes.Type:
	if not assignments.has(waiter):
		return DishTypes.Type.NONE
	var assignment: Dictionary = assignments[waiter]
	var dish: DishTypes.Type = restaurant.kitchen_point.take_ready_dish_by_id(assignment["dish_id"])
	if dish == DishTypes.Type.NONE:
		release_assignment(waiter)
	else:
		assignment["dish_id"] = -1
	return dish

func is_delivery_valid(waiter: CharacterBody2D) -> bool:
	return assignments.has(waiter) and _is_target_valid(assignments[waiter])

func plan_delivery(waiter: CharacterBody2D) -> String:
	if is_delivery_valid(waiter):
		return "deliver"
	release_assignment(waiter)
	_clean_freed_waiters()
	var target: Dictionary = _find_customer(waiter, waiter.carried_dish)
	if not target.is_empty():
		target["dish_id"] = -1
		target["dish"] = waiter.carried_dish
		assignments[waiter] = target
		return "deliver"
	# Don't throw away a dish still requested by a customer reserved by a colleague.
	return "wait" if _has_waiting_customer(waiter.carried_dish) else "trash"

func get_kitchen_position() -> Vector2:
	return restaurant.kitchen_point.global_position + Vector2(60, 0)

func get_delivery_position(waiter: CharacterBody2D) -> Vector2:
	return assignments[waiter]["table"].global_position + Vector2(0, 45)

func get_trash_position() -> Vector2:
	return restaurant.trash_point.global_position

func deliver(waiter: CharacterBody2D) -> bool:
	if not is_delivery_valid(waiter):
		return false
	var assignment: Dictionary = assignments[waiter]
	var delivered: bool = assignment["table"].receive_food(waiter.carried_dish, assignment["customer"])
	release_assignment(waiter)
	return delivered

func _find_customer(waiter: CharacterBody2D, dish: DishTypes.Type) -> Dictionary:
	var best: Dictionary = {}
	var best_distance: float = INF
	for table in restaurant.tables:
		var leader: CharacterBody2D = table.get_seated_customer()
		if not is_instance_valid(leader):
			continue
		var group: Node = leader.get_parent()
		if not group.has_method("get_customers"):
			continue
		for customer in group.get_customers():
			if not table.can_serve_customer(customer, dish) or _is_customer_reserved(customer):
				continue
			var distance: float = waiter.global_position.distance_squared_to(table.global_position)
			if distance < best_distance:
				best_distance = distance
				best = {"table": table, "customer": customer, "round": table.food_round}
	return best

func _has_waiting_customer(dish: DishTypes.Type) -> bool:
	for table in restaurant.tables:
		var leader: CharacterBody2D = table.get_seated_customer()
		if not is_instance_valid(leader):
			continue
		var group: Node = leader.get_parent()
		if not group.has_method("get_customers"):
			continue
		for customer in group.get_customers():
			if table.can_serve_customer(customer, dish):
				return true
	return false

func _is_target_valid(assignment: Dictionary) -> bool:
	var table: Variant = assignment.get("table")
	var customer: Variant = assignment.get("customer")
	return is_instance_valid(table) and is_instance_valid(customer) \
		and table.food_round == assignment["round"] \
		and table.can_serve_customer(customer, assignment["dish"])

func _is_customer_reserved(customer: CharacterBody2D) -> bool:
	for assignment in assignments.values():
		if _is_target_valid(assignment) and assignment["customer"] == customer:
			return true
	return false

func _is_plate_reserved(dish_id: int) -> bool:
	for assignment in assignments.values():
		if assignment["dish_id"] == dish_id:
			return true
	return false

func _clean_freed_waiters() -> void:
	for waiter in assignments.keys():
		if not is_instance_valid(waiter):
			assignments.erase(waiter)
	for waiter in payment_assignments.keys():
		if not is_instance_valid(waiter):
			payment_assignments.erase(waiter)

func _is_payment_target_valid(assignment: Dictionary) -> bool:
	var table: Variant = assignment.get("table")
	var customer: Variant = assignment.get("customer")
	return is_instance_valid(table) and is_instance_valid(customer) \
		and table.state == table.State.WAITING_PAYMENT \
		and table.get_seated_customer() == customer and table.food_round == assignment["round"]

func _is_payment_reserved(table: Node) -> bool:
	for assignment in payment_assignments.values():
		if _is_payment_target_valid(assignment) and assignment["table"] == table:
			return true
	return false
