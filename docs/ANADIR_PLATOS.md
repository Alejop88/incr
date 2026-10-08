# Añadir platos al restaurante

Solo necesitas editar `scripts/DishTypes.gd`. Los platos aparecen automáticamente en «Cocina → Crear la carta». No hace falta modificar clientes, cocina ni camareros.

El catálogo actual contiene los 139 platos de la lista importada. Ensalada, Sopa y Sandwich genéricos se han retirado; sus identificadores `SALAD`, `SOUP` y `SANDWICH` están reservados para no cambiar la numeración histórica y no deben reutilizarse. Los guardados conservan las recetas vigentes y descartan las retiradas; si no queda ninguna, se recupera una carta válida. Todos los platos tienen icono y campo `image`; solo la hamburguesa conserva su imagen de prueba. Las características individuales se definirán más adelante.

## Ejemplo: añadir sopa de pollo

1. Añade `CHICKEN_SOUP` **al final** del enum, después del último plato existente (sin borrar los anteriores):

```gdscript
enum Type {
    NONE,
    BURGER,
    PIZZA,
    SALAD,
    TACO,
    PAELLA,
    CHICKEN_SOUP
}
```

2. Añade su ficha dentro de `CATALOG`:

```gdscript
Type.CHICKEN_SOUP: {"name": "Sopa de pollo", "icon": "🍲", "image": ""},
```

3. Ejecuta el juego y abre **Cocina → Crear la carta**. El nuevo plato entra automáticamente en el sorteo inicial y en la compra aleatoria. Cuando lo desbloquees, desmarca un plato, selecciona Sopa de pollo y pulsa **Aplicar carta**. Se permite seleccionar entre uno y dos platos.

Los clientes nuevos y las nuevas rondas VIP pedirán platos de la carta. Los pedidos anteriores siguen siendo válidos; la cocina permite prepararlos aunque hayas quitado su plato de la carta.

## Usar una imagen

Copia tu PNG o WebP, por ejemplo a `assets/art/dishes/sopa.png`, y cambia la ficha:

```gdscript
Type.CHICKEN_SOUP: {
    "name": "Sopa de pollo",
    "icon": "🍲",
    "image": "res://assets/art/dishes/sopa.png"
},
```

La imagen aparece en la carta, los botones de cocina y el pedido del cliente. Con `image` vacío se usa el icono. El icono también sirve como alternativa si la imagen no existe. Se recomienda una imagen cuadrada con fondo transparente.

## Guardado y valores

- La carta se guarda con **Escape → Guardar** y se conserva al comprar mejoras de estrellas. Aplicar cambia la carta actual; no guarda toda la partida automáticamente.
- **Nueva partida** sortea dos platos distintos de todo el catálogo y los pone en la carta. Los demás se compran con el botón de plato aleatorio por 50 € cada uno, sin repetidos. Comprar no cambia la carta seleccionada. Los desbloqueos se guardan con la partida y se conservan al comprar mejoras de estrellas.
- No renombres ni reordenes los identificadores existentes; añade los nuevos al final. Los nombres visibles sí se pueden cambiar en `name`.
- Cada plato utiliza de momento los mismos tiempos y precios base del restaurante.
- Para cambiar el máximo, modifica `MAX_MENU_DISHES` en este mismo archivo.

- El precio de un nuevo plato se cambia en "NEW_DISH_COST" de este mismo archivo.

## Etiquetas y ficha del plato

Cada ficha admite `"tags": ["Mediterránea", "Arroz", "Para compartir"]`.
Puedes añadir o cambiar estas etiquetas en `CATALOG`; en Normal, las características implementadas se activan cuando la carta cumple sus condiciones.
Al pulsar un plato en Crear la carta aparece su ficha a la derecha, incluso si la carta está llena.
La ficha muestra el tiempo de cocina y el valor actuales del restaurante, incluidas las mejoras: todavía son iguales para todos los platos.

Las etiquetas con género usan siempre la forma femenina, referida a «comida» (por ejemplo, `Fría`, `Vegetariana` y `Mediterránea`). `DishTypes.tags()` normaliza las variantes previstas y elimina duplicados. El filtro de la carta usa estas mismas etiquetas y no cambia los platos seleccionados.

## Información del modo Normal (sin efectos aún)

Puedes añadir `"complexity": "Por definir"` y `"effect_description": "Descripción de la futura característica"` a la ficha del plato. Estos campos solo se muestran en Normal, encima de las etiquetas. Son informativos: no modifican precios, tiempos ni combos. En Cozy no aparecen.

Las 28 características de etiquetas funcionan en Normal. Sus porcentajes se editan en **`scripts/TagBalance.gd`**; las condiciones están en `scripts/TagRules.gd`, y `scripts/MenuTraits.gd` calcula sus efectos. Los textos al pasar el ratón se generan con los mismos valores de configuración. Consulta [Ajustar los porcentajes de las etiquetas](AJUSTAR_ETIQUETAS.md) para ver ejemplos, combinaciones y detalles de Para compartir.

Las variantes se unifican mediante `DishTypes.normalize_tag()`: Pan/Harina/Massa se muestran como Masa, Fideos como Pasta, Verduras como Vegetales y Americana como Estadounidense. La normalización evita contar una misma etiqueta dos veces dentro de un plato.
