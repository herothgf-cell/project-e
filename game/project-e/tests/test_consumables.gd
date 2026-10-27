extends SceneTree
## Consumables use the real authority and damage/timer boundaries.
const STATE_PATH: String = "res://scripts/battle/battle_state.gd"
var checks: int = 0
var failures: int = 0
var state_script: Script

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	state_script = load(STATE_PATH)
	var state: Variant = state_script.new()
	for method: String in ["is_in_home_base", "consumable_purchase_error", "consumable_use_error", "command_buy_consumable", "command_select_consumable", "command_use_consumable"]:
		_check(state.has_method(method), "Battle state exposes %s" % method)
	if failures > 0:
		_finish()
		return
	_test_catalog_and_defaults()
	_test_base_and_purchase()
	_test_validation_and_actions()
	_test_healing()
	_test_interruption()
	_test_death_reset_and_end()
	_test_events_and_tick_order()
	_test_malformed_inputs()
	_test_exact_shared_cooldown_boundary()
	_finish()

func _fixture() -> Variant:
	var state: Variant = state_script.new()
	state.reset()
	state.bots_enabled = false
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero":
			unit.pos = Vector2(-56 if unit.team == 0 else 56, 0)
	var actor: Dictionary = state.units[state.controlled_id]
	actor.energy_regen = 0.0
	actor.credits = 1000.0
	return state

func _enemy(state: Variant) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 1:
			return unit
	return {}

func _prime(state: Variant, item_id: String) -> Dictionary:
	var actor: Dictionary = state.units[state.controlled_id]
	actor.pos = Vector2(-56, 0)
	actor.consumables = {"I01": 0, "I02": 0}
	actor.consumable_cooldown = 0.0
	_check(state.command_buy_consumable(actor.id, item_id), "prime buys " + item_id)
	_check(state.command_select_consumable(actor.id, item_id), "prime selects " + item_id)
	actor.pos = Vector2(-10, 0)
	actor.hp = 300.0
	actor.energy = 10.0
	_check(state.command_use_consumable(actor.id), "prime uses " + item_id)
	return actor

func _test_catalog_and_defaults() -> void:
	var catalog: Script = load("res://scripts/battle/battle_consumables.gd")
	_check(catalog != null, "catalog loads")
	var items: Dictionary = catalog.ITEMS
	_check(items.keys().size() == 2, "exactly two consumables")
	_check(items.I01.cost == 40 and items.I01.resource == "energy" and items.I01.amount == 40 and items.I01.duration == 2, "I01 literal 40 credits and energy40/2s")
	_check(items.I02.cost == 50 and items.I02.resource == "hp" and items.I02.amount == 200 and items.I02.duration == 4, "I02 literal 50 credits and HP200/4s")
	var state: Variant = _fixture()
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero":
			_check(unit.consumables == {"I01": 0, "I02": 0} and unit.consumable_selected == "I01" and unit.consumable_cooldown == 0 and unit.consumable_effect.is_empty(), "hero initial inventory selected cooldown effect")
	var synthetic: Dictionary = state._entity("hero", 0, Vector2(-56, 0), 100, 0.4)
	_check(synthetic.consumables == {"I01": 0, "I02": 0}, "synthetic hero receives independent defaults")
	synthetic.consumables.I01 = 1
	_check(state.units[state.controlled_id].consumables.I01 == 0, "inventory dictionaries are independent")

