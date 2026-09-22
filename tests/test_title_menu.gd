extends "res://tests/test_dish_unlocks.gd"

func make_title() -> Node:
	var menu: Node = load("res://scenes/TitleMenu.tscn").instantiate()
	menu.game_scene_path = fixture_path
	menu.get_node("SaveManager").save_path = save_path
	root.add_child(menu)
	current_scene = menu
	return menu

func run_tests() -> void:
	var fixture: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n[node name="Main" instance=ExtResource("1")]\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var menu: Node = make_title()
	check(menu.continue_button.disabled, "No save must disable Continue")
	check(not menu.has_node("Restaurant"), "Title screen must not run a restaurant in the background")
	menu._continue_game()
	check(current_scene == menu, "Disabled Continue must not start a game")
	var corrupt: FileAccess = FileAccess.open(save_path, FileAccess.WRITE)
	corrupt.store_string("not a save")
	corrupt.close()
	menu.refresh_save_status()
	check(menu.continue_button.disabled and not menu.status_label.text.is_empty(), "Invalid saves must disable Continue and explain the problem")
	menu.save_manager.delete_save()
	menu.new_game_button.pressed.emit()
	await process_frame
	await process_frame
	var game: Node = current_scene
	check(game.has_node("Restaurant") and game.economy_manager.money == 0, "New game without save must start fresh")
	game.economy_manager.money = 123
	game.get_node("RestaurantCamera").restore_zoom(0.55)
	game.get_node("RestaurantCamera").position = Vector2(850, 1500)
	check(game._on_save_requested(), "Fixture game must save")
	game.free()
	menu = make_title()
	check(not menu.continue_button.disabled, "Valid save must enable Continue")
	menu.continue_button.pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(game.economy_manager.money == 123 and game.get_node("RestaurantCamera").position == Vector2(850, 1500), "Continue must restore progress and camera")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	game.pause_menu._input(escape)
	check(paused and game.pause_menu.overlay.visible, "Escape pause menu must remain functional")
	game.pause_menu.close_menu()
	game.free()
	menu = make_title()
	var original_save: String = FileAccess.get_file_as_string(save_path)
	menu.new_game_button.pressed.emit()
	check(menu.confirmation.visible, "New game must confirm before replacing an existing save")
	menu.confirmation.hide()
	menu.confirmation.canceled.emit()
	check(FileAccess.get_file_as_string(save_path) == original_save, "Cancel preserves the save")
	menu.new_game_button.pressed.emit()
	menu.confirmation.confirmed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(game.economy_manager.money == 0 and not FileAccess.file_exists(save_path), "Confirmed new game must reset progression")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("TITLE MENU TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
