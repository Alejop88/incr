extends SceneTree
var base_path := "res://tests/slots-%s.json" % Time.get_ticks_usec()
var failures := 0
var slots: Node
func _initialize() -> void:
	call_deferred("run_tests")
func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)
func title() -> Node:
	var menu: Node = load("res://scenes/TitleMenu.tscn").instantiate()
	menu.get_node("SaveManager").save_path = base_path
	root.add_child(menu)
	current_scene = menu
	return menu
func run_tests() -> void:
	slots = root.get_node("SaveSlots")
	for index in range(3):
		var menu := title()
		menu.new_game_button.pressed.emit()
		check(menu.mode_panel.visible and not menu.slot_panel.visible and current_scene == menu, "New game must first show the mode screen")
		menu.mode_cancel_button.pressed.emit()
		check(menu.main_panel.visible and not menu.mode_panel.visible, "Cancel from modes must return to title")
		menu.new_game_button.pressed.emit()
		menu.mode_buttons["normal" if index == 1 else "cozy"].pressed.emit()
		check(menu.slot_panel.visible and not menu.mode_panel.visible, "Choosing a mode must advance to slots")
		menu.back_to_modes_button.pressed.emit()
		check(menu.mode_panel.visible and not menu.slot_panel.visible, "Changing mode returns to the mode screen")
		menu.mode_buttons["normal" if index == 1 else "cozy"].pressed.emit()
		menu.slot_cancel_button.pressed.emit()
		check(menu.main_panel.visible and not menu.slot_panel.visible and not FileAccess.file_exists(slots.slot_path(base_path, index)), "Cancelling before slot selection must not create a save")
		menu.new_game_button.pressed.emit()
		menu.mode_buttons["normal" if index == 1 else "cozy"].pressed.emit()
		menu.slot_buttons[index].pressed.emit()
		await process_frame
		await process_frame
		var game: Node = current_scene
		check(game.save_manager.save_path == slots.slot_path(base_path, index), "Save path must stay bound to chosen slot")
		check(game.game_mode == ("normal" if index == 1 else "cozy"), "Chosen mode must reach game")
		game.economy_manager.money = 100 + index
		game.play_time = 3661 + index
		game._on_save_requested()
		game.free()
	var menu := title()
	menu.continue_button.pressed.emit()
	check(menu.slot_buttons.size() == 3 and menu.slot_buttons[1].text.contains("Normal") and menu.slot_buttons[1].text.contains("01:01:02"), "Slot summary must include mode and played time")
	menu.slot_buttons[1].pressed.emit()
	await process_frame
	await process_frame
	var game: Node = current_scene
	check(game.game_mode == "normal" and game.economy_manager.money == 101 and game.play_time >= 3662, "Loading must restore chosen slot metadata")
	game.pause_menu.open_menu()
	var paused_time: float = game.play_time
	await process_frame
	await process_frame
	check(game.play_time == paused_time, "Paused game must not accumulate play time")
	game.pause_menu.close_menu()
	game.michelin_manager.toggle_selection("counter_capacity_1")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(game.game_mode == "normal" and game.play_time >= paused_time and game.save_manager.save_path == slots.slot_path(base_path, 1), "Prestige must retain slot mode and played time")
	game.free()
	menu = title()
	menu.new_game_button.pressed.emit()
	menu.mode_buttons.cozy.pressed.emit()
	menu.slot_buttons[1].pressed.emit()
	check(menu.confirmation.visible, "Occupied slot must ask before replacement")
	menu.confirmation.hide()
	menu.confirmation.canceled.emit()
	check(menu._slot_data(1).game_mode == "normal", "Cancel must preserve the occupied slot")
	menu.slot_buttons[1].pressed.emit()
	menu.confirmation.confirmed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(game.game_mode == "cozy" and game.economy_manager.money == 0 and game.play_time < 10, "Replacement must reset only the chosen slot")
	game.free()
	menu = title()
	check(menu._slot_data(0).money == 100 and menu._slot_data(2).money == 102, "Other slots must remain untouched")
	menu.free()
	for index in range(3):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slots.slot_path(base_path, index)))
	slots.active_path = "user://partida.json"
	print("SAVE SLOT TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
