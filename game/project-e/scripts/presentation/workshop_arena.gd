extends "res://scripts/presentation/arena_view.gd"
## First in-engine workshop art pass. Authority footprints and ramps are unchanged.
const HeroRig = preload("res://scripts/presentation/hero_rig.gd")

func _hero(parent: Node3D, key: String, color: Color) -> void:
	var rig: Node3D = HeroRig.new()
	rig.name = "HeroRig"
	parent.add_child(rig)
	rig.build(key, color)

func build(map: Variant, units: Dictionary) -> void:
	super.build(map, units)
	var detail := Node3D.new()
	detail.name = "WorkshopDetail"
	add_child(detail)
	_building_terrain = true
	# Masonry joints lie on existing lane ground; they never declare new paths.
	for lane: Array in map.lane_paths:
		for index: int in range(lane.size() - 1):
			var a: Vector2 = lane[index]
			var b: Vector2 = lane[index + 1]
			var direction: Vector2 = (b - a).normalized()
			var normal := Vector2(-direction.y, direction.x)
			var length: float = a.distance_to(b)
			for step: int in range(2, int(length), 3):
				var point: Vector2 = a + direction * float(step)
				if map.ground_height(point) > 0.05:
					continue
				var seam: MeshInstance3D = _box(detail, Vector3(0.045, 0.025, 5.2), to_world(point, 0.055), Color("b8ad91"))
				seam.rotation.y = atan2(direction.y, direction.x)
				for side: float in [-1.0, 1.0]:
					var inset: Vector2 = point + normal * side * 2.62
					if map.is_ground(inset):
						var tile: MeshInstance3D = _box(detail, Vector3(1.10, 0.055, 0.22), to_world(inset, 0.065), Color("c3b896"))
						tile.rotation.y = atan2(direction.y, direction.x)
	for point: Vector2 in map.high_ground_cells:
		var height: float = float(map.ground_height(point))
		# A masonry drum replaces the visually floating platform underside.
		_cylinder(detail, 2.14, height + 0.35, to_world(point, height * 0.5 - 0.16), Color("9f9277"), 16)
		for tier: int in range(3):
			var ring: MeshInstance3D = ring_mesh(2.16, 0.05, COPPER)
			ring.position = to_world(point, 0.35 + tier * 0.78)
			# Use terrain material rather than emissive hidden-object decoration.
			ring.material_override = _terrain_materials.get(COPPER)
			detail.add_child(ring)
		for angle: float in [0.0, PI]:
			var edge: Vector2 = point + Vector2(cos(angle), sin(angle)) * 1.95
			_box(detail, Vector3(0.22, 0.45, 0.25), to_world(edge, height + 0.20), COPPER)
	# Static workshop props stay on existing non-walkable garden islands.
	for mirror: float in [-1.0, 1.0]:
		for north: float in [-31.0, 31.0]:
			var point := Vector2(mirror * 29.0, north)
			if map.is_ground(point):
				continue
			for offset: float in [-1.1, 0.0, 1.1]:
				_cylinder(detail, 0.45, 0.55, to_world(point + Vector2(offset, 0), 0.1), Color("98734d"), 10)
				var bush: MeshInstance3D = _sphere(detail, 0.61, to_world(point + Vector2(offset, 0), 0.7), Color("729276"))
				bush.scale = Vector3(1.2, 0.85, 1.0)
	_building_terrain = false

func _blocker(rect: Rect2) -> void:
	var center: Vector2 = rect.get_center()
	_box(self, Vector3(rect.size.x, 1.25, rect.size.y), to_world(center, 0.40), Color("958c75"))
	var pieces: int = maxi(2, int(rect.size.x / 1.1))
	for tier: int in range(3):
		for piece: int in range(pieces):
			var x: float = rect.position.x + (float(piece) + 0.5) * rect.size.x / pieces
			_box(self, Vector3(rect.size.x / pieces - 0.045, 0.34, rect.size.y + 0.025), to_world(Vector2(x, center.y), 0.18 + tier * 0.36), Color("c2b798") if (piece + tier) % 2 == 0 else Color("b1a58b"))
	_box(self, Vector3(rect.size.x + 0.08, 0.16, rect.size.y + 0.08), to_world(center, 1.28), Color("e2d2af"))

func _tower(parent: Node3D, subtype: String, color: Color) -> void:
	super._tower(parent, subtype, color)
	for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var direction := Vector3(cos(angle), 0, sin(angle))
		var brace: MeshInstance3D = _box(parent, Vector3(0.15, 1.40, 0.24), direction * 0.69 + Vector3.UP * 1.18, COPPER)
		brace.rotation.y = -angle
		_sphere(parent, 0.11, direction * 0.75 + Vector3.UP * 1.82, color)

func _cell(parent: Node3D, unit: Dictionary) -> void:
	super._cell(parent, unit)
	var socket: MeshInstance3D = ring_mesh(0.51, 0.065, COPPER)
	socket.position.y = 0.30
	parent.add_child(socket)
