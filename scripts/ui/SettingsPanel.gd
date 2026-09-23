extends Control

var settings: Node
var tabs: TabContainer
var mode_option: OptionButton
var monitor_option: OptionButton
var resolution_option: OptionButton
var display_hint: Label
var status: Label
var apply_button: Button
var language_option: OptionButton
var control_buttons: Dictionary = {}
var draft_bindings: Dictionary = {}
var listening_action: String = ""
var window_resolution: Vector2i = Vector2i(1280, 720)
const RESOLUTION_PRESETS: Array[Vector2i] = [Vector2i(960, 540), Vector2i(1152, 648), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1440), Vector2i(3840, 2160)]
var resolutions: Array[Vector2i] = []
var listed_monitor_size := Vector2i.ZERO

func _ready() -> void:
	settings = get_node("/root/GameSettings")
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.75)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(720, 470)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Ajustes"
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	tabs = TabContainer.new()
	tabs.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(tabs)
	var general := _tab("General")
	_note(general, "Idioma")
	language_option = OptionButton.new()
	language_option.add_item("Español")
	general.add_child(language_option)
	_note(general, "Se añadirán más idiomas cuando estén disponibles.")
	_note(general, "Los ajustes se guardan automáticamente al pulsar Aplicar.\nSe conservan aunque empieces una nueva partida.")
	var display := _tab("Pantalla")
	_note(display, "Monitor")
	monitor_option = OptionButton.new()
	display.add_child(monitor_option)
	monitor_option.item_selected.connect(func(_index: int): _update_display_hint())
	_note(display, "Modo de pantalla")
	mode_option = OptionButton.new()
	for text in ["Ventana", "Pantalla completa", "Ventana sin bordes"]:
		mode_option.add_item(text)
	display.add_child(mode_option)
	mode_option.item_selected.connect(func(_index: int): _update_display_hint())
	_note(display, "Resolución de ventana")
	resolution_option = OptionButton.new()
	for size in resolutions:
		resolution_option.add_item("%d × %d" % [size.x, size.y])
	display.add_child(resolution_option)
	display_hint = _note(display, "")
	_note(_tab("Audio"), "Todavía no hay audio en el juego.\nLos ajustes de sonido estarán disponibles cuando se añada.")
	_note(_tab("Gameplay"), "Todavía no hay ajustes de gameplay disponibles.")
	var controls := _tab("Controles")
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 210
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	controls.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for action in settings.CONTROL_NAMES:
		var control_row := HBoxContainer.new()
		list.add_child(control_row)
		var label := Label.new()
		label.text = settings.CONTROL_NAMES[action]
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		control_row.add_child(label)
		var button := Button.new()
		button.custom_minimum_size = Vector2(230, 32)
		button.pressed.connect(_listen.bind(action))
		control_row.add_child(button)
		control_buttons[action] = button
	_note(controls, "Pulsa un control para cambiarlo. Cámara: arrastra; sobre la cocinera: abre la cocina.")
	var reset := Button.new()
	reset.text = "Restablecer controles"
	reset.pressed.connect(func():
		listening_action = ""
		draft_bindings = settings.DEFAULT_BINDINGS.duplicate(true)
		_refresh_controls())
	controls.add_child(reset)
	status = _note(column, "")
	var row := HBoxContainer.new()
	column.add_child(row)
	apply_button = Button.new()
	apply_button.text = "Aplicar"
	apply_button.custom_minimum_size.y = 44
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.pressed.connect(_apply)
	row.add_child(apply_button)
	var close := Button.new()
	close.text = "Cerrar"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(hide)
	row.add_child(close)
	hide()

func _tab(title: String) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.name = title
	page.add_theme_constant_override("separation", 12)
	tabs.add_child(page)
	return page

