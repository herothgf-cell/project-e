extends RefCounted
## Kit geometry and staged effects. No presentation code applies damage.

const SKILLS: Dictionary = {
	"bas": ["룬권 파쇄", "수호 각인", "거석 돌진", "대지의 심판"],
	"rio": ["왕복 혜성", "별무리 닻", "별빛 도약", "삼각 성좌"],
	"nema": ["정령목 심기", "덩굴 물결", "잎새의 가호", "고대숲의 결박"],
}

const SKILL_HELP: Dictionary = {
	"bas": [
		"룬 건틀릿을 휘둘러 전방 3.2m 부채꼴을 파쇄합니다.\n피해 80 + 위력 55%, 0.7초 동안 20% 둔화.\n보이는 적 영웅에게 적중하면 룬을 1중첩 얻습니다.",
		"3m 안의 지면에 수호 룬을 새깁니다.\n반경 2.2m의 아군 영웅에게 1.5초 동안\n100 + 위력 35%의 보호막을 부여합니다.",
		"건틀릿을 앞세워 최대 4.2m 돌진합니다.\n처음 만나는 영웅 앞에서 멈추며 적에게\n45 + 위력 40% 피해와 짧은 밀치기를 줍니다.\n보이는 적 영웅 적중 시 룬 1중첩을 얻습니다.",
		"두 건틀릿으로 땅을 내리쳐 균열을 뻗습니다.\n전방 최대 7m, 폭 2.8m에 150 + 위력 85% 피해.\n0.65초 속박하며, 보이는 적 영웅 적중 시\n룬을 1중첩 얻습니다.",
	],
	"rio": [
		"별빛 원반을 최대 8m 던졌다가 되돌립니다.\n갈 때 70 + 위력 45%, 올 때 50 + 위력 35% 피해.\n원반에서 13m 안의 닻으로 귀환 경로를 바꿉니다.\n왕복 두 적중 때 모두 보이는 같은 적 영웅을\n맞히면 마나 8을 회복합니다.",
		"5m 안에 2초 동안 별무리 닻을 남깁니다.\n반경 1.2m에 40 + 위력 25% 피해를 주고\n0.6초 동안 20% 둔화시킵니다.\n왕복 혜성은 귀환을 시작할 때 닻을 소모합니다.",
		"별빛 궤적을 따라 최대 3.2m 빠르게 돌진합니다.\n도착 후 1.5초 안에 발사하는 다음 기본 공격에\n40 + 위력 25%의 추가 피해를 부여합니다.",
		"세 별을 이어 삼각형의 가장자리를 터뜨립니다.\n폭 0.8m의 변에 140 + 위력 80% 피해를 주고\n1초 동안 30% 둔화시킵니다.\n삼각형의 중앙은 안전합니다.",
	],
	"nema": [
		"6m 안에 8초 동안 살아 있는 정령목을 심습니다.\n반경 1.25m에 65 + 위력 35% 피해.\n정령목은 체력 160, 최대 2그루이며\n세 번째를 심으면 가장 오래된 정령목이 사라집니다.",
		"8m 안의 정령목 또는 연결에 덩굴 물결을 일으킵니다.\n1그루는 반경 1.5m, 2그루는 연결된 폭 1.4m에\n75 + 위력 45% 피해와 0.9초 동안 25% 둔화.\n준비 중 연결된 정령목이 사라지면 취소됩니다.",
		"잎새를 펼쳐 자신과 전방 6m의 아군을 감쌉니다.\n70도 부채꼴 안의 아군 영웅에게 1.8초 동안\n100 + 위력 40% 보호막을 부여하고\n범위·시야 안의 자기 정령목 체력을 50 회복합니다.",
		"연결된 정령목 2그루 사이에 고대 뿌리를 깨웁니다.\n연결의 최근접점이 자신에게서 8m 안이어야 합니다.\n폭 2.2m에 120 + 위력 65% 피해와 0.6초 속박.\n발동하면 적중 여부와 관계없이 두 정령목을 소모합니다.\n준비 중 참여 정령목이 사라지면 취소됩니다.",
	],
}

