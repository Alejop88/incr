extends Node2D

signal customer_paid(amount: float)

var base_plate_price: float = 5.0

func serve_test_customer() -> void:
	customer_paid.emit(base_plate_price)
