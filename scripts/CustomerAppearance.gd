extends Sprite2D
## Shared body frames. Future clothing layers must use this same direction/step.
const SHEET = preload("res://assets/art/CustomerBaseWalk.png")
const SUBTLE_SHEET = preload("res://assets/art/CustomerBaseWalkSubtle.png")
const SKIN_SHADER = preload("res://assets/art/CustomerSkin.gdshader")
const SKINS = [Color("f8c9ad"), Color("e9b58e"), Color("d99b69"), Color("ad7659"), Color("82513a"), Color("593522")]
const WALK_SEQUENCE = [1, 2, 3, 2]
const HAIR_SHEET = preload("res://assets/art/CustomerHairV2.png")
const EXTRA_HAIR_SHEET = preload("res://assets/art/CustomerHairExtra.png")
const CLASSIC_HAIR_SHEET = preload("res://assets/art/CustomerHairClassicV2.png")
const HAIR_STYLE_COUNT = 9
const HAIR_SHADER = preload("res://assets/art/CustomerHair.gdshader")
const HAIR_COLORS = [Color("302925"), Color("593723"), Color("98643c"), Color("dec179"), Color("b95428"), Color("b5b4af")]
static var hair_frames: Array[AtlasTexture] = []
var hair: Sprite2D
var hair_style: int = 0
var hair_color_index: int = 0
static var frames: Array[AtlasTexture] = []
static var head_anchors: Array[Vector2] = []
static var head_widths: Array[float] = []
var walking: bool = false
var direction: int = 0 # front, right, left, back
var step: int = 0
var distance_walked: float = 0.0
var skin_index: int = 0
var seated := false
var eating := false
var sitting_progress := 0.0
var eating_clock := 0.0
var seated_rig: Node2D

func _ready() -> void:
	_build_frames()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Keep the existing customer's approximate 120px visual height and foot position.
	scale = Vector2.ONE * (120.0 / 280.0)
	position = Vector2(1, 10)
	var skin_material := ShaderMaterial.new()
	skin_material.shader = SKIN_SHADER
	material = skin_material
	seated_rig = preload("res://scripts/CustomerSeatedRig.gd").new()
	add_child(seated_rig)
	seated_rig.hide()
	set_skin(randi_range(0, SKINS.size() - 1))
	_build_hair_frames()
	hair = Sprite2D.new()
	hair.name = "Hair"
	hair.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var hair_material := ShaderMaterial.new()
	hair_material.shader = HAIR_SHADER
	hair.material = hair_material
	add_child(hair)
	# -1 is bald; equally likely as any individual hairstyle.
	set_hair(randi_range(-1, HAIR_STYLE_COUNT - 1), randi_range(0, HAIR_COLORS.size() - 1))
	_show_frame(0)

static func _opaque_bounds(image: Image) -> Rect2i:
	# Ignore transparent generation noise and isolated specks when finding anchors.
	var rows: Array[int] = []
	var columns: Array[int] = []
	rows.resize(image.get_height())
	columns.resize(image.get_width())
	rows.fill(0)
	columns.fill(0)
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x, y).a > 0.9:
				rows[y] += 1
				columns[x] += 1
	var left := image.get_width()
	var top := image.get_height()
	var right := 0
	var bottom := 0
	for x in range(columns.size()):
		if columns[x] >= 8:
			left = mini(left, x)
			right = x + 1
	for y in range(rows.size()):
		if rows[y] >= 8:
			top = mini(top, y)
			bottom = y + 1
	return Rect2i(left, top, maxi(1, right - left), maxi(1, bottom - top))

static func _build_hair_frames() -> void:
	if not hair_frames.is_empty():
		return
	var source := HAIR_SHEET.get_image()
	var cell_size := source.get_size() / 4
	for style in range(4):
		for facing in range(4):
			var cell := Rect2i(Vector2i(facing, style) * cell_size, cell_size)
			var used := _opaque_bounds(source.get_region(cell))
			var frame := AtlasTexture.new()
			frame.atlas = HAIR_SHEET
			frame.region = Rect2(cell.position + used.position, used.size)
			frame.filter_clip = true
			hair_frames.append(frame)
	var extra := EXTRA_HAIR_SHEET.get_image()
	var cell_width := extra.get_width() / 4
	# The generated rows have unequal outer padding; keep the tall styles apart.
	var row_edges := [0, roundi(extra.get_height() * 0.34), roundi(extra.get_height() * 0.62), extra.get_height()]
	for style in range(3):
		for facing in range(4):
			var cell := Rect2i(facing * cell_width, row_edges[style], cell_width, row_edges[style + 1] - row_edges[style])
			var used := _opaque_bounds(extra.get_region(cell))
			var frame := AtlasTexture.new()
			frame.atlas = EXTRA_HAIR_SHEET
			frame.region = Rect2(cell.position + used.position, used.size)
			frame.filter_clip = true
			hair_frames.append(frame)

	var classic := CLASSIC_HAIR_SHEET.get_image()
	var classic_width := classic.get_width() / 4
	var classic_rows := [0, roundi(classic.get_height() * 0.33), roundi(classic.get_height() * 0.64), classic.get_height()]
	for style in range(2):
		for facing in range(4):
			var cell := Rect2i(facing * classic_width, classic_rows[style], classic_width, classic_rows[style + 1] - classic_rows[style])
			var used := _opaque_bounds(classic.get_region(cell))
			var frame := AtlasTexture.new()
			frame.atlas = CLASSIC_HAIR_SHEET
			frame.region = Rect2(cell.position + used.position, used.size)
			frame.filter_clip = true
			hair_frames.append(frame)

