extends SceneTree

var failures: int = 0
var fixture_path: String = "res://tests/dish-unlocks-%s.tscn" % Time.get_ticks_usec()
var save_path: String = fixture_path + ".json"

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_tests() -> void:
	var seen: Dictionary = {}
	for i in range(100):
		var initial: Array = DishTypes.random_starting_dishes()
		check(initial.size() == mini(2, DishTypes.CATALOG.size()) and initial[0] != initial[1], "Starting dishes must be distinct")
		for dish in initial:
			seen[dish] = true
	check(seen.size() == DishTypes.CATALOG.size(), "Starting draw must include the whole catalogue")
	var fixture: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n[node name="Main" instance=ExtResource("1")]\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var game: Node = load(fixture_path).instantiate()
	root.add_child(game)
	current_scene = game
	var r: Node = game.restaurant
	check(r.unlocked_dishes.size() == 2 and r.menu_dishes == r.unlocked_dishes, "New game starts with two unlocked dishes on the menu")
	var original_menu: Array = r.menu_dishes.duplicate()
	game.hud.get_node("KitchenPanel/VBoxContainer/MenuButton").pressed.emit()
	var editor: Node = game.hud.menu_editor
	check(editor.purchase_button.disabled, "Buying is disabled without money")
	game._on_dish_purchase_requested()
	check(r.unlocked_dishes.size() == 2, "Unaffordable purchase must not unlock a dish")
	var locked: Array = r.get_locked_dishes()
	check(not r.set_menu_dishes([locked[0]]), "Locked recipes cannot enter the menu")
	check(not editor.dish_buttons[locked[0]].visible, "Locked recipes must not appear as menu choices")
	game.economy_manager.money = 500
	game._refresh_dish_shop()
	editor.purchase_button.pressed.emit()
	check(r.unlocked_dishes.size() == 3 and game.economy_manager.money == 450, "Purchase charges fifty and unlocks exactly one new dish")
	var new_dish: int = r.unlocked_dishes.back()
	check(locked.has(new_dish) and editor.dish_buttons[new_dish].visible, "Reward must come from locked recipes and appear immediately")
	check(r.menu_dishes == original_menu and editor.selected == original_menu, "Unlocking must not replace or expand the active menu")
	editor._toggle_dish(original_menu[0])
	editor._toggle_dish(new_dish)
	editor.apply_button.pressed.emit()
	check(r.menu_dishes.has(new_dish) and r.menu_dishes.size() == 2, "Purchased dish can replace a selected recipe")
	while not r.get_locked_dishes().is_empty():
		game._on_dish_purchase_requested()
	var balance: float = game.economy_manager.money
	game._on_dish_purchase_requested()
	check(game.economy_manager.money == balance and editor.purchase_button.disabled, "Complete catalogue must not charge again")
	check(r.unlocked_dishes.size() == DishTypes.CATALOG.size(), "Unlocks cannot repeat")
	var chosen: Array = r.menu_dishes.duplicate()
	check(game._on_save_requested(), "Unlocks must save")
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.unlocked_dishes.size() == DishTypes.CATALOG.size() and game.restaurant.menu_dishes == chosen, "Reload preserves all unlocks and menu")
	game.michelin_manager.stars = 5
	game.michelin_manager.toggle_selection("player_capacity_2")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.unlocked_dishes.size() == DishTypes.CATALOG.size() and game.restaurant.menu_dishes == chosen, "Prestige retains unlocked recipes and chosen menu")
	check(game.economy_manager.money == 0, "Preserving recipes must not preserve run money")
	game._on_new_game_requested()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.unlocked_dishes.size() == 2 and game.restaurant.menu_dishes == game.restaurant.unlocked_dishes, "Explicit new game resets to two drawn recipes")
	game.restaurant.restore_dish_progress({"menu_dishes": ["SALAD", "TACO"]})
	check(game.restaurant.menu_dishes == [DishTypes.Type.SALAD, DishTypes.Type.TACO], "Legacy save must preserve its selected recipes")
	check(game.restaurant.unlocked_dishes == game.restaurant.menu_dishes, "Legacy selected recipes become unlocked")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("DISH UNLOCK TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
