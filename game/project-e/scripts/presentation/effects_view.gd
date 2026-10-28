extends MeshInstance3D
## Draws authoritative geometry without computing damage or inventing hit results.

var _geometry: ImmediateMesh
var _vertices: int = 0
var _visibility_battle: Variant
var _visible_points: Dictionary = {}
var _wall_map: Variant
var _sight_sources: Array[Dictionary] = []
var _map_signature: int = 0
var _radial_shapes: Dictionary = {}
var _observer_shapes: Dictionary = {}
var _clipped_radials: Dictionary = {}
var terrain_map: Variant
const RADIAL_CACHE_LIMIT: int = 32


func _ready() -> void:
	var material_value := StandardMaterial3D.new()
	material_value.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_value.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_value.vertex_color_use_as_albedo = true
	material_value.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_value.no_depth_test = false
	material_override = material_value
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func redraw(battle: Variant, preview: Dictionary, selected: int, destination: Variant) -> void:
	_geometry = ImmediateMesh.new()
	_geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_vertices = 0
	_visibility_battle = null
	_wall_map = battle.map
	_visible_points.clear()
	_prepare_sight(battle)
	for effect: Dictionary in battle.effects:
		if not _can_show(battle, effect):
			continue
		var color := Color("35bcb9") if int(effect.get("team", 0)) == 0 else Color("f17d44")
		var telegraph: bool = bool(effect.get("telegraph", false))
		color.a = 0.14 if telegraph else 0.24
		# A visible origin does not authorize revealing an enemy line's far endpoint.
		_visibility_battle = battle if int(effect.get("team", 0)) != 0 else null
		_shape(effect, color, int(effect.get("team", 0)) == 1, false)
		_visibility_battle = null
	_persistent_cues(battle)
	for projectile: Dictionary in battle.projectiles:
		var point: Vector2 = projectile.get("pos", Vector2.ZERO)
		# Basic attacks track their target; even friendly ones must disappear in fog.
		# Own skill trajectories are already known and do not expose a hidden target.
		var known_skill: bool = int(projectile.get("team", 0)) == 0 and str(projectile.get("kind", "")) == "rio_disc"
		if not known_skill and not battle.is_point_visible(0, point):
			continue
		var color := Color("76fff1") if int(projectile.get("team", 0)) == 0 else Color("ffb462")
		var radius: float = 0.35 if "disc" in str(projectile.get("kind", "")) else 0.16
		_disc(point, radius, color, 0.65)
		_ring(point, radius + 0.07, 0.045, Color("fff4d8"), false, 0.66)
	if not preview.is_empty():
		var color := Color(0.29, 0.90, 0.78, 0.12) if bool(preview.get("valid", false)) else Color(0.96, 0.37, 0.31, 0.10)
		_shape(preview, color, false, true)
	if selected >= 0 and battle.units.has(selected) and battle.is_visible(0, selected):
		var unit: Dictionary = battle.units[selected]
		if unit.alive:
			_ring(unit.pos, float(unit.radius) + 0.24, 0.08, Color("ffd393"), true, 0.105)
	if destination is Vector2:
		_ring(destination, 0.42, 0.06, Color("d5fff0"), false, 0.075)
		for side: float in [-1.0, 1.0]:
			_band(destination + Vector2(side * 0.58, 0), destination + Vector2(side * 0.83, 0), 0.05, Color("d5fff0"))
	# An empty surface is invalid, so use a fully transparent degenerate triangle.
	if _vertices == 0:
		_triangle(Vector2.ZERO, Vector2.ZERO, Vector2.ZERO, Color(0, 0, 0, 0))
	_geometry.surface_end()
	mesh = _geometry


func _can_show(battle: Variant, effect: Dictionary) -> bool:
	if int(effect.get("team", 0)) == 0:
		return true
	if str(effect.get("shape", "")) in ["circle", "cone"]:
		return not _radial_sources(effect).is_empty()
	# Lines are clipped triangle by triangle, including when only their far end is seen.
	if str(effect.get("shape", "")) in ["line", "triangle"]:
		return true
	return battle.is_point_visible(0, effect.get("origin", Vector2.ZERO))


