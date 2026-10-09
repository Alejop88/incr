extends "res://tests/test_automatic_waiters.gd"

const TRAITS = preload("res://scripts/MenuTraits.gd")

func run_tests() -> void:
	var fixture := {
		1: {"tags": ["Picante", "Picante", "Frío", "Sushi"]},
		2: {"tags": ["Picante", "Fría", "Sushi"]},
		3: {"tags": ["Fría", "Sushi"]},
		4: {"tags": ["Fría", "Sushi"]},
		5: {"tags": ["Carne"]}
	}
	var effects: Dictionary = TRAITS.calculate("normal", [1, 2, 3, 4], fixture)
	check(is_equal_approx(effects.waiter_speed, 1.04), "Picante counts distinct dishes, not repeated tags")
	check(effects.cooking_speed == 1.3 and effects.eating_speed == 1.25 and effects.customer_rate == 1.2, "Cold and four sushi effects combine")
	check(effects.active_tags == ["Picante", "Fría", "Sushi"], "Active labels use the same conditions as gameplay effects")
	check(TRAITS.calculate("normal", [1, 2, 3, 3], fixture).eating_speed == 1.0, "Duplicate dishes cannot satisfy sushi threshold")
	check(TRAITS.calculate("normal", [1, 5], fixture).cooking_speed == 1.0, "One hot dish removes cold bonus")
	check(TRAITS.calculate("normal", [], fixture).cooking_speed == 1.0, "Empty menus do not activate cold")
	check(TRAITS.calculate("cozy", [1, 2, 3, 4], fixture) == TRAITS.calculate("cozy", []), "Cozy ignores every trait")

	var r: Node = world()
	r.unlocked_dishes.assign([DishTypes.Type.VICHYSSOISE, DishTypes.Type.SOBA_FRIA, BURGER])
	r.set_game_mode("normal")
	check(r.set_menu_dishes([DishTypes.Type.VICHYSSOISE, DishTypes.Type.SOBA_FRIA]), "Cold menu accepted")
	check(is_equal_approx(r.kitchen_point.cook_time, 5.0 / 1.3), "Cold increases cooking speed by 30 percent")
	r.cook_speed_level = 2
	r.set_permanent_cook_speed_bonus(1)
	check(is_equal_approx(r.kitchen_point.cook_time, 4.4 / 1.3), "Cold combines with cash and permanent upgrades")
	r.refresh_menu_traits()
	check(is_equal_approx(r.kitchen_point.cook_time, 4.4 / 1.3), "Refreshing cannot compound bonuses")
	r.set_menu_dishes([BURGER])
	check(is_equal_approx(r.kitchen_point.cook_time, 4.4), "Changing menu removes cold bonus")
	r.set_menu_dishes([DishTypes.Type.VICHYSSOISE])
	r.set_game_mode("cozy")
	check(is_equal_approx(r.kitchen_point.cook_time, 4.4), "Cozy restores original cooking stats")
	r.set_game_mode("normal")
	r.restore_dish_progress({"menu_dishes": ["VICHYSSOISE"], "unlocked_dishes": ["VICHYSSOISE"]})
	check(is_equal_approx(r.kitchen_point.cook_time, 4.4 / 1.3), "Loading recipes recalculates effects")

	# Apply calculated fixture effects without modifying the real recipe catalog.
	r.set_menu_capacity_bonus(2)
	r.menu_dishes.assign([BURGER, PIZZA, DishTypes.Type.MAKI, DishTypes.Type.NIGIRI])
	r.menu_effects = effects
	r._apply_menu_traits()
	var actor: Node = waiter(r)
	check(is_equal_approx(actor.speed, 90.0 * 1.04), "New waiter receives current spicy bonus")
	r.waiter_manager.set_speed_level(2)
	r.waiter_manager.set_training_level(1)
	check(is_equal_approx(actor.speed, 120.0 * 1.1 * 1.04), "Spicy survives cash and permanent staff upgrades")
	check(is_equal_approx(r.customer_spawn_timer.wait_time, 20.0 / 2.0 / 1.2), "Sushi arrivals combine with four active dishes")
	var table: Node = r.get_node("Table01Point")
	seat(r, "Table01Point", [BURGER])
	table.receive_food(BURGER)
	check(is_equal_approx(table.eating_timer.wait_time, table.BASE_EATING_TIME / 1.25), "Sushi speeds up normal customers eating")
	var vip_table: Node = r.get_node("Table02Point")
	var vip_group: Node = seat(r, "Table02Point", [BURGER], true)
	vip_table.receive_food(BURGER)
	check(is_equal_approx(vip_table.eating_timer.wait_time, vip_group.get_leader().EATING_TIME / 1.25), "Sushi also speeds up VIP eating")
	r.set_game_mode("cozy")
	check(is_equal_approx(actor.speed, 120.0 * 1.1), "Cozy removes spicy without losing upgrades")
	check(is_equal_approx(r.customer_spawn_timer.wait_time, 20.0 / 2.0), "Cozy removes sushi arrival bonus")
	check(is_equal_approx(table.eating_time, table.BASE_EATING_TIME), "Cozy removes sushi eating bonus")
	r.free()
	var editor: Node = load("res://scripts/ui/MenuEditor.gd").new()
	root.add_child(editor)
	editor.set_unlocks([DishTypes.Type.VICHYSSOISE, DishTypes.Type.SOBA_FRIA, BURGER], 0)
	editor.set_game_mode("normal")
	editor.open_menu([DishTypes.Type.VICHYSSOISE, DishTypes.Type.SOBA_FRIA])
	check(editor.active_traits_panel.visible and editor.active_trait_labels["Fría"].visible, "Cold draft shows its active tag on the left")
	check(not editor.active_traits_empty.visible and not editor.active_trait_labels["Sushi"].visible, "Only fulfilled traits are displayed")
	editor._toggle_dish(DishTypes.Type.SOBA_FRIA)
	editor._toggle_dish(BURGER)
	check(not editor.active_trait_labels["Fría"].visible, "Adding a hot dish immediately removes cold preview")
	editor.open_menu([DishTypes.Type.VICHYSSOISE])
	check(editor.active_trait_labels["Fría"].visible, "Reopening restores the applied menu preview")
	editor.set_game_mode("cozy")
	check(not editor.active_traits_panel.visible, "Cozy hides the entire active traits panel")
	var tooltip_style: StyleBoxFlat = editor.theme.get_stylebox("panel", "TooltipPanel")
	check(tooltip_style.bg_color.a == 1.0, "Tooltip background is fully opaque")
	editor.free()
	print("MENU TRAITS TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
