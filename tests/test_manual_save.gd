extends SceneTree

const MAIN_SCENE = preload("res://scenes/Main.tscn")
var test_path: String = "res://tests/manual-save-%s.json" % Time.get_ticks_usec()
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func start_game() -> Node:
	var game: Node = MAIN_SCENE.instantiate()
	game.get_node("SaveManager").save_path = test_path
	root.add_child(game)
	return game

func press_escape() -> void:
	var event := InputEventKey.new()
	event.keycode = KEY_ESCAPE
	event.pressed = true
	Input.parse_input_event(event)

func run_tests() -> void:
	var game: Node = start_game()
	await process_frame
	var menu: Node = game.get_node("PauseMenu")
	var saver: Node = game.get_node("SaveManager")
	check(not FileAccess.file_exists(test_path), "Starting a game must not save automatically")
	press_escape()
	await process_frame
	check(paused and menu.overlay.visible, "Escape must open the pause menu")
	check(not game.get_node("Restaurant").can_process(), "Restaurant must pause")
	var timer: Timer = game.get_node("Restaurant/CustomerSpawnTimer")
	var remaining: float = timer.time_left
	await create_timer(0.05).timeout
	check(is_equal_approx(timer.time_left, remaining), "Spawn timer must remain paused")
	press_escape()
	await process_frame
	check(not paused and not menu.overlay.visible, "Escape must resume the game")

	game.get_node("EconomyManager").add_money(1000.0)
	game._on_waiter_speed_upgrade_requested()
	game._on_waiter_speed_upgrade_requested()
	game._on_plate_price_upgrade_requested()
	game._on_cook_speed_upgrade_requested()
	game._on_eating_speed_upgrade_requested()
	game._on_patience_upgrade_requested()
	game._on_buy_table_requested()
	game.get_node("MichelinManager").add_stars(100)
	for upgrade in ["counter_capacity_1", "counter_capacity_2", "cook_speed_1", "vip_spawn_1", "vip_spawn_2", "vip_group_2", "vip_group_3", "vip_group_4"]:
		game.michelin_manager.buy_upgrade(upgrade)
	# Seed existing permanent progression; UI purchase/reset has its own test.
	game.restaurant.set_permanent_cook_speed_bonus(game.michelin_manager.cook_speed_bonus)
	game.restaurant.set_vip_spawn_bonus_level(game.michelin_manager.vip_spawn_bonus)
	game.restaurant.set_max_vip_group_size(game.michelin_manager.max_vip_group_size)
	menu.open_menu()
	menu.save_button.pressed.emit()
	check(menu.status_label.text == "Partida guardada correctamente.", "Save button must report success")
	check(FileAccess.file_exists(test_path), "Save button must create the file")
	game.get_node("EconomyManager").add_money(7.0)
	menu.save_button.pressed.emit()
	var expected: Dictionary = saver.load_game()
	check(not expected.is_empty(), "Repeated save must replace the file successfully")
	check(expected.get("money") == game.get_node("EconomyManager").money, "Repeated save must contain the latest balance")
	check(not saver.save_game({}), "Invalid data must not overwrite the save")
	check(saver.load_game() == expected, "Rejected save must preserve previous data")
	game.get_node("EconomyManager").add_money(99.0)
	menu.close_menu()
	game.free()

	game = start_game()
	await process_frame
	menu = game.get_node("PauseMenu")
	saver = game.get_node("SaveManager")
	var restaurant: Node = game.get_node("Restaurant")
	check(game.get_node("EconomyManager").money == expected.get("money"), "Only manually saved money must load")
	check(game.get_node("MichelinManager").get_stars() == expected["michelin"]["stars"], "Stars must load without charging upgrades again")
	check(restaurant.max_vip_group_size == 4, "VIP group upgrade must be restored")
	check(restaurant.vip_spawn_chance == 0.0, "Restored VIP chance bonuses must respect the unlock gate")
	restaurant.set_vip_unlocked(true)
	check(is_equal_approx(restaurant.vip_spawn_chance, 0.07), "VIP spawn bonuses must be restored when enabled")
	check(restaurant.get_counter_capacity() == 7, "Counter bonuses must be restored")
	check(restaurant.player_waiter.speed == 270.0, "Waiter speed must be restored")
	check(is_equal_approx(restaurant.kitchen_point.cook_time, 4.6), "Cooking must combine ordinary and permanent upgrades")
	check(restaurant.plate_price == 6.0, "Plate price must be restored")
	check(restaurant.get_node("Table02Point").unlocked, "Purchased table must be restored")
	check(is_equal_approx(restaurant.get_node("Table02Point").food_wait_time, 22.0), "Patience must be restored")
	check(is_equal_approx(restaurant.get_node("Table02Point").eating_time, 4.8), "Eating speed must be restored")
	check(game.waiter_speed_upgrade_cost == 22.5 and game.table_purchase_cost == 75.0, "Purchase prices must be restored")
	game._on_star_upgrades_requested()
	check(game.get_node("CanvasLayer/MichelinUpgrades").upgrade_buttons["vip_group_4"].disabled, "Restored purchased upgrade must be disabled")
	menu.open_menu()
	menu.save_button.pressed.emit()
	check(saver.load_game() == expected, "Loading then saving must preserve progression")
	menu.close_menu()
	check(not paused, "Continue button must resume")

	var valid_path: String = saver.save_path
	saver.save_path = "res://tests/missing-directory/partida.json"
	menu.open_menu()
	menu.save_button.pressed.emit()
	check(menu.status_label.text != "Partida guardada correctamente.", "Write failure must be visible")
	saver.save_path = valid_path
	menu.close_menu()
	game.free()

	var file: FileAccess = FileAccess.open(test_path, FileAccess.WRITE)
	file.store_string("{ invalid json")
	file.close()
	game = start_game()
	await process_frame
	menu = game.get_node("PauseMenu")
	check(paused and menu.overlay.visible, "Corrupt save must display an error in the menu")
	check(menu.status_label.text.contains("no es válido"), "Load error must be explained")
	check(game.get_node("EconomyManager").money == 0.0, "Corrupt save must not partially apply")
	menu.close_menu()
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	print("MANUAL SAVE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
