extends Area2D
signal opened
func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var collider := CollisionShape2D.new()
	collider.name = "CollisionShape2D"
	var shape := RectangleShape2D.new()
	shape.size = Vector2(210, 80)
	collider.shape = shape
	add_child(collider)
	var label := Label.new()
	label.text = "BARRA · Clic derecho"
	label.position = Vector2(-100, -65)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	input_event.connect(func(_viewport: Node, event: InputEvent, _shape: int):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			opened.emit())
func _draw() -> void:
	draw_rect(Rect2(-105, -35, 210, 75), Color("30231c"))
	draw_rect(Rect2(-100, -30, 200, 25), Color("d29b60"))
	draw_rect(Rect2(-100, 0, 200, 35), Color("805238"))
	for x in [-70, 0, 70]:
		draw_rect(Rect2(x - 10, -25, 20, 15), Color("eee1c5"))
