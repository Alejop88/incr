extends Node2D
## Coarse five-pixel blocks match the customers' twelve-source-pixel outlines.
const SEATING = preload("res://scripts/SeatingLayout.gd")
const DEFAULT_SKIN = preload("res://assets/art/table_classic.tres")
var skin: Resource = DEFAULT_SKIN
var capacity := 2
var seats: Array[Vector2] = []
var rectangles: Array = []

static func surface_size(places: int) -> Vector2:
	# Horizontal planes use the same 1:2 depth projection as chair cushions.
	return Vector2(150, 160 * SEATING.DEPTH_RATIO) if places <= 2 else Vector2(170, 300 * SEATING.DEPTH_RATIO)

static func furniture_bounds(places: int) -> Rect2:
	# Keep the established clearance envelope while changing visual projection.
	return Rect2(-76, -52, 152, 128) if places <= 2 else Rect2(-84, -88, 168, 200)

static func dish_position(places: int, seat: Vector2) -> Vector2:
	if places > 2:
		return Vector2(-40 if seat.x < 0 else 40, -40 if seat.y < 0 else 40)
	var x := surface_size(places).x / 2.0 - 32
	return Vector2(-x if seat.x < 0 else x, seat.y)

func configure(places: int, seat_positions: Array[Vector2], new_skin: Resource) -> void:
	capacity = places
	seats = seat_positions
	skin = new_skin if new_skin != null else DEFAULT_SKIN
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_build()
	queue_redraw()

func rect(position: Vector2, size: Vector2, color: Color) -> void:
	var start := position.snapped(Vector2.ONE * SEATING.PIXEL)
	var end := (position + size).snapped(Vector2.ONE * SEATING.PIXEL)
	rectangles.append([Rect2(start, end - start), color])

func _build() -> void:
	rectangles.clear()
	var size := surface_size(capacity)
	var half := size / 2.0
	# Three-quarter projection: a visible horizontal seat plane and vertical apron.
	# These are projected visual heights, not changes to the navigation markers.
	for seat in seats:
		rect(seat + Vector2(-25, SEATING.FLOOR_Y), Vector2(55, 5), Color(0.08, 0.06, 0.05, 0.20))
		# Far legs are higher in the same depth projection as the seat surface.
		for x in [-20, 15]:
			rect(seat + Vector2(x, SEATING.CUSHION_Y - SEATING.SEAT_DEPTH), Vector2(10, 25), skin.outline)
			rect(seat + Vector2(x, SEATING.CUSHION_Y - SEATING.SEAT_DEPTH + 5), Vector2(5, 15), skin.wood_dark)
		for x in [-20, 15]:
			rect(seat + Vector2(x, SEATING.CUSHION_Y + 5), Vector2(10, 20), skin.outline)
			rect(seat + Vector2(x, SEATING.CUSHION_Y + 10), Vector2(5, 10), skin.wood)
		var back_x := -30.0 if seat.x < 0 else 20.0
		# The far upright and broad top rail reveal the backrest's depth.
		rect(seat + Vector2(back_x, -20), Vector2(10, 60), skin.outline)
		rect(seat + Vector2(back_x, -15), Vector2(5, 45), skin.wood_dark)
		rect(seat + Vector2(-25, SEATING.CUSHION_Y - SEATING.SEAT_DEPTH), Vector2(55, SEATING.SEAT_DEPTH + 5), skin.outline)
		rect(seat + Vector2(-20, SEATING.CUSHION_Y - SEATING.SEAT_DEPTH + 5), Vector2(45, SEATING.SEAT_DEPTH - 5), skin.cushion)
		rect(seat + Vector2(-15, SEATING.CUSHION_Y - SEATING.SEAT_DEPTH + 5), Vector2(35, 5), skin.cushion.lightened(0.14))
		rect(seat + Vector2(-25, SEATING.CUSHION_Y), Vector2(55, 10), skin.outline)
		rect(seat + Vector2(-20, SEATING.CUSHION_Y), Vector2(45, 5), skin.wood_dark)
		rect(seat + Vector2(back_x, 5), Vector2(10, 60), skin.outline)
		rect(seat + Vector2(back_x, 10), Vector2(5, 45), skin.wood)
		rect(seat + Vector2(back_x, -20), Vector2(10, 30), skin.outline)
		rect(seat + Vector2(back_x, -15), Vector2(5, 20), skin.wood_light)
	var custom: Texture2D = skin.two_seat_texture if capacity <= 2 else skin.four_seat_texture
	if custom != null:
		return
	# Two visible feet sit beneath the front edge; tabletop has a bevel and apron.
	rect(Vector2(-half.x + 4, half.y + 30), Vector2(size.x, 10), Color(0.08, 0.06, 0.05, 0.20))
	for x in [-half.x + 12, half.x - 28]:
		rect(Vector2(x, half.y - 5), Vector2(15, 40), skin.outline)
		rect(Vector2(x + 5, half.y + 5), Vector2(5, 25), skin.wood_dark)
	rect(-half + Vector2(0, 12), size, skin.outline)
	rect(Vector2(-half.x + 4, half.y - 4), Vector2(size.x - 8, 12), skin.wood_dark)
	# Stepped corners rather than smooth rounded UI shapes.
	rect(-half + Vector2(4, 0), size - Vector2(8, 0), skin.outline)
	rect(-half + Vector2(0, 4), size - Vector2(0, 8), skin.outline)
	rect(-half + Vector2(4, 4), size - Vector2(8, 8), skin.wood)
	rect(-half + Vector2(8, 4), Vector2(size.x - 16, 4), skin.wood_light)
	rect(-half + Vector2(4, 8), Vector2(4, size.y - 16), skin.wood_light)
	for y in range(int(-half.y + 35), int(half.y - 8), 35):
		rect(Vector2(-half.x + 8, y), Vector2(size.x - 16, 4), skin.wood_dark)
	# A quiet place setting for each seat leaves the center free for serving.
	for seat in seats:
		# Foreshortened cloth: same depth ratio as the chair's horizontal cushion.
		var setting := dish_position(capacity, seat) - Vector2(20, 10)
		rect(setting + Vector2(0, 5), Vector2(40, 20), skin.wood_dark)
		rect(setting, Vector2(40, 20), skin.linen.darkened(0.12))
		rect(setting + Vector2(5, 5), Vector2(30, 10), skin.linen)

func _draw() -> void:
	for item in rectangles:
		draw_rect(item[0], item[1])
	var custom: Texture2D = skin.two_seat_texture if capacity <= 2 else skin.four_seat_texture
	if custom != null:
		draw_texture_rect(custom, furniture_bounds(capacity), false)
