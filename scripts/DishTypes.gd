class_name DishTypes
extends RefCounted

enum Type {
	NONE,
	BURGER,
	PIZZA,
	SALAD,
	TACO,
	PAELLA
}

# Añade nuevos valores al FINAL del enum y su ficha aquí. Ver docs/ANADIR_PLATOS.md.
const CATALOG: Dictionary = {
	Type.BURGER: {"name": "Hamburguesa", "icon": "🍔", "image": ""},
	Type.PIZZA: {"name": "Pizza", "icon": "🍕", "image": ""},
	Type.SALAD: {"name": "Ensalada", "icon": "🥗", "image": ""},
	Type.TACO: {"name": "Taco", "icon": "🌮​", "image": ""},
	Type.PAELLA: {"name": "Paella", "icon": "🥘​​", "image": ""}
}
const MAX_MENU_DISHES: int = 2

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

static func menu_from_keys(keys: Array) -> Array[Type]:
	var result: Array[Type] = []
	for key in keys:
		if Type.has(key):
			var dish: int = Type[key]
			if CATALOG.has(dish) and not result.has(dish) and result.size() < MAX_MENU_DISHES:
				result.append(dish)
	return default_menu() if result.is_empty() else result
