extends SceneTree

var failures := 0
var save_path := "res://tests/pause-title-%s.json" % Time.get_ticks_usec()

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run_tests() -> void:
	for save_first in [false, true]:
		var game: Node = load("res://scenes/Main.tscn").instantiate()
		game.get_node("SaveManager").save_path = save_path
		root.add_child(game)
		current_scene = game
		await process_frame
		game.economy_manager.money = 50
		game._on_save_requested()
		game.economy_manager.money = 75
		var menu: Node = game.pause_menu
		menu.open_menu()
		check(not menu.has_node("Overlay/Center/Panel/Margin/Buttons/NewGameButton") and not menu.has_node("Overlay/Center/Panel/Margin/Buttons/ResumeButton"), "Pause must not contain title-screen actions")
		menu.settings_button.pressed.emit()
		check(menu.settings_panel.visible and paused, "Settings must open while paused")
		var escape := InputEventKey.new()
		escape.keycode = KEY_ESCAPE
		escape.pressed = true
		Input.parse_input_event(escape)
		await process_frame
		check(not menu.settings_panel.visible and menu.overlay.visible and paused, "Escape from settings returns to pause, not gameplay")
		menu.title_button.pressed.emit()
		check(menu.quit_confirmation.visible and menu.returning_to_title, "Title button must offer save choices")
		menu.cancel_quit_button.pressed.emit()
		check(paused and not menu.quit_confirmation.visible, "Cancel must keep the restaurant paused")
		menu.title_button.pressed.emit()
		game.save_manager.save_path = "res://tests/missing-directory/pause.json"
		menu.save_quit_button.pressed.emit()
		check(current_scene == game and paused, "Save failure must prevent leaving")
		game.save_manager.save_path = save_path
		if save_first:
			menu.save_quit_button.pressed.emit()
		else:
			menu.discard_quit_button.pressed.emit()
		await process_frame
		await process_frame
		check(current_scene.scene_file_path == "res://scenes/TitleMenu.tscn" and not paused, "Returning to title must change scene and clear pause")
		var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
		check(data.money == (75 if save_first else 50), "Return must respect save or discard choice")
		current_scene.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	print("PAUSE TITLE TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
