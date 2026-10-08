extends "res://tests/test_automatic_waiters.gd"

func run_tests() -> void:
	var source := FileAccess.get_file_as_string("res://tests/fixtures/dish_catalog.tsv")
	var expected := {}
	for row in source.split("\n", false):
		var cells := row.strip_edges().split("\t")
		var tags := PackedStringArray()
		for i in range(1, cells.size()):
			if cells[i] != "—":
				tags.append(DishTypes.normalize_tag(cells[i]))
		expected[cells[0]] = tags
	check(expected.size() == 139 and DishTypes.CATALOG.size() == 139, "Catalog contains exactly the 139 supplied dishes")
	var names := {}
	for dish in DishTypes.CATALOG:
		var entry: Dictionary = DishTypes.CATALOG[dish]
		check(expected.has(entry.name), "No extra dishes: " + entry.name)
		check(not names.has(entry.name), "No duplicate dish names")
		names[entry.name] = true
		check(DishTypes.tags(dish) == expected.get(entry.name, []), "Exact normalized tags for " + entry.name)
		check(not entry.icon.is_empty() and entry.has("image"), "Every dish has a provisional icon and image slot")
		check(not entry.has("effect_description") and not entry.has("complexity"), "No invented dish characteristics")
		check(DishTypes.menu_from_keys(DishTypes.menu_keys([dish])) == [dish], "Every dish round-trips through save keys")
	check(DishTypes.Type.BURGER == 1 and DishTypes.Type.SASHIMI == 13, "Existing numeric identifiers stay stable")
	for retired in [DishTypes.Type.SALAD, DishTypes.Type.SOUP, DishTypes.Type.SANDWICH]:
		check(not DishTypes.CATALOG.has(retired), "Retired recipe is absent from active catalog")
	check(not DishTypes.tags(DishTypes.Type.SASHIMI).has("Sushi"), "Sashimi follows supplied tags, without Sushi")
	check(not DishTypes.tags(DishTypes.Type.ONIGIRI).has("Fría"), "Onigiri follows supplied tags, without cold")
	check(DishTypes.tags(DishTypes.Type.NIGIRI).has("Cruda"), "Nigiri now counts as raw")
	check(DishTypes.texture(DishTypes.Type.BURGER) != null, "Burger test image is preserved")
	var r: Node = world()
	r.restore_dish_progress({"menu_dishes": ["SALAD", "PIZZA"], "unlocked_dishes": ["SALAD", "PIZZA", "BURGER", "SOUP", "SANDWICH"]})
	check(r.menu_dishes == [PIZZA] and r.unlocked_dishes == [PIZZA, BURGER], "Loading filters retired recipes while preserving surviving unlocks")
	r.restore_dish_progress({"menu_dishes": ["SALAD", "SOUP"], "unlocked_dishes": ["SALAD", "SOUP", "SANDWICH"]})
	check(r.menu_dishes.size() >= 1 and r.unlocked_dishes.size() >= 2, "All-retired save recovers a playable menu")
	for dish in r.menu_dishes:
		check(DishTypes.CATALOG.has(dish) and r.unlocked_dishes.has(dish), "Recovery never selects a locked or retired dish")
	r.free()
	print("DISH CATALOG TESTS: %s (%d failures)" % ["PASS" if failures == 0 else "FAIL", failures])
	quit(0 if failures == 0 else 1)
