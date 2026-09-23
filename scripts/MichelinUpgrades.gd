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
	_build_tree()
	close_button.pressed.connect(_on_close_button_pressed)
	purchase_button.pressed.connect(func(): purchase_requested.emit())
	confirm_button.pressed.connect(func(): purchase_confirmed.emit())
	cancel_button.pressed.connect(cancel_purchase_confirmation)

var tree_map: Control
var detail_label: Label
var focused_upgrade := ""

func _build_tree() -> void:
	var background := ColorRect.new()
	background.color = Color("10233e")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	move_child(background, 0)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	margin.add_child(layout)
	var header := HBoxContainer.new()
	layout.add_child(header)
	var title := Label.new()
	title.text = "MEJORAS PERMANENTES"
	title.add_theme_font_size_override("font_size", 25)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	stars_label.reparent(header)
	var center := Button.new()
	center.text = "Ver árbol completo"
	header.add_child(center)
	close_button.reparent(header)
	var hint := Label.new()
	hint.text = "Arrastra para explorar · Rueda para ampliar · Clic en un círculo para seleccionar"
	hint.add_theme_color_override("font_color", Color("a3bbd7"))
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	layout.add_child(hint)
	tree_map = preload("res://scripts/ui/UpgradeTreeMap.gd").new()
	tree_map.size_flags_vertical = Control.SIZE_EXPAND_FILL
	tree_map.custom_minimum_size.y = 140
	layout.add_child(tree_map)
	center.pressed.connect(tree_map.fit_tree)
	var positions: Dictionary = {}
	for level in range(1, 12):
		var index := level - 1
		var x := -180 - (index % 6) * 120 if index < 6 else -780 + (index % 6) * 120
		positions["permanent_table_%d" % level] = Vector2(x, -130 if index < 6 else -330)
	for level in range(1, 7):
		positions["permanent_waiter" if level == 1 else "permanent_waiter_%d" % level] = Vector2(180 + (level - 1) * 120, -130 - (level - 1) * 25)
	positions.merge({"waiter_capacity_2": Vector2(180, -330), "player_capacity_2": Vector2(20, -330), "counter_capacity_1": Vector2(-180, 160), "counter_capacity_2": Vector2(-350, 270), "cook_speed_1": Vector2(-520, 160), "menu_capacity_1": Vector2(-690, 270), "permanent_vip": Vector2(180, 160), "vip_spawn_1": Vector2(370, 160), "vip_spawn_2": Vector2(560, 110), "vip_group_2": Vector2(500, 300), "vip_group_3": Vector2(660, 300), "vip_group_4": Vector2(820, 300)})
	for level in range(1, 4):
		positions["staff_training_%d" % level] = Vector2(340 + (level - 1) * 160, 0)
	var rules: Node = preload("res://scripts/MichelinManager.gd").new()
	for id in positions:
		var button: Button = preload("res://scripts/ui/UpgradeTreeNode.gd").new()
		button.position = positions[id] - Vector2(48, 46)
		button.size = Vector2(96, 120)
		button.toggle_mode = true
		button.kind = "table" if id.begins_with("permanent_table") else ("staff" if id.begins_with("permanent_waiter") else ("vip" if "vip" in id else ("menu" if "menu" in id else ("cook" if "cook" in id else "plate"))))
		if id.begins_with("staff_training_"):
			button.kind = "speed"
		button.level = int(id.get_slice("_", id.get_slice_count("_") - 1)) if id != "permanent_waiter" and id != "permanent_vip" else 1
		button.pressed.connect(func():
			focused_upgrade = id
			upgrade_requested.emit(id))
		button.mouse_entered.connect(_show_detail.bind(id))
		button.focus_entered.connect(_show_detail.bind(id))
		tree_map.canvas.add_child(button)
		upgrade_buttons[id] = button
		var requirements: Array = rules.upgrade_requirements[id]
		if requirements.is_empty():
			tree_map.edges.append([Vector2.ZERO, positions[id], id])
		else:
			for required in requirements:
				tree_map.edges.append([positions[required], positions[id], id])
	rules.free()
	tree_map.nodes = upgrade_buttons
	for entry in [["MESAS INICIALES", Vector2(-560, -60)], ["CAMAREROS", Vector2(340, -70)], ["COCINA Y CARTA", Vector2(-570, 370)], ["CLIENTES VIP", Vector2(350, 405)]]:
		var label := Label.new()
		label.text = entry[0]
		label.position = entry[1]
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 22)
		label.add_theme_color_override("font_color", Color("95aecb"))
		tree_map.canvas.add_child(label)
	var footer := HBoxContainer.new()
	footer.add_theme_constant_override("separation", 24)
	layout.add_child(footer)
	detail_label = Label.new()
	detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.text = "Señala un círculo para ver su mejora.\nDorado: seleccionada · Verde: comprada · Azul: bloqueada"
	footer.add_child(detail_label)
	var purchase: VBoxContainer = $PurchasePanel
	purchase.custom_minimum_size.x = 350
	purchase.reparent(footer)
	tree_map.fit_tree.call_deferred()

func _show_detail(id: String) -> void:
	focused_upgrade = id
	if detail_label != null:
		detail_label.text = upgrade_buttons[id].tooltip_text.replace("\n\n", "\n")
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
	button.cost = cost
	button.queue_redraw()

	button.tooltip_text = \
		upgrade_name + "\n\n" + \
		description + "\n\n" + \
		"Coste: ⭐ %d" % cost + \
		status_text
	if focused_upgrade == upgrade_id:
		_show_detail(upgrade_id)
	tree_map.canvas.queue_redraw()
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
