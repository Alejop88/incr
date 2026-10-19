extends SceneTree
const DRINKS = preload("res://scripts/DrinkTypes.gd")
const TRAITS = preload("res://scripts/MenuTraits.gd")
var failures := 0
func _initialize() -> void:
	call_deferred("run_tests")
func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
func run_tests() -> void:
	var manager := preload("res://scripts/MichelinManager.gd").new()
	manager.stars = 100
	check(not manager.buy_upgrade("permanent_bar"), "Bar requires advanced menu")
	manager.bought_upgrades["menu_capacity_6"] = true
	check(manager.buy_upgrade("permanent_bar") and manager.stars == 50, "Bar has a one-time permanent cost")
	check(not manager.buy_upgrade("permanent_bar"), "Bar cannot be bought twice")
	manager.free()
	var catalog := {1: {"tags": ["Desayuno"]}, 2: {"tags": ["Carne"]}}
	var effects := TRAITS.calculate("normal", [1, 2], catalog)
	DRINKS.apply(effects, "chocolate", "normal", true)
	check(is_equal_approx(TRAITS.dish_value_multiplier(1, effects, catalog), 1.5), "Chocolate boosts breakfast by 50 percent")
	check(TRAITS.dish_value_multiplier(2, effects, catalog) == 1.0, "Other dishes are unchanged")
	for mode in ["cozy", "normal"]:
		var neutral := TRAITS.calculate(mode, [], catalog)
		DRINKS.apply(neutral, "chocolate", mode, mode == "cozy")
		check(TRAITS.dish_value_multiplier(1, neutral, catalog) == 1.0, "Cozy and locked bars have no effect")
	var path := "res://tests/bar-%d.json" % Time.get_ticks_usec()
	var slots := root.get_node("SaveSlots")
	slots.active_path = path
	var game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	check(not game.restaurant.has_node("Bar"), "Locked bar is absent")
	game.michelin_manager.bought_upgrades["permanent_bar"] = true
	game._setup_bar()
	var panel = game.get_node("CanvasLayer/BarPanel")
	panel.open("", "normal")
	check(panel.description_label.text.contains("50"), "Description displays the configurable percentage")
	check(panel.icons.size() == 3 and panel.index == 0, "Carousel shows three drinks")
	panel.cycle(-1)
	check(panel.index == DRINKS.CATALOG.size() - 1, "Left wraps to last drink")
	panel.cycle(1)
	check(panel.index == 0 and game.restaurant.selected_drink == "", "Browsing wraps without selecting")
	panel.select_button.pressed.emit()
	check(game.restaurant.selected_drink == "chocolate" and panel.select_button.disabled, "Selection applies and is marked active")
	panel.cycle(1)
	panel.hide()
	panel.open(game.restaurant.selected_drink, "normal")
	check(panel.index == 0, "Closing without selecting preserves the active drink")
	game.free()
	game = load("res://scenes/Main.tscn").instantiate()
	root.add_child(game)
	check(game.restaurant.bar_unlocked and game.restaurant.selected_drink == "chocolate", "Loading restores bar and drink")
	current_scene = game
	game.michelin_manager.stars = 100
	game.michelin_manager.toggle_selection("counter_capacity_1")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.bar_unlocked and game.restaurant.selected_drink == "chocolate", "Prestige preserves bar and selected drink")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	slots.active_path = "user://partida.json"
	print("BAR TESTS: ", "PASS" if failures == 0 else "FAIL")
	quit(0 if failures == 0 else 1)
