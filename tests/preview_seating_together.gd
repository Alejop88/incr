extends "res://tests/preview_customer_hair.gd"

func stamp(canvas: Image, source: Image, at: Vector2, size: Vector2) -> void:
	source.resize(maxi(1, roundi(size.x)), maxi(1, roundi(size.y)), Image.INTERPOLATE_NEAREST)
	canvas.blend_rect(source, Rect2i(Vector2i.ZERO, source.get_size()), Vector2i(at.round()))

func render_preview() -> void:
	var canvas := Image.create(840, 420, false, Image.FORMAT_RGBA8)
	canvas.fill(Color("62666b"))
	for capacity in [2, 4]:
		var origin := Vector2(210 if capacity == 2 else 630, 180)
		var seats: Array[Vector2] = []
		seats.assign([Vector2(-125, 0), Vector2(125, 0)] if capacity == 2 else [Vector2(-115, -40), Vector2(115, -40), Vector2(-115, 40), Vector2(115, 40)])
		var furniture = preload("res://scripts/TableAppearance.gd").new()
		furniture.configure(capacity, seats, null)
		for item in furniture.rectangles:
			var color: Color = item[1]
			if color.a < 1.0:
				color = Color("62666b").lerp(Color(color, 1.0), color.a)
			canvas.fill_rect(Rect2i(item[0].position + origin, item[0].size), color)
		furniture.free()
		for index in range(seats.size()):
			var actor = load("res://scenes/customer/Customer.tscn").instantiate()
			root.add_child(actor)
			actor.set_physics_process(false)
			var visual = actor.get_node("Sprite2D")
			visual.set_skin(index % 3)
			visual.set_hair([0, 7, 4, -1][index], index % 3)
			visual.sit_down(Vector2.RIGHT if seats[index].x < 0 else Vector2.LEFT)
			visual.update_movement(Vector2.ZERO, 0.4)
			var rig = visual.seated_rig
			var center: Vector2 = origin + seats[index] + visual.position
			var factor: Vector2 = visual.scale
			var head: AtlasTexture = rig.head.texture
			var head_image := tinted(head.atlas.get_image().get_region(Rect2i(head.region)), visual.SKINS[visual.skin_index], false)
			stamp(canvas, head_image, center + (rig.position + rig.head.position) * factor, head.get_size() * factor)
			for item in rig.blocks:
				canvas.fill_rect(Rect2i((center + (rig.position + item[0].position) * factor).round(), (item[0].size * factor).round()), item[1])
			if visual.hair.visible:
				var hair: AtlasTexture = visual.hair.texture
				var hair_image := tinted(hair.atlas.get_image().get_region(Rect2i(hair.region)), visual.HAIR_COLORS[visual.hair_color_index], true)
				var size: Vector2 = hair.get_size() * visual.hair.scale
				if visual.hair_style >= 7:
					hair_image.resize(roundi(size.x / 12.0), roundi(size.y / 12.0), Image.INTERPOLATE_NEAREST)
				stamp(canvas, hair_image, center + (visual.hair.position - size / 2.0) * factor, size * factor)
			actor.free()
	canvas.resize(1680, 840, Image.INTERPOLATE_NEAREST)
	canvas.save_png("res://output/art-prototypes/seating-together-preview.png")
	quit()
