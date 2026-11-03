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
	detail.name = "WorkshopDetail" # Existing integration tests rely on this name.
	add_child(detail)
	var fantasy_decor := Node3D.new()
	fantasy_decor.name = "FantasyDecor"
	detail.add_child(fantasy_decor)
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
			# Non-walkable islands only; purely cosmetic fantasy tree and runestones.
			_fantasy_tree(fantasy_decor, to_world(point, 0), mirror < 0)
			_fantasy_crystal(fantasy_decor, to_world(point + Vector2(1.55 * mirror, 1.45), 0))
	var relief: Node3D = load("res://scripts/presentation/terrain_relief.gd").new()
	relief.name = "TerrainRelief"
	add_child(relief)
	# Acquire a fog-aware stone material via the existing terrain material cache.
	var donor: MeshInstance3D = _box(detail, Vector3(0.01, 0.01, 0.01), Vector3(0, -2, 0), Color("958c75"))
	relief.build(map, donor.material_override)
	donor.queue_free()
	# Quieter stone/river values keep bright ceramic heroes and skills readable.
	var tones: Dictionary = {Color("e9dfbe"): Color("d9d1b0"), Color("f8edd4"): Color("e8dcba"), Color("e1d4af"): Color("bcd6a8"), Color("d9d0ae"): Color("b5d1af"), Color("62aaa0"): Color("549f89"), Color("326c69"): Color("316e68"), Color("c2b798"): Color("a4b59a"), Color("b1a58b"): Color("879e80"), Color("e2d2af"): Color("dce6be"), Color("b8ad91"): Color("91ae93"), Color("c3b896"): Color("becbab")}
	for source: Color in tones:
		if _terrain_materials.has(source): _terrain_materials[source].set_shader_parameter("base_color", tones[source])
	_building_terrain = false

func _fantasy_tree(parent: Node3D, base: Vector3, left: bool) -> void:
	# All scenery has no collision or vision authority. Layer is hidden by fog shader.
	_cylinder(parent, 0.25, 1.25, base + Vector3(0, 0.62, 0), Color("84634e"), 7)
	for tier: int in range(3):
		var crown: MeshInstance3D = _sphere(parent, 0.95 - tier * 0.13, base + Vector3(0, 1.35 + tier * 0.55, 0), Color("5ba76b") if left else Color("4a9c85"))
		crown.scale = Vector3(1.15, 0.72, 1.08)
	_sphere(parent, 0.13, base + Vector3(0.56, 1.84, 0.12), Color("ffe1a0"))

func _fantasy_crystal(parent: Node3D, base: Vector3) -> void:
	_cylinder(parent, 0.33, 0.30, base + Vector3(0, 0.16, 0), Color("637884"), 6)
	var shard: MeshInstance3D = _cylinder(parent, 0.03, 0.29, base + Vector3(0, 0.75, 0), Color("94d9f8"), 6)
	shard.rotation_degrees.z = -12
	_sphere(parent, 0.14, base + Vector3(0.06, 1.12, 0), Color("d7f1ff"))

func _blocker(rect: Rect2) -> void:
	var center: Vector2 = rect.get_center()
	_box(self, Vector3(rect.size.x, 1.25, rect.size.y), to_world(center, 0.40), Color("958c75"))
	var pieces: int = maxi(2, int(rect.size.x / 1.1))
	for tier: int in range(3):
		for piece: int in range(pieces):
			var x: float = rect.position.x + (float(piece) + 0.5) * rect.size.x / pieces
			_box(self, Vector3(rect.size.x / pieces - 0.045, 0.34, rect.size.y + 0.025), to_world(Vector2(x, center.y), 0.18 + tier * 0.36), Color("c2b798") if (piece + tier) % 2 == 0 else Color("b1a58b"))
	_box(self, Vector3(rect.size.x + 0.08, 0.16, rect.size.y + 0.08), to_world(center, 1.28), Color("e2d2af"))


