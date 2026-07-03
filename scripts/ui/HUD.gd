extends Control

signal serve_customer_requested

@onready var money_label: Label = $VBoxContainer/MoneyLabel
@onready var test_serve_button: Button = $VBoxContainer/TestServeButton

func _ready() -> void:
	test_serve_button.pressed.connect(_on_test_serve_button_pressed)

func set_money(value: float) -> void:
	money_label.text = "Dinero: %.1f €" % value

func _on_test_serve_button_pressed() -> void:
	serve_customer_requested.emit()