func _test_base_and_purchase() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	for team: int in [0, 1]:
		actor.team = team
		var left: float = -59.0 if team == 0 else 53.0
		for position: Vector2 in [Vector2(left, -6), Vector2(left + 5.99, 5.99)]:
			actor.pos = position
			_check(state.is_in_home_base(actor.id), "home rectangle includes near edges")
		for position: Vector2 in [Vector2(left + 6, 0), Vector2(left, 6), Vector2(left - 0.01, 0), Vector2(left, -6.01), Vector2(-56 if team == 1 else 56, 0)]:
			actor.pos = position
			_check(not state.is_in_home_base(actor.id), "home rectangle excludes far/outside/enemy edges")
	actor.team = 0
	actor.pos = Vector2(-56, 0)
	for item_id: String in ["I01", "I02"]:
		actor.consumables = {"I01": 0, "I02": 0}
		actor.credits = 40.0 if item_id == "I01" else 50.0
		var before: Dictionary = actor.duplicate(true)
		state.last_error = "sentinel"
		_check(state.consumable_purchase_error(actor.id, item_id).is_empty(), "exact price preview succeeds")
		_check(actor == before and state.last_error == "sentinel", "purchase preview read-only")
		_check(state.command_buy_consumable(actor.id, item_id), "exact price purchase succeeds")
		_near(actor.credits, 0.0, "exact price deducted")
		_check(not state.command_buy_consumable(actor.id, item_id), "repeat with no funds rejected")
	actor.credits = 1000
	actor.consumables = {"I01": 1, "I02": 0}
	actor.consumable_cooldown = 12
	actor.last_damage = state.time
	actor.last_hostile = state.time
	_check(state.command_buy_consumable(actor.id, "I02"), "buy during cooldown/combat")
	var credits: float = actor.credits
	_check(not state.command_buy_consumable(actor.id, "I01"), "combined two cap rejects third")
	_near(actor.credits, credits, "cap failure costs nothing")
	actor.consumables = {"I01": 0, "I02": 0}
	actor.credits = 40
	_check(state.consumable_purchase_error(actor.id, "I01").is_empty(), "stale preview initially succeeds")
	actor.pos = Vector2.ZERO
	_check(not state.command_buy_consumable(actor.id, "I01"), "command rechecks stale position")
	actor.pos = Vector2(-56, 0)
	actor.credits = 39
	_check(not state.command_buy_consumable(actor.id, "I01"), "command rechecks current funds")
	actor.alive = false
	_check(not state.command_buy_consumable(actor.id, "I01"), "dead hero cannot buy")

func _test_validation_and_actions() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	for id: int in [-1, 999999]:
		_check(not state.command_buy_consumable(id, "I01") and not state.command_select_consumable(id, "I01") and not state.command_use_consumable(id), "invalid unit commands rejected")
	for unit: Dictionary in state.units.values():
		if unit.kind == "tower":
			_check(not state.command_buy_consumable(unit.id, "I01") and not state.command_select_consumable(unit.id, "I01") and not state.command_use_consumable(unit.id), "other unit commands rejected")
			break
	_check(not state.command_buy_consumable(actor.id, "bad") and not state.command_select_consumable(actor.id, "bad"), "invalid item rejected")
	_check(state.command_select_consumable(actor.id, "I02"), "empty selection allowed")
	_check(not state.command_use_consumable(actor.id), "empty selected use rejected")
	_check(state.command_buy_consumable(actor.id, "I01"), "buy does not alter selection")
	_check(actor.consumable_selected == "I02" and not state.command_use_consumable(actor.id), "no automatic fallback to stocked item")
	state.command_select_consumable(actor.id, "I01")
	_check(not state.command_use_consumable(actor.id), "full resource rejected")
	actor.energy = 99
	actor.pos = Vector2(-10, 0)
	state.command_move(actor.id, Vector2(-12, 0))
	actor.phase = "windup"
	actor.phase_left = 0.7
	actor.cast = {"id": 900, "slot": "Q"}
	actor.queued = {"slot": "E", "target": Vector2(-11, 0)}
	actor.root_left = 0.5
	actor.stun_left = 0.6
	var before: Dictionary = actor.duplicate(true)
	state.last_error = "sentinel"
	_check(state.consumable_use_error(actor.id).is_empty(), "use preview accepts offbase CC and casting")
	_check(actor == before and state.last_error == "sentinel", "use preview read-only")
	_check(state.command_use_consumable(actor.id), "use while moving/casting/CC")
	for field: String in ["order", "path", "goal", "target_id", "phase", "phase_left", "cast", "queued", "root_left", "stun_left"]:
		_check(actor[field] == before[field], "use preserves " + field)
	_check(actor.consumables.I01 == 0 and actor.consumable_selected == "I01", "one consumed without auto selection")
	_near(actor.consumable_cooldown, 12, "shared cooldown starts at twelve")
	actor.consumables.I02 = 1
	actor.hp = 100
	state.command_select_consumable(actor.id, "I02")
	_check(not state.command_use_consumable(actor.id), "shared cooldown blocks second type")
	state._timers(actor, 12.0)
	_near(actor.consumable_cooldown, 0.0, "cooldown reaches zero boundary")
	_check(state.command_use_consumable(actor.id) and not state.command_use_consumable(actor.id), "zero boundary consumes once under repeat calls")