func set_hair(style: int, color_index: int) -> void:
	hair_style = clampi(style, -1, HAIR_STYLE_COUNT - 1)
	hair_color_index = clampi(color_index, 0, HAIR_COLORS.size() - 1)
	(hair.material as ShaderMaterial).set_shader_parameter("hair_color", HAIR_COLORS[hair_color_index])
	if texture is AtlasTexture:
		_update_hair()

func _update_hair() -> void:
	if hair == null:
		return
	hair.visible = hair_style >= 0
	if not hair.visible:
		return
	var body_frame := texture as AtlasTexture
	hair.texture = hair_frames[hair_style * 4 + direction]
	var frame_index := frames.find(body_frame)
	# Front caps are shallow: fitting every view by width alone covered the eyes.
	# Keep overlap on both sides even at the extremes of the walking sway.
	var width := maxf(158.0 if hair_style == 2 else 152.0, head_widths[frame_index] + 18.0)
	var height := 110.0
	if direction == 0 and hair_style < 4:
		height = [50.0, 58.0, 62.0, 112.0][hair_style]
	elif hair_style == 3:
		height = 122.0
	var top_offset := -14.0
	var side_offset := 0.0
	if hair_style == 4: # Ponytail projects behind the scalp in profile.
		width = 176.0 if direction in [0, 3] else 194.0
		height = 125.0 if direction == 0 else 160.0
		top_offset = -54.0
		side_offset = -22.0 if direction == 1 else (22.0 if direction == 2 else 0.0)
	elif hair_style == 5: # Afro: a larger halo around the same face opening.
		width = 198.0
		height = 142.0
		top_offset = -44.0 if direction == 0 else -30.0
		if direction in [1, 2]:
			top_offset = -48.0
			side_offset = -18.0 if direction == 1 else 18.0
	elif hair_style == 6: # Long hair reaches below the shoulders.
		width = 174.0
		height = 190.0
		top_offset = -30.0
		if direction in [1, 2]:
			top_offset = -35.0 + 3.0 / scale.y
			side_offset = -14.0 if direction == 1 else 14.0
	elif hair_style == 7: # Bald crown, short sides and lower horseshoe at the back.
		width = 154.0
		height = 65.0
		top_offset = 20.0
		if direction in [1, 2]:
			width = 72.0
			height = 72.0
			top_offset = 12.0
			side_offset = -49.0 if direction == 1 else 49.0
	elif hair_style == 8: # Narrow ridge head-on, full crest in profile.
		width = 35.0 if direction in [0, 3] else 145.0
		height = 75.0 if direction in [0, 3] else 70.0
		top_offset = -50.0 if direction in [0, 3] else -30.0
	var hair_material := hair.material as ShaderMaterial
	hair_material.set_shader_parameter("bald_front", hair_style == 7 and direction == 0)
	if hair_style >= 7:
		# Same coarse square grid as the body's approximately 12px source blocks.
		width = roundf(width / 12.0) * 12.0
		height = roundf(height / 12.0) * 12.0
		var atlas := hair.texture as AtlasTexture
		var sheet_size := atlas.atlas.get_size()
		hair_material.set_shader_parameter("pixel_grid", Vector2(width, height) / 12.0)
		hair_material.set_shader_parameter("atlas_region", Vector4(atlas.region.position.x / sheet_size.x, atlas.region.position.y / sheet_size.y, atlas.region.size.x / sheet_size.x, atlas.region.size.y / sheet_size.y))
	else:
		hair_material.set_shader_parameter("pixel_grid", Vector2.ZERO)
	hair.scale = Vector2(width, height) / hair.texture.get_size()
	var anchor := head_anchors[frame_index]
	var sway := Vector2.ZERO
	if walking:
		var phase := distance_walked / 48.0 * TAU
		var amount := 2.0 if hair_style in [3, 4, 6] else 1.0
		sway = Vector2(roundf(sin(phase) * amount), -roundf(absf(sin(phase)) * amount))
	hair.position = anchor + Vector2(side_offset, height / 2.0 + top_offset) + sway
	if seated:
		hair.position.y += seated_rig.drop + seated_rig.position.y

