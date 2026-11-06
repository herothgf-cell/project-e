extends SceneTree
## Validate imported art and articulation without running another full match.
const HEROES := ["bas", "rio", "nema"]
const JOINTS := ["LeftLeg/Shin", "RightLeg/RightShin", "LeftArm/LeftWeapon", "RightArm/WeaponDetail"]
var checks: int = 0
var failures: int = 0

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	for key: String in HEROES:
		_check_asset("res://assets/heroes/%s.glb" % key, true)
		_check(_texture_valid(load("res://assets/portraits/%s.webp" % key)), key + " portrait decodes")
	for key: String in ["jade_willow", "amber_fig", "ivy_cloister", "copper_millwheel", "garden_bank", "guild_mosaic", "quay_rail", "terracotta_gatehouse", "crown_crystal", "core_observatory", "sentinel_crown"]:
		_check_asset("res://assets/environment/%s.glb" % key, false)
	for key: String in ["canal_flagstones", "canal_waterbed"]:
		_check(_texture_valid(load("res://assets/environment/%s.webp" % key)), key + " illustration decodes")
	for key: String in HEROES:
		_check_rig(key)
	print("Illustrated V5: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check_asset(path: String, hero: bool) -> void:
	var packed := load(path) as PackedScene
	_check(packed != null, path + " imports as a scene")
	if packed == null: return
	var art := packed.instantiate()
	var meshes := art.find_children("*", "MeshInstance3D", true, false)
	var geometry_valid: bool = not meshes.is_empty()
	var paint_valid: bool = true
	var painted_surfaces: int = 0
	for node: MeshInstance3D in meshes:
		if node.mesh == null or node.mesh.get_surface_count() == 0:
			geometry_valid = false
			continue
		for surface: int in node.mesh.get_surface_count():
			var arrays: Array = node.mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			geometry_valid = geometry_valid and vertices.size() >= 3 and node.mesh.get_aabb().size.length() > 0.01
			for vertex: Vector3 in vertices:
				geometry_valid = geometry_valid and vertex.is_finite()
			for index: int in indices:
				geometry_valid = geometry_valid and index >= 0 and index < vertices.size()
			var material := node.mesh.surface_get_material(surface) as StandardMaterial3D
			if material != null and material.albedo_texture != null:
				painted_surfaces += 1
				var uv: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
				paint_valid = paint_valid and uv.size() == vertices.size() and _texture_valid(material.albedo_texture)
	_check(geometry_valid, path + " has finite, nonempty geometry with valid indices")
	_check(paint_valid and (not hero or painted_surfaces >= 2), path + " painted surfaces have UVs and decoded pigment")
	art.free()

func _check_rig(key: String) -> void:
	var rig: Node3D = load("res://scripts/presentation/hero_rig.gd").new()
	root.add_child(rig)
	rig.build(key, Color.CYAN)
	var unit := {"alive": true, "phase": "walk", "cast": {}, "phase_left": 0.0, "attack_windup": 0.4, "last_damage": -100.0, "stun_left": 0.0}
	var authority: Dictionary = unit.duplicate(true)
	rig.pose(unit, 1.18)
	var rest: Dictionary = {}
	for part: Node3D in rig.find_children("*", "Node3D", true, false):
		rest[rig.get_path_to(part)] = part.transform
	for path: String in JOINTS:
		var joint := rig.get_node_or_null(path) as Node3D
		_check(joint != null, key + " articulated joint exists: " + path)
		if joint == null: continue
		rig.pose(unit, 1.18)
		var before := _geometry_points(joint)
		rig.pose(unit, 1.54)
		var after := _geometry_points(joint)
		var displacement: float = 0.0
		for i: int in mini(before.size(), after.size()):
			displacement = maxf(displacement, before[i].distance_to(after[i]))
		_check(not before.is_empty() and displacement > 0.001, key + " distal geometry moves relative to parent: " + path)
	_check(unit == authority, key + " articulated pose leaves authority unchanged")
	unit.phase = "basic"
	unit.phase_left = 0.2
	rig.pose(unit, 1.7)
	unit.phase = "walk"
	unit.phase_left = 0.0
	var repeatable: bool = true
	for repeat: int in 2:
		rig.pose(unit, 1.18)
		for path: NodePath in rest:
			repeatable = repeatable and rig.get_node(path).transform.is_equal_approx(rest[path])
	_check(repeatable, key + " pose resets every joint after an attack and repeated sampling")
	var painted: int = 0
	var bound: bool = true
	for mesh: MeshInstance3D in rig.find_children("*", "MeshInstance3D", true, false):
		var source := mesh.mesh.surface_get_material(0) as StandardMaterial3D
		if source != null and source.albedo_texture != null:
			painted += 1
			var shader := mesh.material_override as ShaderMaterial
			bound = bound and shader != null and shader.get_shader_parameter("textured") == true and shader.get_shader_parameter("pigment") == source.albedo_texture
	_check(painted >= 2 and bound, key + " runtime shader preserves imported painted textures")
	rig.free()

func _geometry_points(joint: Node3D) -> PackedVector3Array:
	var meshes: Array[Node] = joint.find_children("*", "MeshInstance3D", true, false)
	if joint is MeshInstance3D: meshes.append(joint)
	var points := PackedVector3Array()
	for mesh: MeshInstance3D in meshes:
		var relative: Transform3D = joint.get_parent().global_transform.affine_inverse() * mesh.global_transform
		for corner: int in 8:
			points.append(relative * mesh.get_aabb().get_endpoint(corner))
	return points

func _texture_valid(resource: Resource) -> bool:
	var texture := resource as Texture2D
	if texture == null: return false
	var decoded := texture.get_image()
	return decoded != null and not decoded.is_empty() and decoded.get_width() > 1 and decoded.get_height() > 1

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
