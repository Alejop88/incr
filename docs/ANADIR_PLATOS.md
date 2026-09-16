# Añadir platos al restaurante

Solo necesitas editar `scripts/DishTypes.gd`. Los platos aparecen automáticamente en «Cocina → Crear la carta». No hace falta modificar clientes, cocina ni camareros.

## Ejemplo: añadir ensalada

1. Añade `SALAD` **al final** del enum, después de `PIZZA` (pon una coma después de `PIZZA`):

```gdscript
enum Type {
    NONE,
    BURGER,
    PIZZA,
    SALAD
}
```

2. Añade su ficha dentro de `CATALOG`:

```gdscript
Type.SALAD: {"name": "Ensalada", "icon": "🥗", "image": ""},
```

3. Ejecuta el juego, abre **Cocina → Crear la carta**, desmarca un plato y selecciona Ensalada. Pulsa **Aplicar carta**. Se permite seleccionar entre uno y dos platos.

Los clientes nuevos y las nuevas rondas VIP pedirán platos de la carta. Los pedidos anteriores siguen siendo válidos; la cocina permite prepararlos aunque hayas quitado su plato de la carta.

## Usar una imagen

Copia tu PNG o WebP, por ejemplo a `assets/art/dishes/ensalada.png`, y cambia la ficha:

```gdscript
Type.SALAD: {
    "name": "Ensalada",
    "icon": "🥗",
    "image": "res://assets/art/dishes/ensalada.png"
},
```

La imagen aparece en la carta, los botones de cocina y el pedido del cliente. Con `image` vacío se usa el icono. El icono también sirve como alternativa si la imagen no existe. Se recomienda una imagen cuadrada con fondo transparente.

## Guardado y valores

- La carta se guarda con **Escape → Guardar** y se conserva al comprar mejoras de estrellas. Aplicar cambia la carta actual; no guarda toda la partida automáticamente.
- **Nueva partida** devuelve la carta a hamburguesa y pizza.
- No renombres ni reordenes los identificadores existentes; añade los nuevos al final. Los nombres visibles sí se pueden cambiar en `name`.
- Cada plato utiliza de momento los mismos tiempos y precios base del restaurante.
- Para cambiar el máximo, modifica `MAX_MENU_DISHES` en este mismo archivo.
