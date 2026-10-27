extends RefCounted
## Deterministic local decisions; actors submit the same commands as the player.


func think(state: Variant) -> void:
	for actor: Dictionary in state.units.values():
		if not actor.alive:
			continue
		if actor.order == "attack_move":
			continue
		match actor.kind:
			"tower": _tower(state, actor)
			"minion": _minion(state, actor)
			"hero":
				if state.bots_enabled and actor.id != state.controlled_id:
					_hero(state, actor)


func _available(state: Variant, actor: Dictionary, target: Dictionary, reach: float) -> bool:
	return target.alive and target.team != actor.team and target.team < 2 and not target.locked and actor.pos.distance_squared_to(target.pos) <= reach * reach and state.is_visible(actor.team, target.id)


func _tower(state: Variant, actor: Dictionary) -> void:
	var target: Dictionary = {}
	if actor.aggro_until > state.time and state.units.has(actor.aggro_id):
		var aggressor: Dictionary = state.units[actor.aggro_id]
		if _available(state, actor, aggressor, actor.attack_range + aggressor.radius) and state.map.has_line_of_sight(actor.pos, aggressor.pos):
			target = aggressor
	if target.is_empty():
		var best: float = INF
		for candidate: Dictionary in state.units.values():
			if candidate.kind not in ["minion", "hero"] or not _available(state, actor, candidate, actor.attack_range + candidate.radius) or not state.map.has_line_of_sight(actor.pos, candidate.pos):
				continue
			var score: float = actor.pos.distance_squared_to(candidate.pos) + (1000.0 if candidate.kind == "hero" else 0.0)
			# Preserve a valid target among units of the same priority.
			if actor.target_id == candidate.id:
				score -= 100.0
			if score < best:
				best = score
				target = candidate
	if not target.is_empty():
		if actor.target_id != target.id or actor.order != "attack":
			state.command_attack(actor.id, target.id)
	elif actor.order == "attack":
		state.command_stop(actor.id)


func _minion(state: Variant, actor: Dictionary) -> void:
	if actor.phase in ["basic", "windup", "dash", "recovery"] or actor.stun_left > 0.0:
		return
	if actor.get("returning_to_lane", false):
		if _lane_distance(state, actor) > 0.6:
			_advance_lane(state, actor)
			return
		actor.returning_to_lane = false
	var target: Dictionary = state.units.get(actor.target_id, {})
	if not target.is_empty():
		var chase_origin: Vector2 = actor.get("chase_origin", actor.pos)
		var too_far: bool = actor.pos.distance_to(chase_origin) > 8.0 or _lane_distance(state, actor) > 6.0
		if not target.alive or target.locked or too_far or (not state.is_visible(actor.team, target.id) and state.time - actor.last_seen > 1.0):
			state.command_stop(actor.id)
			target = {}
			if too_far:
				actor.returning_to_lane = true
				_advance_lane(state, actor)
				return
	if target.is_empty():
		var best: float = INF
		for candidate: Dictionary in state.units.values():
			if candidate.kind not in ["minion", "hero", "tower", "core"] or not _available(state, actor, candidate, 8.0):
				continue
			var rank: int = 0 if candidate.kind == "minion" else (1 if candidate.kind == "hero" else 2)
			var score: float = rank * 1000.0 + actor.pos.distance_squared_to(candidate.pos)
			if score < best:
				best = score
				target = candidate
		if not target.is_empty():
			actor.chase_origin = actor.pos
			state.command_attack(actor.id, target.id)
	if target.is_empty():
		_advance_lane(state, actor)


func _lane_distance(state: Variant, actor: Dictionary) -> float:
	var nearest: float = INF
	var path: Array = state.map.lane_paths[actor.lane]
	for index: int in range(path.size() - 1):
		nearest = minf(nearest, state.map.segment_distance(actor.pos, path[index], path[index + 1]))
	return nearest


func _progress(state: Variant, actor: Dictionary, position: Vector2) -> float:
	var path: Array = state.map.lane_paths[actor.lane].duplicate()
	if actor.team == 1:
		path.reverse()
	var nearest: float = INF
	var progress: float = 0.0
	var total: float = 0.0
	for index: int in range(path.size() - 1):
		var point: Vector2 = Geometry2D.get_closest_point_to_segment(position, path[index], path[index + 1])
		var distance: float = position.distance_squared_to(point)
		if distance < nearest:
			nearest = distance
			progress = total + path[index].distance_to(point)
		total += path[index].distance_to(path[index + 1])
	return progress


func _advance_lane(state: Variant, actor: Dictionary) -> void:
	var progress: float = _progress(state, actor, actor.pos)
	var goal_progress: float = minf(96.5 if actor.lane == 1 else 108.5, progress + 5.0)
	if actor.kind == "hero":
		for structure: Dictionary in state.units.values():
			if structure.team == actor.team or not structure.alive or structure.kind != "tower" or structure.lane != actor.lane:
				continue
			if not state.has_siege_minion(actor.team, structure.pos):
				goal_progress = minf(goal_progress, _progress(state, actor, structure.pos) - (structure.attack_range + 2.0))
	var goal: Vector2 = state.map.lane_point(actor.lane, maxf(3.5, goal_progress), actor.team)
	if actor.pos.distance_to(goal) > 0.25 and (actor.order != "move" or actor.goal.distance_to(goal) > 1.5 or actor.path.is_empty()):
		state.command_move(actor.id, goal)


