extends Node

@onready var economy_manager: Node = $EconomyManager
@onready var michelin_manager: Node = $MichelinManager
@onready var restaurant: Node2D = $Restaurant
@onready var hud: Control = $CanvasLayer/HUD
@onready var michelin_upgrades: Control = $CanvasLayer/MichelinUpgrades
@onready var save_manager: Node = $SaveManager
@onready var pause_menu: CanvasLayer = $PauseMenu
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
var initial_run_data: Dictionary = {}
var prestige_pending: bool = false
const VIP_UNLOCK_COST: float = 100.0
var vip_run_unlocked: bool = false
func _ready() -> void:
	restaurant.start_random_menu()
	initial_run_data = _get_save_data().duplicate(true)
	_load_saved_progress()
	restaurant.set_vip_unlocked(vip_run_unlocked or michelin_manager.is_upgrade_bought("permanent_vip"))
	restaurant.waiter_manager.apply_permanent_upgrades(
		michelin_manager.is_upgrade_bought("permanent_waiter"),
		michelin_manager.is_upgrade_bought("waiter_capacity_2")
	)
	pause_menu.save_requested.connect(_on_save_requested)
	pause_menu.new_game_requested.connect(_on_new_game_requested)
	pause_menu.quit_requested.connect(_on_quit_requested)
	restaurant.customer_paid.connect(_on_customer_paid)
	restaurant.vip_completed.connect(_on_vip_completed)
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
	hud.hire_waiter_requested.connect(_on_hire_waiter_requested)
	hud.vip_unlock_requested.connect(_on_vip_unlock_requested)
	hud.staff_speed_upgrade_requested.connect(_on_staff_speed_upgrade_requested)
	_update_hire_waiter_button()
	hud.star_upgrades_requested.connect(_on_star_upgrades_requested)
	hud.set_table_purchase(table_purchase_cost,restaurant.has_locked_tables(),economy_manager.money,restaurant.get_next_table_description())
	hud.manual_dish_requested.connect(_on_manual_dish_requested)
	restaurant.set_counter_capacity_bonus(michelin_manager.counter_capacity_bonus)
	restaurant.set_permanent_cook_speed_bonus(michelin_manager.cook_speed_bonus)
	restaurant.set_vip_spawn_bonus_level(michelin_manager.vip_spawn_bonus)
	restaurant.set_max_vip_group_size(michelin_manager.max_vip_group_size)
	restaurant.player_waiter.carry_capacity = 2 if michelin_manager.is_upgrade_bought("player_capacity_2") else 1
	michelin_manager.counter_capacity_bonus_changed.connect(_on_counter_capacity_bonus_changed)
	michelin_upgrades.upgrade_requested.connect(_on_star_upgrade_requested)
	michelin_upgrades.purchase_requested.connect(_on_star_purchase_requested)
	michelin_upgrades.purchase_confirmed.connect(_on_star_purchase_confirmed)
	hud.kitchen_order_move_up_requested.connect(_on_kitchen_order_move_up_requested)
	hud.kitchen_order_move_down_requested.connect(_on_kitchen_order_move_down_requested)
	hud.kitchen_order_cancel_requested.connect(_on_kitchen_order_cancel_requested)
	hud.ready_dish_selected.connect(_on_ready_dish_selected)
	hud.menu_requested.connect(func():
		_refresh_dish_shop()
		hud.menu_editor.open_menu(restaurant.menu_dishes)
	)
	hud.menu_editor.purchase_requested.connect(_on_dish_purchase_requested)
	hud.menu_editor.menu_applied.connect(func(dishes: Array):
		if restaurant.set_menu_dishes(dishes):
			hud.set_manual_order_dishes(restaurant.get_available_manual_dishes())
	)
	hud.set_cook_speed_upgrade(cook_speed_level,cook_speed_upgrade_cost,MAX_COOK_SPEED_LEVEL)
	hud.set_eating_speed_upgrade(eating_speed_level,eating_speed_upgrade_cost,MAX_EATING_SPEED_LEVEL)
	hud.set_patience_upgrade(patience_level,patience_upgrade_cost,MAX_PATIENCE_LEVEL)
	hud.eating_speed_upgrade_requested.connect(_on_eating_speed_upgrade_requested)
	hud.patience_upgrade_requested.connect(_on_patience_upgrade_requested)
	restaurant.spawn_customer()

func _get_save_data() -> Dictionary:
	var unlocked_tables: Array[String] = []
	for table in restaurant.tables:
		if table.unlocked:
			unlocked_tables.append(str(table.name))
	var data: Dictionary = {
		"money": economy_manager.money,
		"vip_unlocked": vip_run_unlocked,
		"menu_dishes": DishTypes.menu_keys(restaurant.menu_dishes),
		"unlocked_dishes": DishTypes.menu_keys(restaurant.unlocked_dishes),
		"hired_waiters": restaurant.waiter_manager.get_hired_count(),
		"michelin": michelin_manager.get_save_data(),
		"levels": {
			"staff_speed": restaurant.waiter_manager.speed_level,
			"waiter_speed": restaurant.waiter_speed_level,
			"plate_price": restaurant.plate_price_level,
			"cook_speed": restaurant.cook_speed_level,
			"eating_speed": restaurant.eating_speed_level,
			"patience": restaurant.patience_level
		},
		"unlocked_tables": unlocked_tables
	}
	return data

