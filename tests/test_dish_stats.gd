extends "res://tests/test_automatic_waiters.gd"

func run_tests() -> void:
	check(DishTypes.CATALOG.size() == 139, "All supplied dishes are present")
	for dish in DishTypes.CATALOG:
		var entry: Dictionary = DishTypes.CATALOG[dish]
		check(entry.has("value") and entry.has("cook_time"), "Every recipe has explicit statistics")
		check(DishTypes.dish_value(dish, "cozy") == 5.0 and DishTypes.dish_cook_time(dish, "cozy") == 5.0, "Cozy remains uniform")
	var r: Node = world()
	r.kitchen_point.game_mode = "normal"
	check(r.kitchen_point.get_dish_cook_time(DishTypes.Type.PAELLA) == 7.0, "Paella cooks for seven seconds")
	r.kitchen_point.set_cook_speed_level(5)
	check(r.kitchen_point.get_dish_cook_time(DishTypes.Type.PAELLA) == 6.0, "Cooking upgrades subtract from each recipe")
	check(r.kitchen_point.get_dish_cook_time(DishTypes.Type.JAMON_IBERICO) == 0.5, "Fast recipes keep the minimum duration")
	var group: Node = seat(r, "Table01Point", [DishTypes.Type.MAKI, DishTypes.Type.SASHIMI])
	var table: Node = r.get_node("Table01Point")
	table.game_mode = "normal"
	table.payment_amount = 6.0
	table.dish_value_multipliers[DishTypes.Type.MAKI] = 1.5
	table.receive_food(DishTypes.Type.MAKI, group.customers[0])
	table.receive_food(DishTypes.Type.SASHIMI, group.customers[1])
	check(is_equal_approx(table.served_value_total, 16.5), "Mixed recipes use their own value plus upgrades and bonuses")
	var payments := []
	table.payment_collected.connect(func(amount: float): payments.append(amount))
	table._on_eating_timer_timeout()
	table.collect_payment()
	check(payments == [16.5] and table.served_value_total == 0.0, "Payment uses the served total and resets it")
	r.free()
	print("DISH STATS TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
