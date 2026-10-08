class_name Kitchen
extends Area2D

const BASE_COOK_TIME: float = 5.0
const COOK_TIME_REDUCTION_PER_LEVEL: float = 0.2
const MIN_COOK_TIME: float = 0.5

var cook_speed_level: int = 0
var menu_speed_multiplier: float = 1.0
var menu_effects: Dictionary = preload("res://scripts/MenuTraits.gd").calculate("cozy", [])
var cook_time: float = BASE_COOK_TIME

var current_dish: DishTypes.Type = DishTypes.Type.NONE
var is_cooking: bool = false

@onready var cook_timer: Timer = $CookTimer

var order_queue: Array[DishTypes.Type] = []
var order_contexts: Array[Dictionary] = []
const BASE_COUNTER_CAPACITY: int = 4
@export var counter_capacity: int = BASE_COUNTER_CAPACITY
var counter_capacity_bonus: int = 0
const COUNTER_CAPACITY_PER_MICHELIN_LEVEL: int = 1
var ready_dishes: Array[DishTypes.Type] = []
var ready_dish_ids: Array[int] = []
var next_ready_dish_id: int = 0
func _ready() -> void:
	cook_timer.timeout.connect(_on_cook_timer_timeout)
	update_cook_time()
func _on_cook_timer_timeout() -> void:
	print(
		"Plato terminado: ",
		DishTypes.Type.keys()[current_dish]
	)

	ready_dishes.append(current_dish)
	ready_dish_ids.append(next_ready_dish_id)
	next_ready_dish_id += 1
	print(
		"Platos preparados: ",
		ready_dishes.size(),
		"/",
		counter_capacity
	)

	is_cooking = false
	current_dish = DishTypes.Type.NONE

	try_start_cooking()
func add_order(dish: DishTypes.Type, context: Dictionary = {}) -> void:
	if dish == DishTypes.Type.NONE:
		return

	order_queue.append(dish)
	order_contexts.append(context)

	print(
		"Pedido añadido a cocina: ",
		DishTypes.Type.keys()[dish],
		" | Pedidos pendientes: ",
		order_queue.size()
	)

	try_start_cooking()

func add_orders(customers: Array, table: Node = null) -> void:
	var counts := {}
	for customer in customers:
		counts[customer.requested_dish] = int(counts.get(customer.requested_dish, 0)) + 1
	for customer in customers:
		var context := {}
		if table != null:
			context = {"table": weakref(table), "round": table.food_round, "repeated": counts[customer.requested_dish]}
		add_order(customer.requested_dish, context)
func try_start_cooking() -> void:
	if is_cooking:
		return

	if ready_dishes.size() >= counter_capacity:
		print("Mostrador lleno. El cocinero espera")
		return

	if order_queue.is_empty():
		return

	current_dish = order_queue.pop_front()
	var context: Dictionary = order_contexts.pop_front() if not order_contexts.is_empty() else {}
	is_cooking = true

	print(
		"Cocinando: ",
		DishTypes.Type.keys()[current_dish]
	)

	cook_timer.start(get_dish_cook_time(current_dish, context))

func get_base_cook_time() -> float:
	return maxf(MIN_COOK_TIME, BASE_COOK_TIME - COOK_TIME_REDUCTION_PER_LEVEL * cook_speed_level)

func get_dish_cook_time(dish: int, context: Dictionary = {}) -> float:
	var traits = preload("res://scripts/MenuTraits.gd")
	var repeated := 1
	if context.has("table"):
		var table: Node = context.table.get_ref()
		if is_instance_valid(table) and table.food_round == context.round and table.state == table.State.WAITING_FOOD:
			repeated = context.repeated
	return cook_time / traits.dish_multiplier(dish, menu_effects, "cooking_speed", DishTypes.CATALOG) / traits.sharing_speed(dish, repeated, menu_effects)
func take_ready_dish() -> DishTypes.Type:
	if ready_dishes.is_empty():
		return DishTypes.Type.NONE

	var dish: DishTypes.Type = ready_dishes.pop_front()
	ready_dish_ids.pop_front()
	print(
		"Plato recogido del mostrador: ",
		DishTypes.Type.keys()[dish],
		" | Quedan preparados: ",
		ready_dishes.size()
	)
	try_start_cooking()
	return dish
