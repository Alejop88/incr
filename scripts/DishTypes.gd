class_name DishTypes
extends RefCounted

# SALAD, SOUP y SANDWICH quedan reservados: retirados del catálogo, sin renumerar guardados.
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
	SASHIMI,
	URAMAKI,
	GUNKAN,
	INARI,
	ENGLISH_BREAKFAST,
	CEVICHE,
	FISH_AND_CHIPS,
	TORTILLA_DE_PATATAS,
	GAZPACHO,
	RATATOUILLE,
	QUESADILLA,
	BURRITO,
	MAC_AND_CHEESE,
	SOPA_DE_MISO,
	EDAMAME,
	POKE,
	LASANA,
	CANELONES,
	VICHYSSOISE,
	STEAK_TARTARE,
	CARPACCIO,
	BEEF_WELLINGTON,
	PATACON,
	PERCEBES,
	CHILE_EN_NOGADA,
	COCHINILLO_ASADO,
	RISOTTO,
	FOIE_GRAS,
	ROLLITOS_DE_PRIMAVERA,
	SOPA_DE_CEBOLLA,
	ALITAS_DE_POLLO,
	AROS_DE_CEBOLLA,
	TAKOYAKI,
	OKONOMIYAKI,
	RAMEN,
	HOT_DOG,
	ARROZ_TRES_DELICIAS,
	AJI_DE_GALLINA,
	MAPO_TOFU,
	CHURROS,
	HUEVOS_BENEDICT,
	HUEVOS_TURCOS,
	ACAI_BOWL,
	TORTITAS,
	WAFFLES,
	MUFFINS,
	GRATIN_DAUPHINOIS,
	PATATAS_FRITAS,
	HUO_GUO,
	FRIJOLES_CON_CHILE,
	TIRADITO,
	SUDADO_DE_PESCADO,
	CAUSA_DE_ATUN,
	PAN_CON_CHICHARRON,
	UDON,
	CHOW_MEIN,
	YAKISOBA,
	SPAGHETTI_ALLE_VONGOLE,
	JAJANGMYEON,
	GNOCCHI,
	PATATAS_BRAVAS,
	PULPO_A_LA_GALLEGA,
	GAMBAS_AL_AJILLO,
	ARROZ_CHAUFA,
	LOMO_SALTADO,
	WANTAN_FRITO,
	XIAO_LONG_BAO,
	ESCARGOTS_DE_BOURGOGNE,
	CROQUE_MONSIEUR,
	BOEUF_BOURGUIGNON,
	CONFIT_DE_PATO,
	CREPES,
	MOULES_MARINIERES,
	ALIGOT,
	CALAMARES_A_LA_ROMANA,
	PIMIENTOS_DE_PADRON,
	PAN_CON_TOMATE,
	JAMON_IBERICO,
	ALBONDIGAS_EN_SALSA,
	COCIDO_MADRILENO,
	EMPANADA_GALLEGA,
	PATATAS_A_LO_POBRE,
	HUEVOS_ROTOS,
	ENSALADILLA_RUSA,
	FIDEUA,
	CHILAQUILES,
	HUEVOS_RANCHEROS,
	POZOLE,
	ELOTE,
	ESQUITES,
	SOPA_DE_TORTILLA,
	ENCHILADAS,
	GUACAMOLE_CON_TOTOPOS,
	COCHINITA_PIBIL,
	MOLE_POBLANO,
	RAVIOLI,
	TAGLIATELLE_AL_RAGU,
	PESTO_GENOVESE,
	PARMIGIANA_DI_MELANZANE,
	ARANCINI,
	CALZONE,
	BRUSCHETTA,
	VITELLO_TONNATO,
	MINESTRONE,
	JALEA_DE_MARISCOS,
	PARIHUELA,
	TACU_TACU,
	CHUPE_DE_CAMARONES,
	PESCADO_A_LO_MACHO,
	ROCOTO_RELLENO,
	LECHE_DE_TIGRE,
	PATO_PEKINES,
	JIAOZI,
	POLLO_KUNG_PAO,
	MA_PO_BERENJENA,
	ARROZ_FRITO_CON_GAMBAS,
	SOPA_WONTON,
	BAOZI,
	LO_MEIN,
	SOBA_FRIA,
	EBI_TEMPURA,
	GYOZA,
	TONKATSU,
	CORN_DOG,
	CLUB_SANDWICH,
	PHILLY_CHEESESTEAK,
	CLAM_CHOWDER,
	PECAN_PIE,
	GUMBO,
	JAMBALAYA
}

static func dish_value(dish: int, mode: String, bonus: float = 0.0) -> float:
	return (float(CATALOG.get(dish, {}).get("value", 5.0)) if mode == "normal" else 5.0) + bonus

static func dish_cook_time(dish: int, mode: String, reduction: float = 0.0) -> float:
	var base := float(CATALOG.get(dish, {}).get("cook_time", 5.0)) if mode == "normal" else 5.0
	return maxf(0.5, base - reduction)

