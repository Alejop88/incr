extends RefCounted

const BALANCE = preload("res://scripts/TagBalance.gd")
const RULES = preload("res://scripts/TagRules.gd")

static func normalized_tags(dish: int, catalog: Dictionary) -> Array[String]:
	var result: Array[String] = []
	for value in catalog.get(dish, {}).get("tags", []):
		var tag: String = DishTypes.normalize_tag(str(value))
		if not result.has(tag):
			result.append(tag)
	return result

static func calculate(mode: String, dishes: Array, catalog: Dictionary = DishTypes.CATALOG, percentages: Dictionary = BALANCE.PERCENTAGES) -> Dictionary:
	var result := {"waiter_speed": 1.0, "cooking_speed": 1.0, "cooking_time": 1.0, "eating_speed": 1.0, "customer_rate": 1.0, "vip_rate": 1.0, "table_patience": 1.0, "queue_patience": 1.0, "active_tags": [], "descriptions": {}, "dish_effects": [], "sharing": mode == "normal", "percentages": percentages}
	if mode != "normal" or dishes.is_empty():
		return result
	var counts := {}
	var seen := []
	for dish in dishes:
		if seen.has(dish) or not catalog.has(dish):
			continue
		seen.append(dish)
		for tag in normalized_tags(dish, catalog):
			counts[tag] = int(counts.get(tag, 0)) + 1
	for entry in RULES.all():
		var count: int = counts.get(entry.tag, 0)
		if count < entry.min or count > int(entry.get("max", 2147483647)):
			continue
		if entry.get("all", false) and count != seen.size():
			continue
		var matches := true
		for tag in entry.get("requires", {}):
			if int(counts.get(tag, 0)) < int(entry.requires[tag]):
				matches = false
		if entry.has("any"):
			var has_any := false
			for tag in entry.any:
				has_any = has_any or int(counts.get(tag, 0)) > 0
			matches = matches and has_any
		if not matches:
			continue
		var texts: Array[String] = []
		for item in entry.effects:
			var percent := float(percentages[item.key]) * (count if entry.get("per_dish", false) else 1)
			# Keep durations and speeds positive during extreme balance experiments.
			var factor := maxf(0.01, 1.0 + percent / 100.0)
			if item.stat == "value" or not item.target.is_empty() or not item.exclude.is_empty():
				var applied: Dictionary = item.duplicate(true)
				applied["factor"] = factor
				result.dish_effects.append(applied)
			else:
				result[item.stat] *= factor
			texts.append(RULES.effect_text(item, percent))
		if not result.active_tags.has(entry.tag):
			result.active_tags.append(entry.tag)
		var previous: String = result.descriptions.get(entry.tag, "")
		result.descriptions[entry.tag] = previous + (" · " if not previous.is_empty() else "") + " · ".join(texts)
	if int(counts.get("Para compartir", 0)) > 0:
		result.sharing = true
		result.active_tags.append("Para compartir")
		result.descriptions["Para compartir"] = "Bonus por pedidos iguales en una mesa; ver detalle."
	return result

static func dish_multiplier(dish: int, effects: Dictionary, stat: String, catalog: Dictionary) -> float:
	var tags := normalized_tags(dish, catalog)
	var multiplier := 1.0
	for entry in effects.dish_effects:
		if entry.stat != stat:
			continue
		var matches: bool = entry.target.is_empty()
		for target in entry.target:
			matches = matches or tags.has(target)
		for excluded in entry.exclude:
			if tags.has(excluded):
				matches = false
		if matches:
			multiplier *= float(entry.factor)
	return multiplier

static func dish_value_multiplier(dish: int, effects: Dictionary, catalog: Dictionary = DishTypes.CATALOG) -> float:
	return dish_multiplier(dish, effects, "value", catalog)

static func dish_cooking_speed(dish: int, effects: Dictionary, catalog: Dictionary = DishTypes.CATALOG) -> float:
	return float(effects.cooking_speed) * dish_multiplier(dish, effects, "cooking_speed", catalog) / float(effects.cooking_time)

static func sharing_speed(dish: int, repeated: int, effects: Dictionary, catalog: Dictionary = DishTypes.CATALOG) -> float:
	if not effects.sharing or repeated < 2 or not normalized_tags(dish, catalog).has("Para compartir"):
		return 1.0
	return maxf(0.01, 1.0 + float(effects.percentages["compartir_cocina_%d" % mini(repeated, 4)]) / 100.0)

static func order_weights(dishes: Array, previous: Array, group_size: int, effects: Dictionary, catalog: Dictionary = DishTypes.CATALOG) -> Array[float]:
	var weights: Array[float] = []
	for dish in dishes:
		var weight := 1.0
		if effects.sharing and group_size >= 2 and previous.has(dish) and normalized_tags(dish, catalog).has("Para compartir"):
			weight = maxf(0.01, 1.0 + float(effects.percentages["compartir_repeticion_%d" % mini(group_size, 4)]) / 100.0)
		weights.append(weight)
	return weights

static func choose_order(dishes: Array, previous: Array, group_size: int, effects: Dictionary) -> int:
	if dishes.is_empty():
		return DishTypes.Type.NONE
	var weights := order_weights(dishes, previous, group_size, effects)
	var total := 0.0
	for weight in weights:
		total += weight
	var roll := randf() * total
	for i in range(dishes.size()):
		roll -= weights[i]
		if roll < 0.0:
			return dishes[i]
	return dishes.back()