func _on_save_requested() -> bool:
	if prestige_pending:
		return false
	if save_manager.save_game(_get_save_data()):
		pause_menu.show_status("Partida guardada correctamente.")
		return true
	else:
		pause_menu.show_status(save_manager.last_error)
		return false

func _on_quit_requested(save_first: bool) -> void:
	if save_first and not _on_save_requested():
		return
	get_tree().quit()

func _on_new_game_requested() -> void:
	if not save_manager.delete_save():
		pause_menu.show_status(save_manager.last_error)
		return
	get_tree().paused = false
	var error: Error = get_tree().reload_current_scene()
	if error != OK:
		pause_menu.open_menu()
		pause_menu.show_status("No se pudo reiniciar el restaurante.")

func _load_saved_progress() -> void:
	var data: Dictionary = save_manager.load_game()
	if data.is_empty():
		if not save_manager.last_error.is_empty():
			pause_menu.show_status(save_manager.last_error)
			pause_menu.open_menu()
		return
	economy_manager.money = float(data["money"])
	vip_run_unlocked = data.get("vip_unlocked", false)
	restaurant.restore_dish_progress(data)
	michelin_manager.load_save_data(data["michelin"])
	var levels: Dictionary = data["levels"]
	restaurant.waiter_manager.set_speed_level(int(levels.get("staff_speed", 0)))
	waiter_speed_level = int(levels["waiter_speed"])
	cook_speed_level = int(levels["cook_speed"])
	eating_speed_level = int(levels["eating_speed"])
	patience_level = int(levels["patience"])
	restaurant.waiter_speed_level = waiter_speed_level
	restaurant.plate_price_level = int(levels["plate_price"])
	restaurant.cook_speed_level = cook_speed_level
	restaurant.eating_speed_level = eating_speed_level
	restaurant.patience_level = patience_level
	waiter_speed_upgrade_cost = 10.0 * pow(1.5, waiter_speed_level)
	plate_price_upgrade_cost = 10.0 * pow(1.5, restaurant.plate_price_level)
	cook_speed_upgrade_cost = 20.0 * pow(1.5, cook_speed_level)
	eating_speed_upgrade_cost = 20.0 * pow(1.5, eating_speed_level)
	patience_upgrade_cost = 20.0 * pow(1.5, patience_level)
	var purchased_table_count: int = 0
	for table in restaurant.tables:
		if str(table.name) in data["unlocked_tables"] and not table.unlocked:
			table.unlock()
			purchased_table_count += 1
	table_purchase_cost = 50.0 * pow(1.5, purchased_table_count)
	restaurant.update_stats()
	restaurant.waiter_manager.restore_hired_count(int(data.get("hired_waiters", 0)))
	pause_menu.show_status("Partida guardada recuperada.")

func _on_serve_customer_requested() -> void:
	restaurant.serve_test_customer()

func _on_customer_paid(amount: float) -> void:
	economy_manager.add_money(amount)

func _on_money_changed(new_money: float) -> void:
	hud.set_money(new_money)

	hud.set_table_purchase(table_purchase_cost,restaurant.has_locked_tables(),new_money,restaurant.get_next_table_description())
	_update_hire_waiter_button()
	
func _on_stars_changed(new_stars: int) -> void:
	hud.set_stars(new_stars)
	michelin_upgrades.set_stars(new_stars)
	_refresh_star_upgrades()
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

	hud.set_table_purchase(table_purchase_cost,restaurant.has_locked_tables(),economy_manager.money,restaurant.get_next_table_description())
func _on_hire_waiter_requested() -> void:
	var manager: Node = restaurant.waiter_manager
	if not manager.can_hire():
		return
	if not economy_manager.spend_money(manager.HIRE_COST):
		return
	manager.create_waiter()
	_update_hire_waiter_button()

func _update_hire_waiter_button() -> void:
	hud.set_vip_unlock(vip_run_unlocked, michelin_manager.is_upgrade_bought("permanent_vip"), VIP_UNLOCK_COST, economy_manager.money)
	var manager: Node = restaurant.waiter_manager
	hud.set_hire_waiter(manager.get_hired_count(), manager.MAX_HIRED_WAITERS, manager.HIRE_COST, economy_manager.money)
	hud.set_staff_speed_upgrade(manager.speed_level, manager.get_speed_upgrade_cost(), manager.MAX_SPEED_LEVEL, economy_manager.money)

func _on_staff_speed_upgrade_requested() -> void:
	var manager: Node = restaurant.waiter_manager
	if prestige_pending or manager.speed_level >= manager.MAX_SPEED_LEVEL:
		return
	if not economy_manager.spend_money(manager.get_speed_upgrade_cost()):
		return
	manager.set_speed_level(manager.speed_level + 1)
	_update_hire_waiter_button()

