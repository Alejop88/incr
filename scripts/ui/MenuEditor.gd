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
var active_traits_panel: PanelContainer
var active_traits_list: VBoxContainer
var active_traits_empty: Label
var active_trait_labels: Dictionary = {}
var close_button: Button
var selected_grid: GridContainer
var selected_cards: Dictionary = {}
var dish_rows: Dictionary = {}
var add_buttons: Dictionary = {}
var search_field: LineEdit
var available_heading: Label
var last_selection: Array = []
var last_capacity: int = -1

func _ready() -> void:
	# Tooltip popups inherit this local theme, including tags in the filter.
	theme = Theme.new()
	var tooltip_style := StyleBoxFlat.new()
	tooltip_style.bg_color = Color("17231f")
	tooltip_style.border_color = Color("759c87")
	tooltip_style.set_border_width_all(1)
	tooltip_style.set_corner_radius_all(6)
	tooltip_style.content_margin_left = 14
	tooltip_style.content_margin_right = 14
	tooltip_style.content_margin_top = 10
	tooltip_style.content_margin_bottom = 10
	theme.set_stylebox("panel", "TooltipPanel", tooltip_style)
	theme.set_color("font_color", "TooltipLabel", Color.WHITE)
	theme.set_font_size("font_size", "TooltipLabel", 16)
	var window_style := StyleBoxFlat.new()
	window_style.bg_color = Color("17231f")
	window_style.border_color = Color("759c87")
	window_style.set_border_width_all(1)
	window_style.set_corner_radius_all(12)
	add_theme_stylebox_override("panel", window_style)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 16)
	add_child(margin)
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 12)
	margin.add_child(body)
	var header := HBoxContainer.new()
	body.add_child(header)
	var header_space := Control.new()
	header_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_space)
	close_button = Button.new()
	close_button.text = "×"
	close_button.tooltip_text = "Cerrar sin aplicar cambios"
	close_button.custom_minimum_size = Vector2(36, 36)
	close_button.add_theme_font_size_override("font_size", 24)
	close_button.pressed.connect(hide)
	header.add_child(close_button)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 16)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	body.add_child(columns)
	var column := VBoxContainer.new()
	column.custom_minimum_size.x = 390
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 4)
	var compact_theme := Theme.new()
	compact_theme.default_font_size = 14
	column.theme = compact_theme
	columns.add_child(column)
	var detail_scroll := ScrollContainer.new()
	detail_scroll.custom_minimum_size.x = 350
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
	detail_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	title.add_theme_font_size_override("font_size", 20)
	column.add_child(title)
	summary = Label.new()
	summary.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(summary)
	selected_grid = GridContainer.new()
	selected_grid.columns = 2
	selected_grid.add_theme_constant_override("h_separation", 8)
	selected_grid.add_theme_constant_override("v_separation", 4)
	column.add_child(selected_grid)
	active_traits_panel = PanelContainer.new()
	var traits_style := StyleBoxFlat.new()
	traits_style.bg_color = Color("20382d")
	traits_style.set_corner_radius_all(8)
	traits_style.content_margin_left = 12
	traits_style.content_margin_right = 12
	traits_style.content_margin_top = 10
	traits_style.content_margin_bottom = 10
	active_traits_panel.add_theme_stylebox_override("panel", traits_style)
	active_traits_panel.custom_minimum_size.x = 240
	columns.add_child(active_traits_panel)
	columns.move_child(active_traits_panel, 0)
	active_traits_list = VBoxContainer.new()
	active_traits_list.add_theme_constant_override("separation", 6)
	active_traits_panel.add_child(active_traits_list)
	var traits_title := Label.new()
	traits_title.text = "ETIQUETAS ACTIVAS"
	traits_title.add_theme_color_override("font_color", Color("a8edbd"))
	active_traits_list.add_child(traits_title)
	var traits_hint := Label.new()
	traits_hint.text = "Vista previa · Se activan al aplicar la carta"
	traits_hint.add_theme_font_size_override("font_size", 13)
	traits_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active_traits_list.add_child(traits_hint)
	active_traits_empty = Label.new()
	active_traits_empty.text = "Ninguna característica cumplida."
	active_traits_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	active_traits_list.add_child(active_traits_empty)
	var trait_scroll := ScrollContainer.new()
	trait_scroll.custom_minimum_size.y = 90
	trait_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	trait_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	active_traits_list.add_child(trait_scroll)
	var trait_rows := VBoxContainer.new()
	trait_rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	trait_scroll.add_child(trait_rows)
	for tag in DishTypes.implemented_tags():
		var effect_label := Label.new()
		effect_label.mouse_filter = Control.MOUSE_FILTER_PASS
		effect_label.tooltip_text = DishTypes.tag_tooltip(tag)
		effect_label.add_theme_font_size_override("font_size", 15)
		effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		trait_rows.add_child(effect_label)
		active_trait_labels[tag] = effect_label
	_update_active_traits()
	purchase_button = Button.new()
	purchase_button.pressed.connect(func(): purchase_requested.emit())
	column.add_child(purchase_button)
	available_heading = Label.new()
	available_heading.text = "PLATOS DISPONIBLES"
	column.add_child(available_heading)
	search_field = LineEdit.new()
	search_field.placeholder_text = "Buscar un plato por nombre…"
	search_field.clear_button_enabled = true
	search_field.text_changed.connect(func(_text): _refresh_filtered_details())
	column.add_child(search_field)
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
		checkbox.tooltip_text = DishTypes.tag_tooltip(tag) if game_mode == "normal" else ""
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
			var button_rect := tag_filter.get_global_rect()
			var available := get_viewport_rect().size
			filter_popup.global_position = Vector2(
				clampf(button_rect.position.x, 0, maxf(0, available.x - filter_popup.size.x)),
				clampf(button_rect.end.y, 0, maxf(0, available.y - filter_popup.size.y)))
			filter_popup.show())
	filter_row.add_child(tag_filter)
	clear_filter_button = Button.new()
	clear_filter_button.text = "Limpiar"
	clear_filter_button.pressed.connect(_clear_filters)
	filter_row.add_child(clear_filter_button)
	empty_results = Label.new()
	empty_results.text = "No tienes platos con todas estas etiquetas."
	empty_results.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(empty_results)
	purchase_result = Label.new()
	purchase_result.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(purchase_result)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 180
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)
	var list := VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(list)
	for dish in DishTypes.CATALOG:
		var row := HBoxContainer.new()
		list.add_child(row)
		dish_rows[dish] = row
		var button := Button.new()
		button.custom_minimum_size.y = 34
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.text = DishTypes.title(dish)
		button.tooltip_text = DishTypes.title(dish) + " · Ver ficha"
		button.icon = DishTypes.texture(dish)
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 24)
		button.pressed.connect(show_dish_info.bind(dish))
		row.add_child(button)
		dish_buttons[dish] = button
		var add := Button.new()
		add.text = "+ Añadir"
		add.pressed.connect(_add_dish.bind(dish))
		row.add_child(add)
		add_buttons[dish] = add
	var hint := Label.new()
	hint.text = "Los pedidos ya hechos se mantienen."
	hint.add_theme_font_size_override("font_size", 12)
	column.add_child(hint)
	var actions := HBoxContainer.new()
	column.add_child(actions)
	apply_button = Button.new()
	apply_button.text = "Aplicar carta"
	apply_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	apply_button.pressed.connect(_apply)
	actions.add_child(apply_button)
	var cancel := Button.new()
	cancel.text = "Cancelar"
	cancel.pressed.connect(hide)
	actions.add_child(cancel)
	visibility_changed.connect(func():
		if not visible:
			filter_popup.hide())
	_update_available_tags()
	get_viewport().size_changed.connect(_fit_window)
	minimum_size_changed.connect(_fit_window)
	_fit_window.call_deferred()
	hide()

