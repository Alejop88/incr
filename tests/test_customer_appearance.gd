extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_tests() -> void:
	var customer = load("res://scenes/customer/Customer.tscn").instantiate()
	root.add_child(customer)
	var visual = customer.get_node("Sprite2D")
	var noisy := Image.create(40, 40, false, Image.FORMAT_RGBA8)
	noisy.fill(Color(1, 1, 1, 0.02))
	noisy.fill_rect(Rect2i(10, 8, 20, 24), Color.WHITE)
	noisy.set_pixel(0, 0, Color.WHITE)
	check(visual._opaque_bounds(noisy) == Rect2i(10, 8, 20, 24), "Transparent noise and isolated specks must not shift anchors")
	check(visual.frames.size() == 16, "All four directions have idle and walk frames")
	check(visual.hair_frames.size() == 36, "Nine hairstyles each have four directions")
	for style in range(9):
		for color_index in range(6):
			visual.set_hair(style, color_index)
			check(visual.hair.material.get_shader_parameter("hair_color") == visual.HAIR_COLORS[color_index], "Each hairstyle supports all six colors")
	visual.set_hair(2, 4)
	for style in range(7, 9):
		visual.set_hair(style, 2)
		for facing in range(4):
			visual.direction = facing
			for column in range(4):
				visual._show_frame(column)
				check(visual.hair.texture == visual.hair_frames[style * 4 + facing], "New styles retain their correct view in every pose")
				var grid: Vector2 = visual.hair.material.get_shader_parameter("pixel_grid")
				check((visual.hair.texture.get_size() * visual.hair.scale / grid).is_equal_approx(Vector2(12, 12)), "Classic hair pixels remain square and match the coarse body scale")
				if facing == 3:
					continue
				var anchor: Vector2 = visual.head_anchors[facing * 4 + column]
				var eye := anchor + Vector2(-22 if facing == 2 else 22, 50)
				var overlay: AtlasTexture = visual.hair.texture
				var local: Vector2 = (eye - visual.hair.position) / visual.hair.scale + overlay.get_size() / 2.0
				if Rect2(Vector2.ZERO, overlay.get_size()).has_point(local):
					check(overlay.atlas.get_image().get_pixelv(Vector2i(overlay.region.position + local)).a < 0.1, "New hairstyle leaves the eye visible")
	visual.set_hair(2, 4)
	for frame in visual.frames:
		check(frame.region.size.x > 50 and frame.region.size.y > 200, "Each frame contains a complete body")
		check(frame.get_size() == Vector2(268, 300), "Every frame has the same clothing canvas")
	for index in range(6):
		visual.set_skin(index)
		check(visual.material.get_shader_parameter("skin_color") == visual.SKINS[index], "All six skin palettes are selectable")
	var directions := [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP]
	for index in range(4):
		visual.update_movement(directions[index] * 13, 0.1)
		check(visual.direction == index, "Movement selects the correct facing")
		check(visual.hair.texture == visual.hair_frames[8 + index], "Hair follows body direction")
		check(visual.hair_style == 2 and visual.hair_color_index == 4, "Movement preserves hairstyle and color")
		for column in range(4):
			visual._show_frame(column)
			var anchor: Vector2 = visual.head_anchors[index * 4 + column]
			var hair_top: float = visual.hair.position.y - visual.hair.texture.get_height() * visual.hair.scale.y / 2.0
			check(hair_top >= anchor.y - 16.0 and hair_top <= anchor.y - 14.0, "Hair sway remains close to the scalp in every walking frame")
			check(visual.hair.texture.get_width() * visual.hair.scale.x >= visual.head_widths[index * 4 + column] + 18.0, "Hair overlaps the head on both sides of every frame")
		visual.update_movement(Vector2.ZERO, 0.1)
		check(visual.texture == visual.frames[index * 4], "Standing keeps facing and uses idle frame")
	visual.set_skin(3)
	visual.set_hair(-1, 0)
	for facing in [Vector2.DOWN, Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.ZERO]:
		visual.update_movement(facing * 12, 0.1)
		check(not visual.hair.visible and visual.hair_style == -1, "Bald customers remain bald while moving and stopping")
	visual.set_hair(6, 2)
	check(visual.hair.visible, "Selecting a hairstyle restores the hair layer")
	# Profile hair must leave the eye area open in idle and every walking pose.
	for style in [5, 6]:
		visual.set_hair(style, 2)
		for facing in [1, 2]:
			visual.direction = facing
			for column in range(4):
				visual._show_frame(column)
				var anchor: Vector2 = visual.head_anchors[facing * 4 + column]
				var eye := anchor + Vector2(22 if facing == 1 else -22, 50)
				var overlay: AtlasTexture = visual.hair.texture
				var local: Vector2 = (eye - visual.hair.position) / visual.hair.scale + overlay.get_size() / 2.0
				var source := overlay.atlas.get_image()
				var pixel: Vector2i = Vector2i(overlay.region.position + local)
				check(source.get_pixelv(pixel).a < 0.1, "Afro and long hair leave profile eyes visible in all frames")
	visual.set_hair(3, 2)
	visual.update_movement(Vector2.ZERO, 0.1)
	visual.update_movement(Vector2.RIGHT * 12, 0.1)
	var first_offset: Vector2 = visual.hair.position - visual.head_anchors[visual.frames.find(visual.texture)]
	visual.update_movement(Vector2.RIGHT * 24, 0.2)
	var next_offset: Vector2 = visual.hair.position - visual.head_anchors[visual.frames.find(visual.texture)]
	check(first_offset != next_offset, "Hair sways with the walking cycle")
	visual.update_movement(Vector2.ZERO, 0.1)
	check(not visual.walking, "Hair movement stops when the customer stops")
	var seen := {}
	for i in range(8):
		visual.update_movement(Vector2.RIGHT * 12, 0.1)
		seen[visual.texture] = true
	check(seen.size() == 3 and visual.skin_index == 3, "Walking cycles poses without changing skin")
	customer.move_to_position(Vector2(60, 0), customer.TargetType.QUEUE)
	for i in range(70):
		customer._physics_process(1.0 / 60.0)
	check(not customer.has_target and visual.direction == 1, "Real route movement animates and stops at its destination")
	check(visual.texture == visual.frames[4], "Arrival settles to the right-facing idle frame")
	customer.free()
	print("CUSTOMER APPEARANCE TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
