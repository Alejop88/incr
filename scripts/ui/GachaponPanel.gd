extends Control
signal spin_requested
var spin_button: Button
var odds_label: Label
var result_label: Label
var collection_label: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.65)
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(490, 420)
	center.add_child(panel)
	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := Label.new()
	title.text = "GACHAPÓN"
	title.add_theme_font_size_override("font_size", 28)
	column.add_child(title)
	var note := Label.new()
	note.text = "Skins provisionales · Sin apariencia disponible aún.\nCada objeto sale una sola vez."
	column.add_child(note)
	odds_label = Label.new()
	column.add_child(odds_label)
	collection_label = Label.new()
	column.add_child(collection_label)
	result_label = Label.new()
	result_label.custom_minimum_size.y = 50
	result_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(result_label)
	spin_button = Button.new()
	spin_button.custom_minimum_size.y = 44
	spin_button.pressed.connect(func(): spin_requested.emit())
	column.add_child(spin_button)
	var close := Button.new()
	close.text = "Cerrar"
	close.pressed.connect(hide)
	column.add_child(close)
	hide()

func refresh(model: RefCounted, money: float) -> void:
	var odds: Array[float] = model.probabilities()
	var counts := [0, 0, 0, 0]
	for item in model.remaining():
		counts[item.rarity] += 1
	odds_label.text = "Probabilidades de la próxima cápsula\n"
	for index in range(4):
		odds_label.text += "%s: %.2f %% · %d restantes\n" % [model.RARITIES[index], odds[index], counts[index]]
	collection_label.text = "Colección: %d / %d" % [model.owned.size(), model.catalog.size()]
	spin_button.text = "Colección completa" if model.remaining().is_empty() else "Sacar cápsula · 100 €"
	spin_button.disabled = money < model.PRICE or model.remaining().is_empty()

func show_result(item: Dictionary) -> void:
	result_label.text = "¡Has obtenido %s!\nAñadido a tu colección." % item.name
	result_label.modulate = [Color("c7e4d1"), Color("77bdff"), Color("d894ff"), Color("ffd66c")][item.rarity]