# Añade nuevos identificadores al final. Ver docs/ANADIR_PLATOS.md.
const CATALOG: Dictionary = {
	Type.MAKI: {"value": 4.0, "cook_time": 3.0, "name": "Maki", "icon": "🍣", "image": "res://assets/art/dishes/maki-pixel-v1.png", "tags": ["Sushi", "Arroz", "Pescado", "Fría", "Japonesa"]},
	Type.SASHIMI: {"value": 8.0, "cook_time": 2.0, "name": "Sashimi", "icon": "🐟", "image": "", "tags": ["Pescado", "Cruda", "Fría", "Japonesa"]},
	Type.ONIGIRI: {"value": 3.0, "cook_time": 2.0, "name": "Onigiri", "icon": "🍙", "image": "", "tags": ["Arroz", "Japonesa"]},
	Type.TEMAKI: {"value": 5.0, "cook_time": 3.0, "name": "Temaki", "icon": "🍣", "image": "", "tags": ["Sushi", "Arroz", "Pescado", "Fría", "Japonesa"]},
	Type.URAMAKI: {"value": 5.0, "cook_time": 3.0, "name": "Uramaki", "icon": "🍣", "image": "", "tags": ["Sushi", "Arroz", "Pescado", "Fría", "Japonesa"]},
	Type.GUNKAN: {"value": 6.0, "cook_time": 3.0, "name": "Gunkan", "icon": "🍣", "image": "", "tags": ["Sushi", "Arroz", "Marisco", "Fría", "Japonesa"]},
	Type.INARI: {"value": 4.0, "cook_time": 2.0, "name": "Inari", "icon": "🍣", "image": "", "tags": ["Sushi", "Arroz", "Vegetariana", "Japonesa"]},
	Type.NIGIRI: {"value": 6.0, "cook_time": 3.0, "name": "Nigiri", "icon": "🍣", "image": "", "tags": ["Sushi", "Arroz", "Pescado", "Cruda", "Fría", "Japonesa"]},
	Type.ENGLISH_BREAKFAST: {"value": 6.0, "cook_time": 5.0, "name": "English breakfast", "icon": "🍳", "image": "", "tags": ["Desayuno", "Carne", "Frita"]},
	Type.CEVICHE: {"value": 7.0, "cook_time": 4.0, "name": "Ceviche", "icon": "🐟", "image": "", "tags": ["Peruana", "Pescado", "Marisco", "Cruda", "Fría", "Picante"]},
	Type.FALAFEL: {"value": 3.0, "cook_time": 3.0, "name": "Falafel", "icon": "🧆", "image": "", "tags": ["Frita", "Vegetales", "Vegetariana", "Vegana", "Comida rápida"]},
	Type.FISH_AND_CHIPS: {"value": 5.0, "cook_time": 4.0, "name": "Fish and chips", "icon": "🐟", "image": "", "tags": ["Pescado", "Patata", "Frita", "Comida rápida"]},
	Type.PAELLA: {"value": 8.0, "cook_time": 7.0, "name": "Paella", "icon": "🥘", "image": "res://assets/art/dishes/paella-pixel-v1.png", "tags": ["Arroz", "Marisco", "Pescado", "Española", "Para compartir"]},
	Type.TORTILLA_DE_PATATAS: {"value": 4.0, "cook_time": 4.0, "name": "Tortilla de patatas", "icon": "🍳", "image": "", "tags": ["Patata", "Vegetariana", "Española", "Para compartir"]},
	Type.GAZPACHO: {"value": 3.0, "cook_time": 2.0, "name": "Gazpacho", "icon": "🥣", "image": "", "tags": ["Fría", "Vegetales", "Vegetariana", "Vegana", "Española", "Caldo"]},
	Type.RATATOUILLE: {"value": 5.0, "cook_time": 5.0, "name": "Ratatouille", "icon": "🍆", "image": "", "tags": ["Vegetales", "Vegetariana", "Vegana", "Francesa"]},
	Type.TACO: {"value": 4.0, "cook_time": 3.0, "name": "Taco", "icon": "🌮", "image": "", "tags": ["Mexicana", "Picante", "Carne", "Vegetales", "Comida rápida", "Masa"]},
	Type.QUESADILLA: {"value": 3.0, "cook_time": 3.0, "name": "Quesadilla", "icon": "🫓", "image": "", "tags": ["Mexicana", "Comida rápida", "Masa", "Vegetariana"]},
	Type.BURRITO: {"value": 5.0, "cook_time": 4.0, "name": "Burrito", "icon": "🌯", "image": "", "tags": ["Mexicana", "Arroz", "Carne", "Vegetales", "Comida rápida", "Masa"]},
	Type.MAC_AND_CHEESE: {"value": 4.0, "cook_time": 3.0, "name": "Mac and cheese", "icon": "🍝", "image": "", "tags": ["Pasta", "Vegetariana", "Comida rápida", "Estadounidense"]},
	Type.SOPA_DE_MISO: {"value": 3.0, "cook_time": 2.0, "name": "Sopa de miso", "icon": "🍲", "image": "", "tags": ["Caldo", "Japonesa"]},
	Type.EDAMAME: {"value": 3.0, "cook_time": 2.0, "name": "Edamame", "icon": "🫛", "image": "", "tags": ["Vegetales", "Vegetariana", "Vegana", "Japonesa", "Para compartir"]},
	Type.POKE: {"value": 6.0, "cook_time": 3.0, "name": "Poke", "icon": "🥗", "image": "", "tags": ["Arroz", "Pescado", "Cruda", "Fría"]},
	Type.PIZZA: {"value": 6.0, "cook_time": 5.0, "name": "Pizza", "icon": "🍕", "image": "res://assets/art/dishes/pizza-pixel-v1.png", "tags": ["Italiana", "Masa", "Comida rápida", "Para compartir"]},
	Type.LASANA: {"value": 6.0, "cook_time": 5.0, "name": "Lasaña", "icon": "🍝", "image": "", "tags": ["Italiana", "Pasta", "Carne"]},
	Type.CANELONES: {"value": 6.0, "cook_time": 5.0, "name": "Canelones", "icon": "🍝", "image": "", "tags": ["Italiana", "Pasta", "Carne"]},
	Type.VICHYSSOISE: {"value": 4.0, "cook_time": 2.0, "name": "Vichyssoise", "icon": "🥣", "image": "", "tags": ["Caldo", "Fría", "Patata", "Vegetariana", "Francesa"]},
	Type.STEAK_TARTARE: {"value": 9.0, "cook_time": 3.0, "name": "Steak tartare", "icon": "🥩", "image": "", "tags": ["Carne", "Cruda", "Fría", "Gourmet", "Francesa"]},
	Type.CARPACCIO: {"value": 8.0, "cook_time": 3.0, "name": "Carpaccio", "icon": "🥩", "image": "", "tags": ["Carne", "Cruda", "Fría", "Gourmet", "Italiana"]},
	Type.BEEF_WELLINGTON: {"value": 12.0, "cook_time": 7.0, "name": "Beef Wellington", "icon": "🥩", "image": "", "tags": ["Carne", "Gourmet", "Masa"]},
	Type.PATACON: {"value": 3.0, "cook_time": 3.0, "name": "Patacón", "icon": "🍌", "image": "", "tags": ["Frita", "Vegetariana", "Vegana", "Para compartir"]},
	Type.PERCEBES: {"value": 12.0, "cook_time": 3.0, "name": "Percebes", "icon": "🦪", "image": "", "tags": ["Marisco", "Gourmet", "Para compartir"]},
	Type.CHILE_EN_NOGADA: {"value": 8.0, "cook_time": 6.0, "name": "Chile en nogada", "icon": "🫑", "image": "", "tags": ["Mexicana", "Carne", "Vegetales", "Gourmet"]},
	Type.COCHINILLO_ASADO: {"value": 11.0, "cook_time": 7.0, "name": "Cochinillo asado", "icon": "🍖", "image": "", "tags": ["Carne", "Española", "Gourmet", "Para compartir"]},
	Type.RISOTTO: {"value": 7.0, "cook_time": 6.0, "name": "Risotto", "icon": "🍚", "image": "", "tags": ["Arroz", "Italiana", "Gourmet"]},
	Type.FOIE_GRAS: {"value": 11.0, "cook_time": 3.0, "name": "Foie gras", "icon": "🍽️", "image": "", "tags": ["Gourmet", "Francesa"]},
	Type.ROLLITOS_DE_PRIMAVERA: {"value": 4.0, "cook_time": 3.0, "name": "Rollitos de primavera", "icon": "🥟", "image": "", "tags": ["China", "Frita", "Vegetales", "Comida rápida", "Masa", "Para compartir"]},
	Type.SOPA_DE_CEBOLLA: {"value": 4.0, "cook_time": 4.0, "name": "Sopa de cebolla", "icon": "🍲", "image": "", "tags": ["Caldo", "Vegetales", "Francesa"]},
	Type.ALITAS_DE_POLLO: {"value": 4.0, "cook_time": 4.0, "name": "Alitas de pollo", "icon": "🍗", "image": "", "tags": ["Carne", "Frita", "Comida rápida", "Para compartir", "Estadounidense"]},
	Type.AROS_DE_CEBOLLA: {"value": 3.0, "cook_time": 3.0, "name": "Aros de cebolla", "icon": "🧅", "image": "", "tags": ["Vegetales", "Vegetariana", "Frita", "Comida rápida", "Para compartir", "Estadounidense"]},
	Type.TAKOYAKI: {"value": 4.0, "cook_time": 4.0, "name": "Takoyaki", "icon": "🐙", "image": "", "tags": ["Marisco", "Japonesa", "Comida rápida", "Masa", "Para compartir"]},
	Type.OKONOMIYAKI: {"value": 5.0, "cook_time": 4.0, "name": "Okonomiyaki", "icon": "🥞", "image": "", "tags": ["Japonesa", "Vegetales", "Masa", "Para compartir"]},
	Type.RAMEN: {"value": 7.0, "cook_time": 5.0, "name": "Ramen", "icon": "🍲", "image": "", "tags": ["Caldo", "Japonesa", "Pasta"]},
	Type.BURGER: {"value": 5.0, "cook_time": 4.0, "name": "Hamburguesa", "icon": "🍔", "image": "res://assets/art/food/burger.jpg", "tags": ["Carne", "Vegetales", "Comida rápida", "Masa", "Estadounidense"]},
	Type.HOT_DOG: {"value": 3.0, "cook_time": 2.0, "name": "Hot dog", "icon": "🌭", "image": "", "tags": ["Carne", "Comida rápida", "Masa", "Estadounidense"]},
	Type.ARROZ_TRES_DELICIAS: {"value": 4.0, "cook_time": 3.0, "name": "Arroz tres delicias", "icon": "🍚", "image": "", "tags": ["Arroz", "China", "Carne", "Vegetales"]},
	Type.AJI_DE_GALLINA: {"value": 5.0, "cook_time": 4.0, "name": "Ají de gallina", "icon": "🍗", "image": "", "tags": ["Peruana", "Carne", "Picante"]},
	Type.MAPO_TOFU: {"value": 5.0, "cook_time": 4.0, "name": "Mapo tofu", "icon": "🥘", "image": "", "tags": ["China", "Picante", "Vegetales", "Carne"]},
	Type.CHURROS: {"value": 3.0, "cook_time": 3.0, "name": "Churros", "icon": "🥖", "image": "", "tags": ["Desayuno", "Frita", "Vegetariana", "Española", "Masa", "Para compartir"]},
	Type.HUEVOS_BENEDICT: {"value": 6.0, "cook_time": 4.0, "name": "Huevos Benedict", "icon": "🍳", "image": "", "tags": ["Desayuno", "Gourmet", "Carne", "Masa"]},
	Type.HUEVOS_TURCOS: {"value": 5.0, "cook_time": 3.0, "name": "Huevos turcos", "icon": "🍳", "image": "", "tags": ["Desayuno", "Picante", "Vegetariana"]},
	Type.ACAI_BOWL: {"value": 5.0, "cook_time": 2.0, "name": "Açaí bowl", "icon": "🫐", "image": "", "tags": ["Desayuno", "Fría", "Vegetales", "Vegetariana", "Vegana"]},
	Type.TORTITAS: {"value": 4.0, "cook_time": 3.0, "name": "Tortitas", "icon": "🥞", "image": "", "tags": ["Desayuno", "Vegetariana", "Masa", "Estadounidense"]},
	Type.WAFFLES: {"value": 4.0, "cook_time": 3.0, "name": "Waffles", "icon": "🧇", "image": "", "tags": ["Desayuno", "Vegetariana", "Masa", "Estadounidense"]},
	Type.MUFFINS: {"value": 3.0, "cook_time": 2.0, "name": "Muffins", "icon": "🧁", "image": "", "tags": ["Desayuno", "Vegetariana", "Masa", "Estadounidense"]},
	Type.GRATIN_DAUPHINOIS: {"value": 5.0, "cook_time": 5.0, "name": "Gratin dauphinois", "icon": "🥔", "image": "", "tags": ["Patata", "Gourmet", "Vegetariana", "Francesa"]},
	Type.PATATAS_FRITAS: {"value": 3.0, "cook_time": 3.0, "name": "Patatas fritas", "icon": "🍟", "image": "", "tags": ["Patata", "Frita", "Vegetariana", "Vegana", "Comida rápida", "Para compartir"]},
	Type.HUO_GUO: {"value": 9.0, "cook_time": 6.0, "name": "Huo Guo", "icon": "🍲", "image": "", "tags": ["Caldo", "Picante", "China", "Para compartir"]},
	Type.FRIJOLES_CON_CHILE: {"value": 4.0, "cook_time": 3.0, "name": "Frijoles con chile", "icon": "🫘", "image": "", "tags": ["Picante", "Vegetales", "Vegetariana", "Vegana", "Mexicana"]},
	Type.TIRADITO: {"value": 8.0, "cook_time": 3.0, "name": "Tiradito", "icon": "🐟", "image": "", "tags": ["Peruana", "Pescado", "Cruda", "Fría", "Picante"]},
	Type.SUDADO_DE_PESCADO: {"value": 7.0, "cook_time": 5.0, "name": "Sudado de pescado", "icon": "🍲", "image": "", "tags": ["Peruana", "Pescado", "Caldo"]},
	Type.CAUSA_DE_ATUN: {"value": 5.0, "cook_time": 3.0, "name": "Causa de atún", "icon": "🥔", "image": "", "tags": ["Peruana", "Pescado", "Patata", "Fría"]},
	Type.PAN_CON_CHICHARRON: {"value": 4.0, "cook_time": 2.0, "name": "Pan con chicharrón", "icon": "🥪", "image": "", "tags": ["Peruana", "Carne", "Desayuno", "Comida rápida", "Masa"]},
	Type.UDON: {"value": 5.0, "cook_time": 4.0, "name": "Udon", "icon": "🍝", "image": "", "tags": ["Pasta", "Japonesa"]},
	Type.CHOW_MEIN: {"value": 5.0, "cook_time": 4.0, "name": "Chow mein", "icon": "🍝", "image": "", "tags": ["Pasta", "China", "Vegetales"]},
	Type.YAKISOBA: {"value": 5.0, "cook_time": 4.0, "name": "Yakisoba", "icon": "🍝", "image": "", "tags": ["Pasta", "Japonesa", "Vegetales", "Comida rápida"]},
	Type.SPAGHETTI_ALLE_VONGOLE: {"value": 8.0, "cook_time": 5.0, "name": "Spaghetti alle vongole", "icon": "🍝", "image": "", "tags": ["Pasta", "Italiana", "Marisco", "Gourmet"]},
	Type.JAJANGMYEON: {"value": 6.0, "cook_time": 4.0, "name": "Jajangmyeon", "icon": "🍝", "image": "", "tags": ["Pasta", "Carne", "Vegetales"]},
	Type.GNOCCHI: {"value": 5.0, "cook_time": 4.0, "name": "Gnocchi", "icon": "🥔", "image": "", "tags": ["Patata", "Italiana", "Vegetariana"]},
	Type.PATATAS_BRAVAS: {"value": 4.0, "cook_time": 3.0, "name": "Patatas bravas", "icon": "🥔", "image": "", "tags": ["Patata", "Española", "Picante", "Frita", "Para compartir"]},
	Type.PULPO_A_LA_GALLEGA: {"value": 9.0, "cook_time": 3.0, "name": "Pulpo a la gallega", "icon": "🐙", "image": "", "tags": ["Marisco", "Española", "Patata", "Para compartir"]},
	Type.GAMBAS_AL_AJILLO: {"value": 8.0, "cook_time": 3.0, "name": "Gambas al ajillo", "icon": "🦐", "image": "", "tags": ["Marisco", "Española", "Para compartir"]},
	Type.ARROZ_CHAUFA: {"value": 5.0, "cook_time": 3.0, "name": "Arroz chaufa", "icon": "🍚", "image": "", "tags": ["Arroz", "Peruana", "China"]},
	Type.LOMO_SALTADO: {"value": 7.0, "cook_time": 4.0, "name": "Lomo saltado", "icon": "🥩", "image": "", "tags": ["Carne", "Peruana", "Vegetales"]},
	Type.WANTAN_FRITO: {"value": 4.0, "cook_time": 3.0, "name": "Wantán frito", "icon": "🥟", "image": "", "tags": ["China", "Frita", "Masa", "Comida rápida", "Para compartir"]},
	Type.XIAO_LONG_BAO: {"value": 6.0, "cook_time": 5.0, "name": "Xiao long bao", "icon": "🥟", "image": "", "tags": ["China", "Masa", "Para compartir"]},
	Type.ESCARGOTS_DE_BOURGOGNE: {"value": 8.0, "cook_time": 4.0, "name": "Escargots de Bourgogne", "icon": "🐌", "image": "", "tags": ["Francesa", "Gourmet"]},
	Type.CROQUE_MONSIEUR: {"value": 5.0, "cook_time": 3.0, "name": "Croque monsieur", "icon": "🥪", "image": "", "tags": ["Francesa", "Masa", "Carne", "Comida rápida"]},
	Type.BOEUF_BOURGUIGNON: {"value": 9.0, "cook_time": 6.0, "name": "Boeuf bourguignon", "icon": "🥩", "image": "", "tags": ["Francesa", "Carne", "Gourmet"]},
	Type.CONFIT_DE_PATO: {"value": 10.0, "cook_time": 6.0, "name": "Confit de pato", "icon": "🍗", "image": "", "tags": ["Francesa", "Carne", "Gourmet"]},
	Type.CREPES: {"value": 4.0, "cook_time": 3.0, "name": "Crêpes", "icon": "🥞", "image": "", "tags": ["Francesa", "Masa", "Desayuno", "Vegetariana"]},
	Type.MOULES_MARINIERES: {"value": 8.0, "cook_time": 4.0, "name": "Moules marinières", "icon": "🦪", "image": "", "tags": ["Francesa", "Marisco", "Gourmet", "Para compartir"]},
	Type.ALIGOT: {"value": 5.0, "cook_time": 3.0, "name": "Aligot", "icon": "🥔", "image": "", "tags": ["Francesa", "Patata", "Vegetariana", "Gourmet"]},
	Type.CALAMARES_A_LA_ROMANA: {"value": 6.0, "cook_time": 4.0, "name": "Calamares a la romana", "icon": "🦑", "image": "", "tags": ["Española", "Marisco", "Frita", "Para compartir"]},
	Type.PIMIENTOS_DE_PADRON: {"value": 3.0, "cook_time": 2.0, "name": "Pimientos de Padrón", "icon": "🫑", "image": "", "tags": ["Española", "Vegetales", "Vegetariana", "Vegana", "Para compartir"]},
	Type.PAN_CON_TOMATE: {"value": 2.0, "cook_time": 1.0, "name": "Pan con tomate", "icon": "🍞", "image": "", "tags": ["Española", "Masa", "Vegetales", "Vegetariana", "Vegana"]},
	Type.JAMON_IBERICO: {"value": 10.0, "cook_time": 1.0, "name": "Jamón ibérico", "icon": "🍖", "image": "", "tags": ["Española", "Carne", "Gourmet", "Para compartir"]},
	Type.ALBONDIGAS_EN_SALSA: {"value": 5.0, "cook_time": 4.0, "name": "Albóndigas en salsa", "icon": "🧆", "image": "", "tags": ["Española", "Carne", "Para compartir"]},
	Type.COCIDO_MADRILENO: {"value": 7.0, "cook_time": 6.0, "name": "Cocido madrileño", "icon": "🍲", "image": "", "tags": ["Española", "Carne", "Caldo", "Para compartir"]},
	Type.EMPANADA_GALLEGA: {"value": 5.0, "cook_time": 3.0, "name": "Empanada gallega", "icon": "🥟", "image": "", "tags": ["Española", "Masa", "Para compartir"]},
	Type.PATATAS_A_LO_POBRE: {"value": 4.0, "cook_time": 3.0, "name": "Patatas a lo pobre", "icon": "🥔", "image": "", "tags": ["Española", "Patata", "Vegetales", "Vegetariana", "Vegana"]},
	Type.HUEVOS_ROTOS: {"value": 5.0, "cook_time": 3.0, "name": "Huevos rotos", "icon": "🍳", "image": "", "tags": ["Española", "Patata", "Para compartir"]},
	Type.ENSALADILLA_RUSA: {"value": 4.0, "cook_time": 2.0, "name": "Ensaladilla rusa", "icon": "🥗", "image": "", "tags": ["Española", "Patata", "Fría", "Para compartir"]},
	Type.FIDEUA: {"value": 8.0, "cook_time": 7.0, "name": "Fideuà", "icon": "🍝", "image": "", "tags": ["Española", "Pasta", "Marisco", "Para compartir"]},
	Type.CHILAQUILES: {"value": 4.0, "cook_time": 3.0, "name": "Chilaquiles", "icon": "🥘", "image": "", "tags": ["Mexicana", "Picante", "Desayuno", "Masa", "Para compartir"]},
	Type.HUEVOS_RANCHEROS: {"value": 5.0, "cook_time": 3.0, "name": "Huevos rancheros", "icon": "🍳", "image": "", "tags": ["Mexicana", "Picante", "Desayuno"]},
	Type.POZOLE: {"value": 6.0, "cook_time": 5.0, "name": "Pozole", "icon": "🍲", "image": "", "tags": ["Mexicana", "Caldo", "Carne", "Picante", "Para compartir"]},
	Type.ELOTE: {"value": 3.0, "cook_time": 2.0, "name": "Elote", "icon": "🌽", "image": "", "tags": ["Mexicana", "Vegetales", "Vegetariana", "Para compartir"]},
	Type.ESQUITES: {"value": 3.0, "cook_time": 2.0, "name": "Esquites", "icon": "🌽", "image": "", "tags": ["Mexicana", "Vegetales", "Vegetariana", "Para compartir"]},
	Type.SOPA_DE_TORTILLA: {"value": 5.0, "cook_time": 4.0, "name": "Sopa de tortilla", "icon": "🍲", "image": "", "tags": ["Mexicana", "Caldo", "Picante", "Masa"]},
	Type.ENCHILADAS: {"value": 6.0, "cook_time": 4.0, "name": "Enchiladas", "icon": "🌯", "image": "", "tags": ["Mexicana", "Masa", "Carne", "Picante", "Para compartir"]},
	Type.GUACAMOLE_CON_TOTOPOS: {"value": 5.0, "cook_time": 2.0, "name": "Guacamole con totopos", "icon": "🥑", "image": "", "tags": ["Mexicana", "Vegetales", "Vegana", "Masa", "Para compartir"]},
	Type.COCHINITA_PIBIL: {"value": 7.0, "cook_time": 4.0, "name": "Cochinita pibil", "icon": "🍖", "image": "", "tags": ["Mexicana", "Carne", "Picante", "Para compartir"]},
	Type.MOLE_POBLANO: {"value": 8.0, "cook_time": 6.0, "name": "Mole poblano", "icon": "🍗", "image": "", "tags": ["Mexicana", "Carne", "Gourmet", "Picante"]},
	Type.RAVIOLI: {"value": 6.0, "cook_time": 4.0, "name": "Ravioli", "icon": "🍝", "image": "", "tags": ["Italiana", "Pasta", "Gourmet"]},
	Type.TAGLIATELLE_AL_RAGU: {"value": 6.0, "cook_time": 4.0, "name": "Tagliatelle al ragù", "icon": "🍝", "image": "", "tags": ["Italiana", "Pasta", "Carne", "Gourmet"]},
	Type.PESTO_GENOVESE: {"value": 5.0, "cook_time": 3.0, "name": "Pesto genovese", "icon": "🍝", "image": "", "tags": ["Italiana", "Pasta", "Vegetales", "Vegetariana"]},
	Type.PARMIGIANA_DI_MELANZANE: {"value": 6.0, "cook_time": 5.0, "name": "Parmigiana di melanzane", "icon": "🍆", "image": "", "tags": ["Italiana", "Vegetales", "Vegetariana", "Gourmet"]},
	Type.ARANCINI: {"value": 4.0, "cook_time": 3.0, "name": "Arancini", "icon": "🍙", "image": "", "tags": ["Italiana", "Arroz", "Frita", "Comida rápida", "Para compartir"]},
	Type.CALZONE: {"value": 6.0, "cook_time": 5.0, "name": "Calzone", "icon": "🥟", "image": "", "tags": ["Italiana", "Masa", "Comida rápida"]},
	Type.BRUSCHETTA: {"value": 3.0, "cook_time": 2.0, "name": "Bruschetta", "icon": "🍞", "image": "", "tags": ["Italiana", "Masa", "Vegetales", "Vegetariana", "Para compartir"]},
	Type.VITELLO_TONNATO: {"value": 7.0, "cook_time": 3.0, "name": "Vitello tonnato", "icon": "🥩", "image": "", "tags": ["Italiana", "Carne", "Fría", "Gourmet"]},
	Type.MINESTRONE: {"value": 4.0, "cook_time": 4.0, "name": "Minestrone", "icon": "🍲", "image": "", "tags": ["Italiana", "Caldo", "Vegetales", "Vegetariana"]},
	Type.JALEA_DE_MARISCOS: {"value": 8.0, "cook_time": 5.0, "name": "Jalea de mariscos", "icon": "🦐", "image": "", "tags": ["Peruana", "Marisco", "Pescado", "Frita", "Para compartir"]},
	Type.PARIHUELA: {"value": 9.0, "cook_time": 6.0, "name": "Parihuela", "icon": "🍲", "image": "", "tags": ["Peruana", "Marisco", "Pescado", "Caldo", "Picante"]},
	Type.TACU_TACU: {"value": 5.0, "cook_time": 4.0, "name": "Tacu tacu", "icon": "🍚", "image": "", "tags": ["Peruana", "Arroz", "Vegetariana"]},
	Type.CHUPE_DE_CAMARONES: {"value": 9.0, "cook_time": 6.0, "name": "Chupe de camarones", "icon": "🍲", "image": "", "tags": ["Peruana", "Marisco", "Caldo", "Gourmet"]},
	Type.PESCADO_A_LO_MACHO: {"value": 9.0, "cook_time": 6.0, "name": "Pescado a lo macho", "icon": "🐟", "image": "", "tags": ["Peruana", "Pescado", "Marisco", "Picante", "Gourmet"]},
	Type.ROCOTO_RELLENO: {"value": 6.0, "cook_time": 5.0, "name": "Rocoto relleno", "icon": "🫑", "image": "", "tags": ["Peruana", "Picante", "Carne", "Gourmet"]},
	Type.LECHE_DE_TIGRE: {"value": 5.0, "cook_time": 2.0, "name": "Leche de tigre", "icon": "🥣", "image": "", "tags": ["Peruana", "Pescado", "Marisco", "Cruda", "Fría"]},
	Type.PATO_PEKINES: {"value": 11.0, "cook_time": 7.0, "name": "Pato pekinés", "icon": "🍗", "image": "", "tags": ["China", "Carne", "Gourmet", "Para compartir"]},
	Type.JIAOZI: {"value": 5.0, "cook_time": 4.0, "name": "Jiaozi", "icon": "🥟", "image": "", "tags": ["China", "Masa", "Carne", "Para compartir"]},
	Type.POLLO_KUNG_PAO: {"value": 6.0, "cook_time": 4.0, "name": "Pollo Kung Pao", "icon": "🍗", "image": "", "tags": ["China", "Carne", "Picante", "Vegetales"]},
	Type.MA_PO_BERENJENA: {"value": 5.0, "cook_time": 4.0, "name": "Ma po berenjena", "icon": "🍆", "image": "", "tags": ["China", "Picante", "Vegetales", "Vegetariana"]},
	Type.ARROZ_FRITO_CON_GAMBAS: {"value": 6.0, "cook_time": 3.0, "name": "Arroz frito con gambas", "icon": "🍚", "image": "", "tags": ["China", "Arroz", "Marisco", "Comida rápida"]},
	Type.SOPA_WONTON: {"value": 5.0, "cook_time": 4.0, "name": "Sopa wonton", "icon": "🍲", "image": "", "tags": ["China", "Caldo", "Masa", "Carne"]},
	Type.BAOZI: {"value": 5.0, "cook_time": 4.0, "name": "Baozi", "icon": "🥟", "image": "", "tags": ["China", "Masa", "Carne", "Para compartir"]},
	Type.LO_MEIN: {"value": 5.0, "cook_time": 4.0, "name": "Lo mein", "icon": "🍝", "image": "", "tags": ["China", "Pasta", "Vegetales"]},
	Type.SOBA_FRIA: {"value": 5.0, "cook_time": 3.0, "name": "Soba fría", "icon": "🍝", "image": "", "tags": ["Japonesa", "Pasta", "Fría", "Vegetariana"]},
	Type.EBI_TEMPURA: {"value": 7.0, "cook_time": 4.0, "name": "Ebi tempura", "icon": "🍤", "image": "", "tags": ["Japonesa", "Marisco", "Frita", "Para compartir"]},
	Type.GYOZA: {"value": 5.0, "cook_time": 4.0, "name": "Gyoza", "icon": "🥟", "image": "", "tags": ["Japonesa", "Masa", "Carne", "Para compartir"]},
	Type.TONKATSU: {"value": 6.0, "cook_time": 4.0, "name": "Tonkatsu", "icon": "🥩", "image": "", "tags": ["Japonesa", "Carne", "Frita"]},
	Type.CORN_DOG: {"value": 3.0, "cook_time": 3.0, "name": "Corn dog", "icon": "🌭", "image": "", "tags": ["Estadounidense", "Carne", "Masa", "Frita", "Comida rápida"]},
	Type.CLUB_SANDWICH: {"value": 5.0, "cook_time": 3.0, "name": "Club sandwich", "icon": "🥪", "image": "", "tags": ["Estadounidense", "Carne", "Masa", "Comida rápida"]},
	Type.PHILLY_CHEESESTEAK: {"value": 6.0, "cook_time": 4.0, "name": "Philly cheesesteak", "icon": "🥪", "image": "", "tags": ["Estadounidense", "Carne", "Masa", "Comida rápida"]},
	Type.CLAM_CHOWDER: {"value": 6.0, "cook_time": 4.0, "name": "Clam chowder", "icon": "🍲", "image": "", "tags": ["Estadounidense", "Caldo", "Marisco", "Gourmet"]},
	Type.PECAN_PIE: {"value": 5.0, "cook_time": 2.0, "name": "Pecan pie", "icon": "🥧", "image": "", "tags": ["Estadounidense", "Masa", "Gourmet", "Vegetariana"]},
	Type.GUMBO: {"value": 7.0, "cook_time": 6.0, "name": "Gumbo", "icon": "🍲", "image": "", "tags": ["Estadounidense", "Caldo", "Marisco", "Carne", "Picante"]},
	Type.JAMBALAYA: {"value": 7.0, "cook_time": 6.0, "name": "Jambalaya", "icon": "🍚", "image": "", "tags": ["Estadounidense", "Arroz", "Marisco", "Carne", "Picante"]}
}
const MAX_MENU_DISHES: int = 2
const MAX_UPGRADED_MENU_DISHES: int = 10
const NEW_DISH_COST: float = 50.0
const TAG_ALIASES := {"Frío": "Fría", "Fresco": "Fresca", "Vegetariano": "Vegetariana", "Ligero": "Ligera", "Especiado": "Especiada", "Mediterráneo": "Mediterránea", "Americano": "Americana", "Italiano": "Italiana", "Mexicano": "Mexicana", "Japonés": "Japonesa", "Chino": "China", "Español": "Española", "Peru": "Peruana", "Perú": "Peruana", "Peruano": "Peruana", "Frito": "Frita", "Fritura": "Frita", "Sopa": "Caldo", "Sopas": "Caldo", "Caldoso": "Caldo", "Caldosos": "Caldo", "Comida Rapida": "Comida rápida"}

