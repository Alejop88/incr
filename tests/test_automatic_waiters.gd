extends SceneTree

const RESTAURANT = preload("res://scenes/restaurant/Restaurant.tscn")
const GROUP = preload("res://scenes/customer/CustomerGroup.tscn")
const BURGER = DishTypes.Type.BURGER
const PIZZA = DishTypes.Type.PIZZA
const NONE = DishTypes.Type.NONE
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func world() -> Node:
	var restaurant: Node = RESTAURANT.instantiate()
	root.add_child(restaurant)
	return restaurant

func seat(restaurant: Node, table_name: String, dishes: Array, vip: bool = false) -> Node:
	var table: Node = restaurant.get_node(table_name)
	table.unlock()
	var group: Node = GROUP.instantiate()
	group.is_vip_group = vip
	restaurant.add_child(group)
	group.setup(dishes.size())
	for i in range(dishes.size()):
		var customer: Node = group.get_customer(i)
		customer.set_requested_dish(dishes[i])
		customer.target_type = customer.TargetType.TABLE
		customer.is_seated = true
	check(table.reserve(group), "Fixture must reserve a table")
	check(table.seat_customer(group.get_leader()), "Fixture must seat the group")
	table.food_wait_timer.stop()
	return group

func plates(restaurant: Node, dishes: Array) -> void:
	var kitchen: Node = restaurant.kitchen_point
	for dish in dishes:
		kitchen.ready_dishes.append(dish)
		kitchen.ready_dish_ids.append(kitchen.next_ready_dish_id)
		kitchen.next_ready_dish_id += 1

func waiter(restaurant: Node) -> Node:
	var actor: Node = restaurant.waiter_manager.create_waiter()
	actor.set_physics_process(false)
	return actor

func arrive(actor: Node) -> void:
	actor.global_position = actor.target_position
	actor._physics_process(1.0 / 60.0)

func begin_delivery(actor: Node) -> void:
	actor._physics_process(0.2)
	arrive(actor)

