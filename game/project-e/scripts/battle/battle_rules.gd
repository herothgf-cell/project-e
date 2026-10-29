extends RefCounted
## One damage/CC/reward authority for human commands, bots and projectiles.


func damage(state: Variant, source_id: int, target_id: int, raw: float, cast_id: int, stage: String) -> float:
	if state.winner != -1 or not state.units.has(source_id) or not state.units.has(target_id) or not is_finite(raw) or raw <= 0.0:
		return 0.0
	var source: Dictionary = state.units[source_id]
	var target: Dictionary = state.units[target_id]
	if not target.alive or source.team == target.team or target.locked or target.protected > 0.0:
		return 0.0
	var key: String = "%d:%s" % [cast_id, stage]
	if not state.hit_registry.has(key):
		state.hit_registry[key] = {"targets": {}, "expires": state.time + 12.0}
	if state.hit_registry[key].targets.has(target_id):
		return 0.0
	state.hit_registry[key].targets[target_id] = true
	var amount: float = maxf(0.0, raw) * 100.0 / (100.0 + maxf(0.0, target.armor))
	if target.kind == "tower" or target.kind == "core":
		if source.kind == "hero" or source.kind == "pin":
			amount *= 0.5
		if not state.has_siege_minion(source.team, target.pos):
			amount *= 0.3
	var applied: float = minf(amount, target.hp + target.shield)
	var left: float = amount
	target.shields.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return a.expires < b.expires if a.expires != b.expires else a.order < b.order)
	for shield: Dictionary in target.shields:
		var absorbed: float = minf(left, shield.amount)
		shield.amount -= absorbed
		left -= absorbed
		if left <= 0.0:
			break
	target.hp = maxf(0.0, target.hp - left)
	sync_shield(target)
	if applied <= 0.0:
		return 0.0
	state.stats.damage += applied
	target.last_damage = state.time
	var owner_id: int = int(source.get("owner_id", source_id))
	var owner: Dictionary = state.units.get(owner_id, source)
	if target.hp > 0.0:
		state._consumables.interrupt_patch(state, target, owner)
	if owner.kind == "hero" and target.kind == "hero":
		owner.last_hostile = state.time
		target.contributors[owner.id] = state.time
		for tower: Dictionary in state.units.values():
			if tower.kind == "tower" and tower.alive and tower.team == target.team and tower.pos.distance_to(owner.pos) <= tower.attack_range + owner.radius:
				tower.aggro_id = owner.id
				tower.aggro_until = state.time + 3.0
	if target.team == 0 or state.is_visible(0, target_id):
		state.log_event("damage", "%s -%d" % [target.name, roundi(applied)], {"target_id": target_id, "owner_id": owner_id, "amount": applied})
	if target.hp <= 0.0:
		_kill(state, target, owner, source.team)
	return applied


func add_shield(state: Variant, target_id: int, source: String, amount: float, duration: float) -> void:
	if not state.units.has(target_id) or amount <= 0.0 or duration <= 0.0:
		return
	var unit: Dictionary = state.units[target_id]
	if not unit.alive or unit.kind != "hero":
		return
	for shield: Dictionary in unit.shields:
		if shield.source == source:
			shield.amount = maxf(shield.amount, amount)
			shield.expires = state.time + duration
			sync_shield(unit)
			return
	unit.shields.append({"source": source, "amount": amount, "expires": state.time + duration, "order": state.next_action_id()})
	sync_shield(unit)


func sync_shield(unit: Dictionary) -> void:
	unit.shield = 0.0
	for shield: Dictionary in unit.shields:
		unit.shield += maxf(0.0, shield.amount)


func cc(state: Variant, target_id: int, kind: String, duration: float, strength: float = 0.0) -> float:
	if not state.units.has(target_id) or duration <= 0.0 or not is_finite(duration):
		return 0.0
	var unit: Dictionary = state.units[target_id]
	if not unit.alive or unit.kind not in ["hero", "minion"] or unit.protected > 0.0:
		return 0.0
	if kind == "slow":
		unit.slows.append({"strength": clampf(strength, 0.0, 0.6), "expires": state.time + duration})
		return duration
	if kind not in ["root", "stun", "knockback"]:
		return 0.0
	var intervals: Array = unit.cc_history.duplicate(true)
	intervals.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.x < b.x)
	var used: float = 0.0
	var end: float = state.time - 3.0
	var existing_end: float = state.time
	for interval: Vector2 in intervals:
		var begin: float = maxf(interval.x, maxf(end, state.time - 3.0))
		if interval.y > begin:
			used += interval.y - begin
		end = maxf(end, interval.y)
		existing_end = maxf(existing_end, interval.y)
	var allowed: float = minf(minf(duration, 1.0), maxf(0.0, 1.5 - used) + maxf(0.0, existing_end - state.time))
	if allowed <= 0.00001:
		return 0.0
	unit.cc_history.append(Vector2(state.time, state.time + allowed))
	if kind == "root":
		unit.root_left = maxf(unit.root_left, allowed)
	else:
		unit.stun_left = maxf(unit.stun_left, allowed)
	var movement_windup: bool = unit.phase == "windup" and unit.cast.get("slot", "") == "E" and unit.hero in ["bas", "rio"]
	if kind != "root" or unit.phase == "dash" or movement_windup:
		state.cancel_action(unit)
	return allowed


