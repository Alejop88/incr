class_name VIPCustomer
extends Customer


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