func _fit_window() -> void:
	if not is_inside_tree():
		return
	var viewport_size := get_viewport_rect().size
	size = Vector2(1120, clampf(viewport_size.y - 48, 600, 800)).max(get_combined_minimum_size())
	var factor := minf(1.0, minf(maxf(1, viewport_size.x - 32) / size.x, maxf(1, viewport_size.y - 32) / size.y))
	scale = Vector2.ONE * factor
	position = (viewport_size - size * factor) / 2.0

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not filter_popup.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		if not filter_popup.get_global_rect().has_point(event.position) and not tag_filter.get_global_rect().has_point(event.position):
			filter_popup.hide()

func open_menu(dishes: Array) -> void:
	active_tags.clear()
	search_field.text = ""
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

func _add_dish(dish: int) -> void:
	if selected.has(dish) or selected.size() >= menu_capacity:
		return
	_toggle_dish(dish)

func _remove_dish(dish: int) -> void:
	if selected.has(dish):
		_toggle_dish(dish)

func _refresh_selected_cards() -> void:
	if selected == last_selection and menu_capacity == last_capacity:
		return
	last_selection = selected.duplicate()
	last_capacity = menu_capacity
	selected_grid.columns = 3 if menu_capacity > 6 else 2
	selected_cards.clear()
	for child in selected_grid.get_children():
		selected_grid.remove_child(child)
		child.queue_free()
	for index in range(menu_capacity):
		var card := PanelContainer.new()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.custom_minimum_size.y = 32
		var style := StyleBoxFlat.new()
		style.bg_color = Color("284d3b") if index < selected.size() else Color("1c2d25")
		style.border_color = Color("75b88e") if index < selected.size() else Color("3b5146")
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		card.add_theme_stylebox_override("panel", style)
		selected_grid.add_child(card)
		if index >= selected.size():
			var empty := Label.new()
			empty.text = "+ Hueco libre"
			empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			empty.add_theme_color_override("font_color", Color("9bad9f"))
			card.add_child(empty)
			continue
		var dish: int = selected[index]
		var row := HBoxContainer.new()
		card.add_child(row)
		var inspect := Button.new()
		inspect.flat = true
		inspect.text = DishTypes.title(dish)
		inspect.icon = DishTypes.texture(dish)
		inspect.expand_icon = true
		inspect.add_theme_constant_override("icon_max_width", 22)
		inspect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		inspect.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		inspect.tooltip_text = DishTypes.title(dish) + " · Ver ficha"
		inspect.pressed.connect(show_dish_info.bind(dish))
		row.add_child(inspect)
		var remove := Button.new()
		remove.text = "×"
		remove.tooltip_text = "Quitar " + str(DishTypes.CATALOG[dish].name) + " de la carta"
		remove.pressed.connect(_remove_dish.bind(dish))
		row.add_child(remove)
		selected_cards[dish] = {"card": card, "inspect": inspect, "remove": remove}

