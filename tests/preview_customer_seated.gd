extends "res://tests/preview_customer_hair.gd"

func render_preview() -> void:
	var actor = load("res://scenes/customer/Customer.tscn").instantiate()
	root.add_child(actor)
	actor.set_physics_process(false)
	var visual = actor.get_node("Sprite2D")
	visual.set_skin(1)
	visual.set_hair(0, 2)
	var result := Image.create(1000, 1000, false, Image.FORMAT_RGBA8)
	result.fill(Color("62666b"))
	for row in range(3):
		for direction in range(4):
			visual.stand_up()
			visual.sit_down([Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP][direction])
			visual.sitting_progress = 1.0
			visual.seated_rig.pose(1.0, [-1.0, 0.2, 0.4][row])
			visual._update_hair()
			var center := Vector2(125 + direction * 250, 150 + row * 330)
			var rig = visual.seated_rig
			var head: AtlasTexture = rig.head.texture
			var head_image := tinted(head.atlas.get_image().get_region(Rect2i(head.region)), visual.SKINS[1], false)
			if direction != 3:
				result.blend_rect(head_image, Rect2i(Vector2i.ZERO, head_image.get_size()), Vector2i(center + rig.position + rig.head.position))
			for item in rig.blocks:
				result.fill_rect(Rect2i(item[0].position + rig.position + center, item[0].size), item[1])
			if direction == 3:
				result.blend_rect(head_image, Rect2i(Vector2i.ZERO, head_image.get_size()), Vector2i(center + rig.position + rig.head.position))
			var hair: AtlasTexture = visual.hair.texture
			var hair_image := tinted(hair.atlas.get_image().get_region(Rect2i(hair.region)), visual.HAIR_COLORS[2], true)
			var size: Vector2 = hair.get_size() * visual.hair.scale
			hair_image.resize(roundi(size.x), roundi(size.y), Image.INTERPOLATE_NEAREST)
			result.blend_rect(hair_image, Rect2i(Vector2i.ZERO, hair_image.get_size()), Vector2i(center + visual.hair.position - size / 2.0))
	result.save_png("res://output/art-prototypes/customer-seated-preview.png")
	actor.free()
	quit()
