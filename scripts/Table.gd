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
@export var unlocked: bool = true
const BASE_EATING_TIME: float = 5.0
const EATING_TIME_REDUCTION_PER_LEVEL: float = 0.2
const MIN_EATING_TIME: float = 1.0

var eating_speed_level: int = 0
var eating_time: float = BASE_EATING_TIME
@export var payment_amount: float = 5.0
@export var seat_capacity: int = 1
const BASE_FOOD_WAIT_TIME: float = 20.0
const FOOD_WAIT_TIME_INCREASE_PER_LEVEL: float = 2.0
const MAX_FOOD_WAIT_TIME: float = 40.0

var patience_level: int = 0
var food_wait_time: float = BASE_FOOD_WAIT_TIME
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
	update_food_wait_time()
	update_eating_time()
	if not unlocked:
		visible = false
func _process(_delta: float) -> void:
	if state == State.WAITING_FOOD:
		patience_bar.value = food_wait_timer.time_left

func seat_customer(customer: CharacterBody2D) -> bool:
	if state != State.RESERVED:
		return false

	seated_customer = customer
	state = State.WAITING_FOOD
	food_wait_timer.start(food_wait_time)
	patience_bar.max_value = food_wait_time
	patience_bar.value = food_wait_time
	patience_bar.visible = true
	var customer_group: Node = customer.get_parent()

	if customer_group != null and customer_group.has_method("get_customers"):
		for group_customer in customer_group.get_customers():
			group_customer.show_order()
	print("Cliente sentado. Esperando comida")
	return true

func reserve(customer_group: Node2D) -> bool:
	if not unlocked:
		return false

	if state != State.FREE:
		return false

	var leader: CharacterBody2D = customer_group.get_leader()

	if leader == null:
		return false

	seated_customer = leader

	required_plates = customer_group.get_group_size()
	occupied_seats = required_plates
	state = State.RESERVED


	return true

func receive_food(dish: DishTypes.Type) -> bool:
	if state != State.WAITING_FOOD:
		print("Esta mesa no está esperando comida")
		return false

	var customer: CharacterBody2D = find_customer_waiting_for_dish(dish)

	if customer == null:
		print(
			"Ningún cliente de esta mesa espera: ",
			DishTypes.Type.keys()[dish]
		)
		return false

	customer.has_received_food = true
	customer.hide_order()
	delivered_plates += 1
	print(
	"Cliente servido con ",
	DishTypes.Type.keys()[dish],
	" | Faltan por servir: ",
	required_plates - delivered_plates
)
	print(
		"Plato entregado a un cliente: ",
		DishTypes.Type.keys()[dish]
	)

	print(
		"Platos entregados: ",
		delivered_plates,
		"/",
		required_plates
	)

	if delivered_plates >= required_plates:
		food_wait_timer.stop()
		patience_bar.visible = false
		state = State.EATING
		eating_timer.start(eating_time)

		print(
			"Todos los clientes tienen su plato. El grupo empieza a comer"
		)

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
	if not unlocked:
		return false

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
func unlock() -> void:
	unlocked = true
	visible = true

	print(name, " desbloqueada")


func lock() -> void:
	unlocked = false
	visible = false
func find_customer_waiting_for_dish(
	dish: DishTypes.Type
) -> CharacterBody2D:

	if seated_customer == null:
		return null

	var customer_group: Node = seated_customer.get_parent()

	if customer_group == null:
		return null

	for customer in customer_group.get_customers():
		if customer.requested_dish == dish \
		and not customer.has_received_food:
			return customer

	return null
func update_eating_time() -> void:
	eating_time = max(
		MIN_EATING_TIME,
		BASE_EATING_TIME - EATING_TIME_REDUCTION_PER_LEVEL * eating_speed_level
	)

func set_eating_speed_level(level: int) -> void:
	eating_speed_level = max(level, 0)
	update_eating_time()
func update_food_wait_time() -> void:
	food_wait_time = min(
		MAX_FOOD_WAIT_TIME,
		BASE_FOOD_WAIT_TIME + FOOD_WAIT_TIME_INCREASE_PER_LEVEL * patience_level
	)

func set_patience_level(level: int) -> void:
	patience_level = max(level, 0)
	update_food_wait_time()
