extends SceneTree
## Real loaded scene tests, button signals and the same key-event entrypoint used in play.
var _checks: int = 0
var _failures: int = 0
var scene: Variant

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set_physics_process(false)
	var ready: bool = true
	for method: String in ["open_shop", "close_shop", "shop_visible", "buy_consumable", "select_consumable", "use_consumable"]:
		var exists: bool = scene.has_method(method)
		_check(exists, "scene exposes " + method)
		ready = ready and exists
	for signal_name: String in ["shop_requested", "shop_closed", "consumable_purchase_requested", "consumable_selected", "consumable_use_requested"]:
		var exists: bool = scene.hud.has_signal(signal_name)
		_check(exists, "HUD emits " + signal_name)
		ready = ready and exists
	if ready:
		await _behavior()
	scene.queue_free()
	await process_frame
	print("Consumable input: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)

func _fresh() -> Dictionary:
	scene.start_match("bas", true)
	scene.battle.bots_enabled = false
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-56, 0)
	hero.credits = 300
	return hero

func _key(code: int, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	scene._input(event)

func _refresh() -> void:
	scene.hud.update_state(scene.battle, scene.aim_slot, scene.is_practice, scene.attack_move_aim)

func _behavior() -> void:
	var hero: Dictionary = _fresh()
	scene._camera_drag = true
	_key(KEY_P)
	_check(scene.shop_visible() and scene.paused, "P opens and pauses the real shop")
	_check(not scene._camera_drag, "shop opening clears camera drag")
	var stopped_time: float = scene.battle.time
	scene._physics_process(1.0)
	_check(scene.battle.time == stopped_time, "shop pauses authority ticking")
	_check(not scene.hud._shop_buy_buttons.I01.disabled, "home-base purchase enabled")
	scene.hud._shop_buy_buttons.I01.pressed.emit()
	_check(hero.consumables.I01 == 1 and hero.credits == 260, "buy button reaches authority once")
	_check(scene.hud._shop_feedback.text.contains("구매"), "purchase feedback is Korean inside modal")
	scene.hud._shop_buy_buttons.I02.pressed.emit()
	_check(hero.consumables.I02 == 1 and hero.credits == 210, "second card buys a different item")
	_check(scene.hud._shop_buy_buttons.I01.disabled and scene.hud._shop_buy_buttons.I02.disabled, "combined capacity disables both cards")
	scene.hud._shop_buy_buttons.I01.pressed.emit()
	_check(hero.consumables.I01 == 1 and hero.credits == 210, "forged repeated button signal rechecks full authority")
	_check(scene.hud._shop_feedback.text.contains("2개"), "full-stock reason is Korean")
	for code: int in [KEY_A, KEY_Q, KEY_W, KEY_E, KEY_R, KEY_B, KEY_S, KEY_D, KEY_SPACE, KEY_G, KEY_F1]:
		_key(code)
		_check(scene.shop_visible() and hero.order == "idle" and hero.consumables.I01 == 1, "shop blocks gameplay/modal key %d" % code)
	for point: Vector2 in [Vector2(1, 300), Vector2(640, 360), Vector2(1100, 600)]:
		_check(scene.ui_blocks_point(point), "modal blocks full viewport " + str(point))
		_check(not scene.world_click(point, MOUSE_BUTTON_LEFT) and not scene.world_click(point, MOUSE_BUTTON_RIGHT), "modal stops world click " + str(point))
	var focus: Vector2 = scene._camera_focus
	scene._on_minimap_point(Vector2(9, 9), MOUSE_BUTTON_LEFT)
	scene._on_minimap_point(Vector2(9, 9), MOUSE_BUTTON_RIGHT)
	_check(scene._camera_focus == focus and hero.order == "idle", "shop blocks minimap camera and movement")
	scene.hud._shop_close.pressed.emit()
	_check(not scene.shop_visible() and not scene.paused, "close button restores running state")
	scene.hud._item_buttons.I02.pressed.emit()
	_check(hero.consumable_selected == "I02" and hero.consumables.I02 == 1, "inventory click selects without using")
	_check(scene.arm_ability("Q"), "Q aim is available before selection/use")
	_check(scene.battle.command_move(hero.id, Vector2(-54, 3)), "real move order accepted before D")
	var before: Dictionary = {"order": hero.order, "goal": hero.goal, "path": hero.path.duplicate(), "cast": hero.cast.duplicate(), "queued": hero.queued.duplicate()}
	hero.hp -= 300
	_key(KEY_D)
	_check(hero.consumables.I02 == 0 and hero.consumable_cooldown == 12.0 and not hero.consumable_effect.is_empty(), "D consumes selected patch once")
	_check(scene.aim_slot == "Q", "D preserves skill aim")
	for field: String in before:
		_check(hero[field] == before[field], "D preserves " + field)
	_key(KEY_D)
	_check(hero.consumables.I01 == 1 and hero.consumables.I02 == 0, "repeated D cannot consume another item")
	_check(hero.consumable_selected == "I02", "empty selected kind is preserved")
	scene.hud._item_buttons.I01.pressed.emit()
	_check(scene.aim_slot == "Q" and hero.consumable_selected == "I01" and hero.consumables.I01 == 1, "slot selection preserves Q aim")
	_refresh()
	_check(scene.hud._inventory_status.text.contains("12.0") and scene.hud._inventory_status.text.contains("수리 패치"), "strip shows shared cooldown and active recovery")
	_key(KEY_P)
	_check(scene.aim_slot == "" and not scene.attack_move_aim and hero.order == "move", "opening shop clears aim and preserves accepted order")
	_key(KEY_ESCAPE)
	_check(not scene.shop_visible() and scene.aim_slot == "" and not scene.paused, "Esc closes shop without rearming or ordering")
	scene._clear_aim()
	scene.arm_attack_move()
	_key(KEY_P)
	_key(KEY_P)
	_check(not scene.attack_move_aim and not scene.shop_visible() and hero.order == "move", "P toggle clears attack aim and preserves order")
	scene.arm_attack_move()
	scene.hud._item_buttons.I02.pressed.emit()
	_check(scene.attack_move_aim and hero.consumable_selected == "I02", "empty selection preserves attack aim")
	scene._clear_aim()
	scene.battle.step(4.1)
	_refresh()
	_check(scene.hud._toast_text.text.contains("회복 완료"), "actual effect completion event has Korean feedback")
	var completed: String = scene.hud._toast_text.text
	scene.hud.show_message("sentinel")
	_refresh()
	_check(scene.hud._toast_text.text == "sentinel", "event cursor does not replay old completion")
	# A real accepted cast plus a queued move must survive D verbatim.
	hero = _fresh()
	hero.pos = Vector2(-4, 0)
	hero.consumables.I01 = 1
	hero.energy -= 60
	_check(scene.battle.command_cast(hero.id, "Q", Vector2.ZERO), "real cast enters windup before consumable use")
	_check(scene.battle.command_move(hero.id, Vector2(-2, 0)), "real move is queued during cast")
	_check(not hero.cast.is_empty() and not hero.queued.is_empty(), "preservation fixture has actual nonempty action and queue")
	var action: Dictionary = hero.cast.duplicate(true)
	var queued: Dictionary = hero.queued.duplicate(true)
	var phase: String = hero.phase
	var phase_left: float = hero.phase_left
	scene.arm_ability("W")
	_key(KEY_D)
	_check(hero.cast == action and hero.queued == queued and hero.phase == phase and hero.phase_left == phase_left, "D preserves active cast, timing and queued move")
	_check(scene.aim_slot == "W" and hero.consumables.I01 == 0, "D preserves another armed skill while consuming")
	# Explicitly stale rendered availability must not authorize a command.
	hero = _fresh()
	scene.hud._shop_button.pressed.emit()
	_check(scene.shop_visible(), "inventory shop button opens actual modal")
	hero.credits = 0
	scene.hud._shop_buy_buttons.I01.pressed.emit()
	_check(hero.consumables.I01 == 0 and hero.credits == 0 and scene.hud._shop_feedback.text.contains("크레딧"), "stale credit button rejected with Korean reason")
	hero.credits = 300
	_refresh()
	hero.pos = Vector2.ZERO
	scene.hud._shop_buy_buttons.I01.pressed.emit()
	_check(hero.consumables.I01 == 0 and hero.credits == 300 and scene.hud._shop_feedback.text.contains("기지"), "stale location button rechecks authority")
	_refresh()
	_check(scene.shop_visible() and scene.hud._shop_buy_buttons.I01.disabled, "offbase shop remains inspectable")
	hero.alive = false
	_refresh()
	_check(scene.hud._shop_buy_buttons.I01.disabled and scene.hud._shop_reasons.I01.text.contains("부활"), "dead shop explains disabled purchase")
	_key(KEY_ESCAPE)
	_key(KEY_P)
	_check(scene.shop_visible(), "dead hero can reopen shop")
	_key(KEY_ESCAPE)
	scene.hud._item_buttons.I02.pressed.emit()
	_check(hero.consumable_selected == "I02", "dead inventory selection is retained")
	_check(not scene.use_consumable(), "dead hero cannot use")
	_key(KEY_D)
	_check(scene.hud._toast_text.text.contains("부활"), "dead use rejection is Korean")
	# Full resources reject without stock loss; D echo is not a second command.
	hero = _fresh()
	hero.consumables.I01 = 2
	_refresh()
	scene.hud._use_button.pressed.emit()
	_check(hero.consumables.I01 == 2 and scene.hud._toast_text.text.contains("가득"), "full-energy use button reports Korean reason without loss")
	hero.energy -= 60
	_key(KEY_D, true)
	_check(hero.consumables.I01 == 2, "key echo is ignored")
	_key(KEY_D)
	_check(hero.consumables.I01 == 1 and hero.consumable_cooldown == 12.0, "first D spends one stock")
	_check(scene.hud._toast_text.text.contains("사용"), "use feedback is Korean")
	scene.battle.step(12.0)
	hero.energy = 0
	_key(KEY_D)
	_key(KEY_D)
	_check(hero.consumables.I01 == 0 and hero.consumable_cooldown == 12.0, "zero boundary repeated D consumes once")
	# Real interruption event; target/enemy names and inventory are not projected.
	hero = _fresh()
	hero.pos = Vector2.ZERO
	hero.hp -= 300
	hero.consumables.I02 = 1
	scene.select_consumable("I02")
	scene.use_consumable()
	var enemy: Dictionary = {}
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "hero" and unit.team == 1:
			enemy = unit
			break
	scene.battle.apply_damage(enemy.id, hero.id, 10, 93001)
	_refresh()
	_check(hero.consumable_effect.is_empty() and scene.hud._toast_text.text.contains("중단"), "actual hostile damage produces Korean patch interruption")
	_check(not scene.hud._toast_text.text.contains(str(enemy.id)), "interruption feedback has no source identity")
	var local_stock_text: String = scene.hud._item_buttons.I01.text + scene.hud._item_buttons.I02.text
	enemy.consumables.I01 = 2
	enemy.consumable_selected = "I02"
	enemy.credits = 9999
	_refresh()
	_check(scene.hud._item_buttons.I01.text + scene.hud._item_buttons.I02.text == local_stock_text and not scene.hud._inventory_credits.text.contains("9999"), "enemy inventory and credits never enter local strip")
	# Pause restoration and mutual exclusion.
	_key(KEY_ESCAPE)
	_check(scene.hud.pause_menu.visible and scene.paused, "Esc pause still works")
	_key(KEY_P)
	_check(not scene.shop_visible() and scene.hud.pause_menu.visible, "pause menu blocks shop")
	scene.open_help()
	_check(scene.help_visible() and scene.paused, "existing help from pause remains available")
	scene.open_shop()
	_check(not scene.shop_visible(), "help blocks shop")
	scene.close_help()
	_check(scene.hud.pause_menu.visible and scene.paused, "help restores prior pause menu")
	scene._resume()
	scene.paused = true
	scene.open_shop()
	scene.close_shop()
	_check(scene.paused and not scene.shop_visible(), "externally paused state is restored")
	scene.paused = false
	scene.open_growth()
	scene.open_shop()
	_check(scene.growth_visible() and not scene.shop_visible(), "growth blocks shop")
	scene.close_growth()
	scene.open_shop()
	scene.open_growth()
	scene.open_help()
	_check(scene.shop_visible() and not scene.growth_visible() and not scene.help_visible(), "shop blocks growth and help methods")
	scene.close_shop()
	# Result, selection and replay clean both the modal and event cursor.
	scene.open_shop()
	scene.battle.winner = 1
	scene._process(0)
	_check(scene.hud.result.visible and not scene.shop_visible(), "result closes shop")
	_check(not scene.buy_consumable("I01") and not scene.select_consumable("I01") and not scene.use_consumable(), "result mutation gates reject all consumable paths")
	scene.return_to_selection()
	_check(not scene.shop_visible() and not scene.hud._inventory.visible and not scene.use_consumable(), "selection hides strip and blocks use")
	hero = _fresh()
	_check(hero.consumables.I01 == 0 and hero.consumable_selected == "I01", "restart resets authority inventory and selection")
	_key(KEY_P)
	scene.hud._shop_buy_buttons.I01.pressed.emit()
	_check(scene.hud._shop_feedback.text.contains("구매"), "fresh match low event sequences still produce feedback")
	scene.close_shop()
	# Both true viewport layouts, no overlap between inventory, hint, skills, map.
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		await process_frame
		await process_frame
		_refresh()
		var strip: Rect2 = scene.hud._inventory.get_global_rect()
		var viewport_size: Vector2 = root.get_visible_rect().size
		_check(is_equal_approx(strip.position.x, 18.0) and is_equal_approx(strip.end.x, viewport_size.x - 298.0), "inventory horizontal band " + str(dimensions))
		_check(is_equal_approx(strip.position.y, viewport_size.y - 240.0) and strip.end.y <= viewport_size.y - 184.0 + 1, "inventory vertical band " + str(dimensions))
		_check(not strip.intersects(scene.hud._bottom.get_global_rect()) and not strip.intersects(scene.hud._map_panel.get_global_rect()), "inventory avoids skills/map " + str(dimensions))
		_check(not strip.intersects(scene.hud._hint.get_global_rect()), "hint avoids inventory " + str(dimensions))
		for control: Control in [scene.hud._inventory, scene.hud._shop_button, scene.hud._use_button, scene.hud._item_buttons.I01, scene.hud._item_buttons.I02]:
			_check(scene.ui_blocks_point(control.get_global_rect().get_center()), "inventory surface blocks world " + control.name + str(dimensions))

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
