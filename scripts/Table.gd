extends Area2D

signal payment_collected(amount: float)
signal customers_left_without_paying(table: Area2D)
signal eating_finished(table: Area2D)
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
var menu_speed_multiplier: float = 1.0
var menu_patience_multiplier: float = 1.0
var eating_time: float = BASE_EATING_TIME
@export var payment_amount: float = 5.0
var dish_value_multipliers: Dictionary = {}
var served_value_bonus: float = 0.0
@export var seat_capacity: int = 1
@export var table_skin: Resource = preload("res://assets/art/table_classic.tres")
var appearance: Node2D
const BASE_FOOD_WAIT_TIME: float = 20.0
const FOOD_WAIT_TIME_INCREASE_PER_LEVEL: float = 2.0
const MAX_FOOD_WAIT_TIME: float = 40.0

var patience_level: int = 0
var food_wait_time: float = BASE_FOOD_WAIT_TIME
var seated_customer: CharacterBody2D = null
var required_plates: int = 1
var delivered_plates: int = 0
var occupied_seats: int = 0
var food_round: int = 0
@onready var eating_timer: Timer = $EatingTimer
@onready var customer_seat_points: Array[Marker2D] = []
@onready var food_wait_timer: Timer = $FoodWaitTimer
@onready var patience_bar: ProgressBar = $PatienceBar
var state: State = State.FREE

func _ready() -> void:
	patience_bar.hide()
	var capacity_label := Label.new()
	capacity_label.text = "%s · %d plazas" % [str(name).trim_prefix("Table").trim_suffix("Point"), seat_capacity]
	var furniture_size := preload("res://scripts/TableAppearance.gd").surface_size(seat_capacity)
	capacity_label.position = Vector2(-64, furniture_size.y / 2.0 + 32)
	capacity_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(capacity_label)
	add_to_group("restaurant_tables")
	for seat in $SeatPoints.get_children():
		if seat is Marker2D:
			customer_seat_points.append(seat)
	appearance = preload("res://scripts/TableAppearance.gd").new()
	appearance.name = "TableAppearance"
	add_child(appearance)
	set_table_skin(table_skin)
	# Every table gets its own hit shape, matching its actual top.
	var hit_shape := RectangleShape2D.new()
	hit_shape.size = furniture_size
	$CollisionShape2D.shape = hit_shape
	$CollisionShape2D.position = Vector2(0, preload("res://scripts/SeatingLayout.gd").TABLETOP_Y)
	patience_bar.position = Vector2(-40, -furniture_size.y / 2.0 - 24)
	patience_bar.size = Vector2(80, 14)
	eating_timer.timeout.connect(_on_eating_timer_timeout)
	update_food_wait_time()
	update_eating_time()
	if not unlocked:
		visible = false
func _process(_delta: float) -> void:
	if state == State.WAITING_FOOD:
		patience_bar.value = food_wait_timer.time_left

func set_table_skin(new_skin: Resource) -> void:
	table_skin = new_skin if new_skin != null else preload("res://assets/art/table_classic.tres")
	if appearance == null:
		return
	var seat_positions: Array[Vector2] = []
	for seat in customer_seat_points:
		seat_positions.append(seat.position)
	appearance.configure(seat_capacity, seat_positions, table_skin)

func get_furniture_bounds() -> Rect2:
	return preload("res://scripts/TableAppearance.gd").furniture_bounds(seat_capacity)

func seat_customer(customer: CharacterBody2D) -> bool:
	if state != State.RESERVED:
		return false

	seated_customer = customer
	food_round += 1
	state = State.WAITING_FOOD
	var current_food_wait_time: float = food_wait_time

	if customer is VIPCustomer:
		current_food_wait_time = customer.FOOD_WAIT_TIME

	current_food_wait_time *= menu_patience_multiplier
	food_wait_timer.start(current_food_wait_time)

	patience_bar.max_value = current_food_wait_time
	patience_bar.value = current_food_wait_time
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
	served_value_bonus = 0.0

	required_plates = customer_group.get_group_size()
	occupied_seats = required_plates
	state = State.RESERVED


	return true

func can_serve_customer(customer: CharacterBody2D, dish: DishTypes.Type) -> bool:
	if state != State.WAITING_FOOD or not is_instance_valid(seated_customer) or not is_instance_valid(customer):
		return false
	var group: Node = seated_customer.get_parent()
	return group.has_method("get_customers") and customer in group.get_customers() \
		and not customer.has_received_food and customer.requested_dish == dish

