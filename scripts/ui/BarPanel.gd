extends Control
signal selected(id: String)
const DRINKS = preload("res://scripts/DrinkTypes.gd")
var index := 0
var active_id := ""
var icons: Array[Button] = []
var title_label: Label
var description_label: Label
var select_button: Button
var mode := "normal"
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.7)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(490, 340)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("22363d")
	style.set_content_margin_all(24)
	panel.add_theme_stylebox_override("panel", style)
	center.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	panel.add_child(column)
	var header := HBoxContainer.new()
	column.add_child(header)
	var label := Label.new()
	label.text = "BEBIDA DE LA BARRA"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(label)
	button(header, "×", hide)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(row)
	button(row, "‹", func(): cycle(-1))
	for offset in [-1, 0, 1]:
		var icon := button(row, "", func(): cycle(offset))
		icon.custom_minimum_size = Vector2(100 if offset == 0 else 75, 90)
		icon.add_theme_font_size_override("font_size", 48 if offset == 0 else 32)
		icon.modulate = Color.WHITE if offset == 0 else Color("93a4ab")
		icons.append(icon)
	button(row, "›", func(): cycle(1))
	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(title_label)
	description_label = Label.new()
	description_label.custom_minimum_size = Vector2(420, 75)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	column.add_child(description_label)
	select_button = button(column, "Seleccionar", func():
		active_id = DRINKS.CATALOG[index].id
		selected.emit(active_id)
		refresh())
	select_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	hide()
func button(parent: Node, text: String, action: Callable) -> Button:
	var result := Button.new()
	result.text = text
	result.custom_minimum_size = Vector2(40, 40)
	result.pressed.connect(action)
	parent.add_child(result)
	return result
func open(id: String, game_mode: String) -> void:
	active_id = id
	mode = game_mode
	index = maxi(0, DRINKS.index_of(id))
	refresh()
	show()
func cycle(amount: int) -> void:
	index = wrapi(index + amount, 0, DRINKS.CATALOG.size())
	refresh()
func refresh() -> void:
	for slot in range(3):
		var drink: Dictionary = DRINKS.CATALOG[wrapi(index + slot - 1, 0, DRINKS.CATALOG.size())]
		icons[slot].text = drink.icon
		icons[slot].tooltip_text = drink.name
	title_label.text = DRINKS.CATALOG[index].name
	description_label.text = DRINKS.description(index) if mode == "normal" else "Modo Cozy: bebida decorativa, sin cambios en las estadísticas."
	select_button.disabled = active_id == DRINKS.CATALOG[index].id
	select_button.text = "Seleccionada" if select_button.disabled else "Seleccionar"
