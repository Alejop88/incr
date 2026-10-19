extends "res://tests/preview_customer_hair.gd"
## CPU preview of the uniform shader's palette/masks at actual atlas coordinates.
func render_preview() -> void:
	var actor = preload("res://scripts/PlayerAppearance.gd").new()
	root.add_child(actor)
	actor.apply_look({"hair": 0, "hair_color": 1, "skin": 1})
	var result := Image.create(900, 680, false, Image.FORMAT_RGBA8)
	result.fill(Color("405454"))
	for facing in range(4):
		for row in range(2):
			actor.direction = facing
			actor._show_frame(row)
			var atlas: AtlasTexture = actor.texture
			var body := atlas.atlas.get_image().get_region(Rect2i(atlas.region))
			body.convert(Image.FORMAT_RGBA8)
			for y in range(body.get_height()):
				for x in range(body.get_width()):
					var pixel := body.get_pixel(x, y)
					if pixel.r <= 0.35 or pixel.a == 0:
						continue
					var u := float(x) / body.get_width()
					var torso := (u > 0.36 and u < 0.74) if facing in [1, 2] else (u > 0.27 and u < 0.73)
					var color: Color = actor.SKINS[1]
					var white := Color(0.92, 0.90, 0.82)
					var dark := Color(0.18, 0.20, 0.24)
					if y >= 120 and y < 180:
						color = dark if torso else white
						if facing == 0 and u > 0.44 and u < 0.56:
							color = white if y < 144 else dark
						if facing == 0 and y >= 132 and y < 144 and u > 0.36 and u < 0.64:
							color = Color(0.45, 0.15, 0.15)
					elif y >= 180 and (torso or y >= 204):
						color = white if y < 198 and torso and facing != 3 else dark
					var shade := 0.76 if pixel.r < 0.80 else (0.89 if pixel.r < 0.92 else 1.0)
					body.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade, pixel.a))
			var center := Vector2(115 + facing * 225, 165 + row * 330)
			result.blend_rect(body, Rect2i(Vector2i.ZERO, body.get_size()), Vector2i(center - Vector2(134, 150) + atlas.margin.position))
			var hair: AtlasTexture = actor.hair.texture
			var hair_image := tinted(hair.atlas.get_image().get_region(Rect2i(hair.region)), actor.HAIR_COLORS[1], true)
			var size: Vector2 = hair.get_size() * actor.hair.scale
			hair_image.resize(roundi(size.x), roundi(size.y), Image.INTERPOLATE_NEAREST)
			result.blend_rect(hair_image, Rect2i(Vector2i.ZERO, hair_image.get_size()), Vector2i(center + actor.hair.position - size / 2))
	result.save_png("res://output/art-prototypes/player-uniform-preview.png")
	actor.free()
	quit()
