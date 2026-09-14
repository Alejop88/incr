extends CanvasLayer

signal save_requested

@onready var overlay: Control = $Overlay
@onready var resume_button: Button = $Overlay/Center/Panel/Margin/Buttons/ResumeButton
@onready var save_button: Button = $Overlay/Center/Panel/Margin/Buttons/SaveButton
@onready var status_label: Label = $Overlay/Center/Panel/Margin/Buttons/StatusLabel

func _ready() -> void:
	resume_button.pressed.connect(close_menu)
	save_button.pressed.connect(func(): save_requested.emit())

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		if overlay.visible:
			close_menu()
		else:
			open_menu()

func open_menu() -> void:
	overlay.show()
	get_tree().paused = true
	resume_button.grab_focus()

func close_menu() -> void:
	overlay.hide()
	get_tree().paused = false

func show_status(message: String) -> void:
	status_label.text = message
