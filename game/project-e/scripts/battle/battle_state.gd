extends RefCounted
## Local 30 Hz battle authority. Network transport is deliberately outside this model.

const MapScript = preload("res://scripts/battle/battle_map.gd")
const RulesScript = preload("res://scripts/battle/battle_rules.gd")
const AbilitiesScript = preload("res://scripts/battle/hero_abilities.gd")
const AIScript = preload("res://scripts/battle/battle_ai.gd")
const FIXED_STEP: float = 1.0 / 30.0
const HERO_STATS: Dictionary = {"bas": [1100.0, 5.8, 2.0, 0.18], "rio": [950.0, 6.2, 6.5, 0.16], "nema": [1000.0, 6.0, 5.5, 0.18]}
static var _shared_map: Variant

var units: Dictionary = {}
var effects: Array = []
var projectiles: Array = []
var controlled_id: int = -1
var time: float = 0.0
var winner: int = -1
var events: Array = []
var map: Variant
var last_error: String = ""
var bots_enabled: bool = true
var practice_mode: bool = false
var stats: Dictionary = {}
var hit_registry: Dictionary = {}
var _rules: Variant = RulesScript.new()
var _abilities: Variant = AbilitiesScript.new()
var _ai: Variant = AIScript.new()
var _accumulator: float = 0.0
var _next_unit: int = 1
var _next_action: int = 1
var _event_seq: int = 0
var _next_wave: float = 20.0
var _wave: int = 0
var _next_income: float = 5.0
var _next_ai: float = 0.0
var _next_cleanup: float = 1.0
var _cells_spawned: bool = false
var _visibility_cache: Dictionary = {}


func reset(hero_key: String = "bas", practice: bool = false) -> void:
	units.clear()
	effects.clear()
	projectiles.clear()
	events.clear()
	hit_registry.clear()
	_visibility_cache.clear()
	time = 0.0
	winner = -1
	last_error = ""
	_accumulator = 0.0
	_next_unit = 1
	_next_action = 1
	_event_seq = 0
	_next_wave = 20.0
	_wave = 0
	_next_income = 5.0
	_next_ai = 0.0
	_next_cleanup = 1.0
	_cells_spawned = false
	bots_enabled = true
	practice_mode = practice
	stats = {"damage": 0.0, "hero_deaths": 0, "casts": 0, "attacks": 0}
	if _shared_map == null:
		_shared_map = MapScript.new()
	map = _shared_map
	if not HERO_STATS.has(hero_key):
		hero_key = "bas"
	controlled_id = -1
	for team: int in range(2):
		var remaining_lanes: Array = [0, 2]
		for hero: String in ["bas", "rio", "nema"]:
			var lane: int = 1 if hero == hero_key else int(remaining_lanes.pop_front())
			if team == 1:
				lane = ["bas", "rio", "nema"].find(hero)
			var unit: Dictionary = _entity("hero", team, map.spawn_points[team] + Vector2(0, (1 - lane) * 2.0), HERO_STATS[hero][0], 0.45)
			unit.merge({"hero": hero, "name": hero.capitalize(), "lane": lane, "speed": HERO_STATS[hero][1], "attack_range": HERO_STATS[hero][2], "attack_windup": HERO_STATS[hero][3], "energy": 100.0, "max_energy": 100.0, "energy_regen": 8.0, "power": 100.0, "points": 2, "credits": 100.0}, true)
			if practice:
				unit.level = 3
				unit.max_hp += 80.0
				unit.hp = unit.max_hp
				unit.power += 6.0
				unit.points = 3
				unit.r_unlocked = true
				unit.investments.R = 1
			if team == 0 and hero == hero_key:
				controlled_id = unit.id
	for spec: Dictionary in map.tower_specs:
		var unit: Dictionary = _entity("tower", spec.team, spec.pos, 2600.0 if spec.subtype == "inner" else 2000.0, 1.0)
		unit.merge({"name": "%s %s %s" % ["West" if spec.team == 0 else "East", ["N", "C", "S"][spec.lane], spec.subtype], "lane": spec.lane, "subtype": spec.subtype, "attack_range": 9.0, "attack_damage": 180.0, "attack_windup": 0.1, "locked": spec.subtype == "inner"}, true)
	for team: int in range(2):
		var core: Dictionary = _entity("core", team, map.core_positions[team], 4000.0, 2.0)
		core.merge({"name": "West Core" if team == 0 else "East Core", "locked": true, "lane": 1}, true)
	refresh_locks()


