extends Control
## R29: read-only, recipient-scoped feedback; never infers rewards from HP/XP deltas.

const SPAWN_LIFE: float = 0.9
const GAIN_LIFE: float = 1.8
const LEVEL_LIFE: float = 3.2
const MAX_CUES: int = 16
const GOLD := Color("ffe09a")
const MINT := Color("b4f5d6")
const DARK := Color("25433d")

var battle: Variant
var camera: Camera3D
var ui_font: Font
var xp_label: Label
var enabled: bool = false
var cues: Array[Dictionary] = []
var _last_seq: int = 0
var _state_id: int = 0
var _match_serial: int = -1
var _flash_left: float = 0.0
var _meter: ProgressBar
var _meter_fill: StyleBoxFlat


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _exit_tree() -> void:
	if is_instance_valid(_meter):
		_meter.queue_free()


func reset_feedback() -> void:
	cues.clear()
	_last_seq = 0
	_state_id = 0
	_match_serial = -1
	_flash_left = 0.0
	if is_instance_valid(_meter):
		_meter.hide()
	queue_redraw()


func update_feedback(delta: float) -> void:
	if battle == null:
		reset_feedback()
		return
	if _state_id != battle.get_instance_id() or _match_serial != battle.match_serial:
		reset_feedback()
		_state_id = battle.get_instance_id()
		_match_serial = battle.match_serial
	var elapsed: float = maxf(0.0, delta) if is_finite(delta) else 0.0
	_flash_left = maxf(0.0, _flash_left - elapsed)
	for cue: Dictionary in cues:
		cue.life -= elapsed
	cues = cues.filter(func(cue: Dictionary) -> bool: return cue.life > 0.0 and (cue.kind != "spawn" or _spawn_visible(cue)))
	for event: Dictionary in battle.feedback_events:
		if int(event.seq) <= _last_seq:
			continue
		# Even rejected/hidden events are consumed. Revealing their location later
		# cannot turn an old authority event into a new visual occurrence.
		_last_seq = int(event.seq)
		if not enabled or not battle.units.has(battle.controlled_id):
			continue
		var age: float = maxf(0.0, float(battle.time) - float(event.time))
		if event.type == "cell_spawn":
			var team: int = battle.units[battle.controlled_id].team
			if team not in event.get("visible_to", []) or age >= SPAWN_LIFE or not _spawn_visible(event):
				continue
			var cue: Dictionary = event.duplicate(true)
			cue.merge({"kind": "spawn", "life": SPAWN_LIFE - age, "duration": SPAWN_LIFE})
			cues.append(cue)
		elif event.type == "xp_gain" and int(event.target_id) == int(battle.controlled_id):
			var amount: float = float(event.get("amount", 0.0))
			if not is_finite(amount) or amount <= 0.0:
				continue
			var duration: float = LEVEL_LIFE if int(event.get("points_gained", 0)) > 0 else GAIN_LIFE
			if age >= duration:
				continue
			var cue: Dictionary = event.duplicate(true)
			cue.merge({"kind": "gain", "life": duration - age, "duration": duration})
			cues.append(cue)
			_flash_left = 0.7
	while cues.size() > MAX_CUES:
		cues.pop_front()
	if not enabled:
		cues.clear()
	_sync_meter()
	queue_redraw()


func _sync_meter() -> void:
	if not is_instance_valid(xp_label):
		if is_instance_valid(_meter):
			_meter.hide()
		return
	if is_instance_valid(_meter) and _meter.get_parent() != xp_label:
		_meter.queue_free()
		_meter = null
	if not is_instance_valid(_meter):
		# The world overlay is drawn BEFORE opaque HUD panels. The meter belongs
		# inside the XP label's HUD branch, while modals retain their later order.
		_meter = ProgressBar.new()
		_meter.name = "XPProgress"
		_meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_meter.min_value = 0.0
		_meter.max_value = 1.0
		_meter.step = 0.0
		_meter.show_percentage = false
		var background := StyleBoxFlat.new()
		background.bg_color = DARK
		background.content_margin_left = 0
		background.content_margin_right = 0
		background.content_margin_top = 0
		background.content_margin_bottom = 0
		_meter_fill = background.duplicate() as StyleBoxFlat
		_meter_fill.bg_color = MINT
		_meter.add_theme_stylebox_override("background", background)
		_meter.add_theme_stylebox_override("fill", _meter_fill)
		xp_label.add_child(_meter)
	# The existing VBox has a four-pixel gap above its XP label. Use only its
	# middle two pixels, without resizing the panel or covering either text row.
	_meter.position = Vector2(0, -3)
	_meter.size = Vector2(minf(245.0, xp_label.size.x), 2)
	_meter.value = progression_ratio()
	_meter_fill.bg_color = GOLD if _flash_left > 0.0 else MINT
	_meter.visible = enabled


func _spawn_visible(cue: Dictionary) -> bool:
	if battle == null or not battle.units.has(battle.controlled_id):
		return false
	var id: int = int(cue.get("target_id", -1))
	if not battle.units.has(id) or not battle.units[id].alive:
		return false
	var team: int = battle.units[battle.controlled_id].team
	return battle.is_point_visible(team, cue.pos)


func progression_ratio() -> float:
	if battle == null or not battle.units.has(battle.controlled_id):
		return 0.0
	var hero: Dictionary = battle.units[battle.controlled_id]
	if hero.level >= 12:
		return 1.0
	return clampf(float(hero.xp) / (100.0 + 25.0 * (int(hero.level) - 1)), 0.0, 1.0)


func progress_rect() -> Rect2:
	if not is_instance_valid(_meter):
		return Rect2()
	var origin: Vector2 = get_global_transform().affine_inverse() * _meter.global_position
	return Rect2(origin, _meter.size)


