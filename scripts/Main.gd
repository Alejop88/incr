extends Node

@onready var economy_manager: Node = $EconomyManager
@onready var restaurant: Node2D = $Restaurant
@onready var hud: Control = $CanvasLayer/HUD

func _ready() -> void:
	restaurant.customer_paid.connect(_on_customer_paid)
	economy_manager.money_changed.connect(_on_money_changed)
	hud.serve_customer_requested.connect(_on_serve_customer_requested)
	
	hud.set_money(economy_manager.money)

func _on_serve_customer_requested() -> void:
	restaurant.serve_test_customer()

func _on_customer_paid(amount: float) -> void:
	economy_manager.add_money(amount)

func _on_money_changed(new_money: float) -> void:
	hud.set_money(new_money)