# The following overrides replace workshop props with fantasy-world ornaments.
# They have no physics body, selection collider, simulation effect or path metadata.
func _minion(parent: Node3D, subtype: String, color: Color) -> void:
	var siege: bool = subtype == "siege"
	var radius: float = 0.38 if siege else 0.28
	_cylinder(parent, radius, 0.65 if siege else 0.52, Vector3(0, 0.37, 0), Color("e4d8b6"), 8)
	_sphere(parent, radius * 0.86, Vector3(0, 0.84, 0), Color("f4ccab"))
	_cylinder(parent, radius * 1.03, 0.22, Vector3(0, 1.10, 0), color, 10)
	_box(parent, Vector3(0.38 if siege else 0.24, 0.12, 0.37), Vector3(0, 0.52, -0.30), color)
	for side: float in [-1.0, 1.0]:
		_cylinder(parent, 0.10, 0.38, Vector3(side * radius * 0.49, 0.12, 0), Color("373a59"), 6)
	if subtype == "melee":
		_box(parent, Vector3(0.13, 0.62, 0.14), Vector3(0.40, 0.70, -0.12), Color("e9eef1"))
		_box(parent, Vector3(0.25, 0.27, 0.10), Vector3(-0.43, 0.52, -0.28), color)
	elif subtype == "ranged":
		_cylinder(parent, 0.055, 0.77, Vector3(0.38, 0.72, -0.10), Color("e4bd7e"), 8)
		_sphere(parent, 0.18, Vector3(0.38, 1.14, -0.10), Color("9de9ff"))
	else:
		_sphere(parent, 0.36, Vector3(0, 1.42, 0), Color("addafb")).scale = Vector3(0.8, 1.3, 0.8)

func _workbench(position: Vector3, team: int) -> void:
	var side_color: Color = TEAL if team == 0 else ORANGE
	_cylinder(self, 0.80, 0.30, position + Vector3(0, 0.18, 0), Color("d9ceb2"), 10)
	for angle: float in [0.0, PI * 0.5, PI, PI * 1.5]:
		var offset := Vector3(cos(angle) * 0.58, 0, sin(angle) * 0.58)
		_cylinder(self, 0.10, 1.05, position + offset + Vector3.UP * 0.82, Color("acb9aa"), 7)
	_sphere(self, 0.40, position + Vector3.UP * 1.50, side_color).scale.y = 1.25
	_sphere(self, 0.16, position + Vector3.UP * 1.86, Color("e5f8ef"))

func _boundary_workshop(position: Vector3, mirror: float) -> void:
	# Stone arch ruin beyond the traversable field.
	for side: float in [-1.0, 1.0]:
		_box(self, Vector3(0.65, 2.8, 0.65), position + Vector3(side * 1.55, 1.2, 0), Color("b7c8b5"))
		_box(self, Vector3(0.82, 0.23, 0.82), position + Vector3(side * 1.55, 2.55, 0), Color("e0d8ba"))
	_box(self, Vector3(3.7, 0.36, 0.72), position + Vector3(0, 2.75, 0), Color("d3cfb9"))
	var sigil: MeshInstance3D = ring_mesh(0.62, 0.09, Color("a9f0da") if mirror < 0 else Color("f1aeec"))
	sigil.position = position + Vector3(0, 1.65, 0)
	sigil.rotation.x = PI * 0.5
	add_child(sigil)

func _drying_rack(position: Vector3) -> void:
	# Crystal shrine, not a misleading traversable bridge.
	_cylinder(self, 0.95, 0.32, position + Vector3(0, 0.16, 0), Color("b8bca7"), 8)
	for side: float in [-1.0, 1.0]:
		_cylinder(self, 0.14, 1.5, position + Vector3(side * 0.57, 0.86, 0), Color("e7d8ae"), 6)
		var gem: MeshInstance3D = _sphere(self, 0.24, position + Vector3(side * 0.57, 1.78, 0), Color("91dffa"))
		gem.scale.y = 1.42

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