func reward_text(cue: Dictionary) -> String:
	var source: String = {"cell": "셀", "minion": "병력", "hero": "교전"}.get(str(cue.get("source_kind", "")), "성장")
	var result: String = "+%s XP · %s" % [_amount_text(float(cue.amount)), source]
	var count: int = int(cue.get("share_count", 1))
	if count > 1:
		result += " · %d명 공유" % count
	if int(cue.get("points_gained", 0)) > 0:
		result += "\n레벨 %d · 성장 +%d · G 투자" % [int(cue.level_after), int(cue.points_gained)]
		if battle != null and battle.units.has(battle.controlled_id):
			var hero: Dictionary = battle.units[battle.controlled_id]
			if int(cue.level_after) >= 3 and not hero.r_unlocked and int(hero.points) > 0:
				result += " / R 해금 가능"
	return result


static func _amount_text(amount: float) -> String:
	if absf(amount - roundf(amount)) < 0.000001:
		return "%d" % roundi(amount)
	if amount < 0.01:
		return "<0.01"
	var rounded: float = roundf(amount * 100.0) / 100.0
	return ("≈" if absf(rounded - amount) > 0.000001 else "") + ("%.2f" % amount)


func cue_world_position(cue: Dictionary) -> Vector3:
	var point: Vector2 = cue.pos
	var ground: float = float(battle.map.ground_height(point)) if battle != null else 0.0
	var lift: float = 0.12 if cue.kind == "spawn" else 3.2 + (float(cue.duration) - float(cue.life)) * 0.5
	return Vector3(point.x, ground + lift, -point.y)


func _draw() -> void:
	if not enabled or battle == null or ui_font == null:
		return
	var latest: Dictionary = {}
	var latest_level: Dictionary = {}
	var world_gains: Array = []
	for cue: Dictionary in cues:
		if cue.kind == "spawn":
			_draw_spawn(cue)
		else:
			latest = cue
			world_gains.append(cue)
			if int(cue.get("points_gained", 0)) > 0:
				latest_level = cue
	# Prefer a still-live growth prompt over a stream of tiny minion rewards.
	if not latest_level.is_empty():
		latest = latest_level
	if not latest.is_empty():
		_draw_notification(latest)
	if camera == null:
		return
	var clip := Rect2(Vector2(8, 78), Vector2(maxf(0, size.x - 16), maxf(0, size.y - 252)))
	var first: int = maxi(0, world_gains.size() - 3)
	for index: int in range(first, world_gains.size()):
		var cue: Dictionary = world_gains[index]
		var world: Vector3 = cue_world_position(cue)
		if camera.is_position_behind(world):
			continue
		var point: Vector2 = camera.unproject_position(world) - Vector2(0, (index - first) * 20.0)
		if clip.has_point(point):
			var color: Color = MINT
			color.a = minf(1.0, float(cue.life) * 3.0)
			_text("+%s XP" % _amount_text(float(cue.amount)), point, 18, color, true)


func _draw_spawn(cue: Dictionary) -> void:
	if camera == null or not _spawn_visible(cue):
		return
	var center: Vector3 = cue_world_position(cue)
	if camera.is_position_behind(center):
		return
	var progress: float = 1.0 - float(cue.life) / SPAWN_LIFE
	var radius: float = 0.6 + progress * 0.8
	var color: Color = GOLD
	color.a = minf(1.0, float(cue.life) * 3.0)
	var team: int = battle.units[battle.controlled_id].team
	var clip := Rect2(Vector2(8, 78), Vector2(maxf(0, size.x - 16), maxf(0, size.y - 252)))
	for index: int in range(32):
		var a: Vector2 = cue.pos + Vector2.from_angle(TAU * index / 32.0) * radius
		var b: Vector2 = cue.pos + Vector2.from_angle(TAU * (index + 1) / 32.0) * radius
		if not battle.is_point_visible(team, a) or not battle.is_point_visible(team, b):
			continue
		var aw := Vector3(a.x, float(battle.map.ground_height(a)) + 0.12, -a.y)
		var bw := Vector3(b.x, float(battle.map.ground_height(b)) + 0.12, -b.y)
		if camera.is_position_behind(aw) or camera.is_position_behind(bw):
			continue
		var pa: Vector2 = camera.unproject_position(aw)
		var pb: Vector2 = camera.unproject_position(bw)
		if clip.has_point(pa) and clip.has_point(pb):
			draw_line(pa, pb, color, 2.0, true)
	var label_point: Vector2 = camera.unproject_position(center) + Vector2(0, 22)
	if clip.has_point(label_point):
		_text("셀 등장 · %d XP" % int(cue.xp_reward), label_point, 13, color, true)


func _draw_notification(cue: Dictionary) -> void:
	var lines: PackedStringArray = reward_text(cue).split("\n")
	var height: float = 54.0 if lines.size() > 1 else 32.0
	var rect := Rect2(Vector2(32, maxf(86, size.y - 176.0 - height)), Vector2(minf(440, maxf(0, size.x - 64)), height))
	var plate := StyleBoxFlat.new()
	plate.bg_color = Color(0.12, 0.24, 0.22, 0.94)
	plate.border_color = GOLD if lines.size() > 1 else MINT
	plate.set_border_width_all(1)
	plate.set_corner_radius_all(5)
	draw_style_box(plate, rect)
	for index: int in range(lines.size()):
		_text(lines[index], rect.position + Vector2(12, 22 + index * 21), 14, GOLD if index > 0 else MINT)


func _text(text: String, point: Vector2, font_size: int, color: Color, centered: bool = false) -> void:
	if centered:
		point.x -= ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x * 0.5
	draw_string_outline(ui_font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, DARK)
	draw_string(ui_font, point, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
