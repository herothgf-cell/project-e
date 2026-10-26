extends MeshInstance3D
## Draws authoritative geometry without computing damage or inventing hit results.

var _geometry: ImmediateMesh
var _vertices: int = 0
var _visibility_battle: Variant
var _visible_points: Dictionary = {}


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
	_visible_points.clear()
	for effect: Dictionary in battle.effects:
		if not _can_show(battle, effect):
			continue
		var color := Color("35bcb9") if int(effect.get("team", 0)) == 0 else Color("f17d44")
		var telegraph: bool = bool(effect.get("telegraph", false))
		color.a = 0.14 if telegraph else 0.24
		# A visible origin does not authorize revealing an enemy line's far endpoint.
		_visibility_battle = battle if int(effect.get("team", 0)) != 0 and str(effect.get("shape", "")) == "line" else null
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
	# Lines are clipped triangle by triangle, including when only their far end is seen.
	if str(effect.get("shape", "")) == "line":
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
		_visible_points[point] = _visibility_battle.is_point_visible(0, point)
	return bool(_visible_points[point])


func _shape(effect: Dictionary, color: Color, enemy: bool, aiming: bool) -> void:
	var origin: Vector2 = effect.get("origin", Vector2.ZERO)
	var target: Vector2 = effect.get("target", origin)
	var radius: float = maxf(0, float(effect.get("radius", 1.0)))
	var width: float = maxf(0.02, float(effect.get("width", 0.8)))
	var line: Color = Color(color.r, color.g, color.b, 0.95)
	var stroke: float = 0.10 if enemy else 0.065
	if aiming:
		stroke = 0.085
	match str(effect.get("shape", "circle")):
		"circle":
			_disc(origin, radius, color)
			_ring(origin, radius, stroke, line, enemy)
		"cone":
			var facing: Vector2 = (target - origin).normalized()
			if facing.length_squared() < 0.01:
				facing = Vector2.RIGHT
			var angle: float = deg_to_rad(float(effect.get("angle", 80.0)))
			var start: float = facing.angle() - angle * 0.5
			var points: Array[Vector2] = [origin]
			for i: int in range(25):
				points.append(origin + Vector2.from_angle(start + angle * float(i) / 24.0) * radius)
			for i: int in range(1, points.size() - 1):
				_triangle(origin, points[i], points[i + 1], color)
			_outline(points, stroke, line, enemy)
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
		_geometry.surface_add_vertex(Vector3(point.x, height, -point.y))
	_vertices += 3
