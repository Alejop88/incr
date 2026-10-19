extends "res://tests/test_automatic_waiters.gd"

func run_tests() -> void:
	var r: Node = world()
	var table: Node = r.get_node("Table01Point")
	var group: Node = seat(r, "Table01Point", [BURGER, PIZZA])
	var members: Array = group.get_customers()
	group.move_customers_to_seats(table.get_group_seat_positions(2), table.global_position)
	for member in members:
		member.set_physics_process(false)
	var first: Node = members[0]
	var second: Node = members[1]
	first.global_position = first.target_position
	first._physics_process(0.01)
	var visual: Node = first.get_node("Sprite2D")
	check(visual.seated and not second.get_node("Sprite2D").seated, "Each member sits only upon reaching their own chair")
	check(visual.direction == (1 if first.seat_facing.x > 0 else 2), "Seated customer faces the table")
	visual.update_movement(Vector2.ZERO, 0.4)
	check(visual.sitting_progress == 1.0 and not visual.eating, "Sitting transition ends in seated idle")
	check(table.receive_food(BURGER, first), "First dish can be served")
	check(not first.is_eating, "Group waits until everyone has food")
	check(table.receive_food(PIZZA, second), "Last dish starts the meal")
	check(first.is_eating and second.is_eating, "Meal state reaches all members")
	check(not second.get_node("Sprite2D").seated, "An early meal must not teleport a walking customer into sitting")
	second.global_position = second.target_position
	second._physics_process(0.01)
	check(second.get_node("Sprite2D").seated and second.get_node("Sprite2D").eating, "Late arrival preserves pending meal state")
	visual.eating_clock = 0.0
	visual.update_movement(Vector2.ZERO, 0.9)
	check(visual.seated_rig.bite == 3, "Eating advances from the plate to the mouth")
	check(visual.seated_rig.plate_target.is_equal_approx(visual.to_local(table.get_dish_position(0))), "Eating targets this customer's actual place setting")
	table._on_eating_timer_timeout()
	check(visual.seated and not visual.eating and visual.seated_rig.bite == 0, "Finished customers return to seated idle")
	var hair_style: int = visual.hair_style
	var skin_index: int = visual.skin_index
	first.leave_restaurant(Vector2(600, 100))
	check(not visual.seated and not visual.eating and not visual.seated_rig.visible, "Leaving restores the walking body")
	check(visual.hair_style == hair_style and visual.skin_index == skin_index, "Sitting preserves appearance")
	check(not visual.material.get_shader_parameter("hide_body"), "Standing body is visible again")
	# Finished VIPs must remain seated while other members eat later courses.
	var vip_group: Node = seat(r, "Table02Point", [BURGER, PIZZA], true)
	var vip_table: Node = r.get_node("Table02Point")
	var vip_a: Node = vip_group.get_customer(0)
	var vip_b: Node = vip_group.get_customer(1)
	for vip in vip_group.get_customers():
		vip.sit_down()
		vip.get_node("Sprite2D").update_movement(Vector2.ZERO, 0.4)
		vip.has_received_food = true
	vip_a.dishes_eaten = vip_a.total_dishes_to_eat
	vip_table._set_group_eating(true)
	check(not vip_a.is_eating and vip_b.is_eating, "Only unfinished VIPs animate in later courses")
	vip_table._set_group_eating(false)
	check(vip_b.get_node("Sprite2D").seated and not vip_b.get_node("Sprite2D").eating, "VIP returns to seated idle between courses")
	# Four directions and every hairstyle must keep the seated head/hair anchor.
	for direction in range(4):
		visual.stand_up()
		visual.sit_down([Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP][direction])
		for style in range(-1, visual.HAIR_STYLE_COUNT):
			visual.set_hair(style, 0)
			visual.update_movement(Vector2.ZERO, 0.4)
			check(visual.hair.visible == (style >= 0), "Bald/haired visibility is preserved seated")
		check(visual.seated_rig.facing == direction, "Rig supports every direction")
		var rig: Node2D = visual.seated_rig
		var hip_y: float = visual.position.y + (rig.position.y + rig.top.y + 180 + rig.drop + 36) * visual.scale.y
		check(is_equal_approx(hip_y, preload("res://scripts/SeatingLayout.gd").CUSHION_Y), "Seated thighs contact the actual cushion in every direction")
		var lowest: float = -INF
		for block in rig.blocks:
			lowest = maxf(lowest, block[0].end.y)
		var feet_y: float = visual.position.y + (rig.position.y + lowest) * visual.scale.y
		check(is_equal_approx(feet_y, preload("res://scripts/SeatingLayout.gd").FLOOR_Y), "Seated feet reach the chair floor rather than floating")
	var vip_visual: Node = vip_b.get_node("Sprite2D")
	var vip_contact: float = vip_visual.position.y + vip_visual.pieces[4].position.y * vip_visual.scale.y
	check(is_equal_approx(vip_contact, preload("res://scripts/SeatingLayout.gd").CUSHION_Y), "Legacy VIP hips use the same chair anchor")
	r.free()
	print("CUSTOMER SEATED TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(1 if failures else 0)