func run_tests() -> void:
	# Latest prepared dish, physical movement, exact delivery, no automatic payment.
	var r: Node = world()
	seat(r, "Table01Point", [BURGER])
	var group: Node = seat(r, "Table02Point", [PIZZA])
	plates(r, [BURGER, PIZZA])
	var a: Node = waiter(r)
	a._physics_process(0.2)
	check(r.waiter_manager.assignments[a]["dish_id"] == 1, "Waiter must reserve the newest cooked plate")
	arrive(a)
	check(a.carried_dish == PIZZA and r.kitchen_point.ready_dishes == [BURGER], "Pickup must remove only the reserved newest plate")
	a.speed = 1800.0
	a.set_physics_process(true)
	for i in range(180):
		if group.get_customer(0).has_received_food:
			break
		await physics_frame
	a.set_physics_process(false)
	check(group.get_customer(0).has_received_food, "Waiter must physically reach and serve the table")
	check(a.carried_dish == NONE, "Served food must leave the waiter's hands")
	r.get_node("Table02Point")._on_eating_timer_timeout()
	check(r.get_node("Table02Point").state == r.get_node("Table02Point").State.WAITING_PAYMENT, "Waiter must leave payment for the player")
	r.free()

	# Player steals the reserved plate; retry a different real plate without duplication.
	r = world()
	seat(r, "Table01Point", [BURGER])
	seat(r, "Table02Point", [PIZZA])
	plates(r, [BURGER, PIZZA])
	a = waiter(r)
	a._physics_process(0.2)
	check(r.kitchen_point.take_ready_dish_by_id(1) == PIZZA, "Player may take reserved food")
	arrive(a)
	check(a.carried_dish == NONE and r.waiter_manager.assignments.is_empty(), "Missing plate must release the old job")
	a._physics_process(0.2)
	check(r.waiter_manager.assignments[a]["dish_id"] == 0, "Waiter must retry another available dish")
	r.free()

	# Player serves first; redirect the carried dish to another table.
	r = world()
	seat(r, "Table01Point", [BURGER])
	group = seat(r, "Table02Point", [BURGER])
	plates(r, [BURGER])
	a = waiter(r)
	a.global_position = r.get_node("Table01Point").global_position
	begin_delivery(a)
	check(r.waiter_manager.assignments[a]["table"] == r.get_node("Table01Point"), "Nearest matching customer must be selected")
	r.get_node("Table01Point").receive_food(BURGER)
	a._physics_process(0.016)
	check(r.waiter_manager.assignments[a]["table"] == r.get_node("Table02Point"), "Player intervention must redirect the waiter")
	arrive(a)
	check(group.get_customer(0).has_received_food, "Redirected dish must reach the other customer")
	r.free()

	# No remaining demand: physically carry food to trash before discarding it.
	r = world()
	seat(r, "Table01Point", [BURGER])
	plates(r, [BURGER])
	a = waiter(r)
	begin_delivery(a)
	r.get_node("Table01Point").receive_food(BURGER)
	a._physics_process(0.016)
	check(a.state == a.State.TO_TRASH and a.carried_dish == BURGER, "Unwanted carried food must travel to trash")
	arrive(a)
	check(a.carried_dish == NONE and a.state == a.State.IDLE, "Food must be discarded only at the trash")
	r.free()

	# Two staff members, same group and dish type: reserve different customers.
	r = world()
	group = seat(r, "Table02Point", [BURGER, BURGER])
	plates(r, [BURGER, BURGER, BURGER])
	a = waiter(r)
	var b: Node = waiter(r)
	var c: Node = waiter(r)
	a._physics_process(0.2)
	b._physics_process(0.2)
	check(r.waiter_manager.assignments[a]["dish_id"] != r.waiter_manager.assignments[b]["dish_id"], "Waiters must reserve different plates")
	check(r.waiter_manager.assignments[a]["customer"] != r.waiter_manager.assignments[b]["customer"], "Waiters must reserve different customers")
	check(not r.waiter_manager.reserve_pickup(c), "Extra waiter must not compete for already reserved customers")
	arrive(a)
	arrive(b)
	arrive(b)
	check(group.get_customer(1).has_received_food and not group.get_customer(0).has_received_food, "Serving in reverse order must respect exact customer reservations")
	arrive(a)
	check(r.get_node("Table02Point").delivered_plates == 2, "Group must receive exactly two plates")
	check(r.waiter_manager.assignments.is_empty(), "Successful deliveries must release all reservations")
	r.free()

	# Customers leaving and freed objects must not leave stale reservations.
	r = world()
	group = seat(r, "Table01Point", [BURGER])
	plates(r, [BURGER])
	a = waiter(r)
	begin_delivery(a)
	r.get_node("Table01Point").clear_seated_customer()
	group.free()
	a._physics_process(0.016)
	check(a.state == a.State.TO_TRASH, "Departed customers must invalidate the destination safely")
	# A new customer can reclaim the food before it reaches the trash.
	group = seat(r, "Table01Point", [BURGER])
	a._physics_process(0.3)
	check(a.state == a.State.TO_TABLE, "New demand must rescue a dish on its way to trash")
	arrive(a)
	check(group.get_customer(0).has_received_food, "Rescued dish must be served")
	r.free()

	# VIPs completing different numbers of rounds; old reservations cannot block new orders.
	r = world()
	group = seat(r, "Table02Point", [BURGER, BURGER], true)
	group.get_customer(0).total_dishes_to_eat = 1
	group.get_customer(1).total_dishes_to_eat = 2
	plates(r, [BURGER, BURGER])
	a = waiter(r)
	a._physics_process(0.2)
	var table: Node = r.get_node("Table02Point")
	table.receive_food(BURGER)
	table.receive_food(BURGER)
	table._on_eating_timer_timeout()
	group.get_customer(1).set_requested_dish(BURGER)
	check(not r.waiter_manager.is_delivery_valid(a), "Reservation must expire when the VIP food round changes")
	b = waiter(r)
	check(r.waiter_manager.reserve_pickup(b), "Old round reservation must not block the continuing VIP")
	check(r.waiter_manager.assignments[b]["customer"] == group.get_customer(1), "Finished VIP must not receive another dish")
	b.free()
	check(not r.waiter_manager.assignments.has(b), "Removing a waiter must release its reservations")
	r.free()

	# Complete a VIP's three rounds through the actual timers and movement loop.
	r = world()
	group = seat(r, "Table01Point", [BURGER], true)
	group.get_customer(0).total_dishes_to_eat = 3
	r.kitchen_point.cook_time = 0.03
	r.kitchen_point.add_order(BURGER)
	a = waiter(r)
	a.speed = 2500.0
	a.set_physics_process(true)
	table = r.get_node("Table01Point")
	for i in range(900):
		if group.get_customer(0).dishes_eaten == 3:
			break
		if table.eating_timer.time_left > 0.1:
			table.eating_timer.start(0.03)
		await physics_frame
	check(group.get_customer(0).dishes_eaten == 3, "Waiter must complete all VIP food rounds automatically")
	check(table.state == table.State.WAITING_PAYMENT, "Completed VIP must wait for manual collection")
	check(r.waiter_manager.assignments.is_empty(), "VIP completion must leave no stale reservations")
	r.free()
	print("AUTOMATIC WAITER TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
