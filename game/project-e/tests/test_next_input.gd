extends SceneTree
## Real scene regressions: attack-move routing, click priority and first-play help.

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set_physics_process(false)
	scene.start_match("rio", true)
	scene.battle.bots_enabled = false
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-4, 0)
	scene._camera_follow = false
	scene._camera_focus = Vector2.ZERO
	scene.camera.size = 30.0
	scene._update_camera(0)
	var ground := Vector2(4, 0)
	var click: Vector2 = scene.camera.unproject_position(Vector3(ground.x, 0, -ground.y))
	var energy: float = hero.energy
	_check(scene.handle_hotkey(KEY_A), "A enters attack-move aiming")
	_check(scene.get("attack_move_aim") == true, "Attack-move cursor state is armed")
	_check(hero.order == "idle" and is_equal_approx(hero.energy, energy), "Arming alone leaves the real order and resources intact")
	_check(scene.world_click(click, MOUSE_BUTTON_LEFT), "Ground confirmation is accepted")
	_check(hero.order == "attack_move", "A then ground click sends the new authority order")
	_check(scene.get("attack_move_aim") != true, "Accepted attack-move exits aiming")
	scene.handle_hotkey(KEY_A)
	scene.handle_hotkey(KEY_ESCAPE)
	_check(not scene.paused and scene.get("attack_move_aim") != true, "Escape cancels attack aim before pausing")
	scene._resume()
	_check(hero.order == "attack_move", "Cancelling a new aim preserves the previous real attack-move order")
	scene.handle_hotkey(KEY_S)
	_check(hero.order == "idle", "S stops the real attack-move order")
	scene.handle_hotkey(KEY_A)
	var blocked: Vector2 = scene.get_growth_button_rect().get_center()
	_check(not scene.world_click(blocked, MOUSE_BUTTON_LEFT), "HUD confirmation cannot issue attack-move")
	_check(scene.get("attack_move_aim") == true and hero.order == "idle", "A blocked confirmation preserves aim without ordering the hero")
	_check(scene.arm_ability("Q"), "Ready skill can replace attack-move aiming")
	_check(scene.aim_slot == "Q" and scene.get("attack_move_aim") != true, "Only one aim mode remains active")
	scene.handle_hotkey(KEY_A)
	_check(scene.aim_slot == "" and scene.get("attack_move_aim") == true, "A can replace a skill preview without casting it")
	_check(is_equal_approx(hero.energy, energy) and is_zero_approx(hero.cooldowns.Q), "Aim switching never spends skill resources")
	_check(scene.world_click(click, MOUSE_BUTTON_RIGHT), "Right click replaces attack aim with ordinary movement")
	_check(hero.order == "move" and scene.get("attack_move_aim") != true, "Right-click ground remains an ordinary move order")
	scene.handle_hotkey(KEY_A)
	scene.open_growth()
	_check(scene.get("attack_move_aim") != true and not scene.handle_hotkey(KEY_A), "Growth clears aiming and prevents new A commands")
	scene.close_growth()
	hero.alive = false
	_check(not scene.handle_hotkey(KEY_A), "A cannot arm a defeated hero")
	hero.alive = true
	scene.handle_hotkey(KEY_A)
	scene.restart_match()
	_check(scene.get("attack_move_aim") != true and scene.battle.units[scene.battle.controlled_id].order == "idle", "Restart clears cursor and old movement order")
	scene.battle.winner = 1
	_check(not scene.handle_hotkey(KEY_A), "A is blocked after the match ends")
	scene.start_match("bas", true)
	scene.battle.bots_enabled = false
	scene._camera_follow = false
	scene._camera_focus = Vector2.ZERO
	scene.camera.size = 30.0
	scene._update_camera(0)
	hero = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-4, 0)
	scene.battle._spawn_wave()
	var enemy: Dictionary = _unit(scene.battle, "hero", 1)
	var minion: Dictionary = _unit(scene.battle, "minion", 1)
	var tower: Dictionary = _unit(scene.battle, "tower", 1)
	enemy.pos = Vector2(0.2, 0)
	minion.pos = Vector2.ZERO
	tower.pos = Vector2.ZERO
	tower.locked = true
	scene.battle._visibility_cache.clear()
	click = scene.camera.unproject_position(Vector3(0, 0.25, 0))
	_check(scene.pick_visible_target(click) == enemy.id, "Overlapped hero wins over a closer minion and a locked tower")
	enemy.alive = false
	_check(scene.pick_visible_target(click) == minion.id, "With hero gone a locked tower does not intercept a minion click")
	minion.alive = false
	_check(scene.pick_visible_target(click) == -1, "Locked structure alone is excluded from attack selection")
	tower.locked = false
	_check(scene.pick_visible_target(click) == tower.id, "Unlocked visible structure becomes attackable")
	tower.pos = Vector2(40, 0)
	scene.battle._visibility_cache.clear()
	click = scene.camera.unproject_position(Vector3(40, 0.25, 0))
	_check(scene.pick_visible_target(click) == -1, "Public structure location does not allow an unseen attack selection")
	_check(scene.has_method("open_help"), "First-play guide can be opened from the scene")
	if scene.has_method("open_help"):
		scene.open_help()
		_check(scene.help_visible() and scene.paused, "Local guide pauses the game while reading")
		_check(not scene.handle_hotkey(KEY_A), "Guide consumes gameplay hotkeys")
		_check(not scene.world_click(Vector2(640, 300), MOUSE_BUTTON_RIGHT), "Guide background prevents world commands")
		scene.handle_hotkey(KEY_ESCAPE)
		_check(not scene.help_visible() and not scene.paused, "Escape closes guide and restores prior running state")
		scene.handle_hotkey(KEY_ESCAPE)
		scene.open_help()
		scene.handle_hotkey(KEY_ESCAPE)
		_check(scene.paused and scene.hud.pause_menu.visible, "Closing guide opened from pause preserves pause")
	scene.queue_free()
	await process_frame
	print("Next input: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _unit(state: Variant, kind: String, team: int) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.kind == kind and unit.team == team:
			return unit
	return {}


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
