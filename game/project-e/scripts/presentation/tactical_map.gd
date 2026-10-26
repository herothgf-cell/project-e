extends Control

signal point_selected(point: Vector2, button: int)

var battle: Variant
var camera: Camera3D
var active: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(230, 148)
	clip_contents = true


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("204e4e"))
	if battle == null:
		return
	var scale_value: float = size.x / 124.0
	for path: Array in battle.map.lane_paths:
		for i: int in range(path.size() - 1):
			draw_line(to_map(path[i]), to_map(path[i + 1]), Color("9ba993"), 6.0 * scale_value, true)
	for link: Array in battle.map.connectors:
		draw_line(to_map(link[0]), to_map(link[1]), Color("7f9988"), 4.0 * scale_value, true)
	for team: int in range(2):
		var center := Vector2(-51.5 if team == 0 else 51.5, 0)
		draw_rect(Rect2(to_map(center) - Vector2(7.5, 8) * scale_value, Vector2(15, 16) * scale_value), Color("9ba993"))
	for blocker: Rect2 in battle.map.blockers:
		var top_left: Vector2 = to_map(Vector2(blocker.position.x, blocker.end.y))
		draw_rect(Rect2(top_left, blocker.size * scale_value), Color("406e65"))
	for id: int in visible_unit_ids():
		var unit: Dictionary = battle.units[id]
		var point: Vector2 = to_map(unit.pos)
		var color := Color("64ead8") if int(unit.team) == 0 else Color("ffa26b")
		match str(unit.kind):
			"hero":
				draw_circle(point, 4.1, color)
				draw_circle(point, 1.5, Color("183e41"))
				if id == battle.controlled_id:
					draw_arc(point, 6.0, 0, TAU, 20, Color("fff6d6"), 1.5, true)
			"tower":
				draw_rect(Rect2(point - Vector2(2.7, 2.7), Vector2(5.4, 5.4)), color)
			"core":
				draw_colored_polygon(PackedVector2Array([point + Vector2(0, -5), point + Vector2(5, 0), point + Vector2(0, 5), point + Vector2(-5, 0)]), color)
			"cell":
				draw_circle(point, 2.2, Color("eaca79"))
			"pin":
				draw_line(point - Vector2(0, 2), point + Vector2(0, 2), color, 1.5)
			_:
				draw_circle(point, 1.6, color)
	if camera != null:
		var viewport_size: Vector2 = get_viewport_rect().size
		var corners: Array[Vector2] = []
		for screen: Vector2 in [Vector2(0, 0), Vector2(viewport_size.x, 0), viewport_size, Vector2(0, viewport_size.y)]:
			var point: Variant = Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
			if point is Vector3:
				corners.append(to_map(Vector2(point.x, -point.z)))
		if corners.size() == 4:
			for i: int in range(4):
				draw_line(corners[i], corners[(i + 1) % 4], Color(1, 0.96, 0.78, 0.65), 1.0, true)
	draw_rect(Rect2(Vector2.ONE, size - Vector2.ONE * 2), Color("76978b"), false, 1)


func visible_unit_ids() -> Array:
	var result: Array = []
	if battle == null:
		return result
	for id: int in battle.units:
		var unit: Dictionary = battle.units[id]
		# Objective locations and destruction are public; the map never reads enemy HP.
		if unit.alive and (int(unit.team) == 0 or unit.kind in ["tower", "core"] or battle.is_visible(0, id)):
			result.append(id)
	return result


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		accept_event()
		if active and event.pressed and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			point_selected.emit(from_map(event.position), event.button_index)


func to_map(point: Vector2) -> Vector2:
	return Vector2((point.x + 62) / 124.0 * size.x, (40 - point.y) / 80.0 * size.y)


func from_map(point: Vector2) -> Vector2:
	return Vector2(point.x / size.x * 124.0 - 62.0, 40.0 - point.y / size.y * 80.0)
