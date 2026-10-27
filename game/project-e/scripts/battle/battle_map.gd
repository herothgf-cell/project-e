extends RefCounted
## M01 geometry. Simulation coordinates are x/east, y/north; presentation uses -z.

var lane_paths: Array = [
	[Vector2(-50, 0), Vector2(-26, 18), Vector2(26, 18), Vector2(50, 0)],
	[Vector2(-50, 0), Vector2(50, 0)],
	[Vector2(-50, 0), Vector2(-26, -18), Vector2(26, -18), Vector2(50, 0)],
]
var connectors: Array = [
	[Vector2(-22, 0), Vector2(-10, 18)], [Vector2(22, 0), Vector2(10, 18)],
	[Vector2(-22, 0), Vector2(-10, -18)], [Vector2(22, 0), Vector2(10, -18)],
]
var blockers: Array[Rect2] = [
	Rect2(-6, 6, 12, 6), Rect2(-6, -12, 12, 6),
	Rect2(-28, 9, 6, 3), Rect2(22, -12, 6, 3),
	Rect2(-28, -12, 6, 3), Rect2(22, 9, 6, 3),
]
var spawn_points: Array[Vector2] = [Vector2(-56, 0), Vector2(56, 0)]
var core_positions: Array[Vector2] = [Vector2(-50, 0), Vector2(50, 0)]
var cell_positions: Array[Vector2] = [Vector2(-18, 24), Vector2(18, 24), Vector2(-24, 6), Vector2(24, -6), Vector2(-18, -24), Vector2(18, -24)]
var tower_specs: Array = []
var structure_circles: Array = []
var _grid: AStarGrid2D


func _init() -> void:
	for team: int in range(2):
		var sign_x: float = -1.0 if team == 0 else 1.0
		for lane: int in range(3):
			for subtype: String in ["outer", "inner"]:
				var inner: bool = subtype == "inner"
				var x: float = (30.0 if lane == 1 else 26.0) if inner else 10.0
				var y: float = (21.5 if lane == 0 else -21.5) if lane != 1 else sign_x * 3.5
				var point: Vector2 = Vector2(sign_x * x, y)
				tower_specs.append({"team": team, "lane": lane, "subtype": subtype, "pos": point})
				structure_circles.append({"pos": point, "radius": 1.0})
		structure_circles.append({"pos": core_positions[team], "radius": 2.0})
	_build_grid()


func _ground(point: Vector2, margin: float = 0.0) -> bool:
	if not point.is_finite() or absf(point.x) > 59.0 - margin or absf(point.y) > 39.0 - margin:
		return false
	for wall: Rect2 in blockers:
		if wall.grow(margin).has_point(point):
			return false
	if Rect2(-59, -8, 15, 16).grow(-margin).has_point(point) or Rect2(44, -8, 15, 16).grow(-margin).has_point(point):
		return true
	for path: Array in lane_paths:
		for index: int in range(path.size() - 1):
			if segment_distance(point, path[index], path[index + 1]) <= 3.0 - margin:
				return true
	for pair: Array in connectors:
		if segment_distance(point, pair[0], pair[1]) <= 2.0 - margin:
			return true
	for center_y: float in [18.0, 0.0, -18.0]:
		if Rect2(-6, center_y - 4.5, 12, 9).grow(-margin).has_point(point):
			return true
	for spec: Dictionary in tower_specs:
		if point.distance_to(spec.pos) <= 3.0 - margin:
			return true
	for center: Vector2 in cell_positions:
		if point.distance_to(center) <= 2.2 - margin:
			return true
		var lane_y: float = 0.0 if absf(center.y) < 10.0 else 18.0 * signf(center.y)
		if segment_distance(point, center, Vector2(center.x, lane_y)) <= 1.5 - margin:
			return true
	return false


func is_walkable(point: Vector2, radius: float = 0.45) -> bool:
	if not _ground(point, radius):
		return false
	for structure: Dictionary in structure_circles:
		if point.distance_to(structure.pos) < structure.radius + radius - 0.001:
			return false
	return true


func is_ground(point: Vector2) -> bool:
	return _ground(point)


func has_line_of_sight(start: Vector2, finish: Vector2, radius: float = 0.0) -> bool:
	if not start.is_finite() or not finish.is_finite():
		return false
	for wall: Rect2 in blockers:
		var grown: Rect2 = wall.grow(radius)
		if grown.has_point(start) or grown.has_point(finish):
			return false
		var corners: Array[Vector2] = [grown.position, grown.position + Vector2(grown.size.x, 0), grown.end, grown.position + Vector2(0, grown.size.y)]
		for index: int in range(4):
			if Geometry2D.segment_intersects_segment(start, finish, corners[index], corners[(index + 1) % 4]) != null:
				return false
	return true


func clear_walk(start: Vector2, finish: Vector2, radius: float = 0.45) -> bool:
	var count: int = maxi(1, int(ceil(start.distance_to(finish) / 0.18)))
	for index: int in range(count + 1):
		if not is_walkable(start.lerp(finish, float(index) / count), radius):
			return false
	return true


func clip_walk(start: Vector2, finish: Vector2, radius: float = 0.45) -> Vector2:
	var count: int = maxi(1, int(ceil(start.distance_to(finish) / 0.08)))
	var result: Vector2 = start
	for index: int in range(1, count + 1):
		var point: Vector2 = start.lerp(finish, float(index) / count)
		if not is_walkable(point, radius):
			break
		result = point
	return result


