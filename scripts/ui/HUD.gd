extends Control

signal serve_customer_requested

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
@onready var star_upgrades_button: Button = $StarUpgradesButton
@onready var waiter_speed_button: Button = $UpgradesPanel/VBoxContainer/WaiterSpeedButton
@onready var plate_price_button: Button = $UpgradesPanel/VBoxContainer/PlatePriceButton
@onready var buy_table_button: Button = $UpgradesPanel/VBoxContainer/BuyTableButton
func _ready() -> void:
	test_serve_button.pressed.connect(_on_test_serve_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	waiter_speed_button.pressed.connect(_on_waiter_speed_button_pressed)
	plate_price_button.pressed.connect(_on_plate_price_button_pressed)
	buy_table_button.pressed.connect(_on_buy_table_button_pressed)
	star_upgrades_button.pressed.connect(_on_star_upgrades_button_pressed)
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
