extends "res://tests/test_automatic_waiters.gd"

func run_tests() -> void:
	var r: Node = world()
	check(r.tables.size() == 6, "Restaurant must have six tables")
	check(r.tables[0].unlocked and r.tables[0].seat_capacity == 2, "Initial table seats two")
	for i in range(1, 6):
		var table: Node = r.tables[i]
		check(not table.unlocked and not table.can_seat_group(1), "Locked tables cannot receive customers")
		check(r.get_next_table_description().contains(str(i + 1).pad_zeros(2)), "Next purchase must follow table order")
		check(r.unlock_next_table(), "Each sequential table must unlock")
		check(table.visible and table.unlocked, "Purchased table must become visible and usable")
		check(table.customer_seat_points.size() == table.seat_capacity, "Every seat capacity must have matching markers")
		check(not table.can_seat_group(table.seat_capacity + 1), "Table cannot seat an oversized group")
		var dishes: Array = []
		for j in range(table.seat_capacity):
			dishes.append(BURGER)
		seat(r, str(table.name), dishes)
		for dish in dishes:
			check(table.receive_food(dish), "Every customer at the new table can be served")
		check(table.state == table.State.EATING, "Full group starts eating")
		table._on_eating_timer_timeout()
		check(table.collect_payment() and table.is_available(), "New table pays and becomes available again")
	check(not r.has_locked_tables() and not r.unlock_next_table(), "No further purchases after the last table")
	for size in [1, 2]:
		for attempt in range(20):
			check(r.get_available_table(size).seat_capacity == 2, "Small groups must prefer two-seat tables")
	for table in r.tables:
		if table.seat_capacity == 2:
			table.state = table.State.RESERVED
	for size in [1, 2, 3, 4]:
		check(r.get_available_table(size).seat_capacity == 4, "Full small tables must allow fallback to four seats")
	r.tables[0].state = r.tables[0].State.FREE
	check(r.get_available_table(1) == r.tables[0] and r.get_available_table(2) == r.tables[0], "Newly freed small table immediately regains priority")
	check(r.get_available_table(3).seat_capacity == 4, "Large groups cannot be assigned to a small table")
	for table in r.tables:
		table.state = table.State.RESERVED
	check(r.get_available_table(1) == null, "No free tables means waiting")
	r.free()
	print("TABLE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
