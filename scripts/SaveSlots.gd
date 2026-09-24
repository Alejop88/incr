extends Node

# The running restaurant keeps this path; saving never asks for another slot.
var active_path: String = "user://partida.json"
var new_game_pending: bool = false
var selected_mode: String = "cozy"

static func slot_path(base: String, index: int) -> String:
	return base if index == 0 else "%s_%d.json" % [base.get_basename(), index + 1]

static func mode_name(mode: String) -> String:
	return "Normal" if mode == "normal" else "Cozy"

static func time_label(seconds: float) -> String:
	var total := int(seconds)
	return "%02d:%02d:%02d" % [total / 3600, (total / 60) % 60, total % 60]