const PASSIVES: Dictionary = {
	"bas": {
		"name": "룬 심장",
		"description": "Q·E·R로 보이는 적 영웅 적중 시 룬 1중첩.\n6초 안에 2중첩을 모아 보이는 적 영웅을 기본 공격하면\n중첩을 소모해 2초간 80 + 위력 25% 보호막을 얻습니다.",
	},
	"rio": {
		"name": "별의 순환",
		"description": "왕복 혜성의 출발·귀환 적중 때 모두 보이는\n같은 적 영웅에게 피해를 주면 마나 8을 회복합니다.\n원반을 한 번 던질 때 한 번 발동합니다.",
	},
	"nema": {
		"name": "숲의 품",
		"description": "정령목 2그루 사이의 연결에 들어온 아군 영웅에게\n1.2초간 60 + 위력 20% 보호막을 부여합니다.\n같은 아군은 4초 뒤 다시 들어와야 발동합니다.",
	},
}

const CONFIG: Dictionary = {
	"bas": {"Q": [16.0, 3.0, 0.20, 0.18], "W": [18.0, 5.0, 0.12, 0.12], "E": [20.0, 5.0, 0.12, 0.16], "R": [32.0, 16.0, 0.65, 0.25]},
	"rio": {"Q": [20.0, 4.0, 0.14, 0.12], "W": [14.0, 4.0, 0.20, 0.12], "E": [18.0, 5.5, 0.06, 0.14], "R": [32.0, 15.0, 0.60, 0.20]},
	"nema": {"Q": [14.0, 2.5, 0.25, 0.12], "W": [18.0, 3.5, 0.35, 0.12], "E": [18.0, 5.0, 0.16, 0.14], "R": [30.0, 18.0, 0.60, 0.20]},
}


