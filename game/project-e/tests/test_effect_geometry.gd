extends SceneTree
## Inspect actual warning triangles against independently chosen wall fixtures.

var _checks: int = 0
var _failures: int = 0

class CountedMap extends "res://scripts/battle/battle_map.gd":
	var outline_calls: int = 0
	func radial_effect_outline(shape: Dictionary) -> Array[Vector2]:
		outline_calls += 1
		return super.radial_effect_outline(shape)

class CountedBattle extends "res://scripts/battle/battle_state.gd":
	var point_queries: int = 0
	func is_point_visible_for_sources(team: int, position: Vector2, sources: Array) -> bool:
		point_queries += 1
		return super.is_point_visible_for_sources(team, position, sources)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state: Variant = load("res://scripts/battle/battle_state.gd").new()
	state.reset("bas", true)
	state.bots_enabled = false
	var view: MeshInstance3D = load("res://scripts/presentation/effects_view.gd").new()
	root.add_child(view)
	await process_frame
	var circle := {"shape": "circle", "origin": Vector2(0, 3), "radius": 5.0, "team": 0, "valid": true}
	var cone := {"shape": "cone", "origin": Vector2(0, 3), "target": Vector2(0, 9), "radius": 6.0, "angle": 80.0, "team": 0, "valid": true}
	for shape: Dictionary in [circle, cone]:
		view.redraw(state, shape, -1, null)
		_check(_covers(view, Vector2(0, 5.5)), "%s keeps its valid area before the north wall" % shape.shape)
		_check(not _covers(view, Vector2(0, 7)), "%s warning never paints inside/behind the north wall" % shape.shape)
		_check(_all_clear(state, view, shape.origin), "%s fill and outline obey authoritative wall LOS" % shape.shape)
		state.effects = [shape]
		view.redraw(state, {}, -1, null)
		_check(not _covers(view, Vector2(0, 7)) and _all_clear(state, view, shape.origin), "%s active effect uses the same clipping as preview" % shape.shape)
		state.effects.clear()
	var corner := {"shape": "circle", "origin": Vector2(-8, 3), "radius": 8.0, "team": 0, "valid": true}
	view.redraw(state, corner, -1, null)
	_check(_covers(view, Vector2(-5.5, 5.6)), "A wall-corner warning preserves the reachable near side")
	_check(not _covers(view, Vector2(-5, 6.5)), "A wall-corner warning does not bridge across the corner")
	_check(_all_clear(state, view, corner.origin), "Corner fan triangles and strokes remain on the visible side")
	var open_circle := {"shape": "circle", "origin": Vector2.ZERO, "radius": 2.0, "team": 0, "valid": true}
	view.redraw(state, open_circle, -1, null)
	for point: Vector2 in [Vector2(1.5, 0), Vector2(-1.5, 0), Vector2(0, 1.5), Vector2(0, -1.5)]:
		_check(_covers(view, point), "Open circle preserves all four valid quadrants")
	_check(not _covers(view, Vector2(2.5, 0)), "Open circle stays within its original radius")
	_test_radial_visibility_and_cost(view)
	view.queue_free()
	await process_frame
	print("Effect geometry: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_radial_visibility_and_cost(view: MeshInstance3D) -> void:
	var state := CountedBattle.new()
	state.reset("bas", true)
	state.bots_enabled = false
	state.map = CountedMap.new()
	var shape := {"shape": "circle", "origin": Vector2(-15, 0), "radius": 2.2, "team": 1}
	state.effects = [shape]
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() / 3 < 1200, "An ordinary enemy circle avoids thousands of radial strip triangles")
	_check(state.point_queries < 400, "A radial warning does not make thousands of whole-world visibility queries")
	state.point_queries = 0
	state.map.outline_calls = 0
	view.redraw(state, {}, -1, null)
	_check(state.point_queries == 0 and state.map.outline_calls == 0, "Unchanged radial geometry and allied sight reuse their clipped result")
	shape = {"shape": "cone", "origin": Vector2(15, 0), "target": Vector2(9, 0), "radius": 6.0, "angle": 70.0, "team": 1}
	state.effects = [shape]
	state.point_queries = 0
	state.map.outline_calls = 0
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() == 3, "A wholly unseen cone emits only the transparent empty-surface triangle")
	_check(state.point_queries < 10 and state.map.outline_calls == 0, "Out-of-sight warnings are rejected before radial construction")
	var hero: Dictionary = state.units[state.controlled_id]
	var ally: Dictionary = {}
	for unit: Dictionary in state.units.values():
		if unit.team == 0:
			unit.alive = unit.id == hero.id
			if unit.kind == "hero" and unit.id != hero.id:
				ally = unit
	hero.pos = Vector2(-10, 0)
	shape = {"shape": "circle", "origin": Vector2(3, 0), "radius": 2.2, "team": 1}
	state.effects = [shape]
	view.redraw(state, {}, -1, null)
	_check(not state.is_point_visible(0, shape.origin) and _covers(view, Vector2(1, 0)), "An enemy circle's observed near side remains visible when its origin is hidden")
	_check(not _covers(view, Vector2(3, 0)) and _all_visible(state, view), "Partial enemy circle geometry never crosses into unseen space")
	state.effects = [{"shape": "cone", "origin": Vector2(3, 0), "target": Vector2(-3, 0), "radius": 6.0, "angle": 70.0, "team": 1}]
	view.redraw(state, {}, -1, null)
	_check(_covers(view, Vector2(1, 0)) and not _covers(view, Vector2(3, 0)) and _all_visible(state, view), "A hidden-origin enemy cone retains only its observed near-side wedge")
	state.effects = [shape]
	view.redraw(state, {}, -1, null)
	_check(not _covers(view, Vector2(2.05, 0.01)), "Point beyond the current exact sight radius stays hidden")
	hero.pos.x += 0.1
	view.redraw(state, {}, -1, null)
	_check(_covers(view, Vector2(2.05, 0.01)), "Even small source movement invalidates enemy-effect sight immediately")
	ally.alive = true
	ally.pos = Vector2(12, 0)
	view.redraw(state, {}, -1, null)
	_check(_covers(view, Vector2(3, 0)) and _all_visible(state, view), "Overlapping allied sources reveal the shared union without a fog bridge")
	_check(_fill_coverage(view, Vector2(1.31, 0.23)) == 1, "Overlapping source polygons do not draw an enemy warning twice")
	hero.alive = false
	view.redraw(state, {}, -1, null)
	_check(_covers(view, Vector2(3, 0)) and _all_visible(state, view), "A remaining allied source keeps its observed part after another dies")
	ally.alive = false
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() == 3, "Removing the last source immediately hides cached enemy geometry")
	hero.alive = true
	hero.pos = Vector2(-8, 3)
	shape = {"shape": "circle", "origin": Vector2(-4, 4), "radius": 6.0, "team": 1}
	state.effects = [shape]
	view.redraw(state, {}, -1, null)
	_check(_covers(view, Vector2(-5, 5)) and not _covers(view, Vector2(-5, 7)), "Enemy radial warning preserves the wall's near side and hides its far side")
	_check(_all_visible(state, view) and _all_clear(state, view, shape.origin), "Native clipping keeps complete triangles inside both effect LOS and team sight")
	# A large diagnostic polygon forces an enclosed visibility island. Ordinary
	# skills are smaller, but the union must not triangulate across the fog hole.
	state.map.blockers.clear()
	hero.pos = Vector2.ZERO
	ally.alive = true
	ally.pos = Vector2(20, 0)
	state.effects = [{"shape": "circle", "origin": Vector2.ZERO, "radius": 24.0, "team": 1}]
	view.redraw(state, {}, -1, null)
	_check(_covers(view, Vector2(0, 1)) and _covers(view, Vector2(16, 1)), "Disjoint convex clipping retains both visible islands in a large warning")
	_check(not _covers(view, Vector2(-16, 1)) and _all_visible(state, view), "An enclosed sight island never fills the surrounding fog complement")
	_check(_fill_coverage(view, Vector2(10.23, 0.37)) == 1, "Overlapping visibility islands draw shared warning fill exactly once")


