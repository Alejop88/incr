extends SceneTree

func _initialize() -> void:
	call_deferred("run_test")

func run_test() -> void:
	var camera: Camera2D = load("res://scripts/RestaurantCamera.gd").new()
	camera.position = Vector2(650, 450)
	camera.zoom = Vector2(0.8, 0.8)
	root.add_child(camera)
	var initial: Vector2 = camera.position
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_RIGHT
	press.pressed = true
	camera._unhandled_input(press)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(80, 40)
	motion.button_mask = MOUSE_BUTTON_MASK_RIGHT
	camera._input(motion)
	assert(camera.position == initial - Vector2(100, 50), "Drag must respect zoom")
	press.pressed = false
	camera._input(press)
	var stopped: Vector2 = camera.position
	camera._input(motion)
	assert(camera.position == stopped, "Release ends dragging")
	var reset := InputEventKey.new()
	reset.keycode = KEY_SPACE
	reset.pressed = true
	camera._unhandled_input(reset)
	assert(camera.position == initial, "Space restores starting view")
	press.pressed = true
	camera._unhandled_input(press)
	paused = true
	camera._input(motion)
	assert(camera.position == initial and not camera.dragging, "Pausing cancels movement")
	paused = false
	var wheel := InputEventMouseButton.new()
	wheel.button_index = MOUSE_BUTTON_WHEEL_UP
	wheel.pressed = true
	wheel.position = Vector2(250, 180)
	camera.force_update_scroll()
	var mouse_world: Vector2 = camera.get_canvas_transform().affine_inverse() * wheel.position
	camera._unhandled_input(wheel)
	assert(camera.zoom.x > 0.8, "Wheel up zooms in")
	assert(mouse_world.distance_to(camera.get_canvas_transform().affine_inverse() * wheel.position) < 0.01, "Zoom must keep the cursor's world point fixed")
	for i in range(30):
		camera._unhandled_input(wheel)
	assert(is_equal_approx(camera.zoom.x, camera.MAX_ZOOM), "Zoom in is bounded")
	wheel.button_index = MOUSE_BUTTON_WHEEL_DOWN
	for i in range(30):
		camera._unhandled_input(wheel)
	assert(is_equal_approx(camera.zoom.x, camera.MIN_ZOOM), "Zoom out is bounded")
	camera._unhandled_input(reset)
	assert(camera.zoom == Vector2(0.8, 0.8) and camera.position == initial, "Space resets position and zoom")
	var restaurant: Node = load("res://scenes/restaurant/Restaurant.tscn").instantiate()
	root.add_child(restaurant)
	camera.force_update_scroll()
	press.position = camera.get_canvas_transform() * restaurant.kitchen_point.global_position
	camera._unhandled_input(press)
	assert(not camera.dragging, "Right click on cook must leave the kitchen interaction available")
	camera.position += Vector2(180, 110)
	camera.force_update_scroll()
	press.position = camera.get_canvas_transform() * restaurant.kitchen_point.global_position
	assert(camera._is_over_kitchen(press.position), "Cook hit detection must follow camera movement and zoom")
	press.position += Vector2(200, 0)
	camera._unhandled_input(press)
	assert(camera.dragging, "Right click away from cook must start panning")
	var settings: Node = root.get_node("GameSettings")
	var original: Dictionary = settings.bindings.duplicate(true)
	settings.bindings.camera = {"mouse": true, "code": MOUSE_BUTTON_MIDDLE}
	settings.bindings.reset_camera = {"mouse": false, "code": KEY_R}
	settings.bindings.zoom_in = {"mouse": false, "code": KEY_Z}
	camera.dragging = false
	camera._unhandled_input(press)
	assert(not camera.dragging, "Old camera binding must no longer pan")
	press.button_index = MOUSE_BUTTON_MIDDLE
	camera._unhandled_input(press)
	var before_drag: Vector2 = camera.position
	motion.button_mask = MOUSE_BUTTON_MASK_MIDDLE
	camera._input(motion)
	assert(camera.position != before_drag, "Rebound camera button must drag")
	press.pressed = false
	camera._input(press)
	assert(not camera.dragging, "Rebound camera release must stop dragging")
	reset.keycode = KEY_R
	camera._unhandled_input(reset)
	assert(camera.position == initial, "Rebound reset key must restore camera")
	reset.keycode = KEY_Z
	camera._unhandled_input(reset)
	assert(camera.zoom.x > 0.8, "Rebound keyboard zoom must work")
	settings.bindings = original
	restaurant.free()
	camera.free()
	print("CAMERA TESTS: PASS")
	quit()
