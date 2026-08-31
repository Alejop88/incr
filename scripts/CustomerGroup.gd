extends Node2D

var group_size: int = 1
var customers: Array[CharacterBody2D] = []
var customer_scene := preload("res://scenes/customer/Customer.tscn")
var vip_customer_scene := preload("res://scenes/customer/VIPCustomer.tscn")
var is_vip_group: bool = false
signal queue_patience_expired(customer_group)

@export var queue_patience_time: float = 60.0

@onready var queue_patience_timer: Timer = $QueuePatienceTimer
func _ready() -> void:
	queue_patience_timer.timeout.connect(_on_queue_patience_timer_timeout)
func get_group_size() -> int:
	return group_size
	
func setup(new_group_size: int) -> void:
	group_size = new_group_size
	create_customers()
	
func create_customers() -> void:
	for i in range(group_size):
		var scene_to_use: PackedScene = customer_scene
		if is_vip_group:
			scene_to_use = vip_customer_scene
		var customer: CharacterBody2D = scene_to_use.instantiate()
		
		customer.group_size = group_size
		add_child(customer)
		var available_dishes: Array[DishTypes.Type] = \
		[
			DishTypes.Type.BURGER,
			DishTypes.Type.PIZZA
		]
		customer.set_requested_dish(available_dishes.pick_random())
		customer.visible = false
		customers.append(customer)
		print(
			"Cliente ",
			i + 1,
			" ha pedido: ",
			DishTypes.Type.keys()[customer.requested_dish]
		)

	print("Grupo creado con ", customers.size(), " clientes")
func get_leader() -> CharacterBody2D:
	if customers.is_empty():
		return null
	customers[0].visible = true
	return customers[0]
func get_customers() -> Array[CharacterBody2D]:
	return customers
func get_customer(index: int) -> CharacterBody2D:
	if index < 0 or index >= customers.size():
		return null

	return customers[index]
func get_customer_count() -> int:
	return customers.size()
func move_customers_to_seats(seat_positions: Array[Vector2]) -> void:
	for i in range(customers.size()):
		var customer: CharacterBody2D = customers[i]
		customer.visible = true
		customer.move_to_position(seat_positions[i],customer.TargetType.TABLE)
func leave_restaurant(exit_position: Vector2) -> void:
	for customer in customers:
		customer.leave_restaurant(exit_position)
		customer.destination_reached.connect(
			_on_customer_exit_reached.bind(customer),
			CONNECT_ONE_SHOT
		)
func _on_customer_exit_reached(customer: CharacterBody2D) -> void:
	customer.queue_free()

	if customers.has(customer):
		customers.erase(customer)

	if customers.is_empty():
		queue_free()
func move_to_queue_position(queue_position: Vector2) -> void:
	var horizontal_spacing: float = 18.0
	var vertical_spacing: float = 18.0

	var positions: Array[Vector2] = []

	match customers.size():
		1:
			positions = [
				Vector2.ZERO
			]

		2:
			positions = [
				Vector2(-horizontal_spacing / 2.0, 0.0),
				Vector2(horizontal_spacing / 2.0, 0.0)
			]

		3:
			positions = [
				Vector2(-horizontal_spacing / 2.0, -vertical_spacing / 2.0),
				Vector2(horizontal_spacing / 2.0, -vertical_spacing / 2.0),
				Vector2(0.0, vertical_spacing / 2.0)
			]

		4:
			positions = [
				Vector2(-horizontal_spacing / 2.0, -vertical_spacing / 2.0),
				Vector2(horizontal_spacing / 2.0, -vertical_spacing / 2.0),
				Vector2(-horizontal_spacing / 2.0, vertical_spacing / 2.0),
				Vector2(horizontal_spacing / 2.0, vertical_spacing / 2.0)
			]

	for i in range(customers.size()):
		var customer: CharacterBody2D = customers[i]

		customer.visible = true
		customer.move_to_position(
			queue_position + positions[i],
			customer.TargetType.QUEUE
		)
func start_queue_patience() -> void:
	queue_patience_timer.start(queue_patience_time)


func stop_queue_patience() -> void:
	queue_patience_timer.stop()


func _on_queue_patience_timer_timeout() -> void:
	queue_patience_expired.emit(self)
