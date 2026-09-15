extends SceneTree

const MAIN = preload("res://scenes/Main.tscn")
var save_path: String = "res://tests/hire-waiter-%s.json" % Time.get_ticks_usec()
var failures: int = 0
var selected_id: int = -1

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func start_game() -> Node:
	var game: Node = MAIN.instantiate()
	game.get_node("SaveManager").save_path = save_path
	root.add_child(game)
	return game

func run_tests() -> void:
	var game: Node = start_game()
	await process_frame
	var hud: Node = game.hud
	var manager: Node = game.restaurant.waiter_manager
	check(hud.hire_waiter_button.disabled, "Hire button must disable without enough money")
	game._on_hire_waiter_requested()
	check(manager.get_hired_count() == 0 and game.economy_manager.money == 0, "Insufficient funds must not hire or spend")
	game.economy_manager.add_money(100.0)
	check(not hud.hire_waiter_button.disabled, "Hire button must enable at the exact price")
	hud.hire_waiter_button.pressed.emit()
	check(manager.get_hired_count() == 1 and game.economy_manager.money == 0, "Hiring must create one waiter and charge exactly once")
	game.economy_manager.add_money(200.0)
	game._on_hire_waiter_requested()
	check(manager.get_hired_count() == 1 and game.economy_manager.money == 200.0, "Initial one-waiter limit must prevent duplicate purchases")
	check(hud.hire_waiter_button.disabled, "Hire button must disable at the limit")
	game._on_waiter_speed_upgrade_requested()
	check(manager.waiters[0].speed == 180.0, "Player speed upgrades must not change hired staff")
	game.pause_menu.open_menu()
	check(not manager.waiters[0].can_process(), "Pause menu must also pause automatic waiters")
	game.pause_menu.save_button.pressed.emit()
	var saved: Dictionary = game.save_manager.load_game()
	check(saved.get("hired_waiters") == 1, "Save must record the hired waiter")
	game.pause_menu.close_menu()
	game.free()
	game = start_game()
	await process_frame
	check(game.restaurant.waiter_manager.get_hired_count() == 1, "Loading must restore the hired waiter")
	check(game.economy_manager.money == saved["money"], "Loading must not charge again")
	check(game.hud.hire_waiter_button.disabled, "Loaded hire must update the button")
	# A legacy save without the new optional field must still load normally.
	saved.erase("hired_waiters")
	check(game.save_manager.save_game(saved), "Legacy save format must remain accepted")
	game.free()
	game = start_game()
	await process_frame
	check(game.restaurant.waiter_manager.get_hired_count() == 0, "Legacy save must start with no hired staff")
	check(game.economy_manager.money == saved["money"], "Legacy save must preserve existing progression")
	# Automatic pickup can replace a ready dish with the same type but a different ID.
	hud = game.hud
	var ids: Array[int] = [10]
	hud.set_ready_dishes_buttons([DishTypes.Type.BURGER], ids)
	await process_frame
	ids = [11]
	hud.set_ready_dishes_buttons([DishTypes.Type.BURGER], ids)
	await process_frame
	hud.ready_dish_selected.connect(func(id: int): selected_id = id)
	hud.ready_dishes_container.get_child(0).pressed.emit()
	check(selected_id == 11, "Kitchen panel must refresh IDs even when dish types stay the same")
	game.save_manager.delete_save()
	game.free()
	print("HIRE WAITER TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
