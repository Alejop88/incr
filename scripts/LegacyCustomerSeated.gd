extends Sprite2D
const SEATING = preload("res://scripts/SeatingLayout.gd")
## Keep the existing clothed VIP artwork until it has directional body frames.
var seated := false
var eating := false
var progress := 0.0
var clock := 0.0
var pieces: Array[Sprite2D] = []
var origins: Array[Vector2] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	for rect in [Rect2(0, 0, 228, 216), Rect2(39, 216, 152, 127), Rect2(0, 216, 39, 127), Rect2(191, 216, 37, 127), Rect2(0, 343, 228, 107)]:
		var part := Sprite2D.new()
		var crop := AtlasTexture.new()
		crop.atlas = texture
		crop.region = rect
		crop.filter_clip = true
		part.texture = crop
		part.centered = false
		part.position = rect.position - texture.get_size() / 2.0
		origins.append(part.position)
		part.hide()
		add_child(part)
		pieces.append(part)

func sit_down(_toward_table: Vector2) -> void:
	if seated:
		return
	seated = true
	progress = 0.0
	self_modulate.a = 0.0
	for part in pieces:
		part.show()
	update_movement(Vector2.ZERO, 0.0)

func set_eating(value: bool) -> void:
	eating = value
	clock = 0.0
	update_movement(Vector2.ZERO, 0.0)

func stand_up() -> void:
	seated = false
	eating = false
	self_modulate.a = 1.0
	for part in pieces:
		part.hide()

func update_movement(_displacement: Vector2, delta: float) -> void:
	if not seated:
		return
	progress = minf(1.0, progress + delta / 0.36)
	if eating and progress >= 1.0:
		clock += delta
	var seated_drop: float = (SEATING.CUSHION_Y - position.y) / scale.y - origins[4].y
	var drop := progress * seated_drop
	for i in range(pieces.size()):
		pieces[i].position = origins[i] + Vector2(0, drop)
	var floor_y: float = lerpf(225.0, (SEATING.FLOOR_Y - position.y) / scale.y, progress)
	pieces[4].scale.y = (floor_y - pieces[4].position.y) / 107.0
	var lift := maxf(0.0, sin(clock * TAU / 1.5)) if eating and progress >= 1.0 else 0.0
	pieces[3].rotation = roundf(lift * 2.0) * PI / 4.0
