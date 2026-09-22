extends Control

const VISIBLE_QUEUED_DISHES: int = 5
var available_money: float = 0.0
signal menu_requested
var menu_editor: PanelContainer

signal serve_customer_requested
var last_order_queue= null
var last_manual_dishes: Variant = null
var last_ready_dishes: Array = []
var last_ready_dish_ids: Array[int] = []
var ready_dishes_initialized: bool = false
@onready var money_label: Label = $VBoxContainer/MoneyLabel
@onready var stars_label: Label = $StarsLabel
@onready var test_serve_button: Button = $VBoxContainer/TestServeButton
@onready var upgrades_button: Button = $VBoxContainer/UpgradesButton
@onready var upgrades_panel: PanelContainer = $UpgradesPanel
@onready var close_button: Button = $UpgradesPanel/VBoxContainer/CloseButton
signal waiter_speed_upgrade_requested
signal plate_price_upgrade_requested
signal cook_speed_upgrade_requested
signal eating_speed_upgrade_requested
signal patience_upgrade_requested
signal buy_table_requested
signal hire_waiter_requested
signal vip_unlock_requested
signal staff_speed_upgrade_requested
signal star_upgrades_requested
signal kitchen_order_move_up_requested(index: int)
signal kitchen_order_move_down_requested(index: int)
signal manual_dish_requested(dish_type: int)
signal kitchen_order_cancel_requested(index: int)
signal ready_dish_selected(dish_id: int)

