extends SceneTree
## Real fixed-step integration checks: navigation, waves, siege and bot pressure.

const STATE_PATH: String = "res://scripts/battle/battle_state.gd"
var checks: int = 0
var failures: int = 0
var state_script: Script


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists(STATE_PATH):
		_check(false, "Three-lane match is not implemented yet")
		_finish()
		return
	state_script = load(STATE_PATH)
	if state_script == null or not state_script.can_instantiate():
		_check(false, "Three-lane match must load")
		_finish()
		return
	_test_navigation()
	_test_waves_and_siege()
	_test_victory_and_restart()
	_test_autonomous_minions_and_towers()
	_test_minion_leash()
	if failures > 0:
		_finish()
		return
	_test_determinism_and_bots()
	_finish()


func _new_state() -> Variant:
	var state: Variant = state_script.new()
	state.reset("bas")
	return state


func _test_navigation() -> void:
	var state: Variant = _new_state()
	_check(state.map.lane_paths.size() == 3 and state.map.connectors.size() == 4, "map has three distinct lanes and four connectors")
	for start: Vector2 in [Vector2(-56.0, 0.0), Vector2(56.0, 0.0)]:
		for goal: Vector2 in [Vector2(0.0, 18.0), Vector2.ZERO, Vector2(0.0, -18.0)]:
			var path: Array = state.map.find_path(start, goal)
			_check(not path.is_empty(), "every spawn can reach every lane")
			var previous: Vector2 = start
			for point: Vector2 in path:
				var length: float = previous.distance_to(point)
				for sample: int in range(int(ceil(length / 0.2)) + 1):
					_check(state.map.is_walkable(previous.lerp(point, minf(1.0, float(sample) * 0.2 / maxf(length, 0.001)))), "navigation segment stays on walkable ground")
				previous = point
	_check(not state.map.is_walkable(Vector2(0.0, 9.0)), "opaque blocker is not walkable")
	_check(not state.map.is_walkable(Vector2(0.0, 30.0)), "water is not walkable")
	state.bots_enabled = false
	var actor: Dictionary = state.units[state.controlled_id]
	# Outside the central 9m-wide fighting pad, the lane is 6m wide.
	actor.pos = Vector2(-8.0, 2.0)
	state.command_cast(actor.id, "E", Vector2(-8.0, 10.0))
	state.step(0.7)
	_check(state.map.is_walkable(actor.pos) and actor.pos.y < 3.0, "dash stops at water and cannot tunnel")


func _test_waves_and_siege() -> void:
	var state: Variant = _new_state()
	state.bots_enabled = false
	state.step(20.05)
	var counts: Dictionary = {}
	for unit: Dictionary in state.units.values():
		if unit.kind == "minion":
			var key: String = "%d:%d" % [unit.team, unit.lane]
			counts[key] = counts.get(key, 0) + 1
	_check(counts.size() == 6, "first wave spawns on every team/lane")
	for amount: int in counts.values():
		_check(amount == 4, "first wave has three melee and one ranged")
	for unit: Dictionary in state.units.values():
		if unit.kind == "minion" and unit.team == 0 and unit.lane == 1:
			_check(unit.pos.x < -44.7, "first-wave front starts at the five-metre spawn anchor")
		if unit.kind == "minion":
			_check(state.map.is_walkable(unit.pos, unit.radius), "every spawned formation member stands outside the core collision")
	var actor: Dictionary = state.units[state.controlled_id]
	var outer: Dictionary = _structure(state, 1, "outer", 1)
	var inner: Dictionary = _structure(state, 1, "inner", 1)
	var core: Dictionary = _structure(state, 1, "core", 1)
	state.apply_damage(actor.id, inner.id, 100.0, 900, "one")
	_check(inner.hp == inner.max_hp, "inner tower ignores damage while outer lives")
	state.apply_damage(actor.id, core.id, 100.0, 901, "one")
	_check(core.hp == core.max_hp, "core ignores damage before lane opens")
	state.apply_damage(actor.id, outer.id, 100.0, 902, "one")
	_check(absf(outer.hp - 1985.0) < 0.01, "hero siege without minions deals 15 percent")
	for unit: Dictionary in state.units.values():
		if unit.kind == "minion" and unit.team == 0:
			unit.pos = outer.pos + Vector2(-3.0, 0.0)
			break
	state.apply_damage(actor.id, outer.id, 100.0, 903, "one")
	_check(absf(outer.hp - 1935.0) < 0.01, "nearby line minion removes only absence protection")
	state.apply_damage(actor.id, outer.id, 100000.0, 904, "one")
	state.step(0.04)
	_check(not inner.locked, "destroying outer unlocks same-lane inner")
	state.apply_damage(actor.id, inner.id, 100000.0, 905, "one")
	state.step(0.04)
	_check(not core.locked, "one open lane permanently unlocks core")


func _structure(state: Variant, team: int, subtype: String, lane: int) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.team == team and (unit.kind == "core" if subtype == "core" else unit.get("subtype", "") == subtype) and (subtype == "core" or unit.lane == lane):
			return unit
	return {}


