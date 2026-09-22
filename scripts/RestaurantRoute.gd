extends RefCounted

# Visibility graph around table corners, with room for the characters' bodies.
const CLEARANCE: float = 55.0
var path: PackedVector2Array = []
var destination: Vector2 = Vector2.INF
var obstacles: Array[Rect2] = []

func table_obstacles(actor: Node) -> Array[Rect2]:
	var restaurant: Node = actor.get_parent()
	while restaurant != null and not restaurant.has_method("get_available_table"):
		restaurant = restaurant.get_parent()
	var result: Array[Rect2] = []
	if restaurant == null:
		return result
	for table in restaurant.tables:
		if table.unlocked:
			var footprint := Rect2(table.global_position - Vector2(40, 40), Vector2(80, 80))
			for seat in table.customer_seat_points:
				footprint = footprint.merge(Rect2(seat.global_position - Vector2(16, 16), Vector2(32, 32)))
			result.append(footprint.grow(CLEARANCE))
	return result

func segment_clear(from: Vector2, to: Vector2, blocks: Array[Rect2]) -> bool:
	for rect in blocks:
		if rect.has_point(from) or rect.has_point(to):
			return false
		var corners: Array[Vector2] = [rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)]
		for i in range(4):
			if Geometry2D.segment_intersects_segment(from, to, corners[i], corners[(i + 1) % 4]) != null:
				return false
	return true

func build_path(from: Vector2, to: Vector2, blocks: Array[Rect2]) -> PackedVector2Array:
	# Enter/leave a seat from its outer side, never through the table or other seats.
	for block in blocks:
		if block.has_point(to):
			var access := Vector2(block.end.x + 2 if to.x >= block.get_center().x else block.position.x - 2, to.y)
			if block.has_point(from):
				var departure := Vector2(block.end.x + 2 if from.x >= block.get_center().x else block.position.x - 2, from.y)
				var middle: PackedVector2Array = build_path(departure, access, blocks)
				if middle.is_empty():
					return middle
				var seated_route := PackedVector2Array([departure])
				seated_route.append_array(middle)
				seated_route.append(to)
				return seated_route
			var arrival: PackedVector2Array = build_path(from, access, blocks)
			if not arrival.is_empty():
				arrival.append(to)
			return arrival
	# A newly unlocked table may appear around someone already walking there.
	# Let them leave its clearance area, then resume a normal obstacle-free route.
	for block in blocks:
		if block.has_point(from):
			var exits: Array[Vector2] = [Vector2(block.position.x - 2, from.y), Vector2(block.end.x + 2, from.y), Vector2(from.x, block.position.y - 2), Vector2(from.x, block.end.y + 2)]
			exits.sort_custom(func(a: Vector2, b: Vector2): return from.distance_squared_to(a) < from.distance_squared_to(b))
			var others: Array[Rect2] = blocks.duplicate()
			others.erase(block)
			for exit_point in exits:
				if not segment_clear(from, exit_point, others):
					continue
				var remaining: PackedVector2Array = build_path(exit_point, to, blocks)
				if not remaining.is_empty():
					var escape_path := PackedVector2Array([exit_point])
					escape_path.append_array(remaining)
					return escape_path
			return PackedVector2Array()
	if segment_clear(from, to, blocks):
		return PackedVector2Array([to])
	var points: Array[Vector2] = [from, to]
	for block in blocks:
		var rect: Rect2 = block.grow(2)
		points.append_array([rect.position, Vector2(rect.end.x, rect.position.y), rect.end, Vector2(rect.position.x, rect.end.y)])
	var graph := AStar2D.new()
	for i in range(points.size()):
		graph.add_point(i, points[i])
	for i in range(points.size()):
		for j in range(i + 1, points.size()):
			if segment_clear(points[i], points[j], blocks):
				graph.connect_points(i, j)
	var result: PackedVector2Array = graph.get_point_path(0, 1)
	if not result.is_empty():
		result.remove_at(0)
	return result

func advance(actor: CharacterBody2D, target: Vector2, speed: float, delta: float) -> bool:
	if actor.global_position.distance_to(target) < 0.5:
		actor.velocity = Vector2.ZERO
		path.clear()
		return true
	var blocks: Array[Rect2] = table_obstacles(actor)
	if target != destination or blocks != obstacles or path.is_empty():
		destination = target
		obstacles = blocks
		path = build_path(actor.global_position, target, obstacles)
	if path.is_empty():
		actor.velocity = Vector2.ZERO
		return false
	var next: Vector2 = path[0]
	var offset: Vector2 = next - actor.global_position
	if offset.length() <= speed * delta:
		actor.global_position = next
		actor.velocity = Vector2.ZERO
		path.remove_at(0)
		return path.is_empty()
	actor.velocity = offset.normalized() * speed
	actor.move_and_slide()
	return false