func _refresh() -> void:
	_update_active_traits()
	_refresh_selected_cards()
	summary.text = "TU CARTA · %d / %d" % [selected.size(), menu_capacity]
	summary.text += " · Completa" if selected.size() >= menu_capacity else " · Huecos libres"
	summary.tooltip_text = "Quita un plato con × para liberar un hueco. Añade platos desde la lista de abajo."
	purchase_result.visible = not purchase_result.text.is_empty()
	apply_button.disabled = selected.is_empty()
	var visible_count := 0
	for dish in dish_buttons:
		var button: Button = dish_buttons[dish]
		button.visible = unlocked.has(dish) and not selected.has(dish) and _matches_tags(dish)
		dish_rows[dish].visible = button.visible
		if button.visible:
			visible_count += 1
		add_buttons[dish].disabled = selected.size() >= menu_capacity
		add_buttons[dish].tooltip_text = "Quita un plato de Tu carta para liberar un hueco." if selected.size() >= menu_capacity else "Añadir a Tu carta"
		button.disabled = false
	empty_results.visible = visible_count == 0
	empty_results.text = "No hay platos disponibles con esta búsqueda." if not search_field.text.is_empty() or not active_tags.is_empty() else "Todos tus platos desbloqueados están en Tu carta."
	available_heading.text = "PLATOS DISPONIBLES · %d" % visible_count

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
	var query := _search_text(search_field.text.strip_edges())
	if not query.is_empty() and not _search_text(str(DishTypes.CATALOG[dish].name)).contains(query):
		return false
	var tags := DishTypes.tags(dish)
	for tag in active_tags:
		if not tags.has(tag):
			return false
	return true

