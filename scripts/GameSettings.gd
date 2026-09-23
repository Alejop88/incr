extends Node

signal settings_changed

enum DisplayMode { WINDOWED, FULLSCREEN, BORDERLESS }
var settings_path: String = "user://ajustes.cfg"
var display_mode: int = DisplayMode.FULLSCREEN
var resolution: Vector2i = Vector2i(1280, 720)
var last_error: String = ""
const CONTROL_NAMES := {"interact": "Mover e interactuar", "camera": "Mover cámara / abrir cocina", "zoom_in": "Acercar cámara", "zoom_out": "Alejar cámara", "reset_camera": "Restablecer cámara", "pause": "Menú de pausa"}
const DEFAULT_BINDINGS := {"interact": {"mouse": true, "code": MOUSE_BUTTON_LEFT}, "camera": {"mouse": true, "code": MOUSE_BUTTON_RIGHT}, "zoom_in": {"mouse": true, "code": MOUSE_BUTTON_WHEEL_UP}, "zoom_out": {"mouse": true, "code": MOUSE_BUTTON_WHEEL_DOWN}, "reset_camera": {"mouse": false, "code": KEY_SPACE}, "pause": {"mouse": false, "code": KEY_ESCAPE}}
var bindings: Dictionary = DEFAULT_BINDINGS.duplicate(true)
var language: String = "es"

func binding_error(action: String, value: Dictionary, candidate: Dictionary) -> String:
	if not value.get("mouse") is bool or not value.get("code") is int or value.code <= 0:
		return "Control no válido."
	if value.mouse and (value.code > MOUSE_BUTTON_XBUTTON2 or (action in ["interact", "camera"] and value.code in [4, 5, 6, 7])):
		return "Usa un botón del ratón que puedas mantener pulsado."
	if action in ["interact", "camera"] and not value.mouse:
		return "Esta acción necesita un botón del ratón."
	if action == "pause" and value.mouse:
		return "Usa una tecla para el menú de pausa."
	if not value.mouse and value.code == KEY_ESCAPE and action != "pause":
		return "Escape está reservado para cerrar menús."
	for other in candidate:
		if other != action and candidate[other] == value:
			return "Ya se utiliza en: " + str(CONTROL_NAMES.get(other, other))
	return ""

func matches(event: InputEvent, action: String, pressed: bool = true) -> bool:
	var value: Dictionary = bindings[action]
	if value.mouse:
		return event is InputEventMouseButton and event.button_index == value.code and event.pressed == pressed
	return event is InputEventKey and event.keycode == value.code and event.pressed == pressed and not event.echo

func binding_text(value: Dictionary) -> String:
	if not value.mouse:
		return "Espacio" if value.code == KEY_SPACE else ("Escape" if value.code == KEY_ESCAPE else OS.get_keycode_string(value.code))
	return {1: "Clic izquierdo", 2: "Clic derecho", 3: "Clic central", 4: "Rueda arriba", 5: "Rueda abajo", 6: "Rueda izquierda", 7: "Rueda derecha", 8: "Botón lateral 1", 9: "Botón lateral 2"}.get(value.code, "Ratón")

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
	var saved: Variant = config.get_value("controls", "bindings", DEFAULT_BINDINGS)
	if saved is Dictionary and saved.size() == DEFAULT_BINDINGS.size():
		var valid := true
		for action in DEFAULT_BINDINGS:
			if not saved.get(action) is Dictionary or not binding_error(action, saved[action], saved).is_empty():
				valid = false
		if valid:
			bindings = saved.duplicate(true)

func commit(mode: int, size: Vector2i, controls: Dictionary = {}, locale: String = "es") -> bool:
	last_error = ""
	if controls.is_empty():
		controls = bindings
	if mode < DisplayMode.WINDOWED or mode > DisplayMode.BORDERLESS or size.x < 640 or size.y < 360 or size.x > 7680 or size.y > 4320:
		last_error = "La configuración de pantalla no es válida."
		return false
	if locale != "es" or controls.size() != DEFAULT_BINDINGS.size():
		last_error = "Idioma o controles no válidos."
		return false
	for action in DEFAULT_BINDINGS:
		if not controls.get(action) is Dictionary:
			last_error = "Falta un control."
			return false
		last_error = binding_error(action, controls[action], controls)
		if not last_error.is_empty():
			return false
	var config := ConfigFile.new()
	config.set_value("display", "mode", mode)
	config.set_value("display", "resolution", size)
	config.set_value("general", "language", locale)
	config.set_value("controls", "bindings", controls)
	if config.save(settings_path) != OK:
		last_error = "No se pudieron guardar los ajustes."
		return false
	display_mode = mode
	resolution = size
	bindings = controls.duplicate(true)
	language = locale
	apply_display()
	settings_changed.emit()
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
