extends Node

signal money_changed(new_money: float)

var money: float = 0.0

func add_money(amount: float) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: float) -> bool:
	if money < amount:
		return false

	money -= amount
	money_changed.emit(money)
	return true
