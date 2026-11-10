extends Node
const RosterScript = preload("res://scripts/battle/hero_roster.gd")
const DisplayLayout = preload("res://scripts/presentation/battlefield_layout.gd")
## Isolated interactive inspection. Same battlefield, rigs, map and skill authority.
## Only this instance receives reset/cooldown/respawn assistance.
var original: Node3D
var stage: Variant
var selected_hero: String = "bas"
var action: String = "idle"
var elapsed: float = 0.0
var running: bool = false
var speed: float = 1.0
var map_view: bool = false
var status: Label
var layer: CanvasLayer
var _dummy_id: int = -1
var _canvases: Array[CanvasLayer] = []
var _canvas_visibility: Array[bool] = []
var _was_paused: bool = false
var _was_visible: bool = true
var _original_process: bool = true
var _original_physics: bool = true
var _original_input: bool = true
var _closing: bool = false
var _action_buttons: Dictionary = {}

func _ready() -> void:
	_was_paused = original.paused
	_was_visible = original.visible
	_original_process = original.is_processing()
	_original_physics = original.is_physics_processing()
	_original_input = original.is_processing_unhandled_input()
	original.paused = true
	original.hide()
	original.set_process(false)
	original.set_physics_process(false)
	original.set_process_unhandled_input(false)
	for item: Node in original.find_children("*", "CanvasLayer", true, false):
		_canvases.append(item)
		_canvas_visibility.append(item.visible)
		item.hide()
	stage = load("res://scenes/battlefield.tscn").instantiate()
	stage.set_meta("review_stage", true)
	add_child(stage)
	stage.edge_pan_enabled = false
	stage.set_process(false)
	stage.set_physics_process(false)
	stage.set_process_unhandled_input(false)
	_build_ui()
	select_hero("bas")

func _build_ui() -> void:
	layer = CanvasLayer.new()
	layer.layer = 40
	add_child(layer)
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	panel.offset_left = 16
	panel.offset_right = -16
	panel.offset_top = 12
	panel.offset_bottom = 110
	layer.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 7)
	panel.add_child(box)
	var title := Label.new()
	title.text = "PROJECT E  /  아스트라 연출실   —   3등신 모델 · 스킬 · 모션"
	title.add_theme_font_size_override("font_size", 20)
	box.add_child(title)
	var row := HFlowContainer.new()
	box.add_child(row)
	for key: String in RosterScript.KEYS:
		_button(row, RosterScript.HEROES[key][0], func() -> void: select_hero(key))
	_button(row, "전체 맵", func() -> void: set_map_view(true))
	_button(row, "언덕 이동", func() -> void: play_action("hill"))
	_button(row, "0.5× / 1×", func() -> void: speed = 0.5 if speed == 1.0 else 1.0)
	_button(row, "재생 / 정지", func() -> void: running = not running)
	_button(row, "다시 보기", func() -> void: play_action(action))
	_button(row, "경기로 돌아가기", close_review)
	var footer := PanelContainer.new()
	layer.add_child(footer)
	footer.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer.offset_left = 16
	footer.offset_right = -16
	footer.offset_top = -106
	footer.offset_bottom = -12
	var lower := VBoxContainer.new()
	footer.add_child(lower)
	status = Label.new()
	status.add_theme_font_size_override("font_size", 14)
	lower.add_child(status)
	var actions := HFlowContainer.new()
	lower.add_child(actions)
	for key: String in ["idle", "walk", "basic", "Q", "W", "E", "R", "hit", "death", "respawn"]:
		var label: String = {"idle":"대기", "walk":"이동", "basic":"기본 공격", "hit":"피격", "death":"사망", "respawn":"부활"}.get(key, key)
		_action_buttons[key] = _button(actions, label, func() -> void: play_action(key))
	for root_control: Control in [panel, footer]:
		var theme := Theme.new()
		theme.default_font = stage.hud.ui_font
		theme.default_font_size = 14
		var style := StyleBoxFlat.new()
		style.bg_color = Color("202941")
		style.border_color = Color("e4bb81")
		style.set_border_width_all(1)
		style.set_corner_radius_all(12)
		style.content_margin_left = 15
		style.content_margin_right = 15
		style.content_margin_top = 10
		style.content_margin_bottom = 10
		theme.set_stylebox("panel", "PanelContainer", style)
		root_control.theme = theme

