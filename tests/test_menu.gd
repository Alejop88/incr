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
	check(not editor.normal_details.visible, "Cozy must keep the original dish details")
	editor.set_game_mode("normal")
	editor.show_dish_info(DishTypes.Type.SALAD)
	check(editor.normal_details.visible and editor.detail_complexity.text.contains("Por definir"), "Normal displays the future complexity field")
	check(editor.detail_effect.text.contains("5 %") and editor.detail_effect.text.contains("todavía no activa"), "Salad describes its future vegetarian bonus as inactive")
	check(editor.plate_value == 5.0 and editor.cooking_time == 5.0, "Informational features must not change price or cooking")
	editor.set_game_mode("cozy")
	check(not editor.normal_details.visible, "Returning to Cozy hides complexity and traits")
	editor.show_dish_info(BURGER)
	check(editor.detail_image.visible and not editor.detail_icon.visible, "Burger details use its image")
	editor.set_unlocks([BURGER, PIZZA, DishTypes.Type.PAELLA], 0)
	editor.dish_buttons[DishTypes.Type.PAELLA].pressed.emit()
	check(editor.detail_name.text == "PAELLA" and editor.selected == [BURGER, PIZZA], "Full menu must still allow inspecting another dish without adding it")
	check(editor.detail_icon.visible and not editor.detail_image.visible, "Dishes without textures use their icon")
	var displayed_tags: Array[String] = []
	for chip in editor.detail_tags.get_children():
		displayed_tags.append(chip.get_child(0).text)
	check(displayed_tags == ["Mediterránea", "Arroz", "Marisco", "Pescado", "Tradicional", "Sartén", "Para compartir"], "Paella must show the requested tags in order")
	editor.set_dish_stats(4.6, 6.0)
	check(editor.detail_time.text.contains("4.6 s") and editor.detail_value.text.contains("6.0 €"), "Details display current cooking time and price")
	check(DishTypes.tags(DishTypes.Type.SALAD).has("Fría") and DishTypes.tags(DishTypes.Type.NIGIRI).has("Fría"), "Shared tags must use a consistent gender")
	check(not DishTypes.all_tags().has("Frío"), "Filter must not contain duplicate gender variants")
	for index in range(editor.tag_checkboxes.size()):
		if editor.tag_checkboxes[index].text == "Arroz":
			editor.tag_checkboxes[index].set_pressed_no_signal(false)
			editor.tag_checkboxes[index].pressed.emit()
	check(editor.dish_buttons[DishTypes.Type.PAELLA].visible and not editor.dish_buttons[BURGER].visible and not editor.dish_buttons[PIZZA].visible, "Rice filter shows only matching unlocked dishes")
	check(editor.selected == [BURGER, PIZZA], "Filtering must preserve selected dishes that become hidden")
	for index in range(editor.tag_checkboxes.size()):
		if editor.tag_checkboxes[index].text == "Mediterránea":
			editor.tag_checkboxes[index].pressed.emit()
	check(editor.active_tags.size() == 2 and editor.dish_buttons[DishTypes.Type.PAELLA].visible and not editor.dish_buttons[PIZZA].visible, "Combined filters require both rice and Mediterranean tags")
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
		if editor.tag_checkboxes[index].text == "Americana":
			editor.tag_checkboxes[index].pressed.emit()
	check(editor.empty_results.visible, "Tags without unlocked matches show an empty state")
	editor.clear_filter_button.pressed.emit()
	check(editor.dish_buttons[BURGER].visible and not editor.empty_results.visible, "All tags restores the dish list")
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
