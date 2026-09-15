extends CharacterBody2D

enum State { IDLE, TO_KITCHEN, TO_TABLE, WAITING_CUSTOMER, TO_TRASH }
@export var speed: float = 180.0
var coordinator: Node
var state: State = State.IDLE
var carried_dish: DishTypes.Type = DishTypes.Type.NONE
var target_position: Vector2
var decision_delay: float = 0.0
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	target_position = global_position
	_update_label()

func _physics_process(delta: float) -> void:
	decision_delay -= delta
	if state == State.IDLE:
		if decision_delay <= 0.0:
			decision_delay = 0.2
			if coordinator.reserve_pickup(self):
				state = State.TO_KITCHEN
				target_position = coordinator.get_kitchen_position()
		return
	if state == State.TO_TABLE and not coordinator.is_delivery_valid(self):
		_plan_delivery()
	elif state in [State.WAITING_CUSTOMER, State.TO_TRASH] and decision_delay <= 0.0:
		_plan_delivery()
	if state == State.WAITING_CUSTOMER:
		velocity = Vector2.ZERO
		return
	var offset: Vector2 = target_position - global_position
	if offset.length() <= maxf(3.0, speed * delta):
		global_position = target_position
		velocity = Vector2.ZERO
		_arrive()
	else:
		velocity = offset.normalized() * speed
		move_and_slide()

func _arrive() -> void:
	match state:
		State.TO_KITCHEN:
			carried_dish = coordinator.pickup(self)
			if carried_dish == DishTypes.Type.NONE:
				_finish_task()
			else:
				_plan_delivery()
		State.TO_TABLE:
			if coordinator.deliver(self):
				_finish_task()
			else:
				_plan_delivery()
		State.TO_TRASH:
			# Last check in case somebody ordered this dish on the way here.
			_plan_delivery()
			if state == State.TO_TRASH:
				_finish_task()

func _plan_delivery() -> void:
	decision_delay = 0.2
	match coordinator.plan_delivery(self):
		"deliver":
			state = State.TO_TABLE
			target_position = coordinator.get_delivery_position(self)
		"wait":
			state = State.WAITING_CUSTOMER
		"trash":
			state = State.TO_TRASH
			target_position = coordinator.get_trash_position()
	_update_label()

func _finish_task() -> void:
	coordinator.release_assignment(self)
	carried_dish = DishTypes.Type.NONE
	state = State.IDLE
	decision_delay = 0.0
	_update_label()

func _update_label() -> void:
	status_label.text = "Camarero"
	if carried_dish != DishTypes.Type.NONE:
		status_label.text += "\n" + DishTypes.Type.keys()[carried_dish]

func _exit_tree() -> void:
	if is_instance_valid(coordinator):
		coordinator.release_assignment(self)
