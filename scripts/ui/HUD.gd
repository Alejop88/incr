extends Control

signal serve_customer_requested
var last_order_queue= null
var last_ready_dishes: Array = []
@onready var money_label: Label = $VBoxContainer/MoneyLabel
@onready var stars_label: Label = $StarsLabel
@onready var test_serve_button: Button = $VBoxContainer/TestServeButton
@onready var upgrades_button: Button = $VBoxContainer/UpgradesButton
@onready var upgrades_panel: PanelContainer = $UpgradesPanel
@onready var close_button: Button = $UpgradesPanel/VBoxContainer/CloseButton
signal waiter_speed_upgrade_requested
signal plate_price_upgrade_requested
signal buy_table_requested
signal star_upgrades_requested
signal kitchen_order_move_up_requested(index: int)
signal kitchen_order_move_down_requested(index: int)
signal manual_dish_requested(dish_type: int)
signal kitchen_order_cancel_requested(index: int)
signal ready_dish_selected(dish_id: int)
@onready var star_upgrades_button: Button = $StarUpgradesButton
@onready var waiter_speed_button: Button = $UpgradesPanel/VBoxContainer/WaiterSpeedButton
@onready var plate_price_button: Button = $UpgradesPanel/VBoxContainer/PlatePriceButton
@onready var buy_table_button: Button = $UpgradesPanel/VBoxContainer/BuyTableButton
@onready var kitchen_panel: Control = $KitchenPanel
@onready var kitchen_close_button: Button = $KitchenPanel/VBoxContainer/CloseButton
@onready var ready_dishes_label: Label = $KitchenPanel/VBoxContainer/ReadyDishesLabel
@onready var cooking_progress_bar: ProgressBar = $KitchenPanel/VBoxContainer/CookingProgressBar
@onready var current_dish_label: Label = $KitchenPanel/VBoxContainer/CurrentDishLabel
@onready var manual_order_buttons: HBoxContainer = $KitchenPanel/VBoxContainer/ManualOrderButtons
@onready var order_queue_container: VBoxContainer = $KitchenPanel/VBoxContainer/OrderQueueContainer
@onready var ready_dishes_container: VBoxContainer = $KitchenPanel/VBoxContainer/ReadyDishesContainer