func _entity(kind: String, team: int, position: Vector2, health: float, radius: float) -> Dictionary:
	var entity: Dictionary = {"id": _next_unit, "kind": kind, "team": team, "hero": "", "name": kind.capitalize(), "pos": position, "facing": Vector2.RIGHT if team == 0 else Vector2.LEFT, "radius": radius, "alive": true, "hp": health, "max_hp": health, "shield": 0.0, "shields": [], "energy": 0.0, "max_energy": 0.0, "energy_regen": 0.0, "level": 1, "xp": 0.0, "points": 0, "r_unlocked": false, "cooldowns": {"Q": 0.0, "W": 0.0, "E": 0.0, "R": 0.0}, "respawn_left": 0.0, "lane": 1, "phase": "idle", "phase_left": 0.0, "locked": false, "power": 0.0, "armor": 0.0, "speed": 0.0, "attack_range": 0.0, "attack_interval": 1.0, "attack_windup": 0.18, "attack_damage": 0.0, "attack_left": 0.0, "target_id": -1, "path": [], "goal": position, "order": "idle", "cast": {}, "queued": {}, "root_left": 0.0, "stun_left": 0.0, "cc_history": [], "slows": [], "knockback": {}, "protected": 0.0, "siege_protected": false, "last_damage": -100.0, "last_hostile": -100.0, "contributors": {}, "pressure": 0, "pressure_left": 0.0, "empowered_left": 0.0, "empowered_damage": 0.0, "pins": [], "return_mark": {}, "passive_inside": {}, "passive_ready": {}, "investments": {"power": 0, "hp": 0, "armor": 0, "regen": 0, "speed": 0, "R": 0}, "credits": 0.0, "kills": 0, "deaths": 0, "assists": 0, "repath_at": 0.0, "last_seen": -100.0, "last_target_pos": position, "aggro_id": -1, "aggro_until": 0.0, "remove_at": INF, "lane_progress": 5.0, "ai_retreat": false, "ai_think": 0.0}
	units[_next_unit] = entity
	_next_unit += 1
	return entity


func step(delta: float) -> void:
	if winner != -1 or not is_finite(delta) or delta <= 0.0:
		return
	_accumulator += delta
	while _accumulator + 0.00000001 >= FIXED_STEP and winner == -1:
		_accumulator -= FIXED_STEP
		_tick(FIXED_STEP)


func _tick(delta: float) -> void:
	time += delta
	_visibility_cache.clear()
	for effect: Dictionary in effects:
		effect.remaining -= delta
	effects = effects.filter(func(effect: Dictionary) -> bool: return effect.remaining > 0.0)
	for unit: Dictionary in units.values():
		_timers(unit, delta)
	if time + 0.00001 >= _next_wave:
		_spawn_wave()
		_next_wave += 18.0
	if time + 0.00001 >= _next_income:
		for unit: Dictionary in units.values():
			if unit.kind == "hero":
				unit.credits += 5.0
		_next_income += 5.0
	if not _cells_spawned and time + 0.00001 >= 30.0:
		_cells_spawned = true
		for position: Vector2 in map.cell_positions:
			_entity("cell", 2, position, 180.0, 0.55)
	if time + 0.00001 >= _next_ai:
		_ai.think(self)
		_next_ai += 0.4
	for unit: Dictionary in units.values():
		if unit.alive:
			_advance_actor(unit, delta)
	var kept: Array = []
	for projectile: Dictionary in projectiles:
		var active: bool = _abilities.disc_step(self, projectile, delta) if projectile.kind == "rio_disc" else _basic_projectile_step(projectile, delta)
		if active:
			kept.append(projectile)
	projectiles = kept
	_abilities.tick_devices(self)
	refresh_locks()
	_resolve_victory()
	if time >= _next_cleanup:
		for key: String in hit_registry.keys():
			if hit_registry[key].expires <= time:
				hit_registry.erase(key)
		for id: int in units.keys():
			if units[id].remove_at <= time:
				units.erase(id)
		_next_cleanup += 1.0


