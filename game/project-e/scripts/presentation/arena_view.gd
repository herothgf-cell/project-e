extends Node3D
## Code-native workshop geometry. All playable paths come from the map model.

const CREAM := Color("e9dfbe")
const PALE := Color("f8edd4")
const COPPER := Color("b8764c")
const DARK := Color("364e4a")
const TEAL := Color("38c6bb")
const ORANGE := Color("f08c55")

const TERRAIN_SHADER := """
shader_type spatial;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D vision_mask : filter_nearest, repeat_disable;
uniform bool vision_bound = false;
varying vec2 world_point;
void vertex() {
 vec3 world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
 world_point = vec2(world.x, -world.z);
}
void fragment() {
 float visible = vision_bound ? texture(vision_mask, (world_point + vec2(62.0,40.0)) / vec2(124.0,80.0)).r : 1.0;
 float grey = dot(base_color.rgb, vec3(0.2126,0.7152,0.0722));
 vec3 unseen = mix(vec3(grey), base_color.rgb, 0.18) * 0.40;
 ALBEDO = mix(unseen, base_color.rgb, visible);
 ROUGHNESS = 0.82;
}
"""

var _materials: Dictionary = {}
var _terrain_materials: Dictionary = {}
var _building_terrain: bool = false
var _vision_texture: Texture2D
var _terrain_shader: Shader
var terrain_map: Variant


func build(map: Variant, units: Dictionary) -> void:
	terrain_map = map
	_building_terrain = true
	_box(self, Vector3(124, 1.1, 84), Vector3(0, -1.15, 0), Color("326c69"))
	_box(self, Vector3(121, 0.16, 81), Vector3(0, -0.48, 0), Color("62aaa0"))
	# Subtle recessed water stripes preserve a quiet, readable play surface.
	for x: int in range(-58, 59, 8):
		_box(self, Vector3(0.05, 0.015, 78), Vector3(x, -0.39, 0), Color("8bc5b3"))
	for lane: Array in map.lane_paths:
		for i: int in range(lane.size() - 1):
			_corridor(lane[i], lane[i + 1], 6.0, CREAM)
		for point: Vector2 in lane:
			_pad(point, 3.0, CREAM)
	for link: Array in map.connectors:
		_corridor(link[0], link[1], 4.0, Color("d9d0ae"))
		# Copper edge marks differentiate support routes from the main lanes.
		var direction: Vector2 = (link[1] - link[0]).normalized()
		var tangent := Vector2(-direction.y, direction.x)
		for side: float in [-1.0, 1.0]:
			_segment_box(link[0] + tangent * 1.87 * side, link[1] + tangent * 1.87 * side, 0.08, 0.055, COPPER, 0.045)
	for team: int in range(2):
		var sign_value: float = -1.0 if team == 0 else 1.0
		_box(self, Vector3(15, 0.6, 16), Vector3(sign_value * 51.5, -0.28, 0), CREAM)
		_box(self, Vector3(6, 0.025, 12), Vector3(sign_value * 56, 0.045, 0), Color("c3d8c1"))
		for z: float in [-6.0, 6.0]:
			_box(self, Vector3(6, 0.045, 0.12), Vector3(sign_value * 56, 0.07, z), TEAL if team == 0 else ORANGE)
		_workbench(Vector3(sign_value * 58, 0, 5.8), team)
	for north: float in [-18.0, 0.0, 18.0]:
		_box(self, Vector3(12, 0.6, 9), Vector3(0, -0.27, -north), PALE)
		for x: float in [-4.0, 0.0, 4.0]:
			_box(self, Vector3(0.035, 0.02, 8.7), Vector3(x, 0.045, -north), Color("d7cdb2"))
	for unit: Dictionary in units.values():
		if unit.kind in ["tower", "core"]:
			_pad(unit.pos, 3.0, PALE)
	for position: Vector2 in map.cell_positions:
		var lane_y: float = 0.0 if absf(position.y) < 10.0 else signf(position.y) * 18.0
		if map.is_high_ground(position):
			_elevated_cell_access(map, position, lane_y)
		else:
			_pad(position, 2.2, Color("e1d4af"))
			_corridor(Vector2(position.x, lane_y), position, 3.0, Color("e1d4af"))
	for blocker: Rect2 in map.blockers:
		_blocker(blocker)
	# These are deliberately recessed garden islands, never extra playable pads.
	for mirror: float in [-1.0, 1.0]:
		for z: float in [-30.5, 30.5]:
			_garden(Vector3(mirror * 30, -0.25, z))
		for z: float in [-11.0, 11.0]:
			_garden(Vector3(mirror * 38, -0.25, z), 0.55)
		_boundary_workshop(Vector3(mirror * 47, -0.2, -30), mirror)
		_drying_rack(Vector3(mirror * 34, -0.2, 31))
	# A continuous enclosing lip is kept outside the simulation bounds.
	for z: float in [-41.0, 41.0]:
		_box(self, Vector3(124, 0.75, 0.8), Vector3(0, -0.1, z), Color("c5b997"))
	for x: float in [-61.0, 61.0]:
		_box(self, Vector3(0.8, 0.75, 82), Vector3(x, -0.1, 0), Color("c5b997"))
	for lane_index: int in range(3):
		var y: float = [18.0, 0.0, -18.0][lane_index]
		for x: float in [-5.7, 5.7]:
			_lane_emblem(Vector2(x, y), ["N", "C", "S"][lane_index])

	_building_terrain = false


