extends Node2D

signal customer_paid(amount: float)

@onready var player_waiter: CharacterBody2D = $PlayerWaiter
@onready var kitchen_point: Area2D = $KitchenPoint
@onready var trash_point: Area2D = $TrashPoint
@onready var tables: Array[Area2D] = []
const BASE_PLATE_PRICE: float = 5.0
var plate_price: float = BASE_PLATE_PRICE
var plate_price_level: int = 0
const PLATE_PRICE_INCREMENT: float = 1.0
const MAX_PLATE_PRICE_LEVEL: int = 10
const MAX_WAITER_SPEED_LEVEL: int = 10
var waiter_speed_level: int = 0
@onready var customer_spawn_point: Marker2D = $CustomerSpawnPoint
@onready var customer_exit_point: Marker2D = $CustomerExitPoint
@onready var customer_spawn_timer: Timer = $CustomerSpawnTimer
@onready var queue_points: Array[Marker2D] = []
var active_customers: Array[CharacterBody2D] = []
var selected_table: Area2D = null
var waiting_queue: Array[Node2D] = []
var customer_scene := preload("res://scenes/customer/Customer.tscn")
var customer_group_scene := preload("res://scenes/customer/CustomerGroup.tscn")

func _ready() -> void:
	for table in get_tree().get_nodes_in_group("restaurant_tables"):
		if table is Area2D:
			tables.append(table)
	for queue_point in $QueuePoints.get_children():
		if queue_point is Marker2D:
			queue_points.append(queue_point)
	get_viewport().physics_object_picking = true

	player_waiter.input_pickable = false

	kitchen_point.input_event.connect(_on_kitchen_point_input_event)
	trash_point.input_event.connect(_on_trash_point_input_event)
	for current_table in tables:
		current_table.input_event.connect(_on_table_input_event.bind(current_table))
	for current_table in tables:
		current_table.payment_collected.connect(_on_table_payment_collected.bind(current_table))
	for current_table in tables:
		current_table.customers_left_without_paying.connect(_on_customers_left_without_paying)
	player_waiter.destination_reached.connect(_on_player_waiter_destination_reached)

	update_stats()
	spawn_customer()
	customer_spawn_timer.timeout.connect(_on_customer_spawn_timer_timeout)
func serve_test_customer() -> void:
	customer_paid.emit(plate_price)
	