func _note(parent: Node, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

func open_settings() -> void:
	listening_action = ""
	draft_bindings = settings.bindings.duplicate(true)
	language_option.select(0)
	_refresh_controls()
	mode_option.select(settings.display_mode)
	window_resolution = settings.resolution
	resolution_option.disabled = true
	status.text = ""
	_refresh_monitors(settings.resolve_monitor(settings.monitor_index))
	_update_display_hint()
	show()
	move_to_front()
	tabs.get_tab_bar().focus_mode = Control.FOCUS_ALL
	tabs.get_tab_bar().grab_focus()

func _update_display_hint() -> void:
	if not resolution_option.disabled and resolution_option.selected >= 0:
		window_resolution = resolutions[resolution_option.selected]
	listed_monitor_size = monitor_resolution()
	resolutions = resolutions_for_monitor(listed_monitor_size, window_resolution)
	resolution_option.clear()
	for size in resolutions:
		resolution_option.add_item("%d × %d" % [size.x, size.y])
	if not resolutions.has(window_resolution):
		window_resolution = listed_monitor_size
	resolution_option.disabled = mode_option.selected != 0
	_show_resolution(listed_monitor_size if resolution_option.disabled else window_resolution)
	display_hint.text = "La ventana se ajusta al espacio disponible en tu monitor." if mode_option.selected == 0 else "Este modo utiliza la resolución del monitor."

func monitor_resolution() -> Vector2i:
	return settings.monitor_size(monitor_option.selected)

func _refresh_monitors(selected: int) -> void:
	monitor_option.clear()
	for index in range(settings.monitor_count()):
		var size: Vector2i = settings.monitor_size(index)
		monitor_option.add_item("Monitor %d — %d × %d" % [index + 1, size.x, size.y])
	monitor_option.select(settings.resolve_monitor(selected))
	monitor_option.disabled = monitor_option.item_count == 1

static func resolutions_for_monitor(maximum: Vector2i, preferred: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var candidates: Array[Vector2i] = RESOLUTION_PRESETS.duplicate()
	candidates.append(preferred)
	candidates.append(maximum)
	for size in candidates:
		if size.x > 0 and size.y > 0 and size.x <= maximum.x and size.y <= maximum.y and not result.has(size):
			result.append(size)
	result.sort_custom(func(a: Vector2i, b: Vector2i): return a.x * a.y < b.x * b.y)
	return result

func _process(_delta: float) -> void:
	if not visible:
		return
	if monitor_option.item_count != settings.monitor_count():
		_refresh_monitors(monitor_option.selected)
		_update_display_hint()
	elif monitor_resolution() != listed_monitor_size:
		_refresh_monitors(monitor_option.selected)
		_update_display_hint()

func _show_resolution(value: Vector2i) -> void:
	resolution_option.select(resolutions.find(value))

func _apply() -> void:
	if mode_option.selected == 0:
		window_resolution = resolutions[resolution_option.selected]
	if settings.commit(mode_option.selected, window_resolution, draft_bindings, "es", monitor_option.selected):
		status.text = "Ajustes guardados."
	else:
		status.text = settings.last_error

func _input(event: InputEvent) -> void:
	if not visible:
		return
	if not listening_action.is_empty():
		if (event is InputEventKey and event.pressed and not event.echo) or (event is InputEventMouseButton and event.pressed):
			get_viewport().set_input_as_handled()
			if event is InputEventKey and event.keycode == KEY_ESCAPE and listening_action != "pause":
				listening_action = ""
				status.text = "Cambio cancelado."
				_refresh_controls()
				return
			var value := {"mouse": event is InputEventMouseButton, "code": event.button_index if event is InputEventMouseButton else event.keycode}
			var error: String = settings.binding_error(listening_action, value, draft_bindings)
			if not error.is_empty():
				status.text = error
				return
			draft_bindings[listening_action] = value
			listening_action = ""
			status.text = "Pulsa Aplicar para guardar los controles."
			_refresh_controls()
		return
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()

func _listen(action: String) -> void:
	listening_action = action
	_refresh_controls()
	status.text = "Pulsa el nuevo control. Escape cancela (o se asigna al menú de pausa)."
	control_buttons[action].release_focus()

func _refresh_controls() -> void:
	for action in control_buttons:
		control_buttons[action].text = "Pulsa un control…" if action == listening_action else settings.binding_text(draft_bindings[action])
	if apply_button != null:
		apply_button.disabled = not listening_action.is_empty()
