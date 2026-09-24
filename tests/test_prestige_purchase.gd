extends SceneTree

var fixture_path: String = "res://tests/prestige-%s.tscn" % Time.get_ticks_usec()
var save_path: String = fixture_path + ".json"
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_tests() -> void:
	root.size = Vector2i(1152, 648)
	var fixture: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n\n[node name="Main" instance=ExtResource("1")]\n\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var saver: Node = load("res://scripts/SaveManager.gd").new()
	saver.save_path = save_path
	check(saver.save_game({
		"money": 500.0, "hired_waiters": 1,
		"menu_dishes": ["PIZZA"],
		"michelin": {"stars": 20, "bought_upgrades": ["counter_capacity_1", "permanent_vip"]},
		"levels": {"waiter_speed": 2, "plate_price": 3, "cook_speed": 1, "eating_speed": 2, "patience": 2},
		"unlocked_tables": ["Table01Point", "Table02Point"]
	}), "Fixture must save a progressed run")
	saver.free()
	var scene: PackedScene = load(fixture_path)
	var game: Node = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var manager: Node = game.michelin_manager
	check(game.restaurant.menu_dishes == [DishTypes.Type.PIZZA], "Saved menu must load before spawning customers")
	var panel: Node = game.michelin_upgrades
	var original_file: String = FileAccess.get_file_as_string(save_path)
	game._on_star_upgrades_requested()
	check(panel.purchase_button.disabled, "Cannot buy an empty selection")
	check(panel.upgrade_buttons["counter_capacity_1"].disabled, "Previously bought improvements remain owned")
	check(panel.upgrade_buttons["vip_group_2"].disabled, "Unmet requirements must be locked")
	panel.upgrade_buttons["vip_spawn_1"].pressed.emit()
	check(manager.stars == 20 and not manager.is_upgrade_bought("vip_spawn_1"), "Clicking an upgrade must only select it")
	check(panel.upgrade_buttons["vip_spawn_1"].button_pressed, "Selected improvement must be visibly marked")
	check(not panel.upgrade_buttons["vip_group_2"].disabled, "Selected prerequisite must unlock its dependent for the same batch")
	panel.upgrade_buttons["vip_group_2"].pressed.emit()
	panel.upgrade_buttons["vip_spawn_1"].pressed.emit()
	check(manager.selected_upgrades.is_empty(), "Deselecting a prerequisite must also deselect dependents")
	for id in ["vip_spawn_1", "vip_group_2", "counter_capacity_2", "cook_speed_1", "player_capacity_2"]:
		panel.upgrade_buttons[id].pressed.emit()
	check(manager.get_selected_cost() == 15, "Batch cost must equal all selected upgrades")
	check(game.economy_manager.money == 500 and game.restaurant.waiter_manager.get_hired_count() == 1, "Selection must not reset the run")
	check(game.restaurant.player_waiter.carry_capacity == 1, "Selection must not apply player capacity early")
	check(game.restaurant.max_vip_group_size == 1, "Selection must not apply bonuses early")
	check(FileAccess.get_file_as_string(save_path) == original_file, "Selection must not change the save file")
	panel.close_button.pressed.emit()
	game._on_star_upgrades_requested()
	check(manager.selected_upgrades.size() == 5, "Closing and reopening must preserve the pending selection")
	manager.stars = 1
	game._on_stars_changed(1)
	check(panel.purchase_button.disabled and manager.get_selected_purchase_data().is_empty(), "Unaffordable batch must be rejected as a whole")
	panel.purchase_button.pressed.emit()
	check(not panel.purchase_confirmation.visible, "Unaffordable batch must not proceed to confirmation")
	manager.stars = 20
	game._on_stars_changed(20)
	panel.purchase_button.pressed.emit()
	check(panel.purchase_confirmation.visible, "Buy button must ask for final confirmation")
	check(manager.stars == 20 and game.economy_manager.money == 500, "Opening confirmation must not spend or reset")
	panel.cancel_button.pressed.emit()
	check(not panel.purchase_confirmation.visible and manager.selected_upgrades.size() == 5, "Cancel must preserve the selection without purchasing")
	check(FileAccess.get_file_as_string(save_path) == original_file, "Cancelling must leave the saved game unchanged")
	panel.purchase_button.pressed.emit()
	game.save_manager.save_path = "res://tests/missing-directory/prestige.json"
	panel.confirm_button.pressed.emit()
	await process_frame
	check(current_scene == game and manager.stars == 20, "Failed save must neither reset nor spend stars")
	check(game.restaurant.waiter_manager.get_hired_count() == 1, "Failed save must preserve ordinary progression")
	check(panel.purchase_status.text.contains("No se pudo guardar"), "Failed save must be explained")
	check(FileAccess.get_file_as_string(save_path) == original_file, "Failed batch must preserve previous save")
	game.save_manager.save_path = save_path
	panel.confirm_button.pressed.emit()
	game._on_star_purchase_confirmed() # Rapid second press must not charge twice.
	await process_frame
	await process_frame
	game = current_scene
	manager = game.michelin_manager
	check(game.restaurant.menu_dishes == [DishTypes.Type.PIZZA], "Prestige must preserve the chosen menu")
	check(manager.stars == 5, "Batch must charge exactly once and retain unspent stars")
	check(manager.bought_upgrades.size() == 7, "Two existing permanent upgrades and five new purchases must survive")
	check(manager.selected_upgrades.is_empty(), "Purchased selection must clear after restarting")
	check(game.economy_manager.money == 0, "Prestige must reset money")
	check(game.restaurant.waiter_manager.get_hired_count() == 0, "Prestige must remove hired staff")
	check(not game.restaurant.get_node("Table02Point").unlocked, "Prestige must reset additional tables")
	check(game.restaurant.waiter_speed_level == 0 and game.restaurant.plate_price_level == 0, "Prestige must reset service and price levels")
	check(game.restaurant.cook_speed_level == 0 and game.restaurant.eating_speed_level == 0 and game.restaurant.patience_level == 0, "Prestige must reset remaining money upgrades")
	check(game.waiter_speed_upgrade_cost == 10 and game.table_purchase_cost == 50, "Purchase prices must return to their defaults")
	check(game.restaurant.get_counter_capacity() == 7, "Old and new permanent capacity upgrades must both apply")
	check(is_equal_approx(game.restaurant.kitchen_point.cook_time, 4.8), "Permanent cook upgrade must apply without the old money bonus")
	check(game.restaurant.max_vip_group_size == 2 and is_equal_approx(game.restaurant.vip_spawn_chance, 0.06), "Permanent VIP unlock enables purchased frequency bonus after prestige")
	var persisted: Dictionary = game.save_manager.load_game()
	check(persisted["money"] == 0 and persisted["michelin"]["stars"] == 5 and persisted["hired_waiters"] == 0, "Restarted run must be persisted immediately")
	check(reload_current_scene() == OK, "Persisted prestige run must reload")
	await process_frame
	await process_frame
	game = current_scene
	check(game.michelin_manager.stars == 5 and game.restaurant.get_counter_capacity() == 7, "Later reload must retain permanent effects without another charge")
	check(game.restaurant.player_waiter.carry_capacity == 2, "Purchased player capacity must survive prestige and reload")
	check(game.economy_manager.money == 0, "Later reload must not resurrect the old run")
	check(game.restaurant.menu_dishes == [DishTypes.Type.PIZZA], "Menu must persist across later reloads")
	game.save_manager.delete_save()
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))

	# Boundary probabilities verify spawn uses the configured chance, not test mode.
	var restaurant: Node = load("res://scenes/restaurant/Restaurant.tscn").instantiate()
	root.add_child(restaurant)
	check(restaurant.vip_spawn_chance == 0.0, "VIPs must start locked")
	restaurant.set_vip_unlocked(true)
	check(is_equal_approx(restaurant.vip_spawn_chance, 0.05), "Unlocked VIP rate must be five percent")
	restaurant.vip_spawn_chance = 0.0
	restaurant.spawn_customer()
	var newest_group: Node = restaurant.get_child(restaurant.get_child_count() - 1)
	check(not newest_group.is_vip_group, "Zero VIP probability must produce regular customers")
	restaurant.vip_spawn_chance = 1.0
	restaurant.spawn_customer()
	newest_group = restaurant.get_child(restaurant.get_child_count() - 1)
	check(newest_group.is_vip_group, "Full VIP probability must still support VIPs")
	restaurant.free()
	print("PRESTIGE PURCHASE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
