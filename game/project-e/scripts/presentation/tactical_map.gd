extends Control

signal point_selected(point: Vector2, button: int)

const DisplayLayout = preload("res://scripts/presentation/battlefield_layout.gd")
const DEFAULT_VISION_TOOLTIP := "팀 공유 시야 · 밝은 고리가 시야 제공원을 나타냅니다.\n고리에 마우스를 올리면 벽에 막히는 실제 시야 범위를 확인할 수 있습니다."

var battle: Variant
var camera: Camera3D
var active: bool = false
var vision_view: Node3D
var _hovered_source: int = -1
var _hover_boundary := PackedVector2Array()
var _hover_source_pos := Vector2(INF, INF)
var _hover_boundary_at: int = 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(124, 192)
	clip_contents = true
	mouse_exited.connect(func() -> void: _update_source_hover(Vector2(INF, INF)))
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tooltip_text = DEFAULT_VISION_TOOLTIP


func _process(_delta: float) -> void:
	_update_source_hover(get_local_mouse_position())


func high_ground_ramp_segments() -> Array:
	var result: Array = []
	if battle == null or battle.map == null:
		return result
	for ramp: Dictionary in battle.map.high_ground_ramps:
		var high: Vector2 = ramp.high
		var low: Vector2 = ramp.low
		result.append({
			"kind": str(ramp.get("kind", "lane")),
			"high": high,
			"low": low,
			"screen_high": to_map(high),
			"screen_low": to_map(low),
		})
	return result


func _update_source_hover(pointer: Vector2) -> void:
	var hovered: int = -1
	if battle != null and vision_view != null and content_rect().has_point(pointer):
		for id: int in vision_view.source_ids():
			if battle.units.has(id) and battle.units[id].alive and (to_map(battle.units[id].pos) + Vector2(0, -6)).distance_to(pointer) < 8:
				hovered = id
				break
	var text: String = vision_view.source_tooltip(hovered) if hovered != -1 else DEFAULT_VISION_TOOLTIP
	if hovered != _hovered_source:
		_hover_source_pos = Vector2(INF, INF)
		_hovered_source = hovered
		queue_redraw()
	if tooltip_text != text:
		tooltip_text = text


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("203f3e"))
	if battle == null:
		return
	var content: Rect2 = content_rect()
	draw_rect(content, Color("2d5b56"))
	var scale_value: float = content.size.x / DisplayLayout.VIEW_SIZE.x
	for path: Array in battle.map.lane_paths:
		for i: int in range(path.size() - 1):
			draw_line(to_map(path[i]), to_map(path[i + 1]), Color("d6d5b9"), 6.0 * scale_value, true)
	for link: Array in battle.map.connectors:
		draw_line(to_map(link[0]), to_map(link[1]), Color("8bba9d"), 4.0 * scale_value, true)
	# R30 ramps are fixed terrain and may be drawn before fog. The warmer support
	# route is distinct from the cream lane-return ramp without exposing cell state.
	for segment: Dictionary in high_ground_ramp_segments():
		var color := Color("c79768") if str(segment.kind) == "support" else Color("cabc92")
		draw_line(segment.screen_high, segment.screen_low, color, 3.0 * scale_value, true)
	for team: int in range(2):
		var center := Vector2(-51.5 if team == 0 else 51.5, 0)
		draw_rect(to_map_rect(Rect2(center - Vector2(7.5, 8), Vector2(15, 16))), Color("9ba993"))
	for blocker: Rect2 in battle.map.blockers:
		draw_rect(to_map_rect(blocker), Color("376e64"))
	# High ground is static terrain knowledge; fog may dim it, but it is never a
	# hidden enemy-state reveal. Double chevrons distinguish it from XP circles.
	for center: Vector2 in battle.map.high_ground_cells:
		var high: Vector2 = to_map(center)
		var r: float = 5.2 * scale_value
		draw_arc(high, r, 0, TAU, 20, Color("d7c58f"), 1.4, true)
		draw_line(high + Vector2(-r * 0.55, r * 0.15), high + Vector2(0, -r * 0.45), Color("f1dfad"), 1.2, true)
		draw_line(high + Vector2(0, -r * 0.45), high + Vector2(r * 0.55, r * 0.15), Color("f1dfad"), 1.2, true)
	if vision_view != null and vision_view.minimap_fog_texture != null:
		# Texture x/y are authoritative east/north. Apply the same view basis
		# as terrain and icons, preserving pixel alignment and uniform scale.
		draw_set_transform_matrix(fog_transform())
		draw_texture_rect(vision_view.minimap_fog_texture, Rect2(Vector2.ZERO, DisplayLayout.SIM_RECT.size), false)
		draw_set_transform(Vector2.ZERO)
	_draw_hover_range()
	for id: int in visible_unit_ids():
		var unit: Dictionary = battle.units[id]
		var point: Vector2 = to_map(unit.pos)
		var color := Color("82d8f8") if int(unit.team) == 0 else Color("f6a1d2")
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
	if vision_view != null:
		for id: int in vision_view.source_ids():
			if battle.units.has(id):
				var source: Vector2 = to_map(battle.units[id].pos) + Vector2(0, -6)
				draw_arc(source, 2.0, 0, TAU, 12, Color("c3f4e3"), 1.0, true)
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
	draw_rect(content.grow(-1), Color("76978b"), false, 1)


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
	if event is InputEventMouseMotion:
		_update_source_hover(event.position)
	if event is InputEventMouseButton:
		accept_event()
		if active and event.pressed and event.position.is_finite() and content_rect().has_point(event.position) and event.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
			point_selected.emit(from_map(event.position), event.button_index)