func _test_victory_and_restart() -> void:
	var state: Variant = _new_state()
	state.bots_enabled = false
	var west: Dictionary = _structure(state, 0, "core", 1)
	var east: Dictionary = _structure(state, 1, "core", 1)
	west.alive = false
	west.hp = 0.0
	east.alive = false
	east.hp = 0.0
	state.step(0.04)
	_check(state.winner == 2, "both cores dead in one tick is a draw")
	var actor: Dictionary = state.units[state.controlled_id]
	_check(not state.command_move(actor.id, Vector2.ZERO), "completed match rejects commands")
	var finished_time: float = state.time
	state.step(10.0)
	_check(state.time == finished_time, "completed match no longer simulates")
	state.reset("nema")
	_check(state.winner == -1 and state.time == 0.0, "restart clears winner and clock")
	_check(state.effects.is_empty() and state.projectiles.is_empty(), "restart clears old effect/projectile state")
	_check(state.units[state.controlled_id].hero == "nema", "restart honors selected hero")
	_check(state.units.size() == 20, "restart has six heroes and fourteen structures")


func _test_determinism_and_bots() -> void:
	var first: Variant = _new_state()
	var second: Variant = _new_state()
	first.controlled_id = -1
	second.controlled_id = -1
	for index: int in range(600):
		first.step(0.1)
	for index: int in range(1800):
		second.step(1.0 / 30.0)
	_check(first.units.size() == second.units.size(), "frame partition does not change spawn/death counts")
	for id: int in first.units:
		if second.units.has(id):
			_check(first.units[id].pos.distance_to(second.units[id].pos) < 0.001 and absf(first.units[id].hp - second.units[id].hp) < 0.001, "fixed-step state is deterministic")
	var damage_at_minute: float = first.stats.damage
	_check(damage_at_minute > 3000.0, "bots and minions produce real combat in first minute")
	print("Bot checkpoint: %.1fs; damage=%.1f; units=%d" % [first.time, first.stats.damage, first.units.size()])
	var long_run: bool = "--long" in OS.get_cmdline_user_args()
	for index: int in range(3600 if long_run else 1500):
		if first.winner != -1:
			break
		first.step(0.5)
		if index > 0 and index % 300 == 0:
			print("Bot checkpoint: %.1fs; damage=%.1f; units=%d" % [first.time, first.stats.damage, first.units.size()])
	var towers_destroyed: int = 0
	for unit: Dictionary in first.units.values():
		if unit.kind == "tower" and not unit.alive:
			towers_destroyed += 1
	_check(towers_destroyed > 0 or first.winner != -1, "long bot simulation produces siege progress")
	_check(first.stats.hero_deaths > 0, "bots can kill and respawn heroes")
	print("Bot diagnostic: %.1fs; winner=%d; towers=%d; damage=%.1f; hero deaths=%d; units=%d" % [first.time, first.winner, towers_destroyed, first.stats.damage, first.stats.hero_deaths, first.units.size()])
	if long_run:
		for unit: Dictionary in first.units.values():
			if unit.kind in ["core", "hero"] or (unit.kind == "tower" and unit.alive):
				print("End state: %s team=%d hp=%.1f position=%s order=%s target=%d" % [unit.name, unit.team, unit.hp, unit.pos, unit.order, unit.target_id])
		_check(first.winner != -1, "extended natural bot match reaches a core result")


func _test_autonomous_minions_and_towers() -> void:
	var state: Variant = _new_state()
	state.bots_enabled = false
	state.step(20.05)
	var front: Dictionary = {}
	for unit: Dictionary in state.units.values():
		if unit.kind == "minion" and unit.team == 0 and unit.lane == 1:
			front = unit
			break
	var before: Vector2 = front.pos
	state.step(2.0)
	_check(front.pos.x > before.x + 5.0, "autonomous wave advances down its assigned lane")
	_check(absf(front.pos.y) < 0.1, "central wave stays on the central lane")
	state = _new_state()
	state.bots_enabled = false
	var hero: Dictionary = state.units[state.controlled_id]
	hero.pos = Vector2(3.0, 3.5)
	var minion: Dictionary = state._entity("minion", 0, Vector2(4.0, 3.5), 240.0, 0.3)
	minion.subtype = "melee"
	minion.reward_xp = 20.0
	minion.reward_credits = 12.0
	state.step(0.6)
	_check(minion.hp < 240.0 and hero.hp == hero.max_hp, "tower chooses a line minion before an enemy hero")
	var defender: Dictionary = {}
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 1:
			defender = unit
			break
	defender.pos = Vector2(8.0, 0.0)
	state.apply_damage(hero.id, defender.id, 1.0, state.next_action_id(), "provoke")
	state.step(1.1)
	_check(hero.hp < hero.max_hp, "hero damage near a tower triggers its three-second retaliation")


func _test_minion_leash() -> void:
	var state: Variant = _new_state()
	state.bots_enabled = false
	var minion: Dictionary = state._entity("minion", 0, Vector2(-14.8, 10.8), 240.0, 0.3)
	minion.merge({"subtype": "melee", "lane": 0, "speed": 3.2, "attack_range": 1.5, "attack_damage": 20.0, "chase_origin": Vector2(-14.8, 18.0)}, true)
	var enemy: Dictionary = {}
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 1:
			enemy = unit
			break
	enemy.pos = Vector2(-16.0, 9.0)
	_check(state.command_attack(minion.id, enemy.id), "visible hero can lure a lane minion")
	state._ai.think(state)
	_check(minion.order == "move" and minion.target_id == -1, "minion beyond its lane leash returns instead of reacquiring the same hero")
	_check(minion.goal.y >= 17.0, "leashed north minion heads back to its original lane")


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)


func _finish() -> void:
	print("Battle match: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
