extends RefCounted

# Multiplicadores derivados de la carta, nunca guardados como mejoras compradas.
static func calculate(mode: String, dishes: Array, catalog: Dictionary = DishTypes.CATALOG) -> Dictionary:
	var result := {"waiter_speed": 1.0, "cooking_speed": 1.0, "eating_speed": 1.0, "customer_rate": 1.0, "vip_rate": 1.0, "seafood_value": 1.0, "fish_seafood_value": 1.0, "active_tags": [], "descriptions": {}}
	if mode != "normal" or dishes.is_empty():
		return result
	var counts := {}
	var seen := []
	for dish in dishes:
		if seen.has(dish) or not catalog.has(dish):
			continue
		seen.append(dish)
		var unique_tags := []
		for value in catalog[dish].get("tags", []):
			var tag: String = str(value).strip_edges()
			tag = DishTypes.TAG_ALIASES.get(tag, tag)
			if not unique_tags.has(tag):
				unique_tags.append(tag)
				counts[tag] = int(counts.get(tag, 0)) + 1
	result.waiter_speed += 0.02 * int(counts.get("Picante", 0))
	if int(counts.get("Picante", 0)) > 0:
		result.active_tags.append("Picante")
		result.descriptions["Picante"] = "+%d %% velocidad de camareros" % (2 * int(counts["Picante"]))
	if not seen.is_empty() and int(counts.get("Fría", 0)) == seen.size():
		result.cooking_speed = 1.3
		result.active_tags.append("Fría")
		result.descriptions["Fría"] = "+30 % velocidad de cocina"
	if int(counts.get("Sushi", 0)) >= 4:
		result.eating_speed = 1.25
		result.customer_rate = 1.2
		result.active_tags.append("Sushi")
		result.descriptions["Sushi"] = "+25 % al comer · +20 % clientes"
	var japanese: int = counts.get("Japonesa", 0)
	if japanese > 0:
		result.cooking_speed *= 1.0 + 0.02 * japanese
		result.active_tags.append("Japonesa")
		result.descriptions["Japonesa"] = "+%d %% velocidad de cocina" % (2 * japanese)
	var rice: int = counts.get("Arroz", 0)
	if rice >= 2:
		var bonus := 30 if rice >= 5 else 10
		result.cooking_speed *= 1.0 + bonus / 100.0
		result.active_tags.append("Arroz")
		result.descriptions["Arroz"] = "+%d %% velocidad de cocina" % bonus
	var fish: int = counts.get("Pescado", 0)
	var seafood: int = counts.get("Marisco", 0)
	if fish >= 3:
		var bonus := 30 if fish >= 6 else 15
		result.eating_speed *= 1.0 + bonus / 100.0
		result.active_tags.append("Pescado")
		result.descriptions["Pescado"] = "+%d %% al comer" % bonus
		if seafood >= 3:
			result.fish_seafood_value = 1.1
			result.descriptions["Pescado"] += " · +10 % valor pescado y marisco"
	if seafood >= 6:
		result.seafood_value = 1.25
		result.vip_rate = 1.05
		result.active_tags.append("Marisco")
		result.descriptions["Marisco"] = "+25 % valor marisco · +5 % aparición VIP"
	return result

static func dish_value_multiplier(dish: int, effects: Dictionary, catalog: Dictionary = DishTypes.CATALOG) -> float:
	var tags: Array = catalog.get(dish, {}).get("tags", [])
	var multiplier := 1.0
	if tags.has("Marisco"):
		multiplier *= float(effects.seafood_value)
	# A dish with both tags receives this shared bonus only once.
	if tags.has("Pescado") or tags.has("Marisco"):
		multiplier *= float(effects.fish_seafood_value)
	return multiplier