func preview(state: Variant, actor: Dictionary, slot: String, target: Vector2) -> Dictionary:
	var plan: Dictionary = {"shape": "circle", "origin": actor.pos, "target": target, "radius": 0.0, "width": 0.0, "angle": 0.0, "points": [], "team": actor.team, "owner_id": actor.id, "remaining": 0.0, "duration": 0.0, "telegraph": true, "valid": false, "reason": "Invalid ability", "slot": slot, "pins": []}
	if not CONFIG.has(actor.hero) or not CONFIG[actor.hero].has(slot) or not target.is_finite():
		return plan
	var values: Array = CONFIG[actor.hero][slot]
	plan.merge({"cost": values[0], "cooldown": values[1], "windup": values[2], "recovery": values[3], "power": actor.power}, true)
	plan.remaining = plan.windup
	plan.duration = plan.windup
	var delta: Vector2 = target - actor.pos
	var distance: float = delta.length()
	var direction: Vector2 = delta.normalized() if distance > 0.0001 else actor.facing
	var direction_required: bool = slot in ["Q", "E", "R"] if actor.hero == "bas" else (slot in ["Q", "E"] if actor.hero == "rio" else slot == "E")
	if direction_required and distance < 0.0001:
		plan.reason = "Choose a direction"
		return plan
	plan.direction = direction
	var aim_valid: bool = true
	match actor.hero + slot:
		"basQ":
			plan.merge({"shape": "cone", "radius": 3.2, "angle": 80.0, "target": actor.pos + direction * 3.2}, true)
		"basW":
			plan.merge({"shape": "circle", "origin": target, "radius": 2.2}, true)
			aim_valid = distance <= 3.0 and state.map.is_walkable(target, 0.0) and state.map.has_line_of_sight(actor.pos, target)
		"basE", "rioE":
			var length: float = 4.2 if actor.hero == "bas" else 3.2
			plan.merge({"shape": "line", "target": state.map.clip_walk(actor.pos, actor.pos + direction * length), "width": 0.9, "dash_distance": length, "dash_speed": 14.0 if actor.hero == "bas" else 16.0}, true)
		"basR":
			plan.merge({"shape": "line", "target": state.map.clip_wall(actor.pos, actor.pos + direction * 7.0, 1.4), "width": 2.8}, true)
		"rioQ":
			plan.merge({"shape": "line", "target": state.map.clip_wall(actor.pos, actor.pos + direction * 8.0, 0.35), "width": 0.7}, true)
			for projectile: Dictionary in state.projectiles:
				if projectile.kind == "rio_disc" and projectile.owner_id == actor.id:
					aim_valid = false
		"rioW":
			plan.merge({"shape": "circle", "origin": target, "radius": 1.2}, true)
			aim_valid = distance <= 5.0 and state.map.is_walkable(target, 0.0) and state.map.has_line_of_sight(actor.pos, target)
		"rioR":
			var third: Vector2 = (actor.pos + target) * 0.5 + Vector2(-direction.y, direction.x) * 3.0
			plan.merge({"shape": "triangle", "points": [actor.pos, target, third], "width": 0.8}, true)
			aim_valid = distance >= 2.0 and distance <= 7.0 and state.map.is_ground(target) and state.map.is_ground(third) and state.map.has_line_of_sight(actor.pos, target, 0.4) and state.map.has_line_of_sight(target, third, 0.4) and state.map.has_line_of_sight(third, actor.pos, 0.4)
		"nemaQ":
			plan.merge({"shape": "circle", "origin": target, "radius": 1.25}, true)
			aim_valid = distance <= 6.0 and valid_pin_point(state, actor, target) and state.map.has_line_of_sight(actor.pos, target)
		"nemaW", "nemaR":
			var pins: Array = live_pins(state, actor)
			if pins.is_empty() or (slot == "R" and pins.size() != 2):
				plan.reason = "Place two linked pins" if slot == "R" else "Place a pin first"
				return plan
			plan.pins = pins.duplicate()
			var first: Vector2 = state.units[pins[0]].pos
			if pins.size() == 1:
				plan.merge({"shape": "circle", "origin": first, "radius": 1.5}, true)
				aim_valid = actor.pos.distance_to(first) <= 8.0
			else:
				var last: Vector2 = state.units[pins[1]].pos
				plan.merge({"shape": "line", "origin": first, "target": last, "width": 1.4 if slot == "W" else 2.2}, true)
				aim_valid = linked(state, pins) and state.map.segment_distance(actor.pos, first, last) <= 8.0
		"nemaE":
			plan.merge({"shape": "cone", "radius": 6.0, "angle": 70.0, "target": actor.pos + direction * 6.0}, true)
	plan.valid = aim_valid
	plan.reason = "" if aim_valid else "Aim outside legal range or terrain / pins not linked"
	return plan


func valid_pin_point(state: Variant, actor: Dictionary, point: Vector2) -> bool:
	if not state.map.is_walkable(point, 0.35):
		return false
	for pin_id: int in live_pins(state, actor):
		if state.units[pin_id].pos.distance_to(point) < 1.0:
			return false
	return true


func live_pins(state: Variant, actor: Dictionary) -> Array:
	var result: Array = []
	for pin_id: int in actor.pins:
		if state.units.has(pin_id) and state.units[pin_id].alive:
			result.append(pin_id)
	return result


func linked(state: Variant, pins: Array) -> bool:
	if pins.size() != 2 or not state.units.has(pins[0]) or not state.units.has(pins[1]):
		return false
	var first: Vector2 = state.units[pins[0]].pos
	var last: Vector2 = state.units[pins[1]].pos
	var distance: float = first.distance_to(last)
	return distance >= 1.0 and distance <= 8.0 and state.map.has_line_of_sight(first, last)


