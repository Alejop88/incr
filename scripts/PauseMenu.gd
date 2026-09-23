extends CanvasLayer

signal save_requested
signal quit_requested(save_first: bool)
signal title_requested(save_first: bool)

var settings_panel: Control
var returning_to_title: bool = false
@onready var overlay: Control = $Overlay
@onready var save_button: Button = $Overlay/Center/Panel/Margin/Buttons/SaveButton
@onready var status_label: Label = $Overlay/Center/Panel/Margin/Buttons/StatusLabel
@onready var title_button: Button = $Overlay/Center/Panel/Margin/Buttons/TitleButton
@onready var settings_button: Button = $Overlay/Center/Panel/Margin/Buttons/SettingsButton
@onready var quit_button: Button = $Overlay/Center/Panel/Margin/Buttons/QuitButton
@onready var quit_confirmation: VBoxContainer = $Overlay/Center/Panel/Margin/Buttons/QuitConfirmation
@onready var save_quit_button: Button = $Overlay/Center/Panel/Margin/Buttons/QuitConfirmation/SaveQuitButton
@onready var discard_quit_button: Button = $Overlay/Center/Panel/Margin/Buttons/QuitConfirmation/DiscardQuitButton
@onready var cancel_quit_button: Button = $Overlay/Center/Panel/Margin/Buttons/QuitConfirmation/CancelQuitButton

func _ready() -> void:
	settings_panel = preload("res://scripts/ui/SettingsPanel.gd").new()
	add_child(settings_panel)
	settings_button.pressed.connect(settings_panel.open_settings)
	settings_panel.visibility_changed.connect(func():
		if not settings_panel.visible and overlay.visible:
			settings_button.grab_focus())
	save_button.pressed.connect(func(): save_requested.emit())
	title_button.pressed.connect(_show_quit_confirmation.bind(true))
	quit_button.pressed.connect(_show_quit_confirmation)
	cancel_quit_button.pressed.connect(_cancel_quit)
	save_quit_button.pressed.connect(_leave.bind(true))
	discard_quit_button.pressed.connect(_leave.bind(false))

func _input(event: InputEvent) -> void:
	if settings_panel.visible:
		return
	if get_node("/root/GameSettings").matches(event, "pause") or (overlay.visible and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE):
		get_viewport().set_input_as_handled()
		if quit_confirmation.visible:
			_cancel_quit()
		elif overlay.visible:
			close_menu()
		else:
			open_menu()

func open_menu() -> void:
	overlay.show()
	get_tree().paused = true
	status_label.text = "Pulsa %s para volver al restaurante." % get_node("/root/GameSettings").binding_text(get_node("/root/GameSettings").bindings.pause)
	save_button.grab_focus()

func close_menu() -> void:
	settings_panel.hide()
	quit_confirmation.hide()
	_update_menu_buttons()
	overlay.hide()
	get_tree().paused = false

func show_status(message: String) -> void:
	status_label.text = message

func _update_menu_buttons() -> void:
	for button in [save_button, title_button, settings_button, quit_button]:
		button.visible = not quit_confirmation.visible

func _show_quit_confirmation(to_title: bool = false) -> void:
	returning_to_title = to_title
	quit_confirmation.get_node("Question").text = "¿Quieres guardar antes de volver al inicio?\nSin guardar perderás los cambios recientes." if to_title else "¿Quieres guardar antes de salir?\nSin guardar perderás los cambios recientes."
	save_quit_button.text = "Guardar y volver al inicio" if to_title else "Guardar y salir"
	discard_quit_button.text = "Volver sin guardar" if to_title else "Salir sin guardar"
	quit_confirmation.show()
	_update_menu_buttons()
	cancel_quit_button.grab_focus()

func _cancel_quit() -> void:
	quit_confirmation.hide()
	_update_menu_buttons()
	(title_button if returning_to_title else quit_button).grab_focus()

func _leave(save_first: bool) -> void:
	if returning_to_title:
		title_requested.emit(save_first)
	else:
		quit_requested.emit(save_first)
