extends SceneTree

const StateScript: Script = preload("res://scripts/battle/battle_state.gd")

var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	print("MINION_AUDIT_ENGINE ", Engine.get_version_info())
	_reserve_scope()
	_one_hp_attacker()
	_tower_and_siege_ranges()
	_single_wave_tower(0.0, false, false)
	_single_wave_tower(0.0, true, false)
	_single_wave_tower(0.0, true, true)
	_single_wave_tower(721.0, true, false)
	_ordinary_lane_with_siege_cadence()
	_parked_one_hp_units()
	_reward_sharing_at_level_cap()
	print("Minion audit isolated probes: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _fixture() -> Variant:
	var state: Variant = StateScript.new()
	state.reset("bas")
	state.bots_enabled = false
	state._next_wave = INF
	state._next_income = INF
	state._cells_spawned = true
	state.units.clear()
	state.controlled_id = -1
	return state

func _minion(state: Variant, team: int, subtype: String, position: Vector2, hp: float = 240.0) -> Dictionary:
	var values: Array = {"melee": [20.0, 1.5, 1.0, 20.0, 12.0], "ranged": [25.0, 6.0, 1.2, 20.0, 12.0], "siege": [45.0, 7.5, 1.5, 35.0, 20.0]}[subtype]
	var unit: Dictionary = state._entity("minion", team, position, hp, 0.45 if subtype == "siege" else 0.3)
	unit.merge({"subtype": subtype, "lane": 1, "speed": 3.2, "attack_damage": values[0], "attack_range": values[1], "attack_interval": values[2], "reward_xp": values[3], "reward_credits": values[4]}, true)
	return unit

func _tower(state: Variant, position: Vector2) -> Dictionary:
	var tower: Dictionary = state._entity("tower", 1, position, 2000.0, 1.0)
	tower.merge({"subtype": "outer", "lane": 1, "attack_range": 8.5, "attack_damage": 180.0, "attack_windup": 0.1}, true)
	return tower

func _reserve_scope() -> void:
	for kind: String in ["hero", "minion", "tower", "core", "cell", "pin"]:
		var state: Variant = _fixture()
		var actor: Dictionary = _minion(state, 0, "melee", Vector2.ZERO)
		var target: Dictionary = state._entity(kind, 1, Vector2(1.0, 0.0), 5.0, 0.3)
		var damage: float = state.apply_damage(actor.id, target.id, 1000.0, state.next_action_id())
		_check(target.alive and target.hp == 1.0 and damage == 4.0, "reserve applies to " + kind)
		print("RESERVE kind=%s hp=%.1f damage=%.1f" % [kind, target.hp, damage])

func _one_hp_attacker() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _minion(state, 0, "melee", Vector2(-1.0, 0.0))
	actor.hp = 1.0
	var victim: Dictionary = _minion(state, 1, "melee", Vector2.ZERO)
	var dealt: float = state.apply_damage(actor.id, victim.id, actor.attack_damage, state.next_action_id())
	_check(dealt == 20.0 and victim.hp == 220.0, "one-HP ordinary unit keeps full damage")
	_check(state.is_point_visible(0, Vector2(-8.9, 0.0)), "one-HP unit keeps vision")
	_check(state.has_siege_minion(0, Vector2(10.9, 0.0)), "one-HP ordinary unit removes structure protection")
	print("ONE_HP damage=%.1f victim_hp=%.1f vision=%s siege_support=%s" % [dealt, victim.hp, state.is_point_visible(0, Vector2(-8.9, 0.0)), state.has_siege_minion(0, Vector2(10.9, 0.0))])

func _tower_and_siege_ranges() -> void:
	var state: Variant = _fixture()
	var tower: Dictionary = _tower(state, Vector2(10.0, 3.5))
	var siege: Dictionary = _minion(state, 0, "siege", Vector2(1.3, 3.5), 480.0)
	_check(state._basic_in_range(tower, siege), "tower reaches siege at 8.7m")
	_check(not state._basic_in_range(siege, tower), "siege cannot reach tower at 8.7m")
	state._ai._minion(state, siege)
	_check(siege.target_id == -1, "siege acquisition radius is only 8m")
	siege.pos = Vector2(1.7, 3.5)
	state._visibility_cache.clear()
	_check(state._basic_in_range(siege, tower), "siege basic reaches tower at 8.3m")
	state._ai._minion(state, siege)
	_check(siege.target_id == -1, "siege does not acquire otherwise reachable tower outside 8m")
	print("RANGE tower_to_siege=8.95 siege_to_tower=8.50 siege_acquisition=8.00")

func _single_wave_tower(spawn_time: float, with_siege: bool, depleted: bool) -> void:
	var state: Variant = _fixture()
	state.time = spawn_time
	state._next_ai = spawn_time
	state._next_cleanup = spawn_time + 1.0
	state._wave = 3 if with_siege else 0
	state._spawn_wave()
	var squad: Array = []
	for unit: Dictionary in state.units.values():
		if unit.kind == "minion" and unit.team == 0 and unit.lane == 1:
			squad.append(unit)
		else:
			state.units.erase(unit.id)
	for i: int in range(squad.size()):
		squad[i].pos = Vector2(-0.6 * i, 0.0)
		if depleted and squad[i].subtype != "siege":
			squad[i].hp = 1.0
	var tower: Dictionary = _tower(state, Vector2(10.0, 3.5))
	var first_tower_hit: float = -1.0
	var wave_cleared: float = -1.0
	for tick: int in range(30 * 25):
		state.step(1.0 / 30.0)
		if first_tower_hit < 0.0 and tower.hp < tower.max_hp:
			first_tower_hit = state.time - spawn_time
		var alive: int = 0
		for unit: Dictionary in squad:
			if unit.alive:
				alive += 1
		if alive == 0:
			wave_cleared = state.time - spawn_time
			break
	_check(wave_cleared > 0.0, "one tower clears isolated wave within 25s")
	print("WAVE_TOWER spawn=%.0f siege=%s regular_one_hp=%s first_tower_damage=%.3f wave_clear=%.3f tower_damage=%.1f tower_hp=%.1f" % [spawn_time, with_siege, depleted, first_tower_hit, wave_cleared, tower.max_hp - tower.hp, tower.hp])

func _ordinary_lane_with_siege_cadence() -> void:
	var state: Variant = _fixture()
	state.time = 20.0
	state._next_ai = 20.0
	state._next_cleanup = 21.0
	var total_spawned: int = 0
	for wave: int in range(5):
		state._spawn_wave()
		for unit: Dictionary in state.units.values():
			if unit.lane != 1:
				state.units.erase(unit.id)
		total_spawned += 10 if (wave + 1) % 4 == 0 else 8
		state.step(18.0)
		var living: int = 0
		var one_hp: int = 0
		var siege: int = 0
		var endpoint: int = 0
		for unit: Dictionary in state.units.values():
			if not unit.alive:
				continue
			living += 1
			if unit.hp <= 1.0:
				one_hp += 1
			if unit.subtype == "siege":
				siege += 1
			if absf(unit.pos.x) >= 46.4:
				endpoint += 1
		if wave < 3:
			_check(living == total_spawned, "ordinary-only waves cause no minion deaths")
		print("ISOLATED_LANE time=%.1f spawned=%d alive=%d one_hp=%d siege=%d endpoint=%d deaths=%d" % [state.time, total_spawned, living, one_hp, siege, endpoint, total_spawned - living])

func _parked_one_hp_units() -> void:
	var state: Variant = _fixture()
	var core: Dictionary = state._entity("core", 1, Vector2(50.0, 0.0), 4000.0, 2.0)
	core.hp = 1.0
	core.locked = false
	for wave: int in range(4):
		for i: int in range(4):
			var unit: Dictionary = _minion(state, 0, "melee" if i < 3 else "ranged", Vector2(43.0 - 0.6 * i, 0.0))
			unit.hp = 1.0
		state.step(18.0)
		var living: int = 0
		var at_endpoint: int = 0
		for unit: Dictionary in state.units.values():
			if unit.kind == "minion" and unit.alive:
				living += 1
				if unit.pos.distance_to(Vector2(46.5, 0.0)) < 0.05:
					at_endpoint += 1
		_check(living == 4 * (wave + 1), "untouched depleted units persist across 18s intervals")
		print("PARKED time=%.1f minions=%d endpoint=%d core_hp=%.1f support=%s" % [state.time, living, at_endpoint, core.hp, state.has_siege_minion(0, core.pos)])

func _reward_sharing_at_level_cap() -> void:
	var state: Variant = _fixture()
	var capped: Dictionary = state._entity("hero", 0, Vector2(-1.0, 0.0), 1000.0, 0.45)
	capped.level = 12
	capped.hero = "bas"
	var learner: Dictionary = state._entity("hero", 0, Vector2(-2.0, 0.0), 1000.0, 0.45)
	learner.hero = "bas"
	var target: Dictionary = _minion(state, 1, "melee", Vector2.ZERO)
	state.apply_damage(capped.id, target.id, 1000.0, state.next_action_id())
	_check(learner.xp == 10.0 and capped.xp == 0.0, "capped hero remains in XP sharing denominator")
	_check(capped.credits == 10.0 and learner.credits == 6.0, "credits split then killer receives four bonus")
	print("REWARD capped_xp=%.1f learner_xp=%.1f capped_credits=%.1f learner_credits=%.1f" % [capped.xp, learner.xp, capped.credits, learner.credits])

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
