extends MeshInstance3D
## Decorative geometry follows the authority's shape, wall LOS and current sight.
const MOTIFS: Dictionary = {
	"bas": {"Q":"runic_impact", "W":"guardian_sigil", "E":"stone_charge", "R":"earth_judgment"},
	"rio": {"Q":"comet_disc", "W":"star_anchor", "E":"starlight_step", "R":"constellation"},
	"nema": {"Q":"spirit_sapling", "W":"vine_wave", "E":"leaf_ward", "R":"ancient_roots"}
}
var rendered_points: Array[Vector2] = []
var rendered_motifs: Dictionary = {}
var _mesh: ImmediateMesh
var _state: Variant
var _effect: Dictionary = {}
var _allowed_points: Dictionary = {}
var _count: int = 0
var _sight_sources: Array[Dictionary] = []
var _raised_regions: Array[Rect2] = []
var _effect_visible: bool = false
var _effect_wall_clear: bool = false
var _effect_flat: bool = false

func style_for(hero_key: String, slot: String) -> Dictionary:
	var tint: Color = Color("ddc58a") if hero_key == "bas" else (Color("a8dfff") if hero_key == "rio" else Color("9ce3a8"))
	return {"motif": str(MOTIFS.get(hero_key, {}).get(slot, "")), "tint": tint}

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func refresh(state: Variant) -> void:
	_state = state
	_prepare_sight()
	rendered_points.clear()
	rendered_motifs.clear()
	_count = 0
	_mesh = ImmediateMesh.new()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for effect: Dictionary in state.effects:
		if bool(effect.get("telegraph", true)):
			continue
		var actor: Dictionary = state.units.get(int(effect.get("owner_id", -1)), {})
		if actor.is_empty():
			continue
		_prepare_effect(effect)
		var key: String = str(actor.hero)
		var slot: String = str(effect.get("slot", ""))
		var style: Dictionary = style_for(key, slot)
		var color: Color = style.tint if int(effect.get("team", 0)) == 0 else Color("ffad72")
		var fraction: float = clampf(1.0 - float(effect.get("remaining", 0.0)) / maxf(0.001, float(effect.get("duration", 0.22))), 0, 1)
		var before: int = _count
		_draw_pattern(key + slot, fraction, color)
		if _count > before:
			rendered_motifs[style.motif] = _count - before
	for actor: Dictionary in state.units.values():
		if actor.kind != "hero" or not actor.alive or actor.phase != "dash" or not state.is_visible(0, actor.id):
			continue
		_prepare_effect(actor.cast)
		var style: Dictionary = style_for(str(actor.hero), "E")
		var color: Color = style.tint if actor.team == 0 else Color("ffad72")
		var before: int = _count
		_draw_dash(actor, color)
		if _count > before:
			rendered_motifs[style.motif] = _count - before
	if _count == 0:
		for index: int in range(3):
			_mesh.surface_set_color(Color(0, 0, 0, 0))
			_mesh.surface_add_vertex(Vector3.ZERO)
	_mesh.surface_end()
	mesh = _mesh

func _prepare_sight() -> void:
	_sight_sources.clear()
	for unit: Dictionary in _state.units.values():
		if unit.team == 0 and unit.alive and unit.pos.is_finite() and unit.kind in ["hero", "minion", "tower", "core"]:
			_sight_sources.append(unit)
	_raised_regions.clear()
	for center: Vector2 in _state.map.high_ground_cells:
		_raised_regions.append(Rect2(center, Vector2.ZERO).grow(_state.map.HIGH_GROUND_PAD_RADIUS + 0.001))
	for ramp: Dictionary in _state.map.high_ground_ramps:
		_raised_regions.append(Rect2(ramp.low, Vector2.ZERO).expand(_state.map.ramp_high_edge(ramp)).grow(float(ramp.width) * 0.5 + 0.001))

