extends "res://scripts/presentation/battlefield.gd"
## Playable composition layer; inherited controller still owns commands/UI/lifecycle.
const TacticalAI = preload("res://scripts/battle/tactical_ai.gd")
const AccentView = preload("res://scripts/presentation/combat_accents.gd")
const CAMERA_MODES: Dictionary = {"combat": 30.0, "tactical": 50.0, "detail": 18.0}
var camera_mode: String = "combat"
var edge_pan_enabled: bool = true
var _accents: MeshInstance3D
var _camera_hint: Label

func _ready() -> void:
	battle._ai = TacticalAI.new()
	_accents = AccentView.new()
	_accents.name = "CombatAccents"
	add_child(_accents)
	super._ready()
	_camera_hint = Label.new()
	_camera_hint.name = "CameraHint"
	_camera_hint.position = Vector2(22, 82)
	_camera_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_camera_hint.add_theme_font_override("font", hud.ui_font)
	_camera_hint.add_theme_font_size_override("font_size", 12)
	_camera_hint.add_theme_color_override("font_color", Color("fff2d4"))
	_camera_hint.add_theme_color_override("font_outline_color", Color("25413d"))
	_camera_hint.add_theme_constant_override("outline_size", 4)
	hud.root_control.add_child(_camera_hint)
	_camera_hint.hide()

func start_match(hero_key: String, practice: bool = false) -> void:
	super.start_match(hero_key, practice)
	camera_mode = "combat"
	_camera_follow = false
	_camera_focus = battle.units[battle.controlled_id].pos
	set_camera_mode("combat")

func set_camera_mode(mode: String) -> void:
	if not CAMERA_MODES.has(mode) or camera == null:
		return
	camera_mode = mode
	camera.size = float(CAMERA_MODES[mode])
	_update_camera(0.0)

func _update_camera(delta: float) -> void:
	if not has_active_match:
		camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		super._update_camera(delta)
		return
	if _camera_follow and battle.units.has(battle.controlled_id):
		var target: Vector2 = battle.units[battle.controlled_id].pos
		_camera_focus = _camera_focus.lerp(target, 1.0 - exp(-maxf(0, delta) * 12.0)) if delta > 0 else target
	_camera_focus.x = clampf(_camera_focus.x, -55.0, 55.0)
	_camera_focus.y = clampf(_camera_focus.y, -31.0, 31.0)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 42.0
	camera.keep_aspect = Camera3D.KEEP_HEIGHT
	var distance: float = camera.size * 0.5 / tan(deg_to_rad(camera.fov * 0.5))
	var pitch: float = deg_to_rad(55.0)
	var height: float = float(battle.map.ground_height(_camera_focus))
	var look := Vector3(_camera_focus.x, height + 0.65, -_camera_focus.y)
	camera.position = look + Vector3(0, sin(pitch) * distance, cos(pitch) * distance)
	camera.look_at(look, Vector3.UP)

func _camera_input_allowed() -> bool:
	if not has_active_match or paused or battle.winner != -1 or hud == null:
		return false
	if hud.selection.visible or hud.growth.visible or hud.help_panel.visible or hud.shop.visible or hud.result.visible or hud.pause_menu.visible:
		return false
	var focus: Control = get_viewport().gui_get_focus_owner()
	return not (focus is LineEdit or focus is TextEdit)

func pan_camera(axis: Vector2, delta: float) -> void:
	if not _camera_input_allowed() or not axis.is_finite() or not is_finite(delta) or delta <= 0:
		return
	_camera_follow = false
	_camera_focus += Vector2(axis.x, -axis.y).limit_length(1.0) * 23.0 * minf(delta, 0.5)
	_update_camera(0.0)

func handle_hotkey(keycode: int) -> bool:
	if keycode in [KEY_F6, KEY_Y] and _camera_input_allowed():
		if keycode == KEY_F6:
			var modes: Array = ["combat", "tactical", "detail"]
			set_camera_mode(modes[(modes.find(camera_mode) + 1) % modes.size()])
		else:
			_camera_follow = not _camera_follow
			_update_camera(0.0)
		return true
	return super.handle_hotkey(keycode)

func _process(delta: float) -> void:
	if edge_pan_enabled and _camera_input_allowed() and not _camera_follow and not _camera_drag and aim_slot.is_empty() and not attack_move_aim and get_window().has_focus():
		var mouse: Vector2 = get_viewport().get_mouse_position()
		var bounds: Rect2 = get_viewport().get_visible_rect()
		if bounds.has_point(mouse) and not ui_blocks_point(mouse):
			var axis := Vector2.ZERO
			if mouse.x < 12: axis.x = -1
			elif mouse.x > bounds.size.x - 12: axis.x = 1
			if mouse.y < 12: axis.y = -1
			elif mouse.y > bounds.size.y - 12: axis.y = 1
			if not axis.is_zero_approx():
				pan_camera(axis, delta)
	super._process(delta)
	if _camera_hint != null:
		_camera_hint.visible = has_active_match and not hud.result.visible and not hud.selection.visible and not hud.help_panel.visible and not hud.shop.visible and not hud.growth.visible
		_camera_hint.text = "F6 시점: %s · Y 추적 %s · Space 내 영웅 · 가장자리/가운데 드래그 이동" % [{"combat": "전투", "tactical": "전술", "detail": "가까이"}.get(camera_mode, "전투"), "ON" if _camera_follow else "OFF"]

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN] and _camera_input_allowed() and not ui_blocks_point(event.position):
		camera.size = clampf(camera.size + (-2.0 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 2.0), 16.0, 58.0)
		_update_camera(0.0)
		get_viewport().set_input_as_handled()
		return
	super._unhandled_input(event)

func screen_to_ground(screen: Vector2) -> Variant:
	if not screen.is_finite() or not get_viewport().get_visible_rect().has_point(screen):
		return null
	var origin: Vector3 = camera.project_ray_origin(screen)
	var direction: Vector3 = camera.project_ray_normal(screen)
	if direction.y >= -0.000001:
		return null
	# First intersection with the authority height field, not a fixed Y=0 plane.
	# Sampling a narrow [3m,0m] slab also handles ramp/plateau discontinuities.
	var near_t: float = maxf(0.0, (3.0 - origin.y) / direction.y)
	var far_t: float = (0.0 - origin.y) / direction.y
	if far_t < near_t:
		return null
	var previous: float = near_t
	for index: int in range(1, 97):
		var current: float = lerpf(near_t, far_t, float(index) / 96.0)
		var point: Vector3 = origin + direction * current
		var surface: float = float(battle.map.ground_height(Vector2(point.x, -point.z)))
		if point.y <= surface + 0.000001:
			var lo: float = previous
			var hi: float = current
			for _iteration: int in range(16):
				var mid: float = (lo + hi) * 0.5
				var probe: Vector3 = origin + direction * mid
				if probe.y > float(battle.map.ground_height(Vector2(probe.x, -probe.z))):
					lo = mid
				else:
					hi = mid
			point = origin + direction * hi
			return Vector2(point.x, -point.z)
		previous = current
	var flat: Vector3 = origin + direction * far_t
	return Vector2(flat.x, -flat.z)

func _sync_visuals(delta: float) -> void:
	super._sync_visuals(delta)
	for id: int in _unit_nodes:
		if not battle.units.has(id) or not _unit_nodes[id].visible:
			continue
		var rig: Variant = _unit_nodes[id].get_node_or_null("Model/HeroRig")
		if rig != null:
			rig.pose(battle.units[id], float(battle.time))
	if _accents != null:
		_accents.refresh(battle)
