extends "res://tests/test_automatic_waiters.gd"

func run_tests() -> void:
	Engine.time_scale = 10.0
	for scenario in [[1, 0], [2, 0], [4, 1], [4, 11], [2, 12], [3, 9]]:
		var size: int = scenario[0]
		var r: Node = world()
		r.customer_spawn_timer.stop()
		var table: Node = r.tables[scenario[1]]
		if scenario[1] > 1:
			for other_table in r.tables:
				other_table.unlock()
		table.unlock()
		var group: Node = GROUP.instantiate()
		r.add_child(group)
		group.global_position = r.customer_spawn_point.global_position
		group.setup(size)
		table.reserve(group)
		group.get_leader().destination_reached.connect(r._on_customer_destination_reached.bind(group.get_leader(), table))
		group.move_customers_to_seats(table.get_group_seat_positions(size), table.global_position)
		for tick in range(360):
			await physics_frame
			table.food_wait_timer.stop()
			var arrived := true
			for customer in group.customers:
				arrived = arrived and customer.is_seated
			if arrived:
				break
		for customer in group.customers:
			print("ARRIVAL ", size, " pos=", customer.global_position, " target=", customer.target_position, " seated=", customer.is_seated, " visual=", customer.get_node("Sprite2D").seated, " waiting=", customer._wait_for_group_member())
			check(customer.is_seated and customer.get_node("Sprite2D").seated, "Customers must walk to their chair and sit without teleportation")
		r.free()
	Engine.time_scale = 1.0
	print("CUSTOMER ARRIVAL TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)
