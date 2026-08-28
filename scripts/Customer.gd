class_name Customer
extends CharacterBody2D
signal destination_reached
@export var speed: float = 120.0
@onready var order_label: Label = $OrderLabel
@export_enum("1", "2", "3", "4")
var group_size: int = 1

var target_position: Vector2
var has_target := false
enum TargetType {
	NONE,
	TABLE,
	QUEUE,
	EXIT
}
var has_received_food: bool = false
var requested_dish: DishTypes.Type = DishTypes.Type.NONE
var target_type: TargetType = TargetType.NONE
var is_seated: bool = false
func _ready() -> void:
	update_order_label()
	hide_order()
func move_to_position(
	new_position: Vector2,
	new_target_type: TargetType
) -> void:
	target_position = new_position
	target_type = new_target_type
	has_target = true


func _physics_process(_delta: float) -> void:
	if !has_target:
		return

	var direction := target_position - global_position

	if direction.length() < 5:
		global_position = target_position
		velocity = Vector2.ZERO
		has_target = false
		destination_reached.emit()
		return

	velocity = direction.normalized() * speed
	move_and_slide()
func leave_restaurant(new_position: Vector2) -> void:
	is_seated = false
	move_to_position(new_position, TargetType.EXIT)

func get_group_size() -> int:
	return group_size
func set_requested_dish(dish: DishTypes.Type) -> void:
	requested_dish = dish
	update_order_label()


func update_order_label() -> void:
	match requested_dish:
		DishTypes.Type.BURGER:
			order_label.text = "🍔"

		DishTypes.Type.PIZZA:
			order_label.text = "🍕"

		_:
			order_label.text = ""
func show_order() -> void:
	order_label.visible = true


func hide_order() -> void:
	order_label.visible = false
