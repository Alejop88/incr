# Ajustar los porcentajes de las etiquetas

Abre **`scripts/TagBalance.gd`**. Es el único archivo que necesitas editar para cambiar porcentajes. Los valores están agrupados por etiqueta.

Por ejemplo, para que cada plato Picante dé un 3 % de velocidad a los camareros en vez de un 2 %, cambia:

```gdscript
"picante_camareros_por_plato": 2.0,
```

por:

```gdscript
"picante_camareros_por_plato": 3.0,
```

Guarda el archivo y vuelve a ejecutar el juego. Se aplica también al cargar una partida existente: no necesitas empezar de cero. Los efectos, los textos al pasar el ratón y los porcentajes del panel se generan a partir de estos mismos números.

- `20.0` significa **20 %**, no `0.20`. Puedes usar decimales, por ejemplo `2.5`.
- Un número negativo reduce la estadística: `-2.0` significa **−2 %**.
- Cambia solo el número; conserva el nombre entre comillas, los dos puntos y la coma final.
- Los sufijos `_2`, `_5`, `_10`, etc. indican el tramo. Cambiar el número a la derecha cambia su porcentaje, no la cantidad de platos necesaria.
- Los nombres con `_por_plato` se multiplican por el número de platos distintos con esa etiqueta que hay en la carta.
- No necesitas tocar `TagRules.gd`: allí están las condiciones, los umbrales y los tipos de platos afectados. `MenuTraits.gd` calcula los resultados.

## Cómo se combinan

Solo funcionan en **Normal**. Cozy conserva sus estadísticas habituales. No se guardan como mejoras compradas: se recalculan desde la carta y se combinan con las mejoras de dinero y estrellas.

En una misma etiqueta se usa el tramo mayor alcanzado: 5 platos de Arroz dan el 30 %, sin sumar también el 10 % del tramo de dos platos. Las características distintas se multiplican. Por ejemplo, una cocina un 30 % más rápida y otro bonus de un 10 % dan una velocidad de `1.3 × 1.1 = 1.43`.

**Velocidad y tiempo son distintos:** +30 % de velocidad divide el tiempo entre 1.3. +20 % de tiempo de cocina, como el coste de Caldo, multiplica el tiempo por 1.2. Los efectos de Carne excluyen completamente a los platos con Pescado o Marisco. Un plato con ambas etiquetas recibe una sola vez el bonus compartido del 10 %; puede combinarlo con el bonus propio de Marisco.

Los cambios de carta no reinician preparaciones, comidas ni esperas en curso. Los nuevos tiempos se usan al comenzar la siguiente actividad. El valor de los platos servidos conserva su bonificación hasta cobrar. Las tasas VIP son cambios relativos y nunca desbloquean VIP por sí solas. Durante pruebas extremas, los multiplicadores tienen un mínimo de 0.01 para evitar tiempos y velocidades nulos o negativos.

## Para compartir

Los porcentajes `compartir_cocina_2`, `_3` y `_4` corresponden a pedidos del **mismo plato, en la misma mesa y ronda**. No se suman pedidos de mesas distintas. El pedido conserva su referencia a la mesa al reordenarlo y pierde la bonificación si ese grupo se ha marchado o ha cambiado de ronda.

Los porcentajes `compartir_repeticion_2`, `_3` y `_4` aumentan el **peso del plato en el sorteo** cuando alguien de ese grupo ya lo ha elegido. Dependen de las personas del grupo, no de las sillas libres. Un +50 % cambia el peso de 1 a 1.5; no suma 50 puntos porcentuales ni garantiza una repetición. El primer comensal elige con pesos iguales. También se aplica en nuevas rondas VIP.

## Nombres y catálogo

Los nombres unificados incluyen **Cruda, Fría, Frita, Vegetariana, Vegana, Japonesa, Francesa, Caldo, Pasta, Masa, Vegetales y Estadounidense**. Se admiten variantes anteriores: Pan/Harina/Massa → Masa; Fideos → Pasta; Verduras → Vegetales; Americana → Estadounidense. Un plato con Pan y Masa cuenta una sola vez como Masa. Estas variantes se normalizan sin cambiar los identificadores ni las partidas guardadas.

Para asignar etiquetas a un plato, edita su lista `tags` en `scripts/DishTypes.gd`, como explica [Añadir platos](ANADIR_PLATOS.md). No se han inventado etiquetas nuevas para los platos existentes: si una receta no tiene Cruda, no recibe el bonus japonés dirigido a Cruda.

Los 28 tipos de características de etiquetas están implementados. Los tramos de 7, 9 y 10 platos están preparados para futuras ampliaciones; con el máximo actual de seis espacios todavía no pueden alcanzarse. El catálogo contiene 139 platos; sus características individuales y complejidad se definirán más adelante. La antigua ensalada genérica y su descripción de ejemplo se han retirado.
