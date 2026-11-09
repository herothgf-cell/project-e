extends RefCounted
## All new numbers are V8 prototype design. Shared authority owns hits and CC.
const HEROES: Array = ["orin", "tere", "mua", "sera", "lume"]

func preview(state: Variant, actor: Dictionary, plan: Dictionary, distance: float) -> Dictionary:
	var direction: Vector2 = plan.direction
	var key: String = actor.hero + plan.slot
	var directional: bool = key in ["orinQ", "orinW", "orinR", "tereQ", "tereW", "tereE", "tereR", "seraQ", "seraE", "seraR"]
	if directional and distance < 0.0001:
		plan.reason = "Choose a direction"
		return plan
	plan.support = key in ["orinE", "tereW", "muaW", "muaE", "seraW", "lumeE"]
	match key:
		"orinQ", "orinR":
			var ready: bool = actor.wind_ready_until > state.time and plan.slot == "Q"
			var length: float = 5.0 if ready else 8.0
			var width: float = 2.4 if ready else (1.6 if plan.slot == "R" else 0.7)
			plan.merge({"shape": "line", "target": state.map.clip_wall(actor.pos, actor.pos + direction * length, width * 0.5), "width": width, "wind_prepared": ready}, true)
		"orinW", "tereQ", "tereW", "tereR", "seraQ", "seraR":
			var spec: Array = {"orinW": [3.5, 90.0], "tereQ": [3.0, 90.0], "tereW": [5.0, 100.0], "tereR": [6.0, 100.0], "seraQ": [2.8, 60.0], "seraR": [3.5, 55.0]}[key]
			var facing: Vector2 = -direction if key == "tereW" else direction
			plan.merge({"shape": "cone", "radius": spec[0], "angle": spec[1], "target": actor.pos + facing * float(spec[0])}, true)
		"tereE", "seraE":
			var length: float = 3.0 if actor.hero == "tere" else 4.0
			plan.merge({"shape": "line", "target": state.map.clip_walk(actor.pos, actor.pos + direction * length), "width": 0.9, "dash_distance": length, "dash_speed": 13.0 if actor.hero == "tere" else 17.0}, true)
		"muaQ", "lumeQ", "lumeR":
			var reach: float = 6.0 if actor.hero == "mua" else (8.0 if plan.slot == "R" else 7.0)
			plan.merge({"shape": "circle", "origin": plan.target, "radius": 2.5 if key == "lumeR" else 2.0}, true)
			if distance > reach or not state.map.is_walkable(plan.target, 0.0) or not state.map.has_line_of_sight(actor.pos, plan.target):
				plan.reason = "Aim outside legal ground or sight line"
				return plan
		"muaW", "muaR":
			var zone: Dictionary = active_zone(state, actor)
			if zone.is_empty():
				plan.reason = "Place a wave zone first"
				return plan
			if key == "muaW":
				for candidate: Dictionary in actor.zones:
					if candidate.id != zone.id and candidate.expires > state.time:
						zone = candidate
						break
			plan.merge({"shape": "circle", "origin": zone.pos, "target": zone.pos, "radius": 3.5 if key == "muaR" else zone.radius, "zone_id": zone.id}, true)
			if actor.pos.distance_to(zone.pos) > 8.0 or not state.map.has_line_of_sight(actor.pos, zone.pos):
				plan.reason = "Wave zone beyond 8m or blocked"
				return plan
		"orinE", "muaE", "seraW", "lumeW", "lumeE":
			plan.merge({"shape": "circle", "origin": actor.pos, "target": actor.pos, "radius": 4.0 if key == "muaE" else (3.0 if key == "lumeW" else actor.radius)}, true)
		_:
			return plan
	plan.valid = true
	plan.reason = ""
	return plan

