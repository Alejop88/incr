extends "res://tests/test_automatic_waiters.gd"

func run_tests() -> void:
	var r: Node = world()
	check(not r.set_menu_dishes([]), "Empty menu must be rejected")
	check(not r.set_menu_dishes([BURGER, BURGER]), "Duplicate dishes must be rejected")
	check(not r.set_menu_dishes([BURGER, PIZZA, NONE]), "More than two dishes must be rejected")
	check(r.set_menu_dishes([PIZZA]), "Single dish menu is valid")
	r.vip_spawn_chance = 0.0
	r.spawn_customer()
	for child in r.get_children():
		if child.has_method("get_customers"):
			for customer in child.get_customers():
				check(customer.requested_dish == PIZZA, "New customers must order from the selected menu")
	var group: Node = seat(r, "Table02Point", [BURGER], true)
	var vip: Node = group.get_customer(0)
	check(r.get_available_manual_dishes().has(BURGER), "Existing off-menu orders must remain cookable")
	for i in range(10):
		check(vip.prepare_next_dish(r.menu_dishes) == PIZZA, "VIP next rounds must use the current menu")
	check(not r.get_available_manual_dishes().has(BURGER), "Old dish must disappear once no outstanding customer needs it")
	check(DishTypes.menu_from_keys(["PIZZA"]) == [PIZZA], "Menu persistence must use stable keys")
	check(DishTypes.menu_from_keys(["REMOVED"]) == DishTypes.default_menu(), "Unknown old menu must recover a valid default")
	r.free()
	var editor: Node = load("res://scripts/ui/MenuEditor.gd").new()
	root.add_child(editor)
	editor.open_menu([BURGER, PIZZA])
	await process_frame
	await process_frame
	check(editor.get_theme_stylebox("panel").bg_color.a == 1.0, "Menu window background is fully opaque")
	var pending_apply := {"count": 0}
	editor.menu_applied.connect(func(_dishes): pending_apply.count += 1)
	editor._toggle_dish(BURGER)
	editor.close_button.pressed.emit()
	check(not editor.visible and pending_apply.count == 0, "Close X hides without applying draft")
	editor.open_menu([BURGER, PIZZA])
	check(not editor.normal_details.visible, "Cozy must keep the original dish details")
	editor.set_game_mode("normal")
	await process_frame
	await process_frame
	check(editor.active_traits_panel.get_global_rect().end.x <= editor.selected_cards[BURGER].card.get_global_rect().position.x, "Benefits have their own column to the left of dishes")
	check(editor.close_button.get_global_rect().end.x > editor.selected_cards[BURGER].card.get_global_rect().end.x, "Close X is at the upper right")
	check(editor.get_global_rect().position.x >= 0 and editor.get_global_rect().end.x <= editor.get_viewport_rect().size.x + 1, "Three columns fit the viewport")
	editor.show_dish_info(DishTypes.Type.GAZPACHO)
	check(editor.normal_details.visible and editor.detail_complexity.text.contains("Por definir"), "Normal displays the future complexity field")
	check(editor.detail_effect.text.contains("todavía no tiene una característica definida"), "New recipes have no invented individual characteristic")
	check(editor.plate_value == 5.0 and editor.cooking_time == 5.0, "Informational features must not change price or cooking")
	check(DishTypes.implemented_tags().size() == 28, "All twenty-eight tag effects are defined")
	for tag in DishTypes.implemented_tags():
		var tooltip := DishTypes.tag_tooltip(tag)
		check(tooltip.contains("modo Normal"), "Tooltip describes implemented effects: " + tag)
		for line in tooltip.split("\n"):
			check(line.length() <= 58, "Long descriptions must wrap to a readable width")
	check(DishTypes.tag_tooltip("Frito") == DishTypes.tag_tooltip("Fritura"), "Fried tag variants share the same effect")
	check(DishTypes.tag_tooltip("Peru") == DishTypes.tag_tooltip("Peruana"), "Peruvian tag variants share the same effect")
	check(DishTypes.tag_tooltip("Tradicional").is_empty(), "Undefined effects must not be invented")
	for chip in editor.detail_tags.get_children():
		check(chip.tooltip_text == DishTypes.tag_tooltip(chip.get_child(0).text), "Normal detail tags display their effect")
		check(chip.mouse_filter == Control.MOUSE_FILTER_PASS, "Detail tags accept hover while preserving scrolling")
	for checkbox in editor.tag_checkboxes:
		check(checkbox.tooltip_text == DishTypes.tag_tooltip(checkbox.text), "Normal filter tags display their effect")
	editor.set_game_mode("cozy")
	for chip in editor.detail_tags.get_children():
		check(chip.tooltip_text.is_empty(), "Switching to Cozy clears existing detail tooltips")
	for checkbox in editor.tag_checkboxes:
		check(checkbox.tooltip_text.is_empty(), "Switching to Cozy clears filter tooltips")
	editor.set_game_mode("normal")
	for chip in editor.detail_tags.get_children():
		check(chip.tooltip_text == DishTypes.tag_tooltip(chip.get_child(0).text), "Switching back restores tooltips without rebuilding tags")
	editor.set_game_mode("cozy")
	check(not editor.normal_details.visible, "Returning to Cozy hides complexity and traits")
	editor.show_dish_info(BURGER)
	for chip in editor.detail_tags.get_children():
		check(chip.tooltip_text.is_empty(), "Newly inspected Cozy dishes have no effect tooltips")
	check(editor.detail_image.visible and not editor.detail_icon.visible, "Burger details use its image")
	editor.set_unlocks([BURGER, PIZZA, DishTypes.Type.PAELLA], 0)
	editor.dish_buttons[DishTypes.Type.PAELLA].pressed.emit()
	check(editor.detail_name.text == "PAELLA" and editor.selected == [BURGER, PIZZA], "Full menu must still allow inspecting another dish without adding it")
	check(editor.detail_icon.visible and not editor.detail_image.visible, "Dishes without textures use their icon")
	var displayed_tags: Array[String] = []
	for chip in editor.detail_tags.get_children():
		displayed_tags.append(chip.get_child(0).text)
	check(displayed_tags == ["Arroz", "Marisco", "Pescado", "Española", "Para compartir"], "Paella must show the requested tags in order")
	editor.set_dish_stats(4.6, 6.0)
	check(editor.detail_time.text.contains("4.6 s") and editor.detail_value.text.contains("6.0 €"), "Details display current cooking time and price")
	check(DishTypes.tags(DishTypes.Type.GAZPACHO).has("Fría") and DishTypes.tags(DishTypes.Type.NIGIRI).has("Fría"), "Shared tags must use a consistent gender")
	check(not DishTypes.all_tags().has("Frío"), "Filter must not contain duplicate gender variants")
	for index in range(editor.tag_checkboxes.size()):
		if editor.tag_checkboxes[index].text == "Arroz":
			editor.tag_checkboxes[index].set_pressed_no_signal(false)
			editor.tag_checkboxes[index].pressed.emit()
	check(editor.dish_buttons[DishTypes.Type.PAELLA].visible and not editor.dish_buttons[BURGER].visible and not editor.dish_buttons[PIZZA].visible, "Rice filter shows only matching unlocked dishes")
	check(editor.selected == [BURGER, PIZZA], "Filtering must preserve selected dishes that become hidden")
	for index in range(editor.tag_checkboxes.size()):
		if editor.tag_checkboxes[index].text == "Pescado":
			editor.tag_checkboxes[index].pressed.emit()
	check(editor.active_tags.size() == 2 and editor.dish_buttons[DishTypes.Type.PAELLA].visible and not editor.dish_buttons[PIZZA].visible, "Combined filters require both rice and fish tags")
	check(editor.filter_scroll.custom_minimum_size.y == 280, "Filter popup height must remain compact")
	editor.tag_filter.pressed.emit()
	await process_frame
	await process_frame
	check(editor.filter_scroll.size.y <= 290, "Opening filter must not expand to fit the entire tag list")
	check(editor.filter_scroll.get_v_scroll_bar().max_value > editor.filter_scroll.size.y, "Remaining tags must be reachable by scrolling")
	editor.tag_filter.pressed.emit()
	check(not editor.filter_popup.visible and editor.active_tags.size() == 2, "Second click must close filter without clearing selections")
	editor.tag_filter.pressed.emit()
	check(editor.filter_popup.visible and editor.active_tags.size() == 2, "Reopening preserves selected tags")
	editor.tag_filter.pressed.emit()
	for index in range(editor.tag_checkboxes.size()):
		if editor.tag_checkboxes[index].text == "Japonesa":
			check(not editor.tag_checkboxes[index].visible, "Tags belonging only to locked dishes must be hidden")
		if editor.tag_checkboxes[index].text == "Estadounidense":
			editor.tag_checkboxes[index].pressed.emit()
	check(editor.empty_results.visible, "Tags without unlocked matches show an empty state")
	editor.clear_filter_button.pressed.emit()
	check(editor.selected_cards.has(BURGER) and editor.dish_buttons[DishTypes.Type.PAELLA].visible and not editor.empty_results.visible, "Clearing filters restores available dishes while keeping the menu separate")
	editor.set_unlocks([BURGER, PIZZA, DishTypes.Type.PAELLA, DishTypes.Type.NIGIRI], 0)
	for checkbox in editor.tag_checkboxes:
		if checkbox.text == "Japonesa":
			check(checkbox.visible, "Unlocking a new dish makes its tags available")
	editor._toggle_dish(NONE)
	check(editor.selected == [BURGER, PIZZA], "A third selection must not exceed the cap")
	editor._toggle_dish(BURGER)
	check(not editor.dish_buttons[BURGER].disabled, "Freeing a slot enables other dishes")
	editor._toggle_dish(PIZZA)
	check(editor.apply_button.disabled, "An empty selection cannot be applied")
	editor._toggle_dish(BURGER)
	check(not editor.apply_button.disabled, "One selected dish can be applied")
	editor.open_menu([PIZZA])
	check(editor.selected == [PIZZA], "Reopening discards unapplied changes")
	check(editor.selected_grid.get_child_count() == 2 and editor.selected_cards.size() == 1, "Menu shows selected dishes and empty slots")
	editor.selected_cards[PIZZA].inspect.pressed.emit()
	editor.dish_buttons[BURGER].pressed.emit()
	check(editor.selected == [PIZZA], "Inspecting either section never changes the menu")
	editor.search_field.text = "  PÁELLA  "
	editor.search_field.text_changed.emit(editor.search_field.text)
	check(editor.dish_rows[DishTypes.Type.PAELLA].visible and not editor.dish_rows[BURGER].visible, "Name search ignores case, accents and outer spaces")
	check(editor.selected_cards[PIZZA].card.visible, "Selected dishes remain visible during searches")
	editor.add_buttons[DishTypes.Type.PAELLA].pressed.emit()
	check(editor.selected == [PIZZA, DishTypes.Type.PAELLA] and not editor.dish_rows[DishTypes.Type.PAELLA].visible, "Adding moves a dish into the menu section")
	check(editor.add_buttons[BURGER].disabled, "Full menus disable adding but allow inspection")
	editor._add_dish(BURGER)
	check(editor.selected.size() == 2, "Add action enforces capacity")
	editor.selected_cards[PIZZA].remove.pressed.emit()
	check(editor.selected == [DishTypes.Type.PAELLA] and not editor.add_buttons[BURGER].disabled, "Explicit remove frees a slot")
	editor.menu_capacity = 6
	editor.search_field.text = ""
	editor._refresh()
	await process_frame
	await process_frame
	check(editor.selected_grid.get_child_count() == 6, "Expanded menus show all six slots")
	check(editor.get_global_rect().end.y <= editor.get_viewport_rect().size.y + 1, "Six-slot editor fits vertically")
	editor.free()
	var game: Node = load("res://scenes/Main.tscn").instantiate()
	game.get_node("SaveManager").save_path = "res://tests/menu-unused-%s.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.restaurant.unlocked_dishes = DishTypes.default_menu()
	game.restaurant.set_menu_dishes(DishTypes.default_menu())
	game.hud.get_node("KitchenPanel/VBoxContainer/MenuButton").pressed.emit()
	check(game.hud.menu_editor.visible, "Kitchen menu button must open the editor")
	game.hud.menu_editor._toggle_dish(BURGER)
	game.hud.menu_editor.apply_button.pressed.emit()
	check(game.restaurant.menu_dishes == [PIZZA], "Apply button must update the actual restaurant menu")
	game.free()
	print("MENU TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
