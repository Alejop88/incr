extends SceneTree

var fixture_path: String = "res://tests/new-game-%s.tscn" % Time.get_ticks_usec()
var save_path: String = fixture_path + ".json"
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_tests() -> void:
	# A separate scene and save path keep the real player's save untouched.
	var fixture: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n\n[node name="Main" instance=ExtResource("1")]\n\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var scene: PackedScene = load(fixture_path)
	var game: Node = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.get_node("EconomyManager").add_money(1000.0)
	game._on_waiter_speed_upgrade_requested()
	game._on_buy_table_requested()
	game.get_node("MichelinManager").add_stars(100)
	game._on_star_upgrade_requested("vip_spawn_1")
	game._on_star_upgrade_requested("vip_group_2")
	var menu: Node = game.get_node("PauseMenu")
	menu.open_menu()
	menu.save_button.pressed.emit()
	var original_save: String = FileAccess.get_file_as_string(save_path)
	menu.new_game_button.pressed.emit()
	check(menu.confirmation.visible and paused, "New game must first show a confirmation while paused")
	check(menu.cancel_button.has_focus(), "Cancel must be the initially focused choice")
	check(FileAccess.get_file_as_string(save_path) == original_save, "Opening confirmation must preserve the save")
	menu.cancel_button.pressed.emit()
	check(not menu.confirmation.visible and menu.overlay.visible and paused, "Cancel must return to pause menu")
	check(game.get_node("Restaurant").waiter_speed_level == 1, "Cancel must preserve current progress")
	menu.new_game_button.pressed.emit()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	check(not menu.confirmation.visible and paused, "Escape must cancel confirmation without resuming")
	check(FileAccess.get_file_as_string(save_path) == original_save, "Cancellation must preserve saved progress")
	menu.new_game_button.pressed.emit()
	menu.confirm_button.pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(is_instance_valid(game), "New game must reload the scene")
	check(not paused, "New game must resume gameplay")
	check(not FileAccess.file_exists(save_path), "New game must remove the old save")
	check(game.get_node("EconomyManager").money == 0.0, "Money must reset")
	check(game.get_node("MichelinManager").stars == 5, "Stars must return to the configured initial value")
	check(game.get_node("MichelinManager").bought_upgrades.is_empty(), "Permanent upgrades must reset")
	check(game.get_node("Restaurant").waiter_speed_level == 0, "Ordinary upgrades must reset")
	check(game.get_node("Restaurant").max_vip_group_size == 1, "VIP group size must reset")
	check(not game.get_node("Restaurant/Table02Point").unlocked, "Purchased tables must reset")
	check(game.table_purchase_cost == 50.0, "Upgrade prices must reset")
	menu = game.get_node("PauseMenu")
	menu.open_menu()
	menu.save_button.pressed.emit()
	check(FileAccess.file_exists(save_path), "The fresh game must still save normally")
	menu.close_menu()
	check(game.get_node("SaveManager").delete_save(), "Test save cleanup must succeed")
	check(game.get_node("SaveManager").delete_save(), "Starting over without an existing save must succeed")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("NEW GAME TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