func _timers(unit: Dictionary, delta: float) -> void:
	for slot: String in unit.cooldowns:
		unit.cooldowns[slot] = maxf(0.0, unit.cooldowns[slot] - delta)
	unit.attack_left = maxf(0.0, unit.attack_left - delta)
	unit.root_left = maxf(0.0, unit.root_left - delta)
	unit.stun_left = maxf(0.0, unit.stun_left - delta)
	unit.protected = maxf(0.0, unit.protected - delta)
	unit.pressure_left = maxf(0.0, unit.pressure_left - delta)
	unit.empowered_left = maxf(0.0, unit.empowered_left - delta)
	if unit.pressure_left <= 0.0:
		unit.pressure = 0
	unit.shields = unit.shields.filter(func(shield: Dictionary) -> bool: return shield.expires > time and shield.amount > 0.0)
	_rules.sync_shield(unit)
	unit.slows = unit.slows.filter(func(slow: Dictionary) -> bool: return slow.expires > time)
	unit.cc_history = unit.cc_history.filter(func(interval: Vector2) -> bool: return interval.y > time - 3.0)
	if not unit.return_mark.is_empty() and unit.return_mark.expires <= time:
		unit.return_mark.clear()
	if not unit.alive:
		if unit.kind in ["hero", "cell"]:
			unit.respawn_left = maxf(0.0, unit.respawn_left - delta)
			if unit.respawn_left <= 0.00001:
				unit.alive = true
				unit.hp = unit.max_hp
				unit.energy = unit.max_energy
				unit.contributors.clear()
				unit.cc_history.clear()
				if unit.kind == "hero":
					unit.pos = map.spawn_points[unit.team] + Vector2(0, (1 - unit.lane) * 2.0)
					unit.protected = 3.0
					unit.passive_inside.clear()
					unit.passive_ready.clear()
					unit.ai_retreat = false
		return
	if unit.kind == "pin":
		if unit.expires <= time:
			remove_pin(unit.id)
		return
	if unit.kind == "hero":
		unit.energy = minf(unit.max_energy, unit.energy + unit.energy_regen * delta)
		var base: Rect2 = Rect2(-59, -6, 6, 12) if unit.team == 0 else Rect2(53, -6, 6, 12)
		if base.has_point(unit.pos) and time - unit.last_damage >= 2.0 and time - unit.last_hostile >= 3.0:
			unit.hp = minf(unit.max_hp, unit.hp + unit.max_hp * 0.2 * delta)
			unit.energy = minf(unit.max_energy, unit.energy + unit.max_energy * 0.2 * delta)


