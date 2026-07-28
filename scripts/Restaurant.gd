extends Node2D

signal customer_paid(amount: float)

@onready var player_waiter: CharacterBody2D = $PlayerWaiter
@onready var kitchen_point: Area2D = $KitchenPoint
@onready var table = $Table01Point
const BASE_PLATE_PRICE: float = 5.0
var plate_price: float = BASE_PLATE_PRICE
var plate_price_level: int = 0
const PLATE_PRICE_INCREMENT: float = 1.0
const MAX_PLATE_PRICE_LEVEL: int = 10
const MAX_WAITER_SPEED_LEVEL: int = 10
var waiter_speed_level: int = 0
@onready var customer_spawn_point: Marker2D = $CustomerSpawnPoint
@onready var customer_exit_point: Marker2D = $CustomerExitPoint
@onready var customer_spawn_timer: Timer = $CustomerSpawnTimer
var active_customers: Array[CharacterBody2D] = []
var table_01_customer: CharacterBody2D = null
var customer_scene := preload("res://scenes/customer/Customer.tscn")
func _ready() -> void:
	get_viewport().physics_object_picking = true

	player_waiter.input_pickable = false

	kitchen_point.input_event.connect(_on_kitchen_point_input_event)
	table.input_event.connect(_on_table_01_point_input_event)

	player_waiter.destination_reached.connect(_on_player_waiter_destination_reached)
	table.payment_collected.connect(_on_table_payment_collected)

	update_stats()
	spawn_customer()
	customer_spawn_timer.timeout.connect(_on_customer_spawn_timer_timeout)
func serve_test_customer() -> void:
	customer_paid.emit(plate_price)
	
func _on_kitchen_point_input_event(_viewport: Viewport,event: InputEvent,_shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Clic izquierdo en cocina")
		player_waiter.move_to_position(kitchen_point.global_position,player_waiter.TargetType.KITCHEN)

func _on_table_01_point_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Click en mesa")
		player_waiter.move_to_position(table.global_position,player_waiter.TargetType.TABLE)
		
#func _input(event: InputEvent) -> void:
#	if event is InputEventMouseButton:
#		print(
#			"GLOBAL -> botón: ",
#			event.button_index,
#			" pulsado: ",
#			event.pressed,
#			" posición: ",
#			event.position
#		)

	if event is InputEventScreenTouch:
		print(
			"TOUCH -> pulsado: ",
			event.pressed,
			" posición: ",
			event.position
		)
func _on_player_waiter_destination_reached() -> void:
	print(
		"CAMARERO LLEGÓ. Tipo de destino: ",
		player_waiter.target_type
	)

	match player_waiter.target_type:
		player_waiter.TargetType.KITCHEN:
			player_waiter.has_plate = true
			print("El camarero ha recogido un plato")

		player_waiter.TargetType.TABLE:
			if player_waiter.has_plate:
				var delivered: bool = table.receive_food()

				if delivered:
					player_waiter.has_plate = false
					print("El camarero ha entregado el plato")
			else:
				print("El camarero ha llegado sin plato")

func _on_table_payment_collected(amount: float) -> void:
	customer_paid.emit(amount)
	var customer: CharacterBody2D = table.get_seated_customer()
	if customer != null:
		customer.leave_restaurant(customer_exit_point.global_position)

func _on_customer_destination_reached(
	customer: CharacterBody2D
) -> void:
	match customer.target_type:
		customer.TargetType.TABLE:
			print("El cliente ha llegado a la mesa")

			table_01_customer = customer
			table.seat_customer(customer)
			customer.is_seated = true
		customer.TargetType.EXIT:
			print("El cliente ha salido del restaurante")

			active_customers.erase(customer)

			if table_01_customer == customer:
				table_01_customer = null

			customer.queue_free()
			customer_spawn_timer.start()
func spawn_customer() -> void:
	var customer: CharacterBody2D = customer_scene.instantiate()

	customer.global_position = customer_spawn_point.global_position
	add_child(customer)

	active_customers.append(customer)
	customer.destination_reached.connect(_on_customer_destination_reached.bind(customer))
	customer.move_to_position(table.get_customer_seat_position(),customer.TargetType.TABLE)
	print("Nuevo cliente creado")
func _on_customer_spawn_timer_timeout() -> void:
	spawn_customer()
func upgrade_waiter_speed() -> void:
	if waiter_speed_level >= MAX_WAITER_SPEED_LEVEL:
		return

	waiter_speed_level += 1

	update_waiter_speed()

	print("Nivel velocidad: ", waiter_speed_level)
	print("Velocidad del camarero: ", player_waiter.speed)
	
func update_waiter_speed() -> void:
	player_waiter.set_speed_upgrade_level(waiter_speed_level)
func upgrade_plate_price() -> void:
	if plate_price_level >= MAX_PLATE_PRICE_LEVEL:
		return

	plate_price_level += 1
	update_plate_price()
	print("Nivel precio del plato: ", plate_price_level)
	print("Precio actual del plato: ", plate_price)
func update_plate_price() -> void:
	plate_price = BASE_PLATE_PRICE + PLATE_PRICE_INCREMENT * plate_price_level
	table.set_payment_amount(plate_price)
	
func get_plate_price() -> float:
	return plate_price
	
# Actualiza todas las estadísticas derivadas de las mejoras actuales.
func update_stats() -> void:
	update_waiter_speed()
	update_plate_price()
