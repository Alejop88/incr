extends Control

signal serve_customer_requested

@onready var money_label: Label = $VBoxContainer/MoneyLabel
@onready var test_serve_button: Button = $VBoxContainer/TestServeButton
@onready var upgrades_button: Button = $VBoxContainer/UpgradesButton
@onready var upgrades_panel: PanelContainer = $UpgradesPanel
@onready var close_button: Button = $UpgradesPanel/VBoxContainer/CloseButton

func _ready() -> void:
	test_serve_button.pressed.connect(_on_test_serve_button_pressed)
	upgrades_button.pressed.connect(_on_upgrades_button_pressed)
	close_button.pressed.connect(_on_close_button_pressed)

func set_money(value: float) -> void:
	money_label.text = "Dinero: %.1f €" % value

func _on_test_serve_button_pressed() -> void:
	serve_customer_requested.emit()
	
func _on_upgrades_button_pressed() -> void:
	upgrades_panel.visible = true

func _on_close_button_pressed() -> void:
	upgrades_panel.visible = false
