extends "res://scripts/battle/battle_ai.gd"
## Optional playable policy layered on the same authority commands as legacy AI.
## All non-public target selection is gated by current team observation.
const CELL_RADIUS: float = 12.0
const SUPPORT_RADIUS: float = 18.0
const TASK_LIFE: float = 8.0
const REST_TIME: float = 6.0

func _hero(state: Variant, actor: Dictionary) -> void:
	# Respawn reuses the hero dictionary. A task belongs to a life, not the ID.
	var deaths: int = int(actor.deaths)
	if int(actor.get("objective_deaths", deaths)) != deaths:
		actor.objective_kind = ""
		actor.objective_id = -1
		actor.objective_until = 0.0
		actor.objective_cooldown = state.time + REST_TIME
		actor.erase("objective_return")
	actor.objective_deaths = deaths
	_spend_points(state, actor)
	if actor.phase in ["basic", "windup", "dash", "recovery"] or actor.stun_left > 0.0:
		return
	if actor.hp < actor.max_hp * 0.35 or actor.ai_retreat:
		actor.objective_kind = ""
		actor.objective_id = -1
		actor.objective_cooldown = state.time + REST_TIME
		super._hero(state, actor)
		return
	var defense: Dictionary = _core_threat(state, actor)
	if not defense.is_empty():
		if actor.get("objective_kind", "") != "defend" or int(actor.get("objective_id", -1)) != int(defense.id):
			_begin(state, actor, defense, "defend")
		_follow_task(state, actor)
		return
	var kind: String = str(actor.get("objective_kind", ""))
	if kind == "return":
		_return_home(state, actor)
		return
	if not kind.is_empty():
		_follow_task(state, actor)
		return
	if _near_enemy(state, actor, 7.0) or state.time < float(actor.get("objective_cooldown", 0.0)):
		super._hero(state, actor)
		return
	var support: Dictionary = _support_target(state, actor)
	if not support.is_empty():
		_begin(state, actor, support, "support")
		_follow_task(state, actor)
		return
	if actor.hp >= actor.max_hp * 0.65 and not _lane_pressure(state, actor):
		var cell: Dictionary = _best_cell(state, actor)
		if not cell.is_empty():
			_begin(state, actor, cell, "cell")
			_follow_task(state, actor)
			return
	super._hero(state, actor)

func _begin(state: Variant, actor: Dictionary, target: Dictionary, kind: String) -> void:
	if str(actor.get("objective_kind", "")).is_empty():
		actor.objective_return = _home_lane_point(state, actor)
	actor.objective_kind = kind
	actor.objective_id = target.id
	actor.objective_until = state.time + TASK_LIFE
	var stat_key: String = "objective_" + kind
	state.stats[stat_key] = int(state.stats.get(stat_key, 0)) + 1

func _abort(state: Variant, actor: Dictionary) -> void:
	state.command_stop(actor.id)
	actor.objective_kind = "return"
	actor.objective_id = -1
	actor.objective_cooldown = state.time + REST_TIME
	_return_home(state, actor)

func _follow_task(state: Variant, actor: Dictionary) -> void:
	var id: int = int(actor.get("objective_id", -1))
	if state.time >= float(actor.get("objective_until", 0)) or not state.units.has(id) or not state.is_visible(actor.team, id):
		_abort(state, actor)
		return
	var target: Dictionary = state.units[id]
	var kind: String = str(actor.get("objective_kind", ""))
	if not target.alive or target.locked or (kind == "cell" and (actor.hp < actor.max_hp * 0.6 or _near_enemy(state, actor, 10.0))):
		_abort(state, actor)
		return
	if _unsafe_tower(state, actor, target.pos):
		_abort(state, actor)
		return
	if kind != "cell" and _hero_skill(state, actor, target):
		return
	if actor.target_id != id or actor.order != "attack":
		if not state.command_attack(actor.id, id):
			_abort(state, actor)

func _return_home(state: Variant, actor: Dictionary) -> void:
	var point: Vector2 = actor.get("objective_return", _home_lane_point(state, actor))
	if actor.pos.distance_to(point) < 0.8:
		actor.objective_kind = ""
		actor.objective_cooldown = state.time + REST_TIME
		state.command_stop(actor.id)
		return
	if _near_enemy(state, actor, 5.0):
		super._hero(state, actor)
		return
	if actor.order != "move" or actor.goal.distance_to(point) > 0.5:
		if not state.command_move(actor.id, point):
			actor.objective_kind = ""
			_advance_lane(state, actor)

