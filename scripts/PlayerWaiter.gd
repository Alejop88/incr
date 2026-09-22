extends CharacterBody2D

var route = preload("res://scripts/RestaurantRoute.gd").new()
signal destination_reached

@export var speed: float = 220.0
const BASE_SPEED: float = 220.0
const SPEED_PER_LEVEL: float = 25.0
var carried_dishes: Array[DishTypes.Type] = []
var carry_capacity: int = 1
var inventory_label: Label
var target_position: Vector2
var has_target: bool = false
enum TargetType {
	NONE,
	KITCHEN,
	TABLE,
	TRASH
}

var target_type: TargetType = TargetType.NONE

func _ready() -> void:
	target_position = global_position
	inventory_label = Label.new()
	inventory_label.position = Vector2(-80, -85)
	inventory_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inventory_label)
	refresh_inventory_label()

func get_free_carry_slots() -> int:
	return maxi(0, carry_capacity - carried_dishes.size())

func add_carried_dish(dish: DishTypes.Type) -> bool:
	if dish == DishTypes.Type.NONE or get_free_carry_slots() == 0:
		return false
	carried_dishes.append(dish)
	refresh_inventory_label()
	return true

func remove_carried_dish(dish: DishTypes.Type) -> void:
	carried_dishes.erase(dish)
	refresh_inventory_label()

func clear_carried_dishes() -> void:
	carried_dishes.clear()
	refresh_inventory_label()

func refresh_inventory_label() -> void:
	if inventory_label == null:
		return
	var names: PackedStringArray = []
	for dish in carried_dishes:
		names.append(DishTypes.Type.keys()[dish])
	inventory_label.text = " + ".join(names)

func move_to_position(new_position: Vector2, type: TargetType) -> void:
	print(
		"CAMARERO RECIBE DESTINO: ",
		new_position,
		" | Posición actual: ",
		global_position
	)
	target_position = new_position
	target_type = type
	has_target = true

func _physics_process(delta: float) -> void:
	if not has_target:
		return
	if route.advance(self, target_position, speed, delta):
		has_target = false
		destination_reached.emit()
func set_speed_upgrade_level(level: int) -> void:
	speed = BASE_SPEED + SPEED_PER_LEVEL * level