@onready var star_upgrades_button: Button = $StarUpgradesButton
@onready var waiter_speed_button: Button = $UpgradesPanel/VBoxContainer/WaiterSpeedButton
@onready var plate_price_button: Button = $UpgradesPanel/VBoxContainer/PlatePriceButton
@onready var cook_speed_button: Button = $UpgradesPanel/VBoxContainer/CookSpeedButton
@onready var buy_table_button: Button = $UpgradesPanel/VBoxContainer/BuyTableButton
@onready var hire_waiter_button: Button = $UpgradesPanel/VBoxContainer/HireWaiterButton
@onready var kitchen_panel: Control = $KitchenPanel
@onready var kitchen_close_button: Button = $KitchenPanel/VBoxContainer/CloseButton
@onready var ready_dishes_label: Label = $KitchenPanel/VBoxContainer/ReadyDishesLabel
@onready var cooking_progress_bar: ProgressBar = $KitchenPanel/VBoxContainer/CookingProgressBar
@onready var current_dish_label: Label = $KitchenPanel/VBoxContainer/CurrentDishLabel
@onready var manual_order_buttons: HBoxContainer = $KitchenPanel/VBoxContainer/ManualOrderButtons
@onready var order_queue_container: VBoxContainer = $KitchenPanel/VBoxContainer/OrderQueueScroll/OrderQueueContainer
@onready var order_queue_scroll: ScrollContainer = $KitchenPanel/VBoxContainer/OrderQueueScroll
@onready var ready_dishes_container: VBoxContainer = $KitchenPanel/VBoxContainer/ReadyDishesContainer
@onready var eating_speed_button: Button = $UpgradesPanel/VBoxContainer/EatingSpeedButton
@onready var patience_button: Button = $UpgradesPanel/VBoxContainer/PatienceButton
func _ready() -> void:
	menu_editor = preload("res://scripts/ui/MenuEditor.gd").new()
	add_child(menu_editor)
	$KitchenPanel/VBoxContainer/MenuButton.pressed.connect(func(): menu_requested.emit())
	test_serve_button.pressed.connect(_on_test_serve_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	waiter_speed_button.pressed.connect(_on_waiter_speed_button_pressed)
	plate_price_button.pressed.connect(_on_plate_price_button_pressed)
	buy_table_button.pressed.connect(_on_buy_table_button_pressed)
	hire_waiter_button.pressed.connect(func(): hire_waiter_requested.emit())
	$UpgradesPanel/VBoxContainer/VipUnlockButton.pressed.connect(func(): vip_unlock_requested.emit())
	$UpgradesPanel/VBoxContainer/StaffSpeedButton.pressed.connect(func(): staff_speed_upgrade_requested.emit())
	star_upgrades_button.pressed.connect(_on_star_upgrades_button_pressed)
	kitchen_close_button.pressed.connect(_on_kitchen_close_button_pressed)
	cook_speed_button.pressed.connect(_on_cook_speed_button_pressed)
	eating_speed_button.pressed.connect(_on_eating_speed_button_pressed)
	patience_button.pressed.connect(_on_patience_button_pressed)
func set_money(value: float) -> void:
	available_money = value
	for button in [waiter_speed_button, plate_price_button, cook_speed_button, eating_speed_button, patience_button]:
		if button.has_meta("upgrade_cost"):
			button.disabled = button.get_meta("upgrade_maxed") or available_money < float(button.get_meta("upgrade_cost"))
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
	waiter_speed_button.set_meta("upgrade_cost", cost)
	waiter_speed_button.set_meta("upgrade_maxed", level >= max_level)
	if level >= max_level:
		waiter_speed_button.text = "Velocidad jugador - MÁXIMO"
		waiter_speed_button.disabled = true
		return

	waiter_speed_button.disabled = available_money < cost
	waiter_speed_button.text = "Velocidad jugador - Nivel %d - %.1f €" % [level,cost]
func set_plate_price_upgrade(level: int, cost: float, max_level: int) -> void:
	plate_price_button.set_meta("upgrade_cost", cost)
	plate_price_button.set_meta("upgrade_maxed", level >= max_level)
	if level >= max_level:
		plate_price_button.text = "Precio del plato - MÁXIMO"
		plate_price_button.disabled = true
		return

	plate_price_button.disabled = available_money < cost
	plate_price_button.text = "Precio del plato - Nivel %d - %.1f €" % [level, cost]
func _on_plate_price_button_pressed() -> void:
	plate_price_upgrade_requested.emit()
func _on_buy_table_button_pressed() -> void:
	buy_table_requested.emit()
func _on_star_upgrades_button_pressed() -> void:
	star_upgrades_requested.emit()
func set_table_purchase(cost: float,has_locked_tables: bool,current_money: float, description: String = "Comprar mesa") -> void:
	if not has_locked_tables:
		buy_table_button.text = "Comprar mesa - MÁXIMO"
		buy_table_button.disabled = true
		return

	buy_table_button.text = "%s - %.1f €" % [description, cost]
	buy_table_button.disabled = current_money < cost
func set_hire_waiter(count: int, maximum: int, cost: float, money: float) -> void:
	hire_waiter_button.disabled = count >= maximum or money < cost
	if count >= maximum:
		hire_waiter_button.text = "Camarero contratado (%d / %d)" % [count, maximum]
	else:
		hire_waiter_button.text = "Contratar camarero - %.0f €" % cost

func set_vip_unlock(unlocked: bool, permanent: bool, cost: float, money: float) -> void:
	var button: Button = $UpgradesPanel/VBoxContainer/VipUnlockButton
	button.visible = not permanent
	button.disabled = unlocked or money < cost
	button.text = "Clientes VIP desbloqueados" if unlocked else "Desbloquear clientes VIP - %.0f €" % cost
	button.tooltip_text = "Permite que aparezcan VIP durante esta partida. Se reinicia al comprar mejoras de estrellas."

func set_staff_speed_upgrade(level: int, cost: float, maximum: int, money: float) -> void:
	var button: Button = $UpgradesPanel/VBoxContainer/StaffSpeedButton
	button.disabled = level >= maximum or money < cost
	button.text = "Velocidad camareros - MÁXIMO" if level >= maximum else "Velocidad camareros - Nivel %d - %.1f €" % [level, cost]
	button.tooltip_text = "Aumenta la velocidad de todos los camareros automáticos, incluido el permanente."

func set_cook_speed_upgrade(
	level: int,
	cost: float,
	max_level: int
) -> void:
	cook_speed_button.set_meta("upgrade_cost", cost)
	cook_speed_button.set_meta("upgrade_maxed", level >= max_level)
	if level >= max_level:
		cook_speed_button.text = "Velocidad cocina - MÁXIMO"
		cook_speed_button.disabled = true
		return

	cook_speed_button.disabled = available_money < cost
	cook_speed_button.text = \
		"Velocidad cocina Nv.%d - %.0f €" % [level, cost]
func set_eating_speed_upgrade(
	level: int,
	cost: float,
	max_level: int
) -> void:
	eating_speed_button.set_meta("upgrade_cost", cost)
	eating_speed_button.set_meta("upgrade_maxed", level >= max_level)
	if level >= max_level:
		eating_speed_button.text = "Velocidad al comer - MÁXIMO"
		eating_speed_button.disabled = true
		return

	eating_speed_button.disabled = available_money < cost
	eating_speed_button.text = \
		"Velocidad al comer Nv.%d - %.0f €" % [level, cost]
func set_patience_upgrade(
	level: int,
	cost: float,
	max_level: int
) -> void:
	patience_button.set_meta("upgrade_cost", cost)
	patience_button.set_meta("upgrade_maxed", level >= max_level)
	if level >= max_level:
		patience_button.text = "Paciencia clientes - MÁXIMO"
		patience_button.disabled = true
		return

	patience_button.disabled = available_money < cost
	patience_button.text = \
		"Paciencia clientes Nv.%d - %.0f €" % [level, cost]
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
	if last_manual_dishes != null and last_manual_dishes == dishes:
		return
	last_manual_dishes = dishes.duplicate()
	for child in manual_order_buttons.get_children():
		child.queue_free()

	for dish in dishes:
		var button := Button.new()

		button.text = DishTypes.title(dish)
		button.icon = DishTypes.texture(dish)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 28)

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
			DishTypes.title(dishes[i])
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
		if i == 0:
			var row_height: float = row.get_combined_minimum_size().y
			var spacing: int = order_queue_container.get_theme_constant("separation")
			order_queue_scroll.custom_minimum_size.y = (
				row_height * VISIBLE_QUEUED_DISHES + spacing * (VISIBLE_QUEUED_DISHES - 1)
			)
