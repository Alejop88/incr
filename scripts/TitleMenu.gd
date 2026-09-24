extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/Main.tscn"
@onready var save_manager: Node = $SaveManager
@onready var slots: Node = get_node("/root/SaveSlots")
var continue_button: Button
var new_game_button: Button
var status_label: Label
var confirmation: ConfirmationDialog
var starting: bool = false
var settings_panel: Control
var settings_button: Button
var main_panel: Control
var slot_panel: Control
var slot_buttons: Array[Button] = []
var mode_panel: Control
var mode_buttons: Dictionary = {}
var selected_mode: String = "cozy"
var mode_cancel_button: Button
var slot_cancel_button: Button
var back_to_modes_button: Button
var slot_heading: Label
var slot_status: Label
var choosing_new: bool = false
var selected_slot: int = 0
var base_save_path: String

func _ready() -> void:
	base_save_path = save_manager.save_path
	var background := ColorRect.new()
	background.color = Color("18252a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
	main_panel = center
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 400
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 32)
	panel.add_child(margin)
	var buttons := VBoxContainer.new()
	buttons.add_theme_constant_override("separation", 16)
	margin.add_child(buttons)
	var title := Label.new()
	title.text = "INCR"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 42)
	buttons.add_child(title)
	var subtitle := Label.new()
	subtitle.text = "Tu restaurante"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	buttons.add_child(subtitle)
	continue_button = _add_button(buttons, "Cargar partida", _continue_game)
	new_game_button = _add_button(buttons, "Nueva partida", _request_new_game)
	_add_button(buttons, "Salir del juego", func(): get_tree().quit())
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.x = 336
	buttons.add_child(status_label)
	var settings_row := HBoxContainer.new()
	settings_row.alignment = BoxContainer.ALIGNMENT_END
	buttons.add_child(settings_row)
	settings_button = Button.new()
	settings_button.text = "⚙"
	settings_button.tooltip_text = "Ajustes"
	settings_button.custom_minimum_size = Vector2(44, 44)
	settings_button.add_theme_font_size_override("font_size", 26)
	settings_row.add_child(settings_button)
	settings_panel = preload("res://scripts/ui/SettingsPanel.gd").new()
	add_child(settings_panel)
	settings_button.pressed.connect(settings_panel.open_settings)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Nueva partida"
	confirmation.dialog_text = "Se borrará la partida guardada, incluidas las mejoras permanentes. ¿Empezar de nuevo?"
	confirmation.ok_button_text = "Nueva partida"
	confirmation.cancel_button_text = "Cancelar"
	confirmation.confirmed.connect(_start_new_game)
	add_child(confirmation)
	_build_mode_panel()
	_build_slot_panel()
	refresh_save_status()
	if continue_button.disabled:
		new_game_button.grab_focus()
	else:
		continue_button.grab_focus()

