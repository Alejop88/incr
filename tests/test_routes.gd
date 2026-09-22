extends "res://tests/test_automatic_waiters.gd"

func run_tests() -> void:
	var r: Node = world()
	for table in r.tables:
		table.unlock()
	var navigator = load("res://scripts/RestaurantRoute.gd").new()
	var blocks: Array[Rect2] = navigator.table_obstacles(r.player_waiter)
	check(blocks.size() == r.tables.size(), "Every unlocked table must be a route obstacle")
	var destinations: Array[Vector2] = [r.kitchen_point.global_position, r.trash_point.global_position, r.customer_exit_point.global_position]
	for table in r.tables:
		destinations.append(table.get_service_position())
		for point in table.customer_seat_points:
			destinations.append(point.global_position)
	for origin in destinations:
		for destination in destinations:
			if origin == destination:
				continue
			var path: PackedVector2Array = navigator.build_path(origin, destination, blocks)
			check(not path.is_empty(), "All seats, service points, kitchen and exit must connect")
			var previous: Vector2 = origin
			for point in path:
				var seat_access: bool = false
				for block in blocks:
					if (previous == origin and block.has_point(origin)) or (point == destination and block.has_point(destination)):
						seat_access = is_equal_approx(previous.y, point.y)
				check(seat_access or navigator.segment_clear(previous, point, blocks), "Only lateral seat entry and exit may cross chair clearance")
				previous = point
	var table: Node = r.tables[0]
	var start: Vector2 = table.global_position - Vector2(200, 0)
	var target: Vector2 = table.global_position + Vector2(200, 0)
	var detour: PackedVector2Array = navigator.build_path(start, target, blocks)
	check(detour.size() > 1, "Cross-table route must bend around the table")
	var chair_start: Vector2 = table.global_position + Vector2(125, -220)
	var chair_end: Vector2 = table.global_position + Vector2(125, 220)
	var chair_route: PackedVector2Array = navigator.build_path(chair_start, chair_end, blocks)
	check(chair_route.size() > 1, "Passing alongside a table must go around its chairs")
	var chair_previous: Vector2 = chair_start
	for point in chair_route:
		check(navigator.segment_clear(chair_previous, point, blocks), "Through traffic cannot cross chair footprints")
		chair_previous = point
	for i in range(1, r.tables.size()):
		check(r.tables[i].position.y >= r.tables[i - 1].position.y, "Table numbering must progress from top to bottom")
	var customer: Node = load("res://scenes/customer/Customer.tscn").instantiate()
	r.add_child(customer)
	var automatic: Node = waiter(r)
	for actor in [r.player_waiter, customer, automatic]:
		actor.set_physics_process(false)
		actor.global_position = start
		var arrived: bool = false
		for step in range(30):
			var previous: Vector2 = actor.global_position
			arrived = actor.route.advance(actor, target, 10000.0, 1.0)
			check(navigator.segment_clear(previous, actor.global_position, blocks), "Every actor must follow safe segments")
			if arrived:
				break
		check(arrived and actor.global_position == target, "Every actor must finish its route")
	check(not navigator.build_path(table.global_position, target, blocks).is_empty(), "Unlocking a table around an actor must allow escape")
	r.free()
	print("ROUTE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