func clip_wall(start: Vector2, finish: Vector2, radius: float = 0.0) -> Vector2:
	var count: int = maxi(1, int(ceil(start.distance_to(finish) / 0.08)))
	var result: Vector2 = start
	for index: int in range(1, count + 1):
		var point: Vector2 = start.lerp(finish, float(index) / count)
		if not has_line_of_sight(start, point, radius):
			break
		result = point
	return result


func radial_effect_outline(shape: Dictionary) -> Array[Vector2]:
	# The same wall segments that reject authoritative effects bound their warning.
	# Corner rays preserve a wall's silhouette between regular circular samples.
	var result: Array[Vector2] = []
	var origin: Vector2 = shape.get("origin", Vector2.ZERO)
	var radius: float = float(shape.get("radius", 0.0))
	if not origin.is_finite() or not is_finite(radius) or radius <= 0.0 or not has_line_of_sight(origin, origin):
		return result
	var cone: bool = str(shape.get("shape", "circle")) == "cone"
	var sweep: float = deg_to_rad(clampf(float(shape.get("angle", 80.0)), 0.01, 360.0)) if cone else TAU
	var direction: Vector2 = shape.get("target", origin + Vector2.RIGHT) - origin
	if direction.length_squared() < 0.00001:
		direction = Vector2.RIGHT
	var start: float = direction.angle() - sweep * 0.5 if cone else 0.0
	var angles: Array[float] = []
	var count: int = maxi(2, ceili(sweep / (TAU / 96.0)))
	for i: int in range(count + 1):
		angles.append(sweep * float(i) / count)
	for wall: Rect2 in blockers:
		for corner: Vector2 in [wall.position, wall.position + Vector2(wall.size.x, 0), wall.end, wall.position + Vector2(0, wall.size.y)]:
			var angle: float = fposmod((corner - origin).angle() - start, TAU)
			if angle > sweep:
				continue
			for offset: float in [-0.00005, 0.0, 0.00005]:
				angles.append(clampf(angle + offset, 0.0, sweep))
	angles.sort()
	var previous: float = -1.0
	for angle: float in angles:
		if absf(angle - previous) < 0.000001:
			continue
		previous = angle
		var endpoint: Vector2 = origin + Vector2.from_angle(start + angle) * radius
		var nearest: float = radius
		var blocked: bool = false
		for wall: Rect2 in blockers:
			var corners: Array[Vector2] = [wall.position, wall.position + Vector2(wall.size.x, 0), wall.end, wall.position + Vector2(0, wall.size.y)]
			for index: int in range(4):
				var hit: Variant = Geometry2D.segment_intersects_segment(origin, endpoint, corners[index], corners[(index + 1) % 4])
				if hit is Vector2 and origin.distance_to(hit) <= nearest:
					nearest = origin.distance_to(hit)
					blocked = true
		result.append(origin + Vector2.from_angle(start + angle) * maxf(0.0, nearest - (0.012 if blocked else 0.0)))
	return result


func _build_grid() -> void:
	_grid = AStarGrid2D.new()
	_grid.region = Rect2i(-59, -38, 119, 77)
	_grid.cell_size = Vector2.ONE
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()
	for x: int in range(-59, 60):
		for y: int in range(-38, 39):
			_grid.set_point_solid(Vector2i(x, y), not is_walkable(Vector2(x, y), 0.58))


func _grid_point(point: Vector2) -> Vector2i:
	var base: Vector2i = Vector2i(point.round())
	var best: Vector2i = Vector2i(999, 999)
	var distance: float = INF
	for x: int in range(-3, 4):
		for y: int in range(-3, 4):
			var candidate: Vector2i = base + Vector2i(x, y)
			if _grid.is_in_boundsv(candidate) and not _grid.is_point_solid(candidate):
				var score: float = point.distance_squared_to(Vector2(candidate))
				if score < distance and clear_walk(point, Vector2(candidate)):
					best = candidate
					distance = score
	return best


func find_path(start: Vector2, finish: Vector2) -> Array:
	if not is_walkable(start) or not is_walkable(finish):
		return []
	if clear_walk(start, finish):
		return [finish]
	var first: Vector2i = _grid_point(start)
	var last: Vector2i = _grid_point(finish)
	if first.x == 999 or last.x == 999:
		return []
	var raw: PackedVector2Array = _grid.get_point_path(first, last)
	if raw.is_empty():
		return []
	var path: Array = []
	for point: Vector2 in raw:
		path.append(point)
	path.append(finish)
	var output: Array = []
	var cursor: Vector2 = start
	var index: int = 0
	while index < path.size():
		var furthest: int = index
		for next: int in range(index, path.size()):
			if clear_walk(cursor, path[next]):
				furthest = next
			else:
				break
		if not clear_walk(cursor, path[furthest]):
			return []
		output.append(path[furthest])
		cursor = path[furthest]
		index = furthest + 1
	return output


func lane_point(lane: int, distance: float, team: int = 0) -> Vector2:
	var path: Array = lane_paths[clampi(lane, 0, 2)].duplicate()
	if team == 1:
		path.reverse()
	var left: float = maxf(0.0, distance)
	for index: int in range(path.size() - 1):
		var length: float = path[index].distance_to(path[index + 1])
		if left <= length:
			return path[index].lerp(path[index + 1], left / length)
		left -= length
	return path.back()


static func segment_distance(point: Vector2, start: Vector2, finish: Vector2) -> float:
	return point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, finish))