func _persistent_cues(battle: Variant) -> void:
	for actor: Dictionary in battle.units.values():
		if actor.kind != "hero" or not actor.alive:
			continue
		var enemy: bool = int(actor.team) != 0
		var color := Color("43d4bf") if not enemy else Color("f8a16b")
		_visibility_battle = battle if enemy else null
		if actor.hero == "nema":
			# The authority validates pin lifetime, owner life, distance and obstruction.
			# Pin visibility is independent from the owner's visibility.
			var link: Dictionary = battle.get_pin_link(actor.id)
			if not link.is_empty():
				var fill := Color(color.r, color.g, color.b, 0.16)
				_ground_line(link.origin, link.target, float(link.width), fill, color, 0.045, enemy)
		elif actor.hero == "rio" and not actor.return_mark.is_empty():
			var mark: Dictionary = actor.return_mark
			var remaining: float = maxf(0.0, float(mark.expires) - float(battle.time))
			var point: Vector2 = mark.pos
			if remaining > 0.0 and (not enemy or _point_visible(point)):
				# A persistent ring is a return location, not a lingering W damage area.
				_ring(point, 0.54, 0.065, color, enemy, 0.085)
				# W's two-second lifetime comes from the active mark's expiry timestamp.
				_ring(point, 0.73, 0.06, Color("fff0b7"), false, 0.09, clampf(remaining / 2.0, 0.0, 1.0))
		_visibility_battle = null
	for projectile: Dictionary in battle.projectiles:
		if str(projectile.get("kind", "")) != "rio_disc" or str(projectile.get("phase", "")) != "return" or not projectile.has("target_pos"):
			continue
		var owner_id: int = int(projectile.get("owner_id", -1))
		if not battle.units.has(owner_id) or not battle.units[owner_id].alive:
			continue
		var enemy: bool = int(projectile.get("team", 0)) != 0
		var origin: Vector2 = projectile.pos
		var endpoint: Vector2 = projectile.target_pos
		var color := Color("a7efdc") if not enemy else Color("fbc298")
		_visibility_battle = battle if enemy else null
		# target_pos is the fixed destination chosen by the simulation at turnaround.
		_ground_line(origin, endpoint, 0.075, color, color, 0.025, enemy)
		if not enemy or _point_visible(endpoint):
			_ring(endpoint, 0.30, 0.045, color, enemy, 0.09)
		_visibility_battle = null


func _ground_line(a: Vector2, b: Vector2, width: float, fill: Color, edge: Color, stroke: float, dashed: bool) -> void:
	var length: float = a.distance_to(b)
	if length < 0.0001:
		return
	var normal := Vector2(-(b - a).y, (b - a).x).normalized()
	# Short cells let observed parts remain visible without bridging a fog interval.
	var count: int = maxi(1, ceili(length / 0.18)) if _visibility_battle != null else 1
	for index: int in range(count):
		var start: Vector2 = a.lerp(b, float(index) / count)
		var finish: Vector2 = a.lerp(b, float(index + 1) / count)
		_band(start, finish, width, fill)
		if not dashed or index % 4 < 2:
			for side: float in [-1.0, 1.0]:
				var offset: Vector2 = normal * maxf(0, width - stroke) * 0.5 * side
				_band(start + offset, finish + offset, stroke, edge, false, 0.08)
	# These caps belong only to the actual endpoints, not to a visibility boundary.
	for point: Vector2 in [a, b]:
		var offset: Vector2 = normal * maxf(0, width - stroke) * 0.5
		_band(point - offset, point + offset, stroke, edge, false, 0.08)


func _point_visible(point: Vector2) -> bool:
	if _visibility_battle == null:
		return true
	if not _visible_points.has(point):
		_visible_points[point] = _visibility_battle.is_point_visible_for_sources(0, point, _sight_sources)
	return bool(_visible_points[point])


func _shape(effect: Dictionary, color: Color, enemy: bool, aiming: bool) -> void:
	var origin: Vector2 = effect.get("origin", Vector2.ZERO)
	var target: Vector2 = effect.get("target", origin)
	var width: float = maxf(0.02, float(effect.get("width", 0.8)))
	var line: Color = Color(color.r, color.g, color.b, 0.95)
	var stroke: float = 0.10 if enemy else 0.065
	if aiming:
		stroke = 0.085
	match str(effect.get("shape", "circle")):
		"circle":
			_radial_shape(effect, color, stroke, line, enemy)
		"cone":
			_radial_shape(effect, color, stroke, line, enemy)
		"line":
			if _visibility_battle != null:
				_ground_line(origin, target, width, color, line, stroke, enemy)
			else:
				var points: Array[Vector2] = _rectangle(origin, target, width)
				_polygon(points, color)
				_outline(points, stroke, line, enemy)
		"triangle":
			var points: Array = effect.get("points", [])
			if points.size() >= 3:
				for i: int in range(3):
					var a: Vector2 = points[i]
					var b: Vector2 = points[(i + 1) % 3]
					if _visibility_battle != null:
						_ground_line(a, b, width, color, line, stroke, enemy)
						continue
					_polygon(_rectangle(a, b, width), color)
					_disc(a, width * 0.5, color)
					var normal := Vector2(-(b - a).y, (b - a).x).normalized() * width * 0.5
					_band(a + normal, b + normal, stroke, line, enemy)
					_band(a - normal, b - normal, stroke, line, enemy)
					_ring(a, width * 0.5, stroke, line, enemy)
	if bool(effect.get("telegraph", false)) and float(effect.get("duration", 0)) > 0:
		var progress: float = clampf(1.0 - float(effect.get("remaining", 0)) / float(effect.duration), 0, 1)
		# Timing tick is separate from the actual damage outline.
		_ring(origin, 0.24, 0.055, Color(line.r, line.g, line.b, 0.9), false, 0.10, progress)


