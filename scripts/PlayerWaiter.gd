extends CharacterBody2D

signal destination_reached

@export var speed: float = 220.0
const BASE_SPEED: float = 220.0
const SPEED_PER_LEVEL: float = 25.0
var has_plate: bool = false
var target_position: Vector2
var has_target: bool = false
enum TargetType {
	NONE,
	KITCHEN,
	TABLE
}

var target_type: TargetType = TargetType.NONE

func _ready() -> void:
	target_position = global_position

func move_to_position(new_position: Vector2, type: TargetType) -> void:
	print(
		"CAMARERO RECIBE DESTINO: ",
		new_position,
		" | Posición actual: ",
		global_position
	)
	target_position = new_position
	target_type = type
	has_target = true

func _physics_process(_delta: float) -> void:
	if not has_target:
		return

	var direction := target_position - global_position

	if direction.length() < 5.0:
		global_position = target_position
		velocity = Vector2.ZERO
		has_target = false

		destination_reached.emit()
		return

	velocity = direction.normalized() * speed
	move_and_slide()
func set_speed_upgrade_level(level: int) -> void:
	speed = BASE_SPEED + SPEED_PER_LEVEL * level
