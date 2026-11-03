extends MeshInstance3D
## Per-kit readable additions. Authority telegraphs stay in Effects.
## Sample every decorative point against current team sight and real effect area.
var rendered_points: Array[Vector2] = []
var _mesh: ImmediateMesh
var _state: Variant
var _count: int = 0
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
	rendered_points.clear()
	_count = 0
	_mesh = ImmediateMesh.new()
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for effect: Dictionary in state.effects:
		if bool(effect.get("telegraph", true)): continue
		var actor: Dictionary = state.units.get(int(effect.get("owner_id", -1)), {})
		if actor.is_empty(): continue
		var key: String = str(actor.hero)
		var color: Color = Color("ffe1a5") if key == "bas" else (Color("9bf9ef") if key == "rio" else Color("a8e4ff"))
		if int(effect.get("team", 0)) != 0: color = Color("ffad72")
		var fraction: float = clampf(1.0 - float(effect.get("remaining", 0.0)) / maxf(0.001, float(effect.get("duration", 0.22))), 0, 1)
		var slot: String = str(effect.get("slot", ""))
		var power: float = 1.35 if slot == "R" else 0.65
		var origin: Vector2 = effect.get("origin", Vector2.ZERO)
		var target: Vector2 = effect.get("target", origin)
		var shape: String = str(effect.get("shape", ""))
		var samples: Array[Vector2] = []
		if shape in ["circle", "cone"]:
			var radius: float = float(effect.get("radius", 0.5)) * (0.30 + fraction * 0.62)
			var direction: Vector2 = effect.get("direction", Vector2.RIGHT)
			var angle: float = float(effect.get("angle", 360.0)) if shape == "cone" else 360.0
			for i: int in range(25):
				var theta: float = direction.angle() + deg_to_rad(angle) * (float(i) / 24.0 - 0.5)
				samples.append(origin + Vector2(cos(theta), sin(theta)) * radius)
		elif shape == "triangle":
			var points: Array = effect.get("points", [])
			for i: int in range(points.size()):
				for j: int in range(12): samples.append(Vector2(points[i]).lerp(points[(i + 1) % points.size()], float(j) / 12))
		else:
			var normal: Vector2 = (target - origin).normalized().orthogonal()
			for i: int in range(18):
				var center: Vector2 = origin.lerp(target, float(i) / 17.0)
				for side: float in [-0.35, 0.35]: samples.append(center + normal * float(effect.get("width", 0.5)) * side)
		for point: Vector2 in samples:
			var source: Vector2 = state._abilities.effect_origin(effect, point)
			if not _allowed(point) or not state._abilities.contains(effect, point, 0) or not state.map.has_line_of_sight(source, point): continue
			var height: float = power * sin(PI * clampf(fraction + 0.10, 0, 1))
			if key == "bas": _blade(point, maxf(0.12, height), 0.12, color)
			elif key == "rio": _diamond(point, 0.25 + height * 0.25, 0.12, color)
			else:
				_blade(point, 0.20 + height, 0.055, color)
				_diamond(point, 0.25 + height, 0.10, color)
	for actor: Dictionary in state.units.values():
		if actor.kind != "hero" or not actor.alive or not state.is_visible(0, actor.id): continue
		if actor.phase == "dash":
			var color := Color("ffe1a5") if actor.hero == "bas" else Color("a8fff0")
			if actor.team != 0: color = Color("ffad72")
			var normal: Vector2 = actor.facing.orthogonal()
			for i: int in range(9):
				for side: float in [-1.0, 1.0]:
					var point: Vector2 = actor.pos - actor.facing * float(i) * 0.10 + normal * side * 0.28
					if _allowed(point) and state.map.has_line_of_sight(actor.pos, point): _blade(point, 0.35, 0.07, color)
	if _count == 0: _triangle(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO, Color(0, 0, 0, 0))
	_mesh.surface_end()
	mesh = _mesh
func _allowed(point: Vector2) -> bool:
	return _state.is_point_visible(0, point)
func _world(point: Vector2, height: float) -> Vector3:
	return Vector3(point.x, _state.map.ground_height(point) + height, -point.y)
func _blade(point: Vector2, height: float, width: float, color: Color) -> void:
	rendered_points.append(point)
	var bottom: Vector3 = _world(point, 0.10)
	var top: Vector3 = _world(point, height + 0.10)
	color.a = 0.75
	_triangle(bottom - Vector3.RIGHT * width, bottom + Vector3.RIGHT * width, top, color)
	_triangle(bottom - Vector3.FORWARD * width, bottom + Vector3.FORWARD * width, top, color)
func _diamond(point: Vector2, height: float, size: float, color: Color) -> void:
	rendered_points.append(point)
	var center: Vector3 = _world(point, height)
	_triangle(center - Vector3.RIGHT * size, center + Vector3.RIGHT * size, center + Vector3.UP * size, color)
	_triangle(center + Vector3.RIGHT * size, center - Vector3.RIGHT * size, center - Vector3.UP * size, color)
func _triangle(a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	for vertex: Vector3 in [a, b, c]:
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(vertex)
	_count += 3
