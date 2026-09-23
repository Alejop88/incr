extends "res://tests/test_dish_unlocks.gd"

func run_tests() -> void:
	var model = load("res://scripts/Gachapon.gd").new()
	check(model.catalog.size() == 100 and model.probabilities() == [70.0, 20.0, 8.0, 2.0], "Initial odds must reflect the catalog")
	model.owned.append("skin_0_000")
	check(is_equal_approx(model.probabilities()[3], 200.0 / 99.0), "Legendary odds must use the shrinking remaining pool")
	for i in range(99):
		check(not model.draw_item().is_empty(), "Each remaining draw must yield a unique item")
	check(model.owned.size() == 100 and model.draw_item().is_empty(), "Exhaustion must not repeat items")
	var fixture := FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n[node name="Main" instance=ExtResource("1")]\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var game: Node = load(fixture_path).instantiate()
	root.add_child(game)
	current_scene = game
	game.restaurant.get_node("GachaponMachine").opened.emit()
	check(game.gachapon_panel.visible and game.gachapon_panel.spin_button.disabled, "Machine opens panel with unaffordable button disabled")
	game._on_gachapon_spin()
	check(game.gachapon.owned.is_empty(), "No money means no reward")
	game.economy_manager.add_money(250)
	game.gachapon_panel.spin_button.pressed.emit()
	check(game.economy_manager.money == 150 and game.gachapon.owned.size() == 1, "A draw charges exactly one hundred and grants one item")
	var obtained: String = game.gachapon.owned[0]
	game._on_save_requested()
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	check(game.gachapon.owned.has(obtained) and game.economy_manager.money == 150, "Collection and money must survive save/load")
	game.michelin_manager.toggle_selection("counter_capacity_1")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(game.gachapon.owned.has(obtained), "Star prestige must retain cosmetics")
	game._on_new_game_requested()
	await process_frame
	await process_frame
	game = current_scene
	check(game.gachapon.owned.is_empty(), "Explicit new game clears the collection with other progress")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("GACHAPON TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
