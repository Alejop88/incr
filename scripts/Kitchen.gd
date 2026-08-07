class_name Kitchen
extends Area2D
@export var cook_time: float = 3.0

var current_dish: DishTypes.Type = DishTypes.Type.NONE
var is_cooking: bool = false

@onready var cook_timer: Timer = $CookTimer

var order_queue: Array[DishTypes.Type] = []
@export var counter_capacity: int = 4

var ready_dishes: Array[DishTypes.Type] = []
func _ready() -> void:
	cook_timer.timeout.connect(_on_cook_timer_timeout)

func _on_cook_timer_timeout() -> void:
	print(
		"Plato terminado: ",
		DishTypes.Type.keys()[current_dish]
	)

	ready_dishes.append(current_dish)

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

	print(
		"Plato recogido del mostrador: ",
		DishTypes.Type.keys()[dish],
		" | Quedan preparados: ",
		ready_dishes.size()
	)

	return dish
