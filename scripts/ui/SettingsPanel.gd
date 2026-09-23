extends Control

var settings: Node
var tabs: TabContainer
var mode_option: OptionButton
var resolution_option: OptionButton
var display_hint: Label
var status: Label
var apply_button: Button
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
	_note(general, "Los ajustes se guardan automáticamente al pulsar Aplicar.\nSe conservan aunque empieces una nueva partida.")
	var display := _tab("Pantalla")
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
	_note(_tab("Controles"), "Clic izquierdo: mover al personaje e interactuar.\nClic derecho en la cocinera: abrir la cocina.\nArrastrar con clic derecho: mover la cámara.\nRueda del ratón: acercar y alejar.\nEspacio: restablecer la cámara.\nEscape: abrir o cerrar el menú de pausa.\n\nLa reasignación de controles aún no está disponible.")
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
	mode_option.select(settings.display_mode)
	window_resolution = settings.resolution
	resolution_option.disabled = true
	status.text = ""
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
	if DisplayServer.get_name() == "headless":
		return get_tree().root.size
	return DisplayServer.screen_get_size(get_tree().root.current_screen)

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
	if visible and monitor_resolution() != listed_monitor_size:
		_update_display_hint()

func _show_resolution(value: Vector2i) -> void:
	resolution_option.select(resolutions.find(value))

func _apply() -> void:
	if mode_option.selected == 0:
		window_resolution = resolutions[resolution_option.selected]
	if settings.commit(mode_option.selected, window_resolution):
		status.text = "Ajustes guardados."
	else:
		status.text = settings.last_error

func _input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		hide()
		get_viewport().set_input_as_handled()
