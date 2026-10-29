extends Node3D
## R30 presentation only: renders the two new support-rotation ramps from map data.
## The existing lane-return ramps remain owned by arena_view.gd and its R28 tests.

const ArenaScript = preload("res://scripts/presentation/arena_view.gd")
const SUPPORT_COLOR := Color("d9d0ae")
const COPPER := Color("b8764c")

var _built: bool = false


func _ready() -> void:
	set_process(true)


func _process(_delta: float) -> void:
	if _built:
		set_process(false)
		return
	var arena: Variant = get_parent()
	if arena == null or arena.terrain_map == null:
		return
	_build(arena, arena.terrain_map)
	_built = true
	set_process(false)


func _build(arena: Variant, map: Variant) -> void:
	for ramp: Dictionary in map.high_ground_ramps:
		if str(ramp.get("kind", "")) != "support":
			continue
		_create_ramp(arena, map, ramp)


func _create_ramp(arena: Variant, map: Variant, ramp: Dictionary) -> void:
	var high_edge: Vector2 = map.ramp_high_edge(ramp)
	var low: Vector2 = ramp.low
	var high_world: Vector3 = ArenaScript.to_world(high_edge, float(map.ground_height(high_edge)) - 0.05)
	var low_world: Vector3 = ArenaScript.to_world(low, float(map.ground_height(low)) - 0.05)
	var delta: Vector3 = low_world - high_world
	if delta.length_squared() < 0.00001:
		return
	var axis_x: Vector3 = delta.normalized()
	var axis_z := Vector3(-axis_x.z, 0.0, axis_x.x).normalized()
	var axis_y: Vector3 = axis_z.cross(axis_x).normalized()
	var basis := Basis(axis_x, axis_y, axis_z)
	var length: float = delta.length()
	var width: float = float(ramp.get("width", 3.0))

	var mesh_resource := BoxMesh.new()
	mesh_resource.size = Vector3(length, 0.18, width)
	var surface := MeshInstance3D.new()
	surface.name = "SupportRamp_%d_%d" % [roundi(Vector2(ramp.high).x), roundi(Vector2(ramp.high).y)]
	surface.mesh = mesh_resource
	surface.material_override = _terrain_material(arena, SUPPORT_COLOR)
	surface.transform = Transform3D(basis, (high_world + low_world) * 0.5)
	surface.add_to_group("high_ground_ramp")
	surface.set_meta("ramp_kind", "support")
	surface.set_meta("high", Vector2(ramp.high))
	surface.set_meta("low", low)
	add_child(surface)

	# Narrow copper rails use the same slope basis and make the fast support route
	# distinct from the cream lane-return ramp without changing collision.
	for side: float in [-1.0, 1.0]:
		var rail_resource := BoxMesh.new()
		rail_resource.size = Vector3(length, 0.12, 0.08)
		var rail := MeshInstance3D.new()
		rail.name = "RailLeft" if side < 0 else "RailRight"
		rail.mesh = rail_resource
		rail.material_override = _terrain_material(arena, COPPER)
		rail.position = Vector3(0.0, 0.14, side * width * 0.47)
		surface.add_child(rail)


func _terrain_material(arena: Variant, color: Color) -> Material:
	var terrain_materials: Dictionary = arena._terrain_materials
	if terrain_materials.has(color):
		return terrain_materials[color]
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = color
	fallback.roughness = 0.82
	return fallback