func _advance_actor(unit: Dictionary, delta: float) -> void:
	if not unit.knockback.is_empty():
		var elapsed: float = minf(delta, unit.knockback.remaining)
		unit.pos = map.clip_walk(unit.pos, unit.pos + unit.knockback.direction * unit.knockback.speed * elapsed, unit.radius)
		unit.knockback.remaining -= elapsed
		if unit.knockback.remaining <= 0.00001:
			unit.knockback.clear()
		return
	if unit.stun_left > 0.00001:
		return
	if unit.phase == "dash":
		_abilities.dash_step(self, unit, delta)
		return
	if unit.phase in ["windup", "basic", "recovery"]:
		unit.phase_left -= delta
		if unit.phase_left <= 0.00001:
			if unit.phase == "windup":
				_abilities.resolve(self, unit, unit.cast)
			elif unit.phase == "basic":
				_release_basic(unit)
				unit.phase = "idle"
				unit.cast.clear()
			else:
				unit.phase = "idle"
				unit.cast.clear()
		return
	if not unit.queued.is_empty():
		var queued: Dictionary = unit.queued.duplicate()
		unit.queued.clear()
		if queued.type == "move":
			command_move(unit.id, queued.target)
		elif queued.type == "attack":
			command_attack(unit.id, queued.target_id)
		elif queued.type == "cast":
			command_cast(unit.id, queued.slot, queued.target)
			if unit.phase == "windup":
				return
		else:
			command_stop(unit.id)
	if unit.order == "attack" and units.has(unit.target_id):
		var target: Dictionary = units[unit.target_id]
		if not target.alive or target.locked:
			unit.target_id = -1
			unit.order = "idle"
		elif is_visible(unit.team, target.id):
			unit.last_seen = time
			unit.last_target_pos = target.pos
			if unit.pos.distance_to(target.pos) <= unit.attack_range + target.radius and map.has_line_of_sight(unit.pos, target.pos):
				unit.path.clear()
				if unit.attack_left <= 0.00001:
					_start_basic(unit, target)
				return
			elif unit.speed > 0.0 and time >= unit.repath_at:
				var direction: Vector2 = (unit.pos - target.pos).normalized()
				var goal: Vector2 = target.pos + direction * maxf(target.radius + unit.radius + 0.15, unit.attack_range * 0.82 + target.radius)
				_set_path(unit, goal)
				unit.repath_at = time + 0.6
		elif time - unit.last_seen > 1.0:
			unit.target_id = -1
			unit.order = "idle"
			unit.path.clear()
	if unit.root_left <= 0.00001 and unit.speed > 0.0:
		_walk(unit, delta)


func _start_basic(unit: Dictionary, target: Dictionary) -> void:
	unit.protected = 0.0
	unit.facing = (target.pos - unit.pos).normalized()
	unit.attack_left = unit.attack_interval
	unit.phase = "basic"
	unit.phase_left = unit.attack_windup
	unit.cast = {"id": next_action_id(), "target_id": target.id, "power": unit.power, "damage": 60.0 + 0.3 * unit.power if unit.kind == "hero" else unit.attack_damage}
	stats.attacks += 1


func _release_basic(unit: Dictionary) -> void:
	var cast: Dictionary = unit.cast
	if cast.is_empty() or not units.has(cast.target_id):
		return
	var target: Dictionary = units[cast.target_id]
	if not target.alive or target.locked:
		return
	var melee: bool = unit.hero == "bas" or unit.get("subtype", "") == "melee"
	if melee:
		if not is_visible(unit.team, target.id) or unit.pos.distance_to(target.pos) > unit.attack_range + target.radius or not map.has_line_of_sight(unit.pos, target.pos):
			return
		var dealt: float = apply_damage(unit.id, target.id, cast.damage, cast.id, "basic")
		if unit.hero == "bas" and dealt > 0.0 and target.kind == "hero" and unit.pressure >= 2:
			unit.pressure = 0
			unit.pressure_left = 0.0
			add_shield(unit.id, "%d:passive" % unit.id, 80.0 + 0.25 * unit.power, 2.0)
	else:
		var damage: float = cast.damage
		if unit.hero == "rio" and unit.empowered_left > 0.0:
			damage += unit.empowered_damage
			unit.empowered_left = 0.0
		projectiles.append({"id": cast.id, "cast_id": cast.id, "kind": "tower_bolt" if unit.kind == "tower" else "basic", "pos": unit.pos, "target_pos": target.pos, "target_id": target.id, "owner_id": unit.id, "team": unit.team, "damage": damage, "remaining": 3.0})


