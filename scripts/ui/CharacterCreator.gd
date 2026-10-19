extends CenterContainer
signal accepted(look: Dictionary)
signal cancelled
const APPEARANCE = preload("res://scripts/PlayerAppearance.gd")
var preview: Sprite2D
var accept_button: Button
var random_button: Button
var values: Dictionary = {}
var look: Dictionary = APPEARANCE.DEFAULT_LOOK.duplicate()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(600, 440)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("22363d")
	style.border_color = Color("8caa9a")
	style.set_border_width_all(3)
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	var title := Label.new()
	title.text = "Crea tu camarero"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	column.add_child(row)
	var character_column := VBoxContainer.new()
	row.add_child(character_column)
	var backdrop := ColorRect.new()
	backdrop.color = Color("405454")
	backdrop.custom_minimum_size = Vector2(250, 280)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	character_column.add_child(backdrop)
	preview = APPEARANCE.new()
	backdrop.add_child(preview)
	preview.position = Vector2(125, 135)
	preview.scale = Vector2.ONE * 0.72
	accept_button = button(character_column, "Aceptar", func(): accepted.emit(look.duplicate()))
	var options := VBoxContainer.new()
	options.custom_minimum_size.x = 260
	options.add_theme_constant_override("separation", 12)
	row.add_child(options)
	for key in ["hair", "hair_color", "skin"]:
		var label := Label.new()
		label.text = {"hair": "Peinado", "hair_color": "Color del pelo", "skin": "Tono de piel"}[key]
		options.add_child(label)
		var controls := HBoxContainer.new()
		options.add_child(controls)
		button(controls, "‹", cycle.bind(key, -1)).custom_minimum_size.x = 44
		var value := Label.new()
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		controls.add_child(value)
		values[key] = value
		button(controls, "›", cycle.bind(key, 1)).custom_minimum_size.x = 44
	random_button = button(options, "Aleatorio", randomize_look)
	button(options, "Volver", func(): cancelled.emit())
	refresh()
	hide()

func button(parent: Node, text: String, callback: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size.y = 40
	result.pressed.connect(callback)
	parent.add_child(result)
	return result

func open_creator() -> void:
	look = APPEARANCE.DEFAULT_LOOK.duplicate()
	refresh()
	show()
	accept_button.grab_focus()

func cycle(key: String, step: int) -> void:
	var count: int = APPEARANCE.HAIR_STYLE_COUNT + 1 if key == "hair" else (APPEARANCE.HAIR_COLORS.size() if key == "hair_color" else APPEARANCE.SKINS.size())
	var offset := 1 if key == "hair" else 0
	look[key] = posmod(int(look[key]) + offset + step, count) - offset
	refresh()

func randomize_look() -> void:
	look = {"hair": randi_range(-1, APPEARANCE.HAIR_STYLE_COUNT - 1), "hair_color": randi_range(0, APPEARANCE.HAIR_COLORS.size() - 1), "skin": randi_range(0, APPEARANCE.SKINS.size() - 1)}
	refresh()

func refresh() -> void:
	preview.apply_look(look)
	values.hair.text = APPEARANCE.HAIR_NAMES[int(look.hair) + 1]
	values.hair_color.text = ["Negro", "Castaño", "Castaño claro", "Rubio", "Pelirrojo", "Gris"][int(look.hair_color)]
	values.skin.text = "%d / %d" % [int(look.skin) + 1, APPEARANCE.SKINS.size()]