func _on_kitchen_order_move_up_pressed(index: int) -> void:
	kitchen_order_move_up_requested.emit(index)
func _on_kitchen_order_move_down_pressed(index: int) -> void:
	kitchen_order_move_down_requested.emit(index)
func _on_kitchen_order_cancel_pressed(index: int) -> void:
	kitchen_order_cancel_requested.emit(index)
func set_ready_dishes_buttons(dishes: Array,dish_ids: Array[int]) -> void:
	if ready_dishes_initialized and dishes == last_ready_dishes and dish_ids == last_ready_dish_ids:
		return

	ready_dishes_initialized = true
	last_ready_dishes = dishes.duplicate()
	last_ready_dish_ids = dish_ids.duplicate()

	for child in ready_dishes_container.get_children():
		child.queue_free()

	if dishes.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No hay platos preparados"
		ready_dishes_container.add_child(empty_label)
		return

	for i in range(dishes.size()):
		var button := Button.new()

		button.text = DishTypes.title(dishes[i])
		button.icon = DishTypes.texture(dishes[i])
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 28)
		button.toggle_mode = true
		button.set_meta("dish_id", dish_ids[i])

		button.pressed.connect(
			_on_ready_dish_pressed.bind(dish_ids[i])
		)

		ready_dishes_container.add_child(button)
func _on_ready_dish_pressed(dish_id: int) -> void:
	ready_dish_selected.emit(dish_id)

func set_ready_dish_selection(selected_ids: Array[int], free_slots: int) -> void:
	for child in ready_dishes_container.get_children():
		if child is Button and not child.is_queued_for_deletion():
			var selected: bool = selected_ids.has(child.get_meta("dish_id"))
			child.set_pressed_no_signal(selected)
			child.disabled = not selected and selected_ids.size() >= free_slots
func _on_cook_speed_button_pressed() -> void:
	cook_speed_upgrade_requested.emit()
func _on_eating_speed_button_pressed() -> void:
	eating_speed_upgrade_requested.emit()
func _on_patience_button_pressed() -> void:
	patience_upgrade_requested.emit()
