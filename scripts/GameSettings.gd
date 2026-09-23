extends Node

enum DisplayMode { WINDOWED, FULLSCREEN, BORDERLESS }
var settings_path: String = "user://ajustes.cfg"
var display_mode: int = DisplayMode.FULLSCREEN
var resolution: Vector2i = Vector2i(1280, 720)
var last_error: String = ""

func _ready() -> void:
	load_settings()
	apply_display()

func load_settings() -> void:
	var config := ConfigFile.new()
	if config.load(settings_path) != OK:
		return
	var mode: Variant = config.get_value("display", "mode", DisplayMode.FULLSCREEN)
	var size: Variant = config.get_value("display", "resolution", Vector2i(1280, 720))
	if mode is int and mode >= DisplayMode.WINDOWED and mode <= DisplayMode.BORDERLESS:
		display_mode = mode
	if size is Vector2i and size.x >= 640 and size.y >= 360 and size.x <= 7680 and size.y <= 4320:
		resolution = size

func commit(mode: int, size: Vector2i) -> bool:
	last_error = ""
	if mode < DisplayMode.WINDOWED or mode > DisplayMode.BORDERLESS or size.x < 640 or size.y < 360 or size.x > 7680 or size.y > 4320:
		last_error = "La configuración de pantalla no es válida."
		return false
	var config := ConfigFile.new()
	config.set_value("display", "mode", mode)
	config.set_value("display", "resolution", size)
	if config.save(settings_path) != OK:
		last_error = "No se pudieron guardar los ajustes."
		return false
	display_mode = mode
	resolution = size
	apply_display()
	return true

func apply_display() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window: Window = get_tree().root
	var screen: int = window.current_screen
	window.mode = Window.MODE_WINDOWED
	window.borderless = false
	match display_mode:
		DisplayMode.WINDOWED:
			var usable: Rect2i = DisplayServer.screen_get_usable_rect(screen)
			window.size = Vector2i(mini(resolution.x, usable.size.x - 32), mini(resolution.y, usable.size.y - 64))
			window.position = usable.position + (usable.size - window.size) / 2
		DisplayMode.FULLSCREEN:
			window.mode = Window.MODE_FULLSCREEN
		DisplayMode.BORDERLESS:
			window.borderless = true
			window.size = DisplayServer.screen_get_size(screen)
			window.position = DisplayServer.screen_get_position(screen)
