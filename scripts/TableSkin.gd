extends Resource
## Appearance only: skins never change capacity, seats or navigation.
@export var skin_id: StringName = &"classic_wood"
@export var display_name := "Madera clásica"
@export var outline := Color("30231c")
@export var wood := Color("ad7347")
@export var wood_light := Color("d29b60")
@export var wood_dark := Color("805238")
@export var cushion := Color("557b70")
@export var linen := Color("e8ddbd")
## Optional future images, fitted to the same fixed visual bounds.
@export var two_seat_texture: Texture2D
@export var four_seat_texture: Texture2D
