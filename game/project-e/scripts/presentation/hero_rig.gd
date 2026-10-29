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

func build(key: String, team_color: Color) -> void:
	hero_key = key
	_team = team_color
	var broad: float = 1.0 if key == "bas" else (0.7 if key == "rio" else 0.82)
	var body: Node3D = _joint(self, "Torso", Vector3(0, 1.10, 0))
	_cylinder(body, broad * 0.37, broad * 0.43, 0.68, Vector3(0, 0.14, 0), CERAMIC, 8)
	_block(body, Vector3(broad * 0.67, 0.38, 0.12), Vector3(0, 0.15, -0.32), _team)
	_cylinder(body, broad * 0.38, broad * 0.37, 0.12, Vector3(0, -0.19, 0), COPPER, 10)
	_block(body, Vector3(0.21, 0.16, 0.10), Vector3(0, -0.18, -0.37), COPPER)
	for side: float in [-1.0, 1.0]:
		var leg: Node3D = _joint(self, "LeftLeg" if side < 0 else "RightLeg", Vector3(side * broad * 0.24, 0.78, 0))
		_capsule(leg, 0.13 if key == "rio" else 0.17, 0.56, Vector3(0, -0.24, 0), CLOTH)
		_block(leg, Vector3(0.22, 0.20, 0.16), Vector3(0, -0.30, -0.16), CERAMIC)
		_capsule(leg, 0.17, 0.30, Vector3(0, -0.62, -0.09), CLOTH)
		_block(leg, Vector3(0.32, 0.13, 0.43), Vector3(0, -0.69, -0.09), COPPER)
		var arm: Node3D = _joint(self, "LeftArm" if side < 0 else "RightArm", Vector3(side * broad * 0.51, 1.48, 0))
		_capsule(arm, 0.15, 0.59, Vector3(0, -0.24, 0), CLOTH)
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
	var head: Node3D = _joint(self, "Head", Vector3(0, 1.82, 0))
	_sphere(head, 0.29, Vector3.ZERO, SKIN)
	_cylinder(head, 0.28, 0.32, 0.21, Vector3(0, 0.18, 0.03), CLOTH, 10)
	_block(head, Vector3(0.42, 0.11, 0.12), Vector3(0, 0.12, -0.23), _team)
	for side: float in [-1.0, 1.0]:
		_sphere(head, 0.102, Vector3(side * 0.13, 0.015, -0.25), COPPER)
		_sphere(head, 0.075, Vector3(side * 0.13, 0.015, -0.30), Color("a0e1d7"))
	_block(head, Vector3(0.14, 0.045, 0.045), Vector3(0, -0.16, -0.25), CLOTH)
	if key == "bas":
		var tank: MeshInstance3D = _cylinder(body, 0.23, 0.23, 0.60, Vector3(0, 0.18, 0.38), COPPER, 10)
		tank.rotation_degrees.z = 90
		for x: float in [-0.20, 0.20]:
			_sphere(body, 0.10, Vector3(x, 0.49, 0.37), _team)
	elif key == "rio":
		var cape: Node3D = _joint(self, "Cloth", Vector3(0, 1.50, 0.2))
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
		var cape: Node3D = _joint(self, "Cloth", Vector3(0, 1.25, 0.2))
		_cloth(cape, 0.70, 0.77, CLOTH)

func _gauntlet(arm: Node3D, large: bool) -> void:
	var factor: float = 1.15 if large else 0.88
	var shell: MeshInstance3D = _cylinder(arm, 0.33 * factor, 0.26 * factor, 0.62, Vector3(0, -0.38, -0.16), CERAMIC, 8)
	shell.rotation_degrees.x = 64
	_ring(arm, 0.30 * factor, 0.065, Vector3(0, -0.22, -0.08), COPPER).rotation_degrees.x = 64
	for x: float in [-0.18, 0.0, 0.18]:
		_block(arm, Vector3(0.15, 0.22, 0.16) * factor, Vector3(x * factor, -0.55, -0.48), COPPER)
	_block(arm, Vector3(0.36, 0.12, 0.10) * factor, Vector3(0, -0.26, -0.43), _team)

func pose(unit: Dictionary, time: float) -> void:
	if _parts.is_empty():
		return
	var moving: bool = str(unit.phase) == "walk"
	var stride: float = sin(time * 11.0) * (0.50 if moving else 0.0)
	_parts.LeftLeg.rotation.x = stride
	_parts.RightLeg.rotation.x = -stride
	_parts.LeftArm.rotation.x = -stride * 0.65
	_parts.RightArm.rotation.x = stride * 0.65
	_parts.Torso.rotation = Vector3.ZERO
	_parts.Head.rotation = Vector3.ZERO
	if str(unit.phase) == "basic":
		var progress: float = clampf(1.0 - float(unit.phase_left) / maxf(0.01, float(unit.attack_windup)), 0.0, 1.0)
		_parts.RightArm.rotation.x = -0.5 - progress * 1.1
		_parts.Torso.rotation.y = -0.18 + progress * 0.38
	elif str(unit.phase) in ["windup", "recovery"]:
		_parts.LeftArm.rotation.x = -0.95
		_parts.RightArm.rotation.x = -1.30
		_parts.Torso.rotation.x = 0.09
	elif str(unit.phase) == "dash":
		_parts.Torso.rotation.x = -0.22
		_parts.LeftArm.rotation.x = -1.30
		_parts.RightArm.rotation.x = -1.55
	if float(unit.stun_left) > 0:
		_parts.Head.rotation.z = 0.20
		_parts.LeftArm.rotation.z = -0.15
		_parts.RightArm.rotation.z = 0.15
	else:
		_parts.LeftArm.rotation.z = 0
		_parts.RightArm.rotation.z = 0
	if _parts.has("Cloth"):
		_parts.Cloth.rotation.x = 0.12 + sin(time * 5) * (0.14 if moving else 0.035)

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