func resolve(state: Variant, actor: Dictionary, cast: Dictionary, abilities: Variant) -> void:
	var power: float = cast.power
	var multiplier: float = 1.0
	if actor.hero == "lume" and cast.slot in ["Q", "W", "R"]:
		if actor.heat_count == 3:
			multiplier = 1.25
			actor.heat_count = 0
		else:
			actor.heat_count += 1
	match actor.hero + cast.slot:
		"orinQ":
			abilities.area_damage(state, actor, cast, 70.0 + 0.45 * power)
			actor.wind_ready_until = 0.0
			actor.empowered_left = 3.0
			actor.empowered_damage = 30.0 + 0.20 * power
		"orinW":
			abilities.area_damage(state, actor, cast, 35.0 + 0.20 * power, "slow", 0.8, 0.25)
			actor.wind_ready_until = state.time + 5.0
		"orinE":
			haste(state, actor, "orinE", 0.35, 2.0)
		"orinR":
			abilities.area_damage(state, actor, cast, 85.0 + 0.40 * power, "", 0.0, 0.0, "wave1")
			schedule(state, cast, 0.45, 85.0 + 0.40 * power, "wave2")
		"tereQ":
			abilities.area_damage(state, actor, cast, 65.0 + 0.35 * power, "slow", 0.8, 0.25)
		"tereW":
			state.add_shield(actor.id, "%d:W" % actor.id, 110.0 + 0.30 * power, 2.0)
			var protected_ally: bool = false
			for ally: Dictionary in allies_in(state, actor, cast, abilities):
				state.add_shield(ally.id, "%d:W" % actor.id, 110.0 + 0.30 * power, 2.0)
				protected_ally = protected_ally or ally.id != actor.id
			if protected_ally:
				state.add_shield(actor.id, "%d:passive" % actor.id, 50.0 + 0.15 * power, 2.0)
		"tereE", "seraE":
			actor.phase = "dash"
			actor.dash_left = cast.dash_distance
			actor.phase_left = 0.0
			return
		"tereR":
			abilities.area_damage(state, actor, cast, 120.0 + 0.55 * power, "root", 0.8)
		"muaQ":
			while actor.zones.size() >= 2:
				actor.zones.pop_front()
			for zone: Dictionary in actor.zones:
				zone.active = false
			actor.zones.append({"id": cast.id, "pos": cast.origin, "radius": 2.0, "expires": state.time + 8.0, "active": true})
			actor.passive_inside.clear()
			abilities.area_damage(state, actor, cast, 55.0 + 0.30 * power)
		"muaW", "muaR":
			var zone: Dictionary = zone_by_id(state, actor, cast.zone_id)
			if zone.is_empty():
				state.cancel_action(actor)
				return
			if cast.slot == "W":
				var switched: bool = not zone.active
				for item: Dictionary in actor.zones:
					item.active = item.id == zone.id
				if switched:
					actor.passive_inside.clear()
				for ally: Dictionary in allies_in(state, actor, cast, abilities):
					haste(state, ally, "%d:muaW" % actor.id, 0.25, 2.0)
			else:
				abilities.area_damage(state, actor, cast, 130.0 + 0.60 * power, "root", 0.6)
				actor.zones.erase(zone)
				if not actor.zones.is_empty():
					actor.zones.back().active = true
				actor.passive_inside.clear()
		"muaE":
			var zone: Dictionary = active_zone(state, actor)
			for ally: Dictionary in allies_in(state, actor, cast, abilities):
				var amount: float = 80.0 + 0.30 * power
				if not zone.is_empty() and ally.pos.distance_to(zone.pos) <= zone.radius + ally.radius and state.map.has_line_of_sight(zone.pos, ally.pos):
					amount += 40.0 + 0.15 * power
				state.add_shield(ally.id, "%d:E" % actor.id, amount, 1.8)
		"seraQ":
			abilities.area_damage(state, actor, cast, 65.0 + 0.40 * power)
		"seraW":
			state.add_shield(actor.id, "%d:W" % actor.id, 90.0 + 0.30 * power, 1.5)
		"seraR":
			for target: Dictionary in state.units.values():
				if not target.alive or target.team == actor.team or not abilities.contains(cast, target.pos, target.radius) or not state.map.has_line_of_sight(cast.origin, target.pos):
					continue
				var stacks: int = mark_stacks(state, actor, target)
				var dealt: float = state.apply_damage(actor.id, target.id, 100.0 + 0.50 * power + stacks * (35.0 + 0.15 * power), cast.id, "impact")
				if dealt > 0.0 and stacks > 0:
					actor.marks.erase(target.id)
		"lumeQ":
			abilities.area_damage(state, actor, cast, (80.0 + 0.45 * power) * multiplier)
		"lumeW":
			abilities.area_damage(state, actor, cast, (35.0 + 0.20 * power) * multiplier, "slow", 0.9, 0.30)
		"lumeE":
			state.add_shield(actor.id, "%d:E" % actor.id, 80.0 + 0.25 * power, 1.8)
			haste(state, actor, "lumeE", 0.25, 2.0)
		"lumeR":
			var amount: float = (70.0 + 0.30 * power) * multiplier
			abilities.area_damage(state, actor, cast, amount, "", 0.0, 0.0, "shell1")
			schedule(state, cast, 0.45, amount, "shell2")
			schedule(state, cast, 0.90, amount, "shell3")
	impact_visual(state, cast)
	actor.phase = "recovery"
	actor.phase_left = cast.recovery

func allies_in(state: Variant, actor: Dictionary, shape: Dictionary, abilities: Variant) -> Array:
	var allies: Array = []
	for ally: Dictionary in state.units.values():
		if ally.kind == "hero" and ally.team == actor.team and ally.alive and abilities.contains(shape, ally.pos, ally.radius) and state.map.has_line_of_sight(shape.origin, ally.pos):
			allies.append(ally)
	return allies

func haste(state: Variant, actor: Dictionary, source: String, strength: float, duration: float) -> void:
	actor.speed_buffs = actor.speed_buffs.filter(func(buff: Dictionary) -> bool: return buff.source != source and buff.expires > state.time)
	actor.speed_buffs.append({"source": source, "strength": strength, "expires": state.time + duration})

