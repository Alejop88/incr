extends Area2D

signal payment_collected(amount: float)
signal table_selected(table: Area2D)
signal customers_left_without_paying(table: Area2D)
enum State {
	FREE,
	RESERVED,
	WAITING_FOOD,
	EATING,
	WAITING_PAYMENT
}

@export var eating_time: float = 5.0
@export var payment_amount: float = 5.0
@export var seat_capacity: int = 1
var seated_customer: CharacterBody2D = null
var required_plates: int = 1
var delivered_plates: int = 0
var occupied_seats: int = 0
@onready var eating_timer: Timer = $EatingTimer
@onready var customer_seat_points: Array[Marker2D] = []
@onready var food_wait_timer: Timer = $FoodWaitTimer
@onready var patience_bar: ProgressBar = $PatienceBar
var state: State = State.FREE


func _ready() -> void:
	add_to_group("restaurant_tables")
	for seat in $SeatPoints.get_children():
		if seat is Marker2D:
			customer_seat_points.append(seat)
	input_event.connect(_on_input_event)
	eating_timer.timeout.connect(_on_eating_timer_timeout)
func _process(_delta: float) -> void:
	if state == State.WAITING_FOOD:
		patience_bar.value = food_wait_timer.time_left

func seat_customer(customer: CharacterBody2D) -> bool:
	if state != State.RESERVED:
		return false

	seated_customer = customer
	state = State.WAITING_FOOD
	food_wait_timer.start(20.0)
	patience_bar.max_value = 20.0
	patience_bar.value = 20.0
	patience_bar.visible = true
	print("Cliente sentado. Esperando comida")
	return true

func reserve(customer: CharacterBody2D) -> bool:
	if state != State.FREE:
		return false

	seated_customer = customer
	required_plates = customer.get_group_size()
	occupied_seats = required_plates
	state = State.RESERVED

	print("Mesa reservada para un grupo de ",required_plates," personas")

	return true

func receive_food() -> bool:
	if state != State.WAITING_FOOD:
		print("Esta mesa no está esperando comida")
		return false

	delivered_plates += 1

	print("Platos entregados: ", delivered_plates, "/", required_plates)

	if delivered_plates >= required_plates:
		food_wait_timer.stop()
		patience_bar.visible = false
		state = State.EATING
		eating_timer.start(eating_time)

		print("Todos los platos entregados. El grupo empieza a comer")
	
	return true


func _on_eating_timer_timeout() -> void:
	if state != State.EATING:
		return

	state = State.WAITING_PAYMENT
	print("El cliente ha terminado. Esperando pago")


func collect_payment() -> bool:
	if state != State.WAITING_PAYMENT:
		return false

	var total_payment: float = payment_amount * required_plates
	payment_collected.emit(total_payment)
	clear_seated_customer()

	state = State.FREE
	print("Pago recogido: ",total_payment," € (",required_plates," platos)")
	print("La mesa vuelve a estar libre")

	return true


func _on_input_event(
	_viewport: Viewport,
	event: InputEvent,
	_shape_idx: int
) -> void:
	pass
			
func set_payment_amount(amount: float) -> void:
	payment_amount = amount
	
func get_customer_seat_position(seat_index: int = 0) -> Vector2:
	if seat_index < 0 or seat_index >= customer_seat_points.size():
		push_error("Índice de asiento inválido en la mesa: " + name)
		return global_position

	return customer_seat_points[seat_index].global_position
	
func get_seated_customer() -> CharacterBody2D:
	return seated_customer
	
func clear_seated_customer() -> void:
	seated_customer = null
	required_plates = 1
	delivered_plates = 0
	occupied_seats = 0
	state = State.FREE
	patience_bar.visible = false
func get_seat_capacity() -> int:
	return seat_capacity
func is_available() -> bool:
	return visible and state == State.FREE
func can_seat_group(group_size: int) -> bool:
	if not is_available():
		return false

	return seat_capacity >= group_size
func get_required_plates() -> int:
	return required_plates
func get_occupied_seats() -> int:
	return occupied_seats
func get_group_seat_positions(group_size: int) -> Array[Vector2]:
	var positions: Array[Vector2] = []

	for i in range(group_size):
		positions.append(get_customer_seat_position(i))

	return positions


func _on_food_wait_timer_timeout() -> void:
	if state != State.WAITING_FOOD:
		return

	print("Los clientes se han cansado de esperar")
	customers_left_without_paying.emit(self)