func _ready() -> void:
	test_serve_button.pressed.connect(_on_test_serve_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	waiter_speed_button.pressed.connect(_on_waiter_speed_button_pressed)
	plate_price_button.pressed.connect(_on_plate_price_button_pressed)
	buy_table_button.pressed.connect(_on_buy_table_button_pressed)
	star_upgrades_button.pressed.connect(_on_star_upgrades_button_pressed)
	kitchen_close_button.pressed.connect(_on_kitchen_close_button_pressed)
func set_money(value: float) -> void:
	money_label.text = "Dinero: %.1f €" % value
func set_stars(value: int) -> void:
	stars_label.text = "⭐ %d" % value
func _on_test_serve_button_pressed() -> void:
	serve_customer_requested.emit()
	
func _on_upgrades_button_pressed() -> void:
	upgrades_panel.visible = true

func _on_close_button_pressed() -> void:
	upgrades_panel.visible = false

func _on_waiter_speed_button_pressed() -> void:
	waiter_speed_upgrade_requested.emit()
	
func set_waiter_speed_upgrade(level: int,cost: float,max_level: int) -> void:
	if level >= max_level:
		waiter_speed_button.text = "Velocidad camarero - MÁXIMO"
		waiter_speed_button.disabled = true
		return

	waiter_speed_button.disabled = false
	waiter_speed_button.text = "Velocidad camarero - Nivel %d - %.1f €" % [level,cost]
func set_plate_price_upgrade(level: int, cost: float, max_level: int) -> void:
	if level >= max_level:
		plate_price_button.text = "Precio del plato - MÁXIMO"
		plate_price_button.disabled = true
		return

	plate_price_button.disabled = false
	plate_price_button.text = "Precio del plato - Nivel %d - %.1f €" % [level, cost]
func _on_plate_price_button_pressed() -> void:
	plate_price_upgrade_requested.emit()
func _on_buy_table_button_pressed() -> void:
	buy_table_requested.emit()
func _on_star_upgrades_button_pressed() -> void:
	star_upgrades_requested.emit()
func set_table_purchase(cost: float,has_locked_tables: bool,current_money: float) -> void:
	if not has_locked_tables:
		buy_table_button.text = "Comprar mesa - MÁXIMO"
		buy_table_button.disabled = true
		return

	buy_table_button.text = "Comprar mesa - %.1f €" % cost
	buy_table_button.disabled = current_money < cost
func open_kitchen_panel() -> void:
	kitchen_panel.visible = true

func _on_kitchen_close_button_pressed() -> void:
	kitchen_panel.visible = false
func set_kitchen_ready_dishes(current: int, capacity: int) -> void:
	ready_dishes_label.text = \
		"Platos preparados: %d / %d" % [current, capacity]

func set_kitchen_cooking_progress(progress: float) -> void:
	cooking_progress_bar.value = progress
func set_current_cooking_dish(dish_name: String) -> void:
	if dish_name.is_empty():
		current_dish_label.text = "Cocinando: Nada"
	else:
		current_dish_label.text = "Cocinando: " + dish_name


func set_manual_order_dishes(dishes: Array) -> void:
	for child in manual_order_buttons.get_children():
		child.queue_free()

	for dish in dishes:
		var button := Button.new()

		button.text = DishTypes.Type.keys()[dish]

		button.pressed.connect(
			func():
				manual_dish_requested.emit(dish)
		)

		manual_order_buttons.add_child(button)
func set_kitchen_order_queue_buttons(dishes: Array) -> void:
	if last_order_queue != null and dishes == last_order_queue:
		return

	last_order_queue = dishes.duplicate()

	for child in order_queue_container.get_children():
		child.queue_free()
	if dishes.is_empty():
		var empty_label := Label.new()
		empty_label.text = "Cola vacía"
		order_queue_container.add_child(empty_label)
		return
	for i in range(dishes.size()):
		var row := HBoxContainer.new()

		var label := Label.new()
		label.text = "%d. %s" % [
			i + 1,
			DishTypes.Type.keys()[dishes[i]]
		]

		var up_button := Button.new()
		up_button.text = "↑"

		if i == 0:
			up_button.disabled = true
		else:
			up_button.pressed.connect(
				_on_kitchen_order_move_up_pressed.bind(i)
			)
		var down_button := Button.new()
		down_button.text = "↓"

		if i == dishes.size() - 1:
			down_button.disabled = true
		else:
			down_button.pressed.connect(
				_on_kitchen_order_move_down_pressed.bind(i)
			)
		var cancel_button := Button.new()
		cancel_button.text = "X"

		cancel_button.pressed.connect(
			_on_kitchen_order_cancel_pressed.bind(i)
		)
		row.add_child(label)
		row.add_child(up_button)
		row.add_child(down_button)
		row.add_child(cancel_button)
		order_queue_container.add_child(row)
func _on_kitchen_order_move_up_pressed(index: int) -> void:
	kitchen_order_move_up_requested.emit(index)
func _on_kitchen_order_move_down_pressed(index: int) -> void:
	kitchen_order_move_down_requested.emit(index)
func _on_kitchen_order_cancel_pressed(index: int) -> void:
	kitchen_order_cancel_requested.emit(index)
func set_ready_dishes_buttons(dishes: Array,dish_ids: Array[int]) -> void:
	if dishes == last_ready_dishes:
		return

	last_ready_dishes = dishes.duplicate()

	for child in ready_dishes_container.get_children():
		child.queue_free()

	if dishes.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No hay platos preparados"
		ready_dishes_container.add_child(empty_label)
		return

	for i in range(dishes.size()):
		var button := Button.new()

		button.text = DishTypes.Type.keys()[dishes[i]]

		button.pressed.connect(
			_on_ready_dish_pressed.bind(dish_ids[i])
		)

		ready_dishes_container.add_child(button)
func _on_ready_dish_pressed(dish_id: int) -> void:
	ready_dish_selected.emit(dish_id)
