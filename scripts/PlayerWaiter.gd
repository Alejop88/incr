extends CharacterBody2D

@export var speed: float = 220.0

var target_position: Vector2
var has_target: bool = false

func _ready() -> void:
	target_position = global_position

func move_to_position(new_position: Vector2) -> void:
	target_position = new_position
	has_target = true

func _physics_process(_delta: float) -> void:
	if not has_target:
		return
	
	var direction := target_position - global_position
	
	if direction.length() < 5.0:
		global_position = target_position
		velocity = Vector2.ZERO
		has_target = false
		return
	
	velocity = direction.normalized() * speed
	move_and_slide()
