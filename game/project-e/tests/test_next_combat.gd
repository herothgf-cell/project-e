extends SceneTree
## Real fixed-step contracts for cell tiers, tower reach, and attack-move orders.

const State = preload("res://scripts/battle/battle_state.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_cells()
	_test_tower_range()
	_test_visibility_sources()
	var state: Variant = _fixture()
	_check(state.has_method("command_attack_move"), "simulation exposes attack-move command")
	_check(state.has_method("is_attackable_target"), "simulation exposes shared target eligibility")
	if state.has_method("command_attack_move") and state.has_method("is_attackable_target"):
		_test_acquire_and_resume()
		_test_candidates_and_retention()
		_test_fog_and_leash()
		_test_fog_during_basic()
		_test_arrival()
		_test_replacement_and_rejection()
		_test_queues()
		_test_cc_death_reset()
	print("Next combat: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _fixture(hero: String = "bas") -> Variant:
	var state: Variant = State.new()
	state.reset(hero)
	state.bots_enabled = false
	state._next_wave = INF
	var retained: Array = [state.controlled_id]
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 1 and unit.hero == "bas":
			retained.append(unit.id)
	for id: int in state.units.keys():
		if id not in retained:
			state.units.erase(id)
	state.units[state.controlled_id].pos = Vector2(-20, 0)
	_enemy(state).pos = Vector2(-15, 0)
	return state


func _enemy(state: Variant) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.team == 1 and unit.kind == "hero":
			return unit
	return {}


func _test_cells() -> void:
	var state: Variant = _fixture()
	_enemy(state).pos = Vector2(50, 0)
	state.step(29.9)
	_check(state.units.size() == 2, "cells do not spawn before 30 seconds")
	state.step(0.1)
	var cells: Array = state.units.values().filter(func(u: Dictionary) -> bool: return u.kind == "cell")
	_check(cells.size() == 6, "first spawn creates exactly six cells at 30 seconds")
	var counts: Dictionary = {20: 0, 30: 0, 40: 0}
	for cell: Dictionary in cells:
		var expected: float = 30.0 if absf(cell.pos.x) == 24.0 else (40.0 if cell.pos.x * cell.pos.y < 0 else 20.0)
		_check(cell.has("xp_reward") and cell.has("cell_tier"), "cell publishes tier and XP fields")
		if not cell.has("xp_reward") or not cell.has("cell_tier"):
			continue
		_near(cell.xp_reward, expected, "position determines 20/30/40 cell XP")
		_check(cell.cell_tier is String and not cell.cell_tier.is_empty(), "cell tier is a nonempty String")
		counts[int(cell.xp_reward)] += 1
		_near(cell.hp, 180.0, "cell HP remains 180")
		var actor: Dictionary = state.units[state.controlled_id]
		actor.pos = cell.pos
		actor.xp = 0.0
		actor.level = 1
		var ally: Dictionary = state._entity("hero", 0, cell.pos + Vector2(0, 14), 1000, 0.45)
		var excluded: Dictionary = state._entity("hero", 0, cell.pos + Vector2(0, 14.01), 1000, 0.45)
		var credits: float = actor.credits
		state.apply_damage(actor.id, cell.id, 500, state.next_action_id())
		_near(actor.xp, expected / 2.0, "cell XP is shared among two heroes within 14m")
		_near(ally.xp, expected / 2.0, "hero exactly 14m away receives half XP")
		_near(excluded.xp, 0.0, "hero beyond 14m receives no XP")
		_near(actor.credits - credits, 5.0, "cell still shares ten credits")
		_near(cell.respawn_left, 45.0, "cell respawn stays 45 seconds")
		var tier: String = cell.cell_tier
		state._timers(cell, 45.0)
		_check(cell.alive and cell.cell_tier == tier and cell.xp_reward == expected, "cell retains XP tier after respawn")
		state.units.erase(ally.id)
		state.units.erase(excluded.id)
	_check(counts == {20: 2, 30: 2, 40: 2}, "each XP tier has exactly two cells")


func _test_visibility_sources() -> void:
	var state: Variant = _fixture()
	_check(state.has_method("is_point_visible_for_sources"), "visibility exposes shared source-filter API")
	if not state.has_method("is_point_visible_for_sources"):
		return
	var actor: Dictionary = state.units[state.controlled_id]
	var point: Vector2 = Vector2(-36, 0)
	var dead: Dictionary = state._entity("hero", 0, point, 1000, 0.45)
	dead.alive = false
	var cell: Dictionary = state._entity("cell", 2, point, 180, 0.55)
	var pin: Dictionary = state._entity("pin", 0, point, 160, 0.35)
	var hostile: Dictionary = _enemy(state)
	hostile.pos = point
	_check(not state.is_point_visible_for_sources(0, point, [dead, cell, pin, hostile]), "dead, neutral objective, allied pin and enemy sources never reveal ground")
	_check(not state.is_point_visible_for_sources(0, point, []), "empty candidate sources provide no vision")
	_check(not state.is_point_visible_for_sources(0, Vector2(NAN, 0), [actor]), "nonfinite query remains hidden in source-filter API")
	_check(state.is_point_visible_for_sources(0, actor.pos, [actor]), "live allied hero reveals its literal position")
	_check(not state.is_point_visible_for_sources(0, point, [actor]), "live allied hero cannot reveal a literal point sixteen metres away")
	for query: Vector2 in [actor.pos, point]:
		_check(state.is_point_visible(0, query) == state.is_point_visible_for_sources(0, query, state.units.values()), "ordinary visibility wrapper matches full source API")
	_check(state.is_point_visible(0, actor.pos) and not state.is_point_visible(0, point), "wrapper parity is grounded in known visible and hidden points")
	var minion: Dictionary = state._entity("minion", 0, Vector2(-40, 0), 240, 0.3)
	_check(state.is_point_visible_for_sources(0, Vector2(-32, 0), [minion]), "minion source reveals ground exactly eight metres away")
	_check(not state.is_point_visible_for_sources(0, Vector2(-31.99, 0), [minion]), "minion source cannot reveal beyond eight metres")
	actor.pos = Vector2(-4, 3)
	_check(state.is_point_visible_for_sources(0, Vector2(-4, 4), [actor]), "nearby unobstructed source remains visible")
	_check(not state.is_point_visible_for_sources(0, Vector2(-4, 13), [actor]), "wall blocks source-filter visibility inside the hero radius")


func _test_tower_range() -> void:
	for distance: float in [8.94, 8.96]:
		var state: Variant = _fixture()
		var actor: Dictionary = state.units[state.controlled_id]
		actor.pos = Vector2(-20, 0)
		var tower: Dictionary = state._entity("tower", 1, Vector2(-20 + distance, 0), 2000, 1.0)
		tower.merge({"attack_range": 8.5, "attack_damage": 180.0, "subtype": "outer"}, true)
		_enemy(state).pos = tower.pos
		state._ai.think(state)
		_check((tower.target_id == actor.id) == (distance < 8.95), "tower acquisition uses 8.5m plus victim radius")
		tower.aggro_id = -1
		state.apply_damage(actor.id, _enemy(state).id, 1, state.next_action_id())
		_check((tower.aggro_id == actor.id) == (distance < 8.95), "tower retaliation uses the same attack_range field")
	var state: Variant = State.new()
	state.reset()
	for unit: Dictionary in state.units.values():
		if unit.kind == "tower":
			_near(unit.attack_range, 8.5, "every real tower spawns with 8.5m attack range")


func _test_acquire_and_resume() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	var destination: Vector2 = Vector2(-8, 0)
	_check(state.command_attack_move(actor.id, destination), "attack-move accepts walkable destination")
	state.step(0.8)
	_check(actor.order == "attack_move" and actor.target_id == enemy.id, "attack-move acquires and retains an enemy")
	_near(actor.attack_move_goal.distance_to(destination), 0, "combat preserves separate final destination")
	state.step(1.0)
	_check(enemy.hp < enemy.max_hp and state.stats.casts == 0, "attack-move performs basic damage without automatic skills")
	state.apply_damage(actor.id, enemy.id, 10000, state.next_action_id())
	state.step(2.0)
	_check(actor.pos.distance_to(destination) < 0.1 and actor.target_id == -1, "target death resumes original destination")


func _test_candidates_and_retention() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	enemy.pos = Vector2(-14, 0)
	var cell: Dictionary = state._entity("cell", 2, Vector2(-19, 0), 180, 0.55)
	var pin: Dictionary = state._entity("pin", 1, Vector2(-19, 0), 160, 0.35)
	pin.expires = 100
	var locked: Dictionary = state._entity("tower", 1, Vector2(-18, 0), 2000, 1)
	locked.subtype = "inner"
	locked.locked = true
	var peer: Dictionary = state._entity("minion", 1, Vector2(-26, 0), 240, 0.3)
	state.command_attack_move(actor.id, Vector2(-8, 0))
	state.step(State.FIXED_STEP)
	_check(actor.target_id == enemy.id, "nearest candidate ties break by unit ID; cells, pins and locked towers excluded")
	peer.pos = actor.pos + Vector2(0.8, 0)
	state.step(0.3)
	_check(actor.target_id == enemy.id, "a closer new enemy never causes target jitter")
	_check(state.is_attackable_target(0, cell.id) and state.is_attackable_target(0, pin.id), "visible cell and enemy pin remain direct attack targets")
	_check(not state.is_attackable_target(0, locked.id) and not state.is_attackable_target(0, actor.id), "shared eligibility rejects locked structures and allies")
	_check(state.command_attack(actor.id, cell.id) and actor.order == "attack", "direct cell attack replaces attack-move")


func _test_fog_and_leash() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	state.command_attack_move(actor.id, Vector2(-30, 0))
	state.step(0.1)
	var before: Vector2 = actor.pos
	enemy.pos = Vector2(10, 0)
	state.step(State.FIXED_STEP)
	_check(actor.target_id == -1 and actor.pos.x < before.x, "fog loss immediately drops target and resumes destination, without chasing hidden latest position")
	state = _fixture()
	actor = state.units[state.controlled_id]
	enemy = _enemy(state)
	state.command_attack_move(actor.id, Vector2(-30, 0))
	var origin: Vector2 = actor.pos
	var peak: float = 0.0
	for i: int in range(180):
		enemy.pos = actor.pos + Vector2(5, 0)
		state.step(State.FIXED_STEP)
		peak = maxf(peak, actor.pos.x - origin.x)
	_check(peak <= 8.01, "finite chase never exceeds eight metres from acquisition origin")
	_check(actor.pos.x < origin.x and actor.target_id == -1, "exhausted target cannot reset chase limit by reacquiring every tick")


func _test_arrival() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	enemy.pos = Vector2(30, 0)
	state.command_attack_move(actor.id, Vector2(-18, 0))
	state.step(0.5)
	var destination: Vector2 = actor.pos
	enemy.pos = destination + Vector2(5, 0)
	state.step(0.5)
	_check(actor.pos.distance_to(destination) < 0.01 and actor.target_id == -1, "arrived attack-move never chases an out-of-range candidate")
	enemy.pos = destination + Vector2(2, 0)
	state.step(0.4)
	_check(enemy.hp < enemy.max_hp, "arrived attack-move attacks an enemy already in basic range")
	enemy.pos = destination + Vector2(5, 0)
	state.step(0.5)
	_check(actor.pos.distance_to(destination) < 0.01 and actor.target_id == -1, "arrived attack-move drops a target leaving basic range")


func _test_fog_during_basic() -> void:
	var state: Variant = _fixture("rio")
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	state.command_attack_move(actor.id, Vector2(-30, 0))
	state.step(State.FIXED_STEP)
	_check(actor.phase == "basic", "ranged attack-move begins real basic windup")
	enemy.pos = Vector2(30, 0)
	state.step(State.FIXED_STEP)
	_check(actor.target_id == -1 and actor.phase != "basic" and state.projectiles.is_empty(), "fog loss cancels an unreleased attack-move basic immediately")
	state = _fixture("rio")
	actor = state.units[state.controlled_id]
	enemy = _enemy(state)
	state.command_attack_move(actor.id, Vector2(-30, 0))
	state.step(0.2)
	_check(not state.projectiles.is_empty(), "visible ranged basic releases a real projectile")
	enemy.pos = Vector2(30, 0)
	state.step(State.FIXED_STEP)
	_check(actor.target_id == -1 and not state.projectiles.is_empty(), "fog drops attack-move target without deleting an already fired projectile")
	if not state.projectiles.is_empty():
		_check(state.projectiles[0].target_pos == enemy.pos, "already fired basic projectile preserves existing internal tracking contract")


func _test_replacement_and_rejection() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	state.command_attack_move(actor.id, Vector2(-30, 0))
	var old_goal: Vector2 = actor.attack_move_goal
	_check(not state.command_attack_move(actor.id, Vector2(NAN, 0)), "nonfinite attack-move rejected")
	_check(not state.command_move(actor.id, Vector2(0, 9)), "terrain-invalid move rejected")
	_check(not state.command_attack(actor.id, actor.id), "friendly attack rejected")
	_check(not state.command_cast(actor.id, "R", actor.pos), "locked skill rejected")
	_check(actor.order == "attack_move" and actor.attack_move_goal == old_goal, "rejected commands preserve previous attack-move")
	_check(state.command_move(actor.id, Vector2(-25, 0)) and actor.order == "move", "ordinary movement replaces attack-move")
	state.command_attack_move(actor.id, Vector2(-30, 0))
	state.command_stop(actor.id)
	_check(actor.order == "idle" and actor.path.is_empty() and actor.target_id == -1, "stop clears attack-move intent and target")
	state.command_attack_move(actor.id, Vector2(-30, 0))
	_check(state.command_cast(actor.id, "W", actor.pos) and actor.order == "idle", "accepted cast replaces attack-move")
	state.step(0.8)
	_check(actor.order == "idle", "completed cast never resurrects replaced attack-move")


func _test_queues() -> void:
	for skill: String in ["W", "E"]:
		var phase_state: Variant = _fixture()
		var phase_actor: Dictionary = phase_state.units[phase_state.controlled_id]
		phase_state.command_cast(phase_actor.id, skill, phase_actor.pos + Vector2(-3, 0))
		for i: int in range(20):
			if phase_actor.phase == ("recovery" if skill == "W" else "dash"):
				break
			phase_state.step(State.FIXED_STEP)
		_check(phase_actor.phase == ("recovery" if skill == "W" else "dash"), "real skill reaches " + skill + " queue phase")
		_check(phase_state.command_attack_move(phase_actor.id, Vector2(-30, 0)), "attack-move accepted in " + phase_actor.phase)
		_check(phase_actor.queued.get("type", "") == "attack_move", "active skill queues attack-move without interruption")
		phase_state.command_stop(phase_actor.id)
		phase_state.step(0.8)
		_check(phase_actor.order == "idle" and phase_actor.queued.is_empty(), "latest stop replaces queued attack-move in " + skill)
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	_check(state.command_cast(actor.id, "W", actor.pos), "queue fixture starts real skill windup")
	state.command_attack_move(actor.id, Vector2(-30, 0))
	_check(actor.queued.get("type", "") == "attack_move", "attack-move queues during skill windup")
	state.command_move(actor.id, Vector2(-25, 0))
	_check(actor.queued.get("type", "") == "move", "new valid move replaces queued attack-move")
	state.command_attack_move(actor.id, Vector2(-28, 0))
	_check(not state.command_attack_move(actor.id, Vector2(0, 9)), "invalid latest queued attack-move rejected")
	_check(actor.queued.get("target", Vector2.ZERO) == Vector2(-28, 0), "rejected queued input preserves latest valid destination")
	state.step(0.8)
	_check(actor.order == "attack_move" and actor.attack_move_goal == Vector2(-28, 0), "latest queued attack-move executes after recovery")
	state = _fixture()
	actor = state.units[state.controlled_id]
	_enemy(state).pos = actor.pos + Vector2(2, 0)
	state.command_attack(actor.id, _enemy(state).id)
	state.step(State.FIXED_STEP)
	_check(actor.phase == "basic", "replacement fixture reaches real basic windup")
	state.command_cast(actor.id, "W", actor.pos)
	state.command_attack_move(actor.id, Vector2(-30, 0))
	_check(actor.phase == "idle" and actor.queued.is_empty(), "attack-move cancels basic windup and supersedes queued skill")
	state.step(0.5)
	_check(actor.cooldowns.W == 0.0, "superseded queued skill never executes")


func _test_cc_death_reset() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	_enemy(state).pos = Vector2(30, 0)
	state.command_attack_move(actor.id, Vector2(-30, 0))
	var start: Vector2 = actor.pos
	state.apply_cc(actor.id, "root", 0.5)
	_check(not state.command_attack_move(actor.id, Vector2(-25, 0)), "root rejects new movement intent")
	state.step(0.3)
	_check(actor.pos == start and actor.order == "attack_move", "root pauses existing attack-move without erasing destination")
	state.step(0.5)
	_check(actor.pos.x < start.x, "attack-move resumes after root ends")
	state.apply_cc(actor.id, "stun", 0.5)
	start = actor.pos
	_check(not state.command_attack_move(actor.id, Vector2(-25, 0)), "stun rejects new attack-move")
	state.step(0.2)
	_check(actor.pos == start, "stun pauses attack-move")
	state.step(0.6)
	_check(actor.pos.x < start.x, "attack-move resumes after stun ends")
	state.apply_damage(_enemy(state).id, actor.id, 10000, state.next_action_id())
	_check(not actor.alive and actor.order == "idle" and actor.target_id == -1 and actor.path.is_empty(), "death clears attack-move order and destination path")
	_check(not state.command_attack_move(actor.id, Vector2(-30, 0)), "dead hero rejects attack-move")
	state.step(actor.respawn_left + 0.1)
	_check(actor.alive and actor.order == "idle" and actor.path.is_empty(), "respawn never resurrects stale attack-move")
	state.reset()
	actor = state.units[state.controlled_id]
	_check(actor.order == "idle" and actor.queued.is_empty(), "match reset clears movement and queued intent")
	state.winner = 0
	_check(not state.command_attack_move(actor.id, Vector2(-30, 0)), "finished match rejects attack-move")


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.02, "%s: expected %.3f, got %.3f" % [label, expected, actual])


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
