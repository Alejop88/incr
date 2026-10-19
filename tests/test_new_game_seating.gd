extends "res://tests/test_save_slots.gd"

func run_tests() -> void:
	slots = root.get_node("SaveSlots")
	var menu := title()
	menu.new_game_button.pressed.emit()
	menu.mode_buttons["normal"].pressed.emit()
	menu.slot_buttons[0].pressed.emit()
	menu.character_creator.accept_button.pressed.emit()
	await process_frame
	await process_frame
	var game: Node = current_scene
	await check_seating(game, "new game")
	game.free()
	menu = title()
	menu.continue_button.pressed.emit()
	menu.slot_buttons[0].pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	await check_seating(game, "loaded game")
	Engine.time_scale = 1.0
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(slots.slot_path(base_path, 0)))
	slots.active_path = "user://partida.json"
	print("NEW GAME SEATING: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)

func check_seating(game: Node, context: String) -> void:
	var r: Node = game.restaurant
	# Spawn through the production entry point until the initial table is reserved.
	for attempt in range(20):
		if not r.active_customers.is_empty():
			break
		r.spawn_customer()
	r.customer_spawn_timer.stop()
	check(not r.active_customers.is_empty(), "A small group reserves the initial table")
	if r.active_customers.is_empty():
		return
	var group: Node = r.active_customers[0].get_parent()
	Engine.time_scale = 10.0
	for tick in range(240):
		await physics_frame
		r.tables[0].food_wait_timer.stop()
	for customer in group.customers:
		var visual: Node = customer.get_node("Sprite2D")
		check(customer.is_seated and visual.seated and visual.sitting_progress == 1.0, "%s: customers finish sitting on their chairs" % context)
		check(visual.seated_rig.visible and not visual.seated_rig.blocks.is_empty(), "%s: seated body is visible" % context)
		check(visual.material.get_shader_parameter("hide_body") == true, "%s: standing body is hidden" % context)


