class_name Customer
extends CharacterBody2D
var route = preload("res://scripts/RestaurantRoute.gd").new()
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
var seat_facing := Vector2.DOWN
var plate_position := Vector2.INF
var table_cover := Rect2()
var is_eating := false
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
	if new_target_type != TargetType.TABLE:
		is_seated = false
		set_eating(false)
		var visual := get_node_or_null("Sprite2D")
		if visual != null and visual.has_method("stand_up"):
			visual.stand_up()


func _physics_process(delta: float) -> void:
	var previous_position := global_position
	if not has_target:
		_update_appearance(Vector2.ZERO, delta)
		return
	if _wait_for_group_member():
		_update_appearance(Vector2.ZERO, delta)
		return
	if route.advance(self, target_position, speed, delta):
		has_target = false
		if target_type == TargetType.TABLE:
			sit_down()
		destination_reached.emit()
	_update_appearance(global_position - previous_position, delta)

func _wait_for_group_member() -> bool:
	var group := get_parent()
	if group == null or not group.has_method("get_customers"):
		return false
	# Allow the final approach to individual seats and the shared exit.
	if global_position.distance_to(target_position) < 100.0:
		return false
	var heading := global_position.direction_to(target_position)
	for other in group.get_customers():
		if other == self or not is_instance_valid(other) or not other.has_target:
			continue
		var separation: Vector2 = other.global_position - global_position
		if separation.length() >= 80.0 or separation.dot(heading) <= 0:
			continue
		# Yield only to the person ahead travelling the same way, avoiding
		# mutual waiting when paths cross on their way to different seats.
		var other_heading: Vector2 = other.global_position.direction_to(other.target_position)
		if heading.dot(other_heading) > 0.7 and other.global_position.distance_to(other.target_position) < global_position.distance_to(target_position):
			return true
	return false

func _update_appearance(displacement: Vector2, delta: float) -> void:
	var visual := get_node_or_null("Sprite2D")
	if visual != null and visual.has_method("update_movement"):
		visual.update_movement(displacement, delta)

func sit_down() -> void:
	is_seated = true
	var visual := get_node_or_null("Sprite2D")
	if visual != null and visual.has_method("sit_down"):
		if plate_position != Vector2.INF and visual.has_method("set_plate_position"):
			visual.set_plate_position(plate_position)
			visual.set_table_cover(table_cover)
		visual.sit_down(seat_facing)
		visual.set_eating(is_eating)

func set_eating(value: bool) -> void:
	is_eating = value
	var visual := get_node_or_null("Sprite2D")
	if visual != null and visual.has_method("set_eating"):
		visual.set_eating(value)
func leave_restaurant(new_position: Vector2) -> void:
	is_seated = false
	move_to_position(new_position, TargetType.EXIT)

func get_group_size() -> int:
	return group_size
func set_requested_dish(dish: DishTypes.Type) -> void:
	requested_dish = dish
	update_order_label()


func update_order_label() -> void:
	order_label.text = DishTypes.CATALOG.get(requested_dish, {}).get("icon", "")
	var picture: TextureRect = order_label.get_node_or_null("DishPicture")
	if picture == null:
		picture = TextureRect.new()
		picture.name = "DishPicture"
		picture.size = Vector2(32, 32)
		picture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		picture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		order_label.add_child(picture)
	picture.texture = DishTypes.texture(requested_dish)
	picture.visible = picture.texture != null
	if picture.visible:
		order_label.text = ""
func show_order() -> void:
	order_label.visible = true


func hide_order() -> void:
	order_label.visible = false
