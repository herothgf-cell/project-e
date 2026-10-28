extends Node3D
## Presentation only: current shared sight at 1m. Motion resamples at most 4Hz;
## source membership changes refresh immediately.
## No explored memory; enemy icons, cells and devices never become observers.

const ArenaScript = preload("res://scripts/presentation/arena_view.gd")
const OverlayScript = preload("res://scripts/presentation/unit_overlay.gd")
const MASK_SIZE := Vector2i(124, 80)
const MAP_RECT := Rect2(-62, -40, 124, 80)
const REFRESH_SECONDS := 0.25
const CONTOUR_STEPS := 128
const VISION_COLOR := Color("c3f4e3")
const ATTACK_COLOR := Color("efb370")

var battle: RefCounted
var mask_texture: ImageTexture
var minimap_fog_texture: ImageTexture
var refresh_count: int = 0
var last_refresh_usec: int = 0
var hovered_source_id: int = -1
var _mask: Image
var _fog: Image
var _team: int = 0
var _force_refresh: bool = true
var _elapsed: float = REFRESH_SECONDS
var _sampled_sources: Dictionary = {}
var _sources: Dictionary = {}
var _markers: Dictionary = {}
var _marker_root: Node3D
var _contour: MeshInstance3D
var _source_overlay: Control
var _marker_camera: Camera3D
var _tooltip: PanelContainer
var _tooltip_label: Label
var _boundary_id: int = -1
var _boundary_pos := Vector2(INF, INF)
var _boundary := PackedVector2Array()


func configure(state: RefCounted) -> void:
	battle = state
	if _marker_root == null:
		_marker_root = Node3D.new()
		_marker_root.name = "Sources"
		add_child(_marker_root)
		_contour = MeshInstance3D.new()
		_contour.name = "HoveredVisionRange"
		_contour.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_contour)
		var layer := CanvasLayer.new()
		layer.layer = 5
		add_child(layer)
		_source_overlay = Control.new()
		_source_overlay.name = "SourceBadges"
		_source_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_source_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_source_overlay.draw.connect(_draw_source_markers)
		layer.add_child(_source_overlay)
		_tooltip = PanelContainer.new()
		_tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_tooltip.visible = false
		layer.add_child(_tooltip)
		_tooltip_label = Label.new()
		_tooltip_label.add_theme_font_override("font", preload("res://assets/fonts/ProjectEKorean.woff2"))
		_tooltip_label.add_theme_font_size_override("font_size", 13)
		_tooltip_label.add_theme_color_override("font_color", Color("e5fff4"))
		_tooltip.add_child(_tooltip_label)
	_mask = Image.create(MASK_SIZE.x, MASK_SIZE.y, false, Image.FORMAT_RGBA8)
	_fog = Image.create(MASK_SIZE.x, MASK_SIZE.y, false, Image.FORMAT_RGBA8)
	_mask.fill(Color.BLACK)
	_fog.fill(Color(0.10, 0.14, 0.15, 0.67))
	_sampled_sources.clear()
	_force_refresh = true
	update_view(null, _team, REFRESH_SECONDS, false)
	if get_parent() != null:
		var arena: Node = get_parent().get_node_or_null("Arena")
		if arena != null and arena.has_method("set_vision_texture"):
			arena.set_vision_texture(mask_texture)


func update_view(camera: Camera3D, team: int, delta: float, hover_enabled: bool) -> void:
	if battle == null:
		return
	_elapsed += maxf(0, delta)
	_sources.clear()
	for id: int in battle.units:
		var unit: Dictionary = battle.units[id]
		if int(unit.team) == team and unit.alive and unit.kind in ["hero", "minion", "tower", "core"]:
			_sources[id] = unit.pos
	var membership_changed: bool = _force_refresh or team != _team or _sources.size() != _sampled_sources.size()
	var moved: bool = membership_changed
	for id: int in _sources:
		if not _sampled_sources.has(id):
			membership_changed = true
			moved = true
		elif Vector2(_sources[id]).distance_squared_to(_sampled_sources[id]) > 0.01:
			moved = true
	_team = team
	if membership_changed or (moved and _elapsed >= REFRESH_SECONDS):
		_refresh_mask()
	_sync_markers()
	_marker_camera = camera
	_source_overlay.queue_redraw()
	_update_hover(camera, hover_enabled)