func _radial_shape(effect: Dictionary, fill: Color, stroke: float, edge: Color, dashed: bool) -> void:
	var key: Array = [effect.get("shape", "circle"), effect.origin, effect.get("target", effect.origin), effect.get("radius", 0.0), effect.get("angle", 0.0), stroke, dashed]
	var sources: Array[Dictionary] = []
	if _visibility_battle != null:
		sources = _radial_sources(effect)
	var sight_key: Array = []
	for source: Dictionary in sources:
		sight_key.append([source.id, source.pos, source.kind])
	var clipped_key: Array = [key, sight_key, _visibility_battle != null]
	if not _clipped_radials.has(clipped_key):
		if _visibility_battle != null and sources.is_empty():
			return
		var shape: Dictionary = _radial_geometry(effect, key, stroke, dashed)
		var fill_parts: Array = shape.fill
		var edge_parts: Array = shape.edge
		if _visibility_battle != null:
			fill_parts = _visible_parts(fill_parts, sources)
			edge_parts = _visible_parts(edge_parts, sources)
		_cache_put(_clipped_radials, clipped_key, {"fill": _faces(fill_parts), "edge": _faces(edge_parts)})
	var clipped: Dictionary = _clipped_radials[clipped_key]
	# These polygons were clipped as whole regions. Rechecking thousands of
	# sampled triangle points here would discard valid near-side portions and
	# turn an ordinary warning into a multi-hundred-millisecond frame stall.
	_emit_faces(clipped.fill, fill, 0.065)
	_emit_faces(clipped.edge, edge, 0.075)


func _prepare_sight(battle: Variant) -> void:
	var signature: int = hash([battle.map.get_instance_id(), battle.map.blockers])
	if signature != _map_signature:
		_map_signature = signature
		_radial_shapes.clear()
		_observer_shapes.clear()
		_clipped_radials.clear()
	_sight_sources.clear()
	var live: Dictionary = {}
	for unit: Dictionary in battle.units.values():
		if int(unit.team) == 0 and unit.alive and unit.kind in ["hero", "minion", "tower", "core"]:
			_sight_sources.append(unit)
			live[unit.id] = true
	for id: int in _observer_shapes.keys():
		if not live.has(id):
			_observer_shapes.erase(id)


func _radial_sources(effect: Dictionary) -> Array[Dictionary]:
	var sources: Array[Dictionary] = []
	var origin: Vector2 = effect.get("origin", Vector2.ZERO)
	var radius: float = maxf(0, float(effect.get("radius", 0.0)))
	for source: Dictionary in _sight_sources:
		var reach: float = (8.0 if source.kind == "minion" else 12.0) + radius
		if origin.distance_squared_to(source.pos) > reach * reach:
			continue
		var structure_sight: bool = source.kind in ["tower", "core"]
		if structure_sight or _visibility_battle == null or _visibility_battle.map.height_allows_sight(source.pos, origin):
			sources.append(source)
	return sources


