extends "res://scripts/presentation/arena_view.gd"
## Vertex-painted canal gardens and working aqueducts on the M01 authority map.
const HeroRig = preload("res://scripts/presentation/hero_rig.gd")

const JADE := preload("res://assets/environment/jade_willow.glb")
const AMBER := preload("res://assets/environment/amber_fig.glb")
const CLOISTER := preload("res://assets/environment/ivy_cloister.glb")
const MILL := preload("res://assets/environment/copper_millwheel.glb")
const BANK := preload("res://assets/environment/garden_bank.glb")
const MOSAIC := preload("res://assets/environment/guild_mosaic.glb")
const RAIL := preload("res://assets/environment/quay_rail.glb")
const GATEHOUSE := preload("res://assets/environment/terracotta_gatehouse.glb")
const CRYSTAL := preload("res://assets/environment/crown_crystal.glb")
const OBSERVATORY := preload("res://assets/environment/core_observatory.glb")
const SENTINEL := preload("res://assets/environment/sentinel_crown.glb")

var _wheels: Array[Node3D] = []

func _process(delta: float) -> void:
	for wheel: Node3D in _wheels:
		wheel.rotate_z(0.24 * delta)


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
	for point: Vector2 in map.high_ground_cells:
		var height: float = float(map.ground_height(point))
		# A masonry drum replaces the visually floating platform underside.
		_cylinder(detail, 2.14, height + 0.22, to_world(point, height * 0.5 - 0.18), Color("9f9277"), 16)
		for tier: int in range(3):
			var ring: MeshInstance3D = ring_mesh(2.16, 0.05, COPPER)
			ring.position = to_world(point, 0.35 + tier * 0.78)
			# Use terrain material rather than emissive hidden-object decoration.
			ring.material_override = _terrain_materials.get(COPPER)
			detail.add_child(ring)
		for angle: float in [0.0, PI]:
			var edge: Vector2 = point + Vector2(cos(angle), sin(angle)) * 1.95
			_box(detail, Vector3(0.22, 0.45, 0.25), to_world(edge, height + 0.20), COPPER)
	# The outer planted banks are broad, low and varied. A visible water gap
	# separates them from the light walkable paving all along the outer lanes.
	for side: float in [-1.0, 1.0]:
		for i: int in range(9):
			var bank_point := Vector2(-48.0 + i * 12.0,side * (32.5 + 1.6 * cos(i * 1.64)))
			var shore := _scenery(fantasy_decor,BANK,to_world(bank_point,-0.03))
			shore.scale = Vector3(2.65 + 0.22 * cos(i), 1.4, 2.52 + 0.25 * sin(i))
			shore.rotation.y = 0.12 * sin(i * 3.8)
			for offset: float in [-2.8,2.6]:
				var grove := _scenery(fantasy_decor, JADE if (i % 3) != 0 else AMBER,
					to_world(bank_point + Vector2(offset,side * sin(i + offset)),0.26))
				grove.scale = Vector3.ONE * (0.93 + 0.27 * sin(i * 1.14 + offset))
				grove.rotation.y = i * 2.14 + offset
	_quays(map,fantasy_decor)
	# Low islands frame the navigable paths. The four footprint samples keep
	# even the widest crown and stone skirt clear of the gameplay corridor.
	var groves := [Vector2(47, 14), Vector2(44, 19), Vector2(39, 23),
		Vector2(30, 28), Vector2(23, 30), Vector2(13, 26), Vector2(6, 27),
		Vector2(1, 32), Vector2(34, 6), Vector2(10, 8)]
	for east: float in [-1.0, 1.0]:
		for north: float in [-1.0, 1.0]:
			for i: int in range(groves.size()):
				var point: Vector2 = groves[i] * Vector2(east,north)
				var extent: float = 1.25 if i >= 8 else 2.0
				var clear := true
				for offset: Vector2 in [Vector2.ZERO,Vector2.LEFT,Vector2.RIGHT,Vector2.UP,Vector2.DOWN]:
					if map.is_ground(point + offset * extent):
						clear = false
						break
				if clear:
					var shore := _scenery(fantasy_decor, BANK, to_world(point, -0.08))
					shore.scale = Vector3(0.74,0.87,0.68) if i >= 8 else Vector3(1.12,1.02,1.28)
					shore.rotation.y = east * north * 0.27
					var tree := _scenery(fantasy_decor, AMBER if (i + int(east > 0)) % 3 == 0 else JADE, to_world(point,0.12))
					tree.scale = Vector3.ONE * (0.66 if i >= 8 else (1.00 + 0.13 * (i % 3)))
					tree.rotation.y = east * i * 1.72 + north * 0.5
	var relief: Node3D = load("res://scripts/presentation/terrain_relief.gd").new()
	relief.name = "TerrainRelief"
	add_child(relief)
	relief.build(map, material(Color("958c75")))
	var paving_tints := {CREAM: Color("c9c4b9"), PALE: Color("d8d1bd"),
		Color("e1d4af"): Color("c1c6ae"), Color("d9d0ae"): Color("b5c1af")}
	for source: Color in paving_tints:
		_terrain_materials[source].set_shader_parameter("base_color", paving_tints[source])
	_building_terrain = false

func _scenery(parent: Node3D, asset: PackedScene, at: Vector3) -> Node3D:
	var prop := asset.instantiate() as Node3D
	parent.add_child(prop)
	prop.position = at
	var painted := material(Color("fcfff7") if asset == BANK else Color.WHITE) as ShaderMaterial
	painted.set_shader_parameter("finish", 5 if asset == BANK else 3)
	_paint(prop,painted)
	return prop


func _paint(prop: Node3D, paint: Material) -> void:
	if prop is MeshInstance3D:
		(prop as MeshInstance3D).material_override = paint
	for child in prop.find_children("*", "MeshInstance3D", true, false):
		(child as MeshInstance3D).material_override = paint