func _refresh_mask() -> void:
	var started: int = Time.get_ticks_usec()
	_mask.fill(Color.BLACK)
	_fog.fill(Color(0.10, 0.14, 0.15, 0.67))
	# Mark only source bounds. This avoids 9,920 authority calls when most of the
	# map is unseen; overlapping sources still use one shared predicate per texel.
	var candidates: Array = []
	candidates.resize(MASK_SIZE.x * MASK_SIZE.y)
	for id: int in _sources:
		var unit: Dictionary = battle.units[id]
		var radius: float = 8.0 if unit.kind == "minion" else 12.0
		var p: Vector2 = unit.pos - MAP_RECT.position
		for y: int in range(maxi(0, floori(p.y - radius)), mini(MASK_SIZE.y, ceili(p.y + radius))):
			for x: int in range(maxi(0, floori(p.x - radius)), mini(MASK_SIZE.x, ceili(p.x + radius))):
				if Vector2(x + 0.5, y + 0.5).distance_squared_to(p) <= radius * radius:
					var pixel: int = y * MASK_SIZE.x + x
					if candidates[pixel] == null:
						candidates[pixel] = []
					candidates[pixel].append(unit)
	for y: int in range(MASK_SIZE.y):
		for x: int in range(MASK_SIZE.x):
			if candidates[y * MASK_SIZE.x + x] == null:
				continue
			var point := MAP_RECT.position + Vector2(x + 0.5, y + 0.5)
			# Spatial filtering only removes observers whose real radius cannot reach
			# this point. Use the authority script itself for all radius / wall checks.
			if battle.is_point_visible_for_sources(_team, point, candidates[y * MASK_SIZE.x + x]):
				_mask.set_pixel(x, y, Color.WHITE)
				_fog.set_pixel(x, y, Color.TRANSPARENT)
	if mask_texture == null:
		mask_texture = ImageTexture.create_from_image(_mask)
		minimap_fog_texture = ImageTexture.create_from_image(_fog)
	else:
		mask_texture.update(_mask)
		minimap_fog_texture.update(_fog)
	_force_refresh = false
	_sampled_sources = _sources.duplicate()
	_elapsed = 0
	refresh_count += 1
	last_refresh_usec = Time.get_ticks_usec() - started


func mask_visibility_at(point: Vector2) -> float:
	if _mask == null or not MAP_RECT.has_point(point):
		return 0
	var pixel := Vector2i((point - MAP_RECT.position).floor())
	return _mask.get_pixel(pixel.x, pixel.y).r


func source_ids() -> Array:
	return _sources.keys()


func source_tooltip(id: int) -> String:
	if not _sources.has(id) or not battle.units.has(id):
		return ""
	var unit: Dictionary = battle.units[id]
	var radius: int = 8 if unit.kind == "minion" else 12
	var names: Dictionary = {"hero": "영웅", "minion": "병력", "tower": "포탑", "core": "코어"}
	var text := "팀 공유 시야 · %s\n밝은 실선: %dm 시야 · 벽에 막힘" % [names.get(str(unit.kind), "시야 제공원"), radius]
	if unit.kind == "tower":
		text += "\n황색 점선: %.1fm 공격 사거리" % float(unit.attack_range)
	return text


func source_boundary(id: int) -> PackedVector2Array:
	if not _sources.has(id):
		return PackedVector2Array()
	var unit: Dictionary = battle.units[id]
	var radius: float = 8.0 if unit.kind == "minion" else 12.0
	var points := PackedVector2Array()
	for index: int in range(CONTOUR_STEPS):
		var angle: float = TAU * index / CONTOUR_STEPS
		var end: Vector2 = unit.pos + Vector2(cos(angle), sin(angle)) * radius
		if not battle.map.has_line_of_sight(unit.pos, end):
			var near_value: float = 0
			var far_value: float = 1
			for _step: int in range(12):
				var mid: float = (near_value + far_value) * 0.5
				if battle.map.has_line_of_sight(unit.pos, unit.pos.lerp(end, mid)):
					near_value = mid
				else:
					far_value = mid
			end = unit.pos.lerp(end, near_value)
		points.append(end)
	return points


func _sync_markers() -> void:
	for id: int in _markers.keys():
		if not _sources.has(id):
			_marker_root.remove_child(_markers[id])
			_markers[id].queue_free()
			_markers.erase(id)
	for id: int in _sources:
		var unit: Dictionary = battle.units[id]
		if not _markers.has(id):
			# World anchors retain source identity; the visible eye is a fixed-pixel
			# 2D status badge, separate from 3D terrain/range geometry.
			var marker := Node3D.new()
			marker.name = "Source_%d" % id
			_markers[id] = marker
			_marker_root.add_child(marker)
		_markers[id].position = OverlayScript.status_anchor_world(unit)