func _button(parent: Control, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(78, 31)
	button.focus_mode = Control.FOCUS_NONE
	parent.add_child(button)
	button.pressed.connect(callback)
	return button

func select_hero(key: String) -> void:
	if key not in RosterScript.KEYS: return
	selected_hero = key
	for index: int in range(4):
		var slot: String = ["Q", "W", "E", "R"][index]
		var button: Button = _action_buttons[slot]
		button.text = "%s\n%s" % [slot, stage.hud.SKILLS[key][index]]
		button.add_theme_font_size_override("font_size", 12)
		button.tooltip_text = stage.hud.SKILL_HELP[key][index]
	play_action("idle")

func _reset_stage() -> Dictionary:
	stage.start_match(selected_hero, true)
	stage.paused = true
	stage.battle.bots_enabled = false
	stage.battle._next_ai = INF
	stage.battle._next_wave = INF
	# Advance only this isolated clock to the real initial-spawn boundary.
	# The authority creates the cells and their tier/reward data; no cloned rules.
	stage.battle._next_income = INF
	stage.battle.time = 30.0 - stage.battle.FIXED_STEP
	stage.battle.step(stage.battle.FIXED_STEP)
	var hero: Dictionary = stage.battle.units[stage.battle.controlled_id]
	_dummy_id = -1
	for id: int in stage.battle.units.keys():
		var unit: Dictionary = stage.battle.units[id]
		if unit.kind == "hero" and id != hero.id:
			if unit.team == 1 and unit.hero == "bas":
				_dummy_id = id
				unit.pos = Vector2(0, 0)
				unit.protected = 0
			else: stage.battle.units.erase(id)
		elif unit.kind == "cell": unit.alive = true
	hero.pos = Vector2(-3, 0)
	hero.facing = Vector2(0, -1)
	hero.protected = 0.0
	stage._camera_follow = false
	stage._camera_focus = Vector2(-1, 0)
	stage.battle._visibility_cache.clear()
	stage._sync_visuals(0.0)
	for canvas: CanvasLayer in stage.find_children("*", "CanvasLayer", true, false): canvas.hide()
	stage.camera.current = true
	return hero

func play_action(key: String) -> bool:
	if key not in ["idle", "walk", "basic", "Q", "W", "E", "R", "hit", "death", "respawn", "hill"]: return false
	map_view = false
	action = key
	elapsed = 0.0
	var hero: Dictionary = _reset_stage()
	var accepted: bool = true
	if key in ["Q", "W", "E", "R"]:
		hero.facing = Vector2.RIGHT
		if selected_hero == "nema" and key in ["W", "R"]:
			# Real Q commands establish prerequisites, not fake decorative pins.
			for point: Vector2 in [Vector2(-1, -1.2), Vector2(1, 1.2)]:
				hero.cooldowns.Q = 0.0
				hero.energy = hero.max_energy
				accepted = stage.battle.command_cast(hero.id, "Q", point) and accepted
				stage.battle.step(0.45)
			hero.energy = hero.max_energy
			stage._sync_visuals(0.0)
		if selected_hero == "mua" and key in ["W", "E", "R"]:
			for point: Vector2 in [Vector2(-2, 0), Vector2(1, 0)]:
				hero.cooldowns.Q = 0.0
				hero.energy = hero.max_energy
				accepted = stage.battle.command_cast(hero.id, "Q", point) and accepted
				stage.battle.step(0.55)
			hero.energy = hero.max_energy
		if selected_hero == "sera" and key == "R":
			# Real crescent hits create the marked bonus used by the demonstration.
			hero.pos = Vector2(-1, 0)
			accepted = stage.battle.command_cast(hero.id, "Q", Vector2(1, 0)) and accepted
			stage.battle.step(0.6)
			hero.energy = hero.max_energy
		var target := Vector2(1, 0)
		if selected_hero == "bas" and key == "W": target = hero.pos
		if selected_hero == "tere" and key == "E": target = hero.pos + Vector2.LEFT * 4.0
		accepted = stage.battle.command_cast(hero.id, key, target) and accepted
	elif key == "walk":
		accepted = stage.battle.command_move(hero.id, Vector2(3, 0))
	elif key == "hill":
		hero.pos = Vector2(-18, 18)
		hero.facing = Vector2.UP
		stage._camera_focus = Vector2(-18, 22)
		accepted = stage.battle.command_move(hero.id, Vector2(-18, 24))
	elif key == "basic":
		accepted = stage.battle.command_attack(hero.id, _dummy_id)
	elif key in ["hit", "death", "respawn"]:
		accepted = stage.battle.apply_damage(_dummy_id, hero.id, 120.0 if key == "hit" else 99999.0, stage.battle.next_action_id()) > 0
		stage._sync_visuals(0.0)
		if key == "respawn":
			# Shorten only the isolated demonstration wait; tick real respawn logic.
			hero.respawn_left = 0.05
			stage.battle.step(0.10)
			hero.pos = Vector2(-3, 0)
			stage._sync_visuals(0.0)
	running = true
	_redraw()
	return accepted

func advance_review(seconds: float) -> void:
	if not is_finite(seconds) or seconds < 0: return
	stage.battle.step(minf(seconds, 5.0))
	elapsed += minf(seconds, 5.0)
	_redraw()

func _process(delta: float) -> void:
	if _closing: return
	if running and not map_view:
		advance_review(minf(delta, 0.1) * speed)
	else: _redraw()

func _redraw() -> void:
	stage.battle._visibility_cache.clear()
	stage._sync_visuals(0.0)
	for canvas: CanvasLayer in stage.find_children("*", "CanvasLayer", true, false): canvas.hide()
	var hero: Dictionary = stage.battle.units[stage.battle.controlled_id]
	if map_view:
		stage.arena.set_vision_texture(null)
		# Full objective disclosure belongs only to this separate review state.
		for unit: Dictionary in stage.battle.units.values():
			if unit.kind in ["cell", "tower", "core"] and stage._unit_nodes.has(unit.id):
				stage._unit_nodes[unit.id].visible = bool(unit.alive)
		stage.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		var viewport_height: float = stage.get_viewport().get_visible_rect().size.y
		stage.camera.size = 124.0 * viewport_height / maxf(100.0, viewport_height - 260.0)
		stage.camera.position = DisplayLayout.camera_offset(108, 44)
		stage.camera.look_at(Vector3.ZERO, Vector3.UP)
	else:
		stage.arena.set_vision_texture(stage.vision_view.mask_texture)
		var portrait: bool = action in ["idle", "walk", "hit", "death", "respawn"]
		if portrait and stage._unit_nodes.has(_dummy_id): stage._unit_nodes[_dummy_id].hide()
		var focus: Vector2 = hero.pos if portrait else stage._camera_focus
		var height: float = stage.battle.map.ground_height(focus)
		var target := Vector3(focus.x, height + 0.9, -focus.y)
		stage.camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		stage.camera.fov = 42.0
		var skill_camera_offset := Vector3(0, 8.0, 14.0) if selected_hero == "tere" and action == "R" else Vector3(0, 7.0, 12.0)
		stage.camera.position = target + (Vector3(0, 5.0, 9.0) if portrait else skill_camera_offset)
		stage.camera.look_at(target, Vector3.UP)
	var action_name: String = {"idle": "대기", "walk": "이동", "basic": "기본 공격", "hit": "피격", "death": "사망", "respawn": "부활", "hill": "언덕 이동"}.get(action, action)
	var slot_index: int = ["Q", "W", "E", "R"].find(action)
	if slot_index >= 0:
		action_name = "%s %s" % [action, stage.hud.SKILLS[selected_hero][slot_index]]
	status.text = "%s / %s · %.2f초 · %.1f× · 지면 %.2fm · %s" % [RosterScript.HEROES[selected_hero][0], action_name, elapsed, speed, stage.battle.map.ground_height(hero.pos), "연출실 전체 지형 보기" if map_view else "스킬 범위와 적중 확인"]

func set_map_view(enabled: bool) -> void:
	map_view = enabled
	_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_F7]: close_review()
		elif event.keycode == KEY_SPACE: running = not running
		else: return
		get_viewport().set_input_as_handled()

func close_review() -> void:
	if _closing: return
	_closing = true
	if is_instance_valid(original):
		original.review_lab = null
		original.paused = _was_paused
		original.visible = _was_visible
		original.set_process(_original_process)
		original.set_physics_process(_original_physics)
		original.set_process_unhandled_input(_original_input)
		for index: int in range(_canvases.size()):
			if is_instance_valid(_canvases[index]): _canvases[index].visible = _canvas_visibility[index]
		original.camera.current = true
	queue_free()
