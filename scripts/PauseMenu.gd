extends CanvasLayer

signal save_requested
signal new_game_requested
signal quit_requested(save_first: bool)

@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/Center/Panel/Margin/Buttons/ResumeButton
@onready var save_button: Button = $Overlay/Center/Panel/Margin/Buttons/SaveButton
@onready var status_label: Label = $Overlay/Center/Panel/Margin/Buttons/StatusLabel
@onready var new_game_button: Button = $Overlay/Center/Panel/Margin/Buttons/NewGameButton
@onready var confirmation: VBoxContainer = $Overlay/Center/Panel/Margin/Buttons/NewGameConfirmation
@onready var confirm_button: Button = $Overlay/Center/Panel/Margin/Buttons/NewGameConfirmation/ConfirmButton
@onready var cancel_button: Button = $Overlay/Center/Panel/Margin/Buttons/NewGameConfirmation/CancelButton
@onready var quit_button: Button = $Overlay/Center/Panel/Margin/Buttons/QuitButton
@onready var quit_confirmation: VBoxContainer = $Overlay/Center/Panel/Margin/Buttons/QuitConfirmation
@onready var save_quit_button: Button = $Overlay/Center/Panel/Margin/Buttons/QuitConfirmation/SaveQuitButton
@onready var discard_quit_button: Button = $Overlay/Center/Panel/Margin/Buttons/QuitConfirmation/DiscardQuitButton
@onready var cancel_quit_button: Button = $Overlay/Center/Panel/Margin/Buttons/QuitConfirmation/CancelQuitButton

func _ready() -> void:
	resume_button.pressed.connect(close_menu)
	save_button.pressed.connect(func(): save_requested.emit())
	new_game_button.pressed.connect(_show_new_game_confirmation)
	cancel_button.pressed.connect(_cancel_new_game)
	confirm_button.pressed.connect(_confirm_new_game)
	quit_button.pressed.connect(_show_quit_confirmation)
	cancel_quit_button.pressed.connect(_cancel_quit)
	save_quit_button.pressed.connect(func(): quit_requested.emit(true))
	discard_quit_button.pressed.connect(func(): quit_requested.emit(false))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if quit_confirmation.visible:
			_cancel_quit()
		elif confirmation.visible:
			_cancel_new_game()
		elif overlay.visible:
			close_menu()
		else:
			open_menu()

func open_menu() -> void:
	overlay.show()
	get_tree().paused = true
	resume_button.grab_focus()

func close_menu() -> void:
	quit_confirmation.hide()
	_set_confirmation_visible(false)
	overlay.hide()
	get_tree().paused = false

func show_status(message: String) -> void:
	status_label.text = message

func _show_new_game_confirmation() -> void:
	_set_confirmation_visible(true)
	cancel_button.grab_focus()

func _cancel_new_game() -> void:
	_set_confirmation_visible(false)
	new_game_button.grab_focus()

func _confirm_new_game() -> void:
	_set_confirmation_visible(false)
	new_game_requested.emit()

func _set_confirmation_visible(value: bool) -> void:
	confirmation.visible = value
	_update_menu_buttons()

func _update_menu_buttons() -> void:
	var show_buttons: bool = not confirmation.visible and not quit_confirmation.visible
	resume_button.visible = show_buttons
	save_button.visible = show_buttons
	new_game_button.visible = show_buttons
	quit_button.visible = show_buttons

func _show_quit_confirmation() -> void:
	confirmation.hide()
	quit_confirmation.show()
	_update_menu_buttons()
	cancel_quit_button.grab_focus()

func _cancel_quit() -> void:
	quit_confirmation.hide()
	_update_menu_buttons()
	quit_button.grab_focus()
