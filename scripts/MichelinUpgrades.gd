extends Control
signal upgrade_requested(upgrade_id: String)

@onready var stars_label: Label = $StarsLabel
@onready var close_button: Button = $CloseButton
@onready var counter_capacity_upgrade_button: Button = $CounterCapacityUpgradeButton

var upgrade_buttons: Dictionary = {}
func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	counter_capacity_upgrade_button.pressed.connect(_on_counter_capacity_upgrade_button_pressed)
	upgrade_buttons["counter_capacity_1"] = counter_capacity_upgrade_button
func set_stars(value: int) -> void:
	stars_label.text = "⭐ %d" % value
func set_counter_capacity_upgrade_bought(is_bought: bool) -> void:
	counter_capacity_upgrade_button.disabled = is_bought
func _on_counter_capacity_upgrade_button_pressed() -> void:
	upgrade_requested.emit("counter_capacity_1")
func _on_close_button_pressed() -> void:
	visible = false
func set_upgrade_bought(upgrade_id: String, is_bought: bool) -> void:
	if not upgrade_buttons.has(upgrade_id):
		return

	var button: Button = upgrade_buttons[upgrade_id]
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

	button.tooltip_text = \
		upgrade_name + "\n\n" + \
		description + "\n\n" + \
		"Coste: ⭐ %d" % cost
