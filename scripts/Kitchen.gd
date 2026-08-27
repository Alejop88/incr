class_name Kitchen
extends Area2D

const BASE_COOK_TIME: float = 5.0
const COOK_TIME_REDUCTION_PER_LEVEL: float = 0.2
const MIN_COOK_TIME: float = 0.5

var cook_speed_level: int = 0
var cook_time: float = BASE_COOK_TIME

var current_dish: DishTypes.Type = DishTypes.Type.NONE
var is_cooking: bool = false

@onready var cook_timer: Timer = $CookTimer

var order_queue: Array[DishTypes.Type] = []
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
func add_order(dish: DishTypes.Type) -> void:
	if dish == DishTypes.Type.NONE:
		return

	order_queue.append(dish)

	print(
		"Pedido añadido a cocina: ",
		DishTypes.Type.keys()[dish],
		" | Pedidos pendientes: ",
		order_queue.size()
	)

	try_start_cooking()

func get_pending_order_count() -> int:
	return order_queue.size()
func add_orders(customers: Array) -> void:
	for customer in customers:
		add_order(customer.requested_dish)
func try_start_cooking() -> void:
	if is_cooking:
		return

	if ready_dishes.size() >= counter_capacity:
		print("Mostrador lleno. El cocinero espera")
		return

	if order_queue.is_empty():
		return

	current_dish = order_queue.pop_front()
	is_cooking = true

	print(
		"Cocinando: ",
		DishTypes.Type.keys()[current_dish]
	)

	cook_timer.start(cook_time)
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
func get_ready_dish_count() -> int:
	return ready_dishes.size()
func is_counter_full() -> bool:
	return ready_dishes.size() >= counter_capacity
func get_free_counter_slots() -> int:
	return max(0, counter_capacity - ready_dishes.size())
func increase_counter_capacity(amount: int) -> void:
	counter_capacity += amount
	try_start_cooking()
	print("Nueva capacidad del mostrador: ", counter_capacity)
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

	return DishTypes.Type.keys()[current_dish]
func get_order_queue() -> Array:
	return order_queue.duplicate()
func get_available_manual_dishes() -> Array:
	return [
		DishTypes.Type.PIZZA,
		DishTypes.Type.BURGER
	]
func add_manual_order(dish: DishTypes.Type) -> void:
	order_queue.append(dish)
	try_start_cooking()
func move_order_up(index: int) -> void:
	if index <= 0:
		return

	if index >= order_queue.size():
		return

	var previous_dish = order_queue[index - 1]
	order_queue[index - 1] = order_queue[index]
	order_queue[index] = previous_dish
func move_order_down(index: int) -> void:
	if index < 0:
		return

	if index >= order_queue.size() - 1:
		return

	var next_dish = order_queue[index + 1]
	order_queue[index + 1] = order_queue[index]
	order_queue[index] = next_dish
func cancel_order(index: int) -> void:
	if index < 0:
		return

	if index >= order_queue.size():
		return

	order_queue.remove_at(index)

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
	cook_time = max(
		MIN_COOK_TIME,
		BASE_COOK_TIME - COOK_TIME_REDUCTION_PER_LEVEL * cook_speed_level
	)
func set_cook_speed_level(level: int) -> void:
	cook_speed_level = level
	update_cook_time()