func _test_healing() -> void:
	for item_id: String in ["I01", "I02"]:
		var state: Variant = _fixture()
		var actor: Dictionary = _prime(state, item_id)
		var resource: String = "energy" if item_id == "I01" else "hp"
		var initial: float = actor[resource]
		var duration: float = 2 if item_id == "I01" else 4
		var amount: float = 40 if item_id == "I01" else 200
		state._timers(actor, duration - 0.01)
		_near(actor[resource], initial + amount * (duration - 0.01) / duration, "healing before final partial tick")
		state._timers(actor, 0.1)
		_near(actor[resource], initial + amount, "final partial tick pays exact total")
		_check(actor.consumable_effect.is_empty(), "effect completed")
		_near(actor.consumable_cooldown, 12 - duration - 0.09, "cooldown independent of effect length")
		_check(_last_end(state).get("reason") == "completed", "completion event reason")
		actor = _prime(state, item_id)
		actor[resource] = actor["max_" + resource] - 1
		state._timers(actor, duration + 1)
		_near(actor[resource], actor["max_" + resource], "partial resource caps without overflow")
	var state: Variant = _fixture()
	var actor: Dictionary = _prime(state, "I01")
	actor.energy_regen = 8
	state._timers(actor, 1.0)
	_near(actor.energy, 38, "natural regeneration adds to bottle")
	actor.pos = Vector2(-56, 0)
	state._timers(actor, 0.5)
	_near(actor.energy, 62, "base and natural regeneration add to bottle")
	actor = _prime(state, "I02")
	actor.pos = Vector2(-56, 0)
	state._timers(actor, 0.5)
	_near(actor.hp, 435, "base HP regeneration adds to patch")

func _test_interruption() -> void:
	for mode: String in ["hero", "device", "dead_owner", "shield", "minion", "tower", "protected", "duplicate", "cc", "zero", "friendly", "invalid"]:
		var state: Variant = _fixture()
		var actor: Dictionary = _prime(state, "I02")
		var enemy: Dictionary = _enemy(state)
		var source_id: int = enemy.id
		var cast_id: int = 1100
		if mode in ["device", "dead_owner"]:
			var device: Dictionary = state._entity("pin", 1, Vector2.ZERO, 100, 0.3)
			device.owner_id = enemy.id
			source_id = device.id
			if mode == "dead_owner":
				enemy.alive = false
		if mode in ["minion", "tower"]:
			var unit: Dictionary = state._entity(mode, 1, Vector2.ZERO, 100, 0.3)
			source_id = unit.id
			actor.contributors[enemy.id] = state.time
		if mode == "shield":
			state.add_shield(actor.id, "test", 100, 3)
		if mode == "protected":
			actor.protected = 1
		if mode == "duplicate":
			state.apply_damage(enemy.id, actor.id, 10, cast_id, "dot")
			actor = _prime(state, "I02")
		if mode == "friendly":
			source_id = actor.id
		if mode == "invalid":
			source_id = -1
		if mode == "cc":
			state.apply_cc(actor.id, "root", 0.5)
		else:
			state.apply_damage(source_id, actor.id, 0 if mode == "zero" else 10, cast_id, "dot")
		var interrupted: bool = mode in ["hero", "device", "dead_owner", "shield"]
		_check(actor.consumable_effect.is_empty() == interrupted, "patch interruption source " + mode)
		if interrupted:
			_check(_last_end(state).get("reason") == "interrupted", "interruption event reason " + mode)
		else:
			var hp: float = actor.hp
			state._timers(actor, 0.1)
			_near(actor.hp, hp + 5, "uninterrupted patch continues " + mode)
	var state: Variant = _fixture()
	var actor: Dictionary = _prime(state, "I01")
	state.apply_damage(_enemy(state).id, actor.id, 10, 1110)
	_check(not actor.consumable_effect.is_empty(), "hostile hero damage does not stop bottle")

