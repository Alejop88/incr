extends Node2D

signal customer_paid(amount: float)

@onready var player_waiter: CharacterBody2D = $PlayerWaiter
@onready var kitchen_point: Area2D = $KitchenPoint
@onready var table_01_point = $Table01Point
var base_plate_price: float = 5.0
@onready var customer_spawn_point: Marker2D = $CustomerSpawnPoint
@onready var customer_seat_point: Marker2D = $Table01Point/SeatPoints/Seat01
var customer_scene := preload("res://scenes/customer/Customer.tscn")
func _ready() -> void:
	get_viewport().physics_object_picking = true

	player_waiter.input_pickable = false

	kitchen_point.input_event.connect(_on_kitchen_point_input_event)
	table_01_point.input_event.connect(_on_table_01_point_input_event)

	player_waiter.destination_reached.connect(
		_on_player_waiter_destination_reached
	)

	table_01_point.payment_collected.connect(
		_on_table_payment_collected
	)

	table_01_point.seat_customer()
	
	var customer = customer_scene.instantiate()
	customer.global_position = customer_spawn_point.global_position
	add_child(customer)
	customer.move_to_position(customer_seat_point.global_position)
	
func serve_test_customer() -> void:
	customer_paid.emit(base_plate_price)
	
func _on_kitchen_point_input_event(_viewport: Viewport,event: InputEvent,_shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Clic izquierdo en cocina")
		player_waiter.move_to_position(kitchen_point.global_position,player_waiter.TargetType.KITCHEN)

func _on_table_01_point_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Click en mesa")
		player_waiter.move_to_position(table_01_point.global_position,player_waiter.TargetType.TABLE)
		
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		print(
			"GLOBAL -> botón: ",
			event.button_index,
			" pulsado: ",
			event.pressed,
			" posición: ",
			event.position
		)

	if event is InputEventScreenTouch:
		print(
			"TOUCH -> pulsado: ",
			event.pressed,
			" posición: ",
			event.position
		)
func _on_player_waiter_destination_reached() -> void:
	match player_waiter.target_type:
		player_waiter.TargetType.KITCHEN:
			player_waiter.has_plate = true
			print("El camarero ha recogido un plato")

		player_waiter.TargetType.TABLE:
			if player_waiter.has_plate:
				var delivered: bool = table_01_point.receive_food()

				if delivered:
					player_waiter.has_plate = false
					print("El camarero ha entregado el plato")
			else:
				print("El camarero ha llegado sin plato")
func _on_table_payment_collected(amount: float) -> void:
	customer_paid.emit(amount)