static func _build_frames() -> void:
	if not frames.is_empty():
		return
	var source: Image = SHEET.get_image()
	var subtle_source: Image = SUBTLE_SHEET.get_image()
	# Generated sheet cells have outer padding. Trim each cell's transparent
	# bounds into an equally sized atlas frame, anchored at the feet.
	for row in range(4):
		var vertical := row == 0 or row == 3
		var idle_cell := Rect2i(96, 16 + row * 306, 268, 306)
		var idle_bounds := _opaque_bounds(source.get_region(idle_cell))
		for column in range(4):
			# Passing pose uses the exact idle body to avoid torso/head wobble.
			var source_column := 0 if vertical and column == 2 else column
			var cell := Rect2i(96 + source_column * 268, 16 + row * 306, 268, 306)
			var use_subtle := vertical and column in [1, 3]
			var used := _opaque_bounds((subtle_source if use_subtle else source).get_region(cell))
			var frame := AtlasTexture.new()
			frame.atlas = SUBTLE_SHEET if use_subtle else SHEET
			frame.region = Rect2(cell.position + used.position, used.size)
			frame.margin = Rect2(Vector2((268 - used.size.x) / 2.0, 300 - used.size.y), Vector2(268 - used.size.x, 300 - used.size.y))
			if vertical:
				frame.margin.position.y = 300 - idle_bounds.size.y
			frame.filter_clip = true
			frames.append(frame)
			# Anchor to the head rather than the whole body's bounds: walking arms
			# change those bounds and previously shifted the hair across the face.
			var body_image := subtle_source if use_subtle else source
			var head_region := Rect2i(cell.position + used.position, Vector2i(used.size.x, 85))
			var head_bounds := _opaque_bounds(body_image.get_region(head_region))
			head_widths.append(float(head_bounds.size.x))
			head_anchors.append(Vector2(-134 + frame.margin.position.x + head_bounds.position.x + head_bounds.size.x / 2.0, -150 + frame.margin.position.y))

func set_skin(index: int) -> void:
	skin_index = clampi(index, 0, SKINS.size() - 1)
	(material as ShaderMaterial).set_shader_parameter("skin_color", SKINS[skin_index])

func update_movement(displacement: Vector2, _delta: float) -> void:
	if seated:
		sitting_progress = minf(1.0, sitting_progress + _delta / 0.36)
		if eating and sitting_progress >= 1.0:
			eating_clock += _delta
		seated_rig.pose(sitting_progress, eating_clock if eating and sitting_progress >= 1.0 else -1.0)
		_update_hair()
		return
	if displacement.length_squared() < 0.0001:
		walking = false
		distance_walked = 0.0
		step = 0
		_show_frame(0)
		return
	walking = true
	if absf(displacement.x) > absf(displacement.y):
		direction = 1 if displacement.x > 0 else 2
	else:
		direction = 0 if displacement.y > 0 else 3
	distance_walked += displacement.length()
	step = int(distance_walked / 12.0) % WALK_SEQUENCE.size()
	_show_frame(WALK_SEQUENCE[step])

func _show_frame(column: int) -> void:
	texture = frames[direction * 4 + column]
	_update_hair()

func sit_down(toward_table: Vector2) -> void:
	if seated:
		return
	walking = false
	distance_walked = 0.0
	step = 0
	if absf(toward_table.x) > absf(toward_table.y):
		direction = 1 if toward_table.x > 0 else 2
	else:
		direction = 0 if toward_table.y > 0 else 3
	_show_frame(0)
	seated_rig.configure(texture, material, direction)
	seated = true
	sitting_progress = 0.0
	seated_rig.pose(0.0, -1.0)
	seated_rig.show()
	(material as ShaderMaterial).set_shader_parameter("hide_body", true)
	_update_hair()

func set_plate_position(world_position: Vector2) -> void:
	seated_rig.plate_target = to_local(world_position)

func set_table_cover(world_rect: Rect2) -> void:
	seated_rig.table_occlusion = Rect2(to_local(world_rect.position), world_rect.size / global_scale)

func set_eating(value: bool) -> void:
	eating = value
	eating_clock = 0.0
	if seated:
		seated_rig.pose(sitting_progress, 0.0 if value else -1.0)

func stand_up() -> void:
	seated = false
	eating = false
	sitting_progress = 0.0
	seated_rig.hide()
	(material as ShaderMaterial).set_shader_parameter("hide_body", false)
	_show_frame(0)
