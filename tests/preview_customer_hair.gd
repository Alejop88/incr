extends SceneTree
## CPU layout preview using the actual atlas regions, transforms and palettes.
func _initialize() -> void:
	call_deferred("render_preview")

func tinted(image: Image, color: Color, is_hair: bool) -> Image:
	image.convert(Image.FORMAT_RGBA8)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel := image.get_pixel(x, y)
			if pixel.a == 0:
				continue
			if is_hair:
				var shade := 0.25 if pixel.r < 0.15 else (0.85 if pixel.r < 0.65 else 1.25)
				image.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade, pixel.a))
			elif pixel.r > 0.35:
				var shade := 0.76 if pixel.r < 0.80 else (0.89 if pixel.r < 0.92 else 1.0)
				image.set_pixel(x, y, Color(color.r * shade, color.g * shade, color.b * shade, pixel.a))
	return image

func render_preview() -> void:
	var actor = load("res://scenes/customer/Customer.tscn").instantiate()
	root.add_child(actor)
	var visual = actor.get_node("Sprite2D")
	var pose := 1
	if not OS.get_cmdline_user_args().is_empty():
		pose = clampi(int(OS.get_cmdline_user_args()[0]), 0, 3)
	var result := Image.create(800, 1280, false, Image.FORMAT_RGBA8)
	result.fill(Color("62666b"))
	for style in range(7, 9):
		for direction in range(4):
			visual.direction = direction
			visual.set_hair(style, 2)
			visual._show_frame(pose)
			var center := Vector2(100 + direction * 200, 180 + (style - 7) * 350)
			var body: AtlasTexture = visual.texture
			var body_image := tinted(body.atlas.get_image().get_region(Rect2i(body.region)), visual.SKINS[1], false)
			result.blend_rect(body_image, Rect2i(Vector2i.ZERO, body_image.get_size()), Vector2i(center - Vector2(134, 150) + body.margin.position))
			var hair: AtlasTexture = visual.hair.texture
			var hair_image := tinted(hair.atlas.get_image().get_region(Rect2i(hair.region)), visual.HAIR_COLORS[2], true)
			var size: Vector2 = hair.get_size() * visual.hair.scale
			if style >= 7:
				hair_image.resize(roundi(size.x / 12.0), roundi(size.y / 12.0), Image.INTERPOLATE_NEAREST)
			if style == 7 and direction == 0:
				for x in range(hair_image.get_width()):
					var ratio := (x + 0.5) / hair_image.get_width()
					if ratio > 0.12 and ratio < 0.88:
						hair_image.fill_rect(Rect2i(x, 0, 1, hair_image.get_height()), Color.TRANSPARENT)
			hair_image.resize(roundi(size.x), roundi(size.y), Image.INTERPOLATE_NEAREST)
			result.blend_rect(hair_image, Rect2i(Vector2i.ZERO, hair_image.get_size()), Vector2i(center + visual.hair.position - size / 2.0))
	result.save_png("res://output/art-prototypes/customer-hair-bald-fixed-preview-%d.png" % pose)
	actor.free()
	quit()