func _lane_emblem(position: Vector2, letter: String) -> void:
	var mark := _scenery(self,MOSAIC,to_world(position,0.075))
	mark.scale = Vector3.ONE * (1.27 if letter == "C" else 0.98)


func _quays(map: Variant,parent: Node3D) -> void:
	# Place short low balustrades only where the far side is canal. Keep the
	# openings at every junction, objective pad, and ramp free.
	for lane: Array in map.lane_paths:
		for i: int in range(lane.size() - 1):
			var a: Vector2 = lane[i]
			var b: Vector2 = lane[i + 1]
			var heading := (b - a).normalized()
			for side: float in [-1.0,1.0]:
				var outside := heading.orthogonal() * side
				for step: int in range(3, floori(a.distance_to(b))-2, 5):
					var edge := a + heading * float(step) + outside * 3.00
					var connects := false
					for x: float in [-1.45, 0.0, 1.45]:
						if map.is_ground(edge + outside * 0.45 + heading * x):
							connects = true
							break
					if not connects:
						var rail := _scenery(parent,RAIL,to_world(edge,0.035))
						rail.rotation.y = atan2(heading.y,heading.x)


func _garden(at: Vector3, size_factor: float = 1.0) -> void:
	var shore := _scenery(self,BANK,at + Vector3.UP * 0.17)
	shore.scale = Vector3(size_factor * 1.38,1.0,size_factor * 1.19)
	var tree := _scenery(self, JADE if at.x < 0 else AMBER, at + Vector3.UP * 0.4)
	tree.scale = Vector3.ONE * size_factor


func _blocker(rect: Rect2) -> void:
	var center := rect.get_center()
	# The foundation fills the authoritative rectangle. The arcade sits above it.
	var bank := _scenery(self,BANK,to_world(center,-0.02))
	bank.scale = Vector3(rect.size.x / 6.3,1.16,rect.size.y / 3.45)
	var large := rect.size.x >= 10.0
	var spans: int = 3 if large else 1
	for i in range(spans):
		var u := (float(i) + 0.5) / float(spans) - 0.5
		var point := center + Vector2(u * rect.size.x, 0.0)
		var arch := _scenery(self, CLOISTER, to_world(point,0.18))
		arch.scale = Vector3(rect.size.x / (4.15 * spans), 1.08, 1.60)
	if large:
		var near_bank := center + Vector2(0.6,-rect.size.y*0.36)
		var wheel := _scenery(self, MILL, to_world(near_bank,1.02))
		_wheels.append(wheel)
		var bank_side := signf(center.y)
		# Place the sluice house on the blocker footprint, with its front door
		# and working wheel facing mid. The adjacent arcade remains visible.
		var lodge := _scenery(self, GATEHOUSE,
			to_world(center + Vector2(-3.7 * bank_side, 0.72 * bank_side), 0.25))
		lodge.scale = Vector3.ONE * 1.11
		var tree := _scenery(self, JADE, to_world(center + Vector2(4.35 * bank_side, 1.12), 0.18))
		tree.scale = Vector3.ONE * 0.72


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

func _boundary_workshop(at: Vector3, mirror: float) -> void:
	var arch := _scenery(self, CLOISTER, at)
	arch.scale = Vector3(1.28,1.22,1.12)
	var wheel := _scenery(self, MILL, at + Vector3(0.7 * mirror,1.34,0.74))
	_wheels.append(wheel)


func _drying_rack(position: Vector3) -> void:
	# Crystal shrine, not a misleading traversable bridge.
	_cylinder(self, 0.95, 0.32, position + Vector3(0, 0.16, 0), Color("b8bca7"), 8)
	for side: float in [-1.0, 1.0]:
		_cylinder(self, 0.14, 1.5, position + Vector3(side * 0.57, 0.86, 0), Color("e7d8ae"), 6)
		var gem: MeshInstance3D = _sphere(self, 0.24, position + Vector3(side * 0.57, 1.78, 0), Color("91dffa"))
		gem.scale.y = 1.42

func _structure_art(parent: Node3D, asset: PackedScene, color: Color) -> Node3D:
	var art := asset.instantiate() as Node3D
	parent.add_child(art)
	var warm := color == ORANGE
	var cache_key := "ember_ceramic" if warm else "azure_ceramic"
	var paint := _materials.get(cache_key) as ShaderMaterial
	if paint == null:
		paint = ShaderMaterial.new()
		paint.shader = TERRAIN_SHADER
		paint.set_shader_parameter("finish", 3)
		paint.set_shader_parameter("warm_ceramic", warm)
		_materials[cache_key] = paint
	_paint(art, paint)
	return art


func _tower(parent: Node3D, subtype: String, color: Color) -> void:
	_structure_art(parent, SENTINEL, color)
	var gem := _structure_art(parent, CRYSTAL, color)
	gem.position = Vector3(0, 1.99, 0)
	gem.scale = Vector3.ONE * (1.18 if subtype == "inner" else 1.04)
	if subtype == "inner":
		var halo := ring_mesh(0.79, 0.055, color)
		halo.position.y = 2.37
		parent.add_child(halo)


func _core(parent: Node3D, color: Color) -> void:
	_structure_art(parent, OBSERVATORY, color)
	var gem := _structure_art(parent, CRYSTAL, color)
	gem.position = Vector3(0, 1.13, 0)
	gem.scale = Vector3.ONE * 2.12


func _cell(parent: Node3D, unit: Dictionary) -> void:
	super._cell(parent, unit)
	var socket: MeshInstance3D = ring_mesh(0.51, 0.065, COPPER)
	socket.position.y = 0.30
	parent.add_child(socket)
