extends Control

var canvas: Control
var nodes: Dictionary = {}
var edges: Array = []
var dragging := false
var view_zoom := 0.7
var initialized := false

func _ready() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.draw.connect(_draw_connections)
	resized.connect(func():
		if not initialized:
			fit_tree())
	gui_input.connect(_board_input)

func fit_tree() -> void:
	if size.x < 1 or nodes.is_empty():
		return
	var bounds := Rect2(Vector2(-850, -410), Vector2(1750, 840))
	view_zoom = clampf(minf(size.x / bounds.size.x, size.y / bounds.size.y) * 0.92, 0.3, 1.3)
	canvas.scale = Vector2.ONE * view_zoom
	canvas.position = size / 2 - bounds.get_center() * view_zoom
	initialized = true
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("142c50"))
	for x in range(18, int(size.x), 38):
		for y in range(18, int(size.y), 38):
			draw_circle(Vector2(x, y), 1, Color("223e64"))

func _draw_connections() -> void:
	for edge in edges:
		var a: Vector2 = edge[0]
		var b: Vector2 = edge[1]
		var target: Button = nodes[edge[2]]
		var color := Color("567397")
		if target.button_pressed or target.get_meta("bought", false):
			color = Color("efc66b")
		canvas.draw_line(a, b, Color("0c1e38"), 8, true)
		canvas.draw_line(a, b, color, 3, true)
	canvas.draw_circle(Vector2.ZERO, 36, Color("edc86d"))
	canvas.draw_string(ThemeDB.fallback_font, Vector2(-15, 13), "★", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color("183557"))

func _board_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = event.pressed
		accept_event()

func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		dragging = false
		return
	if event is InputEventMouseButton:
		if not event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			dragging = false
		if get_global_rect().has_point(event.position) and event.pressed:
			if event.button_index == MOUSE_BUTTON_RIGHT:
				dragging = true
				get_viewport().set_input_as_handled()
			elif event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
				zoom_at(event.position - global_position, 1.15 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / 1.15)
				get_viewport().set_input_as_handled()
	if event is InputEventMouseMotion and dragging:
		canvas.position += event.relative
		get_viewport().set_input_as_handled()

func zoom_at(point: Vector2, factor: float) -> void:
	var before: Vector2 = (point - canvas.position) / view_zoom
	view_zoom = clampf(view_zoom * factor, 0.3, 1.6)
	canvas.scale = Vector2.ONE * view_zoom
	canvas.position = point - before * view_zoom

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		dragging = false
