extends Node

@onready var economy_manager: Node = $EconomyManager
@onready var michelin_manager: Node = $MichelinManager
@onready var restaurant: Node2D = $Restaurant
@onready var hud: Control = $CanvasLayer/HUD
@onready var michelin_upgrades: Control = $CanvasLayer/MichelinUpgrades
@onready var ready_dishes_list_label: Label = $KitchenPanel/VBoxContainer/ReadyDishesListLabel
var waiter_speed_level: int = 0
var waiter_speed_upgrade_cost: float = 10.0
const MAX_WAITER_SPEED_LEVEL: int = 10
var plate_price_upgrade_cost: float = 10.0
var table_purchase_cost: float = 50.0
var cook_speed_upgrade_cost: float = 20.0
var cook_speed_level: int = 0

const MAX_COOK_SPEED_LEVEL: int = 10
var eating_speed_upgrade_cost: float = 20.0
var eating_speed_level: int = 0

const MAX_EATING_SPEED_LEVEL: int = 10
var patience_upgrade_cost: float = 20.0
var patience_level: int = 0

const MAX_PATIENCE_LEVEL: int = 10
func _ready() -> void:
	restaurant.customer_paid.connect(_on_customer_paid)
	restaurant.kitchen_panel_requested.connect(_on_kitchen_panel_requested)
	economy_manager.money_changed.connect(_on_money_changed)
	michelin_manager.stars_changed.connect(_on_stars_changed)
	hud.serve_customer_requested.connect(_on_serve_customer_requested)
	hud.waiter_speed_upgrade_requested.connect(_on_waiter_speed_upgrade_requested)
	hud.cook_speed_upgrade_requested.connect(_on_cook_speed_upgrade_requested)
	hud.set_money(economy_manager.money)
	hud.set_stars(michelin_manager.get_stars())
	hud.set_waiter_speed_upgrade(waiter_speed_level,waiter_speed_upgrade_cost,MAX_WAITER_SPEED_LEVEL)
	hud.set_plate_price_upgrade(restaurant.plate_price_level,plate_price_upgrade_cost,restaurant.MAX_PLATE_PRICE_LEVEL)
	hud.plate_price_upgrade_requested.connect(_on_plate_price_upgrade_requested)
	hud.buy_table_requested.connect(_on_buy_table_requested)
	hud.star_upgrades_requested.connect(_on_star_upgrades_requested)
	hud.set_table_purchase(table_purchase_cost,restaurant.has_locked_tables(),economy_manager.money)
	hud.manual_dish_requested.connect(_on_manual_dish_requested)
	restaurant.set_counter_capacity_bonus(michelin_manager.counter_capacity_bonus)
	restaurant.set_permanent_cook_speed_bonus(michelin_manager.cook_speed_bonus)
	michelin_manager.counter_capacity_bonus_changed.connect(_on_counter_capacity_bonus_changed)
	michelin_upgrades.upgrade_requested.connect(_on_star_upgrade_requested)
	hud.kitchen_order_move_up_requested.connect(_on_kitchen_order_move_up_requested)
	hud.kitchen_order_move_down_requested.connect(_on_kitchen_order_move_down_requested)
	hud.kitchen_order_cancel_requested.connect(_on_kitchen_order_cancel_requested)
	hud.ready_dish_selected.connect(_on_ready_dish_selected)
	hud.set_cook_speed_upgrade(cook_speed_level,cook_speed_upgrade_cost,MAX_COOK_SPEED_LEVEL)
	hud.set_eating_speed_upgrade(eating_speed_level,eating_speed_upgrade_cost,MAX_EATING_SPEED_LEVEL)
	hud.set_patience_upgrade(patience_level,patience_upgrade_cost,MAX_PATIENCE_LEVEL)
	hud.eating_speed_upgrade_requested.connect(_on_eating_speed_upgrade_requested)
	hud.patience_upgrade_requested.connect(_on_patience_upgrade_requested)
func _on_serve_customer_requested() -> void:
	restaurant.serve_test_customer()

func _on_customer_paid(amount: float) -> void:
	economy_manager.add_money(amount)

func _on_money_changed(new_money: float) -> void:
	hud.set_money(new_money)

	hud.set_table_purchase(table_purchase_cost,restaurant.has_locked_tables(),new_money)
	
func _on_stars_changed(new_stars: int) -> void:
	hud.set_stars(new_stars)
	michelin_upgrades.set_stars(new_stars)
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
func _on_cook_speed_upgrade_requested() -> void:
	if cook_speed_level >= MAX_COOK_SPEED_LEVEL:
		print("La velocidad de cocina ya está al máximo")
		return

	var purchase_successful: bool = economy_manager.spend_money(
		cook_speed_upgrade_cost
	)

	if not purchase_successful:
		print("No hay suficiente dinero para mejorar la cocina")
		return

	cook_speed_level += 1

	restaurant.upgrade_cook_speed()

	cook_speed_upgrade_cost *= 1.5
	hud.set_cook_speed_upgrade(cook_speed_level,cook_speed_upgrade_cost,MAX_COOK_SPEED_LEVEL)
	print(
		"Mejora cocina comprada | Nivel: ",
		cook_speed_level,
		" | Próximo coste: ",
		cook_speed_upgrade_cost
	)