func _hero(state: Variant, actor: Dictionary) -> void:
	_spend_points(state, actor)
	if actor.phase in ["basic", "windup", "dash", "recovery"] or actor.stun_left > 0.0:
		return
	if actor.hp < actor.max_hp * 0.35:
		actor.ai_retreat = true
	if actor.ai_retreat:
		if actor.hp >= actor.max_hp * 0.85:
			actor.ai_retreat = false
		else:
			var base: Vector2 = state.map.spawn_points[actor.team] + Vector2(0, (1 - actor.lane) * 2.0)
			if actor.shield < 1.0:
				if actor.hero == "bas" and _cast(state, actor, "W", actor.pos):
					return
				if actor.hero == "nema" and _cast(state, actor, "E", base):
					return
			if actor.pos.distance_to(base) > 5.0 and actor.hero in ["bas", "rio"] and _cast(state, actor, "E", base):
				return
			if actor.order != "move" or actor.goal.distance_to(base) > 0.1:
				state.command_move(actor.id, base)
			return
	var target: Dictionary = {}
	var best: float = INF
	for candidate: Dictionary in state.units.values():
		if candidate.kind not in ["hero", "minion", "tower", "core"] or not _available(state, actor, candidate, 12.0):
			continue
		if candidate.kind in ["tower", "core"] and not state.has_siege_minion(actor.team, candidate.pos):
			continue
		var distance: float = actor.pos.distance_to(candidate.pos)
		var rank: float = 0.0 if candidate.kind == "hero" and distance < 7.0 else (20.0 if candidate.kind == "minion" else 40.0)
		var score: float = distance + rank
		if score < best:
			best = score
			target = candidate
	if target.is_empty():
		_advance_lane(state, actor)
		return
	# Do not pursue a hero into unsupported tower range.
	if _unsafe_tower(state, actor, target.pos) and actor.pos.distance_to(target.pos) > actor.attack_range + target.radius:
		_advance_lane(state, actor)
		return
	if _hero_skill(state, actor, target):
		return
	if actor.target_id != target.id or actor.order != "attack":
		state.command_attack(actor.id, target.id)


func _cast(state: Variant, actor: Dictionary, slot: String, point: Vector2) -> bool:
	if actor.cooldowns[slot] > 0.00001 or (slot == "R" and not actor.r_unlocked):
		return false
	return state.command_cast(actor.id, slot, point)


func _hero_skill(state: Variant, actor: Dictionary, target: Dictionary) -> bool:
	var distance: float = actor.pos.distance_to(target.pos)
	if actor.hero == "bas":
		if actor.pressure >= 2 and target.kind == "hero" and distance <= actor.attack_range + target.radius:
			return false
		if actor.hp < actor.max_hp * 0.72 and actor.shield < 1.0 and _cast(state, actor, "W", actor.pos):
			return true
		if target.kind == "hero" and distance > 3.0 and distance < 6.0 and not _unsafe_tower(state, actor, target.pos) and _cast(state, actor, "E", target.pos):
			return true
		if distance <= 3.2 + target.radius and _cast(state, actor, "Q", target.pos):
			return true
		if target.kind == "hero" and distance <= 7.0 and _cast(state, actor, "R", target.pos):
			return true
	elif actor.hero == "rio":
		if target.kind == "hero" and distance < 3.0 and _cast(state, actor, "E", actor.pos + (actor.pos - target.pos).normalized() * 3.2):
			return true
		if distance <= 8.0 + target.radius and _cast(state, actor, "Q", target.pos):
			return true
		if target.kind == "hero" and distance >= 2.0 and distance <= 7.0 and _cast(state, actor, "R", target.pos):
			return true
		if distance <= 5.0 and _cast(state, actor, "W", target.pos):
			return true
	else:
		if actor.hp < actor.max_hp * 0.75 and actor.shield < 1.0 and _cast(state, actor, "E", target.pos):
			return true
		for slot: String in ["R", "W"]:
			var preview: Dictionary = state.get_cast_preview(actor.id, slot, target.pos)
			if preview.valid and state._abilities.contains(preview, target.pos, target.radius) and _cast(state, actor, slot, target.pos):
				return true
		if distance <= 6.8:
			var toward: Vector2 = (target.pos - actor.pos).normalized()
			for offset: float in [-1.1, 1.1, -2.2]:
				var point: Vector2 = target.pos + toward * offset
				if target.kind in ["tower", "core"]:
					point = target.pos - toward * (target.radius + 0.6)
				if _cast(state, actor, "Q", point):
					return true
	return false


func _unsafe_tower(state: Variant, actor: Dictionary, point: Vector2) -> bool:
	for tower: Dictionary in state.units.values():
		if tower.kind == "tower" and tower.alive and tower.team != actor.team and point.distance_to(tower.pos) < tower.attack_range + 0.5 and not state.has_siege_minion(actor.team, tower.pos):
			return true
	return false


func _spend_points(state: Variant, actor: Dictionary) -> void:
	if actor.points <= 0:
		return
	if actor.level >= 3 and not actor.r_unlocked:
		state.invest(actor.id, "R")
	var priorities: Array = ["hp", "power", "armor", "regen", "speed"] if actor.hero == "bas" else ["power", "hp", "regen", "armor", "speed"]
	while actor.points > 0:
		var spent: bool = false
		for allowance: int in range(1, 6):
			for stat: String in priorities:
				if actor.investments[stat] < allowance and state.invest(actor.id, stat):
					spent = true
					break
			if spent:
				break
		if not spent:
			break