func _prepare_effect(effect: Dictionary) -> void:
	_effect = effect
	_allowed_points.clear()
	var origin: Vector2 = effect.get("origin", Vector2.ZERO)
	var bounds := Rect2(origin, Vector2.ZERO)
	if effect.get("shape", "") in ["circle", "cone"]:
		bounds = bounds.grow(float(effect.get("radius", 0.0)))
	else:
		bounds = bounds.expand(effect.get("target", origin))
		for point: Vector2 in effect.get("points", []):
			bounds = bounds.expand(point)
		bounds = bounds.grow(float(effect.get("width", 0.0)) * 0.5)
	_effect_flat = true
	for region: Rect2 in _raised_regions:
		if bounds.intersects(region, true):
			_effect_flat = false
			break
	_effect_wall_clear = _clear_bounds(bounds)
	_effect_visible = false
	var corners: Array[Vector2] = [bounds.position, bounds.end, Vector2(bounds.position.x, bounds.end.y), Vector2(bounds.end.x, bounds.position.y)]
	for source: Dictionary in _sight_sources:
		var radius: float = 8.0 if source.kind == "minion" else 12.0
		var covers: bool = true
		for corner: Vector2 in corners:
			if source.pos.distance_squared_to(corner) > radius * radius:
				covers = false
				break
		if not covers or not _clear_bounds(bounds.expand(source.pos)):
			continue
		if _effect_flat or source.kind in ["tower", "core"] or _state.map.is_high_ground(source.pos):
			_effect_visible = true
			break

func _clear_bounds(bounds: Rect2) -> bool:
	# Every sight ray between points in this rectangle remains in the rectangle.
	# Reject the broad-phase proof whenever any authoritative wall touches it.
	for wall: Rect2 in _state.map.blockers:
		if bounds.intersects(wall, true):
			return false
	return true

func _draw_pattern(key: String, fraction: float, color: Color) -> void:
	var origin: Vector2 = _effect.get("origin", Vector2.ZERO)
	var direction: Vector2 = _effect.get("direction", Vector2.RIGHT)
	var rise: float = sin(PI * clampf(fraction + 0.08, 0, 1))
	var accent: Color = Color("82e5cd") if key.begins_with("bas") else Color("f4e7b5")
	if int(_effect.get("team", 0)) != 0:
		accent = Color("ffd6a0")
	match key:
		"basQ":
			for point: Vector2 in _samples(9, 0.48 + fraction * 0.34):
				_stone(point, 0.12, 0.16 + rise * 0.48, direction, color)
				_stroke(point - direction * 0.25, point, 0.055, 0.13, accent)
		"basW":
			var points: Array[Vector2] = _samples(6, 0.68)
			for index: int in range(points.size()):
				var point: Vector2 = points[index]
				var next: Vector2 = points[(index + 1) % points.size()]
				_stroke(point, next, 0.075, 0.14, color)
				_shield(point, (point - origin).orthogonal().normalized(), 0.24, 0.30 + rise * 0.42, accent)
		"basE":
			for point: Vector2 in _samples(8, 0.64):
				_chevron(point, direction, 0.20, 0.10, accent)
				_stone(point, 0.10, 0.25, direction, color)
		"basR":
			var points: Array[Vector2] = _samples(14, 0.70)
			for index: int in range(points.size()):
				var point: Vector2 = points[index]
				var offset: Vector2 = direction.orthogonal() * (0.22 if index % 2 == 0 else -0.22)
				_stone(point + offset, 0.23, 0.30 + rise * (0.65 + float(index % 3) * 0.12), direction, color.darkened(0.22))
				_chevron(point, direction, 0.18, 0.12, accent)
				if index > 0:
					_stroke(points[index - 1], point, 0.07, 0.10, accent)
		"rioQ":
			for point: Vector2 in _samples(7, 0.66):
				_star(point, 0.20, 0.22 + rise * 0.20, color)
				_stroke(point - direction * 0.34, point, 0.045, 0.20, accent)
		"rioW":
			for point: Vector2 in _samples(8, 0.48 + fraction * 0.30):
				_stroke(origin.lerp(point, 0.38), point, 0.045, 0.16, color)
				_star(point, 0.14, 0.20 + rise * 0.18, accent)
			_star(origin, 0.28, 0.24, color)
		"rioE":
			for point: Vector2 in _samples(5, 0.65):
				_crescent(point, direction, 0.25, 0.20 + rise * 0.18, color)
		"rioR":
			var points: Array[Vector2] = _samples(24, 0.72)
			for index: int in range(points.size()):
				var point: Vector2 = points[index]
				if index % 3 == 0:
					_star(point, 0.14, 0.25 + rise * 0.20, accent)
				if index > 0:
					_stroke(points[index - 1], point, 0.055, 0.16, color)
			if _effect.get("shape", "") == "triangle" and not points.is_empty():
				_stroke(points[-1], points[0], 0.055, 0.16, color)
				for vertex: Vector2 in _effect.get("points", []):
					_star(vertex, 0.28, 0.30 + rise * 0.25, accent)
		"nemaQ":
			for point: Vector2 in _samples(5, 0.52):
				var middle: Vector2 = origin.lerp(point, 0.55) + (point - origin).orthogonal() * 0.16
				_stroke(origin, middle, 0.07, 0.11, color.darkened(0.30))
				_stroke(middle, point, 0.055, 0.13, color)
				_leaf(point, (point - origin).normalized(), 0.18, 0.25 + rise * 0.25, color)
			_stone(origin, 0.10, 0.18 + rise * 0.70, direction, accent)
			_leaf(origin + direction * 0.14, direction, 0.26, 0.38 + rise * 0.38, color)
		"nemaW":
			_vines(0.10, 0.08 + rise * 0.24, color, false)
		"nemaE":
			for point: Vector2 in _samples(11, 0.40 + fraction * 0.36):
				_leaf(point, (point - origin).normalized(), 0.26, 0.38 + rise * 0.42, color)
				_stroke(origin.lerp(point, 0.84), point, 0.035, 0.11, accent)
		"nemaR":
			_vines(0.23, 0.15 + rise * 0.48, color, true)

