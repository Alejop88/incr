extends SceneTree

func _initialize() -> void:
	var canvas := Image.create(800, 320, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("44494b"))
	for capacity in [2, 4]:
		var furniture = preload("res://scripts/TableAppearance.gd").new()
		var seats: Array[Vector2] = []
		seats.assign([Vector2(125, 0), Vector2(-125, 0)] if capacity == 2 else [Vector2(115, 40), Vector2(-115, 40), Vector2(-115, -40), Vector2(115, -40)])
		furniture.configure(capacity, seats, null)
		var origin := Vector2(200 if capacity == 2 else 600, 140)
		for item in furniture.rectangles:
			var color: Color = item[1]
			if color.a < 1.0:
				color = Color("44494b").lerp(Color(color, 1.0), color.a)
			canvas.fill_rect(Rect2i(item[0].position + origin, item[0].size), color)
		furniture.free()
	canvas.resize(1600, 640, Image.INTERPOLATE_NEAREST)
	canvas.save_png("res://output/art-prototypes/tables-classic-preview.png")
	quit()
