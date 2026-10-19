extends RefCounted
## Stable IDs for saves. Percentages and tags can be edited here.
const CATALOG = [
	{"id": "chocolate", "name": "Batido de chocolate", "icon": "🥤", "tag": "Desayuno", "percent": 50.0},
	{"id": "coffee", "name": "Café", "icon": "☕", "tag": "Masa", "percent": 25.0},
	{"id": "wine", "name": "Vino", "icon": "🍷", "tag": "Gourmet", "percent": 30.0},
]
static func index_of(id: String) -> int:
	for index in range(CATALOG.size()):
		if CATALOG[index].id == id:
			return index
	return -1

static func apply(effects: Dictionary, id: String, mode: String, unlocked: bool) -> void:
	var index := index_of(id)
	if not unlocked or mode != "normal" or index < 0:
		return
	var drink: Dictionary = CATALOG[index]
	effects.dish_effects.append({"stat": "value", "target": [drink.tag], "exclude": [], "factor": 1.0 + drink.percent / 100.0})

static func description(index: int) -> String:
	var drink: Dictionary = CATALOG[index]
	return "+%s %% de valor para los platos con la etiqueta %s de tu carta. Se combina con los demás beneficios." % [str(drink.percent), drink.tag]