func _radial_geometry(effect: Dictionary, key: Array, stroke: float, dashed: bool) -> Dictionary:
	if _radial_shapes.has(key):
		return _radial_shapes[key]
	var result: Dictionary = {"fill": [], "edge": []}
	for outline: PackedVector2Array in _radial_polygons(effect):
		result.fill.append_array(_convex_parts(outline))
		# Strokes are clipped to the same wall-bounded polygon, including corners.
		for inset: PackedVector2Array in Geometry2D.offset_polygon(outline, -stroke * 0.65):
			for index: int in range(inset.size()):
				var a: Vector2 = inset[index]
				var b: Vector2 = inset[(index + 1) % inset.size()]
				var parts: int = maxi(1, ceili(a.distance_to(b) / 0.45)) if dashed else 1
				for part: int in range(parts):
					if dashed and part % 2 == 1:
						continue
					var band := PackedVector2Array(_rectangle(a.lerp(b, float(part) / parts), a.lerp(b, float(part + 1) / parts), stroke))
					for clipped: PackedVector2Array in Geometry2D.intersect_polygons(outline, band):
						result.edge.append_array(_convex_parts(clipped))
	_cache_put(_radial_shapes, key, result)
	return result


func _source_parts(source: Dictionary) -> Array:
	var cached: Dictionary = _observer_shapes.get(source.id, {})
	if cached.get("pos") == source.pos and cached.get("kind") == source.kind:
		return cached.parts
	# Inscribed circles and a 2mm inward margin make native clipping conservative
	# at floating-point boundaries. Wall segments are the authority map's own.
	var radius: float = (8.0 if source.kind == "minion" else 12.0) - 0.002
	var parts: Array = []
	for polygon: PackedVector2Array in _radial_polygons({"shape": "circle", "origin": source.pos, "radius": radius}):
		parts.append_array(_convex_parts(polygon))
	_observer_shapes[source.id] = {"pos": source.pos, "kind": source.kind, "parts": parts}
	return parts


func _radial_polygons(effect: Dictionary) -> Array[PackedVector2Array]:
	var outline := PackedVector2Array()
	if str(effect.get("shape", "circle")) == "cone":
		outline.append(effect.origin)
	outline.append_array(_wall_map.radial_effect_outline(effect))
	outline = _clean_polygon(outline)
	if outline.size() < 3:
		return []
	# Tangents that touch a wall corner are blocked by authoritative LOS. A tiny
	# inward margin also keeps native boolean rounding off those tangent edges.
	return Geometry2D.offset_polygon(outline, -0.002)


func _visible_parts(polygons: Array, sources: Array[Dictionary]) -> Array:
	var remaining: Array = polygons.duplicate()
	var visible: Array = []
	# Subtract each accepted region before considering the next observer. This
	# builds a disjoint union, so overlap neither doubles alpha nor fills fog holes.
	for source: Dictionary in sources:
		for sight: PackedVector2Array in _source_parts(source):
			var next: Array = []
			for subject: PackedVector2Array in remaining:
				var intersection: Array[PackedVector2Array] = Geometry2D.intersect_polygons(subject, sight)
				if intersection.is_empty():
					next.append(subject)
					continue
				visible.append_array(intersection)
				if not Geometry2D.clip_polygons(subject, sight).is_empty():
					# Half-plane partitioning handles both concave complements and
					# enclosed holes as disjoint convex pieces. Unlike decomposing
					# boolean slivers, it remains stable at rounded wall corners.
					next.append_array(_subtract_convex(subject, sight))
			remaining = next
			if remaining.is_empty():
				return visible
	return visible


func _subtract_convex(subject: PackedVector2Array, clip: PackedVector2Array) -> Array:
	var remaining := subject
	var outside: Array = []
	for index: int in range(clip.size()):
		var a: Vector2 = clip[index]
		var b: Vector2 = clip[(index + 1) % clip.size()]
		var part := _half_plane(remaining, a, b, false)
		if part.size() >= 3:
			outside.append(part)
		remaining = _half_plane(remaining, a, b, true)
		if remaining.size() < 3:
			break
	return outside


func _half_plane(polygon: PackedVector2Array, a: Vector2, b: Vector2, inside: bool) -> PackedVector2Array:
	var result := PackedVector2Array()
	if polygon.is_empty():
		return result
	var sign_value: float = 1.0 if inside else -1.0
	var previous: Vector2 = polygon[-1]
	var previous_side: float = (b - a).cross(previous - a) * sign_value
	for point: Vector2 in polygon:
		var side: float = (b - a).cross(point - a) * sign_value
		if (side >= 0.0) != (previous_side >= 0.0):
			result.append(previous.lerp(point, previous_side / (previous_side - side)))
		if side >= 0.0:
			result.append(point)
		previous = point
		previous_side = side
	return _clean_polygon(result)