func _add_button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 52
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _build_mode_panel() -> void:
	mode_panel = CenterContainer.new()
	mode_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(mode_panel)
	var panel := PanelContainer.new()
	mode_panel.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 20)
	margin.add_child(column)
	var heading := Label.new()
	heading.text = "Nueva partida · Elige tu modo"
	heading.add_theme_font_size_override("font_size", 28)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(heading)
	var choices := HBoxContainer.new()
	choices.add_theme_constant_override("separation", 20)
	column.add_child(choices)
	for mode in ["cozy", "normal"]:
		var button := Button.new()
		button.custom_minimum_size = Vector2(310, 280)
		button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		button.add_theme_font_size_override("font_size", 20)
		button.text = "COZY\n\nDecora tu restaurante y juega con tranquilidad.\n\nLos platos cambian de apariencia, sin estadísticas ni combos." if mode == "cozy" else "NORMAL\n\nGestiona los platos y sus combinaciones.\n\nTendrá estadísticas y combos. Por ahora funciona igual que Cozy."
		for state in ["normal", "hover", "pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = Color("274d44") if mode == "cozy" else Color("2d435e")
			style.border_color = Color("d7dfb2") if state != "normal" else Color("65877e")
			style.set_border_width_all(3 if state != "normal" else 1)
			style.set_corner_radius_all(14)
			style.content_margin_left = 22
			style.content_margin_right = 22
			button.add_theme_stylebox_override(state, style)
		button.pressed.connect(_select_mode.bind(mode))
		choices.add_child(button)
		mode_buttons[mode] = button
	mode_cancel_button = _add_button(column, "Cancelar nueva partida", _cancel_new_game)
	mode_panel.hide()

func _select_mode(mode: String) -> void:
	if starting or mode not in ["cozy", "normal"]:
		return
	selected_mode = mode
	_open_slots(true)
	slot_buttons[0].grab_focus()

func _cancel_new_game() -> void:
	if starting:
		return
	confirmation.hide()
	mode_panel.hide()
	slot_panel.hide()
	main_panel.show()
	refresh_save_status()
	new_game_button.grab_focus()

func _build_slot_panel() -> void:
	slot_panel = CenterContainer.new()
	slot_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(slot_panel)
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = 590
	slot_panel.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	slot_heading = Label.new()
	slot_heading.add_theme_font_size_override("font_size", 26)
	column.add_child(slot_heading)
	for index in range(3):
		var button := _add_button(column, "", _choose_slot.bind(index))
		button.custom_minimum_size.y = 68
		slot_buttons.append(button)
	slot_status = Label.new()
	slot_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(slot_status)
	back_to_modes_button = _add_button(column, "Cambiar modo", _request_new_game)
	slot_cancel_button = _add_button(column, "Cancelar nueva partida", _cancel_new_game)
	slot_panel.hide()

func _slot_data(index: int) -> Dictionary:
	var reader: Node = preload("res://scripts/SaveManager.gd").new()
	reader.save_path = slots.slot_path(base_save_path, index)
	var data: Dictionary = reader.load_game()
	reader.free()
	return data

func refresh_save_status() -> void:
	continue_button.disabled = true
	status_label.text = ""
	for index in range(3):
		if not _slot_data(index).is_empty():
			continue_button.disabled = false
		elif FileAccess.file_exists(slots.slot_path(base_save_path, index)):
			status_label.text = "Hay una ranura con un guardado no válido."
	continue_button.tooltip_text = "No hay partidas guardadas válidas." if continue_button.disabled else "Elige una de tus tres partidas."

func _continue_game() -> void:
	if not starting:
		_open_slots(false)

func _request_new_game() -> void:
	if not starting:
		main_panel.hide()
		slot_panel.hide()
		mode_panel.show()
		mode_buttons[selected_mode].grab_focus()

func _open_slots(create_new: bool) -> void:
	choosing_new = create_new
	mode_panel.hide()
	back_to_modes_button.visible = create_new
	slot_cancel_button.text = "Cancelar nueva partida" if create_new else "Volver"
	main_panel.hide()
	slot_panel.show()
	slot_heading.text = "Nueva partida · %s · Elige ranura" % slots.mode_name(selected_mode) if create_new else "Cargar partida"
	slot_status.text = "La partida siempre se guardará en la ranura que elijas." if create_new else "Selecciona la partida que quieres continuar."
	for index in range(3):
		var data := _slot_data(index)
		var button := slot_buttons[index]
		button.disabled = not create_new and data.is_empty()
		if data.is_empty():
			button.text = "Ranura %d · %s" % [index + 1, "Guardado no válido" if FileAccess.file_exists(slots.slot_path(base_save_path, index)) else "Vacía"]
		else:
			button.text = "Ranura %d · %s\nDinero: %.1f €   |   Estrellas: %d   |   Tiempo: %s" % [index + 1, slots.mode_name(data.get("game_mode", "cozy")), data.money, data.michelin.stars, slots.time_label(float(data.get("play_time", 0.0)))]


func _choose_slot(index: int) -> void:
	if starting or index < 0 or index >= 3:
		return
	selected_slot = index
	if choosing_new:
		if FileAccess.file_exists(slots.slot_path(base_save_path, index)):
			confirmation.dialog_text = "¿Reemplazar la partida de la ranura %d? Se borrará su progreso, incluidas las mejoras permanentes. Las otras ranuras no cambiarán." % (index + 1)
			confirmation.popup_centered(Vector2i(490, 180))
			confirmation.get_cancel_button().grab_focus()
		else:
			_start_new_game()
	elif not _slot_data(index).is_empty():
		_enter_game(false)

func _start_new_game() -> void:
	_enter_game(true)

func _enter_game(reset_save: bool) -> void:
	if starting:
		return
	var scene: PackedScene = load(game_scene_path) as PackedScene
	if scene == null:
		slot_status.text = "No se pudo abrir el restaurante."
		return
	var previous_path: String = slots.active_path
	slots.active_path = slots.slot_path(base_save_path, selected_slot)
	slots.selected_mode = selected_mode
	slots.new_game_pending = reset_save
	starting = true
	var tree: SceneTree = get_tree()
	tree.paused = false
	var error: Error = tree.change_scene_to_packed(scene)
	if error != OK:
		slots.active_path = previous_path
		slots.new_game_pending = false
		starting = false
		slot_status.text = "No se pudo abrir el restaurante."