func _on_eating_speed_upgrade_requested() -> void:
	if eating_speed_level >= MAX_EATING_SPEED_LEVEL:
		print("La velocidad de comer ya está al máximo")
		return

	var purchase_successful: bool = economy_manager.spend_money(
		eating_speed_upgrade_cost
	)

	if not purchase_successful:
		print("No hay suficiente dinero para mejorar la velocidad de comer")
		return

	eating_speed_level += 1

	restaurant.upgrade_eating_speed()
	eating_speed_upgrade_cost *= 1.5
	hud.set_eating_speed_upgrade(eating_speed_level,eating_speed_upgrade_cost,MAX_EATING_SPEED_LEVEL)
	print(
		"Mejora velocidad de comer comprada | Nivel: ",
		eating_speed_level,
		" | Próximo coste: ",
		eating_speed_upgrade_cost
	)
func _on_patience_upgrade_requested() -> void:
	if patience_level >= MAX_PATIENCE_LEVEL:
		print("La paciencia de los clientes ya está al máximo")
		return

	var purchase_successful: bool = economy_manager.spend_money(
		patience_upgrade_cost
	)

	if not purchase_successful:
		print("No hay suficiente dinero para mejorar la paciencia")
		return

	patience_level += 1

	restaurant.upgrade_patience()

	patience_upgrade_cost *= 1.5
	hud.set_patience_upgrade(patience_level,patience_upgrade_cost,MAX_PATIENCE_LEVEL)
	print(
		"Mejora paciencia comprada | Nivel: ",
		patience_level,
		" | Próximo coste: ",
		patience_upgrade_cost
	)
func _on_plate_price_upgrade_requested() -> void:
	if not economy_manager.spend_money(plate_price_upgrade_cost):
		return

	restaurant.upgrade_plate_price()
	plate_price_upgrade_cost *= 1.5

	hud.set_plate_price_upgrade(restaurant.plate_price_level,plate_price_upgrade_cost,restaurant.MAX_PLATE_PRICE_LEVEL)
func _on_buy_table_requested() -> void:
	if not restaurant.has_locked_tables():
		print("No quedan mesas por comprar")
		return

	if not economy_manager.spend_money(table_purchase_cost):
		print("No hay suficiente dinero para comprar la mesa")
		return

	var table_unlocked: bool = restaurant.unlock_next_table()

	if not table_unlocked:
		return

	table_purchase_cost *= 1.5

	hud.set_table_purchase(table_purchase_cost,restaurant.has_locked_tables(),economy_manager.money)
func _on_counter_capacity_bonus_changed(new_level: int) -> void:
	restaurant.set_counter_capacity_bonus(new_level)
func _on_star_upgrades_requested() -> void:
	michelin_upgrades.set_stars(
		michelin_manager.get_stars()
	)

	for upgrade_id in michelin_upgrades.get_upgrade_ids():
		michelin_upgrades.set_upgrade_bought(
			upgrade_id,
			michelin_manager.is_upgrade_bought(upgrade_id)
		)

		michelin_upgrades.set_upgrade_locked(
			upgrade_id,
			not michelin_manager.are_upgrade_requirements_met(upgrade_id)
		)

		michelin_upgrades.set_upgrade_info(
			upgrade_id,
			michelin_manager.get_upgrade_name(upgrade_id),
			michelin_manager.get_upgrade_description(upgrade_id),
			michelin_manager.get_upgrade_cost(upgrade_id)
		)
	michelin_upgrades.visible = true
func _on_manual_dish_requested(dish_type: int) -> void:
	restaurant.add_manual_kitchen_order(dish_type)
func _on_kitchen_order_move_up_requested(index: int) -> void:
	restaurant.move_kitchen_order_up(index)
func _on_kitchen_order_move_down_requested(index: int) -> void:
	restaurant.move_kitchen_order_down(index)
func _on_kitchen_order_cancel_requested(index: int) -> void:
	restaurant.cancel_kitchen_order(index)
func _on_ready_dish_selected(dish_id: int) -> void:
	restaurant.request_specific_ready_dish(dish_id)
	
func _on_star_upgrade_requested(upgrade_id: String) -> void:
	var bought: bool = michelin_manager.buy_upgrade(upgrade_id)

	if not bought:
		print("No se ha podido comprar la mejora: ",upgrade_id)
		return

	michelin_upgrades.set_upgrade_bought(upgrade_id, true)
	restaurant.set_permanent_cook_speed_bonus(michelin_manager.cook_speed_bonus)
	for current_upgrade_id in michelin_upgrades.get_upgrade_ids():
		michelin_upgrades.set_upgrade_locked(
			current_upgrade_id,
			not michelin_manager.are_upgrade_requirements_met(
				current_upgrade_id
			)
		)
		michelin_upgrades.set_upgrade_info(
			current_upgrade_id,
			michelin_manager.get_upgrade_name(current_upgrade_id),
			michelin_manager.get_upgrade_description(current_upgrade_id),
			michelin_manager.get_upgrade_cost(current_upgrade_id))
func _on_kitchen_panel_requested() -> void:
	hud.set_kitchen_ready_dishes(restaurant.get_ready_dishes_count(),restaurant.get_counter_capacity())


	hud.open_kitchen_panel()

	hud.set_manual_order_dishes(restaurant.get_available_manual_dishes())

func _process(_delta: float) -> void:
	if hud.kitchen_panel.visible:
		hud.set_kitchen_cooking_progress(restaurant.get_cooking_progress())
		hud.set_kitchen_ready_dishes(restaurant.get_ready_dishes_count(),restaurant.get_counter_capacity())
		hud.set_current_cooking_dish(restaurant.get_current_dish_name())
		hud.set_kitchen_order_queue_buttons(restaurant.get_order_queue())
		hud.set_ready_dishes_buttons(restaurant.get_ready_dishes(),restaurant.get_ready_dish_ids())
