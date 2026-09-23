extends "res://tests/test_dish_unlocks.gd"

func count_tables(game: Node) -> int:
	var count := 0
	for table in game.restaurant.tables:
		if table.unlocked:
			count += 1
	return count

func run_tests() -> void:
	var fixture := FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n[node name="Main" instance=ExtResource("1")]\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var game: Node = load(fixture_path).instantiate()
	root.add_child(game)
	current_scene = game
	game.michelin_manager.stars = 500
	game._on_star_upgrades_requested()
	var panel: Control = game.michelin_upgrades
	check(panel.get_upgrade_ids().size() == game.michelin_manager.upgrade_costs.size(), "Every upgrade must be represented in the tree")
	check(panel.upgrade_buttons.permanent_table_2.disabled, "Later table levels require previous levels")
	for id in ["permanent_table_1", "permanent_table_2", "permanent_table_3", "permanent_waiter", "permanent_waiter_2", "permanent_waiter_3", "waiter_capacity_2", "staff_training_1", "staff_training_2", "staff_training_3"]:
		panel.upgrade_buttons[id].pressed.emit()
	check(count_tables(game) == 1 and game.restaurant.waiter_manager.waiters.is_empty(), "Selection must not grant bonuses before purchase")
	panel.upgrade_buttons.permanent_table_1.pressed.emit()
	check(not game.michelin_manager.selected_upgrades.has("permanent_table_3"), "Removing a prerequisite must remove descendants")
	for id in ["permanent_table_1", "permanent_table_2", "permanent_table_3"]:
		panel.upgrade_buttons[id].pressed.emit()
	await process_frame
	await process_frame
	var map: Control = panel.tree_map
	check(map.nodes.size() == panel.upgrade_buttons.size(), "Map must contain every upgrade node")
	var point := Vector2(170, 90)
	var world_point: Vector2 = (point - map.canvas.position) / map.view_zoom
	map.zoom_at(point, 1.15)
	check(world_point.distance_to((point - map.canvas.position) / map.view_zoom) < 0.01, "Tree zoom must keep the cursor position anchored")
	map.zoom_at(point, 100)
	check(map.view_zoom == 1.6, "Tree zoom must have an upper limit")
	map.zoom_at(point, 0.001)
	check(map.view_zoom == 0.3, "Tree zoom must have a lower limit")
	map.fit_tree()
	panel._show_detail("permanent_table_1")
	check(panel.detail_label.text.contains("mesa"), "Hover detail must identify the selected node")
	check(panel.purchase_button.get_global_rect().end.y <= panel.get_global_rect().end.y, "Purchase button must stay inside the enlarged panel")
	panel.purchase_button.pressed.emit()
	panel.confirm_button.pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(count_tables(game) == 4, "Three permanent table upgrades must start with four tables")
	check(game.table_purchase_cost == 50, "Free starting tables must not increase the first money purchase price")
	var staff: Node = game.restaurant.waiter_manager
	check(staff.waiters.size() == 3 and staff.get_hired_count() == 0, "Three permanent waiters must spawn without consuming paid slot")
	staff.apply_permanent_upgrades(3, true)
	check(staff.waiters.size() == 3, "Reapplying permanent staff must not duplicate them")
	for waiter in staff.waiters:
		check(waiter.carry_capacity == 2, "Carry upgrade applies to all permanent staff")
		check(is_equal_approx(waiter.speed, 117.0), "Three training levels grant thirty percent permanent speed")
	game.economy_manager.money = 1000
	game._on_buy_table_requested()
	game._on_hire_waiter_requested()
	game._on_staff_speed_upgrade_requested()
	for waiter in staff.waiters:
		check(is_equal_approx(waiter.speed, 136.5), "Permanent speed stacks with money upgrades for existing and newly hired staff")
	game._on_save_requested()
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	check(count_tables(game) == 5 and game.restaurant.waiter_manager.waiters.size() == 4, "Save reload must retain paid and permanent additions")
	for waiter in game.restaurant.waiter_manager.waiters:
		check(is_equal_approx(waiter.speed, 136.5), "Reload restores both speed bonuses")
	check(game.table_purchase_cost == 75, "Only paid tables increase purchase price after reload")
	game.michelin_manager.toggle_selection("cook_speed_1")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(count_tables(game) == 4 and game.restaurant.waiter_manager.waiters.size() == 3, "Later prestige must retain permanent additions and reset paid ones")
	check(is_equal_approx(game.restaurant.waiter_manager.waiters[0].speed, 117.0), "Prestige keeps training but resets money speed")
	for level in range(4, 12):
		game.michelin_manager.toggle_selection("permanent_table_%d" % level)
	for level in range(4, 7):
		game.michelin_manager.toggle_selection("permanent_waiter_%d" % level)
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(count_tables(game) == 12 and game.restaurant.waiter_manager.waiters.size() == 6, "Final levels must unlock all twelve tables and six permanent waiters")
	game._on_new_game_requested()
	await process_frame
	await process_frame
	game = current_scene
	check(count_tables(game) == 1 and game.restaurant.waiter_manager.waiters.is_empty(), "Explicit new game must still reset permanent progression")
	check(game.restaurant.waiter_manager.training_level == 0, "Explicit new game resets training")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("PERMANENT TREE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
