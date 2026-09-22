extends PanelContainer

signal menu_applied(dishes: Array)
signal purchase_requested
var unlocked: Array = DishTypes.default_menu()
var purchase_button: Button
var purchase_result: Label
var locked_list: Label
var selected: Array = []
var menu_capacity: int = DishTypes.MAX_MENU_DISHES
var dish_buttons: Dictionary = {}
var summary: Label
var apply_button: Button

func _ready() -> void:
	position = Vector2(240, 32)
	size = Vector2(470, 580)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Crear la carta"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	summary = Label.new()
	column.add_child(summary)
	purchase_button = Button.new()
	purchase_button.pressed.connect(func(): purchase_requested.emit())
	column.add_child(purchase_button)
	locked_list = Label.new()
	locked_list.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	locked_list.max_lines_visible = 2
	locked_list.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	locked_list.custom_minimum_size.x = 400
	column.add_child(locked_list)
	purchase_result = Label.new()
	column.add_child(purchase_result)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 100
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for dish in DishTypes.CATALOG:
		var button := Button.new()
		button.custom_minimum_size.y = 64
		button.toggle_mode = true
		button.text = DishTypes.title(dish)
		button.icon = DishTypes.texture(dish)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 48)
		button.pressed.connect(_toggle_dish.bind(dish))
		list.add_child(button)
		dish_buttons[dish] = button
	var hint := Label.new()
	hint.text = "Los pedidos ya hechos se mantienen."
	column.add_child(hint)
	apply_button = Button.new()
	apply_button.text = "Aplicar carta"
	apply_button.pressed.connect(_apply)
	column.add_child(apply_button)
	var cancel := Button.new()
	cancel.text = "Cancelar"
	cancel.pressed.connect(hide)
	column.add_child(cancel)
	hide()

func open_menu(dishes: Array) -> void:
	purchase_result.text = ""
	selected = dishes.duplicate()
	_refresh()
	show()
	move_to_front()

func _toggle_dish(dish: int) -> void:
	if not unlocked.has(dish):
		return
	if selected.has(dish):
		selected.erase(dish)
	elif selected.size() < menu_capacity:
		selected.append(dish)
	_refresh()

func _refresh() -> void:
	summary.text = "Seleccionados: %d / %d · Elige al menos uno." % [selected.size(), menu_capacity]
	apply_button.disabled = selected.is_empty()
	for dish in dish_buttons:
		var button: Button = dish_buttons[dish]
		button.visible = unlocked.has(dish)
		button.set_pressed_no_signal(selected.has(dish))
		button.disabled = not selected.has(dish) and selected.size() >= menu_capacity

func _apply() -> void:
	if selected.is_empty() or selected.size() > menu_capacity:
		return
	menu_applied.emit(selected.duplicate())
	hide()

func set_unlocks(dishes: Array, money: float) -> void:
	unlocked = dishes.duplicate()
	var remaining: PackedStringArray = []
	for dish in DishTypes.CATALOG:
		if not unlocked.has(dish):
			remaining.append(DishTypes.title(dish))
	purchase_button.disabled = remaining.is_empty() or money < DishTypes.NEW_DISH_COST
	purchase_button.text = "Todos los platos desbloqueados" if remaining.is_empty() else "Comprar plato aleatorio · %.0f €" % DishTypes.NEW_DISH_COST
	locked_list.text = "Por descubrir: " + ", ".join(remaining) if not remaining.is_empty() else "Colección completa"
	locked_list.tooltip_text = locked_list.text
	_refresh()
