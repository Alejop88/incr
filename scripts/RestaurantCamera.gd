extends Camera2D

var dragging: bool = false
var starting_position: Vector2
var starting_zoom: Vector2
const MIN_ZOOM: float = 0.35
const MAX_ZOOM: float = 1.6
const ZOOM_STEP: float = 1.15
@export var kitchen_path: NodePath = NodePath("../Restaurant/KitchenPoint")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	starting_position = position
	starting_zoom = zoom

func _input(event: InputEvent) -> void:
	if get_tree().paused:
		dragging = false
		return
	# Releases must also be seen over a menu, where GUI consumes input.
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and not event.pressed:
		dragging = false
	if event is InputEventMouseMotion and dragging:
		if not event.button_mask & MOUSE_BUTTON_MASK_RIGHT:
			dragging = false
			return
		position -= event.relative / zoom
		get_viewport().set_input_as_handled()

func _unhandled_input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		var factor: float = ZOOM_STEP if event.button_index == MOUSE_BUTTON_WHEEL_UP else 1.0 / ZOOM_STEP
		_zoom_at(event.position, factor)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		if _is_over_kitchen(event.position):
			dragging = false
			# Leave this click to the kitchen's normal physics picking handler.
			return
		dragging = true
		get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		position = starting_position
		zoom = starting_zoom
		force_update_scroll()
		dragging = false
		get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		dragging = false

func _zoom_at(viewport_position: Vector2, factor: float) -> void:
	force_update_scroll()
	var before: Vector2 = get_canvas_transform().affine_inverse() * viewport_position
	zoom = Vector2.ONE * clampf(zoom.x * factor, MIN_ZOOM, MAX_ZOOM)
	force_update_scroll()
	var after: Vector2 = get_canvas_transform().affine_inverse() * viewport_position
	global_position += before - after
	force_update_scroll()

func restore_zoom(value: float) -> void:
	zoom = Vector2.ONE * clampf(value, MIN_ZOOM, MAX_ZOOM)
	force_update_scroll()

func _is_over_kitchen(viewport_position: Vector2) -> bool:
	var kitchen: Area2D = get_node_or_null(kitchen_path) as Area2D
	if kitchen == null or not kitchen.is_visible_in_tree():
		return false
	var collider: CollisionShape2D = kitchen.get_node("CollisionShape2D")
	if collider.disabled or not collider.shape is RectangleShape2D:
		return false
	var world_position: Vector2 = get_canvas_transform().affine_inverse() * viewport_position
	var local_position: Vector2 = collider.to_local(world_position)
	return Rect2(-collider.shape.size / 2.0, collider.shape.size).has_point(local_position)
