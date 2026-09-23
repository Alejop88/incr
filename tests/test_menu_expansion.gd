extends "res://tests/test_dish_unlocks.gd"

func run_tests() -> void:
	var fixture: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n[node name="Main" instance=ExtResource("1")]\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var game: Node = load(fixture_path).instantiate()
	root.add_child(game)
	current_scene = game
	check(game.restaurant.customer_spawn_timer.wait_time == 20.0, "Base arrival interval must be twenty seconds")
	var original: Array = game.restaurant.unlocked_dishes.duplicate()
	game._on_star_upgrades_requested()
	game.michelin_upgrades.upgrade_buttons["menu_capacity_1"].pressed.emit()
	check(game.restaurant.menu_capacity == 2 and game.restaurant.unlocked_dishes.size() == 2, "Selection must not apply the upgrade or gift")
	game.michelin_upgrades.purchase_button.pressed.emit()
	game.michelin_upgrades.confirm_button.pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(game.michelin_manager.stars == 0 and game.restaurant.menu_capacity == 3, "Purchase must charge five stars and add one menu slot")
	check(game.restaurant.customer_spawn_timer.wait_time == 16.0, "Upgrade must increase arrival frequency by twenty-five percent")
	check(game.restaurant.unlocked_dishes.size() == 3, "Two-recipe player must receive one free random unlock")
	check(game.restaurant.menu_dishes.size() == 3, "Purchase must automatically fill all three menu slots")
	for dish in original:
		check(game.restaurant.unlocked_dishes.has(dish), "Gift must preserve existing recipes")
	game.hud.get_node("KitchenPanel/VBoxContainer/MenuButton").pressed.emit()
	var editor: Node = game.hud.menu_editor
	check(editor.menu_capacity == 3, "Menu editor must use the permanent capacity")
	check(editor.selected.size() == 3, "Editor must open with three recipes already selected")
	editor.apply_button.pressed.emit()
	check(game.restaurant.menu_dishes.size() == 3, "Third recipe must be selectable and applicable")
	game._on_save_requested()
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.menu_dishes.size() == 3 and game.restaurant.unlocked_dishes.size() == 3, "Reload must retain three selected recipes without another gift")
	check(game.restaurant.customer_spawn_timer.wait_time == 16.0, "Reload must retain arrival bonus")
	game.michelin_manager.stars = 5
	game.michelin_manager.toggle_selection("player_capacity_2")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.menu_capacity == 3 and game.restaurant.unlocked_dishes.size() == 3, "Later prestige retains bonus without duplicate gifts")
	game.michelin_manager.stars = 100
	for id in ["menu_capacity_2", "menu_capacity_3", "menu_capacity_4"]:
		game.michelin_manager.toggle_selection(id)
	check(game.restaurant.menu_capacity == 3, "Selecting levels must not apply them immediately")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.menu_capacity == 6 and game.restaurant.menu_dishes.size() == 6, "Batch purchase must fill the six-slot menu")
	check(game.restaurant.unlocked_dishes.size() == 6, "Missing recipes must be granted without duplicates")
	check(game.michelin_manager.stars == 55, "New levels cost ten, fifteen and twenty stars")
	check(game.restaurant.customer_spawn_timer.wait_time == 10.0, "Four levels double the base arrival frequency")
	game._on_save_requested()
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.menu_capacity == 6 and game.restaurant.menu_dishes.size() == 6, "Six-slot menu must survive save/load")
	game.restaurant.set_menu_capacity_bonus(99)
	check(game.restaurant.menu_capacity == 6, "Menu capacity must be capped at six")
	game._on_new_game_requested()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.menu_capacity == 2 and game.restaurant.customer_spawn_timer.wait_time == 20.0, "Explicit new game resets permanent capacity and arrival rate")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("MENU EXPANSION TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
