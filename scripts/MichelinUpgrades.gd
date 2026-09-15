extends Control
signal upgrade_requested(upgrade_id: String)
signal purchase_requested
signal purchase_confirmed

@onready var stars_label: Label = $StarsLabel
@onready var close_button: Button = $CloseButton
@onready var purchase_button: Button = $PurchasePanel/PurchaseButton
@onready var purchase_summary: Label = $PurchasePanel/SummaryLabel
@onready var purchase_status: Label = $PurchasePanel/StatusLabel
@onready var purchase_confirmation: VBoxContainer = $PurchasePanel/Confirmation
@onready var confirmation_label: Label = $PurchasePanel/Confirmation/WarningLabel
@onready var confirm_button: Button = $PurchasePanel/Confirmation/ConfirmButton
@onready var cancel_button: Button = $PurchasePanel/Confirmation/CancelButton



var upgrade_buttons: Dictionary = {}
func _ready() -> void:
	close_button.pressed.connect(_on_close_button_pressed)
	purchase_button.pressed.connect(func(): purchase_requested.emit())
	confirm_button.pressed.connect(func(): purchase_confirmed.emit())
	cancel_button.pressed.connect(cancel_purchase_confirmation)
	for child in get_children():
		if child is Button and child != close_button:
			upgrade_buttons[child.name] = child
	for upgrade_id in upgrade_buttons:
		var button: Button = upgrade_buttons[upgrade_id]
		button.toggle_mode = true

		button.pressed.connect(
			func():
				upgrade_requested.emit(upgrade_id)
		)
func set_stars(value: int) -> void:
	stars_label.text = "⭐ %d" % value


func _on_close_button_pressed() -> void:
	cancel_purchase_confirmation()
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
	elif button.button_pressed:
		status_text = "\n\nSELECCIONADA"
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

func set_upgrade_selected(upgrade_id: String, selected: bool) -> void:
	if upgrade_buttons.has(upgrade_id):
		upgrade_buttons[upgrade_id].set_pressed_no_signal(selected)

func set_purchase_summary(count: int, cost: int, stars: int) -> void:
	purchase_button.disabled = count == 0 or cost > stars
	if cost > stars:
		purchase_summary.text = "Seleccionadas: %d · Coste: ⭐ %d\nFaltan ⭐ %d para comprar." % [count, cost, cost - stars]
	else:
		purchase_summary.text = "Seleccionadas: %d · Coste: ⭐ %d\nDespués de comprar: ⭐ %d" % [count, cost, stars - cost]

func show_purchase_status(message: String) -> void:
	purchase_status.text = message

func show_purchase_confirmation(cost: int) -> void:
	confirmation_label.text = "¿Comprar por ⭐ %d?\nSe reiniciará la partida conservando las mejoras permanentes." % cost
	purchase_confirmation.show()
	purchase_button.hide()
	cancel_button.grab_focus()

func cancel_purchase_confirmation() -> void:
	purchase_confirmation.hide()
	purchase_button.show()