func active_zone(state: Variant, actor: Dictionary) -> Dictionary:
	for zone: Dictionary in actor.zones:
		if zone.active and zone.expires > state.time:
			return zone
	return {}

func zone_by_id(state: Variant, actor: Dictionary, id: int) -> Dictionary:
	for zone: Dictionary in actor.zones:
		if zone.id == id and zone.expires > state.time:
			return zone
	return {}

func add_mark(state: Variant, actor: Dictionary, target: Dictionary) -> void:
	if target.kind != "hero" or not target.alive or not state.is_visible(actor.team, target.id):
		return
	var stacks: int = mark_stacks(state, actor, target)
	actor.marks[target.id] = {"stacks": mini(2, stacks + 1), "expires": state.time + 5.0}

func mark_stacks(state: Variant, actor: Dictionary, target: Dictionary) -> int:
	if target.kind != "hero" or not target.alive or not state.is_visible(actor.team, target.id):
		return 0
	var mark: Dictionary = actor.marks.get(target.id, {})
	return int(mark.stacks) if not mark.is_empty() and mark.expires > state.time else 0

func basic_bonus(state: Variant, actor: Dictionary, target: Dictionary, power: float) -> float:
	if actor.hero == "sera" and target.protected <= 0.0 and mark_stacks(state, actor, target) == 2:
		actor.marks.erase(target.id)
		return 55.0 + 0.30 * power
	return 0.0

func schedule(state: Variant, cast: Dictionary, delay: float, amount: float, stage: String) -> void:
	var hit: Dictionary = cast.duplicate(true)
	hit.merge({"due": state.time + delay, "amount": amount, "hit_stage": stage, "remaining": delay, "duration": delay, "telegraph": true, "scheduled": true}, true)
	state.scheduled_hits.append(hit)
	state.effects.append(hit.duplicate(true))

func retreat_impact(state: Variant, actor: Dictionary, cast: Dictionary) -> void:
	var fan: Dictionary = cast.duplicate(true)
	fan.merge({"shape": "cone", "target": cast.origin - cast.direction * 3.5, "radius": 3.5, "angle": 100.0, "movement": false}, true)
	schedule(state, fan, 0.35, 65.0 + 0.30 * cast.power, "retreat")

func impact_visual(state: Variant, cast: Dictionary) -> void:
	var visual: Dictionary = cast.duplicate(true)
	visual.merge({"telegraph": false, "remaining": 0.22, "duration": 0.22}, true)
	state.effects.append(visual)

func tick(state: Variant, abilities: Variant) -> void:
	var pending: Array = state.scheduled_hits
	state.scheduled_hits = []
	for hit: Dictionary in pending:
		var owner: Dictionary = state.units.get(hit.owner_id, {})
		if owner.is_empty() or not owner.alive:
			continue
		if hit.due > state.time + 0.00001:
			state.scheduled_hits.append(hit)
			continue
		abilities.area_damage(state, owner, hit, hit.amount, "", 0.0, 0.0, hit.hit_stage)
		impact_visual(state, hit)
	for actor: Dictionary in state.units.values():
		if actor.kind != "hero":
			continue
		actor.speed_buffs = actor.speed_buffs.filter(func(buff: Dictionary) -> bool: return buff.expires > state.time)
		for target_id: int in actor.marks.keys():
			if actor.marks[target_id].expires <= state.time or not state.units.has(target_id) or not state.units[target_id].alive:
				actor.marks.erase(target_id)
		if not actor.alive or actor.hero != "mua":
			continue
		actor.zones = actor.zones.filter(func(zone: Dictionary) -> bool: return zone.expires > state.time)
		var zone: Dictionary = active_zone(state, actor)
		if zone.is_empty() and not actor.zones.is_empty():
			actor.zones.back().active = true
			zone = actor.zones.back()
		var inside: Dictionary = {}
		if not zone.is_empty():
			var shape: Dictionary = {"shape": "circle", "origin": zone.pos, "radius": zone.radius}
			for ally: Dictionary in allies_in(state, actor, shape, abilities):
				inside[ally.id] = true
				if not actor.passive_inside.has(ally.id) and state.time >= actor.passive_ready.get(ally.id, -1.0):
					state.add_shield(ally.id, "%d:passive" % actor.id, 35.0 + 0.15 * actor.power, 1.2)
					actor.passive_ready[ally.id] = state.time + 4.0
		actor.passive_inside = inside

func clear_owner(state: Variant, actor: Dictionary) -> void:
	actor.zones.clear()
	actor.marks.clear()
	actor.speed_buffs.clear()
	actor.wind_ready_until = 0.0
	actor.heat_count = 0
	actor.passive_inside.clear()
	actor.passive_ready.clear()
	state.scheduled_hits = state.scheduled_hits.filter(func(hit: Dictionary) -> bool: return hit.owner_id != actor.id)
	state.effects = state.effects.filter(func(effect: Dictionary) -> bool: return effect.get("owner_id", -1) != actor.id)
	for owner: Dictionary in state.units.values():
		if owner.kind == "hero":
			owner.marks.erase(actor.id)
