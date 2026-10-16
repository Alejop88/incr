extends Node2D
const SEATING = preload("res://scripts/SeatingLayout.gd")
## Articulated seated body on the same coarse grid as the walking sprite.
## Reuses the original head, skin shader and (sibling) hair layer.
var head: Sprite2D
var facing := 0
var skin := Color.WHITE
var top := Vector2.ZERO
var drop := 0.0
var bend := 0.0
var bite := 0
var blocks: Array = []
var outlines: Array = []
var fills: Array = []
var sit_fraction := 0.0

func configure(frame: AtlasTexture, skin_material: ShaderMaterial, direction: int) -> void:
	facing = direction
	skin = skin_material.get_shader_parameter("skin_color")
	top = Vector2(-134, -150) + frame.margin.position
	if head == null:
		head = Sprite2D.new()
		head.centered = false
		add_child(head)
	var cropped := AtlasTexture.new()
	cropped.atlas = frame.atlas
	cropped.region = Rect2(frame.region.position, Vector2(frame.region.size.x, 120))
	cropped.filter_clip = true
	head.texture = cropped
	head.show_behind_parent = facing != 3
	head.material = skin_material.duplicate()
	head.material.set_shader_parameter("hide_body", false)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	blocks.clear()

func pose(progress: float, eating_time: float) -> void:
	var next_drop := roundf(progress * 24.0 / 6.0) * 6.0
	var next_bend := roundf(progress * 48.0 / 12.0) * 12.0
	# Reach, lift, mouth, lower, then a short pause. No diagonal subpixels.
	var next_bite: int = [0, 1, 2, 2, 1, 0, 0, 0][int(eating_time / 0.18) % 8] if eating_time >= 0 else 0
	if progress == sit_fraction and next_drop == drop and next_bend == bend and next_bite == bite and not blocks.is_empty():
		return
	drop = next_drop
	bend = next_bend
	bite = next_bite
	sit_fraction = progress
	# Contact is the underside of the thigh, not the sprite's center or feet.
	var contact_y := top.y + 180 + 24 + 36
	var target_y: float = (SEATING.CUSHION_Y - SEATING.BODY_ORIGIN_Y) / SEATING.BODY_SCALE
	position.y = (target_y - contact_y) * progress
	head.position = top + Vector2(0, drop)
	_build_body()
	queue_redraw()

func block(rect: Rect2, color: Color) -> void:
	outlines.append([rect, Color("30231c")])
	if rect.size.x > 24 and rect.size.y > 24:
		fills.append([Rect2(rect.position + Vector2(12, 12), rect.size - Vector2(24, 24)), color])

func _draw() -> void:
	for item in blocks:
		draw_rect(item[0], item[1])

func _build_body() -> void:
	blocks.clear()
	outlines.clear()
	fills.clear()
	if head == null:
		return
	var center := top.x + head.texture.get_width() / 2.0
	var shoulder := top.y + 108 + drop
	var hip := top.y + 180 + drop
	var standing_foot := top.y + 264
	var seated_foot: float = (SEATING.FLOOR_Y - SEATING.BODY_ORIGIN_Y) / SEATING.BODY_SCALE - position.y
	var foot := lerpf(standing_foot, seated_foot, sit_fraction)
	if facing in [1, 2]:
		var sign_x := 1.0 if facing == 1 else -1.0
		var knee := center + sign_x * bend
		# Far thigh/foot sit higher in screen space: both legs are visible from above.
		var depth := roundf(sit_fraction * 24.0 / 12.0) * 12.0
		block(Rect2(minf(center, knee) - 24, hip - depth, absf(knee - center) + 48, 36), skin.darkened(0.22))
		block(Rect2(knee - 12 + sign_x * 12, hip - depth + 12, 36, maxf(36, foot - hip - 12)), skin.darkened(0.22))
		block(Rect2(knee - 12 + minf(0, sign_x * 12), foot - depth - 24, 60, 24), skin.darkened(0.22))
		# Near leg remains anchored to the cushion and foreground floor.
		block(Rect2(minf(center, knee) - 24, hip, absf(knee - center) + 48, 36), skin.darkened(0.11))
		block(Rect2(knee - 24, hip + 12, 48, maxf(36, foot - hip - 12)), skin)
		block(Rect2(knee - 24 + minf(0, sign_x * 12), foot - 24, 60, 24), skin)
		block(Rect2(center - 36, shoulder, 60, 96), skin)
		# A slightly broader shoulder and lap show their upper surfaces.
		block(Rect2(center - 36, shoulder - depth / 2.0, 60, 36), skin)
		var hand_x := center + sign_x * 24
		var hand_y := shoulder + 48 - bite * 36
		block(Rect2(center - 36, shoulder + 12, 48, 60), skin.darkened(0.11))
		block(Rect2(minf(center - 12, hand_x - 24), hand_y, absf(hand_x - center + 12) + 36, 36), skin)
		if bite > 0:
			block(Rect2(hand_x - 18, hand_y + 12, 36, shoulder + 72 - hand_y), skin)
	else:
		# Knees move outward slightly; lower legs stay vertical under the seat.
		for side in [-1, 1]:
			var leg_x: float = center + side * (18 + bend / 4) - 24
			block(Rect2(leg_x, hip, 48, maxf(36, foot - hip)), skin)
			block(Rect2(leg_x - 6, hip, 60, 36), skin.darkened(0.11))
		block(Rect2(center - 48, shoulder, 96, 96), skin)
		block(Rect2(center - 72, shoulder + 12, 36, 72), skin)
		var arm_y := shoulder + 48 - bite * 36
		block(Rect2(center + 36, shoulder + 12, 36, 60), skin.darkened(0.11))
		# The hand is hidden behind the head when viewed from the back.
		if facing != 3:
			block(Rect2(center + 12 - bite * 12, arm_y, 60, 36), skin)
			if bite > 0:
				block(Rect2(center + 24 - bite * 12, arm_y + 12, 36, shoulder + 72 - arm_y), skin)
		else:
			# Seen from behind, the raised elbow moves but the hand stays in front.
			block(Rect2(center + 36, shoulder + 36 - bite * 12, 36, 48), skin)
	# Fill connected limbs after their outlines so joints have no black seams.
	blocks.assign(outlines + fills)
