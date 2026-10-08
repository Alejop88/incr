extends "res://tests/test_automatic_waiters.gd"

const TRAITS = preload("res://scripts/MenuTraits.gd")
const BALANCE = preload("res://scripts/TagBalance.gd")
const RULES = preload("res://scripts/TagRules.gd")

func fixture(tags: Array, count: int) -> Dictionary:
	var catalog := {}
	for i in range(count):
		catalog[i + 100] = {"tags": tags}
	return catalog

func calculate(catalog: Dictionary, mode: String = "normal") -> Dictionary:
	return TRAITS.calculate(mode, catalog.keys(), catalog)

func approx(actual: float, expected: float, message: String) -> void:
	check(is_equal_approx(actual, expected), message + ": " + str(actual) + " != " + str(expected))

func run_tests() -> void:
	check(RULES.tags().size() == 28, "All 28 requested tags have rules")
	var used: Array = []
	for rule in RULES.all():
		for effect in rule.effects:
			check(BALANCE.PERCENTAGES.has(effect.key), "Every effect has a balance setting")
			used.append(effect.key)
	for key in BALANCE.PERCENTAGES:
		check(used.has(key) or str(key).begins_with("compartir_"), "No unused percentage: " + key)
	var catalog := fixture(["Crudo", "Picante"], 3)
	var effects := calculate(catalog)
	approx(effects.cooking_speed, 1.15, "Raw bonus per distinct dish")
	approx(effects.waiter_speed, 1.06, "Spicy staff bonus per dish")
	approx(effects.table_patience, 0.94, "Spicy patience cost per dish")
	var changed: Dictionary = BALANCE.PERCENTAGES.duplicate()
	changed.cruda_cocina_por_plato = 7.5
	approx(TRAITS.calculate("normal", catalog.keys(), catalog, changed).cooking_speed, 1.225, "Changing only config changes gameplay")
	check(RULES.description("Cruda", changed).contains("7.5"), "Descriptions use the same changed percentage")
	for case in [[1, 1.0, 1.0], [2, 1.5, 1.1], [3, 1.5, 1.1], [4, 1.75, 1.2]]:
		effects = calculate(fixture(["Caldo"], case[0]))
		approx(effects.table_patience, case[1], "Broth patience tier")
		approx(effects.cooking_time, case[2], "Broth increases duration, not subtracting speed")
	catalog = fixture(["Frito"], 2)
	effects = calculate(catalog)
	approx(effects.customer_rate, 1.5, "All fried arrival bonus")
	approx(effects.vip_rate, 0.7, "All fried VIP cost")
	catalog[999] = {"tags": []}
	approx(calculate(catalog).customer_rate, 1.0, "Mixed menu removes all-fried bonus")
	catalog = fixture(["Desayuno"], 2)
	effects = calculate(catalog)
	approx(TRAITS.dish_value_multiplier(100, effects, catalog), 1.15, "All breakfast value")
	approx(calculate(fixture(["Comida rápida"], 2)).cooking_speed, 1.0, "Fast-food below threshold")
	approx(calculate(fixture(["Comida rápida"], 3)).cooking_speed, 1.3, "Three fast-food cooking bonus")
	effects = calculate(fixture(["Gourmet"], 1))
	approx(effects.customer_rate, 0.5, "All gourmet customer cost")
	approx(effects.vip_rate, 1.5, "All gourmet VIP bonus")
	catalog = fixture(["Vegetariano"], 2)
	effects = calculate(catalog)
	approx(effects.queue_patience, 1.15, "Vegetarian queue patience")
	approx(effects.table_patience, 1.15, "Vegetarian table patience")
	catalog[999] = {"tags": ["Carne"]}
	effects = calculate(catalog)
	approx(effects.customer_rate, 0.85, "Mixed vegetarian menu arrival penalty")
	approx(effects.table_patience, 1.0, "Mixed menu loses all-vegetarian benefit")
	for case in [[1, 1.05], [4, 1.05], [5, 1.15], [9, 1.15], [10, 1.3]]:
		catalog = fixture(["Vegano"], case[0])
		catalog[999] = {"tags": ["Vegetales"]}
		effects = calculate(catalog)
		approx(TRAITS.dish_value_multiplier(999, effects, catalog), case[1], "Vegan vegetable value tier")
		approx(effects.customer_rate, 0.85 if case[0] >= 10 else 1.0, "Vegan arrival cost only at ten")
		catalog[998] = {"tags": ["Vegetariana"]}
		effects = calculate(catalog)
		approx(TRAITS.dish_value_multiplier(998, effects, catalog), 1.1 if case[0] >= 10 else 1.0, "Vegan vegetarian bonus only at ten")
	for pair in [["Japonesa", "Cruda"], ["Italiana", "Pasta"], ["Mexicana", "Picante"], ["China", "Arroz"], ["Española", "Para compartir"], ["Peruana", "Pescado"], ["Estadounidense", "Comida rápida"], ["Francesa", "Gourmet"]]:
		catalog = fixture([pair[0]], 3)
		catalog[999] = {"tags": [pair[1]]}
		effects = calculate(catalog)
		approx(TRAITS.dish_value_multiplier(999, effects, catalog), 1.06, "Origin increases only target value: " + pair[0])
		approx(TRAITS.dish_value_multiplier(100, effects, catalog), 1.0, "Origin alone has no own value bonus")
	catalog = fixture(["Carne"], 5)
	catalog[999] = {"tags": ["Pescado", "Marisco"]}
	effects = calculate(catalog)
	approx(TRAITS.dish_value_multiplier(100, effects, catalog), 1.3, "Meat value bonus")
	approx(TRAITS.dish_cooking_speed(100, effects, catalog), 0.7, "Meat cooking speed cost")
	approx(TRAITS.dish_value_multiplier(999, effects, catalog), 1.0, "Fish excludes meat value effect")
	approx(TRAITS.dish_cooking_speed(999, effects, catalog), 1.0, "Seafood excludes meat cooking cost")
	for case in [[1, 1.0], [2, 1.05], [4, 1.05], [5, 1.1], [9, 1.1], [10, 1.25]]:
		approx(calculate(fixture(["Patata"], case[0])).waiter_speed, case[1], "Potato tier")
	for case in [[1, 1.02], [2, 1.02], [3, 1.08], [5, 1.08], [6, 1.15], [8, 1.15], [9, 1.4]]:
		catalog = fixture(["Vegetales"], case[0])
		catalog[999] = {"tags": ["Vegana"]}
		effects = calculate(catalog)
		approx(effects.queue_patience, case[1], "Vegetable queue tier")
		approx(TRAITS.dish_cooking_speed(999, effects, catalog), 1.25 if case[0] >= 9 else 1.0, "Nine vegetables speed up only vegan dishes")
	for case in [[1, 1.02], [3, 1.02], [4, 1.1], [6, 1.1], [7, 1.25]]:
		approx(calculate(fixture(["Fideos"], case[0])).customer_rate, case[1], "Pasta arrival tier")
	catalog = fixture(["Caldo"], 3)
	catalog[999] = {"tags": ["Pasta"]}
	effects = calculate(catalog)
	approx(TRAITS.dish_value_multiplier(999, effects, catalog), 1.15, "Pasta and three broth synergy")
	for case in [[1, 1.0], [2, 1.15], [5, 1.15], [6, 1.25], [9, 1.25], [10, 1.5]]:
		catalog = fixture(["Pan", "Masa", "Harina"], case[0])
		effects = calculate(catalog)
		approx(TRAITS.dish_value_multiplier(100, effects, catalog), case[1], "Dough tier counts aliases only once")
		approx(effects.cooking_speed, 1.25 if case[0] >= 10 else 1.0, "Ten dough dishes global cooking bonus")
	# Every rule is inert in Cozy, including high thresholds and conflicting tags.
	catalog = fixture(RULES.tags(), 10)
	check(calculate(catalog, "cozy") == TRAITS.calculate("cozy", []), "Every trait is inert in Cozy")
	await integration_tests()
	print("TAG BALANCE TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)

func integration_tests() -> void:
	var r: Node = world()
	r.set_game_mode("normal")
	r.unlocked_dishes.assign([PIZZA, DishTypes.Type.SOUP])
	r.set_menu_dishes([PIZZA])
	var effects: Dictionary = r.menu_effects
	for n in [2, 3, 4]:
		approx(TRAITS.order_weights([PIZZA, BURGER], [PIZZA], n, effects)[0], [1.2, 1.33, 1.5][n - 2], "Sharing weight for group size")
		approx(TRAITS.order_weights([PIZZA, BURGER], [PIZZA], n, effects)[1], 1.0, "Other orders keep base weight")
		approx(TRAITS.sharing_speed(PIZZA, n, effects), [1.2, 1.3, 1.4][n - 2], "Sharing cooking tier")
	approx(TRAITS.order_weights([PIZZA], [], 4, effects)[0], 1.0, "First diner has no repeat bonus")
	var group: Node = seat(r, "Table02Point", [PIZZA, PIZZA, PIZZA])
	var table: Node = r.get_node("Table02Point")
	r.kitchen_point.add_orders(group.get_customers(), table)
	approx(r.kitchen_point.cook_timer.wait_time, 5.0 / 1.3, "First repeated order gets exact same-table bonus")
	check(r.kitchen_point.order_contexts.size() == r.kitchen_point.order_queue.size(), "Queue and contexts remain aligned")
	r.kitchen_point.add_order(BURGER)
	r.kitchen_point.move_order_up(2)
	check(r.kitchen_point.order_contexts[1].is_empty(), "Moving order preserves its context")
	r.kitchen_point.move_order_down(1)
	r.kitchen_point.cancel_order(2)
	check(r.kitchen_point.order_queue.size() == 2 and r.kitchen_point.order_contexts.size() == 2, "Cancel removes associated context")
	var context: Dictionary = r.kitchen_point.order_contexts[0]
	table.clear_seated_customer()
	approx(r.kitchen_point.get_dish_cook_time(PIZZA, context), 5.0, "Departed group cannot grant a cooking bonus")
	seat(r, "Table02Point", [PIZZA])
	approx(r.kitchen_point.get_dish_cook_time(PIZZA, context), 5.0, "New group on same table cannot reuse old round bonus")
	# Patience multipliers reach both ordinary and VIP timers without changing their bases.
	r.menu_effects = calculate(fixture(["Caldo"], 4))
	r._apply_menu_traits()
	var vip_group: Node = seat(r, "Table04Point", [BURGER], true)
	var vip_table: Node = r.get_node("Table04Point")
	vip_table.start_next_food_round(vip_group.get_leader(), 1)
	approx(vip_table.food_wait_timer.wait_time, VIPCustomer.FOOD_WAIT_TIME * 1.75, "Broth affects VIP table patience")
	approx(r.kitchen_point.get_dish_cook_time(BURGER), 6.0, "Broth applies extra cooking duration")
	r.menu_effects = calculate(fixture(["Vegetariana"], 1))
	r._apply_menu_traits()
	vip_group.menu_effects = r.menu_effects
	vip_group.start_queue_patience()
	approx(vip_group.queue_patience_timer.wait_time, VIPCustomer.QUEUE_WAIT_TIME * 1.15, "Vegetarian bonus affects VIP queue")
	vip_table.start_next_food_round(vip_group.get_leader(), 1)
	approx(vip_table.food_wait_timer.wait_time, VIPCustomer.FOOD_WAIT_TIME * 1.15, "New VIP rounds use current patience")
	r.set_game_mode("cozy")
	approx(r.kitchen_point.get_dish_cook_time(PIZZA, context), 5.0, "Cozy removes all cooking and sharing effects")
	r.free()
	# Two separate single-person tables must never combine into a sharing bonus.
	r = world()
	r.set_game_mode("normal")
	r.unlocked_dishes.assign([PIZZA])
	r.set_menu_dishes([PIZZA])
	var first: Node = seat(r, "Table01Point", [PIZZA])
	var second: Node = seat(r, "Table02Point", [PIZZA])
	r.kitchen_point.add_orders(first.get_customers(), r.get_node("Table01Point"))
	r.kitchen_point.add_orders(second.get_customers(), r.get_node("Table02Point"))
	approx(r.kitchen_point.cook_timer.wait_time, 5.0, "Separate tables cannot pool sharing orders")
	approx(r.kitchen_point.get_dish_cook_time(PIZZA, r.kitchen_point.order_contexts[0]), 5.0, "Second table also keeps base cooking time")
	r.free()
	# A real VIP repeat round picks the whole round before starting its first dish.
	r = world()
	r.set_game_mode("normal")
	r.unlocked_dishes.assign([PIZZA])
	r.set_menu_dishes([PIZZA])
	group = seat(r, "Table02Point", [PIZZA, PIZZA], true)
	table = r.get_node("Table02Point")
	for customer in group.get_customers():
		customer.total_dishes_to_eat = 3
	table.receive_food(PIZZA)
	table.receive_food(PIZZA)
	table._on_eating_timer_timeout()
	approx(r.kitchen_point.cook_timer.wait_time, 5.0 / 1.2, "VIP next round includes both repeated orders")
	check(table.required_plates == 2 and table.food_round == 2, "VIP round has matching table context")
	r.free()
	await process_frame
