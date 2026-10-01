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
	FALAFEL,
	MAKI,
	TEMAKI,
	ONIGIRI,
	SASHIMI
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
	Type.NIGIRI: {"name": "Nigiri", "icon": "🍣​​​​​", "image": "", "tags": ["Japonesa", "Sushi", "Arroz", "Pescado", "Fría", "Tradicional", "Individual"]},
	Type.FALAFEL: {"name": "Falafel", "icon": "​🧆​", "image": "", "tags": ["Oriente Medio", "Legumbres", "Vegetariana", "Fritura", "Tradicional", "Comida callejera"]},
	Type.MAKI: {"name": "Maki", "icon": "🍣", "image": "", "tags": ["Sushi", "Arroz", "Pescado", "Fría", "Japonesa"]},
	Type.TEMAKI: {"name": "Temaki", "icon": "🍣", "image": "", "tags": ["Sushi", "Arroz", "Pescado", "Fría", "Japonesa"]},
	Type.ONIGIRI: {"name": "Onigiri", "icon": "🍙", "image": "", "tags": ["Arroz", "Fría", "Japonesa"]},
	Type.SASHIMI: {"name": "Sashimi", "icon": "🍣", "image": "", "tags": ["Sushi", "Pescado", "Fría", "Japonesa"]}
}
const MAX_MENU_DISHES: int = 2
const NEW_DISH_COST: float = 50.0
const TAG_ALIASES := {"Frío": "Fría", "Fresco": "Fresca", "Vegetariano": "Vegetariana", "Ligero": "Ligera", "Especiado": "Especiada", "Mediterráneo": "Mediterránea", "Americano": "Americana", "Italiano": "Italiana", "Mexicano": "Mexicana", "Japonés": "Japonesa", "Chino": "China", "Español": "Española", "Peru": "Peruana", "Perú": "Peruana", "Peruano": "Peruana", "Frito": "Frita", "Fritura": "Frita", "Sopa": "Caldo", "Sopas": "Caldo", "Caldoso": "Caldo", "Caldosos": "Caldo", "Comida Rapida": "Comida rápida"}

# Descripciones; la lógica de las características implementadas vive en MenuTraits.gd.
const IMPLEMENTED_TAG_EFFECTS := ["Picante", "Fría", "Sushi", "Japonesa", "Arroz", "Pescado", "Marisco"]
const TAG_EFFECTS := {
	"Picante": "Por cada plato con Picante en la carta, aumenta un 2 % la velocidad de los camareros.",
	"Fría": "Si todos los platos de la carta son fríos, se cocinan un 30 % más rápido.",
	"Sushi": "Con 4 o más platos de sushi en la carta, los clientes comen un 25 % más rápido y la aparición de clientes aumenta un 20 %.",
	"Caldo": "Con 2 o más platos con caldo en la carta, la paciencia de los clientes esperando en la mesa aumenta un 50 %. Con 4 o más, aumenta un 75 %.",
	"Frita": "Si todos los platos de la carta son fritos, la aparición de clientes aumenta un 50 %, pero la tasa de aparición de clientes VIP baja un 30 %.",
	"Desayuno": "Si todos los platos de la carta son de desayuno, el valor de los platos aumenta un 15 %.",
	"Comida rápida": "Con 3 o más platos de comida rápida en la carta, la velocidad de preparación de la cocina aumenta un 30 %.",
	"Gourmet": "Si todos los platos de la carta son gourmet, la aparición de clientes VIP aumenta un 50 %, pero la tasa de aparición de clientes baja un 50 %.",
	"Vegetariana": "Si toda la carta es vegetariana, la paciencia en la cola y en las mesas aumenta un 15 %. Si en la misma carta hay platos con carne, pescado o marisco, la aparición de clientes baja un 15 %.",
	"Japonesa": "Por cada plato japonés en la carta, la velocidad de la cocina aumenta un 2 %.",
	"Italiana": "Por cada plato italiano en la carta, la aparición de clientes aumenta un 2 %.",
	"Mexicana": "Por cada plato mexicano en la carta, el valor de los platos con Picante aumenta un 2 %.",
	"China": "Por cada plato chino en la carta, la aparición de clientes aumenta un 2 %.",
	"Española": "Por cada plato español en la carta, la aparición de clientes VIP aumenta un 1 %.",
	"Peruana": "Por cada plato peruano en la carta, el valor de los platos con pescado aumenta un 2 %.",
	"Marisco": "Con 6 o más platos con marisco en la carta, el valor de los platos con marisco aumenta un 25 % y la aparición de clientes VIP un 5 %.",
	"Arroz": "Con 2 o más platos con arroz en la carta, la velocidad de la cocina aumenta un 10 %. Con 5 o más, aumenta un 30 %.",
	"Carne": "Con 5 o más platos de carne en la carta, el valor de todos los platos aumenta un 30 %, pero la velocidad de la cocina baja un 30 %. Los platos con pescado o marisco quedan excluidos de ambos efectos.",
	"Pescado": "Con 3 o más platos con pescado en la carta, la velocidad de comer aumenta un 15 %. Con 6 o más, aumenta un 30 %. Si además hay 3 o más platos con marisco, el valor de los platos con pescado o marisco aumenta un 10 %.",
	"Patata": "Con 2 o más platos con patata en la carta, la velocidad de los camareros aumenta un 5 %. Con 5 o más, aumenta un 10 %. Con 10 o más, aumenta un 25 %."
}

static func tag_tooltip(tag: String) -> String:
	var description: String = TAG_EFFECTS.get(TAG_ALIASES.get(tag, tag), "")
	if description.is_empty():
		return ""
	var implemented: bool = IMPLEMENTED_TAG_EFFECTS.has(TAG_ALIASES.get(tag, tag))
	var result := "Efecto de la carta (modo Normal)\n" if implemented else "Efecto previsto (todavía no activo)\n"
	var line_length := 0
	for word in description.split(" "):
		if line_length > 0:
			if line_length + 1 + word.length() > 58:
				result += "\n"
				line_length = 0
			else:
				result += " "
				line_length += 1
		result += word
		line_length += word.length()
	return result

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