func _on_vip_unlock_requested() -> void:
	if prestige_pending or vip_run_unlocked or michelin_manager.is_upgrade_bought("permanent_vip"):
		return
	if not economy_manager.spend_money(VIP_UNLOCK_COST):
		return
	vip_run_unlocked = true
	restaurant.set_vip_unlocked(true)
	_update_hire_waiter_button()

func _on_counter_capacity_bonus_changed(new_level: int) -> void:
	restaurant.set_counter_capacity_bonus(new_level)
func _on_star_upgrades_requested() -> void:
	_refresh_star_upgrades()
	michelin_upgrades.visible = true

func _refresh_star_upgrades() -> void:
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
			not michelin_manager.are_upgrade_requirements_met(upgrade_id, true)
		)
		michelin_upgrades.set_upgrade_selected(upgrade_id, upgrade_id in michelin_manager.selected_upgrades)

		michelin_upgrades.set_upgrade_info(
			upgrade_id,
			michelin_manager.get_upgrade_name(upgrade_id),
			michelin_manager.get_upgrade_description(upgrade_id),
			michelin_manager.get_upgrade_cost(upgrade_id)
		)
	michelin_upgrades.set_purchase_summary(
		michelin_manager.selected_upgrades.size(),
		michelin_manager.get_selected_cost(),
		michelin_manager.get_stars()
	)
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
func _on_vip_completed(amount: int) -> void:
	michelin_manager.add_stars(amount)
func _on_star_upgrade_requested(upgrade_id: String) -> void:
	if prestige_pending:
		return
	michelin_upgrades.cancel_purchase_confirmation()
	michelin_upgrades.show_purchase_status("")
	michelin_manager.toggle_selection(upgrade_id)
	_refresh_star_upgrades()

func _on_star_purchase_requested() -> void:
	if prestige_pending or michelin_manager.get_selected_purchase_data().is_empty():
		return
	michelin_upgrades.show_purchase_confirmation(michelin_manager.get_selected_cost())

func _on_star_purchase_confirmed() -> void:
	if prestige_pending:
		return
	var permanent_data: Dictionary = michelin_manager.get_selected_purchase_data()
	if permanent_data.is_empty():
		michelin_upgrades.cancel_purchase_confirmation()
		_refresh_star_upgrades()
		michelin_upgrades.show_purchase_status("Revisa la selección y las estrellas disponibles.")
		return
	var previous_data: Dictionary = _get_save_data()
	var new_run: Dictionary = initial_run_data.duplicate(true)
	new_run["michelin"] = permanent_data
	new_run["menu_dishes"] = DishTypes.menu_keys(restaurant.menu_dishes)
	new_run["unlocked_dishes"] = DishTypes.menu_keys(restaurant.unlocked_dishes)
	if not save_manager.save_game(new_run):
		michelin_upgrades.show_purchase_status(save_manager.last_error)
		return
	prestige_pending = true
	get_tree().paused = false
	var error: Error = get_tree().reload_current_scene()
	if error != OK:
		# Keep the playable run and its money/stars if scene reload fails.
		if save_manager.save_game(previous_data):
			prestige_pending = false
			michelin_upgrades.show_purchase_status("No se pudo reiniciar. La compra no se ha aplicado.")
		else:
			michelin_upgrades.show_purchase_status("La compra está guardada. Cierra y vuelve a abrir el juego.")
func _on_kitchen_panel_requested() -> void:
	hud.set_kitchen_ready_dishes(restaurant.get_ready_dishes_count(),restaurant.get_counter_capacity())


	hud.open_kitchen_panel()

	hud.set_manual_order_dishes(restaurant.get_available_manual_dishes())

func _process(_delta: float) -> void:
	if hud.menu_editor.visible:
		_refresh_dish_shop()
	if hud.kitchen_panel.visible:
		hud.set_manual_order_dishes(restaurant.get_available_manual_dishes())
		hud.set_kitchen_cooking_progress(restaurant.get_cooking_progress())
		hud.set_kitchen_ready_dishes(restaurant.get_ready_dishes_count(),restaurant.get_counter_capacity())
		hud.set_current_cooking_dish(restaurant.get_current_dish_name())
		hud.set_kitchen_order_queue_buttons(restaurant.get_order_queue())
		hud.set_ready_dishes_buttons(restaurant.get_ready_dishes(),restaurant.get_ready_dish_ids())
		hud.set_ready_dish_selection(restaurant.get_selected_ready_dish_ids(), restaurant.player_waiter.get_free_carry_slots())

func _refresh_dish_shop() -> void:
	hud.menu_editor.set_unlocks(restaurant.unlocked_dishes, economy_manager.money)

func _on_dish_purchase_requested() -> void:
	if prestige_pending:
		return
	var pool: Array = restaurant.get_locked_dishes()
	if pool.is_empty() or economy_manager.money < DishTypes.NEW_DISH_COST:
		_refresh_dish_shop()
		return
	var dish: DishTypes.Type = pool.pick_random()
	if economy_manager.spend_money(DishTypes.NEW_DISH_COST):
		restaurant.unlocked_dishes.append(dish)
		hud.menu_editor.purchase_result.text = "Nuevo plato: " + DishTypes.title(dish)
		_refresh_dish_shop()
