extends "res://tests/test_automatic_waiters.gd"

const TRAITS = preload("res://scripts/MenuTraits.gd")

func run_tests() -> void:
	var catalog := {}
	for id in range(1, 7):
		catalog[id] = {"tags": ["Japonesa", "Arroz", "Pescado", "Marisco"]}
	catalog[7] = {"tags": ["Carne"]}
	var one: Dictionary = TRAITS.calculate("normal", [1], catalog)
	check(is_equal_approx(one.cooking_speed, 1.0), "Japanese dishes no longer grant cooking speed")
	check(one.eating_speed == 1.0 and TRAITS.dish_value_multiplier(1, one, catalog) == 1.0, "Threshold bonuses are absent below their requirements")
	var two: Dictionary = TRAITS.calculate("normal", [1, 2], catalog)
	check(is_equal_approx(two.cooking_speed, 1.1), "Two rice dishes activate the ten percent tier")
	var three: Dictionary = TRAITS.calculate("normal", [1, 2, 3], catalog)
	check(is_equal_approx(three.eating_speed, 1.15) and is_equal_approx(TRAITS.dish_value_multiplier(1, three, catalog), 1.1), "Three fish and three seafood activate eating and shared value bonuses")
	check(is_equal_approx(TRAITS.dish_value_multiplier(1, three, catalog), 1.1), "A dual-tag dish receives shared value bonus only once")
	check(TRAITS.dish_value_multiplier(7, three, catalog) == 1.0, "Unrelated dishes receive no value bonus")
	var five: Dictionary = TRAITS.calculate("normal", [1, 2, 3, 4, 5], catalog)
	check(is_equal_approx(five.cooking_speed, 1.3), "Five rice dishes use the thirty percent tier without stacking the ten percent tier")
	check(is_equal_approx(five.eating_speed, 1.15) and five.vip_rate == 1.0, "Five fish and seafood do not reach six-dish tiers")
	var six: Dictionary = TRAITS.calculate("normal", [1, 2, 3, 4, 5, 6], catalog)
	check(is_equal_approx(six.eating_speed, 1.3) and six.vip_rate == 1.05, "Six dishes activate higher fish tier and VIP multiplier")
	check(is_equal_approx(TRAITS.dish_value_multiplier(1, six, catalog), 1.25 * 1.1), "Independent seafood value bonuses combine")
	var cozy: Dictionary = TRAITS.calculate("cozy", [1, 2, 3, 4, 5, 6], catalog)
	check(cozy == TRAITS.calculate("cozy", []), "Cozy remains unaffected by all new traits")
	var fish_only := {1: {"tags": ["Pescado"]}, 2: {"tags": ["Pescado"]}, 3: {"tags": ["Pescado"]}}
	check(TRAITS.dish_value_multiplier(1, TRAITS.calculate("normal", [1, 2, 3], fish_only), fish_only) == 1.0, "Fish alone cannot activate seafood synergy")

	var r: Node = world()
	r.set_game_mode("normal")
	r.set_menu_capacity_bonus(2)
	r.unlocked_dishes.assign([DishTypes.Type.NIGIRI, DishTypes.Type.MAKI, DishTypes.Type.TEMAKI, DishTypes.Type.URAMAKI])
	r.set_menu_dishes(r.unlocked_dishes)
	check(is_equal_approx(r.kitchen_point.cook_time, 5.0 / (1.3 * 1.1 * 1.05)), "Real sushi menu combines cold, rice and raw cooking bonuses")
	check(is_equal_approx(r.tables[0].eating_time, 5.0 / (1.25 * 1.15)), "Real sushi menu combines sushi and fish eating bonuses")
	r.menu_effects = six
	r._apply_menu_traits()
	check(r.vip_spawn_chance == 0.0, "Seafood cannot unlock VIPs")
	r.set_vip_unlocked(true)
	check(is_equal_approx(r.vip_spawn_chance, 0.05 * 1.05), "Seafood increases existing VIP probability relatively")
	r.set_vip_spawn_bonus_level(2)
	check(is_equal_approx(r.vip_spawn_chance, 0.07 * 1.05), "VIP upgrades preserve seafood multiplier")
	r.plate_price_level = 1
	r.update_plate_price()
	var table: Node = r.get_node("Table02Point")
	seat(r, "Table02Point", [DishTypes.Type.PAELLA, BURGER])
	table.receive_food(DishTypes.Type.PAELLA)
	table.receive_food(BURGER)
	var receipts: Array = []
	table.payment_collected.connect(func(amount: float): receipts.append(amount))
	r.set_game_mode("cozy")
	table._on_eating_timer_timeout()
	table.collect_payment()
	check(receipts.size() == 1 and is_equal_approx(receipts[0], 6.0 * (1.375 + 1.0)), "Payment includes only eligible served dishes and keeps their bonus across menu changes")
	check(table.served_value_bonus == 0.0, "Clearing a table clears old value bonuses")
	check(is_equal_approx(r.vip_spawn_chance, 0.07), "Cozy removes seafood VIP bonus")
	seat(r, "Table02Point", [DishTypes.Type.PAELLA])
	table.receive_food(DishTypes.Type.PAELLA)
	table._on_eating_timer_timeout()
	table.collect_payment()
	check(receipts.size() == 2 and is_equal_approx(receipts[1], 6.0), "Next Cozy customer pays the unchanged base price")
	r.free()
	var editor: Node = load("res://scripts/ui/MenuEditor.gd").new()
	root.add_child(editor)
	editor.set_game_mode("normal")
	editor.open_menu([DishTypes.Type.NIGIRI, DishTypes.Type.MAKI, DishTypes.Type.TEMAKI, DishTypes.Type.URAMAKI])
	for tag in ["Japonesa", "Arroz", "Pescado"]:
		check(editor.active_trait_labels[tag].visible, "Active preview includes " + tag)
	check(not editor.active_trait_labels["Marisco"].visible, "Preview hides unmet seafood trait")
	editor.free()
	print("SEAFOOD TRAITS TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
