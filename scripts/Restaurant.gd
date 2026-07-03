extends Node2D

signal customer_paid(amount: float)

@onready var player_waiter: CharacterBody2D = $PlayerWaiter
@onready var kitchen_point: Area2D = $KitchenPoint
@onready var table_01_point: Area2D = $Table01Point

var base_plate_price: float = 5.0

func _ready() -> void:
	kitchen_point.input_event.connect(_on_kitchen_point_input_event)
	table_01_point.input_event.connect(_on_table_01_point_input_event)

func serve_test_customer() -> void:
	customer_paid.emit(base_plate_price)

func _on_kitchen_point_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		player_waiter.move_to_position(kitchen_point.global_position)

func _on_table_01_point_input_event(_viewport, event, _shape_idx) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		player_waiter.move_to_position(table_01_point.global_position)
