extends SceneTree

var failures: int = 0
var fixture_path: String = "res://tests/vip-unlock-%s.tscn" % Time.get_ticks_usec()
var save_path: String = fixture_path + ".json"

func _initialize() -> void:
	call_deferred("run_tests")

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func run_tests() -> void:
	var fixture: FileAccess = FileAccess.open(fixture_path, FileAccess.WRITE)
	fixture.store_string('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://scenes/Main.tscn" id="1"]\n[node name="Main" instance=ExtResource("1")]\n[node name="SaveManager" parent="." index="0"]\nsave_path = "%s"\n' % save_path)
	fixture.close()
	var game: Node = load(fixture_path).instantiate()
	root.add_child(game)
	current_scene = game
	check(not game.restaurant.vip_unlocked and game.restaurant.vip_spawn_chance == 0.0, "Fresh run must not spawn VIPs")
	game.restaurant.vip_spawn_chance = 1.0
	game.restaurant.spawn_customer()
	var group: Node = game.restaurant.get_child(game.restaurant.get_child_count() - 1)
	check(not group.is_vip_group, "VIP gate must block spawning regardless of chance")
	game.restaurant.set_vip_spawn_bonus_level(2)
	check(game.restaurant.vip_spawn_chance == 0.0, "Chance bonuses cannot unlock VIPs")
	game._on_vip_unlock_requested()
	check(not game.vip_run_unlocked, "Unaffordable unlock must fail")
	game.economy_manager.money = 150
	game.hud.get_node("UpgradesPanel/VBoxContainer/VipUnlockButton").pressed.emit()
	check(game.vip_run_unlocked and is_equal_approx(game.restaurant.vip_spawn_chance, 0.07), "Money unlock enables VIPs with existing chance bonuses")
	game._on_vip_unlock_requested()
	check(game.economy_manager.money == 50, "Unlock must charge only once")
	game._on_save_requested()
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	check(game.vip_run_unlocked and game.restaurant.vip_unlocked, "Money unlock survives normal save and reload")
	game.michelin_manager.stars = 10
	game.michelin_manager.toggle_selection("player_capacity_2")
	game._on_star_purchase_confirmed()
	await process_frame
	await process_frame
	game = current_scene
	check(not game.vip_run_unlocked and not game.restaurant.vip_unlocked, "Prestige resets the money unlock")
	game._on_star_upgrades_requested()
	game.michelin_upgrades.upgrade_buttons["permanent_vip"].pressed.emit()
	check(not game.restaurant.vip_unlocked, "Selecting permanent VIP must not apply before purchase")
	game.michelin_upgrades.purchase_button.pressed.emit()
	game.michelin_upgrades.confirm_button.pressed.emit()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.vip_unlocked and is_equal_approx(game.restaurant.vip_spawn_chance, 0.05), "Permanent upgrade enables VIPs from the restarted run")
	check(not game.hud.get_node("UpgradesPanel/VBoxContainer/VipUnlockButton").visible, "Permanent ownership hides the money upgrade")
	game.economy_manager.money = 200
	game._on_vip_unlock_requested()
	check(game.economy_manager.money == 200, "Hidden money upgrade cannot charge permanent owners")
	reload_current_scene()
	await process_frame
	await process_frame
	game = current_scene
	check(game.restaurant.vip_unlocked, "Permanent unlock survives reload")
	game._on_new_game_requested()
	await process_frame
	await process_frame
	game = current_scene
	check(not game.restaurant.vip_unlocked and game.hud.get_node("UpgradesPanel/VBoxContainer/VipUnlockButton").visible, "Explicit new game resets VIP unlock and restores money button")
	game.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(fixture_path))
	print("VIP UNLOCK TESTS: ", "PASS" if failures == 0 else "FAIL", " (", failures, " failures)")
	quit(0 if failures == 0 else 1)
