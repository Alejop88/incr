extends Area2D

signal payment_collected(amount: float)

enum State {
	FREE,
	WAITING_FOOD,
	EATING,
	WAITING_PAYMENT
}

@export var eating_time: float = 5.0
@export var payment_amount: float = 5.0

@onready var eating_timer: Timer = $EatingTimer

var state: State = State.FREE


func _ready() -> void:
	input_event.connect(_on_input_event)
	eating_timer.timeout.connect(_on_eating_timer_timeout)


func seat_customer() -> bool:
	if state != State.FREE:
		return false

	state = State.WAITING_FOOD
	print("Cliente sentado. Esperando comida")
	return true


func receive_food() -> bool:
	if state != State.WAITING_FOOD:
		print("Esta mesa no está esperando comida")
		return false

	state = State.EATING
	eating_timer.start(eating_time)

	print("El cliente empieza a comer")
	return true


func _on_eating_timer_timeout() -> void:
	if state != State.EATING:
		return

	state = State.WAITING_PAYMENT
	print("El cliente ha terminado. Esperando pago")


func collect_payment() -> bool:
	if state != State.WAITING_PAYMENT:
		return false

	payment_collected.emit(payment_amount)

	state = State.FREE
	print("Pago recogido: ", payment_amount, " €")
	print("La mesa vuelve a estar libre")

	return true


func _on_input_event(
	_viewport: Viewport,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:

		if state == State.WAITING_PAYMENT:
			collect_payment()