func create_unit(unit: Dictionary, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Unit_%s" % unit.id
	parent.add_child(root)
	var color: Color = TEAL if int(unit.team) == 0 else ORANGE
	if int(unit.team) == 2:
		color = Color("ffd075")
	var ring := ring_mesh(float(unit.radius), 0.045, color)
	ring.name = "Footprint"
	ring.position.y = 0.075
	root.add_child(ring)
	var model := Node3D.new()
	model.name = "Model"
	root.add_child(model)
	match str(unit.kind):
		"hero":
			_hero(model, str(unit.hero), color)
		"minion":
			_minion(model, str(unit.get("subtype", "melee")), color)
		"tower":
			_tower(model, str(unit.get("subtype", "outer")), color)
		"core":
			_core(model, color)
		"cell":
			_cell(model, unit)
		"pin":
			_pin(model, color)
	root.position = to_world(unit.pos, terrain_map.ground_height(unit.pos) if terrain_map != null else 0.0)
	return root


func _cell(parent: Node3D, unit: Dictionary) -> void:
	# All tiers keep the authority's radius / Footprint. Only the crystal varies.
	var tier: String = str(unit.get("cell_tier", "medium"))
	var reward: float = float(unit.get("xp_reward", {"low": 20, "medium": 30, "high": 40}.get(tier, 30)))
	var count: int = 1 if reward < 25 else (2 if reward < 35 else 3)
	var height: float = 0.66 + count * 0.17
	_cylinder(parent, 0.55, 0.18, Vector3(0, 0.12, 0), COPPER, 6)
	for index: int in range(count):
		var x: float = (float(index) - (count - 1) * 0.5) * 0.32
		var crystal: MeshInstance3D = _sphere(parent, 0.28 + count * 0.035, Vector3(x, height - absf(x) * 0.6, 0), Color("f9d887"))
		crystal.scale = Vector3(0.67, 1.20 + count * 0.26, 0.80)
	_box(parent, Vector3(0.09, height * 1.15, 0.09), Vector3(0, height * 0.6, 0), PALE)


func set_vision_texture(texture: Texture2D) -> void:
	_vision_texture = texture
	for value: ShaderMaterial in _terrain_materials.values():
		value.set_shader_parameter("vision_mask", texture)
		value.set_shader_parameter("vision_bound", texture != null)


func _hero(parent: Node3D, key: String, color: Color) -> void:
	# One physical foot circle for all heroes; equipment changes only silhouette.
	for x: float in [-0.23, 0.23]:
		_box(parent, Vector3(0.26, 0.48, 0.38), Vector3(x, 0.31, 0.04), DARK)
	var torso := Vector3(0.78, 0.75, 0.50)
	if key == "rio":
		torso = Vector3(0.43, 0.9, 0.36)
	_box(parent, torso, Vector3(0, 0.95, 0), Color("f3e8c9"))
	_box(parent, Vector3(torso.x + 0.05, 0.17, torso.z + 0.08), Vector3(0, 0.68, 0), COPPER)
	_sphere(parent, 0.27, Vector3(0, 1.58, 0), Color("d1a579"))
	_cylinder(parent, 0.30, 0.12, Vector3(0, 1.76, 0), color)
	_box(parent, Vector3(0.34, 0.105, 0.09), Vector3(0, 1.58, -0.245), DARK)
	match key:
		"bas":
			for side: float in [-1.0, 1.0]:
				_box(parent, Vector3(0.38, 0.45, 0.44), Vector3(side * 0.55, 1.08, -0.05), COPPER)
				_box(parent, Vector3(0.52, 0.60, 0.66), Vector3(side * 0.66, 0.9, -0.25), PALE)
				_box(parent, Vector3(0.35, 0.13, 0.08), Vector3(side * 0.66, 0.98, -0.61), color)
			_box(parent, Vector3(0.58, 0.23, 0.08), Vector3(0, 1.15, -0.29), color)
		"rio":
			for side: float in [-1.0, 1.0]:
				_box(parent, Vector3(0.17, 0.62, 0.19), Vector3(side * 0.36, 1.0, 0), COPPER)
				var disc: MeshInstance3D = ring_mesh(0.37, 0.12, COPPER)
				disc.position = Vector3(side * 0.66, 1.04, -0.2)
				disc.rotation_degrees.x = 70
				parent.add_child(disc)
			var scarf: MeshInstance3D = _box(parent, Vector3(0.28, 0.1, 1.1), Vector3(-0.22, 1.35, 0.55), color)
			scarf.rotation_degrees.x = 24
			_box(parent, Vector3(0.15, 0.08, 0.90), Vector3(0.24, 1.0, 0.6), Color("dfb076"))
		"nema":
			_box(parent, Vector3(0.70, 0.80, 0.34), Vector3(0, 1.04, 0.40), COPPER)
			_box(parent, Vector3(0.53, 0.58, 0.10), Vector3(0, 1.07, 0.63), color)
			for side: float in [-1.0, 1.0]:
				_box(parent, Vector3(0.17, 0.62, 0.20), Vector3(side * 0.45, 1.0, -0.05), PALE)
				_cylinder(parent, 0.10, 1.2, Vector3(side * 0.32, 1.50, 0.38), PALE)
				_sphere(parent, 0.15, Vector3(side * 0.32, 2.12, 0.38), color)
			_box(parent, Vector3(0.40, 0.3, 0.09), Vector3(0, 1.08, -0.31), color)


func _minion(parent: Node3D, subtype: String, color: Color) -> void:
	var siege: bool = subtype == "siege"
	var width: float = 0.92 if siege else 0.57
	_box(parent, Vector3(width, 0.45, 0.65), Vector3(0, 0.45, 0), CREAM)
	_box(parent, Vector3(width * 0.75, 0.13, 0.50), Vector3(0, 0.74, 0), color)
	for x: float in [-1.0, 1.0]:
		var wheel: MeshInstance3D = _cylinder(parent, 0.19, 0.16, Vector3(x * width * 0.53, 0.25, 0), DARK, 10)
		wheel.rotation_degrees.z = 90
	if subtype in ["ranged", "siege"]:
		var barrel: MeshInstance3D = _cylinder(parent, 0.16 if siege else 0.08, 0.50, Vector3(0, 0.66, -0.43), COPPER)
		barrel.rotation_degrees.x = 90
	else:
		_box(parent, Vector3(0.45, 0.34, 0.13), Vector3(0, 0.47, -0.40), COPPER)


func _tower(parent: Node3D, subtype: String, color: Color) -> void:
	_cylinder(parent, 1.0, 0.32, Vector3(0, 0.18, 0), COPPER, 8)
	_cylinder(parent, 0.80, 0.45, Vector3(0, 0.52, 0), PALE, 8)
	_cylinder(parent, 0.53, 1.70, Vector3(0, 1.50, 0), CREAM, 8)
	for x: float in [-0.60, 0.60]:
		_box(parent, Vector3(0.18, 1.50, 0.20), Vector3(x, 1.55, 0), COPPER)
	_cylinder(parent, 0.76, 0.20, Vector3(0, 2.35, 0), COPPER, 8)
	var gem: MeshInstance3D = _sphere(parent, 0.43, Vector3(0, 2.80, 0), color)
	gem.scale.y = 1.3
	if subtype == "inner":
		var halo: MeshInstance3D = ring_mesh(0.85, 0.09, COPPER)
		halo.position.y = 3.0
		parent.add_child(halo)
	_box(parent, Vector3(0.10, 0.6, 0.12), Vector3(0, 2.70, 0), PALE)


func _core(parent: Node3D, color: Color) -> void:
	_cylinder(parent, 2.0, 0.30, Vector3(0, 0.18, 0), COPPER, 16)
	_cylinder(parent, 1.68, 0.40, Vector3(0, 0.48, 0), PALE, 16)
	_cylinder(parent, 1.25, 0.27, Vector3(0, 0.76, 0), color, 24)
	for angle: float in [0.0, PI / 2.0, PI, PI * 1.5]:
		_box(parent, Vector3(0.35, 1.85, 0.35), Vector3(cos(angle) * 1.32, 1.5, sin(angle) * 1.32), CREAM)
	var gem: MeshInstance3D = _sphere(parent, 0.80, Vector3(0, 1.85, 0), color)
	gem.scale.y = 1.5
	for height: float in [1.05, 2.8]:
		var ring: MeshInstance3D = ring_mesh(1.32, 0.15, COPPER)
		ring.position.y = height
		parent.add_child(ring)


func _pin(parent: Node3D, color: Color) -> void:
	_cylinder(parent, 0.32, 0.15, Vector3(0, 0.12, 0), COPPER, 6)
	_cylinder(parent, 0.11, 1.2, Vector3(0, 0.72, 0), PALE, 6)
	_box(parent, Vector3(0.60, 0.18, 0.16), Vector3(0, 1.22, 0), color)
	_sphere(parent, 0.18, Vector3(0, 1.48, 0), color)


func _elevated_cell_access(map: Variant, position: Vector2, lane_y: float) -> void:
	var color := Color("e1d4af")
	var height: float = float(map.ground_height(position))
	# Raised circular pad. Simulation footprint is unchanged; only the surface
	# follows the authority map's elevation.
	_cylinder(self, 2.2, 0.58, to_world(position, height - 0.28), color, 32)
	# The original straight 3m access becomes a visible ramp from lane height to
	# the plateau. Its walkability still comes from battle_map.gd.
	var direction: float = signf(position.y)
	var start := Vector2(position.x, lane_y)
	var finish := Vector2(position.x, lane_y + direction * map.HIGH_GROUND_RAMP_LENGTH)
	var center2 := (start + finish) * 0.5
	var horizontal: float = start.distance_to(finish)
	var slope_length: float = sqrt(horizontal * horizontal + height * height)
	var ramp := _box(self, Vector3(3.0, 0.18, slope_length), to_world(center2, height * 0.5 - 0.05), color)
	ramp.rotation_degrees.x = rad_to_deg(atan2(height, horizontal)) * direction
	# Copper rails make the route read as a deliberate high-ground entrance.
	for side: float in [-1.0, 1.0]:
		var rail := _box(self, Vector3(0.08, 0.16, slope_length), to_world(center2 + Vector2(side * 1.42, 0), height * 0.5 + 0.05), COPPER)
		rail.rotation_degrees.x = ramp.rotation_degrees.x


func _corridor(a: Vector2, b: Vector2, width: float, color: Color) -> void:
	_segment_box(a, b, width, 0.58, color, -0.28)
	# Paired narrow insets read as paving joints, not collision boundaries.
	var length: float = a.distance_to(b)
	for distance: float in range(3, int(length), 4):
		var point: Vector2 = a.lerp(b, distance / length)
		var transverse: Vector2 = Vector2(-(b - a).y, (b - a).x).normalized()
		_segment_box(point - transverse * (width * 0.48), point + transverse * (width * 0.48), 0.035, 0.015, Color("d3c7a9"), 0.023)


func _segment_box(a: Vector2, b: Vector2, width: float, height: float, color: Color, y: float) -> MeshInstance3D:
	var length: float = a.distance_to(b)
	var center: Vector3 = to_world((a + b) * 0.5, y)
	var mesh: MeshInstance3D = _box(self, Vector3(length, height, width), center, color)
	mesh.rotation.y = atan2((b - a).y, (b - a).x)
	return mesh


func _pad(point: Vector2, radius: float, color: Color) -> void:
	_cylinder(self, radius, 0.58, to_world(point, -0.28), color, 32)


func _blocker(rect: Rect2) -> void:
	var center: Vector2 = rect.get_center()
	_box(self, Vector3(rect.size.x, 1.35, rect.size.y), to_world(center, 0.43), Color("a99c78"))
	_box(self, Vector3(rect.size.x + 0.05, 0.16, rect.size.y + 0.05), to_world(center, 1.18), Color("c5a27c"))
	for x: float in [rect.position.x + 0.4, rect.end.x - 0.4]:
		_box(self, Vector3(0.18, 1.6, rect.size.y), Vector3(x, 0.58, -center.y), COPPER)
	_box(self, Vector3(rect.size.x * 0.6, 0.2, rect.size.y * 0.6), to_world(center, 1.35), Color("708c6d"))


func _garden(position: Vector3, scale_value: float = 1.0) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = position
	node.scale = Vector3.ONE * scale_value
	_box(node, Vector3(14, 0.25, 4.0), Vector3.ZERO, Color("5c8a70"))
	for x: float in [-5.0, -2.0, 2.0, 5.0]:
		_cylinder(node, 0.55, 0.50, Vector3(x, 0.23, 0), Color("9b7853"))
		var bush: MeshInstance3D = _sphere(node, 0.80, Vector3(x, 0.95, 0), Color("81965f"))
		bush.scale = Vector3(1.3, 0.65, 1.0)


func _workbench(position: Vector3, team: int) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = position
	_box(node, Vector3(1.4, 0.75, 1.7), Vector3(0, 0.4, 0), Color("927451"))
	_box(node, Vector3(1.55, 0.13, 1.85), Vector3(0, 0.85, 0), PALE)
	_cylinder(node, 0.3, 0.25, Vector3(0, 1.05, 0), TEAL if team == 0 else ORANGE)


func _boundary_workshop(position: Vector3, mirror: float) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = position
	_box(node, Vector3(10, 1.0, 6), Vector3(0, 0.2, 0), Color("a29a74"))
	_box(node, Vector3(8, 2.7, 3.7), Vector3(0, 1.75, 0.6), Color("c9b98b"))
	_box(node, Vector3(9, 0.30, 4.7), Vector3(0, 3.3, 0.6), Color("ac7855"))
	for x: float in [-3.0, 0.0, 3.0]:
		_box(node, Vector3(1.5, 1.25, 0.08), Vector3(x, 2.05, -1.3), Color("417f78"))
	_cylinder(node, 0.55, 4.0, Vector3(mirror * 3.7, 2.0, 1), COPPER)


func _drying_rack(position: Vector3) -> void:
	var node := Node3D.new()
	add_child(node)
	node.position = position
	for x: float in [-5.0, 5.0]:
		_box(node, Vector3(0.25, 3.0, 0.25), Vector3(x, 1.3, 0), COPPER)
	_box(node, Vector3(10, 0.18, 0.2), Vector3(0, 2.8, 0), COPPER)
	for x: float in [-3.5, -1.2, 1.2, 3.5]:
		_box(node, Vector3(1.8, 1.55, 0.04), Vector3(x, 2.0, 0), Color("ecd0a0") if x < 0 else Color("8bb5a6"))


func _lane_emblem(position: Vector2, letter: String) -> void:
	var label := Label3D.new()
	label.text = letter
	label.font_size = 64
	label.pixel_size = 0.023
	label.modulate = Color("aa9975")
	label.outline_size = 0
	label.position = to_world(position, 0.05)
	label.rotation_degrees.x = -90
	add_child(label)


func _box(parent: Node3D, size_value: Vector3, position_value: Vector3, color: Color) -> MeshInstance3D:
	var resource := BoxMesh.new()
	resource.size = size_value
	return _mesh(parent, resource, position_value, color)


func _cylinder(parent: Node3D, radius: float, height: float, position_value: Vector3, color: Color, sides: int = 16) -> MeshInstance3D:
	var resource := CylinderMesh.new()
	resource.top_radius = radius
	resource.bottom_radius = radius
	resource.height = height
	resource.radial_segments = sides
	return _mesh(parent, resource, position_value, color)


func _sphere(parent: Node3D, radius: float, position_value: Vector3, color: Color) -> MeshInstance3D:
	var resource := SphereMesh.new()
	resource.radius = radius
	resource.height = radius * 2.0
	resource.radial_segments = 12
	resource.rings = 6
	return _mesh(parent, resource, position_value, color)


func _mesh(parent: Node3D, resource: Mesh, position_value: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.mesh = resource
	mesh.material_override = material(color)
	mesh.position = position_value
	parent.add_child(mesh)
	return mesh


func material(color: Color) -> Material:
	if _building_terrain:
		if not _terrain_materials.has(color):
			if _terrain_shader == null:
				_terrain_shader = Shader.new()
				_terrain_shader.code = TERRAIN_SHADER
			var terrain := ShaderMaterial.new()
			terrain.shader = _terrain_shader
			terrain.set_shader_parameter("base_color", color)
			terrain.set_shader_parameter("vision_mask", _vision_texture)
			terrain.set_shader_parameter("vision_bound", _vision_texture != null)
			_terrain_materials[color] = terrain
		return _terrain_materials[color]
	if not _materials.has(color):
		var result := StandardMaterial3D.new()
		result.albedo_color = color
		result.roughness = 0.82
		_materials[color] = result
	return _materials[color]


static func to_world(point: Vector2, height: float = 0.0) -> Vector3:
	return Vector3(point.x, height, -point.y)


static func ring_mesh(radius: float, width: float, color: Color) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i: int in range(48):
		var a: float = TAU * float(i) / 48.0
		var b: float = TAU * float(i + 1) / 48.0
		var inner: float = maxf(0.0, radius - width * 0.5)
		var outer: float = radius + width * 0.5
		var points: Array[Vector3] = [Vector3(cos(a) * inner, 0, sin(a) * inner), Vector3(cos(a) * outer, 0, sin(a) * outer), Vector3(cos(b) * outer, 0, sin(b) * outer), Vector3(cos(b) * inner, 0, sin(b) * inner)]
		for index: int in [0, 1, 2, 0, 2, 3]:
			mesh.surface_add_vertex(points[index])
	mesh.surface_end()
	var material_value := StandardMaterial3D.new()
	material_value.albedo_color = color
	material_value.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material_value.cull_mode = BaseMaterial3D.CULL_DISABLED
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	instance.material_override = material_value
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return instance
