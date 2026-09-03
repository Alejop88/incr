class_name VIPCustomer
extends Customer

const FOOD_WAIT_TIME: float = 10.0
const QUEUE_WAIT_TIME: float = 20.0
const EATING_TIME: float = 5.0
var total_dishes_to_eat: int = 0
var dishes_eaten: int = 0

func _ready() -> void:
	super._ready()

	total_dishes_to_eat = randi_range(3, 5)
	dishes_eaten = 0

	print(
		"VIP creado - Platos que pedirá: ",
		total_dishes_to_eat
	)
func prepare_next_dish() -> DishTypes.Type:
	var available_dishes: Array[DishTypes.Type] = [
		DishTypes.Type.BURGER,
		DishTypes.Type.PIZZA
	]

	has_received_food = false
	set_requested_dish(available_dishes.pick_random())
	show_order()

	return requested_dish
