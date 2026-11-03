extends Node3D
## Original game meshes, not concept-image billboards. Visual joints only;
## pose() reads authority state and never writes collision or combat data.
const CLOTH := Color("253f49")
const CERAMIC := Color("f0e5c9")
const COPPER := Color("b97c51")
const SKIN := Color("d5a47b")
var hero_key: String = "bas"
var _parts: Dictionary = {}
var _materials: Dictionary = {}
var _team := Color("39c8bb")
var _player: AnimationPlayer
var _rest: Dictionary = {}
var _previous_alive: bool = true
var _death_at: float = -100.0
var _respawn_at: float = -100.0
var current_clip: String = "idle"

func build(key: String, team_color: Color) -> void:
	hero_key = key
	_team = team_color
	var broad: float = 1.0 if key == "bas" else (0.7 if key == "rio" else 0.82)
	var body: Node3D = _joint(self, "Torso", Vector3(0, 1.48, 0))
	_cylinder(body, broad * 0.37, broad * 0.43, 0.86, Vector3(0, 0.14, 0), CERAMIC, 8)
	_block(body, Vector3(broad * 0.67, 0.38, 0.12), Vector3(0, 0.15, -0.32), _team)
	_cylinder(body, broad * 0.38, broad * 0.37, 0.12, Vector3(0, -0.19, 0), COPPER, 10)
	_block(body, Vector3(0.21, 0.16, 0.10), Vector3(0, -0.18, -0.37), COPPER)
	for side: float in [-1.0, 1.0]:
		var leg: Node3D = _joint(self, "LeftLeg" if side < 0 else "RightLeg", Vector3(side * broad * 0.24, 1.06, 0))
		_capsule(leg, 0.13 if key == "rio" else 0.17, 0.79, Vector3(0, -0.34, 0), CLOTH)
		_block(leg, Vector3(0.22, 0.20, 0.16), Vector3(0, -0.47, -0.16), CERAMIC)
		_capsule(leg, 0.17, 0.30, Vector3(0, -0.89, -0.09), CLOTH)
		_block(leg, Vector3(0.32, 0.13, 0.43), Vector3(0, -0.97, -0.09), COPPER)
		var arm: Node3D = _joint(self, "LeftArm" if side < 0 else "RightArm", Vector3(side * broad * 0.51, 1.90, 0))
		_capsule(arm, 0.15, 0.72, Vector3(0, -0.30, 0), CLOTH)
		_sphere(arm, 0.22, Vector3.ZERO, CERAMIC)
		if key == "bas":
			_gauntlet(arm, side > 0)
		elif key == "rio":
			_block(arm, Vector3(0.22, 0.30, 0.26), Vector3(0, -0.47, 0), COPPER)
			var disc: MeshInstance3D = _ring(arm, 0.38, 0.10, Vector3(side * 0.12, -0.43, -0.22), COPPER)
			disc.rotation_degrees = Vector3(65, 0, side * 15)
			_ring(arm, 0.30, 0.025, Vector3(side * 0.12, -0.43, -0.22), _team).rotation = disc.rotation
		else:
			_block(arm, Vector3(0.24, 0.30, 0.25), Vector3(0, -0.45, -0.04), CERAMIC)
			_sphere(arm, 0.12, Vector3(0, -0.60, -0.12), _team)
	var head: Node3D = _joint(self, "Head", Vector3(0, 2.34, 0))
	_sphere(head, 0.235, Vector3.ZERO, SKIN)
	_cylinder(head, 0.235, 0.255, 0.18, Vector3(0, 0.18, 0.03), CLOTH, 10)
	_block(head, Vector3(0.42, 0.11, 0.12), Vector3(0, 0.12, -0.23), _team)
	for side: float in [-1.0, 1.0]:
		_sphere(head, 0.065, Vector3(side * 0.10, 0.025, -0.212), COPPER)
		_sphere(head, 0.048, Vector3(side * 0.10, 0.025, -0.245), Color("a0e1d7"))
	_block(head, Vector3(0.14, 0.045, 0.045), Vector3(0, -0.16, -0.25), CLOTH)
	if key == "bas":
		var tank: MeshInstance3D = _cylinder(body, 0.23, 0.23, 0.60, Vector3(0, 0.18, 0.38), COPPER, 10)
		tank.rotation_degrees.z = 90
		for x: float in [-0.20, 0.20]:
			_sphere(body, 0.10, Vector3(x, 0.49, 0.37), _team)
	elif key == "rio":
		var cape: Node3D = _joint(self, "Cloth", Vector3(0, 1.98, 0.2))
		_cloth(cape, 0.52, 1.10, _team)
		for side: float in [-1.0, 1.0]:
			_block(body, Vector3(0.15, 0.34, 0.18), Vector3(side * 0.32, -0.27, 0.17), COPPER)
	else:
		_block(body, Vector3(0.73, 0.77, 0.35), Vector3(0, 0.15, 0.43), COPPER)
		_block(body, Vector3(0.57, 0.51, 0.07), Vector3(0, 0.15, 0.64), _team)
		for side: float in [-1.0, 1.0]:
			_cylinder(body, 0.075, 0.11, 1.18, Vector3(side * 0.31, 0.62, 0.39), CERAMIC, 8)
			_sphere(body, 0.14, Vector3(side * 0.31, 1.24, 0.39), _team)
			_ring(body, 0.18, 0.035, Vector3(side * 0.31, 1.16, 0.39), COPPER)
		var cape: Node3D = _joint(self, "Cloth", Vector3(0, 1.65, 0.2))
		_cloth(cape, 0.70, 0.77, CLOTH)

	if key == "bas":
		_block(head, Vector3(0.44, 0.20, 0.12), Vector3(0, -0.07, -0.20), CLOTH)
		for side: float in [-1.0, 1.0]:
			var plate: MeshInstance3D = _block(self, Vector3(0.44, 0.18, 0.53), Vector3(side * 0.57, 2.01, 0), CERAMIC)
			plate.rotation.z = side * -0.18
	elif key == "rio":
		var crest: MeshInstance3D = _block(head, Vector3(0.12, 0.22, 0.43), Vector3(0, 0.23, 0.10), COPPER)
		crest.rotation.x = -0.30
	else:
		_cylinder(head, 0.12, 0.34, 0.27, Vector3(0, 0.25, 0.04), CERAMIC, 6)
		_ring(head, 0.33, 0.035, Vector3(0, 0.13, 0.04), COPPER)
	for part: String in _parts:
		_rest[part] = _parts[part].position
	_build_animations()

