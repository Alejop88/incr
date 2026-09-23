extends Button

var kind := "table"
var level := 1
var cost := 0
var accent := Color("85d6df")

func _ready() -> void:
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _draw() -> void:
	var center := Vector2(48, 46)
	var bought: bool = get_meta("bought", false)
	var fill := Color("fff5db")
	if bought:
		fill = Color("a8e3bf")
	elif button_pressed:
		fill = Color("ffd269")
	elif disabled:
		fill = Color("7189ad")
	draw_circle(center, 43, fill, true, -1, true)
	draw_circle(center, 43, accent if is_hovered() or has_focus() else Color("152d50"), false, 4, true)
	var ink := Color("294369") if not disabled or bought else Color("455e80")
	if kind == "speed":
		draw_colored_polygon(PackedVector2Array([Vector2(52, 24), Vector2(33, 48), Vector2(46, 48), Vector2(40, 68), Vector2(65, 40), Vector2(51, 40)]), ink)
	elif kind == "table":
		draw_rect(Rect2(29, 34, 38, 18), ink, false, 3)
		for x in [32, 64]:
			draw_line(Vector2(x, 52), Vector2(x, 64), ink, 3)
	elif kind == "staff":
		draw_circle(Vector2(48, 31), 8, ink)
		draw_style_box(_body(ink), Rect2(34, 43, 28, 22))
		draw_line(Vector2(48, 45), Vector2(48, 61), fill, 3)
	elif kind == "vip":
		draw_polyline(PackedVector2Array([Vector2(28, 34), Vector2(33, 58), Vector2(63, 58), Vector2(68, 34), Vector2(57, 43), Vector2(48, 29), Vector2(39, 43), Vector2(28, 34)]), ink, 3, true)
	elif kind == "menu":
		draw_rect(Rect2(32, 27, 32, 38), ink, false, 3)
		for y in [37, 46, 55]:
			draw_line(Vector2(39, y), Vector2(57, y), ink, 2)
	elif kind == "cook":
		draw_arc(Vector2(48, 53), 18, PI, TAU, 24, ink, 3, true)
		draw_line(Vector2(26, 55), Vector2(70, 55), ink, 3)
		draw_circle(Vector2(48, 32), 3, ink)
	else:
		draw_circle(Vector2(48, 45), 19, ink, false, 3, true)
		draw_circle(Vector2(48, 45), 12, ink, false, 2, true)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(71, 80), str(level), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var caption := "✓" if bought else ("★ %d" % cost)
	var width := font.get_string_size(caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18).x
	draw_string(font, Vector2(48 - width / 2, 112), caption, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("fff3ca"))

func _body(color: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.set_corner_radius_all(5)
	return box