const BALANCE = preload("res://scripts/TagBalance.gd")
const RULES = preload("res://scripts/TagRules.gd")

static func implemented_tags() -> Array[String]:
	return RULES.tags()

static func normalize_tag(value: String) -> String:
	var tag := value.strip_edges()
	var extra := {"Crudo": "Cruda", "Vegano": "Vegana", "Verduras": "Vegetales", "Vegetal": "Vegetales", "Pan": "Masa", "Harina": "Masa", "Massa": "Masa", "Fideos": "Pasta", "Pasta/Fideos": "Pasta", "Americana": "Estadounidense", "Americano": "Estadounidense", "Francés": "Francesa", "Frances": "Francesa", "Para Compartir": "Para compartir", "Comida Rápida": "Comida rápida"}
	return extra.get(tag, TAG_ALIASES.get(tag, tag))

static func tag_tooltip(tag: String) -> String:
	var description := RULES.description(normalize_tag(tag), BALANCE.PERCENTAGES)
	if description.is_empty():
		return ""
	var result := "Efecto de la carta (modo Normal)\n"
	for paragraph in description.split("\n"):
		var line_length := 0
		for word in paragraph.split(" "):
			if line_length > 0:
				if line_length + 1 + word.length() > 58:
					result += "\n"
					line_length = 0
				else:
					result += " "
					line_length += 1
			result += word
			line_length += word.length()
		result += "\n"
	return result.strip_edges()

static func tags(dish: int) -> PackedStringArray:
	var result := PackedStringArray()
	for value in CATALOG.get(dish, {}).get("tags", []):
		var tag := normalize_tag(str(value))
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
