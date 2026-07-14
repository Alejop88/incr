extends Node2D

signal customer_paid(amount: float)

@onready var player_waiter: CharacterBody2D = $PlayerWaiter
@onready var kitchen_point: Area2D = $KitchenPoint
@onready var table_01_point: Area2D = $Table01Point

var base_plate_price: float = 5.0

func _ready() -> void:
	get_viewport().physics_object_picking = true

	player_waiter.input_pickable = false

	print("Waiter pickable: ", player_waiter.input_pickable)
	print("Kitchen pickable: ", kitchen_point.input_pickable)
	print("Kitchen layer: ", kitchen_point.collision_layer)

	kitchen_point.input_event.connect(_on_kitchen_point_input_event)
	table_01_point.input_event.connect(_on_table_01_point_input_event)
	player_waiter.destination_reached.connect(_on_player_waiter_destination_reached)
	
func serve_test_customer() -> void:
	customer_paid.emit(base_plate_price)
	
func _on_kitchen_point_input_event(_viewport: Viewport,event: InputEvent,_shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Clic izquierdo en cocina")
		player_waiter.move_to_position(kitchen_point.global_position)

func _on_table_01_point_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		print("Click en mesa")
		player_waiter.move_to_position(table_01_point.global_position)
		
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
	print("El camarero ha llegado a su destino")
