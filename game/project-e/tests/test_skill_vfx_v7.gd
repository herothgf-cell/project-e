extends SceneTree
## Real rendered meshes must differ by slot and stay inside authority geometry.
var checks: int = 0
var failures: int = 0

class CountedBattle extends "res://scripts/battle/battle_state.gd":
	var sight_queries: int = 0
	func is_point_visible_for_sources(team: int, position: Vector2, sources: Array) -> bool:
		sight_queries += 1
		return super.is_point_visible_for_sources(team, position, sources)

class CountedMap extends "res://scripts/battle/battle_map.gd":
	var wall_queries: int = 0
	var height_queries: int = 0
	func has_line_of_sight(start: Vector2, finish: Vector2, radius: float = 0.0) -> bool:
		wall_queries += 1
		return super.has_line_of_sight(start, finish, radius)
	func ground_height(point: Vector2) -> float:
		height_queries += 1
		return super.ground_height(point)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Variant = load("res://scripts/battle/battle_state.gd").new()
	state.reset("nema", true)
	state.bots_enabled = false
	var hero: Dictionary = state.units[state.controlled_id]
	for unit: Dictionary in state.units.values():
		unit.alive = unit.id == hero.id
	hero.pos = Vector2.ZERO
	var view: Variant = load("res://scripts/presentation/skill_vfx.gd").new()
	root.add_child(view)
	await process_frame
	for key: String in ["bas", "rio", "nema"]:
		hero.hero = key
		var meshes: Dictionary = {}
		for slot: String in ["Q", "W", "E", "R"]:
			var effect := {"shape":"circle", "origin":Vector2.ZERO, "target":Vector2(1, 0), "direction":Vector2.RIGHT, "radius":2.0, "width":1.4, "telegraph":false, "owner_id":hero.id, "team":0, "remaining":0.12, "duration":0.22, "slot":slot}
			state.effects = [effect]
			view.refresh(state)
			var faces: PackedVector3Array = view.mesh.get_faces()
			_check(faces.size() > 3, key + slot + " emits visible geometry")
			var signature: int = hash(faces)
			_check(not meshes.has(signature), key + slot + " has a distinct rendered pattern in the same area")
			meshes[signature] = slot
			_check(_inside_circle(faces, Vector2.ZERO, 2.0), key + slot + " keeps complete decorations inside the real area")
	# A small late impact catches glyph corners extending beyond an approved center.
	hero.hero = "bas"
	state.effects = [{"shape":"circle", "origin":Vector2.ZERO, "target":Vector2.ZERO, "radius":0.35, "telegraph":false, "owner_id":hero.id, "team":0, "remaining":0.005, "duration":0.22, "slot":"R"}]
	view.refresh(state)
	_check(_inside_circle(view.mesh.get_faces(), Vector2.ZERO, 0.35), "late decorations clip their complete footprint")
	state.effects[0].origin = Vector2(54, 25)
	state.effects[0].target = Vector2(54, 25)
	view.refresh(state)
	_check(view.rendered_points.is_empty(), "unseen decoration geometry is immediately discarded")
	_check_real_shapes(state, hero, view)
	_check_visibility_cost(view)
	state.effects.clear()
	hero.hero = "nema"
	state.spawn_pin(hero, Vector2(1, 0))
	var pin: Dictionary = state.units[hero.pins[0]]
	var arena: Variant = load("res://scripts/presentation/arena_view.gd").new()
	root.add_child(arena)
	var unit_root: Node3D = arena.create_unit(pin, arena)
	var meshes: Array[Node] = unit_root.get_node("Model").find_children("*", "MeshInstance3D", true, false)
	_check(meshes.size() >= 10, "persistent spirit tree renders a trunk, branches, roots and foliage")
	_check(unit_root.get_node("Footprint").mesh != null and is_equal_approx(pin.radius, 0.35), "spirit tree retains its authoritative target footprint")
	view.queue_free()
	arena.queue_free()
	await process_frame
	print("Skill VFX V7: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check_real_shapes(state: Variant, hero: Dictionary, view: Variant) -> void:
	hero.hero = "rio"
	var corners: Array[Vector2] = [Vector2.ZERO, Vector2(6, 0), Vector2(3, 3)]
	state.effects = [{"shape":"triangle", "origin":Vector2.ZERO, "target":Vector2(6, 0), "points":corners, "width":0.8, "telegraph":false, "owner_id":hero.id, "team":0, "remaining":0.10, "duration":0.22, "slot":"R"}]
	view.refresh(state)
	var inside_edges: bool = true
	for vertex: Vector3 in view.mesh.get_faces():
		var point := Vector2(vertex.x, -vertex.z)
		var distance: float = INF
		for index: int in range(3):
			distance = minf(distance, point.distance_to(Geometry2D.get_closest_point_to_segment(point, corners[index], corners[(index + 1) % 3])))
		inside_edges = inside_edges and distance <= 0.4001
	_check(view.rendered_points.size() > 0 and inside_edges, "Rio constellation occupies the three edge corridors")
	for key: String in ["bas", "rio"]:
		hero.hero = key
		hero.phase = "dash"
		hero.pos = Vector2(0.18, 0)
		hero.facing = Vector2.RIGHT
		hero.cast = {"shape":"line", "origin":Vector2.ZERO, "target":Vector2(4.2, 0), "width":0.9, "slot":"E"}
		state.effects.clear()
		view.refresh(state)
		var in_corridor: bool = true
		for vertex: Vector3 in view.mesh.get_faces():
			in_corridor = in_corridor and vertex.x >= -0.0001 and vertex.x <= 4.2001 and absf(vertex.z) <= 0.4501
		_check(view.rendered_points.size() > 0 and in_corridor, key + " dash decorations stay within the actual swept corridor")
	hero.phase = "idle"
	hero.cast = {}
	hero.hero = "nema"
	hero.pos = Vector2.ZERO
	var effect := {"shape":"circle", "origin":Vector2(0, 3), "target":Vector2(0, 3), "radius":5.0, "telegraph":false, "owner_id":hero.id, "team":0, "remaining":0.10, "duration":0.22, "slot":"W"}
	state.effects = [effect]
	var before: Dictionary = state.units.duplicate(true)
	view.refresh(state)
	_check(view.rendered_points.size() > 0 and _visible_and_clear(state, view, effect.origin), "whole vine cells respect the north wall and current sight")
	_check(state.units == before, "decorative refresh leaves combat authority untouched")
	hero.pos = Vector2(-10, 0)
	state._visibility_cache.clear()
	effect.origin = Vector2(3, 0)
	effect.target = effect.origin
	effect.radius = 2.0
	effect.team = 1
	view.refresh(state)
	_check(view.rendered_points.size() > 0 and _visible_and_clear(state, view, effect.origin), "partly observed enemy vines reveal only currently visible cells")
	hero.pos = Vector2.ZERO
	state._visibility_cache.clear()

func _visible_and_clear(state: Variant, view: Variant, origin: Vector2) -> bool:
	var faces: PackedVector3Array = view.mesh.get_faces()
	for index: int in range(0, faces.size(), 3):
		var a := Vector2(faces[index].x, -faces[index].z)
		var b := Vector2(faces[index + 1].x, -faces[index + 1].z)
		var c := Vector2(faces[index + 2].x, -faces[index + 2].z)
		for u: int in range(5):
			for v: int in range(5 - u):
				var point: Vector2 = a + (b - a) * (float(u) / 4.0) + (c - a) * (float(v) / 4.0)
				if not state.is_point_visible(0, point) or not state.map.has_line_of_sight(origin, point):
					return false
	return true

func _check_visibility_cost(view: Variant) -> void:
	var state := CountedBattle.new()
	state.reset("bas", true)
	state.map = CountedMap.new()
	var hero: Dictionary = state.units[state.controlled_id]
	hero.pos = Vector2.ZERO
	for unit: Dictionary in state.units.values():
		unit.alive = unit.id == hero.id
	var effect: Dictionary = state._abilities.preview(state, hero, "R", Vector2(6, 0))
	effect.merge({"telegraph":false, "remaining":0.10, "duration":0.22}, true)
	state.effects = [effect]
	state.map.wall_queries = 0
	state.map.height_queries = 0
	view.refresh(state)
	_check(view.rendered_points.size() > 0 and state.sight_queries < 8, "a wholly visible impact avoids per-triangle whole-world sight queries")
	_check(state.map.wall_queries < 8 and state.map.height_queries < 8, "an open flat impact avoids per-vertex wall and height scans")
	state.map.blockers.append(Rect2(2.5, -1.5, 0.5, 3.0))
	view.refresh(state)
	_check(view.rendered_points.size() > 0 and _visible_and_clear(state, view, Vector2.ZERO), "changed blockers immediately restore exact visibility and wall checks")
	state.map.blockers.pop_back()
	state.map.high_ground_cells.append(Vector2(3, 0))
	hero.pos = Vector2(3, 0)
	view.refresh(state)
	var elevated: bool = false
	var follows_terrain: bool = true
	for vertex: Vector3 in view.mesh.get_faces():
		var ground: float = state.map.ground_height(Vector2(vertex.x, -vertex.z))
		elevated = elevated or ground > 0.0
		follows_terrain = follows_terrain and vertex.y >= ground + 0.099
	_check(elevated and follows_terrain, "changed raised terrain immediately restores exact vertex heights")
	hero.pos = Vector2(-30, 0)
	view.refresh(state)
	_check(view.rendered_points.is_empty(), "moving the sole observer immediately invalidates visible-area reuse")
	hero.pos = Vector2.ZERO
	hero.alive = false
	view.refresh(state)
	_check(view.rendered_points.is_empty(), "losing the sole observer immediately invalidates visible-area reuse")

func _inside_circle(faces: PackedVector3Array, center: Vector2, radius: float) -> bool:
	for vertex: Vector3 in faces:
		if Vector2(vertex.x, -vertex.z).distance_to(center) > radius + 0.0001:
			return false
	return true

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
