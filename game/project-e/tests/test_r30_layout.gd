extends SceneTree
## R30 spatial contract: each 40 XP plateau has a lane ramp and a shorter support-rotation ramp.

const MapScript = preload("res://scripts/battle/battle_map.gd")

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map: Variant = MapScript.new()
	var has_contract: bool = false
	for property: Dictionary in map.get_property_list():
		if str(property.get("name", "")) == "high_ground_ramps":
			has_contract = true
			break
	_check(has_contract, "map exposes data-driven high-ground ramps")
	_check(map.has_method("ramp_high_edge"), "map exposes the authoritative slope start")
	if not has_contract or not map.has_method("ramp_high_edge"):
		_finish()
		return

	var ramps: Array = map.high_ground_ramps
	_check(ramps.size() == 4, "two high grounds expose one lane ramp and one support ramp each")
	var north := Vector2(-18, 24)
	var south := Vector2(18, -24)
	var north_ramps: Array = map.ramps_for_high_ground(north)
	var south_ramps: Array = map.ramps_for_high_ground(south)
	_check(north_ramps.size() == 2 and south_ramps.size() == 2, "each plateau owns exactly two ramps")

	var north_support: Dictionary = _ramp(north_ramps, "support")
	var south_support: Dictionary = _ramp(south_ramps, "support")
	var north_lane: Dictionary = _ramp(north_ramps, "lane")
	var south_lane: Dictionary = _ramp(south_ramps, "lane")
	_check(not north_support.is_empty() and not south_support.is_empty(), "both plateaus expose support ramps")
	_check(not north_lane.is_empty() and not south_lane.is_empty(), "both original lane ramps remain")
	if north_support.is_empty() or south_support.is_empty() or north_lane.is_empty() or south_lane.is_empty():
		_finish()
		return

	_check(north_support.high == north and north_support.low == Vector2(-12, 18), "northwest support ramp reaches the west-north connector lane")
	_check(south_support.high == south and south_support.low == Vector2(12, -18), "southeast support ramp is the 180-degree mirror")
	_check(north_lane.low == Vector2(-18, 18) and south_lane.low == Vector2(18, -18), "original lane-return endpoints stay unchanged")
	for ramp: Dictionary in ramps:
		_near(float(ramp.width), 3.0, "every high-ground ramp is three metres wide")
		_check(map.is_walkable(ramp.high) and map.is_walkable(ramp.low), "ramp endpoints remain walkable")
		var high_edge: Vector2 = map.ramp_high_edge(ramp)
		var midpoint: Vector2 = high_edge.lerp(ramp.low, 0.5)
		_near(map.ground_height(high_edge), 2.4, "ramp starts at the declared plateau height")
		_near(map.ground_height(midpoint), 1.2, "ramp midpoint interpolates to half height")
		_near(map.ground_height(ramp.low), 0.0, "ramp reaches lane height at the low endpoint")

	var connector_entry := Vector2(-10, 18)
	var route: Array = map.find_path(north, connector_entry)
	_check(not route.is_empty(), "northwest high ground reaches the existing support connector")
	var route_length: float = _path_length(north, route)
	var old_lane_loop: float = north.distance_to(Vector2(-18, 18)) + Vector2(-18, 18).distance_to(connector_entry)
	_check(route_length < old_lane_loop - 1.5, "support ramp shortens high-ground-to-connector rotation")

	var middle: Vector2 = Vector2(north_support.high).lerp(north_support.low, 0.5)
	var direction: Vector2 = (Vector2(north_support.low) - Vector2(north_support.high)).normalized()
	var normal := Vector2(-direction.y, direction.x)
	_check(map.is_walkable(middle + normal * 1.30, 0.15), "support corridor keeps usable interior width")
	_check(not map.is_ground(middle + normal * 2.20), "support corridor does not create undeclared off-ground shortcuts")
	for fraction: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		_check(map.is_walkable(Vector2(north_support.high).lerp(north_support.low, fraction), 0.45), "support centerline avoids tower collision at %.2f" % fraction)

	_finish()


func _ramp(ramps: Array, kind: String) -> Dictionary:
	for ramp: Dictionary in ramps:
		if str(ramp.get("kind", "")) == kind:
			return ramp
	return {}


func _path_length(start: Vector2, path: Array) -> float:
	var result: float = 0.0
	var cursor: Vector2 = start
	for point: Vector2 in path:
		result += cursor.distance_to(point)
		cursor = point
	return result


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.04, "%s: expected %.2f, got %.2f" % [label, expected, actual])


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)


func _finish() -> void:
	print("R30 layout: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
