extends SceneTree

var fixture_path: String = "res://tests/permanent-waiter-%s.tscn" % Time.get_ticks_usec()
var save_path: String = fixture_path + ".json"
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_tests() -> void:
	var fixture: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n[node name="Main" instance=ExtResource("1")]\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var game: Node = load(fixture_path).instantiate()
	root.add_child(game)
	current_scene = game
	game.michelin_manager.stars = 30
	game._on_star_upgrades_requested()
	var panel: Node = game.michelin_upgrades
	check(panel.upgrade_buttons["waiter_capacity_2"].disabled, "Capacity upgrade must require permanent waiter")
	panel.upgrade_buttons["permanent_waiter"].pressed.emit()
	check(game.restaurant.waiter_manager.waiters.is_empty(), "Selecting must not create staff or spend stars")
	check(not panel.upgrade_buttons["waiter_capacity_2"].disabled, "Pending prerequisite must allow buying both together")
	panel.upgrade_buttons["waiter_capacity_2"].pressed.emit()
	check(game.michelin_manager.get_selected_cost() == 13, "Both upgrades must be included in the batch preview")
	panel.upgrade_buttons["permanent_waiter"].pressed.emit()
	check(game.michelin_manager.selected_upgrades.is_empty(), "Removing prerequisite must remove capacity selection too")
	panel.upgrade_buttons["permanent_waiter"].pressed.emit()
	panel.purchase_button.pressed.emit()
	panel.confirm_button.pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	var manager: Node = game.restaurant.waiter_manager
	check(game.michelin_manager.stars == 25 and manager.waiters.size() == 1, "First prestige must grant exactly one permanent waiter")
	check(manager.waiters[0].is_permanent and manager.waiters[0].carry_capacity == 1, "Permanent waiter initially carries one dish")
	check(manager.get_hired_count() == 0 and manager.can_hire(), "Permanent staff must leave paid slot free")
	check(manager.waiters[0].speed == 90.0, "Permanent waiter starts at half the former speed")
	game._on_staff_speed_upgrade_requested()
	check(manager.speed_level == 0, "Unaffordable staff upgrade cannot apply")
	game.economy_manager.money = 25
	var player_speed: float = game.restaurant.player_waiter.speed
	game.hud.get_node("UpgradesPanel/VBoxContainer/StaffSpeedButton").pressed.emit()
	check(manager.speed_level == 1 and manager.waiters[0].speed == 105.0, "Staff upgrade must accelerate existing permanent waiter")
	check(game.economy_manager.money == 0 and manager.get_speed_upgrade_cost() == 37.5, "Staff upgrade must charge once and increase next price")
	check(game.restaurant.player_waiter.speed == player_speed, "Staff upgrade must not change player speed")
	game.economy_manager.money = 100
	game._on_hire_waiter_requested()
	check(manager.waiters.size() == 2 and manager.get_hired_count() == 1, "Permanent and paid waiter must coexist")
	check(manager.waiters[1].speed == 105.0, "New hires inherit staff speed level")
	check(game._on_save_requested(), "Mixed staff must save")
	check(game.save_manager.load_game()["hired_waiters"] == 1, "Save must only count paid staff in hired_waiters")
	check(reload_current_scene() == OK, "Mixed staff save must reload")
	await process_frame
	await process_frame
	game = current_scene
	manager = game.restaurant.waiter_manager
	check(manager.waiters.size() == 2 and manager.get_hired_count() == 1, "Reload must not duplicate or lose staff")
	check(manager.speed_level == 1 and manager.waiters[0].speed == 105.0 and manager.waiters[1].speed == 105.0, "Save and reload must restore staff speed for both waiter types")
	game._on_star_upgrades_requested()
	panel = game.michelin_upgrades
	panel.upgrade_buttons["waiter_capacity_2"].pressed.emit()
	panel.purchase_button.pressed.emit()
	panel.confirm_button.pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	manager = game.restaurant.waiter_manager
	check(game.michelin_manager.stars == 17, "Second upgrade must charge eight stars")
	check(manager.waiters.size() == 1 and manager.get_hired_count() == 0, "Later prestige retains permanent staff but resets paid staff")
	check(manager.waiters[0].carry_capacity == 2, "Capacity applies to permanent waiter")
	check(manager.speed_level == 0 and manager.waiters[0].speed == 90.0, "Prestige resets money speed bonuses for permanent staff too")
	game.economy_manager.money = 10000
	for i in range(10):
		game._on_staff_speed_upgrade_requested()
	check(manager.speed_level == 10 and manager.waiters[0].speed == 240.0, "Ten upgrades reach the speed cap")
	var remaining_money: float = game.economy_manager.money
	game._on_staff_speed_upgrade_requested()
	check(game.economy_manager.money == remaining_money and manager.speed_level == 10, "Capped upgrades cannot charge again")
	game.economy_manager.money = 100
	game._on_hire_waiter_requested()
	check(manager.waiters[1].carry_capacity == 2, "New paid waiters inherit permanent capacity")
	game._on_save_requested()
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	for actor in game.restaurant.waiter_manager.waiters:
		check(actor.carry_capacity == 2, "Capacity survives save and reload for all waiters")
	game._on_new_game_requested()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.waiter_manager.waiters.is_empty(), "Explicit new game resets permanent upgrades and staff")
	check(game.restaurant.waiter_manager.carry_capacity == 1, "Explicit new game restores default staff capacity")
	check(game.restaurant.waiter_manager.speed_level == 0, "New game resets staff speed")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("PERMANENT WAITER TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
