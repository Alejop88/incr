extends PanelContainer

signal menu_applied(dishes: Array)
signal purchase_requested
var unlocked: Array = DishTypes.default_menu()
var purchase_button: Button
var purchase_result: Label
var tag_filter: Button
var filter_popup: PanelContainer
var tag_checkboxes: Array[CheckBox] = []
var filter_scroll: ScrollContainer
var active_tags: PackedStringArray = []
var clear_filter_button: Button
var empty_results: Label
var selected: Array = []
var menu_capacity: int = DishTypes.MAX_MENU_DISHES
var dish_buttons: Dictionary = {}
var summary: Label
var apply_button: Button
var detail_name: Label
var detail_image: TextureRect
var detail_icon: Label
var detail_time: Label
var detail_value: Label
var normal_details: VBoxContainer
var detail_complexity: Label
var detail_effect: Label
var game_mode: String = "cozy"
var detail_tags: HFlowContainer
var inspected_dish: int = DishTypes.Type.NONE
var cooking_time: float = 5.0
var plate_value: float = 5.0

func _ready() -> void:
	position = Vector2(100, 24)
	size = Vector2(940, 580)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	margin.add_child(columns)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 420
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 8)
	columns.add_child(column)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size.x = 400
	detail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	columns.add_child(detail_scroll)
	var details := VBoxContainer.new()
	details.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	details.add_theme_constant_override("separation", 14)
	detail_scroll.add_child(details)
	detail_name = Label.new()
	detail_name.add_theme_font_size_override("font_size", 26)
	detail_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	details.add_child(detail_name)
	detail_image = TextureRect.new()
	detail_image.custom_minimum_size = Vector2(0, 160)
	detail_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	detail_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	details.add_child(detail_image)
	detail_icon = Label.new()
	detail_icon.add_theme_font_size_override("font_size", 90)
	detail_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail_icon.custom_minimum_size.y = 140
	details.add_child(detail_icon)
	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 16)
	details.add_child(stats_row)
	detail_time = Label.new()
	detail_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stats_row.add_child(detail_time)
	detail_value = Label.new()
	detail_value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stats_row.add_child(detail_value)
	normal_details = VBoxContainer.new()
	normal_details.add_theme_constant_override("separation", 10)
	details.add_child(normal_details)
	detail_complexity = Label.new()
	normal_details.add_child(detail_complexity)
	detail_effect = Label.new()
	detail_effect.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	normal_details.add_child(detail_effect)
	normal_details.hide()
	var tags_heading := Label.new()
	tags_heading.text = "ETIQUETAS:"
	details.add_child(tags_heading)
	detail_tags = HFlowContainer.new()
	detail_tags.add_theme_constant_override("h_separation", 8)
	detail_tags.add_theme_constant_override("v_separation", 8)
	details.add_child(detail_tags)
	var title := Label.new()
	title.text = "Crear la carta"
	title.add_theme_font_size_override("font_size", 24)
	column.add_child(title)
	summary = Label.new()
	column.add_child(summary)
	purchase_button = Button.new()
	purchase_button.pressed.connect(func(): purchase_requested.emit())
	column.add_child(purchase_button)
	var filter_row := HBoxContainer.new()
	column.add_child(filter_row)
	tag_filter = Button.new()
	tag_filter.text = "Filtrar etiquetas"
	tag_filter.custom_minimum_size.x = 190
	filter_popup = PanelContainer.new()
	filter_popup.z_index = 100
	filter_popup.set_as_top_level(true)
	add_child(filter_popup)
	filter_popup.hide()
	filter_scroll = ScrollContainer.new()
	filter_scroll.custom_minimum_size = Vector2(260, 280)
	filter_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	filter_popup.add_child(filter_scroll)
	var filter_list := VBoxContainer.new()
	filter_list.add_theme_constant_override("separation", 0)
	filter_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	filter_scroll.add_child(filter_list)
	for tag in DishTypes.all_tags():
		var checkbox := CheckBox.new()
		checkbox.text = tag
		checkbox.custom_minimum_size.y = 28
		checkbox.add_theme_font_size_override("font_size", 16)
		for state in ["normal", "hover", "pressed", "hover_pressed"]:
			checkbox.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		checkbox.pressed.connect(_filter_by_tag.bind(tag_checkboxes.size()))
		filter_list.add_child(checkbox)
		tag_checkboxes.append(checkbox)
	tag_filter.pressed.connect(func():
		if filter_popup.visible:
			filter_popup.hide()
		else:
			filter_popup.size = Vector2(280, 288)
			filter_popup.global_position = tag_filter.global_position + Vector2(0, tag_filter.size.y)
			filter_popup.show())
	filter_row.add_child(tag_filter)
	clear_filter_button = Button.new()
	clear_filter_button.text = "Limpiar"
	clear_filter_button.pressed.connect(_clear_filters)
	filter_row.add_child(clear_filter_button)
	empty_results = Label.new()
	empty_results.text = "No tienes platos con todas estas etiquetas."
	column.add_child(empty_results)
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
	visibility_changed.connect(func():
		if not visible:
			filter_popup.hide())
	_update_available_tags()
	hide()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not filter_popup.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		if not filter_popup.get_global_rect().has_point(event.position) and not tag_filter.get_global_rect().has_point(event.position):
			filter_popup.hide()

func open_menu(dishes: Array) -> void:
	active_tags.clear()
	_update_filter_button()
	purchase_result.text = ""
	selected = dishes.duplicate()
	show_dish_info(int(dishes[0]) if not dishes.is_empty() else DishTypes.Type.NONE)
	_refresh()
	show()
	move_to_front()