func _home_lane_point(state: Variant, actor: Dictionary) -> Vector2:
	var nearest: Vector2 = actor.pos
	var best: float = INF
	var path: Array = state.map.lane_paths[actor.lane]
	for i: int in range(path.size() - 1):
		var point: Vector2 = Geometry2D.get_closest_point_to_segment(actor.pos, path[i], path[i + 1])
		if point.distance_squared_to(actor.pos) < best and state.map.is_walkable(point, actor.radius):
			nearest = point
			best = point.distance_squared_to(actor.pos)
	return nearest

func _near_enemy(state: Variant, actor: Dictionary, radius: float) -> bool:
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team != actor.team and state.is_visible(actor.team, unit.id) and unit.alive and actor.pos.distance_squared_to(unit.pos) <= radius * radius:
			return true
	return false

func _lane_pressure(state: Variant, actor: Dictionary) -> bool:
	if _near_enemy(state, actor, 10.0):
		return true
	for unit: Dictionary in state.units.values():
		if unit.kind == "minion" and unit.team != actor.team and state.is_visible(actor.team, unit.id) and unit.alive and int(unit.lane) == int(actor.lane) and actor.pos.distance_squared_to(unit.pos) < 49.0:
			return true
	return false

func _reserved(state: Variant, actor: Dictionary, id: int) -> bool:
	for ally: Dictionary in state.units.values():
		if ally.kind == "hero" and ally.team == actor.team and ally.alive and ally.id != actor.id and int(ally.get("objective_id", -1)) == id and state.time < float(ally.get("objective_until", 0)):
			return true
	return false

func _route_cost(state: Variant, actor: Dictionary, goal: Vector2) -> float:
	if not state.map.is_walkable(goal, actor.radius):
		return INF
	var route: Array = state.map.find_path(actor.pos, goal)
	if route.is_empty():
		return INF
	var cost: float = 0.0
	var cursor: Vector2 = actor.pos
	for next: Vector2 in route:
		var length: float = cursor.distance_to(next)
		var steps: int = maxi(1, ceili(length))
		for index: int in range(steps + 1):
			if _unsafe_tower(state, actor, cursor.lerp(next, float(index) / steps)):
				return INF
		cost += length
		cursor = next
	return cost

func _best_cell(state: Variant, actor: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var score: float = -INF
	for unit: Dictionary in state.units.values():
		if unit.kind != "cell" or not state.is_visible(actor.team, unit.id):
			continue
		if not unit.alive or actor.pos.distance_squared_to(unit.pos) > CELL_RADIUS * CELL_RADIUS or _reserved(state, actor, unit.id):
			continue
		var cost: float = _route_cost(state, actor, unit.pos)
		if cost > 22.0:
			continue
		var value: float = float(unit.get("xp_reward", 30)) / (2.0 + cost)
		if value > score:
			score = value
			best = unit
	return best

func _support_target(state: Variant, actor: Dictionary) -> Dictionary:
	var best: Dictionary = {}
	var best_cost: float = INF
	for foe: Dictionary in state.units.values():
		if foe.kind != "hero" or foe.team == actor.team or not state.is_visible(actor.team, foe.id):
			continue
		if not foe.alive or actor.pos.distance_to(foe.pos) > SUPPORT_RADIUS or _reserved(state, actor, foe.id):
			continue
		var aided: bool = false
		for ally: Dictionary in state.units.values():
			if ally.kind == "hero" and ally.team == actor.team and ally.alive and ally.id != actor.id and ally.pos.distance_squared_to(foe.pos) < 49.0:
				aided = true
				break
		if not aided:
			continue
		var cost: float = _route_cost(state, actor, foe.pos)
		if cost < best_cost and cost <= 26.0:
			best_cost = cost
			best = foe
	return best

func _core_threat(state: Variant, actor: Dictionary) -> Dictionary:
	for core: Dictionary in state.units.values():
		if core.kind != "core" or core.team != actor.team or not core.alive or core.locked or actor.pos.distance_to(core.pos) > 26.0:
			continue
		for foe: Dictionary in state.units.values():
			if foe.kind not in ["hero", "minion"] or foe.team == actor.team or not state.is_visible(actor.team, foe.id):
				continue
			if foe.alive and foe.pos.distance_squared_to(core.pos) < 100.0 and _route_cost(state, actor, foe.pos) < 30.0:
				return foe
	return {}