func _all_visible(state: Variant, view: MeshInstance3D) -> bool:
	var faces: PackedVector3Array = view.mesh.get_faces()
	for index: int in range(0, faces.size(), 3):
		var a := Vector2(faces[index].x, -faces[index].z)
		var b := Vector2(faces[index + 1].x, -faces[index + 1].z)
		var c := Vector2(faces[index + 2].x, -faces[index + 2].z)
		if absf((b - a).cross(c - a)) < 0.000001:
			continue
		for u: int in range(5):
			for v: int in range(5 - u):
				if not state.is_point_visible(0, a + (b - a) * (float(u) / 4) + (c - a) * (float(v) / 4)):
					print("Unseen triangle sample: ", a + (b - a) * (float(u) / 4) + (c - a) * (float(v) / 4), " from ", a, " / ", b, " / ", c)
					return false
	return true


func _fill_coverage(view: MeshInstance3D, point: Vector2) -> int:
	var count: int = 0
	var faces: PackedVector3Array = view.mesh.get_faces()
	for index: int in range(0, faces.size(), 3):
		if not is_equal_approx(faces[index].y, 0.065):
			continue
		var polygon := PackedVector2Array([Vector2(faces[index].x, -faces[index].z), Vector2(faces[index + 1].x, -faces[index + 1].z), Vector2(faces[index + 2].x, -faces[index + 2].z)])
		if Geometry2D.is_point_in_polygon(point, polygon):
			count += 1
	return count


func _covers(view: MeshInstance3D, point: Vector2) -> bool:
	var faces: PackedVector3Array = view.mesh.get_faces()
	for i: int in range(0, faces.size(), 3):
		var triangle := PackedVector2Array([Vector2(faces[i].x, -faces[i].z), Vector2(faces[i + 1].x, -faces[i + 1].z), Vector2(faces[i + 2].x, -faces[i + 2].z)])
		if absf((triangle[1] - triangle[0]).cross(triangle[2] - triangle[0])) < 0.000001:
			continue
		if Geometry2D.is_point_in_polygon(point, triangle):
			return true
	return false


func _all_clear(state: Variant, view: MeshInstance3D, origin: Vector2) -> bool:
	var faces: PackedVector3Array = view.mesh.get_faces()
	for i: int in range(0, faces.size(), 3):
		var a := Vector2(faces[i].x, -faces[i].z)
		var b := Vector2(faces[i + 1].x, -faces[i + 1].z)
		var c := Vector2(faces[i + 2].x, -faces[i + 2].z)
		if absf((b - a).cross(c - a)) < 0.000001:
			continue
		for point: Vector2 in [a, b, c, (a + b) * 0.5, (b + c) * 0.5, (c + a) * 0.5, (a + b + c) / 3.0]:
			if not state.map.has_line_of_sight(origin, point):
				print("Wall-crossing triangle sample: ", point, " from ", a, " / ", b, " / ", c)
				return false
	return true


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