func resolve(state: Variant, actor: Dictionary, cast: Dictionary) -> void:
	if not actor.alive:
		return
	for pin_id: int in cast.pins:
		if not state.units.has(pin_id) or not state.units[pin_id].alive:
			state.cancel_action(actor)
			return
	var power: float = cast.power
	match actor.hero + cast.slot:
		"basQ":
			area_damage(state, actor, cast, 80.0 + 0.55 * power, "slow", 0.7, 0.2)
		"basW":
			_shield_area(state, actor, cast, 100.0 + 0.35 * power, 1.5, false)
		"basE", "rioE":
			actor.phase = "dash"
			actor.dash_left = cast.dash_distance
			actor.phase_left = 0.0
			return
		"basR":
			area_damage(state, actor, cast, 150.0 + 0.85 * power, "root", 0.65)
		"rioQ":
			state.projectiles.append({"id": cast.id, "cast_id": cast.id, "kind": "rio_disc", "pos": actor.pos, "owner_id": actor.id, "team": actor.team, "direction": cast.direction, "target_pos": actor.pos + cast.direction * 8.0, "remaining": 2.2, "distance": 8.0, "phase": "outbound", "turn_left": 0.2, "power": power, "outbound_visible": {}, "refunded": false})
		"rioW":
			area_damage(state, actor, cast, 40.0 + 0.25 * power, "slow", 0.6, 0.2)
			actor.return_mark = {"pos": cast.origin, "expires": state.time + 2.0}
		"rioR":
			area_damage(state, actor, cast, 140.0 + 0.80 * power, "slow", 1.0, 0.3)
		"nemaQ":
			if valid_pin_point(state, actor, cast.origin):
				state.spawn_pin(actor, cast.origin)
				area_damage(state, actor, cast, 65.0 + 0.35 * power)
		"nemaW":
			area_damage(state, actor, cast, 75.0 + 0.45 * power, "slow", 0.9, 0.25)
		"nemaE":
			_shield_area(state, actor, cast, 100.0 + 0.40 * power, 1.8, true)
		"nemaR":
			area_damage(state, actor, cast, 120.0 + 0.65 * power, "root", 0.60)
			for pin_id: int in cast.pins:
				state.remove_pin(pin_id)
	var visual: Dictionary = cast.duplicate(true)
	visual.telegraph = false
	visual.remaining = 0.22
	visual.duration = 0.22
	state.effects.append(visual)
	actor.phase = "recovery"
	actor.phase_left = cast.recovery


func area_damage(state: Variant, actor: Dictionary, cast: Dictionary, amount: float, control: String = "", duration: float = 0.0, strength: float = 0.0) -> void:
	var pressure_earned: bool = false
	for unit: Dictionary in state.units.values():
		if not unit.alive or unit.team == actor.team or not contains(cast, unit.pos, unit.radius):
			continue
		var origin: Vector2 = effect_origin(cast, unit.pos)
		if not state.map.has_line_of_sight(origin, unit.pos):
			continue
		var visible: bool = state.is_visible(actor.team, unit.id)
		var dealt: float = state.apply_damage(actor.id, unit.id, amount, cast.id, "impact")
		if dealt > 0.0:
			if control != "":
				state.apply_cc(unit.id, control, duration, strength)
			if actor.hero == "bas" and cast.slot in ["Q", "R"] and unit.kind == "hero" and visible:
				pressure_earned = true
	if pressure_earned:
		gain_pressure(actor)


func _shield_area(state: Variant, actor: Dictionary, cast: Dictionary, amount: float, duration: float, repair: bool) -> void:
	for unit: Dictionary in state.units.values():
		if not unit.alive or unit.team != actor.team:
			continue
		var self_included: bool = repair and unit.id == actor.id
		if not self_included and (not contains(cast, unit.pos, unit.radius) or not state.map.has_line_of_sight(cast.origin, unit.pos)):
			continue
		if unit.kind == "hero":
			state.add_shield(unit.id, "%d:%s" % [actor.id, cast.slot], amount, duration)
		elif repair and unit.kind == "pin" and unit.owner_id == actor.id:
			unit.hp = minf(160.0, unit.hp + 50.0)


