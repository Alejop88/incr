extends Node2D

signal customer_paid(amount: float)
signal kitchen_panel_requested
signal vip_completed(amount: int)
@onready var player_waiter: CharacterBody2D = $PlayerWaiter
@onready var waiter_manager: Node = $WaiterManager
@onready var kitchen_point: Area2D = $KitchenPoint
@onready var trash_point: Area2D = $TrashPoint
@onready var tables: Array[Area2D] = []
const BASE_PLATE_PRICE: float = 5.0
var plate_price: float = BASE_PLATE_PRICE
var plate_price_level: int = 0
const BASE_VIP_SPAWN_CHANCE: float = 0.05
const VIP_SPAWN_CHANCE_PER_BONUS_LEVEL: float = 0.01
const MAX_VIP_SPAWN_CHANCE: float = 0.25
var max_vip_group_size: int = 1
var vip_spawn_bonus_level: int = 0
var vip_spawn_chance: float = 0.0
var vip_unlocked: bool = false

func set_vip_unlocked(value: bool) -> void:
	vip_unlocked = value
	update_vip_spawn_chance()
const PLATE_PRICE_INCREMENT: float = 1.0
const MAX_PLATE_PRICE_LEVEL: int = 10
const MAX_WAITER_SPEED_LEVEL: int = 10
const MAX_COOK_SPEED_LEVEL: int = 10
var cook_speed_level: int = 0
const MAX_EATING_SPEED_LEVEL: int = 10
var eating_speed_level: int = 0
const MAX_PATIENCE_LEVEL: int = 10
var patience_level: int = 0
var permanent_cook_speed_bonus: int = 0
var waiter_speed_level: int = 0

@onready var customer_spawn_point: Marker2D = $CustomerSpawnPoint
@onready var customer_exit_point: Marker2D = $CustomerExitPoint
@onready var customer_spawn_timer: Timer = $CustomerSpawnTimer
@onready var queue_points: Array[Marker2D] = []
var active_customers: Array[CharacterBody2D] = []
var selected_table: Area2D = null
var menu_dishes: Array[DishTypes.Type] = DishTypes.default_menu()
var menu_capacity: int = DishTypes.MAX_MENU_DISHES
const BASE_SPAWN_INTERVAL: float = 20.0

func set_menu_capacity_bonus(bonus: int) -> void:
	menu_capacity = DishTypes.MAX_MENU_DISHES + maxi(0, bonus)
	customer_spawn_timer.wait_time = BASE_SPAWN_INTERVAL / (1.0 + 0.25 * maxi(0, bonus))
var unlocked_dishes: Array[DishTypes.Type] = DishTypes.default_menu()

func start_random_menu() -> void:
	unlocked_dishes = DishTypes.random_starting_dishes()
	menu_dishes = unlocked_dishes.duplicate()

func get_locked_dishes() -> Array[DishTypes.Type]:
	var result: Array[DishTypes.Type] = []
	for dish in DishTypes.CATALOG:
		if not unlocked_dishes.has(dish):
			result.append(dish)
	return result

func restore_dish_progress(data: Dictionary) -> void:
	var saved_menu: Array[DishTypes.Type] = DishTypes.menu_from_keys(data.get("menu_dishes", []), menu_capacity)
	# Old saves retain their selected recipes; new saves restore the full collection.
	unlocked_dishes = DishTypes.unlocked_from_keys(data.get("unlocked_dishes", DishTypes.menu_keys(saved_menu)))
	if unlocked_dishes.is_empty():
		unlocked_dishes = DishTypes.random_starting_dishes()
	if not data.has("unlocked_dishes"):
		var pool: Array[DishTypes.Type] = get_locked_dishes()
		pool.shuffle()
		while unlocked_dishes.size() < 2 and not pool.is_empty():
			unlocked_dishes.append(pool.pop_back())
	var valid_menu: Array[DishTypes.Type] = []
	for dish in saved_menu:
		if unlocked_dishes.has(dish):
			valid_menu.append(dish)
	menu_dishes = valid_menu if not valid_menu.is_empty() else unlocked_dishes.slice(0, menu_capacity)

func set_menu_dishes(dishes: Array) -> bool:
	if dishes.is_empty() or dishes.size() > menu_capacity:
		return false
	var validated: Array[DishTypes.Type] = []
	for dish in dishes:
		if not unlocked_dishes.has(dish) or validated.has(dish):
			return false
		validated.append(dish)
	menu_dishes = validated
	return true