func _samples(count: int, radius_fraction: float) -> Array[Vector2]:
	var result: Array[Vector2] = []
	var origin: Vector2 = _effect.get("origin", Vector2.ZERO)
	var target: Vector2 = _effect.get("target", origin)
	var shape: String = str(_effect.get("shape", ""))
	var direction: Vector2 = _effect.get("direction", Vector2.RIGHT)
	for index: int in range(count):
		var fraction: float = float(index) / maxf(1, count - 1)
		if shape in ["circle", "cone"]:
			var angle: float = deg_to_rad(float(_effect.get("angle", 360.0))) if shape == "cone" else TAU
			var theta: float = direction.angle() + angle * (float(index) / count - 0.5)
			result.append(origin + Vector2.from_angle(theta) * float(_effect.get("radius", 0.5)) * radius_fraction)
		elif shape == "triangle":
			var points: Array = _effect.get("points", [])
			if points.size() == 3:
				var edge_position: float = float(index) / count * 3.0
				var edge: int = int(edge_position)
				result.append(Vector2(points[edge]).lerp(points[(edge + 1) % 3], fmod(edge_position, 1.0)))
		else:
			result.append(origin.lerp(target, 0.05 + fraction * 0.90))
	return result

func _vines(amplitude: float, height: float, color: Color, binding: bool) -> void:
	var points: Array[Vector2] = _samples(22 if binding else 18, 0.66)
	var direction: Vector2 = _effect.get("direction", Vector2.RIGHT)
	if _effect.get("shape", "") == "line":
		direction = (Vector2(_effect.target) - Vector2(_effect.origin)).normalized()
	var normal: Vector2 = direction.orthogonal()
	for side: float in [-1.0, 1.0]:
		var previous := Vector2.ZERO
		for index: int in range(points.size()):
			var point: Vector2 = points[index] + normal * sin(float(index) * 0.85 + float(_state.time) * 3.0) * amplitude * side
			if index > 0:
				_stroke(previous, point, 0.065 if binding else 0.045, height, color.darkened(0.16))
			if index % 3 == 1:
				_leaf(point, normal * side, 0.17, height + 0.15, color)
				if binding:
					_stone(point, 0.07, height + 0.40, normal * side, color.darkened(0.32))
			previous = point

func _draw_dash(actor: Dictionary, color: Color) -> void:
	var direction: Vector2 = actor.facing
	for index: int in range(5):
		var point: Vector2 = actor.pos - direction * float(index) * 0.18
		if actor.hero == "bas":
			_chevron(point, direction, 0.23, 0.12, Color("93e8d0") if actor.team == 0 else color)
			for side: float in [-1.0, 1.0]:
				_stone(point + direction.orthogonal() * side * 0.26, 0.075, 0.16 + float(4 - index) * 0.035, direction, color)
		else:
			_crescent(point, direction, 0.24, 0.22, color)
			if index % 2 == 0:
				_star(point, 0.12, 0.48, Color("f5e6bd") if actor.team == 0 else color)

