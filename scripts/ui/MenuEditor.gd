extends PanelContainer

signal menu_applied(dishes: Array)
var selected: Array = []
var dish_buttons: Dictionary = {}
var summary: Label
var apply_button: Button

func _ready() -> void:
	position = Vector2(240, 70)
	size = Vector2(470, 460)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Crear la carta"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	summary = Label.new()
	column.add_child(summary)
	var scroll := ScrollContainer.new()
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
	selected = dishes.duplicate()
	_refresh()
	show()
	move_to_front()

func _toggle_dish(dish: int) -> void:
	if not DishTypes.CATALOG.has(dish):
		return
	if selected.has(dish):
		selected.erase(dish)
	elif selected.size() < DishTypes.MAX_MENU_DISHES:
		selected.append(dish)
	_refresh()

func _refresh() -> void:
	summary.text = "Seleccionados: %d / %d · Elige al menos uno." % [selected.size(), DishTypes.MAX_MENU_DISHES]
	apply_button.disabled = selected.is_empty()
	for dish in dish_buttons:
		var button: Button = dish_buttons[dish]
		button.set_pressed_no_signal(selected.has(dish))
		button.disabled = not selected.has(dish) and selected.size() >= DishTypes.MAX_MENU_DISHES

func _apply() -> void:
	if selected.is_empty() or selected.size() > DishTypes.MAX_MENU_DISHES:
		return
	menu_applied.emit(selected.duplicate())
	hide()
