extends Control

@export_file("*.tscn") var game_scene_path: String = "res://scenes/Main.tscn"
@onready var save_manager: Node = $SaveManager
var continue_button: Button
var new_game_button: Button
var status_label: Label
var confirmation: ConfirmationDialog
var starting: bool = false

func _ready() -> void:
	var background := ColorRect.new()
	background.color = Color("18252a")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	var center := CenterContainer.new()
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
	continue_button = _add_button(buttons, "Continuar", _continue_game)
	new_game_button = _add_button(buttons, "Nueva partida", _request_new_game)
	_add_button(buttons, "Salir del juego", func(): get_tree().quit())
	status_label = Label.new()
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.x = 336
	buttons.add_child(status_label)
	confirmation = ConfirmationDialog.new()
	confirmation.title = "Nueva partida"
	confirmation.dialog_text = "Se borrará la partida guardada, incluidas las mejoras permanentes. ¿Empezar de nuevo?"
	confirmation.ok_button_text = "Nueva partida"
	confirmation.cancel_button_text = "Cancelar"
	confirmation.confirmed.connect(_start_new_game)
	add_child(confirmation)
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

func refresh_save_status() -> void:
	continue_button.disabled = save_manager.load_game().is_empty()
	status_label.text = save_manager.last_error
	continue_button.tooltip_text = "No hay una partida guardada válida." if continue_button.disabled else "Cargar tu partida guardada."

func _continue_game() -> void:
	if starting:
		return
	refresh_save_status()
	if not continue_button.disabled:
		_enter_game(false)

func _request_new_game() -> void:
	if starting:
		return
	if FileAccess.file_exists(save_manager.save_path):
		confirmation.popup_centered(Vector2i(460, 180))
		confirmation.get_cancel_button().grab_focus()
	else:
		_start_new_game()

func _start_new_game() -> void:
	_enter_game(true)

func _enter_game(reset_save: bool) -> void:
	if starting:
		return
	var scene: PackedScene = load(game_scene_path) as PackedScene
	if scene == null:
		status_label.text = "No se pudo abrir el restaurante."
		return
	if reset_save and not save_manager.delete_save():
		status_label.text = save_manager.last_error
		return
	starting = true
	get_tree().paused = false
	var error: Error = get_tree().change_scene_to_packed(scene)
	if error != OK:
		starting = false
		status_label.text = "No se pudo abrir el restaurante."
