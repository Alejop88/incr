extends SceneTree

class SimulatedSettings extends "res://scripts/GameSettings.gd":
	var screens: Array[Vector2i] = [Vector2i(1920, 1080), Vector2i(2560, 1440)]
	func monitor_count() -> int:
		return screens.size()
	func monitor_size(index: int) -> Vector2i:
		return screens[resolve_monitor(index)]

var failures := 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func run_tests() -> void:
	var settings := SimulatedSettings.new()
	settings.settings_path = "res://tests/monitors-%s.cfg" % Time.get_ticks_usec()
	root.add_child(settings)
	var panel: Control = load("res://scripts/ui/SettingsPanel.gd").new()
	root.add_child(panel)
	panel.settings = settings
	panel.open_settings()
	check(panel.monitor_option.item_count == 2, "All detected monitors must appear")
	panel.monitor_option.select(1)
	panel.monitor_option.item_selected.emit(1)
	check(panel.monitor_resolution() == Vector2i(2560, 1440), "Resolution must follow the selected target monitor")
	check(panel.resolutions.has(Vector2i(2560, 1440)), "Larger target monitor must unlock its resolution")
	check(settings.monitor_index == 0, "Monitor changes must wait for Apply")
	panel._apply()
	check(settings.monitor_index == 1, "Apply must select the target monitor")
	var restored := SimulatedSettings.new()
	restored.settings_path = settings.settings_path
	root.add_child(restored)
	check(restored.monitor_index == 1, "Monitor choice must survive restart")
	panel.monitor_option.select(0)
	panel.monitor_option.item_selected.emit(0)
	check(not panel.resolutions.has(Vector2i(2560, 1440)), "Smaller target monitor must hide larger resolutions")
	panel.hide()
	panel.open_settings()
	check(panel.monitor_option.selected == 1, "Unapplied monitor changes must be discarded")
	settings.screens.resize(1)
	panel._process(0)
	check(panel.monitor_option.selected == 0 and panel.monitor_option.disabled, "Unplugged monitor must fall back to the remaining screen")
	settings.load_settings()
	check(settings.monitor_index == 0, "Unavailable saved monitor must fall back safely")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(settings.settings_path))
	panel.free()
	settings.free()
	restored.free()
	print("MONITOR TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