func update_counter_capacity_from_bonus() -> void:
	counter_capacity = BASE_COUNTER_CAPACITY + counter_capacity_bonus

	try_start_cooking()

	print("Capacidad del mostrador actualizada: ",counter_capacity)
func set_counter_capacity_bonus(bonus: int) -> void:
	counter_capacity_bonus = bonus
	update_counter_capacity_from_bonus()
func get_ready_dishes_count() -> int:
	return ready_dishes.size()

func get_counter_capacity() -> int:
	return counter_capacity
func get_ready_dishes() -> Array:
	return ready_dishes.duplicate()
func get_cooking_progress() -> float:
	if not is_cooking:
		return 0.0

	if cook_timer.wait_time <= 0.0:
		return 0.0

	var elapsed: float = cook_timer.wait_time - cook_timer.time_left
	return clamp(elapsed / cook_timer.wait_time * 100.0, 0.0, 100.0)
func get_current_dish_name() -> String:
	if not is_cooking:
		return ""

	return DishTypes.title(current_dish)
func get_order_queue() -> Array:
	return order_queue.duplicate()
func get_available_manual_dishes() -> Array:
	return DishTypes.CATALOG.keys()
func add_manual_order(dish: DishTypes.Type) -> void:
	var context := {}
	# Manual copies can fulfil an outstanding repeated order from one actual table.
	var most_repeated := 1
	for table in get_tree().get_nodes_in_group("restaurant_tables"):
		if table.state != table.State.WAITING_FOOD or not is_instance_valid(table.seated_customer):
			continue
		var count := 0
		var pending := false
		for customer in table.seated_customer.get_parent().get_customers():
			if customer is VIPCustomer and customer.dishes_eaten >= customer.total_dishes_to_eat:
				continue
			if customer.requested_dish == dish:
				count += 1
				pending = pending or not customer.has_received_food
		if pending and count > most_repeated:
			most_repeated = count
			context = {"table": weakref(table), "round": table.food_round, "repeated": count}
	add_order(dish, context)
func move_order_up(index: int) -> void:
	if index <= 0:
		return

	if index >= order_queue.size():
		return

	var previous_dish = order_queue[index - 1]
	order_queue[index - 1] = order_queue[index]
	order_queue[index] = previous_dish
	var previous_context: Dictionary = order_contexts[index - 1]
	order_contexts[index - 1] = order_contexts[index]
	order_contexts[index] = previous_context
func move_order_down(index: int) -> void:
	if index < 0:
		return

	if index >= order_queue.size() - 1:
		return

	var next_dish = order_queue[index + 1]
	order_queue[index + 1] = order_queue[index]
	order_queue[index] = next_dish
	var next_context: Dictionary = order_contexts[index + 1]
	order_contexts[index + 1] = order_contexts[index]
	order_contexts[index] = next_context
func cancel_order(index: int) -> void:
	if index < 0:
		return

	if index >= order_queue.size():
		return

	order_queue.remove_at(index)
	order_contexts.remove_at(index)

func get_ready_dish_ids() -> Array[int]:
	return ready_dish_ids.duplicate()
func take_ready_dish_by_id(dish_id: int) -> DishTypes.Type:
	var index: int = ready_dish_ids.find(dish_id)

	if index == -1:
		return DishTypes.Type.NONE

	var dish: DishTypes.Type = ready_dishes[index]

	ready_dishes.remove_at(index)
	ready_dish_ids.remove_at(index)

	print(
		"Plato recogido por ID: ",
		dish_id,
		" | Plato: ",
		DishTypes.Type.keys()[dish]
	)

	try_start_cooking()

	return dish
func update_cook_time() -> void:
	cook_time = get_base_cook_time() * float(menu_effects.cooking_time) / menu_speed_multiplier
func set_cook_speed_level(level: int) -> void:
	cook_speed_level = level
	update_cook_time()