func _clean_polygon(polygon: PackedVector2Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for point: Vector2 in polygon:
		if result.is_empty() or result[-1].distance_squared_to(point) > 0.00000001:
			result.append(point)
	if result.size() > 1 and result[0].distance_squared_to(result[-1]) < 0.00000001:
		result.remove_at(result.size() - 1)
	if Geometry2D.is_polygon_clockwise(result):
		result.reverse()
	return result


func _convex_parts(polygon: PackedVector2Array) -> Array[PackedVector2Array]:
	var clean := _clean_polygon(polygon)
	if clean.size() < 3:
		return []
	var twice_area: float = 0.0
	for index: int in range(clean.size()):
		twice_area += clean[index].cross(clean[(index + 1) % clean.size()])
	if absf(twice_area) < 0.000001:
		return []
	return Geometry2D.decompose_polygon_in_convex(clean)


func _faces(polygons: Array) -> PackedVector2Array:
	var result := PackedVector2Array()
	for polygon: PackedVector2Array in polygons:
		for index: int in range(1, polygon.size() - 1):
			result.append(polygon[0])
			result.append(polygon[index])
			result.append(polygon[index + 1])
	return result


func _emit_faces(faces: PackedVector2Array, color: Color, height: float) -> void:
	_geometry.surface_set_color(color)
	for point: Vector2 in faces:
		_geometry.surface_add_vertex(Vector3(point.x, _terrain_height(point) + height, -point.y))
	_vertices += faces.size()


func _terrain_height(point: Vector2) -> float:
	return float(terrain_map.ground_height(point)) if terrain_map != null and terrain_map.has_method("ground_height") else 0.0


func _cache_put(cache: Dictionary, key: Array, value: Dictionary) -> void:
	if cache.size() >= RADIAL_CACHE_LIMIT:
		cache.erase(cache.keys()[0])
	cache[key] = value


func _rectangle(a: Vector2, b: Vector2, width: float) -> Array[Vector2]:
	var normal := Vector2(-(b - a).y, (b - a).x).normalized() * width * 0.5
	return [a + normal, b + normal, b - normal, a - normal]


func _polygon(points: Array[Vector2], color: Color) -> void:
	for i: int in range(1, points.size() - 1):
		_triangle(points[0], points[i], points[i + 1], color)


func _outline(points: Array[Vector2], width: float, color: Color, dashed: bool) -> void:
	for i: int in range(points.size()):
		_band(points[i], points[(i + 1) % points.size()], width, color, dashed)


func _band(a: Vector2, b: Vector2, width: float, color: Color, dashed: bool = false, height: float = 0.075) -> void:
	var length: float = a.distance_to(b)
	if length <= 0.0001:
		return
	if dashed:
		var parts: int = maxi(1, ceili(length / 0.45))
		for i: int in range(parts):
			if i % 2 == 0:
				_band(a.lerp(b, float(i) / parts), a.lerp(b, float(i + 1) / parts), width, color, false, height)
		return
	var points: Array[Vector2] = _rectangle(a, b, width)
	_triangle(points[0], points[1], points[2], color, height)
	_triangle(points[0], points[2], points[3], color, height)


func _disc(center: Vector2, radius: float, color: Color, height: float = 0.065) -> void:
	for i: int in range(48):
		var a: Vector2 = center + Vector2.from_angle(TAU * float(i) / 48.0) * radius
		var b: Vector2 = center + Vector2.from_angle(TAU * float(i + 1) / 48.0) * radius
		_triangle(center, a, b, color, height)


func _ring(center: Vector2, radius: float, width: float, color: Color, dashed: bool = false, height: float = 0.08, fraction: float = 1.0) -> void:
	var count: int = maxi(1, ceili(48 * fraction))
	for i: int in range(count):
		if dashed and i % 4 >= 2:
			continue
		var a: Vector2 = center + Vector2.from_angle(TAU * float(i) / 48.0) * radius
		var b: Vector2 = center + Vector2.from_angle(TAU * minf(float(i + 1) / 48.0, fraction)) * radius
		_band(a, b, width, color, false, height)


func _triangle(a: Vector2, b: Vector2, c: Vector2, color: Color, height: float = 0.065) -> void:
	if _visibility_battle != null:
		# Test the complete small cell, not just a line's center or one endpoint.
		for point: Vector2 in [a, b, c, (a + b) * 0.5, (b + c) * 0.5, (c + a) * 0.5, (a + b + c) / 3.0]:
			if not _point_visible(point):
				return
	_geometry.surface_set_color(color)
	for point: Vector2 in [a, b, c]:
		_geometry.surface_add_vertex(Vector3(point.x, _terrain_height(point) + height, -point.y))
	_vertices += 3
