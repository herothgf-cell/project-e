extends Node3D
## Static embankments below authoritative ground only. No new collision/paths.
var supported_ramps: int = 0
func build(map: Variant, material: Material) -> void:
	var mesh := SurfaceTool.new()
	mesh.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ramp: Dictionary in map.high_ground_ramps:
		var high: Vector2 = map.ramp_high_edge(ramp)
		var low: Vector2 = ramp.low
		var normal: Vector2 = (low - high).normalized().orthogonal()
		for side: float in [-1.0, 1.0]:
			var offset: Vector2 = normal * side * (float(ramp.width) * 0.5 - 0.03)
			for i: int in range(12):
				var a: Vector2 = high.lerp(low, float(i) / 12) + offset
				var b: Vector2 = high.lerp(low, float(i + 1) / 12) + offset
				_wall(mesh, a, b, float(map.ground_height(a)), float(map.ground_height(b)))
		supported_ramps += 1
	# Low banks make walkable causeways read as land rather than floating strips.
	for lane: Array in map.lane_paths:
		for index: int in range(lane.size() - 1):
			var a: Vector2 = lane[index]
			var b: Vector2 = lane[index + 1]
			var normal: Vector2 = (b - a).normalized().orthogonal()
			var count: int = maxi(1, ceili(a.distance_to(b)))
			for i: int in range(count):
				for side: float in [-1.0, 1.0]:
					var start: Vector2 = a.lerp(b, float(i) / count) + normal * side * 2.98
					var finish: Vector2 = a.lerp(b, float(i + 1) / count) + normal * side * 2.98
					if not map.is_ground((start + finish) * 0.5 + normal * side * 0.30):
						_wall(mesh, start, finish, 0.0, 0.0)
	mesh.generate_normals()
	var surface := MeshInstance3D.new()
	surface.mesh = mesh.commit()
	surface.material_override = material
	add_child(surface)
func _wall(mesh: SurfaceTool, a: Vector2, b: Vector2, ya: float, yb: float) -> void:
	var at := Vector3(a.x, ya - 0.035, -a.y)
	var bt := Vector3(b.x, yb - 0.035, -b.y)
	var ab := Vector3(a.x, -0.7, -a.y)
	var bb := Vector3(b.x, -0.7, -b.y)
	for p: Vector3 in [at, ab, bb, at, bb, bt, bb, ab, at, bt, bb, at]: mesh.add_vertex(p)