func _gauntlet(arm: Node3D, large: bool) -> void:
	var factor: float = 1.15 if large else 0.88
	var shell: MeshInstance3D = _cylinder(arm, 0.33 * factor, 0.26 * factor, 0.62, Vector3(0, -0.38, -0.16), CERAMIC, 8)
	shell.rotation_degrees.x = 64
	_ring(arm, 0.30 * factor, 0.065, Vector3(0, -0.22, -0.08), COPPER).rotation_degrees.x = 64
	for x: float in [-0.18, 0.0, 0.18]:
		_block(arm, Vector3(0.15, 0.22, 0.16) * factor, Vector3(x * factor, -0.55, -0.48), COPPER)
	_block(arm, Vector3(0.36, 0.12, 0.10) * factor, Vector3(0, -0.26, -0.43), _team)

func _build_animations() -> void:
	_player = AnimationPlayer.new()
	_player.name = "AnimationPlayer"
	_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(_player)
	var library := AnimationLibrary.new()
	_player.add_animation_library("", library)
	var amplitude: float = 0.48 if hero_key == "bas" else 0.65
	_add_clip(library, "idle", 2.0, {"Torso": Vector3(0.025, 0, 0), "Head": Vector3(0, 0.025, 0), "LeftArm": Vector3(0.03, 0, 0), "RightArm": Vector3(-0.03, 0, 0)}, true)
	_add_clip(library, "walk", 0.58 if hero_key == "rio" else 0.72, {"LeftLeg": Vector3(amplitude, 0, 0), "RightLeg": Vector3(-amplitude, 0, 0), "LeftArm": Vector3(-amplitude * 0.55, 0, 0), "RightArm": Vector3(amplitude * 0.55, 0, 0), "Torso": Vector3(-0.08, 0.05, 0)}, true)
	var basic := {"RightArm": Vector3(-1.55, 0, -0.15), "LeftArm": Vector3(-0.25, 0, 0.15), "Torso": Vector3(0.10, 0.32, 0), "Head": Vector3(0, -0.12, 0)}
	_add_clip(library, "basic", 1.0, basic)
	var poses: Dictionary
	if hero_key == "bas":
		poses = {"Q": [Vector3(-1.55, 0, -0.55),Vector3(-1.9, 0, 0.3),Vector3(0.24, 0.35, 0)], "W": [Vector3(-1.30, 0, 0.62),Vector3(-1.30, 0, -0.62),Vector3(0.10, 0, 0)], "E": [Vector3(-0.4, 0, -0.2),Vector3(-1.85, 0, 0),Vector3(-0.35, -0.15, 0)], "R": [Vector3(-2.85, 0, -0.20),Vector3(-2.85, 0, 0.20),Vector3(-0.20, 0, 0)]}
	elif hero_key == "rio":
		poses = {"Q": [Vector3(-0.3, 0, -0.55),Vector3(-1.4, 0, 0.8),Vector3(0, -0.60, 0.15)], "W": [Vector3(-1.8, 0, -0.2),Vector3(-0.6, 0, 0.25),Vector3(0.22, 0.22, 0)], "E": [Vector3(0.5, 0, -0.65),Vector3(0.5, 0, 0.65),Vector3(-0.48, 0, 0.25)], "R": [Vector3(-1.4, 0, -1.2),Vector3(-1.4, 0, 1.2),Vector3(-0.08, 0.60, 0)]}
	else:
		poses = {"Q": [Vector3(-0.4, 0, -0.25),Vector3(-1.9, 0, 0.15),Vector3(0.25, -0.20, 0)], "W": [Vector3(-1.5, 0, -0.75),Vector3(-1.5, 0, 0.75),Vector3(0.12, 0, 0)], "E": [Vector3(-1.3, 0, 0.25),Vector3(-1.0, 0, -0.50),Vector3(-0.10, 0.25, 0)], "R": [Vector3(-2.45, 0, -0.8),Vector3(-2.45, 0, 0.8),Vector3(-0.22, 0, 0)]}
	for slot: String in poses:
		_add_clip(library, slot, 1.0, {"LeftArm": poses[slot][0], "RightArm": poses[slot][1], "Torso": poses[slot][2], "Head": Vector3(-0.08, 0, 0)})
	_add_clip(library, "hit", 0.26, {"LeftArm": Vector3(0.30, 0, -0.15), "RightArm": Vector3(0.30, 0, 0.15), "Torso": Vector3(-0.3, 0, 0.16), "Head": Vector3(-0.25, 0, 0)})
	_add_clip(library, "death", 0.85, {"LeftArm": Vector3(0.30, 0, -0.50), "RightArm": Vector3(0.30, 0, 0.50), "Torso": Vector3(0.6, 0, 0.2), "Head": Vector3(0.3, 0, 0.15)})
	var death: Animation = library.get_animation("death")
	var root_track: int = death.add_track(Animation.TYPE_VALUE)
	death.track_set_path(root_track, NodePath(".:rotation"))
	death.track_insert_key(root_track, 0, Vector3.ZERO)
	death.track_insert_key(root_track, 0.85, Vector3(0, 0, -1.48))
	_add_clip(library, "respawn", 0.65, {"LeftArm": Vector3(-0.6, 0, -0.3), "RightArm": Vector3(-0.6, 0, 0.3), "Torso": Vector3(0.24, 0, 0), "Head": Vector3(0.22, 0, 0)})