func _toggle_dish(dish: int) -> void:
	if not unlocked.has(dish):
		return
	show_dish_info(dish)
	if selected.has(dish):
		selected.erase(dish)
	elif selected.size() < menu_capacity:
		selected.append(dish)
	_refresh()

func _refresh() -> void:
	summary.text = "Seleccionados: %d / %d · Elige al menos uno." % [selected.size(), menu_capacity]
	apply_button.disabled = selected.is_empty()
	var visible_count := 0
	for dish in dish_buttons:
		var button: Button = dish_buttons[dish]
		button.visible = unlocked.has(dish) and _matches_tags(dish)
		if button.visible:
			visible_count += 1
		button.set_pressed_no_signal(selected.has(dish))
		# Full menus still allow inspecting dishes; _toggle_dish enforces capacity.
		button.disabled = false
	empty_results.visible = visible_count == 0

func _filter_by_tag(index: int) -> void:
	if not tag_checkboxes[index].visible:
		return
	var tag: String = tag_checkboxes[index].text
	if active_tags.has(tag):
		active_tags.remove_at(active_tags.find(tag))
	else:
		active_tags.append(tag)
	_update_filter_button()
	_refresh_filtered_details()

func _matches_tags(dish: int) -> bool:
	var tags := DishTypes.tags(dish)
	for tag in active_tags:
		if not tags.has(tag):
			return false
	return true

func _clear_filters() -> void:
	active_tags.clear()
	_update_filter_button()
	_refresh_filtered_details()

func _update_filter_button() -> void:
	tag_filter.text = "Filtrar etiquetas" if active_tags.is_empty() else "Etiquetas (%d)" % active_tags.size()
	tag_filter.tooltip_text = "Deben coincidir todas las etiquetas seleccionadas.\n" + ", ".join(active_tags)
	clear_filter_button.disabled = active_tags.is_empty()
	for checkbox in tag_checkboxes:
		checkbox.set_pressed_no_signal(active_tags.has(checkbox.text))

func _refresh_filtered_details() -> void:
	_refresh()
	if dish_buttons.has(inspected_dish) and dish_buttons[inspected_dish].visible:
		return
	for dish in dish_buttons:
		if dish_buttons[dish].visible:
			show_dish_info(dish)
			return
	show_dish_info(DishTypes.Type.NONE)

func _apply() -> void:
	if selected.is_empty() or selected.size() > menu_capacity:
		return
	menu_applied.emit(selected.duplicate())
	hide()

func set_unlocks(dishes: Array, money: float) -> void:
	var changed: bool = unlocked != dishes
	unlocked = dishes.duplicate()
	if changed:
		_update_available_tags()
	var remaining: PackedStringArray = []
	for dish in DishTypes.CATALOG:
		if not unlocked.has(dish):
			remaining.append(DishTypes.title(dish))
	purchase_button.disabled = remaining.is_empty() or money < DishTypes.NEW_DISH_COST
	purchase_button.text = "Todos los platos desbloqueados" if remaining.is_empty() else "Comprar plato aleatorio · %.0f €" % DishTypes.NEW_DISH_COST
	_refresh()

func _update_available_tags() -> void:
	var available := PackedStringArray()
	for dish in unlocked:
		for tag in DishTypes.tags(dish):
			if not available.has(tag):
				available.append(tag)
	for checkbox in tag_checkboxes:
		checkbox.visible = available.has(checkbox.text)
	for tag in active_tags.duplicate():
		if not available.has(tag):
			active_tags.remove_at(active_tags.find(tag))
	_update_filter_button()

func set_dish_stats(time: float, value: float) -> void:
	cooking_time = time
	plate_value = value
	_update_detail_stats()

func set_game_mode(mode: String) -> void:
	game_mode = mode
	_update_normal_details()

func _update_normal_details() -> void:
	if normal_details == null:
		return
	var entry: Dictionary = DishTypes.CATALOG.get(inspected_dish, {})
	normal_details.visible = game_mode == "normal" and not entry.is_empty()
	detail_complexity.text = "COMPLEJIDAD: " + str(entry.get("complexity", "Por definir"))
	detail_effect.text = "CARACTERÍSTICA (todavía no activa):\n" + str(entry.get("effect_description", "Este plato todavía no tiene una característica definida."))

func _update_detail_stats() -> void:
	if detail_time != null:
		detail_time.text = "TIEMPO: %.1f s" % cooking_time
		detail_time.tooltip_text = "Tiempo de cocinado"
		detail_value.text = "VALOR: %.1f €" % plate_value

func show_dish_info(dish: int) -> void:
	inspected_dish = dish
	_update_normal_details()
	var entry: Dictionary = DishTypes.CATALOG.get(dish, {})
	detail_name.text = str(entry.get("name", "Selecciona un plato")).to_upper()
	detail_image.texture = DishTypes.texture(dish)
	detail_image.visible = detail_image.texture != null
	detail_icon.visible = detail_image.texture == null
	detail_icon.text = str(entry.get("icon", ""))
	_update_detail_stats()
	detail_time.visible = not entry.is_empty()
	detail_value.visible = not entry.is_empty()
	var tags: PackedStringArray = DishTypes.tags(dish)
	for child in detail_tags.get_children():
		detail_tags.remove_child(child)
		child.queue_free()
	if tags.is_empty():
		tags.append("Sin etiquetas todavía")
	for tag in tags:
		var chip := PanelContainer.new()
		chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = Color("304840")
		style.set_corner_radius_all(8)
		style.content_margin_left = 10
		style.content_margin_right = 10
		style.content_margin_top = 5
		style.content_margin_bottom = 5
		chip.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.text = tag
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(label)
		detail_tags.add_child(chip)
