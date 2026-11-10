extends RefCounted
## The north-south display is a rigid basis change, not a second game map.
## Authority x remains lane progress and y remains lateral position.

const SIM_RECT := Rect2(-62, -40, 124, 80)
const VIEW_SIZE := Vector2(80, 124)
const LANE_LABELS: Array[String] = ["L", "C", "R"]


static func to_view(point: Vector2) -> Vector2:
	# Display east/north: lane 0 is left, team 0 is at the bottom.
	return Vector2(-point.y, point.x)


static func from_view(point: Vector2) -> Vector2:
	return Vector2(point.y, -point.x)


static func screen_axis_to_sim(axis: Vector2) -> Vector2:
	return from_view(Vector2(axis.x, -axis.y))


static func camera_offset(height: float, distance: float) -> Vector3:
	return Vector3(-distance, height, 0)