func _add_clip(library: AnimationLibrary, title: String, length: float, joints: Dictionary, loop: bool = false) -> void:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for part: String in joints:
		var track: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track, NodePath(part + ":rotation"))
		var peak: Vector3 = joints[part]
		anim.track_insert_key(track, 0.0, -peak * 0.6 if title == "walk" else Vector3.ZERO)
		anim.track_insert_key(track, length * 0.38, peak)
		anim.track_insert_key(track, length * 0.68, -peak * 0.6 if title == "walk" else peak * 0.82)
		anim.track_insert_key(track, length, -peak * 0.6 if title == "walk" else Vector3.ZERO)
	library.add_animation(title, anim)

func pose(unit: Dictionary, time: float) -> void:
	if _player == null: return
	if bool(unit.alive) != _previous_alive:
		if unit.alive: _respawn_at = time
		else: _death_at = time
		_previous_alive = bool(unit.alive)
	rotation = Vector3.ZERO
	position = Vector3.ZERO
	for part: String in _parts:
		_parts[part].rotation = Vector3.ZERO
		_parts[part].position = _rest[part]
	var clip: String = "idle"
	var sample: float = fposmod(time, 2.0)
	if not unit.alive:
		clip = "death"
		sample = clampf(time - _death_at, 0, 0.849)
	elif time - _respawn_at < 0.65:
		clip = "respawn"
		sample = maxf(0.0, time - _respawn_at)
	elif str(unit.phase) in ["windup", "recovery", "dash"] and not unit.cast.is_empty():
		clip = str(unit.cast.get("slot", "idle"))
		if unit.phase == "windup":
			sample = clampf(1.0 - float(unit.phase_left) / maxf(0.001, float(unit.cast.get("windup", 0.2))), 0, 1) * 0.60
		elif unit.phase == "recovery":
			sample = 0.60 + clampf(1.0 - float(unit.phase_left) / maxf(0.001, float(unit.cast.get("recovery", 0.2))), 0, 1) * 0.39
		else: sample = 0.55
	elif str(unit.phase) == "basic":
		clip = "basic"
		sample = clampf(1.0 - float(unit.phase_left) / maxf(0.01, float(unit.attack_windup)), 0.0, 1.0) * 0.7
	elif time - float(unit.last_damage) < 0.26:
		clip = "hit"
		sample = maxf(0.0, time - float(unit.last_damage))
	elif str(unit.phase) == "walk":
		clip = "walk"
		sample = fposmod(time, _player.get_animation(clip).length)
	current_clip = clip if _player.has_animation(clip) else "idle"
	_player.play(current_clip)
	_player.seek(sample, true)
	if float(unit.stun_left) > 0:
		_parts.Head.rotation.z += 0.23
	if _parts.has("Cloth"):
		_parts.Cloth.rotation.x = 0.12 + sin(time * 5) * (0.16 if unit.phase in ["walk", "dash"] else 0.04)