var waiting_queue: Array[Node2D] = []
var customer_scene := preload("res://scenes/customer/Customer.tscn")
var customer_group_scene := preload("res://scenes/customer/CustomerGroup.tscn")
var selected_ready_dish_ids: Array[int] = []
var manual_pickup: bool = false

func _ready() -> void:
	set_menu_capacity_bonus(0)
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
	for current_table in tables:
		current_table.eating_finished.connect(_on_table_eating_finished)
	player_waiter.destination_reached.connect(_on_player_waiter_destination_reached)

	update_stats()
	customer_spawn_timer.timeout.connect(_on_customer_spawn_timer_timeout)
func serve_test_customer() -> void:
	customer_paid.emit(plate_price)
	
func _on_kitchen_point_input_event(_viewport: Viewport,event: InputEvent,_shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed:
		if get_node("/root/GameSettings").matches(event, "interact"):
			_clear_pickup_selection()
			if player_waiter.get_free_carry_slots() == 0:
				return

			player_waiter.move_to_position(
				kitchen_point.global_position,
				player_waiter.TargetType.KITCHEN
			)
		elif get_node("/root/GameSettings").matches(event, "camera"):
			kitchen_panel_requested.emit()
			
func _on_table_input_event(_viewport: Viewport,event: InputEvent,_shape_idx: int,current_table: Area2D) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and get_node("/root/GameSettings").matches(event, "interact"):

		print(
	"Click en mesa: ",
	current_table.name,
	" | Posición: ",
	current_table.global_position
)
		_clear_pickup_selection()
		selected_table = current_table

		player_waiter.move_to_position(current_table.get_service_position(),player_waiter.TargetType.TABLE)
		
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
func _on_table_eating_finished(current_table: Area2D) -> void:
	var customer: CharacterBody2D = \
		current_table.get_seated_customer()

	if customer == null:
		return

	if not customer is VIPCustomer:
		print(
			"Cliente normal ha terminado de comer en: ",
			current_table.name
		)
		return

	var customer_group: Node = customer.get_parent()

	if customer_group == null \
			or not customer_group.has_method("get_customers"):
		return

	var group_customers: Array = \
		customer_group.get_customers()

	print(
		"VIPs encontrados en el grupo: ",
		group_customers.size()
	)

	# Primero contamos la ronda que acaba de terminar.
	for group_customer in group_customers:
		if not group_customer is VIPCustomer:
			continue

		var group_vip := group_customer as VIPCustomer

		# Solo contamos el plato si este VIP todavía
		# no había completado todos los suyos.
		if group_vip.dishes_eaten \
				< group_vip.total_dishes_to_eat:

			group_vip.dishes_eaten += 1

			print(
				"VIP ha comido ",
				group_vip.dishes_eaten,
				"/",
				group_vip.total_dishes_to_eat,
				" platos"
			)

	# Ahora preparamos la siguiente ronda solamente
	# para los VIP que todavía no han terminado.
	var vip_still_eating: Array[VIPCustomer] = []

	for group_customer in group_customers:
		if not group_customer is VIPCustomer:
			continue

		var group_vip := group_customer as VIPCustomer

		if group_vip.dishes_eaten \
				< group_vip.total_dishes_to_eat:

			vip_still_eating.append(group_vip)

	# Si ninguno necesita más platos,
	# la mesa permanece en WAITING_PAYMENT.
	if vip_still_eating.is_empty():
		print("Todos los VIP han terminado su visita")
		return

	# Cada VIP que continúa elige su siguiente plato.
	for vip in vip_still_eating:
		var next_dish: DishTypes.Type = \
			vip.prepare_next_dish(menu_dishes)

		kitchen_point.add_order(next_dish)

		print(
			"VIP pide su siguiente plato: ",
			DishTypes.Type.keys()[next_dish]
		)

	# Reiniciamos la mesa para la siguiente ronda.
	current_table.start_next_food_round(
		customer,
		vip_still_eating.size()
	)
func _on_player_waiter_destination_reached() -> void:
	match player_waiter.target_type:
		player_waiter.TargetType.KITCHEN:
			if manual_pickup:
				for dish_id in selected_ready_dish_ids:
					if player_waiter.get_free_carry_slots() == 0:
						break
					player_waiter.add_carried_dish(kitchen_point.take_ready_dish_by_id(dish_id))
			else:
				for i in range(player_waiter.get_free_carry_slots()):
					player_waiter.add_carried_dish(kitchen_point.take_ready_dish())
			_clear_pickup_selection()
		player_waiter.TargetType.TABLE:
			if not is_instance_valid(selected_table):
				return
			for dish in player_waiter.carried_dishes.duplicate():
				if selected_table.receive_food(dish):
					player_waiter.remove_carried_dish(dish)
			selected_table.collect_payment()
		player_waiter.TargetType.TRASH:
			player_waiter.clear_carried_dishes()
func _on_table_payment_collected(
	amount: float,
	current_table: Area2D
) -> void:
	var customer: CharacterBody2D = \
		current_table.get_seated_customer()

	if customer == null:
		return

	var customer_group: Node = customer.get_parent()

	if customer is VIPCustomer:
		var vip_count: int = 1

		if customer_group != null \
				and customer_group.has_method("get_customers"):

			vip_count = 0

			for group_customer in customer_group.get_customers():
				if group_customer is VIPCustomer:
					vip_count += 1

		vip_completed.emit(vip_count)

		print(
			"Grupo VIP completado: +",
			vip_count,
			" estrellas Michelin"
		)
	else:
		customer_paid.emit(amount)

	if customer_group != null \
			and customer_group.has_method("leave_restaurant"):

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

	var is_vip: bool = vip_unlocked and randf() < vip_spawn_chance
	var group_size: int

	if is_vip:
		group_size = randi_range(1, max_vip_group_size)
	else:
		group_size = [1, 2, 3, 4].pick_random()
	print("Tamaño de grupo generado: ", group_size)

	var customer_group: Node2D = customer_group_scene.instantiate()
	customer_group.global_position = customer_spawn_point.global_position
	add_child(customer_group)
	customer_group.is_vip_group = is_vip
	customer_group.available_dishes = menu_dishes.duplicate()
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
func upgrade_cook_speed() -> void:
	if cook_speed_level >= MAX_COOK_SPEED_LEVEL:
		return

	cook_speed_level += 1
	update_cook_speed()

	print("Nivel velocidad cocina: ", cook_speed_level)
func update_cook_speed() -> void:
	var total_level: int = \
		cook_speed_level + permanent_cook_speed_bonus

	kitchen_point.set_cook_speed_level(total_level)
func upgrade_eating_speed() -> void:
	if eating_speed_level >= MAX_EATING_SPEED_LEVEL:
		return

	eating_speed_level += 1
	update_eating_speed()

	print("Nivel velocidad al comer: ", eating_speed_level)


func update_eating_speed() -> void:
	for table in get_tree().get_nodes_in_group("restaurant_tables"):
		if table.has_method("set_eating_speed_level"):
			table.set_eating_speed_level(eating_speed_level)
func upgrade_patience() -> void:
	if patience_level >= MAX_PATIENCE_LEVEL:
		return

	patience_level += 1
	update_patience()

	print("Nivel paciencia clientes: ", patience_level)


func update_patience() -> void:
	for table in get_tree().get_nodes_in_group("restaurant_tables"):
		if table.has_method("set_patience_level"):
			table.set_patience_level(patience_level)
func update_vip_spawn_chance() -> void:
	if not vip_unlocked:
		vip_spawn_chance = 0.0
		return
	vip_spawn_chance = min(
		MAX_VIP_SPAWN_CHANCE,
		BASE_VIP_SPAWN_CHANCE
			+ VIP_SPAWN_CHANCE_PER_BONUS_LEVEL
			* vip_spawn_bonus_level
	)
func set_vip_spawn_bonus_level(level: int) -> void:
	vip_spawn_bonus_level = max(level, 0)
	update_vip_spawn_chance()
func set_permanent_cook_speed_bonus(bonus: int) -> void:
	permanent_cook_speed_bonus = bonus
	update_cook_speed()
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
	update_cook_speed()
	update_eating_speed()
	update_patience()
	update_vip_spawn_chance()
func get_available_table(group_size: int = 1) -> Area2D:
	var valid_tables: Array[Area2D] = []
	var smallest_capacity: int = 2147483647

	for current_table in tables:
		if current_table.can_seat_group(group_size):
			if current_table.seat_capacity < smallest_capacity:
				smallest_capacity = current_table.seat_capacity
				valid_tables.clear()
			if current_table.seat_capacity == smallest_capacity:
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

	for table in tables:
		if not table.unlocked:
			table.unlock()
			print("Mesa comprada: ", table.name)
			try_seat_waiting_group()
			return true

	print("No quedan mesas bloqueadas")
	return false
func has_locked_tables() -> bool:

	for table in tables:
		if not table.unlocked:
			return true

	return false
func get_next_table_description() -> String:
	for table in tables:
		if not table.unlocked:
			return "Mesa %s · %d personas" % [str(table.name).trim_prefix("Table").trim_suffix("Point"), table.seat_capacity]
	return ""
func _on_trash_point_input_event(
	_viewport: Viewport,
	event: InputEvent,
	_shape_idx: int
) -> void:
	if event is InputEventMouseButton \
			and get_node("/root/GameSettings").matches(event, "interact") \
			and event.pressed:

		if player_waiter.carried_dishes.is_empty():
			print("El camarero no lleva ningún plato")
			return

		_clear_pickup_selection()
		player_waiter.move_to_position(
			trash_point.global_position,
			player_waiter.TargetType.TRASH
		)
func set_counter_capacity_bonus(bonus: int) -> void:
	kitchen_point.set_counter_capacity_bonus(bonus)
func get_ready_dishes_count() -> int:
	return kitchen_point.get_ready_dishes_count()

func get_counter_capacity() -> int:
	return kitchen_point.get_counter_capacity()
	
func get_ready_dishes() -> Array:
	return kitchen_point.get_ready_dishes()
func get_cooking_progress() -> float:
	return kitchen_point.get_cooking_progress()
func get_current_dish_name() -> String:
	return kitchen_point.get_current_dish_name()
func get_order_queue() -> Array:
	return kitchen_point.get_order_queue()
func get_available_manual_dishes() -> Array:
	# Keep outstanding old orders available after changing the menu.
	var dishes: Array = menu_dishes.duplicate()
	for child in get_children():
		if child.has_method("get_customers"):
			for customer in child.get_customers():
				if not customer.has_received_food and customer.target_type != customer.TargetType.EXIT and not dishes.has(customer.requested_dish):
					dishes.append(customer.requested_dish)
	return dishes
func add_manual_kitchen_order(dish: DishTypes.Type) -> void:
	if get_available_manual_dishes().has(dish):
		kitchen_point.add_manual_order(dish)
func move_kitchen_order_up(index: int) -> void:
	kitchen_point.move_order_up(index)
func move_kitchen_order_down(index: int) -> void:
	kitchen_point.move_order_down(index)
func cancel_kitchen_order(index: int) -> void:
	kitchen_point.cancel_order(index)
func _clear_pickup_selection() -> void:
	selected_ready_dish_ids.clear()
	manual_pickup = false

func get_selected_ready_dish_ids() -> Array[int]:
	var available: Array[int] = kitchen_point.get_ready_dish_ids()
	for dish_id in selected_ready_dish_ids.duplicate():
		if not available.has(dish_id):
			selected_ready_dish_ids.erase(dish_id)
	return selected_ready_dish_ids.duplicate()

func request_specific_ready_dish(dish_id: int) -> void:
	get_selected_ready_dish_ids()
	if selected_ready_dish_ids.has(dish_id):
		selected_ready_dish_ids.erase(dish_id)
		if selected_ready_dish_ids.is_empty():
			player_waiter.has_target = false
			player_waiter.velocity = Vector2.ZERO
			player_waiter.target_type = player_waiter.TargetType.NONE
			manual_pickup = false
		return
	if not kitchen_point.get_ready_dish_ids().has(dish_id):
		return
	if selected_ready_dish_ids.size() >= player_waiter.get_free_carry_slots():
		return
	manual_pickup = true
	selected_ready_dish_ids.append(dish_id)
	player_waiter.move_to_position(kitchen_point.global_position, player_waiter.TargetType.KITCHEN)
func get_ready_dish_ids() -> Array[int]:
	return kitchen_point.get_ready_dish_ids()
func set_max_vip_group_size(value: int) -> void:
	max_vip_group_size = clamp(value, 1, 4)

	print(
		"Tamaño máximo de grupo VIP: ",
		max_vip_group_size
	)
