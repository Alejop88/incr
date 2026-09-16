# Añadir platos al restaurante

Solo necesitas editar `scripts/DishTypes.gd`. Los platos aparecen automáticamente en «Cocina → Crear la carta». No hace falta modificar clientes, cocina ni camareros.

## Ejemplo: añadir sopa

1. Añade `SOUP` **al final** del enum, después del último plato existente (sin borrar los anteriores):

```gdscript
enum Type {
    NONE,
    BURGER,
    PIZZA,
    SALAD,
    TACO,
    PAELLA,
    SOUP
}
```

2. Añade su ficha dentro de `CATALOG`:

```gdscript
Type.SOUP: {"name": "Sopa", "icon": "🍲", "image": ""},
```

3. Ejecuta el juego y abre **Cocina → Crear la carta**. El nuevo plato entra automáticamente en el sorteo inicial y en la compra aleatoria. Cuando lo desbloquees, desmarca un plato, selecciona Sopa y pulsa **Aplicar carta**. Se permite seleccionar entre uno y dos platos.

Los clientes nuevos y las nuevas rondas VIP pedirán platos de la carta. Los pedidos anteriores siguen siendo válidos; la cocina permite prepararlos aunque hayas quitado su plato de la carta.

## Usar una imagen

Copia tu PNG o WebP, por ejemplo a `assets/art/dishes/sopa.png`, y cambia la ficha:

```gdscript
Type.SOUP: {
    "name": "Sopa",
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
