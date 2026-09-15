extends "res://tests/test_automatic_waiters.gd"

var revenue: Dictionary = {"money": 0.0, "stars": 0}

func paid_world() -> Node:
	revenue = {"money": 0.0, "stars": 0}
	var restaurant: Node = world()
	restaurant.customer_paid.connect(func(amount: float): revenue["money"] += amount)
	restaurant.vip_completed.connect(func(amount: int): revenue["stars"] += amount)
	return restaurant

func finish_round(table: Node, group: Node) -> void:
	for customer in group.get_customers():
		if not customer.has_received_food:
			table.receive_food(customer.requested_dish)
	table.eating_timer.stop()
	table._on_eating_timer_timeout()

func run_tests() -> void:
	# Normal customers pay once, only after the waiter physically reaches the table.
	var r: Node = paid_world()
	var group: Node = seat(r, "Table02Point", [BURGER, PIZZA])
	var table: Node = r.get_node("Table02Point")
	finish_round(table, group)
	var a: Node = waiter(r)
	a._physics_process(0.2)
	check(a.state == a.State.TO_PAYMENT and revenue.money == 0, "Waiter must walk to collect payment")
	arrive(a)
	check(revenue.money == 10.0 and revenue.stars == 0, "Normal group must pay its full price exactly once")
	check(table.state == table.State.FREE, "Collection must free the table")
	check(not r.waiter_manager.collect_payment(a) and revenue.money == 10.0, "Repeated collection must not duplicate income")
	a._physics_process(0.2)
	check(a.state == a.State.RETURNING, "Idle waiter must return to the kitchen")
	a.speed = 2000.0
	a.set_physics_process(true)
	for i in range(180):
		if a.state == a.State.IDLE and a.global_position.distance_to(r.waiter_manager.get_waiting_position(a)) < 3.0:
			break
		await physics_frame
	check(a.global_position.distance_to(r.waiter_manager.get_waiting_position(a)) < 3.0, "Waiter must physically reach the waiting spot")
	var parked_position: Vector2 = a.global_position
	for i in range(20):
		await physics_frame
	check(a.global_position == parked_position, "Waiter must remain stationary when no tasks exist")
	r.free()

	# VIP stars only become collectible after every VIP finishes every round.
	r = paid_world()
	group = seat(r, "Table02Point", [BURGER, BURGER], true)
	group.get_customer(0).total_dishes_to_eat = 1
	group.get_customer(1).total_dishes_to_eat = 2
	table = r.get_node("Table02Point")
	a = waiter(r)
	finish_round(table, group)
	check(not r.waiter_manager.reserve_payment(a) and revenue.stars == 0, "VIPs must not pay between rounds")
	finish_round(table, group)
	a._physics_process(0.2)
	check(a.state == a.State.TO_PAYMENT, "Completed VIP group must become collectible")
	arrive(a)
	check(revenue.stars == 2 and revenue.money == 0, "VIP group must award one star per VIP")
	check(table.state == table.State.FREE, "VIP collection must free the table")
	r.free()

	# Player collects first and another group reuses the same table.
	r = paid_world()
	group = seat(r, "Table01Point", [BURGER])
	table = r.get_node("Table01Point")
	finish_round(table, group)
	a = waiter(r)
	a._physics_process(0.2)
	table.collect_payment()
	check(revenue.money == 5.0, "Player must still be able to collect a reserved payment")
	group = seat(r, "Table01Point", [PIZZA])
	finish_round(table, group)
	check(not r.waiter_manager.is_payment_valid(a), "Old payment reservation must not match a new group")
	a._physics_process(0.016)
	check(revenue.money == 5.0 and a.state == a.State.IDLE, "Lost payment job must cancel without another charge")
	a._physics_process(0.2)
	arrive(a)
	check(revenue.money == 10.0, "Waiter can subsequently claim the new group's actual payment")
	r.free()

	# Future multiple waiters reserve separate payments.
	r = paid_world()
	group = seat(r, "Table01Point", [BURGER])
	finish_round(r.get_node("Table01Point"), group)
	group = seat(r, "Table02Point", [BURGER, PIZZA])
	finish_round(r.get_node("Table02Point"), group)
	a = waiter(r)
	var b: Node = waiter(r)
	var c: Node = waiter(r)
	a._physics_process(0.2)
	b._physics_process(0.2)
	check(r.waiter_manager.payment_assignments[a]["table"] != r.waiter_manager.payment_assignments[b]["table"], "Waiters must not reserve the same bill")
	check(not r.waiter_manager.reserve_payment(c), "A third waiter must not duplicate payment reservations")
	check(r.waiter_manager.get_waiting_position(a) != r.waiter_manager.get_waiting_position(b), "Each waiter must have a separate waiting spot")
	arrive(b)
	arrive(a)
	check(revenue.money == 15.0 and r.waiter_manager.payment_assignments.is_empty(), "Both bills must be collected exactly once")
	r.free()

	# Returning home does not prevent reacting to new work, including payments.
	r = paid_world()
	a = waiter(r)
	a.global_position = r.get_node("Table01Point").global_position
	a._physics_process(0.2)
	check(a.state == a.State.RETURNING, "Waiter with no work must head home")
	group = seat(r, "Table01Point", [BURGER])
	plates(r, [BURGER])
	a._physics_process(0.3)
	check(a.state == a.State.TO_KITCHEN, "A new plate must interrupt the return home")
	arrive(a)
	check(a.carried_dish == BURGER, "Waiter must finish its delivery before taking another task")
	arrive(a)
	finish_round(r.get_node("Table01Point"), group)
	plates(r, [PIZZA])
	a._physics_process(0.2)
	check(a.state == a.State.TO_PAYMENT, "An idle waiter must prioritize freeing a paid table")
	r.free()
	print("WAITER PAYMENT TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
