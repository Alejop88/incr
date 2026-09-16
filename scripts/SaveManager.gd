extends Node

const SAVE_VERSION: int = 1
@export_file("*.json") var save_path: String = "user://partida.json"
var last_error: String = ""

func save_game(data: Dictionary) -> bool:
	last_error = ""
	var payload: Dictionary = data.duplicate(true)
	payload["version"] = SAVE_VERSION
	if not _is_valid_save(payload):
		last_error = "No se pudo guardar: los datos de la partida no son válidos."
		return false
	# Conserva el guardado anterior si falla la escritura del temporal.
	var temporary_path: String = save_path + ".tmp"
	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		last_error = "No se pudo guardar. Comprueba el espacio y los permisos."
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		last_error = "No se pudo completar la escritura de la partida."
		return false
	var rename_error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(save_path)
	)
	if rename_error != OK:
		last_error = "No se pudo reemplazar el guardado anterior."
		return false
	return true

func delete_save() -> bool:
	last_error = ""
	if not FileAccess.file_exists(save_path):
		return true
	var error: Error = DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	if error != OK:
		last_error = "No se pudo borrar el guardado. La partida actual se conserva."
		return false
	return true

func load_game() -> Dictionary:
	last_error = ""
	if not FileAccess.file_exists(save_path):
		return {}
	var file: FileAccess = FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		last_error = "No se pudo abrir la partida guardada."
		return {}
	var parser := JSON.new()
	var parse_error: Error = parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not parser.data is Dictionary:
		last_error = "El guardado no es válido. No se ha cargado."
		return {}
	var data: Dictionary = parser.data
	if not _is_valid_save(data):
		last_error = "El guardado está incompleto o pertenece a otra versión."
		return {}
	return data

func _is_valid_save(data: Dictionary) -> bool:
	if data.get("version") != SAVE_VERSION:
		return false
	if not _is_nonnegative_number(data.get("money")):
		return false
	if not data.get("michelin") is Dictionary or not data.get("levels") is Dictionary:
		return false
	var michelin: Dictionary = data["michelin"]
	if not _is_nonnegative_number(michelin.get("stars")):
		return false
	if not _is_string_array(michelin.get("bought_upgrades")):
		return false
	if not _is_string_array(data.get("unlocked_tables")):
		return false
	var hired_waiters: Variant = data.get("hired_waiters", 0)
	if data.has("menu_dishes") and not _is_string_array(data["menu_dishes"]):
		return false
	if data.has("unlocked_dishes") and not _is_string_array(data["unlocked_dishes"]):
		return false
	if not _is_nonnegative_number(hired_waiters):
		return false
	if hired_waiters > 1 or hired_waiters != floor(hired_waiters):
		return false
	for key in ["waiter_speed", "plate_price", "cook_speed", "eating_speed", "patience"]:
		var value: Variant = data["levels"].get(key)
		if not _is_nonnegative_number(value):
			return false
		if value > 10 or value != floor(value):
			return false
	return true

func _is_nonnegative_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= 0

func _is_string_array(value: Variant) -> bool:
	if not value is Array:
		return false
	for item in value:
		if not item is String:
			return false
	return true
