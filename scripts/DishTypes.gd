class_name DishTypes
extends RefCounted

enum Type {
	NONE,
	BURGER,
	PIZZA,
	SALAD,
	TACO,
	PAELLA,
	SOUP,
	SANDWICH,
	NIGIRI,
	FALAFEL
}

# Añade nuevos valores al FINAL del enum y su ficha aquí. Ver docs/ANADIR_PLATOS.md.
const CATALOG: Dictionary = {
	Type.BURGER: {"name": "Hamburguesa", "icon": "🍔", "image": "res://assets/art/food/burger.jpg", "tags": ["Americana", "Carne", "Pan", "Plancha", "Comida rápida", "Individual"]},
	Type.PIZZA: {"name": "Pizza", "icon": "🍕", "image": "", "tags": ["Italiana", "Mediterránea", "Masa", "Queso", "Horno", "Para compartir"]},
	Type.SALAD: {"name": "Ensalada", "icon": "🥗", "image": "", "tags": ["Verduras", "Fresca", "Vegetariana", "Fría", "Ligera", "Individual"], "complexity": "Por definir", "effect_description": "Si la ensalada está en la carta, los otros platos con la etiqueta Vegetariana incluidos en ella aumentarán su valor un 5 %."},
	Type.TACO: {"name": "Taco", "icon": "🌮​", "image": "", "tags": ["Mexicana", "Tortilla", "Especiada", "Tradicional", "Comida callejera", "Individual"]},
	Type.PAELLA: {"name": "Paella", "icon": "🥘​​", "image": "", "tags": ["Mediterránea", "Arroz", "Marisco", "Pescado", "Tradicional", "Sartén", "Para compartir"]},
	Type.SOUP: {"name": "Sopa", "icon": "🍲​​​", "image": "", "tags": ["Caldo", "Caliente", "Cuchara", "Olla", "Tradicional", "Individual"]},
	Type.SANDWICH: {"name": "Sandwich", "icon": "🥪​​​​", "image": "", "tags": ["Pan", "Fría", "Comida rápida", "Para llevar", "Individual"]},
	Type.NIGIRI: {"name": "Nigiri", "icon": "🍣​​​​​", "image": "", "tags": ["Japonesa", "Arroz", "Pescado", "Fría", "Tradicional", "Individual"]},
	Type.FALAFEL: {"name": "Falafel", "icon": "​🧆​", "image": "", "tags": ["Oriente Medio", "Legumbres", "Vegetariana", "Fritura", "Tradicional", "Comida callejera"]}
}
const MAX_MENU_DISHES: int = 2
const NEW_DISH_COST: float = 50.0
const TAG_ALIASES := {"Frío": "Fría", "Fresco": "Fresca", "Vegetariano": "Vegetariana", "Ligero": "Ligera", "Especiado": "Especiada", "Mediterráneo": "Mediterránea", "Americano": "Americana", "Italiano": "Italiana", "Mexicano": "Mexicana", "Japonés": "Japonesa"}

static func tags(dish: int) -> PackedStringArray:
	var result := PackedStringArray()
	for value in CATALOG.get(dish, {}).get("tags", []):
		var tag := str(value).strip_edges()
		tag = TAG_ALIASES.get(tag, tag)
		if not tag.is_empty() and not result.has(tag):
			result.append(tag)
	return result

static func all_tags() -> PackedStringArray:
	var result := PackedStringArray()
	for dish in CATALOG:
		for tag in tags(dish):
			if not result.has(tag):
				result.append(tag)
	result.sort()
	return result

static func random_starting_dishes() -> Array[Type]:
	var pool: Array = CATALOG.keys()
	pool.shuffle()
	var result: Array[Type] = []
	for dish in pool.slice(0, mini(2, pool.size())):
		result.append(dish)
	return result

static func unlocked_from_keys(keys: Array) -> Array[Type]:
	var result: Array[Type] = []
	for key in keys:
		if Type.has(key) and CATALOG.has(Type[key]) and not result.has(Type[key]):
			result.append(Type[key])
	return result

static func default_menu() -> Array[Type]:
	return [Type.BURGER, Type.PIZZA]

static func title(dish: int) -> String:
	var entry: Dictionary = CATALOG.get(dish, {})
	return str(entry.get("icon", "")) + " " + str(entry.get("name", ""))

static func texture(dish: int) -> Texture2D:
	var path: String = CATALOG.get(dish, {}).get("image", "")
	if not path.is_empty() and ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null

static func menu_keys(dishes: Array) -> Array[String]:
	var keys: Array[String] = []
	for dish in dishes:
		keys.append(Type.keys()[dish])
	return keys

static func menu_from_keys(keys: Array, capacity: int = MAX_MENU_DISHES) -> Array[Type]:
	var result: Array[Type] = []
	for key in keys:
		if Type.has(key):
			var dish: int = Type[key]
			if CATALOG.has(dish) and not result.has(dish) and result.size() < capacity:
				result.append(dish)
	return default_menu() if result.is_empty() else result
