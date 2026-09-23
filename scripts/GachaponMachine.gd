extends Area2D
signal opened

func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var collision := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(72, 82)
	collision.shape = rectangle
	add_child(collision)
	var label := Label.new()
	label.text = "GACHAPÓN"
	label.position = Vector2(-60, 48)
	label.size.x = 120
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	input_event.connect(func(_viewport: Viewport, event: InputEvent, _shape: int):
		if get_node("/root/GameSettings").matches(event, "interact"):
			opened.emit())

func _draw() -> void:
	draw_rect(Rect2(-36, -26, 62, 64), Color("32b45b"))
	draw_colored_polygon(PackedVector2Array([Vector2(-36, -26), Vector2(-20, -42), Vector2(42, -42), Vector2(26, -26)]), Color("72e88e"))
	draw_colored_polygon(PackedVector2Array([Vector2(26, -26), Vector2(42, -42), Vector2(42, 22), Vector2(26, 38)]), Color("207c40"))
