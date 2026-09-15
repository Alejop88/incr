extends SceneTree

var failures: int = 0
var selected_index: int = -1

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func settle_layout() -> void:
	for i in range(5):
		await process_frame

func run_tests() -> void:
	root.size = Vector2i(1152, 648)
	var hud: Control = load("res://scenes/ui/HUD.tscn").instantiate()
	root.add_child(hud)
	hud.open_kitchen_panel()
	hud.set_manual_order_dishes([DishTypes.Type.BURGER, DishTypes.Type.PIZZA])
	hud.set_kitchen_order_queue_buttons([DishTypes.Type.BURGER])
	var single_id: Array[int] = [10]
	hud.set_ready_dishes_buttons([DishTypes.Type.BURGER], single_id)
	await settle_layout()
	var scroll: ScrollContainer = hud.get_node("KitchenPanel/VBoxContainer/OrderQueueScroll")
	var initial_panel_height: float = hud.kitchen_panel.size.y
	var ready_position: Vector2 = hud.ready_dishes_container.global_position
	check(not scroll.get_v_scroll_bar().visible, "A short list must not show a scrollbar")
	var five_dishes: Array = []
	five_dishes.resize(5)
	five_dishes.fill(DishTypes.Type.BURGER)
	hud.set_kitchen_order_queue_buttons(five_dishes)
	await settle_layout()
	check(not scroll.get_v_scroll_bar().visible, "Exactly five dishes must fit without scrolling")
	var fifth_row: Control = hud.order_queue_container.get_child(4)
	check(is_equal_approx(fifth_row.get_global_rect().end.y, scroll.get_global_rect().end.y), "Viewport must fit exactly five complete rows")
	five_dishes.append(DishTypes.Type.PIZZA)
	hud.set_kitchen_order_queue_buttons(five_dishes)
	await settle_layout()
	check(scroll.get_v_scroll_bar().visible, "A sixth dish must show the scrollbar")
	var dishes: Array = []
	for i in range(40):
		dishes.append(DishTypes.Type.BURGER if i % 2 == 0 else DishTypes.Type.PIZZA)
	hud.set_kitchen_order_queue_buttons(dishes)
	await settle_layout()
	var row_height: float = hud.order_queue_container.get_child(0).get_combined_minimum_size().y
	var spacing: int = hud.order_queue_container.get_theme_constant("separation")
	check(scroll.size.y == row_height * 5 + spacing * 4, "Order queue viewport must remain five rows high")
	check(is_equal_approx(hud.kitchen_panel.size.y, initial_panel_height), "Adding many queued dishes must not grow the panel")
	check(scroll.get_v_scroll_bar().visible, "Overflow must show a vertical scrollbar")
	check(not scroll.get_h_scroll_bar().visible, "No horizontal scrollbar is needed")
	check(hud.kitchen_panel.get_global_rect().end.y <= root.size.y, "Panel must fit the game window")
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)
	await settle_layout()
	check(scroll.scroll_vertical > 0, "The list must scroll to lower dishes")
	check(hud.ready_dishes_container.global_position == ready_position, "Scrolling orders must not move prepared dishes")
	var last_row: Control = hud.order_queue_container.get_child(39)
	check(last_row.get_global_rect().end.y <= scroll.get_global_rect().end.y, "The last order must become reachable")
	hud.kitchen_order_cancel_requested.connect(func(index: int): selected_index = index)
	last_row.get_child(3).pressed.emit()
	check(selected_index == 39, "Scrolled cancel button must still target its correct order")
	hud.kitchen_order_move_up_requested.connect(func(index: int): selected_index = index)
	selected_index = -1
	last_row.get_child(1).pressed.emit()
	check(selected_index == 39, "Scrolled move-up button must still target its correct order")
	# A normal dish removal must preserve the user's scroll position.
	var scroll_position: int = scroll.scroll_vertical / 2
	scroll.scroll_vertical = scroll_position
	dishes.pop_back()
	hud.set_kitchen_order_queue_buttons(dishes)
	await settle_layout()
	check(scroll.scroll_vertical == scroll_position, "Refreshing the list must preserve scroll position")
	hud.set_kitchen_order_queue_buttons([DishTypes.Type.PIZZA])
	await settle_layout()
	check(not scroll.get_v_scroll_bar().visible and scroll.scroll_vertical == 0, "Shortening the list must remove scrollbar and reset offset")
	hud.free()
	print("ORDER QUEUE SCROLL TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
