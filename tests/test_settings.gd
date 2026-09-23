extends SceneTree

var failures: int = 0
var settings_path: String = "res://tests/settings-%s.cfg" % Time.get_ticks_usec()

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_tests() -> void:
	root.size = Vector2i(1920, 1080)
	var settings: Node = load("res://scripts/GameSettings.gd").new()
	settings.settings_path = settings_path
	root.add_child(settings)
	check(settings.display_mode == 1, "Default display remains fullscreen")
	var title: Node = load("res://scenes/TitleMenu.tscn").instantiate()
	title.get_node("SaveManager").save_path = settings_path + ".no-save"
	root.add_child(title)
	var panel: Node = title.settings_panel
	panel.settings = settings
	title.settings_button.pressed.emit()
	check(panel.visible and panel.tabs.get_tab_count() == 5, "Gear must open five settings sections")
	check(panel.resolution_option.disabled, "Fullscreen must use monitor resolution")
	check(panel.resolutions[panel.resolution_option.selected] == panel.monitor_resolution(), "Fullscreen must display actual monitor resolution")
	check(not panel.resolutions.has(Vector2i(2560, 1440)) and not panel.resolutions.has(Vector2i(3840, 2160)), "1080p monitor must hide larger resolutions")
	var small: Array[Vector2i] = panel.resolutions_for_monitor(Vector2i(1366, 768), Vector2i(3840, 2160))
	check(small.has(Vector2i(1366, 768)) and small.has(Vector2i(1280, 720)), "Nonstandard monitor maximum must be included")
	for size in small:
		check(size.x <= 1366 and size.y <= 768, "Every option must fit both monitor dimensions")
	panel.mode_option.select(0)
	panel.mode_option.item_selected.emit(0)
	check(not panel.resolution_option.disabled, "Window mode enables resolution choice")
	panel.resolution_option.select(panel.resolutions.find(Vector2i(1600, 900)))
	panel.apply_button.pressed.emit()
	check(settings.display_mode == 0 and settings.resolution == Vector2i(1600, 900), "Apply updates window mode and size")
	check(FileAccess.file_exists(settings_path), "Apply persists settings separately")
	var restored: Node = load("res://scripts/GameSettings.gd").new()
	restored.settings_path = settings_path
	root.add_child(restored)
	check(restored.display_mode == 0 and restored.resolution == Vector2i(1600, 900), "Restart restores display settings")
	panel.mode_option.select(1)
	panel.mode_option.item_selected.emit(1)
	check(panel.resolutions[panel.resolution_option.selected] == panel.monitor_resolution(), "Changing to fullscreen updates displayed resolution")
	panel.apply_button.pressed.emit()
	check(settings.resolution == Vector2i(1600, 900), "Applying fullscreen must preserve the preferred window size")
	panel.mode_option.select(0)
	panel.mode_option.item_selected.emit(0)
	check(panel.resolutions[panel.resolution_option.selected] == Vector2i(1600, 900), "Returning to window restores its selected size")
	panel.apply_button.pressed.emit()
	panel.mode_option.select(2)
	panel.hide()
	panel.open_settings()
	check(panel.mode_option.selected == 0, "Closing without Apply discards pending changes")
	check(settings.commit(2, Vector2i(1600, 900)), "Borderless preference can be saved")
	restored.load_settings()
	check(restored.display_mode == 2, "Borderless mode persists")
	check(not settings.commit(9, Vector2i(1600, 900)) and settings.display_mode == 2, "Invalid mode cannot change settings")
	settings.resolution = Vector2i(3840, 2160)
	settings.display_mode = 0
	panel.open_settings()
	check(panel.resolutions[panel.resolution_option.selected] == Vector2i(1920, 1080), "Oversized saved window must fall back to monitor maximum")
	root.size = Vector2i(1366, 768)
	panel._process(0.0)
	check(panel.resolutions[panel.resolution_option.selected] == Vector2i(1366, 768) and not panel.resolutions.has(Vector2i(1920, 1080)), "Monitor changes must refresh and clamp the list")
	settings.display_mode = 2
	settings.settings_path = "res://tests/missing-folder/settings.cfg"
	check(not settings.commit(0, Vector2i(1280, 720)) and settings.display_mode == 2, "Failed save must keep applied settings")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	panel._input(escape)
	check(not panel.visible, "Escape closes settings")
	title.free()
	settings.free()
	restored.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings_path))
	print("SETTINGS TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