func _basic_projectile_step(projectile: Dictionary, delta: float) -> bool:
	projectile.remaining -= delta
	if projectile.remaining <= 0.0 or not units.has(projectile.target_id) or not units[projectile.target_id].alive:
		return false
	var target: Dictionary = units[projectile.target_id]
	projectile.target_pos = target.pos
	var start: Vector2 = projectile.pos
	var offset: Vector2 = target.pos - start
	var travel: float = minf(offset.length(), 20.0 * delta)
	var goal: Vector2 = start + offset.normalized() * travel
	if not map.has_line_of_sight(start, goal):
		return false
	projectile.pos = goal
	if goal.distance_to(target.pos) <= target.radius + 0.1:
		apply_damage(projectile.owner_id, target.id, projectile.damage, projectile.cast_id, "basic")
		return false
	return true


func _walk(unit: Dictionary, delta: float) -> void:
	if unit.path.is_empty():
		unit.phase = "idle"
		return
	var slow: float = 0.0
	for item: Dictionary in unit.slows:
		slow = maxf(slow, item.strength)
	var remaining: float = unit.speed * maxf(0.4, 1.0 - slow) * delta
	unit.phase = "walk"
	for segment: int in range(4):
		if remaining <= 0.00001 or unit.path.is_empty():
			break
		var offset: Vector2 = unit.path[0] - unit.pos
		if offset.length() < 0.05:
			unit.path.pop_front()
			continue
		unit.facing = offset.normalized()
		var travel: float = minf(remaining, offset.length())
		var candidate: Vector2 = map.clip_walk(unit.pos, unit.pos + unit.facing * travel, unit.radius)
		if unit.kind == "hero" and _hero_overlap(unit, candidate):
			var perpendicular: Vector2 = Vector2(-unit.facing.y, unit.facing.x)
			var found: bool = false
			for sign_value: float in [1.0, -1.0]:
				var side: Vector2 = unit.pos + (unit.facing + perpendicular * sign_value).normalized() * travel
				if map.clear_walk(unit.pos, side, unit.radius) and not _hero_overlap(unit, side):
					candidate = side
					found = true
					break
			if not found:
				break
		var moved: float = unit.pos.distance_to(candidate)
		unit.pos = candidate
		remaining -= moved
		if moved < travel - 0.001:
			break
		if unit.pos.distance_to(unit.path[0]) < 0.05:
			unit.path.pop_front()
	if unit.path.is_empty() and unit.order == "move":
		unit.order = "idle"
		unit.phase = "idle"


func _hero_overlap(unit: Dictionary, position: Vector2) -> bool:
	for other: Dictionary in units.values():
		if other.kind == "hero" and other.alive and other.id != unit.id and position.distance_squared_to(other.pos) < 0.81 and position.distance_squared_to(other.pos) < unit.pos.distance_squared_to(other.pos) - 0.00001:
			return true
	return false


func _set_path(unit: Dictionary, goal: Vector2) -> bool:
	if not map.is_walkable(goal, unit.radius):
		return false
	var path: Array = map.find_path(unit.pos, goal)
	if path.is_empty():
		return false
	unit.path = path
	unit.goal = goal
	return true


func command_move(actor_id: int, target: Vector2) -> bool:
	if not _valid_actor(actor_id) or not target.is_finite():
		return _reject(actor_id, "Cannot move now")
	var actor: Dictionary = units[actor_id]
	if actor.root_left > 0.0 or actor.stun_left > 0.0 or not map.is_walkable(target, actor.radius):
		return _reject(actor_id, "Movement blocked by terrain or control")
	if actor.phase in ["windup", "dash", "recovery"]:
		actor.queued = {"type": "move", "target": target}
		return true
	if actor.phase == "basic":
		cancel_action(actor)
	if not _set_path(actor, target):
		return _reject(actor_id, "No walkable path")
	actor.order = "move"
	actor.target_id = -1
	actor.queued.clear()
	if actor_id == controlled_id:
		last_error = ""
	return true