func _joint(parent: Node3D, title: String, point: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = title
	node.position = point
	parent.add_child(node)
	_parts[title] = node
	return node

func _material(color: Color) -> StandardMaterial3D:
	if not _materials.has(color):
		var mat := StandardMaterial3D.new()
		mat.albedo_color = color
		mat.roughness = 0.65
		mat.metallic = 0.45 if color == COPPER else 0.05
		_materials[color] = mat
	return _materials[color]

func _mesh(parent: Node3D, shape: Mesh, point: Vector3, color: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = shape
	node.material_override = _material(color)
	node.position = point
	parent.add_child(node)
	return node

func _block(parent: Node3D, dimensions: Vector3, point: Vector3, color: Color) -> MeshInstance3D:
	var shape := BoxMesh.new()
	shape.size = dimensions
	return _mesh(parent, shape, point, color)

func _sphere(parent: Node3D, radius: float, point: Vector3, color: Color) -> MeshInstance3D:
	var shape := SphereMesh.new()
	shape.radius = radius
	shape.height = radius * 2
	shape.radial_segments = 12
	shape.rings = 6
	return _mesh(parent, shape, point, color)

func _capsule(parent: Node3D, radius: float, height: float, point: Vector3, color: Color) -> MeshInstance3D:
	var shape := CapsuleMesh.new()
	shape.radius = radius
	shape.height = maxf(height, radius * 2)
	shape.radial_segments = 10
	shape.rings = 4
	return _mesh(parent, shape, point, color)

func _cylinder(parent: Node3D, top: float, bottom: float, height: float, point: Vector3, color: Color, sides: int = 12) -> MeshInstance3D:
	var shape := CylinderMesh.new()
	shape.top_radius = top
	shape.bottom_radius = bottom
	shape.height = height
	shape.radial_segments = sides
	return _mesh(parent, shape, point, color)

func _ring(parent: Node3D, radius: float, thickness: float, point: Vector3, color: Color) -> MeshInstance3D:
	var shape := TorusMesh.new()
	shape.inner_radius = radius - thickness
	shape.outer_radius = radius + thickness
	shape.rings = 16
	shape.ring_segments = 8
	return _mesh(parent, shape, point, color)

func _cloth(parent: Node3D, width: float, length: float, color: Color) -> void:
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var a := Vector3(-width * 0.45, 0, 0)
	var b := Vector3(width * 0.45, 0, 0)
	var c := Vector3(width * 0.65, -length, 0.50)
	var d := Vector3(-width * 0.60, -length * 0.85, 0.53)
	for point: Vector3 in [a, b, c, a, c, d, c, b, a, d, c, a]:
		surface.add_vertex(point)
	surface.generate_normals()
	_mesh(parent, surface.commit(), Vector3.ZERO, color)