func _test_death_reset_and_end() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _prime(state, "I01")
	actor.consumables.I02 = 1
	state.command_select_consumable(actor.id, "I02")
	state.apply_damage(_enemy(state).id, actor.id, 10000, 1200)
	_check(not actor.alive and actor.consumable_effect.is_empty(), "actual lethal hit clears bottle")
	_check(_last_end(state).get("reason") == "death", "death event reason")
	state._timers(actor, 1)
	_near(actor.consumable_cooldown, 11, "cooldown counts during death")
	_check(actor.consumables.I02 == 1 and actor.consumable_selected == "I02", "death preserves inventory selection")
	_near(actor.energy, 10, "dead hero receives no HoT")
	actor.respawn_left = 0.5
	state._timers(actor, 0.5)
	_check(actor.alive and actor.consumables.I02 == 1 and actor.consumable_effect.is_empty(), "respawn preserves stock without effect")
	_near(actor.consumable_cooldown, 10.5, "respawn retains cooldown")
	actor = _prime(state, "I02")
	state.winner = 0
	var before: Dictionary = actor.duplicate(true)
	state.step(3)
	_check(actor == before, "ended match time and effects frozen")
	_check(not state.command_buy_consumable(actor.id, "I01") and not state.command_use_consumable(actor.id), "ended match rejects purchase/use")
	state.reset()
	actor = state.units[state.controlled_id]
	_check(actor.consumables == {"I01": 0, "I02": 0} and actor.consumable_selected == "I01" and actor.consumable_effect.is_empty() and actor.consumable_cooldown == 0, "reset clears all consumable state")
	var bot: Dictionary = _enemy(state)
	bot.credits = 100
	bot.pos = Vector2(56, 0)
	state.last_error = "human sentinel"
	var count: int = state.events.size()
	_check(state.command_buy_consumable(bot.id, "I02"), "same authority purchases for bot")
	_check(not state.command_buy_consumable(bot.id, "bad"), "bot rejection")
	bot.hp -= 300
	state.command_select_consumable(bot.id, "I02")
	state.command_use_consumable(bot.id)
	state._timers(bot, 4)
	_check(state.last_error == "human sentinel" and state.events.size() == count, "bot commands do not overwrite controlled error or events")

