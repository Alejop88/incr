extends Node2D

var group_size: int = 1
var customers: Array[CharacterBody2D] = []
var customer_scene := preload("res://scenes/customer/Customer.tscn")

func get_group_size() -> int:
	return group_size
	
func setup(new_group_size: int) -> void:
	group_size = new_group_size
	create_customers()
	
func create_customers() -> void:
	for i in range(group_size):
		var customer: CharacterBody2D = customer_scene.instantiate()
		customer.group_size = group_size
		add_child(customer)
		customer.visible = false
		customers.append(customer)
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
