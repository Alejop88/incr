extends SceneTree

const MAIN_SCENE = preload("res://scenes/Main.tscn")
var test_path: String = "res://tests/quit-save-%s.json" % Time.get_ticks_usec()
var failures: int = 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_tests() -> void:
	var game: Node = MAIN_SCENE.instantiate()
	game.get_node("SaveManager").save_path = test_path
	root.add_child(game)
	await process_frame
	var menu: Node = game.get_node("PauseMenu")
	var saver: Node = game.get_node("SaveManager")
	game.get_node("EconomyManager").add_money(50.0)
	menu.open_menu()
	menu.save_button.pressed.emit()
	var saved_text: String = FileAccess.get_file_as_string(test_path)
	game.get_node("EconomyManager").add_money(25.0)
	menu.quit_button.pressed.emit()
	check(menu.quit_confirmation.visible and paused, "Exit must first ask whether to save")
	check(menu.cancel_quit_button.has_focus(), "Cancel must have initial focus")
	menu.cancel_quit_button.pressed.emit()
	check(not menu.quit_confirmation.visible and menu.overlay.visible and paused, "Cancel must keep game paused in menu")
	check(FileAccess.get_file_as_string(test_path) == saved_text, "Cancel must not save")
	menu.quit_button.pressed.emit()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	Input.parse_input_event(escape)
	await process_frame
	check(not menu.quit_confirmation.visible and paused, "Escape must cancel exit")
	menu.quit_button.pressed.emit()
	saver.save_path = "res://tests/missing-directory/quit.json"
	menu.save_quit_button.pressed.emit()
	# Reaching the next frame verifies a save failure did not quit the game.
	await process_frame
	check(menu.quit_confirmation.visible and paused, "Failed save must keep exit choices available")
	check(menu.status_label.text.contains("No se pudo guardar"), "Save failure must be visible")
	saver.save_path = test_path
	if "discard" in OS.get_cmdline_user_args():
		menu.discard_quit_button.pressed.emit()
		check(FileAccess.get_file_as_string(test_path) == saved_text, "Exit without saving must preserve last saved state")
	else:
		menu.save_quit_button.pressed.emit()
		check(saver.load_game().get("money") == 75.0, "Save and exit must write current progress")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	print("QUIT MENU TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	if failures != 0:
		quit(1)