func receive_food(dish: DishTypes.Type, target_customer: CharacterBody2D = null) -> bool:
	if state != State.WAITING_FOOD:
		print("Esta mesa no está esperando comida")
		return false

	var customer: CharacterBody2D = target_customer
	if customer == null:
		customer = find_customer_waiting_for_dish(dish)
	elif not can_serve_customer(customer, dish):
		return false

	if customer == null:
		print(
			"Ningún cliente de esta mesa espera: ",
			DishTypes.Type.keys()[dish]
		)
		return false

	customer.has_received_food = true
	customer.hide_order()
	delivered_plates += 1
	# Keep each delivered dish's bonus even if the menu changes before payment.
	served_value_bonus += float(dish_value_multipliers.get(dish, 1.0)) - 1.0
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
		_set_group_eating(true)

		var current_eating_time: float = eating_time

		if seated_customer is VIPCustomer:
			current_eating_time = seated_customer.EATING_TIME / menu_speed_multiplier

		eating_timer.start(current_eating_time)

		print(
			"Todos los clientes tienen su plato. El grupo empieza a comer"
		)

	return true

func start_next_food_round(customer: CharacterBody2D,plates_needed: int) -> void:
	_set_group_eating(false)
	served_value_bonus = 0.0
	food_round += 1
	delivered_plates = 0
	required_plates = plates_needed

	state = State.WAITING_FOOD

	var current_food_wait_time: float = food_wait_time

	if customer is VIPCustomer:
		current_food_wait_time = customer.FOOD_WAIT_TIME

	current_food_wait_time *= menu_patience_multiplier
	food_wait_timer.start(current_food_wait_time)

	patience_bar.max_value = current_food_wait_time
	patience_bar.value = current_food_wait_time
	patience_bar.visible = true

	print(
		"Nueva ronda VIP. Platos necesarios: ",
		required_plates
	)
func _on_eating_timer_timeout() -> void:
	if state != State.EATING:
		return

	state = State.WAITING_PAYMENT
	_set_group_eating(false)
	print("El cliente ha terminado. Esperando pago")
	eating_finished.emit(self)

func _set_group_eating(value: bool) -> void:
	if not is_instance_valid(seated_customer):
		return
	var group := seated_customer.get_parent()
	if group.has_method("get_customers"):
		for customer in group.get_customers():
			var participating: bool = customer.has_received_food
			if customer is VIPCustomer:
				participating = participating and customer.dishes_eaten < customer.total_dishes_to_eat
			customer.set_eating(value and participating)
	else:
		seated_customer.set_eating(value)

func show_money_popup(amount: float) -> void:
	var popup := Label.new()
	popup.name = "MoneyPopup"
	popup.text = "+%s €" % ("%.1f" % amount).trim_suffix(".0")
	popup.position = Vector2(-90, -95)
	popup.size = Vector2(180, 44)
	popup.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	popup.z_index = 100
	popup.add_theme_font_size_override("font_size", 30)
	popup.add_theme_color_override("font_color", Color("6fff91"))
	popup.add_theme_color_override("font_outline_color", Color("173c25"))
	popup.add_theme_constant_override("outline_size", 6)
	popup.pivot_offset = popup.size / 2
	popup.scale = Vector2.ONE * 0.8
	popup.modulate.a = 0.0
	add_child(popup)
	var animation := popup.create_tween().set_parallel(true)
	animation.tween_property(popup, "position:y", popup.position.y - 65, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	animation.tween_property(popup, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation.tween_property(popup, "modulate:a", 1.0, 0.12)
	animation.tween_property(popup, "modulate:a", 0.0, 0.65).set_delay(0.55)
	animation.chain().tween_callback(popup.queue_free)

func collect_payment() -> bool:
	if state != State.WAITING_PAYMENT:
		return false

	var total_payment: float = payment_amount * (required_plates + served_value_bonus)
	payment_collected.emit(total_payment)
	clear_seated_customer()

	state = State.FREE
	print("Pago recogido: ",total_payment," € (",required_plates," platos)")
	print("La mesa vuelve a estar libre")

	return true


func set_payment_amount(amount: float) -> void:
	payment_amount = amount
	
func get_customer_seat_position(seat_index: int = 0) -> Vector2:
	if seat_index < 0 or seat_index >= customer_seat_points.size():
		push_error("Índice de asiento inválido en la mesa: " + name)
		return global_position

	return customer_seat_points[seat_index].global_position

func get_dish_position(seat_index: int) -> Vector2:
	# Stable target for future dish sprites and hand-to-plate eating animation.
	if seat_index < 0 or seat_index >= customer_seat_points.size():
		return global_position
	return to_global(preload("res://scripts/TableAppearance.gd").dish_position(seat_capacity, customer_seat_points[seat_index].position))
	
func get_seated_customer() -> CharacterBody2D:
	return seated_customer
	
func clear_seated_customer() -> void:
	_set_group_eating(false)
	served_value_bonus = 0.0
	seated_customer = null
	required_plates = 1
	delivered_plates = 0
	occupied_seats = 0
	state = State.FREE
	patience_bar.visible = false
func get_service_position() -> Vector2:
	var clearance: float = preload("res://scripts/RestaurantRoute.gd").CLEARANCE
	return global_position + Vector2(0, maxf(165, get_furniture_bounds().end.y + clearance + 12))
func is_available() -> bool:
	if not unlocked:
		return false

	return visible and state == State.FREE
func can_seat_group(group_size: int) -> bool:
	if not is_available():
		return false

	return seat_capacity >= group_size
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
	) / menu_speed_multiplier

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