func _test_events_and_tick_order() -> void:
	for item_id: String in ["I01", "I02"]:
		var state: Variant = _fixture()
		var actor: Dictionary = _prime(state, item_id)
		var resource: String = "energy" if item_id == "I01" else "hp"
		var duration: float = 2 if item_id == "I01" else 4
		state.step(duration)
		_near(actor[resource], 50 if item_id == "I01" else 500, "fixed ticks pay literal total " + item_id)
		_check(actor.consumable_effect.is_empty(), "fixed ticks finish on duration " + item_id)
		var found: Array = []
		for event: Dictionary in state.events:
			if event.type.begins_with("consumable_"):
				found.append(event.type)
				_check(event.target_id == actor.id and event.item_id == item_id, "event identifies hero and item")
		_check(found == ["consumable_purchase", "consumable_use", "consumable_end"], "one event per successful transition")
	var state: Variant = _fixture()
	var actor: Dictionary = _prime(state, "I02")
	var enemy: Dictionary = _enemy(state)
	# The timer phase pays this tick before the later projectile phase interrupts.
	state.projectiles.append({"id": 1700, "cast_id": 1700, "kind": "basic", "pos": actor.pos, "target_pos": actor.pos, "target_id": actor.id, "owner_id": enemy.id, "team": 1, "damage": 10.0, "remaining": 3.0})
	state.step(1.0 / 30.0)
	_near(actor.hp, 300.0 + 50.0 / 30.0 - 10.0, "same tick pays healing before interruption")
	_check(actor.consumable_effect.is_empty(), "projectile interrupts in existing tick order")
	var hp: float = actor.hp
	state.step(1.0 / 30.0)
	_near(actor.hp, hp, "next tick has no interrupted healing")
	actor = _prime(state, "I02")
	state.apply_damage(enemy.id, actor.id, 10000, 1800)
	_check(not actor.alive and actor.consumable_effect.is_empty() and _last_end(state).reason == "death", "lethal patch damage emits one death end")
	var ends: int = 0
	for event: Dictionary in state.events:
		if event.type == "consumable_end" and event.item_id == "I02" and event.get("reason") == "death":
			ends += 1
	_check(ends == 1, "lethal patch does not double end")

func _test_malformed_inputs() -> void:
	for mutation: String in ["id", "alive", "negative_cooldown", "inventory", "credits", "resource", "position"]:
		var state: Variant = _fixture()
		var actor: Dictionary = state.units[state.controlled_id]
		actor.consumables.I01 = 1
		actor.energy = 10
		match mutation:
			"id": actor.erase("id")
			"alive": actor.alive = "invalid"
			"negative_cooldown": actor.consumable_cooldown = -1.0
			"inventory": actor.consumables = {"I01": -1, "I02": 0}
			"credits": actor.credits = NAN
			"resource": actor.energy = INF
			"position": actor.pos = Vector2(NAN, 0)
		var before: Dictionary = actor.duplicate(true)
		if mutation in ["id", "alive", "inventory", "credits", "position"]:
			_check(not state.consumable_purchase_error(state.controlled_id, "I01").is_empty(), "malformed purchase rejected " + mutation)
		if mutation in ["id", "alive", "negative_cooldown", "inventory", "resource"]:
			_check(not state.consumable_use_error(state.controlled_id).is_empty(), "malformed use rejected " + mutation)
		if mutation != "position" and mutation != "credits" and mutation != "resource":
			_check(actor == before, "malformed preview leaves actor unchanged " + mutation)
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	actor.consumables.I01 = 1
	actor.energy = 10
	actor.consumable_cooldown = 1
	var before: Dictionary = actor.duplicate(true)
	_check(not state.command_use_consumable(actor.id) and actor == before, "failed use preserves all actor state")

func _test_exact_shared_cooldown_boundary() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _prime(state, "I01")
	actor.consumables.I02 = 1
	state.command_select_consumable(actor.id, "I02")
	state.step(12.0)
	_check(actor.consumable_cooldown == 0.0, "360 fixed ticks clamp exact twelve-second cooldown to zero")
	_check(state.command_use_consumable(actor.id), "exact twelve-second boundary unlocks selected patch")
	_check(not state.command_use_consumable(actor.id) and actor.consumables.I02 == 0, "boundary repeat consumes only once")

func _last_end(state: Variant) -> Dictionary:
	for index: int in range(state.events.size() - 1, -1, -1):
		if state.events[index].type == "consumable_end":
			return state.events[index]
	return {}

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _near(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) < 0.0001, "%s (actual %.6f expected %.6f)" % [message, actual, expected])

func _finish() -> void:
	print("Consumables: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