func dash_step(state: Variant, actor: Dictionary, delta: float) -> void:
	var cast: Dictionary = actor.cast
	if cast.is_empty():
		actor.phase = "idle"
		return
	var travel: float = minf(actor.dash_left, cast.dash_speed * delta)
	var direction: Vector2 = cast.direction
	var start: Vector2 = actor.pos
	var goal: Vector2 = state.map.clip_walk(start, start + direction * travel, actor.radius)
	var contact: Dictionary = {}
	var best_distance: float = start.distance_to(goal)
	for other: Dictionary in state.units.values():
		if other.kind != "hero" or not other.alive or other.id == actor.id:
			continue
		var offset: Vector2 = other.pos - start
		var along: float = offset.dot(direction)
		var perpendicular: float = absf(offset.cross(direction))
		var radius: float = actor.radius + other.radius
		if along < 0.0 or perpendicular >= radius:
			continue
		var collision: float = maxf(0.0, along - sqrt(maxf(0.0, radius * radius - perpendicular * perpendicular)))
		if collision <= best_distance + 0.00001:
			best_distance = collision
			contact = other
	actor.pos = start + direction * maxf(0.0, best_distance - (0.002 if not contact.is_empty() else 0.0))
	actor.dash_left -= start.distance_to(actor.pos)
	var blocked: bool = start.distance_to(goal) < travel - 0.001 or not contact.is_empty()
	if not contact.is_empty() and contact.team != actor.team and actor.hero == "bas":
		var visible: bool = state.is_visible(actor.team, contact.id)
		var dealt: float = state.apply_damage(actor.id, contact.id, 45.0 + 0.40 * cast.power, cast.id, "contact")
		if dealt > 0.0:
			if visible:
				gain_pressure(actor)
			var allowed: float = state.apply_cc(contact.id, "knockback", 0.12)
			if allowed > 0.0:
				contact.knockback = {"direction": direction, "remaining": allowed, "speed": 0.8 / 0.12}
	if blocked or actor.dash_left < 0.001:
		if actor.hero == "rio":
			actor.empowered_left = 1.5
			actor.empowered_damage = 40.0 + 0.25 * cast.power
		actor.phase = "recovery"
		actor.phase_left = cast.recovery


func gain_pressure(actor: Dictionary) -> void:
	actor.pressure = mini(2, actor.pressure + 1)
	actor.pressure_left = 6.0


func tick_devices(state: Variant) -> void:
	for actor: Dictionary in state.units.values():
		if actor.kind != "hero" or actor.hero != "nema" or not actor.alive:
			continue
		var pins: Array = live_pins(state, actor)
		var inside: Dictionary = {}
		if linked(state, pins):
			var line: Dictionary = {"shape": "line", "origin": state.units[pins[0]].pos, "target": state.units[pins[1]].pos, "width": 0.5}
			for ally: Dictionary in state.units.values():
				if ally.kind != "hero" or ally.team != actor.team or not ally.alive:
					continue
				if contains(line, ally.pos, ally.radius) and state.map.has_line_of_sight(effect_origin(line, ally.pos), ally.pos):
					inside[ally.id] = true
					if not actor.passive_inside.has(ally.id) and state.time >= actor.passive_ready.get(ally.id, -1.0):
						state.add_shield(ally.id, "%d:passive" % actor.id, 60.0 + 0.2 * actor.power, 1.2)
						actor.passive_ready[ally.id] = state.time + 4.0
		actor.passive_inside = inside


