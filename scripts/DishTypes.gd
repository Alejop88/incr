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
	Type.BURGER: {"name": "Hamburguesa", "icon": "🍔", "image": ""},
	Type.PIZZA: {"name": "Pizza", "icon": "🍕", "image": ""},
	Type.SALAD: {"name": "Ensalada", "icon": "🥗", "image": ""},
	Type.TACO: {"name": "Taco", "icon": "🌮​", "image": ""},
	Type.PAELLA: {"name": "Paella", "icon": "🥘​​", "image": ""},
	Type.SOUP: {"name": "Sopa", "icon": "🍲​​​", "image": ""},
	Type.SANDWICH: {"name": "Sandwich", "icon": "🥪​​​​", "image": ""},
	Type.NIGIRI: {"name": "Nigiri", "icon": "🍣​​​​​", "image": ""},
	Type.FALAFEL: {"name": "Falafel", "icon": "​🧆​", "image": ""}
}
const MAX_MENU_DISHES: int = 2
const NEW_DISH_COST: float = 50.0

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
