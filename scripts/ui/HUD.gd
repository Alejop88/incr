extends Control

signal serve_customer_requested

@onready var money_label: Label = $VBoxContainer/MoneyLabel
@onready var test_serve_button: Button = $VBoxContainer/TestServeButton
@onready var upgrades_button: Button = $VBoxContainer/UpgradesButton
@onready var upgrades_panel: PanelContainer = $UpgradesPanel
@onready var close_button: Button = $UpgradesPanel/VBoxContainer/CloseButton
signal waiter_speed_upgrade_requested
@onready var waiter_speed_button: Button = $UpgradesPanel/VBoxContainer/WaiterSpeedButton
func _ready() -> void:
	test_serve_button.pressed.connect(_on_test_serve_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)
	waiter_speed_button.pressed.connect(_on_waiter_speed_button_pressed)
func set_money(value: float) -> void:
	money_label.text = "Dinero: %.1f €" % value

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
