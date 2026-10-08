extends RefCounted

# Conditions live here; balance numbers live only in TagBalance.gd.
static func effect(stat: String, key: String, target: Array = [], exclude: Array = []) -> Dictionary:
	return {"stat": stat, "key": key, "target": target, "exclude": exclude}

static func rule(tag: String, minimum: int, effects: Array, extra: Dictionary = {}) -> Dictionary:
	var result := {"tag": tag, "min": minimum, "effects": effects}
	result.merge(extra)
	return result

static func all() -> Array:
	var r: Array = [
		rule("Cruda", 1, [effect("cooking_speed", "cruda_cocina_por_plato")], {"per_dish": true}),
		rule("Picante", 1, [effect("waiter_speed", "picante_camareros_por_plato"), effect("table_patience", "picante_paciencia_por_plato")], {"per_dish": true}),
		rule("Fría", 1, [effect("cooking_speed", "fria_cocina")], {"all": true}),
		rule("Sushi", 4, [effect("eating_speed", "sushi_comer"), effect("customer_rate", "sushi_clientes")]),
		rule("Caldo", 2, [effect("table_patience", "caldo_paciencia_2"), effect("cooking_time", "caldo_tiempo_cocina_2")], {"max": 3}),
		rule("Caldo", 4, [effect("table_patience", "caldo_paciencia_4"), effect("cooking_time", "caldo_tiempo_cocina_4")]),
		rule("Frita", 1, [effect("customer_rate", "frita_clientes"), effect("vip_rate", "frita_vip")], {"all": true}),
		rule("Desayuno", 1, [effect("value", "desayuno_valor")], {"all": true}),
		rule("Comida rápida", 3, [effect("cooking_speed", "rapida_cocina")]),
		rule("Gourmet", 1, [effect("vip_rate", "gourmet_vip"), effect("customer_rate", "gourmet_clientes")], {"all": true}),
		rule("Vegetariana", 1, [effect("queue_patience", "vegetariana_paciencia_cola"), effect("table_patience", "vegetariana_paciencia_mesa")], {"all": true}),
		rule("Vegetariana", 1, [effect("customer_rate", "vegetariana_clientes_con_carne")], {"any": ["Carne", "Pescado", "Marisco"]}),
		rule("Vegana", 1, [effect("value", "vegana_valor_vegetales_1", ["Vegetales"])], {"max": 4}),
		rule("Vegana", 5, [effect("value", "vegana_valor_vegetales_5", ["Vegetales"])], {"max": 9}),
		rule("Vegana", 10, [effect("value", "vegana_valor_vegetales_10", ["Vegetales"]), effect("value", "vegana_valor_vegetariana_10", ["Vegetariana"]), effect("customer_rate", "vegana_clientes_10")]),
		rule("Marisco", 6, [effect("value", "marisco_valor_6", ["Marisco"]), effect("vip_rate", "marisco_vip_6")]),
		rule("Arroz", 2, [effect("cooking_speed", "arroz_cocina_2")], {"max": 4}),
		rule("Arroz", 5, [effect("cooking_speed", "arroz_cocina_5")]),
		rule("Carne", 5, [effect("value", "carne_valor_5", [], ["Pescado", "Marisco"]), effect("cooking_speed", "carne_cocina_5", [], ["Pescado", "Marisco"])]),
		rule("Pescado", 3, [effect("eating_speed", "pescado_comer_3")], {"max": 5}),
		rule("Pescado", 6, [effect("eating_speed", "pescado_comer_6")]),
		rule("Pescado", 3, [effect("value", "pescado_marisco_valor", ["Pescado", "Marisco"])], {"requires": {"Marisco": 3}}),
		rule("Patata", 2, [effect("waiter_speed", "patata_camareros_2")], {"max": 4}),
		rule("Patata", 5, [effect("waiter_speed", "patata_camareros_5")], {"max": 9}),
		rule("Patata", 10, [effect("waiter_speed", "patata_camareros_10")]),
		rule("Vegetales", 1, [effect("queue_patience", "vegetales_cola_1")], {"max": 2}),
		rule("Vegetales", 3, [effect("queue_patience", "vegetales_cola_3")], {"max": 5}),
		rule("Vegetales", 6, [effect("queue_patience", "vegetales_cola_6")], {"max": 8}),
		rule("Vegetales", 9, [effect("queue_patience", "vegetales_cola_9"), effect("cooking_speed", "vegetales_cocina_vegana_9", ["Vegana"])]),
		rule("Pasta", 1, [effect("customer_rate", "pasta_clientes_1")], {"max": 3}),
		rule("Pasta", 4, [effect("customer_rate", "pasta_clientes_4")], {"max": 6}),
		rule("Pasta", 7, [effect("customer_rate", "pasta_clientes_7")]),
		rule("Pasta", 1, [effect("value", "pasta_valor_con_caldo", ["Pasta"])], {"requires": {"Caldo": 3}}),
		rule("Masa", 2, [effect("value", "masa_valor_2", ["Masa"])], {"max": 5}),
		rule("Masa", 6, [effect("value", "masa_valor_6", ["Masa"])], {"max": 9}),
		rule("Masa", 10, [effect("value", "masa_valor_10", ["Masa"]), effect("cooking_speed", "masa_cocina_10")])
	]
	for entry in [
		["Japonesa", "japonesa_valor_cruda", "Cruda"], ["Italiana", "italiana_valor_pasta", "Pasta"],
		["Mexicana", "mexicana_valor_picante", "Picante"], ["China", "china_valor_arroz", "Arroz"],
		["Española", "espanola_valor_compartir", "Para compartir"], ["Peruana", "peruana_valor_pescado", "Pescado"],
		["Estadounidense", "estadounidense_valor_rapida", "Comida rápida"], ["Francesa", "francesa_valor_gourmet", "Gourmet"]
	]:
		r.append(rule(entry[0], 1, [effect("value", entry[1], [entry[2]])], {"per_dish": true}))
	return r

