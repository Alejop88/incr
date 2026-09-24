extends SceneTree

func _initialize() -> void:
	call_deferred("run_tests")

func run_tests() -> void:
	var manager: Node = load("res://scripts/MichelinManager.gd").new()
	root.add_child(manager)
	manager.stars = 100
	assert(not manager.buy_upgrade("vip_spawn_1"), "VIP frequency must require permanent VIP unlock")
	manager.toggle_selection("vip_spawn_1")
	assert(manager.selected_upgrades.is_empty(), "Locked VIP frequency cannot be selected")
	manager.toggle_selection("permanent_vip")
	manager.toggle_selection("vip_spawn_1")
	manager.toggle_selection("vip_spawn_2")
	assert(manager.selected_upgrades.size() == 3, "VIP prerequisite can be bought in the same batch")
	manager.toggle_selection("permanent_vip")
	assert(manager.selected_upgrades.is_empty(), "Removing VIP unlock removes dependent selections")
	assert(not manager.buy_upgrade("cook_speed_2"), "Cooking tiers require previous levels")
	for level in range(1, 6):
		manager.toggle_selection("cook_speed_%d" % level)
	assert(manager.get_selected_cost() == 30 and manager.cook_speed_bonus == 0, "Cooking selection costs thirty and does not apply early")
	var saved: Dictionary = manager.get_selected_purchase_data()
	manager.load_save_data(saved)
	assert(manager.cook_speed_bonus == 5 and manager.stars == 70, "All cooking levels survive loading")
	var kitchen: Node = load("res://scripts/Kitchen.gd").new()
	kitchen.set_cook_speed_level(manager.cook_speed_bonus)
	assert(is_equal_approx(kitchen.cook_time, 4.0), "Five permanent levels reduce base cooking from five to four seconds")
	kitchen.set_cook_speed_level(manager.cook_speed_bonus + 10)
	assert(is_equal_approx(kitchen.cook_time, 2.0), "Permanent cooking stacks with money upgrades")
	kitchen.free()
	manager.free()
	print("COOK VIP UPGRADE TESTS: PASS")
	quit()