func award_xp(state: Variant, unit_id: int, amount: float, context: Dictionary = {}) -> float:
	if not state.units.has(unit_id) or amount <= 0.0 or not is_finite(amount):
		return 0.0
	var unit: Dictionary = state.units[unit_id]
	if unit.kind != "hero" or unit.level >= 12:
		return 0.0
	var level_before: int = unit.level
	var points_before: int = unit.points
	var xp_before: float = unit.xp
	# Clip only the overflow the existing level-12 rule already discarded. Compute
	# capacity first so even a huge finite grant cannot lose its accepted amount.
	var capacity: float = -xp_before
	for level: int in range(level_before, 12):
		capacity += 100.0 + 25.0 * (level - 1)
	var applied: float = minf(amount, maxf(0.0, capacity))
	if applied <= 0.0:
		return 0.0
	unit.xp += applied
	while unit.level < 12:
		var required: float = 100.0 + 25.0 * (unit.level - 1)
		if unit.xp + 0.00001 < required:
			break
		unit.xp -= required
		unit.level += 1
		unit.points += 1
		unit.max_hp += 40.0
		if unit.alive:
			unit.hp = minf(unit.max_hp, unit.hp + 40.0)
		unit.power += 3.0
		state.log_event("level", "%s Lv.%d" % [unit.name, unit.level], {"target_id": unit_id, "team": unit.team})
	if unit.level >= 12:
		unit.xp = 0.0
	# A personal reward may be received beyond sight range. Expose the recipient,
	# never the defeated object's position or identity, to the feedback consumer.
	state.log_event("xp_gain", "XP awarded", {"target_id": unit_id, "amount": applied, "source_kind": str(context.get("source_kind", "")), "share_count": int(context.get("share_count", 1)), "level_before": level_before, "level_after": int(unit.level), "points_gained": int(unit.points) - points_before, "xp_before": xp_before, "xp_after": float(unit.xp)})
	return applied


func _share(state: Variant, team: int, position: Vector2, xp: float, credits: float, source_kind: String = "") -> void:
	var eligible: Array = []
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == team and unit.alive and unit.pos.distance_to(position) <= 14.0:
			eligible.append(unit)
	if eligible.is_empty():
		return
	for unit: Dictionary in eligible:
		award_xp(state, unit.id, xp / eligible.size(), {"source_kind": source_kind, "share_count": eligible.size()})
		unit.credits += credits / eligible.size()


func _kill(state: Variant, unit: Dictionary, source: Dictionary, team: int) -> void:
	if not unit.alive:
		return
	unit.alive = false
	unit.hp = 0.0
	state.cancel_action(unit)
	state._clear_attack_move(unit)
	unit.order = "idle"
	unit.path.clear()
	unit.target_id = -1
	unit.shields.clear()
	unit.shield = 0.0
	unit.root_left = 0.0
	unit.stun_left = 0.0
	unit.slows.clear()
	unit.knockback.clear()
	if unit.kind == "hero":
		state._consumables.end_effect(state, unit, "death")
		state.stats.hero_deaths += 1
		unit.respawn_left = 8.0 + 2.0 * unit.level
		unit.pressure = 0
		unit.pressure_left = 0.0
		unit.empowered_left = 0.0
		unit.return_mark.clear()
		unit.protected = 0.0
		unit.deaths += 1
		for pin_id: int in unit.pins.duplicate():
			state.remove_pin(pin_id)
		var killer: Dictionary = source if source.kind == "hero" else {}
		if killer.is_empty():
			var latest: float = -INF
			for contributor_id: int in unit.contributors:
				if state.units.has(contributor_id) and state.time - unit.contributors[contributor_id] <= 6.0 and unit.contributors[contributor_id] > latest:
					killer = state.units[contributor_id]
					latest = unit.contributors[contributor_id]
		if not killer.is_empty():
			killer.credits += 60.0
			killer.kills += 1
			team = killer.team
			for contributor_id: int in unit.contributors:
				if contributor_id != killer.id and state.units.has(contributor_id) and state.time - unit.contributors[contributor_id] <= 6.0:
					state.units[contributor_id].credits += 20.0
					state.units[contributor_id].assists += 1
		_share(state, team, unit.pos, 60.0, 0.0, "hero")
		state.log_event("death", "%s defeated" % unit.name, {"target_id": unit.id, "team": unit.team})
	elif unit.kind == "minion":
		_share(state, team, unit.pos, unit.reward_xp, unit.reward_credits, "minion")
		if source.kind == "hero":
			source.credits += 4.0
		unit.remove_at = state.time + 0.8
	elif unit.kind == "cell":
		_share(state, team, unit.pos, unit.xp_reward, 10.0, "cell")
		unit.respawn_left = 45.0
	elif unit.kind == "pin":
		state.remove_pin(unit.id)
	elif unit.kind == "tower":
		for hero: Dictionary in state.units.values():
			if hero.kind == "hero" and hero.team == team:
				hero.credits += 30.0
		state.log_event("tower", "%s destroyed" % unit.name, {"target_id": unit.id, "team": unit.team})
		state.refresh_locks()