func _world(point: Vector2, height: float) -> Vector3:
	var ground: float = 0.0 if _effect_flat else _state.map.ground_height(point)
	return Vector3(point.x, ground + height, -point.y)

func _stroke(a: Vector2, b: Vector2, width: float, height: float, color: Color) -> void:
	var normal: Vector2 = (b - a).normalized().orthogonal() * width * 0.5
	_triangle(_world(a + normal, height), _world(a - normal, height), _world(b + normal, height), color)
	_triangle(_world(a - normal, height), _world(b - normal, height), _world(b + normal, height), color)

func _chevron(point: Vector2, direction: Vector2, size: float, height: float, color: Color) -> void:
	var normal: Vector2 = direction.orthogonal()
	_stroke(point - direction * size + normal * size, point, 0.055, height, color)
	_stroke(point - direction * size - normal * size, point, 0.055, height, color)

func _stone(point: Vector2, size: float, height: float, direction: Vector2, color: Color) -> void:
	var normal: Vector2 = direction.orthogonal()
	var corners: Array[Vector2] = [point + direction * size, point + normal * size, point - direction * size, point - normal * size]
	var top: Vector3 = _world(point + direction * size * 0.18, height + 0.10)
	for index: int in range(4):
		_triangle(_world(corners[index], 0.10), _world(corners[(index + 1) % 4], 0.10), top, color.darkened(float(index % 2) * 0.20))

func _shield(point: Vector2, tangent: Vector2, size: float, height: float, color: Color) -> void:
	var bottom: Vector3 = _world(point, 0.13)
	var left: Vector3 = _world(point - tangent * size, height)
	var right: Vector3 = _world(point + tangent * size, height)
	var top: Vector3 = _world(point, height + 0.18)
	_triangle(bottom, left, right, Color(color, 0.44))
	_triangle(left, top, right, Color(color, 0.72))

func _star(point: Vector2, size: float, height: float, color: Color) -> void:
	for index: int in range(4):
		var direction: Vector2 = Vector2.from_angle(PI * 0.5 * index)
		var normal: Vector2 = direction.orthogonal()
		_triangle(_world(point + direction * size, height), _world(point + normal * size * 0.24, height), _world(point - normal * size * 0.24, height), color)

func _crescent(point: Vector2, direction: Vector2, size: float, height: float, color: Color) -> void:
	for index: int in range(8):
		var angle: float = direction.angle() - PI * 0.65 + float(index) * PI * 1.3 / 8.0
		var next_angle: float = angle + PI * 1.3 / 8.0
		_stroke(point + Vector2.from_angle(angle) * size, point + Vector2.from_angle(next_angle) * size, 0.045, height, color)

func _leaf(point: Vector2, direction: Vector2, size: float, height: float, color: Color) -> void:
	var normal: Vector2 = direction.orthogonal()
	var bottom: Vector3 = _world(point - direction * size * 0.30, height - size * 0.40)
	var tip: Vector3 = _world(point + direction * size * 0.60, height + size)
	var left: Vector3 = _world(point - normal * size * 0.48, height)
	var right: Vector3 = _world(point + normal * size * 0.48, height)
	_triangle(bottom, left, tip, color.darkened(0.16))
	_triangle(bottom, tip, right, color)

func _allowed(point: Vector2) -> bool:
	if _allowed_points.has(point):
		return bool(_allowed_points[point])
	var allowed: bool = _state._abilities.contains(_effect, point, 0.0)
	if allowed and not _effect_visible:
		allowed = _state.is_point_visible_for_sources(0, point, _sight_sources)
	if allowed and not _effect_wall_clear:
		var source: Vector2 = _state._abilities.effect_origin(_effect, point)
		allowed = _state.map.has_line_of_sight(source, point)
	_allowed_points[point] = allowed
	return allowed

func _triangle(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var first := Vector2(a.x, -a.z)
	var second := Vector2(b.x, -b.z)
	var third := Vector2(c.x, -c.z)
	# Whole tiny triangles are checked so decorative corners never cross a wall,
	# a sight boundary or the actual effect footprint.
	for point: Vector2 in [first, second, third, (first + second) * 0.5, (second + third) * 0.5, (third + first) * 0.5, (first + second + third) / 3.0]:
		if not _allowed(point):
			return
	rendered_points.append((first + second + third) / 3.0)
	color.a *= 0.82
	for vertex: Vector3 in [a, b, c]:
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(vertex)
	_count += 3