func content_rect() -> Rect2:
	var scale_value: float = maxf(0.0, minf(size.x / DisplayLayout.VIEW_SIZE.x, size.y / DisplayLayout.VIEW_SIZE.y))
	var extent: Vector2 = DisplayLayout.VIEW_SIZE * scale_value
	return Rect2((size - extent) * 0.5, extent)


func to_map(point: Vector2) -> Vector2:
	var content: Rect2 = content_rect()
	var view: Vector2 = DisplayLayout.to_view(point)
	return content.get_center() + Vector2(view.x, -view.y) * (content.size.x / DisplayLayout.VIEW_SIZE.x)


func from_map(point: Vector2) -> Vector2:
	var content: Rect2 = content_rect()
	if not point.is_finite() or content.size.x <= 0.0:
		return Vector2(INF, INF)
	var view: Vector2 = (point - content.get_center()) * (DisplayLayout.VIEW_SIZE.x / content.size.x)
	return DisplayLayout.from_view(Vector2(view.x, -view.y))


func to_map_rect(rectangle: Rect2) -> Rect2:
	var first: Vector2 = to_map(rectangle.position)
	return Rect2(first, to_map(rectangle.end) - first).abs()


func fog_transform() -> Transform2D:
	var content: Rect2 = content_rect()
	var scale_value: float = content.size.x / DisplayLayout.VIEW_SIZE.x
	return Transform2D(Vector2(0, -scale_value), Vector2(-scale_value, 0), content.end)


func vision_at(point: Vector2) -> float:
	if vision_view != null:
		return vision_view.mask_visibility_at(point)
	return 1.0 if battle != null and battle.is_point_visible(0, point) else 0.0


func _draw_hover_range() -> void:
	if vision_view == null or _hovered_source not in vision_view.source_ids() or not battle.units.has(_hovered_source):
		return
	var unit: Dictionary = battle.units[_hovered_source]
	if _hover_source_pos == Vector2(INF, INF) or (_hover_source_pos.distance_squared_to(unit.pos) > 0.01 and Time.get_ticks_msec() - _hover_boundary_at >= 250):
		_hover_boundary = vision_view.source_boundary(_hovered_source)
		_hover_source_pos = unit.pos
		_hover_boundary_at = Time.get_ticks_msec()
	for index: int in range(_hover_boundary.size()):
		draw_line(to_map(_hover_boundary[index]), to_map(_hover_boundary[(index + 1) % _hover_boundary.size()]), Color("c3f4e3"), 1, true)
	if unit.kind == "tower":
		for index: int in range(32):
			if index % 2 == 1:
				continue
			var a: float = TAU * index / 32.0
			var b: float = TAU * (index + 1) / 32.0
			draw_line(to_map(unit.pos + Vector2(cos(a), sin(a)) * float(unit.attack_range)), to_map(unit.pos + Vector2(cos(b), sin(b)) * float(unit.attack_range)), Color("efb370"), 1, true)
