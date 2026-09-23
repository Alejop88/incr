extends RefCounted

const PRICE := 100.0
const RARITIES := ["Común", "Raro", "Muy raro", "Legendario"]
const COUNTS := [70, 20, 8, 2]
const CATEGORIES := ["Personaje", "Mesa", "Suelo", "Ambiente"]
var catalog: Array[Dictionary] = []
var owned: Array[String] = []

func _init() -> void:
	for rarity in range(COUNTS.size()):
		for index in range(COUNTS[rarity]):
			catalog.append({"id": "skin_%d_%03d" % [rarity, index], "rarity": rarity, "name": "%s %02d · %s" % [CATEGORIES[index % CATEGORIES.size()], index + 1, RARITIES[rarity]]})

func remaining() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in catalog:
		if not item.id in owned:
			result.append(item)
	return result

func probabilities() -> Array[float]:
	var counts: Array[float] = [0.0, 0.0, 0.0, 0.0]
	var available := remaining()
	for item in available:
		counts[item.rarity] += 1.0
	if not available.is_empty():
		for index in range(counts.size()):
			counts[index] = counts[index] * 100.0 / available.size()
	return counts

func draw_item() -> Dictionary:
	var available := remaining()
	if available.is_empty():
		return {}
	var item: Dictionary = available.pick_random()
	owned.append(item.id)
	return item

func restore(value: Array) -> void:
	owned.clear()
	for item in catalog:
		if item.id in value:
			owned.append(item.id)
