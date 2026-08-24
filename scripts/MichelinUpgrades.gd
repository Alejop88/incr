extends Control
signal upgrade_requested(upgrade_id: String)

@onready var stars_label: Label = $StarsLabel
@onready var close_button: Button = $CloseButton



var upgrade_buttons: Dictionary = {}
func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	for child in get_children():
		if child is Button and child != close_button:
			upgrade_buttons[child.name] = child
	for upgrade_id in upgrade_buttons:
		var button: Button = upgrade_buttons[upgrade_id]

		button.pressed.connect(
			func():
				upgrade_requested.emit(upgrade_id)
		)
func set_stars(value: int) -> void:
	stars_label.text = "⭐ %d" % value


func _on_close_button_pressed() -> void:
	visible = false
func set_upgrade_bought(upgrade_id: String, is_bought: bool) -> void:
	if not upgrade_buttons.has(upgrade_id):
		return

	var button: Button = upgrade_buttons[upgrade_id]

	button.set_meta("bought", is_bought)
	button.disabled = is_bought
func get_upgrade_ids() -> Array[String]:
	return upgrade_buttons.keys()
func set_upgrade_info(
	upgrade_id: String,
	upgrade_name: String,
	description: String,
	cost: int
) -> void:
	if not upgrade_buttons.has(upgrade_id):
		return

	var button: Button = upgrade_buttons[upgrade_id]

	var status_text := ""

	if button.get_meta("bought", false):
		status_text = "\n\nCOMPRADA"
	elif button.disabled:
		status_text = "\n\nBLOQUEADA"

	button.tooltip_text = \
		upgrade_name + "\n\n" + \
		description + "\n\n" + \
		"Coste: ⭐ %d" % cost + \
		status_text
func set_upgrade_locked(upgrade_id: String, is_locked: bool) -> void:
	if not upgrade_buttons.has(upgrade_id):
		return

	var button: Button = upgrade_buttons[upgrade_id]

	if button.get_meta("bought", false):
		button.disabled = true
		return

	button.disabled = is_locked