func command_attack(actor_id: int, target_id: int) -> bool:
	if not _valid_actor(actor_id) or not units.has(target_id):
		return _reject(actor_id, "Invalid attacker or target")
	var actor: Dictionary = units[actor_id]
	var target: Dictionary = units[target_id]
	if not target.alive or target.team == actor.team or target.locked or not is_visible(actor.team, target_id) or actor.stun_left > 0.0:
		return _reject(actor_id, "Target unavailable, hidden, allied, or locked")
	if actor.phase in ["windup", "dash", "recovery"]:
		actor.queued = {"type": "attack", "target_id": target_id}
		return true
	actor.queued.clear()
	actor.target_id = target_id
	actor.order = "attack"
	actor.last_target_pos = target.pos
	actor.last_seen = time
	actor.protected = 0.0
	if actor_id == controlled_id:
		last_error = ""
	return true


func command_cast(actor_id: int, slot: String, target: Vector2) -> bool:
	slot = slot.to_upper()
	if not _valid_actor(actor_id) or units[actor_id].kind != "hero":
		return _reject(actor_id, "Cannot cast now")
	var actor: Dictionary = units[actor_id]
	var plan: Dictionary = get_cast_preview(actor_id, slot, target)
	if not plan.valid:
		return _reject(actor_id, plan.reason)
	if actor.phase in ["windup", "dash", "recovery", "basic"]:
		actor.queued = {"type": "cast", "slot": slot, "target": target}
		return true
	actor.energy -= plan.cost
	actor.cooldowns[slot] = plan.cooldown
	actor.facing = plan.direction
	actor.phase = "windup"
	actor.phase_left = plan.windup
	actor.path.clear()
	actor.order = "idle"
	actor.target_id = -1
	actor.queued.clear()
	plan.id = next_action_id()
	actor.cast = plan
	if not (actor.hero == "bas" and slot == "W") and not (actor.hero == "nema" and slot == "E"):
		actor.protected = 0.0
	effects.append(plan.duplicate(true))
	stats.casts += 1
	if actor_id == controlled_id:
		last_error = ""
	return true


func command_stop(actor_id: int) -> void:
	if not _valid_actor(actor_id):
		return
	var actor: Dictionary = units[actor_id]
	if actor.phase in ["windup", "dash", "recovery"]:
		actor.queued = {"type": "stop"}
		return
	if actor.phase == "basic":
		cancel_action(actor)
	actor.path.clear()
	actor.order = "idle"
	actor.target_id = -1
	actor.queued.clear()


func get_cast_preview(actor_id: int, slot: String, target: Vector2) -> Dictionary:
	if not units.has(actor_id):
		return {"valid": false, "reason": "Unknown actor"}
	slot = slot.to_upper()
	var actor: Dictionary = units[actor_id]
	var result: Dictionary = _abilities.preview(self, actor, slot, target)
	if not result.valid:
		return result
	var reason: String = ""
	if winner != -1 or not actor.alive:
		reason = "Match ended or hero defeated"
	elif actor.stun_left > 0.0:
		reason = "Stunned"
	elif slot == "E" and actor.hero in ["bas", "rio"] and actor.root_left > 0.0:
		reason = "Rooted: movement skill unavailable"
	elif slot == "R" and not actor.r_unlocked:
		reason = "R requires level 3 and one growth point"
	elif actor.cooldowns[slot] > 0.00001:
		reason = "Ability is cooling down"
	elif actor.energy + 0.00001 < result.cost:
		reason = "Not enough energy"
	if reason != "":
		result.valid = false
		result.reason = reason
	return result


