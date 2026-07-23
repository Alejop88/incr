extends Node

@onready var economy_manager: Node = $EconomyManager
@onready var restaurant: Node2D = $Restaurant
@onready var hud: Control = $CanvasLayer/HUD
var waiter_speed_level: int = 0
var waiter_speed_upgrade_cost: float = 10.0
const MAX_WAITER_SPEED_LEVEL: int = 10
var plate_price_upgrade_cost: float = 10.0
func _ready() -> void:
	restaurant.customer_paid.connect(_on_customer_paid)
	economy_manager.money_changed.connect(_on_money_changed)
	hud.serve_customer_requested.connect(_on_serve_customer_requested)
	hud.waiter_speed_upgrade_requested.connect(_on_waiter_speed_upgrade_requested)
	hud.set_money(economy_manager.money)
	hud.set_waiter_speed_upgrade(waiter_speed_level,waiter_speed_upgrade_cost,MAX_WAITER_SPEED_LEVEL)
	hud.set_plate_price_upgrade(restaurant.plate_price_level,plate_price_upgrade_cost,restaurant.MAX_PLATE_PRICE_LEVEL)
	hud.plate_price_upgrade_requested.connect(_on_plate_price_upgrade_requested)
func _on_serve_customer_requested() -> void:
	restaurant.serve_test_customer()

func _on_customer_paid(amount: float) -> void:
	economy_manager.add_money(amount)

func _on_money_changed(new_money: float) -> void:
	hud.set_money(new_money)
	
func _on_waiter_speed_upgrade_requested() -> void:
	if waiter_speed_level >= MAX_WAITER_SPEED_LEVEL:
		print("La velocidad del camarero ya está al máximo")
		return
	var purchase_successful: bool = economy_manager.spend_money(
		waiter_speed_upgrade_cost
	)

	if not purchase_successful:
		print("No hay suficiente dinero para comprar la mejora")
		return

	waiter_speed_level += 1

	restaurant.upgrade_waiter_speed()

	waiter_speed_upgrade_cost *= 1.5

	hud.set_waiter_speed_upgrade(waiter_speed_level,waiter_speed_upgrade_cost,MAX_WAITER_SPEED_LEVEL)
func _on_plate_price_upgrade_requested() -> void:
	if not economy_manager.spend_money(plate_price_upgrade_cost):
		return

	restaurant.upgrade_plate_price()
	plate_price_upgrade_cost *= 1.5

	hud.set_plate_price_upgrade(restaurant.plate_price_level,plate_price_upgrade_cost,restaurant.MAX_PLATE_PRICE_LEVEL)