func _on_kitchen_point_input_event(_viewport: Viewport,event: InputEvent,_shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("Clic izquierdo en cocina")
		player_waiter.move_to_position(kitchen_point.global_position,player_waiter.TargetType.KITCHEN)

func _on_table_input_event(_viewport: Viewport,event: InputEvent,_shape_idx: int,current_table: Area2D) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:

		print(
	"Click en mesa: ",
	current_table.name,
	" | Posición: ",
	current_table.global_position
)
		selected_table = current_table

		player_waiter.move_to_position(current_table.global_position,player_waiter.TargetType.TABLE)
		
#func _input(event: InputEvent) -> void:
#	if event is InputEventMouseButton:
#		print(
#			"GLOBAL -> botón: ",
#			event.button_index,
#			" pulsado: ",
#			event.pressed,
#			" posición: ",
#			event.position
#		)

	if event is InputEventScreenTouch:
		print(
			"TOUCH -> pulsado: ",
			event.pressed,
			" posición: ",
			event.position
		)
func _on_player_waiter_destination_reached() -> void:
	print(
		"CAMARERO LLEGÓ. Tipo de destino: ",
		player_waiter.target_type
	)

	match player_waiter.target_type:
		player_waiter.TargetType.KITCHEN:
			if player_waiter.carried_dish != DishTypes.Type.NONE:
				print("El camarero ya lleva un plato")
				return

			var dish: DishTypes.Type = kitchen_point.take_ready_dish()

			if dish == DishTypes.Type.NONE:
				print("No hay platos preparados en la cocina")
				return

			player_waiter.carried_dish = dish

			print(
				"El camarero ha recogido: ",
				DishTypes.Type.keys()[player_waiter.carried_dish]
			)

			print(
				"El camarero ha recogido: ",
				DishTypes.Type.keys()[player_waiter.carried_dish]
			)

		player_waiter.TargetType.TABLE:
			if selected_table == null:
				print("No hay ninguna mesa seleccionada")
				return

			print(
				"El camarero llegó a la mesa: ",
				selected_table.name
			)

			if player_waiter.carried_dish != DishTypes.Type.NONE:
				var delivered: bool = selected_table.receive_food(player_waiter.carried_dish)

				if delivered:
					print("El camarero ha entregado ",DishTypes.Type.keys()[player_waiter.carried_dish]," en ",selected_table.name)

					player_waiter.carried_dish = DishTypes.Type.NONE
			else:
				print("El camarero ha llegado sin plato")

			if selected_table.collect_payment():
				print("El camarero ha cobrado la mesa")
		player_waiter.TargetType.TRASH:
			if player_waiter.carried_dish == DishTypes.Type.NONE:
				print("El camarero ha llegado a la papelera sin plato")
				return

			print(
				"Plato tirado: ",
				DishTypes.Type.keys()[player_waiter.carried_dish]
			)

			player_waiter.carried_dish = DishTypes.Type.NONE

func _on_table_payment_collected(amount: float,current_table: Area2D) -> void:
	customer_paid.emit(amount)

	var customer: CharacterBody2D = current_table.get_seated_customer()

	if customer != null:
		var customer_group: Node = customer.get_parent()

		if customer_group.has_method("leave_restaurant"):
			customer_group.leave_restaurant(
				customer_exit_point.global_position
			)
	call_deferred("try_seat_waiting_group")
func _on_customers_left_without_paying(
	current_table: Area2D
) -> void:
	var customer: CharacterBody2D = \
		current_table.get_seated_customer()

	if customer == null:
		return

	var customer_group: Node = customer.get_parent()

	if customer_group.has_method("leave_restaurant"):
		customer_group.leave_restaurant(
			customer_exit_point.global_position
		)

	current_table.clear_seated_customer()
	try_seat_waiting_group()
func _on_customer_destination_reached(customer: CharacterBody2D,customer_table: Area2D) -> void:
	match customer.target_type:
		customer.TargetType.TABLE:
			print(
				"El cliente ha llegado a: ",
				customer_table.name
			)

			var seated: bool = customer_table.seat_customer(customer)

			if seated:
				customer.is_seated = true

			var customer_group: Node = customer.get_parent()

			if customer_group != null \
					and customer_group.has_method("get_customers"):

				kitchen_point.add_orders(customer_group.get_customers())
				
		customer.TargetType.QUEUE:
			print("El grupo ha llegado a la cola")
		customer.TargetType.EXIT:
			print("El cliente ha salido del restaurante")

			active_customers.erase(customer)
			customer.queue_free()
			customer_spawn_timer.start()
func spawn_customer() -> void:
	print("Spawn solicitado")

	var group_size: int = [1, 2, 3, 4].pick_random()
	print("Tamaño de grupo generado: ", group_size)

	var customer_group: Node2D = customer_group_scene.instantiate()
	customer_group.global_position = customer_spawn_point.global_position
	add_child(customer_group)
	customer_group.setup(group_size)

	var available_table: Area2D = get_available_table(group_size)

	if available_table == null:
		if waiting_queue.size() >= queue_points.size():
			print("La cola está llena")
			customer_group.queue_free()
			customer_spawn_timer.start()
			return

		waiting_queue.append(customer_group)

		customer_group.queue_patience_expired.connect(_on_queue_patience_expired)
		customer_group.start_queue_patience()
		
		var queue_index: int = waiting_queue.size() - 1
		customer_group.move_to_queue_position(queue_points[queue_index].global_position)
		print("Grupo añadido a la cola en: ",queue_points[queue_index].name)

		customer_spawn_timer.start()
		return

	var group_customers: Array[CharacterBody2D] = customer_group.get_customers()
	print("Clientes reales creados: ", group_customers.size())

	var customer: CharacterBody2D = customer_group.get_leader()

	
	
	var reserved: bool = available_table.reserve(customer_group)
	if not reserved:
		customer.queue_free()
		customer_spawn_timer.start()
		return
	
	active_customers.append(customer)

	customer.destination_reached.connect(_on_customer_destination_reached.bind(customer,available_table))

	var seat_positions: Array[Vector2] = available_table.get_group_seat_positions(group_size)

	customer_group.move_customers_to_seats(seat_positions)

	print("Nuevo cliente creado para: ", available_table.name)
	customer_spawn_timer.start()
func _on_customer_spawn_timer_timeout() -> void:
	spawn_customer()
func upgrade_waiter_speed() -> void:
	if waiter_speed_level >= MAX_WAITER_SPEED_LEVEL:
		return

	waiter_speed_level += 1

	update_waiter_speed()

	print("Nivel velocidad: ", waiter_speed_level)
	print("Velocidad del camarero: ", player_waiter.speed)
	
func update_waiter_speed() -> void:
	player_waiter.set_speed_upgrade_level(waiter_speed_level)
func upgrade_plate_price() -> void:
	if plate_price_level >= MAX_PLATE_PRICE_LEVEL:
		return

	plate_price_level += 1
	update_plate_price()
	print("Nivel precio del plato: ", plate_price_level)
	print("Precio actual del plato: ", plate_price)
func update_plate_price() -> void:
	plate_price = BASE_PLATE_PRICE + PLATE_PRICE_INCREMENT * plate_price_level

	for current_table in tables:
		current_table.set_payment_amount(plate_price)
	
func get_plate_price() -> float:
	return plate_price
	
# Actualiza todas las estadísticas derivadas de las mejoras actuales.
func update_stats() -> void:
	update_waiter_speed()
	update_plate_price()
func get_available_table(group_size: int = 1) -> Area2D:
	var valid_tables: Array[Area2D] = []

	for current_table in tables:
		if current_table.can_seat_group(group_size):
			valid_tables.append(current_table)

	if valid_tables.is_empty():
		return null

	return valid_tables.pick_random()

func try_seat_waiting_group() -> void:
	if waiting_queue.is_empty():
		return

	for i in range(waiting_queue.size()):
		var customer_group: Node2D = waiting_queue[i]
		var group_size: int = customer_group.get_group_size()
		var available_table: Area2D = get_available_table(group_size)

		if available_table == null:
			continue

		waiting_queue.remove_at(i)
		customer_group.stop_queue_patience()
		update_waiting_queue_positions()

		var customer: CharacterBody2D = customer_group.get_leader()
		var reserved: bool = available_table.reserve(customer_group)

		if not reserved:
			waiting_queue.insert(i, customer_group)
			update_waiting_queue_positions()
			return

		active_customers.append(customer)

		customer.destination_reached.connect(
			_on_customer_destination_reached.bind(
				customer,
				available_table
			)
		)

		var seat_positions: Array[Vector2] = \
			available_table.get_group_seat_positions(group_size)

		customer_group.move_customers_to_seats(seat_positions)

		print(
			"Un grupo compatible de la cola entra en: ",
			available_table.name
		)

		return

func update_waiting_queue_positions() -> void:
	for i in range(waiting_queue.size()):
		var customer_group: Node2D = waiting_queue[i]

		customer_group.move_to_queue_position(
			queue_points[i].global_position
		)
func _on_queue_patience_expired(customer_group: Node2D) -> void:
	if not waiting_queue.has(customer_group):
		return
	customer_group.stop_queue_patience()

	waiting_queue.erase(customer_group)
	update_waiting_queue_positions()

	customer_group.leave_restaurant(
		customer_exit_point.global_position
	)

	print("Un grupo se ha cansado de esperar y se marcha")
func unlock_next_table() -> bool:
	var tables := get_tree().get_nodes_in_group("restaurant_tables")

	for table in tables:
		if not table.unlocked:
			table.unlock()
			print("Mesa comprada: ", table.name)
			return true

	print("No quedan mesas bloqueadas")
	return false
func has_locked_tables() -> bool:
	var tables := get_tree().get_nodes_in_group("restaurant_tables")

	for table in tables:
		if not table.unlocked:
			return true

	return false
func _on_trash_point_input_event(
	_viewport: Viewport,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton \
			and event.button_index == MOUSE_BUTTON_LEFT \
			and event.pressed:

		if player_waiter.carried_dish == DishTypes.Type.NONE:
			print("El camarero no lleva ningún plato")
			return

		player_waiter.move_to_position(
			trash_point.global_position,
			player_waiter.TargetType.TRASH
		)
func set_counter_capacity_bonus(bonus: int) -> void:
	kitchen_point.set_counter_capacity_bonus(bonus)