func invest(actor_id: int, stat: String) -> bool:
	if winner != -1 or not units.has(actor_id) or units[actor_id].kind != "hero":
		return false
	var actor: Dictionary = units[actor_id]
	var limits: Dictionary = {"power": 5, "hp": 5, "armor": 4, "regen": 3, "speed": 3, "R": 1}
	if not limits.has(stat) or actor.points <= 0 or actor.investments[stat] >= limits[stat] or (stat == "R" and actor.level < 3):
		return _reject(actor_id, "Growth point unavailable or upgrade locked")
	actor.points -= 1
	actor.investments[stat] += 1
	match stat:
		"power": actor.power += 10.0
		"hp":
			actor.max_hp += 80.0
			if actor.alive:
				actor.hp += 80.0
		"armor": actor.armor += 5.0
		"regen": actor.energy_regen += 1.0
		"speed": actor.speed += 0.15
		"R": actor.r_unlocked = true
	return true


func _valid_actor(actor_id: int) -> bool:
	return winner == -1 and units.has(actor_id) and units[actor_id].alive and units[actor_id].kind in ["hero", "minion", "tower"]


func _reject(actor_id: int, reason: String) -> bool:
	if actor_id == controlled_id:
		last_error = reason
	return false


func cancel_action(actor: Dictionary) -> void:
	var cast_id: int = int(actor.cast.get("id", -1))
	if cast_id != -1:
		effects = effects.filter(func(effect: Dictionary) -> bool: return int(effect.get("id", -2)) != cast_id or not effect.telegraph)
	actor.cast = {}
	actor.phase = "idle"
	actor.phase_left = 0.0
	actor.queued.clear()


func is_point_visible(team: int, position: Vector2) -> bool:
	if not position.is_finite():
		return false
	for observer: Dictionary in units.values():
		if observer.team != team or not observer.alive or observer.kind not in ["hero", "minion", "tower", "core"]:
			continue
		var sight: float = 8.0 if observer.kind == "minion" else 12.0
		if observer.pos.distance_squared_to(position) <= sight * sight and map.has_line_of_sight(observer.pos, position):
			return true
	return false


func is_visible(team: int, unit_id: int) -> bool:
	if not units.has(unit_id):
		return false
	var unit: Dictionary = units[unit_id]
	if unit.team == team:
		return true
	# Public objectives retain their known position; current health is visible only in sight.
	var key: String = "%d:%d" % [team, unit_id]
	if not _visibility_cache.has(key):
		_visibility_cache[key] = is_point_visible(team, unit.pos)
	return _visibility_cache[key]


func get_pin_link(actor_id: int) -> Dictionary:
	if not units.has(actor_id):
		return {}
	var actor: Dictionary = units[actor_id]
	var pins: Array = _abilities.live_pins(self, actor)
	if not actor.alive or not _abilities.linked(self, pins):
		return {}
	return {"shape": "line", "origin": units[pins[0]].pos, "target": units[pins[1]].pos, "width": 0.5, "team": actor.team, "owner_id": actor_id, "valid": true, "telegraph": false, "remaining": 1.0, "duration": 1.0}


func apply_damage(source_id: int, target_id: int, amount: float, cast_id: int, stage: String = "impact") -> float:
	return _rules.damage(self, source_id, target_id, amount, cast_id, stage)


func add_shield(target_id: int, source: String, amount: float, duration: float) -> void:
	_rules.add_shield(self, target_id, source, amount, duration)


func apply_cc(target_id: int, kind: String, duration: float, strength: float = 0.0) -> float:
	return _rules.cc(self, target_id, kind, duration, strength)


func award_xp(target_id: int, amount: float) -> void:
	_rules.award_xp(self, target_id, amount)


func next_action_id() -> int:
	var result: int = _next_action
	_next_action += 1
	return result


func log_event(type: String, message: String, extra: Dictionary = {}) -> void:
	_event_seq += 1
	var item: Dictionary = {"seq": _event_seq, "time": time, "type": type, "text": message}
	item.merge(extra)
	if item.has("target_id") and units.has(item.target_id):
		item.pos = units[item.target_id].pos
		item.team = units[item.target_id].team
	events.append(item)
	if events.size() > 96:
		events.pop_front()


