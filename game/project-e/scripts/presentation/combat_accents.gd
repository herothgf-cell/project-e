extends MeshInstance3D
## Cosmetic accents only. Existing Effects remains the authority-shaped telegraph.
var visible_projectile_count: int = 0
var _geometry: ImmediateMesh
var _vertices: int = 0
var _battle: Variant

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func refresh(battle: Variant) -> void:
	_battle = battle
	visible_projectile_count = 0
	_vertices = 0
	_geometry = ImmediateMesh.new()
	_geometry.surface_begin(Mesh.PRIMITIVE_LINES)
	for unit: Dictionary in battle.units.values():
		if unit.kind != "hero" or not unit.alive or not battle.is_visible(0, unit.id):
			continue
		var color := Color("7bffdf") if int(unit.team) == 0 else Color("ffc18a")
		if unit.shield > 0.0:
			_circle(unit.pos, 0.63, 1.0, color, battle.time)
			_circle(unit.pos, 0.48, 1.55, Color(color.r, color.g, color.b, 0.55), -battle.time)
		if unit.stun_left > 0.0 or unit.root_left > 0.0:
			var height: float = 2.65 if unit.stun_left > 0.0 else 0.20
			for index: int in range(3):
				var angle: float = battle.time * 3 + index * TAU / 3
				_spark(unit.pos + Vector2(cos(angle), sin(angle)) * 0.5, height, 0.12, Color("ffe4a5"))
		if unit.phase == "windup":
			var wind: float = float(unit.cast.get("windup", 0.2))
			var strength: float = clampf(1.0 - float(unit.phase_left) / maxf(0.01, wind), 0.0, 1.0)
			for side: float in [-1.0, 1.0]:
				var point: Vector2 = unit.pos + unit.facing * 0.5 + Vector2(-unit.facing.y, unit.facing.x) * side * 0.4
				_spark(point, 1.1, 0.13 + strength * 0.15, color)
	for projectile: Dictionary in battle.projectiles:
		var point: Vector2 = projectile.get("pos", Vector2.ZERO)
		var own_disc: bool = int(projectile.get("team", 0)) == 0 and str(projectile.get("kind", "")) == "rio_disc"
		if not own_disc and not battle.is_point_visible(0, point):
			continue
		visible_projectile_count += 1
		var color := Color("b5fff0") if int(projectile.get("team", 0)) == 0 else Color("ffd59a")
		if str(projectile.get("kind", "")) == "rio_disc":
			_circle(point, 0.36, 0.72, color, battle.time * 8)
			for i: int in range(4):
				var angle: float = battle.time * 12 + i * PI * 0.5
				_line(_world(point, 0.72), _world(point + Vector2(cos(angle), sin(angle)) * 0.39, 0.72), color)
		else:
			_spark(point, 0.75, 0.18, color)
	for effect: Dictionary in battle.effects:
		if bool(effect.get("telegraph", true)):
			continue
		var origin: Vector2 = effect.get("origin", Vector2.ZERO)
		var end: Vector2 = effect.get("target", origin)
		var color := Color("b7fce5") if int(effect.get("team", 0)) == 0 else Color("ffd2a1")
		var remaining: float = float(effect.get("remaining", 0.0))
		for i: int in range(7):
			var point: Vector2 = origin.lerp(end, float(i) / 6.0)
			# Each sample is independently authorized, including the far end of a line.
			if not battle.is_point_visible(0, point) or not battle.map.has_line_of_sight(origin, point):
				continue
			if not battle._abilities.contains(effect, point, 0.0):
				continue
			var height: float = 0.15 + absf(sin(remaining * 12 + i * 1.7)) * 0.5
			_spark(point, height, 0.11, Color(color.r, color.g, color.b, 0.7))
	if _vertices == 0:
		_line(Vector3.ZERO, Vector3.ZERO, Color(0, 0, 0, 0))
	_geometry.surface_end()
	mesh = _geometry

func _world(point: Vector2, height: float) -> Vector3:
	return Vector3(point.x, float(_battle.map.ground_height(point)) + height, -point.y)

func _line(a: Vector3, b: Vector3, color: Color) -> void:
	_geometry.surface_set_color(color)
	_geometry.surface_add_vertex(a)
	_geometry.surface_set_color(color)
	_geometry.surface_add_vertex(b)
	_vertices += 2

func _spark(point: Vector2, height: float, radius: float, color: Color) -> void:
	var center: Vector3 = _world(point, height)
	_line(center - Vector3.RIGHT * radius, center + Vector3.RIGHT * radius, color)
	_line(center - Vector3.UP * radius, center + Vector3.UP * radius, color)
	_line(center - Vector3.FORWARD * radius, center + Vector3.FORWARD * radius, color)

func _circle(point: Vector2, radius: float, height: float, color: Color, phase: float) -> void:
	for i: int in range(24):
		if i % 6 == 5:
			continue
		var a: float = TAU * float(i) / 24 + phase
		var b: float = TAU * float(i + 1) / 24 + phase
		_line(_world(point + Vector2(cos(a), sin(a)) * radius, height), _world(point + Vector2(cos(b), sin(b)) * radius, height), color)