func disc_step(state: Variant, projectile: Dictionary, delta: float) -> bool:
	if not state.units.has(projectile.owner_id) or not state.units[projectile.owner_id].alive:
		return false
	var actor: Dictionary = state.units[projectile.owner_id]
	projectile.remaining -= delta
	if projectile.remaining <= 0.0:
		return false
	if projectile.phase == "turn":
		projectile.turn_left -= delta
		if projectile.turn_left <= 0.00001:
			var destination: Vector2 = actor.pos
			if not actor.return_mark.is_empty() and actor.return_mark.expires > state.time and projectile.pos.distance_to(actor.return_mark.pos) <= 13.0:
				destination = actor.return_mark.pos
				actor.return_mark.clear()
			var offset: Vector2 = destination - projectile.pos
			projectile.target_pos = projectile.pos + offset.limit_length(13.0)
			projectile.direction = offset.normalized()
			projectile.distance = minf(13.0, offset.length())
			projectile.phase = "return"
		return true
	var speed: float = 12.0 if projectile.phase == "outbound" else 16.0
	var travel: float = minf(projectile.distance, speed * delta)
	var start: Vector2 = projectile.pos
	var goal: Vector2 = state.map.clip_wall(start, start + projectile.direction * travel, 0.35)
	var blocked: bool = start.distance_to(goal) < travel - 0.001
	projectile.pos = goal
	projectile.distance -= start.distance_to(goal)
	for target: Dictionary in state.units.values():
		if not target.alive or target.team == actor.team or state.map.segment_distance(target.pos, start, goal) > 0.35 + target.radius:
			continue
		if not state.map.has_line_of_sight(Geometry2D.get_closest_point_to_segment(target.pos, start, goal), target.pos):
			continue
		var visible: bool = state.is_visible(actor.team, target.id)
		var amount: float = 70.0 + 0.45 * projectile.power if projectile.phase == "outbound" else 50.0 + 0.35 * projectile.power
		var dealt: float = state.apply_damage(actor.id, target.id, amount, projectile.cast_id, projectile.phase)
		if dealt > 0.0 and visible and target.kind == "hero":
			if projectile.phase == "outbound":
				projectile.outbound_visible[target.id] = true
			elif projectile.outbound_visible.has(target.id) and not projectile.refunded:
				actor.energy = minf(actor.max_energy, actor.energy + 8.0)
				projectile.refunded = true
	if blocked or projectile.distance <= 0.001:
		if projectile.phase == "outbound":
			projectile.phase = "turn"
			projectile.turn_left = 0.20
		else:
			return false
	return true


static func contains(shape: Dictionary, point: Vector2, radius: float) -> bool:
	var origin: Vector2 = shape.origin
	match shape.shape:
		"circle":
			return point.distance_to(origin) <= shape.radius + radius
		"cone":
			var offset: Vector2 = point - origin
			var distance: float = offset.length()
			if distance <= radius:
				return true
			if distance > shape.radius + radius:
				return false
			var facing: Vector2 = (shape.target - origin).normalized()
			var half_angle: float = deg_to_rad(shape.angle * 0.5)
			if absf(facing.angle_to(offset)) <= half_angle:
				return true
			# Test the finite radial edges, including their rounded capsule corners.
			# Expanding angle and distance independently creates hits outside the sector.
			for side: float in [-1.0, 1.0]:
				var edge: Vector2 = origin + facing.rotated(half_angle * side) * shape.radius
				if point.distance_to(Geometry2D.get_closest_point_to_segment(point, origin, edge)) <= radius:
					return true
			return false
		"line":
			var length: float = origin.distance_to(shape.target)
			var direction: Vector2 = (shape.target - origin).normalized()
			var offset: Vector2 = point - origin
			var along: float = offset.dot(direction)
			var across: float = absf(offset.cross(direction))
			var dx: float = maxf(0.0, maxf(-along, along - length))
			var dy: float = maxf(0.0, across - shape.width * 0.5)
			return dx * dx + dy * dy <= radius * radius
		"triangle":
			for index: int in range(3):
				if point.distance_to(Geometry2D.get_closest_point_to_segment(point, shape.points[index], shape.points[(index + 1) % 3])) <= shape.width * 0.5 + radius:
					return true
	return false


static func effect_origin(shape: Dictionary, point: Vector2) -> Vector2:
	if shape.shape == "line":
		return Geometry2D.get_closest_point_to_segment(point, shape.origin, shape.target)
	if shape.shape == "triangle":
		var nearest: Vector2 = shape.points[0]
		for index: int in range(3):
			var candidate: Vector2 = Geometry2D.get_closest_point_to_segment(point, shape.points[index], shape.points[(index + 1) % 3])
			if point.distance_squared_to(candidate) < point.distance_squared_to(nearest):
				nearest = candidate
		return nearest
	return shape.origin