static func tags() -> Array[String]:
	var result: Array[String] = ["Para compartir"]
	for entry in all():
		if not result.has(entry.tag):
			result.append(entry.tag)
	return result

static func effect_text(entry: Dictionary, percent: float) -> String:
	var names := {"value": "valor", "cooking_speed": "velocidad de cocina", "cooking_time": "tiempo de cocina", "waiter_speed": "velocidad de camareros", "eating_speed": "velocidad al comer", "queue_patience": "paciencia en cola", "table_patience": "paciencia en mesa", "customer_rate": "aparición de clientes", "vip_rate": "aparición VIP"}
	var result := ("+" if percent >= 0 else "") + str(percent) + " % " + str(names[entry.stat])
	if not entry.target.is_empty():
		result += " (" + " / ".join(entry.target) + ")"
	if not entry.exclude.is_empty():
		result += " (excepto " + " / ".join(entry.exclude) + ")"
	return result

static func description(tag: String, percentages: Dictionary) -> String:
	if tag == "Para compartir":
		var lines: Array[String] = ["Pedidos iguales en la misma mesa:"]
		for n in [2, 3, 4]:
			lines.append("%d pedidos: +%s %% velocidad de cocina." % [n, percentages["compartir_cocina_%d" % n]])
		lines.append("Peso extra al repetir un plato ya elegido por el grupo:")
		for n in [2, 3, 4]:
			lines.append("%d personas: +%s %%." % [n, percentages["compartir_repeticion_%d" % n]])
		return "\n".join(lines)
	var lines: Array[String] = []
	for entry in all():
		if entry.tag != tag:
			continue
		var condition := "Con %d o más platos %s" % [entry.min, tag]
		if entry.has("max"):
			condition = "Con %d–%d platos %s" % [entry.min, entry.max, tag]
		if entry.get("all", false):
			condition = "Si toda la carta tiene " + tag
		if entry.get("per_dish", false):
			condition = "Por cada plato " + tag + " en la carta"
		for required in entry.get("requires", {}):
			condition += ", y %d o más con %s" % [entry.requires[required], required]
		if entry.has("any"):
			condition += ", junto a platos con " + " / ".join(entry.any)
		var effects: Array[String] = []
		for item in entry.effects:
			effects.append(effect_text(item, float(percentages[item.key])))
		lines.append(condition + ": " + "; ".join(effects) + ".")
	return "\n".join(lines)
