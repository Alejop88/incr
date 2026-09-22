extends CharacterBody2D

enum State { IDLE, TO_KITCHEN, TO_TABLE, WAITING_CUSTOMER, TO_TRASH, TO_PAYMENT, RETURNING }
const BASE_SPEED: float = 90.0
const SPEED_PER_LEVEL: float = 15.0
@export var speed: float = BASE_SPEED

func set_speed_upgrade_level(level: int) -> void:
	speed = BASE_SPEED + SPEED_PER_LEVEL * level
var route = preload("res://scripts/RestaurantRoute.gd").new()
var coordinator: Node
var state: State = State.IDLE
var carried_dish: DishTypes.Type = DishTypes.Type.NONE
var second_dish: DishTypes.Type = DishTypes.Type.NONE
var carry_capacity: int = 1
var is_permanent: bool = false
var target_position: Vector2
var decision_delay: float = 0.0
var waiting_offset: Vector2 = Vector2(90, 65)
@onready var status_label: Label = $StatusLabel

func _ready() -> void:
	target_position = global_position
	_update_label()

func _physics_process(delta: float) -> void:
	decision_delay -= delta
	if state == State.IDLE:
		if decision_delay <= 0.0:
			_find_work()
		return
	if state == State.RETURNING and decision_delay <= 0.0:
		_find_work()
	if state == State.TO_PAYMENT and not coordinator.is_payment_valid(self):
		_finish_task()
		return
	if state == State.TO_TABLE and not coordinator.is_delivery_valid(self):
		_plan_delivery()
	elif state in [State.WAITING_CUSTOMER, State.TO_TRASH] and decision_delay <= 0.0:
		_plan_delivery()
	if state == State.IDLE:
		velocity = Vector2.ZERO
		return
	if route.advance(self, target_position, speed, delta):
		_arrive()

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
				_finish_dish()
			else:
				_plan_delivery()
		State.TO_PAYMENT:
			coordinator.collect_payment(self)
			_finish_task()
		State.RETURNING:
			state = State.IDLE
			_update_label()
		State.TO_TRASH:
			# Last check in case somebody ordered this dish on the way here.
			_plan_delivery()
			if state == State.TO_TRASH:
				_finish_dish()

func _finish_dish() -> void:
	coordinator.advance_dish(self)
	if carried_dish == DishTypes.Type.NONE:
		_finish_task()
	else:
		_plan_delivery()

func _plan_delivery() -> void:
	decision_delay = 0.2
	match coordinator.plan_delivery(self):
		"deliver":
			state = State.TO_TABLE
			target_position = coordinator.get_delivery_position(self)
		"wait":
			state = State.WAITING_CUSTOMER
			target_position = coordinator.get_waiting_position(self)
		"trash":
			state = State.TO_TRASH
			target_position = coordinator.get_trash_position()
	_update_label()

func _find_work() -> void:
	decision_delay = 0.2
	if coordinator.reserve_payment(self):
		state = State.TO_PAYMENT
		target_position = coordinator.get_payment_position(self)
	elif coordinator.reserve_pickup(self):
		state = State.TO_KITCHEN
		target_position = coordinator.get_kitchen_position()
	else:
		target_position = coordinator.get_waiting_position(self)
		state = State.RETURNING if global_position.distance_to(target_position) > 3.0 else State.IDLE
	_update_label()

func _finish_task() -> void:
	coordinator.release_assignment(self)
	carried_dish = DishTypes.Type.NONE
	second_dish = DishTypes.Type.NONE
	state = State.IDLE
	decision_delay = 0.0
	_update_label()

func _update_label() -> void:
	status_label.text = "Camarero permanente" if is_permanent else "Camarero"
	if carried_dish != DishTypes.Type.NONE:
		status_label.text += "\n" + DishTypes.Type.keys()[carried_dish]
		if second_dish != DishTypes.Type.NONE:
			status_label.text += " + " + DishTypes.Type.keys()[second_dish]
	elif state == State.TO_PAYMENT:
		status_label.text += "\nCobrar"
	elif state == State.RETURNING:
		status_label.text += "\nVolviendo"

func _exit_tree() -> void:
	if is_instance_valid(coordinator):
		coordinator.release_assignment(self)