func spawn_pin(actor: Dictionary, position: Vector2) -> void:
	while actor.pins.size() >= 2:
		remove_pin(actor.pins[0])
	var pin: Dictionary = _entity("pin", actor.team, position, 160.0, 0.35)
	pin.owner_id = actor.id
	pin.expires = time + 8.0
	pin.created = time
	pin.name = "%s Pin" % actor.name
	actor.pins.append(pin.id)
	actor.passive_inside.clear()


func remove_pin(pin_id: int) -> void:
	if not units.has(pin_id):
		return
	var pin: Dictionary = units[pin_id]
	pin.alive = false
	pin.hp = 0.0
	pin.remove_at = time + 0.1
	if units.has(pin.get("owner_id", -1)):
		var actor: Dictionary = units[pin.owner_id]
		actor.pins.erase(pin_id)
		actor.passive_inside.clear()
		if actor.phase == "windup" and pin_id in actor.cast.get("pins", []):
			cancel_action(actor)


func _spawn_wave() -> void:
	_wave += 1
	var multiplier: float = 1.0 + minf(3.0, floorf(time / 240.0)) * 0.1
	for team: int in range(2):
		for lane: int in range(3):
			var types: Array = ["melee", "melee", "melee", "ranged"]
			if _wave % 4 == 0:
				types.append("siege")
			for index: int in range(types.size()):
				var subtype: String = types[index]
				var values: Array = {"melee": [240.0, 20.0, 1.5, 1.0, 20.0, 12.0], "ranged": [180.0, 25.0, 6.0, 1.2, 20.0, 12.0], "siege": [480.0, 45.0, 7.5, 1.5, 35.0, 20.0]}[subtype]
				# The lead unit uses M01's 5m anchor. Rear units remain beyond core clearance.
				var progress: float = 5.0 - index * 0.6
				var unit: Dictionary = _entity("minion", team, map.lane_point(lane, progress, team), values[0] * multiplier, 0.3 if subtype != "siege" else 0.45)
				unit.merge({"name": subtype.capitalize(), "subtype": subtype, "lane": lane, "speed": 3.2, "attack_damage": values[1] * multiplier, "attack_range": values[2], "attack_interval": values[3], "reward_xp": values[4], "reward_credits": values[5], "lane_progress": progress}, true)


func has_siege_minion(team: int, position: Vector2) -> bool:
	for unit: Dictionary in units.values():
		if unit.kind == "minion" and unit.alive and unit.team == team and unit.pos.distance_squared_to(position) <= 144.0:
			return true
	return false


func refresh_locks() -> void:
	for unit: Dictionary in units.values():
		if unit.kind == "tower" and unit.subtype == "inner" and unit.locked:
			for outer: Dictionary in units.values():
				if outer.kind == "tower" and outer.subtype == "outer" and outer.team == unit.team and outer.lane == unit.lane and not outer.alive:
					unit.locked = false
		if unit.kind == "core" and unit.locked:
			for inner: Dictionary in units.values():
				if inner.kind == "tower" and inner.subtype == "inner" and inner.team == unit.team and not inner.alive:
					unit.locked = false
		if unit.kind in ["tower", "core"]:
			unit.siege_protected = not has_siege_minion(1 - unit.team, unit.pos)


func _resolve_victory() -> void:
	var destroyed: Array = []
	for unit: Dictionary in units.values():
		if unit.kind == "core" and not unit.alive:
			destroyed.append(unit.team)
	if destroyed.size() == 2:
		winner = 2
	elif destroyed.size() == 1:
		winner = 1 - destroyed[0]
	if winner != -1:
		log_event("result", "Draw" if winner == 2 else ("West wins" if winner == 0 else "East wins"), {"winner": winner})
