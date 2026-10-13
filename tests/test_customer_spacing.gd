extends "res://tests/test_automatic_waiters.gd"

func run_tests() -> void:
	var group = load("res://scenes/customer/CustomerGroup.tscn").instantiate()
	root.add_child(group)
	group.setup(4)
	group.move_to_queue_position(Vector2(800, 0))
	for i in range(4):
		for j in range(i + 1, 4):
			check(group.customers[i].position.distance_to(group.customers[j].position) >= 96.0, "Group starts spaced apart")
			check(group.customers[i].target_position.distance_to(group.customers[j].target_position) >= 96.0, "Queue destinations stay spaced apart")
	var first = group.customers[0]
	var follower = group.customers[1]
	first.position = Vector2(200, 0)
	follower.position = Vector2(150, 0)
	first.move_to_position(Vector2(800, 0), first.TargetType.QUEUE)
	follower.move_to_position(Vector2(800, 0), follower.TargetType.QUEUE)
	check(follower._wait_for_group_member() and not first._wait_for_group_member(), "Follower leaves room for the person ahead")
	first.position.x = 250
	check(not follower._wait_for_group_member(), "Follower resumes once space opens")
	group.free()
	print("CUSTOMER SPACING TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
