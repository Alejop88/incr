extends "res://tests/test_dish_unlocks.gd"

func run_tests() -> void:
	var fixture: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n[node name="Main" instance=ExtResource("1")]\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var game: Node = load(fixture_path).instantiate()
	root.add_child(game)
	current_scene = game
	var hud: Node = game.hud
	for button in [hud.waiter_speed_button, hud.plate_price_button, hud.cook_speed_button, hud.eating_speed_button, hud.patience_button]:
		check(button.disabled, "Upgrades must start disabled without money")
	game.economy_manager.add_money(20)
	check(not hud.waiter_speed_button.disabled and not hud.cook_speed_button.disabled, "Reaching the exact price must enable upgrades")
	game._on_waiter_speed_upgrade_requested()
	check(hud.waiter_speed_button.disabled and hud.cook_speed_button.disabled, "Spending money must update all buttons and the next upgrade cost")
	check(not hud.plate_price_button.disabled, "Affordable remaining upgrade stays enabled")
	hud.set_patience_upgrade(10, 20, 10)
	game.economy_manager.add_money(1000)
	check(hud.patience_button.disabled, "Money changes cannot enable a maxed upgrade")
	game.get_node("RestaurantCamera").restore_zoom(0.55)
	game.get_node("RestaurantCamera").position = Vector2(-120, 1450)
	check(game._on_save_requested(), "Custom zoom must save")
	game.get_node("RestaurantCamera").restore_zoom(1.2)
	game.get_node("RestaurantCamera").position = Vector2(900, 300)
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	check(is_equal_approx(game.get_node("RestaurantCamera").zoom.x, 0.55), "Reload restores saved zoom rather than unsaved changes")
	check(game.get_node("RestaurantCamera").position == Vector2(-120, 1450), "Reload restores saved camera position including negative coordinates")
	game.michelin_manager.toggle_selection("player_capacity_2")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(is_equal_approx(game.get_node("RestaurantCamera").zoom.x, 0.55), "Prestige preserves the current zoom")
	check(game.get_node("RestaurantCamera").position == Vector2(-120, 1450), "Prestige preserves camera position")
	check(game.hud.waiter_speed_button.disabled, "Reset money must disable upgrades again")
	game.save_manager.delete_save()
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("ZOOM AND AFFORDABILITY TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
