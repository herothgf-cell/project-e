extends SceneTree
## Real bot decisions, authority commands and resource timers; no decision mocks.
const STATE_PATH: String = "res://scripts/battle/battle_state.gd"
var checks: int = 0
var failures: int = 0
var state_script: Script

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	state_script = load(STATE_PATH)
	_test_home_stock()
	_test_affordability()
	_test_purchase_location()
	_test_excluded_actors()
	_test_use_thresholds()
	_test_real_recovery_and_cooldown()
	_test_independent_orders()
	_test_player_isolation_and_denial()
	_test_hidden_enemy_independence()
	print("Consumable AI: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func _fixture() -> Variant:
	var state: Variant = state_script.new()
	state.reset("bas")
	state.time = 10.0
	# Keep the real decision entry point while isolating one eligible bot.
	for unit: Dictionary in state.units.values():
		unit.alive = unit.id == state.controlled_id
	var player: Dictionary = state.units[state.controlled_id]
	player.order = "attack_move"
	var actor: Dictionary = _bot(state)
	actor.alive = true
	actor.points = 0
	actor.phase = "windup"
	actor.phase_left = 0.7
	actor.pos = Vector2(-56, 0)
	actor.energy_regen = 0.0
	actor.last_damage = 8.0
	return state

func _bot(state: Variant) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 0 and unit.id != state.controlled_id:
			return unit
	return {}

func _ready_offbase(state: Variant) -> Dictionary:
	var actor: Dictionary = _bot(state)
	actor.pos = Vector2(-10, 0)
	actor.hp = actor.max_hp - 250.0
	actor.energy = 0.0
	actor.consumables = {"I01": 1, "I02": 1}
	return actor

func _test_home_stock() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _bot(state)
	actor.consumable_selected = "I02"
	actor.hp -= 250.0
	actor.energy = 0.0
	state._ai.think(state)
	_check(actor.consumables == {"I01": 1, "I02": 1}, "real think stocks one patch and one bottle at home")
	_near(actor.credits, 10.0, "home purchases spend actual 90 credits")
	_check(actor.consumable_selected == "I02" and actor.consumable_effect.is_empty() and actor.consumable_cooldown == 0.0, "home purchase neither selects nor uses despite resource deficits")
	actor.credits = 100.0
	state._ai.think(state)
	_check(actor.consumables == {"I01": 1, "I02": 1} and actor.credits == 100.0, "repeat decision respects combined stock cap")
	for missing: String in ["I01", "I02"]:
		actor.consumables = {"I01": 1, "I02": 1}
		actor.consumables[missing] = 0
		actor.credits = 100.0
		actor.consumable_cooldown = 12.0
		actor.last_damage = state.time
		state._ai.think(state)
		_check(actor.consumables == {"I01": 1, "I02": 1}, "refills only missing " + missing)
		_near(actor.credits, 60.0 if missing == "I01" else 50.0, "refill exact price even in combat and cooldown " + missing)
	for stock: Dictionary in [{"I01": 2, "I02": 0}, {"I01": 0, "I02": 2}]:
		actor.consumables = stock.duplicate()
		actor.credits = 100.0
		state._ai.think(state)
		_check(actor.consumables == stock and actor.credits == 100.0, "full combined inventory prevents missing-type purchase")

func _test_affordability() -> void:
	# Literal outcomes prove patch-first buying and exact affordability boundaries.
	for example: Array in [[0, 0, 0, 0], [39, 0, 0, 39], [40, 1, 0, 0], [49, 1, 0, 9], [50, 0, 1, 0], [89, 0, 1, 39], [90, 1, 1, 0]]:
		var state: Variant = _fixture()
		var actor: Dictionary = _bot(state)
		actor.credits = float(example[0])
		state._ai.think(state)
		_check(actor.consumables == {"I01": example[1], "I02": example[2]}, "stock priority and affordability at %d credits" % example[0])
		_near(actor.credits, float(example[3]), "nonnegative exact credit remainder at %d" % example[0])
		_check(actor.hp == actor.max_hp and actor.energy == actor.max_energy, "full resources allow purchase without use")

func _test_purchase_location() -> void:
	for example: Array in [[0, Vector2(-56, 0), true], [1, Vector2(56, 0), true], [0, Vector2(56, 0), false], [1, Vector2(-56, 0), false], [0, Vector2(-53, 0), false], [1, Vector2(59, 0), false], [0, Vector2.ZERO, false]]:
		var state: Variant = _fixture()
		var actor: Dictionary = _bot(state)
		actor.team = example[0]
		actor.pos = example[1]
		state._ai.think(state)
		_check(actor.consumables == ({"I01": 1, "I02": 1} if example[2] else {"I01": 0, "I02": 0}), "purchase only in own base: team %d at %s" % [actor.team, actor.pos])
		_near(actor.credits, 10.0 if example[2] else 100.0, "purchase location controls actual spending")

func _test_excluded_actors() -> void:
	for exclusion: String in ["dead", "disabled", "controlled"]:
		for at_home: bool in [true, false]:
			var state: Variant = _fixture()
			var actor: Dictionary = _bot(state)
			if not at_home:
				actor = _ready_offbase(state)
			if exclusion == "dead":
				actor.alive = false
			elif exclusion == "disabled":
				state.bots_enabled = false
			else:
				state.controlled_id = actor.id
			var before: Dictionary = actor.duplicate(true)
			state._ai.think(state)
			_check(actor == before, "%s hero unchanged for home=%s" % [exclusion, at_home])

func _test_use_thresholds() -> void:
	# hp deficit, energy deficit, damage elapsed, patch stock, bottle stock, expected use.
	for example: Array in [[200.0, 40.0, 2.0, 1, 1, "I02"], [199.99, 40.0, 2.0, 1, 1, "I01"], [200.0, 40.0, 1.999, 1, 1, "I01"], [250.0, 39.99, 1.999, 1, 1, ""], [199.99, 39.99, 2.0, 1, 1, ""], [0.0, 40.0, 0.0, 1, 1, "I01"], [250.0, 40.0, 2.0, 0, 1, "I01"], [200.0, 0.0, 2.0, 1, 0, "I02"], [250.0, 100.0, 2.0, 0, 0, ""], [0.0, 0.0, 2.0, 1, 1, ""]]:
		var state: Variant = _fixture()
		var actor: Dictionary = _ready_offbase(state)
		actor.hp = actor.max_hp - example[0]
		actor.energy = actor.max_energy - example[1]
		actor.last_damage = state.time - example[2]
		actor.consumables = {"I01": example[4], "I02": example[3]}
		actor.consumable_selected = "I02" if example[5] == "I01" else "I01"
		var before: Dictionary = actor.duplicate(true)
		state._ai.think(state)
		var chosen: String = example[5]
		_check(actor.consumable_effect.get("item_id", "") == chosen, "own-resource threshold chooses '%s' for %s" % [chosen, example])
		_near(actor.credits, 100.0, "offbase decision never purchases")
		if chosen.is_empty():
			_check(actor == before, "unusable decision preserves selection and all actor state")
		else:
			_check(actor.consumables[chosen] == before.consumables[chosen] - 1 and actor.consumable_selected == chosen, "successful decision selects and consumes exactly one " + chosen)
			_near(actor.consumable_cooldown, 12.0, "successful decision starts shared cooldown")

func _test_real_recovery_and_cooldown() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _ready_offbase(state)
	var initial_hp: float = actor.hp
	state._ai.think(state)
	state._timers(actor, 4.0)
	_near(actor.hp, initial_hp + 200.0, "bot-selected patch restores real 200 HP over four seconds")
	_check(actor.consumables == {"I01": 1, "I02": 0} and actor.consumable_effect.is_empty(), "patch recovery ends with bottle retained")
	actor.consumable_selected = "I02"
	var before: Dictionary = actor.duplicate(true)
	state._ai.think(state)
	_check(actor == before, "shared cooldown prevents selection mutation or bottle use")
	state._timers(actor, 8.0)
	_check(actor.consumable_cooldown == 0.0, "twelve-second shared cooldown unlocks")
	state._ai.think(state)
	_check(actor.consumable_selected == "I01" and actor.consumables.I01 == 0, "bot uses retained bottle after shared cooldown")
	state._ai.think(state)
	state._timers(actor, 2.0)
	_near(actor.energy, 40.0, "bot-selected bottle restores real 40 energy over two seconds")
	_check(actor.consumables == {"I01": 0, "I02": 0} and actor.consumable_effect.is_empty(), "repeat decisions do not double-consume")

func _test_independent_orders() -> void:
	for action: String in ["basic", "windup", "dash", "recovery", "stunned", "attack_move"]:
		var state: Variant = _fixture()
		var actor: Dictionary = _ready_offbase(state)
		actor.order = "attack_move" if action == "attack_move" else "move"
		actor.phase = action if action in ["basic", "windup", "dash", "recovery"] else "idle"
		actor.stun_left = 0.6 if action == "stunned" else 0.0
		actor.root_left = 0.5
		actor.path = [Vector2(-12, 0)]
		actor.goal = Vector2(-12, 0)
		actor.attack_move_goal = Vector2(-14, 0)
		actor.cast = {"id": 900, "slot": "Q"}
		actor.queued = {"slot": "E", "target": Vector2(-11, 0)}
		var before: Dictionary = actor.duplicate(true)
		state._ai.think(state)
		_check(actor.consumable_effect.get("item_id", "") == "I02", "independent patch use during " + action)
		for field: String in ["order", "path", "goal", "target_id", "phase", "phase_left", "cast", "queued", "root_left", "stun_left", "attack_move_goal"]:
			_check(actor[field] == before[field], "consumable preserves %s during %s" % [field, action])

func _test_player_isolation_and_denial() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _ready_offbase(state)
	var player: Dictionary = state.units[state.controlled_id]
	player.pos = Vector2(-10, 0)
	player.hp -= 250.0
	player.energy = 0.0
	player.consumables = {"I01": 1, "I02": 1}
	player.consumable_selected = "I02"
	var before_player: Dictionary = player.duplicate(true)
	state.last_error = "unrelated player error"
	var before_events: Array = state.events.duplicate(true)
	state._ai.think(state)
	_check(player == before_player, "eligible player receives no automatic consumption or selection mutation")
	_check(state.last_error == "unrelated player error" and state.events == before_events, "bot use preserves player error and event stream")
	_check(actor.consumable_effect.get("item_id", "") == "I02", "player isolation still permits eligible bot use")
	for denied: String in ["ended", "cooldown", "empty", "full", "poor"]:
		state = _fixture()
		actor = _ready_offbase(state)
		actor.consumable_selected = "I01"
		match denied:
			"ended": state.winner = 0
			"cooldown": actor.consumable_cooldown = 0.001
			"empty": actor.consumables = {"I01": 0, "I02": 0}
			"full":
				actor.hp = actor.max_hp
				actor.energy = actor.max_energy
			"poor":
				actor.pos = Vector2(-56, 0)
				actor.consumables = {"I01": 0, "I02": 0}
				actor.credits = 39.0
		var before: Dictionary = actor.duplicate(true)
		state.last_error = "unrelated player error"
		state._ai.think(state)
		_check(actor == before, "authority denial leaves selection/stock/credits unchanged: " + denied)
		_check(state.last_error == "unrelated player error", "denied bot decision preserves unrelated player error: " + denied)

func _test_hidden_enemy_independence() -> void:
	var snapshots: Array = []
	for changed_enemy: bool in [false, true]:
		var state: Variant = _fixture()
		var actor: Dictionary = _ready_offbase(state)
		for enemy: Dictionary in state.units.values():
			if enemy.kind == "hero" and enemy.team == 1:
				enemy.alive = true
				enemy.points = 0
				enemy.phase = "windup"
				enemy.pos = Vector2(40, -18) if changed_enemy else Vector2(56, 0)
				enemy.hp = 1.0 if changed_enemy else enemy.max_hp
				_check(not state.is_visible(actor.team, enemy.id), "comparison enemy remains hidden")
		state._ai.think(state)
		snapshots.append(actor.duplicate(true))
	_check(snapshots[0] == snapshots[1] and snapshots[0].consumable_effect.get("item_id", "") == "I02", "hidden enemy position and health cannot affect consumable decision")

func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func _near(actual: float, expected: float, message: String) -> void:
	_check(absf(actual - expected) < 0.0001, "%s (actual %.6f expected %.6f)" % [message, actual, expected])