func source_marker_screen_position(camera: Camera3D, id: int) -> Vector2:
	if camera == null or not _sources.has(id) or not battle.units.has(id):
		return Vector2(INF, INF)
	var unit: Dictionary = battle.units[id]
	var world: Vector3 = OverlayScript.status_anchor_world(unit, float(battle.map.ground_height(unit.pos)))
	if not unit.alive or camera.is_position_behind(world):
		return Vector2(INF, INF)
	var anchor: Vector2 = camera.unproject_position(world)
	# Keep a five-pixel gap from the existing plate after the badge's 8px extent.
	return anchor + Vector2(-OverlayScript.status_bar_width(unit) * 0.5 - 13.0, 3)


func source_at_screen_position(camera: Camera3D, point: Vector2) -> int:
	var result: int = -1
	var best: float = 20.0 * 20.0
	for id: int in _sources:
		var badge: Vector2 = source_marker_screen_position(camera, id)
		if not badge.is_finite():
			continue
		var distance: float = badge.distance_squared_to(point)
		if distance < best:
			best = distance
			result = id
	return result


func _draw_source_markers() -> void:
	if _marker_camera == null or not is_instance_valid(_marker_camera):
		return
	var play_rect := Rect2(Vector2(8, 78), get_viewport().get_visible_rect().size - Vector2(16, 190))
	for id: int in _sources:
		var point: Vector2 = source_marker_screen_position(_marker_camera, id)
		if not point.is_finite() or not play_rect.has_point(point):
			continue
		# Dark backing survives both bright observed roads and desaturated fog.
		_source_overlay.draw_circle(point, 8.0, Color("173f3c"), true, -1, true)
		_source_overlay.draw_arc(point, 7.2, 0, TAU, 24, VISION_COLOR, 1.2, true)
		var eye := PackedVector2Array([point + Vector2(-5, 0), point + Vector2(-2, -3), point + Vector2(2, -3), point + Vector2(5, 0), point + Vector2(2, 3), point + Vector2(-2, 3), point + Vector2(-5, 0)])
		_source_overlay.draw_polyline(eye, VISION_COLOR, 1.3, true)
		_source_overlay.draw_circle(point, 1.6, VISION_COLOR, true, -1, true)


func _update_hover(camera: Camera3D, hover_enabled: bool) -> void:
	hovered_source_id = source_at_screen_position(camera, get_viewport().get_mouse_position()) if camera != null and hover_enabled else -1
	_contour.visible = hovered_source_id != -1
	_tooltip.visible = hovered_source_id != -1
	if hovered_source_id == -1:
		return
	_tooltip_label.text = source_tooltip(hovered_source_id)
	_tooltip.reset_size()
	_tooltip.position = (get_viewport().get_mouse_position() + Vector2(18, 20)).clamp(Vector2(8, 80), get_viewport().get_visible_rect().size - _tooltip.size - Vector2(8, 8))
	var p: Vector2 = _sources[hovered_source_id]
	if _boundary_id != hovered_source_id or _boundary_pos.distance_squared_to(p) > 0.01:
		_boundary_id = hovered_source_id
		_boundary_pos = p
		_boundary = source_boundary(hovered_source_id)
		_draw_contour(hovered_source_id)


func _draw_contour(id: int) -> void:
	var geometry := ImmediateMesh.new()
	geometry.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for index: int in range(_boundary.size()):
		_add_segment(geometry, _boundary[index], _boundary[(index + 1) % _boundary.size()], 0.075, VISION_COLOR)
	var unit: Dictionary = battle.units[id]
	if unit.kind == "tower":
		# Dashed amber attack ring differs from the solid pale, wall-clipped sight.
		for index: int in range(64):
			if index % 2 == 1:
				continue
			var a: float = TAU * index / 64.0
			var b: float = TAU * (index + 1) / 64.0
			_add_segment(geometry, unit.pos + Vector2(cos(a), sin(a)) * float(unit.attack_range), unit.pos + Vector2(cos(b), sin(b)) * float(unit.attack_range), 0.065, ATTACK_COLOR)
	geometry.surface_end()
	_contour.mesh = geometry
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_contour.material_override = material


func _add_segment(mesh: ImmediateMesh, a: Vector2, b: Vector2, width: float, color: Color) -> void:
	var normal := Vector2(-(b - a).y, (b - a).x).normalized() * width * 0.5
	mesh.surface_set_color(color)
	for point: Vector2 in [a - normal, a + normal, b + normal, a - normal, b + normal, b - normal]:
		mesh.surface_add_vertex(ArenaScript.to_world(point, float(battle.map.ground_height(point)) + 0.13))