func _search_text(value: String) -> String:
	return value.to_lower().replace("á", "a").replace("é", "e").replace("í", "i").replace("ó", "o").replace("ú", "u").replace("ü", "u")

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
	if selected.has(inspected_dish) or (dish_buttons.has(inspected_dish) and dish_buttons[inspected_dish].visible):
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
	if game_mode == mode:
		return
	game_mode = mode
	_update_normal_details()
	_update_active_traits()
	for checkbox in tag_checkboxes:
		checkbox.tooltip_text = DishTypes.tag_tooltip(checkbox.text) if game_mode == "normal" else ""
	if detail_tags != null:
		for chip in detail_tags.get_children():
			chip.tooltip_text = DishTypes.tag_tooltip(str(chip.get_meta("tag", ""))) if game_mode == "normal" else ""

func _update_active_traits() -> void:
	if active_traits_panel == null:
		return
	active_traits_panel.visible = game_mode == "normal"
	var effects: Dictionary = preload("res://scripts/MenuTraits.gd").calculate(game_mode, selected)
	active_traits_empty.visible = effects.active_tags.is_empty()
	for tag in active_trait_labels:
		active_trait_labels[tag].visible = effects.active_tags.has(tag)
		active_trait_labels[tag].text = tag + " · " + str(effects.descriptions.get(tag, ""))
	_update_detail_stats()

func _update_normal_details() -> void:
	if normal_details == null:
		return
	var entry: Dictionary = DishTypes.CATALOG.get(inspected_dish, {})
	normal_details.visible = game_mode == "normal" and not entry.is_empty()
	detail_complexity.text = "COMPLEJIDAD: " + str(entry.get("complexity", "Por definir"))
	detail_effect.text = "CARACTERÍSTICA (todavía no activa):\n" + str(entry.get("effect_description", "Este plato todavía no tiene una característica definida."))

func _update_detail_stats() -> void:
	if detail_time != null:
		var effects: Dictionary = preload("res://scripts/MenuTraits.gd").calculate(game_mode, selected)
		var speed: float = preload("res://scripts/MenuTraits.gd").dish_cooking_speed(inspected_dish, effects)
		detail_time.text = "TIEMPO: %.1f s" % (cooking_time / speed)
		detail_time.tooltip_text = "Tiempo con la carta seleccionada; no incluye repeticiones de una mesa." if game_mode == "normal" else "Tiempo de cocinado"
		var multiplier: float = preload("res://scripts/MenuTraits.gd").dish_value_multiplier(inspected_dish, effects)
		detail_value.text = ("VALOR: %.2f €" if game_mode == "normal" else "VALOR: %.1f €") % (plate_value * multiplier)
		detail_value.tooltip_text = "Valor con la carta seleccionada; se activa al aplicar." if game_mode == "normal" else "Valor del plato"

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
		chip.mouse_filter = Control.MOUSE_FILTER_PASS
		chip.set_meta("tag", tag)
		chip.tooltip_text = DishTypes.tag_tooltip(tag) if game_mode == "normal" else ""
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
