extends "res://scripts/CustomerAppearance.gd"
const UNIFORM = preload("res://assets/art/PlayerUniform.gdshader")
const DEFAULT_LOOK = {"hair": 0, "hair_color": 1, "skin": 1}
const HAIR_NAMES = ["Calvo", "Corto", "Puntas", "Rizado", "Melena corta", "Coleta", "Afro", "Melena larga", "Semicalvo", "Cresta"]

func _ready() -> void:
	super._ready()
	var uniform := ShaderMaterial.new()
	uniform.shader = UNIFORM
	material = uniform
	apply_look(DEFAULT_LOOK)

static func clean_look(value: Variant) -> Dictionary:
	var result := DEFAULT_LOOK.duplicate()
	if value is Dictionary:
		for key in result:
			var number: Variant = value.get(key)
			if (number is int or number is float) and is_finite(float(number)):
				var maximum: int = HAIR_STYLE_COUNT - 1 if key == "hair" else (HAIR_COLORS.size() - 1 if key == "hair_color" else SKINS.size() - 1)
				result[key] = clampi(int(number), -1 if key == "hair" else 0, maximum)
	return result

func apply_look(value: Variant) -> void:
	var look := clean_look(value)
	set_skin(look.skin)
	set_hair(look.hair, look.hair_color)
	_show_frame(0)

func get_look() -> Dictionary:
	return {"hair": hair_style, "hair_color": hair_color_index, "skin": skin_index}

func _show_frame(column: int) -> void:
	super._show_frame(column)
	if material == null or material.shader != UNIFORM:
		return
	var frame := texture as AtlasTexture
	var sheet_size := frame.atlas.get_size()
	material.set_shader_parameter("body_region", Vector4(frame.region.position.x / sheet_size.x, frame.region.position.y / sheet_size.y, frame.region.size.x / sheet_size.x, frame.region.size.y / sheet_size.y))
	material.set_shader_parameter("body_size", frame.region.size)
	material.set_shader_parameter("facing", direction)
