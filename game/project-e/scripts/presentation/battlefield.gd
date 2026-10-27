extends Node3D
## Converts local input to authority commands and renders only observable state.

const BattleScript = preload("res://scripts/battle/battle_state.gd")
const HUDScript = preload("res://scripts/presentation/battle_hud.gd")
const AbilityScript = preload("res://scripts/battle/hero_abilities.gd")
const VisionScript = preload("res://scripts/presentation/team_vision_view.gd")

var battle: Variant = BattleScript.new()
var has_active_match: bool = false
var paused: bool = false
var aim_slot: String = ""
var attack_move_aim: bool = false
var selected_target_id: int = -1
var is_practice: bool = false
var minimap: Control
var hud: CanvasLayer
var vision_view: Node3D
var _hero_key: String = "bas"
var _unit_nodes: Dictionary = {}
var _destination: Variant = null
var _destination_left: float = 0.0
var _camera_focus := Vector2(-28, 0)
var _camera_follow: bool = false
var _camera_drag: bool = false
var _result_shown: bool = false
var _help_was_paused: bool = false
var _shop_was_paused: bool = false

@onready var camera: Camera3D = $Camera3D
@onready var arena: Node3D = $Arena
@onready var units_view: Node3D = $Units
@onready var effects_view: MeshInstance3D = $Effects


func _ready() -> void:
	battle.reset("bas", false)
	arena.build(battle.map, battle.units)
	vision_view = VisionScript.new()
	vision_view.name = "TeamVision"
	add_child(vision_view)
	vision_view.configure(battle)
	hud = HUDScript.new()
	hud.name = "BattleHUD"
	add_child(hud)
	minimap = hud.minimap
	minimap.battle = battle
	minimap.camera = camera
	minimap.vision_view = vision_view
	minimap.point_selected.connect(_on_minimap_point)
	hud.unit_overlay.battle = battle
	hud.unit_overlay.camera = camera
	hud.match_requested.connect(start_match)
	hud.ability_requested.connect(arm_ability)
	hud.growth_requested.connect(open_growth)
	hud.investment_requested.connect(spend_growth)
	hud.resume_requested.connect(_resume)
	hud.selection_requested.connect(return_to_selection)
	hud.restart_requested.connect(restart_match)
	hud.pause_requested.connect(func() -> void: handle_hotkey(KEY_ESCAPE))
	hud.growth_closed.connect(close_growth)
	hud.help_requested.connect(open_help)
	hud.help_closed.connect(close_help)
	hud.shop_requested.connect(open_shop)
	hud.shop_closed.connect(close_shop)
	hud.consumable_purchase_requested.connect(buy_consumable)
	hud.consumable_selected.connect(select_consumable)
	hud.consumable_use_requested.connect(use_consumable)
	camera.current = true
	camera.size = 66.0
	_update_camera(0)
	_sync_visuals(0)
	hud.show_selection()


func _physics_process(delta: float) -> void:
	if has_active_match and not paused and battle.winner == -1:
		battle.step(delta)


func _process(delta: float) -> void:
	if hud == null:
		return
	_update_camera(delta)
	_sync_visuals(delta)
	if has_active_match:
		if not battle.units[battle.controlled_id].alive:
			_clear_aim()
		hud.update_state(battle, aim_slot, is_practice, attack_move_aim)
		if battle.winner != -1 and not _result_shown:
			_result_shown = true
			_clear_aim()
			paused = true
			hud.show_result(battle, is_practice)


func start_match(hero_key: String, practice: bool = false) -> void:
	_hero_key = hero_key if HUDScript.HEROES.has(hero_key) else "bas"
	battle.reset(_hero_key, practice)
	is_practice = practice
	has_active_match = true
	paused = false
	_clear_aim()
	selected_target_id = -1
	_destination = null
	_destination_left = 0.0
	_result_shown = false
	_help_was_paused = false
	_shop_was_paused = false
	_camera_drag = false
	_camera_follow = true
	_clear_models()
	vision_view.configure(battle)
	hud.unit_overlay.reset_feedback()
	hud.show_match()
	hud.select_hero(_hero_key)
	camera.size = 42.0
	_camera_focus = battle.units[battle.controlled_id].pos
	_update_camera(0)
	_sync_visuals(0)
	hud.update_state(battle, aim_slot, is_practice)
	hud.show_message("기술 체험 · 레벨 3 / R 해금 · P 상점 / D 사용 · F1 도움말" if practice else "G 성장 · P 기지 상점 / D 사용 · 첫 병력은 20초 · F1 도움말", 5.0)


func restart_match() -> void:
	start_match(_hero_key, is_practice)


func return_to_selection() -> void:
	has_active_match = false
	paused = false
	_clear_aim()
	selected_target_id = -1
	_destination = null
	_camera_follow = false
	_camera_drag = false
	_camera_focus = Vector2(-18, 0)
	camera.size = 66.0
	hud.show_selection()
	_update_camera(0)


func selection_visible() -> bool:
	return hud.selection.visible


func growth_visible() -> bool:
	return hud.growth.visible


func help_visible() -> bool:
	return hud.help_panel.visible


func open_help() -> void:
	if not has_active_match or battle.winner != -1 or growth_visible() or shop_visible():
		return
	if help_visible():
		close_help()
		return
	_help_was_paused = paused
	_clear_aim()
	_camera_drag = false
	paused = true
	hud.help_panel.show()


func close_help() -> void:
	if not help_visible():
		return
	hud.help_panel.hide()
	paused = _help_was_paused


func shop_visible() -> bool:
	return hud.shop.visible


func open_shop() -> void:
	if not has_active_match or battle.winner != -1 or growth_visible() or help_visible() or hud.result.visible or hud.pause_menu.visible:
		return
	if shop_visible():
		close_shop()
		return
	_shop_was_paused = paused
	_clear_aim()
	_camera_drag = false
	paused = true
	hud._shop_feedback.text = ""
	hud.shop.show()
	hud.update_state(battle, aim_slot, is_practice, attack_move_aim)


func close_shop() -> void:
	if not shop_visible():
		return
	hud.shop.hide()
	paused = _shop_was_paused


func buy_consumable(item_id: String) -> bool:
	if not has_active_match or not shop_visible() or battle.winner != -1:
		return false
	var accepted: bool = battle.command_buy_consumable(battle.controlled_id, item_id)
	if not accepted:
		hud.show_consumable_message(HUDScript.consumable_reason(str(battle.last_error)))
	hud.update_state(battle, aim_slot, is_practice, attack_move_aim)
	return accepted


func select_consumable(item_id: String) -> bool:
	if not has_active_match or battle.winner != -1 or paused or hud.selection.visible or hud.result.visible or shop_visible() or growth_visible() or help_visible() or hud.pause_menu.visible:
		return false
	var accepted: bool = battle.command_select_consumable(battle.controlled_id, item_id)
	if not accepted:
		hud.show_consumable_message(HUDScript.consumable_reason(str(battle.last_error)))
	hud.update_state(battle, aim_slot, is_practice, attack_move_aim)
	return accepted


func use_consumable() -> bool:
	if not _accepts_commands():
		return false
	var accepted: bool = battle.command_use_consumable(battle.controlled_id)
	if not accepted:
		hud.show_consumable_message(HUDScript.consumable_reason(str(battle.last_error)))
	hud.update_state(battle, aim_slot, is_practice, attack_move_aim)
	return accepted

func get_growth_button_rect() -> Rect2:
	return hud.growth_button.get_global_rect()


func open_growth() -> void:
	if not has_active_match or battle.winner != -1 or hud.pause_menu.visible or help_visible() or shop_visible():
		return
	if growth_visible():
		close_growth()
		return
	_clear_aim()
	_camera_drag = false
	paused = true
	hud.growth.show()
	hud.update_state(battle, aim_slot, is_practice)


func close_growth() -> void:
	hud.growth.hide()
	paused = false


func spend_growth(stat: String) -> bool:
	if not has_active_match or not growth_visible() or battle.winner != -1:
		return false
	var accepted: bool = battle.invest(battle.controlled_id, stat)
	if not accepted:
		_show_error()
	hud.update_state(battle, aim_slot, is_practice)
	return accepted


func arm_ability(slot: String) -> bool:
	slot = slot.to_upper()
	if not _accepts_commands() or slot not in ["Q", "W", "E", "R"]:
		return false
	var hero: Dictionary = battle.units[battle.controlled_id]
	var error: String = ""
	if not hero.alive:
		error = "부활 후 기술을 사용할 수 있습니다."
	elif slot == "R" and not hero.r_unlocked:
		error = "R은 레벨 3부터 성장 1포인트로 해금합니다."
	elif hero.cooldowns[slot] > 0:
		error = "%s 재사용까지 %.1f초 남았습니다." % [slot, hero.cooldowns[slot]]
	elif hero.energy < float(AbilityScript.CONFIG[hero.hero][slot][0]):
		error = "에너지가 부족합니다."
	elif hero.stun_left > 0:
		error = "기절 중에는 기술을 사용할 수 없습니다."
	if error != "":
		hud.show_message(error)
		return false
	attack_move_aim = false
	aim_slot = slot
	hud.show_message("%s 조준 · 좌클릭 확정 / Esc 취소" % slot, 2.0)
	return true


func arm_attack_move() -> bool:
	if not _accepts_commands():
		return false
	var hero: Dictionary = battle.units[battle.controlled_id]
	if not hero.alive or hero.stun_left > 0.0 or hero.root_left > 0.0:
		hud.show_message("지금은 공격 이동을 시작할 수 없습니다.")
		return false
	aim_slot = ""
	attack_move_aim = true
	hud.show_message("A 공격 이동 · 지면 좌클릭 확정 / Esc 취소", 2.0)
	return true


func _clear_aim() -> void:
	aim_slot = ""
	attack_move_aim = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func handle_hotkey(keycode: int) -> bool:
	var focus: Control = get_viewport().gui_get_focus_owner()
	if focus is LineEdit or focus is TextEdit:
		return false
	if not has_active_match:
		return false
	if keycode == KEY_ESCAPE:
		if battle.winner != -1:
			return false
		if shop_visible():
			close_shop()
		elif aim_slot != "" or attack_move_aim:
			_clear_aim()
			hud.show_message("조준을 취소했습니다.", 1.2)
		elif help_visible():
			close_help()
		elif growth_visible():
			close_growth()
		elif paused:
			_resume()
		else:
			paused = true
			_camera_drag = false
			hud.pause_menu.show()
		return true
	if keycode == KEY_P and battle.winner == -1 and not growth_visible() and not help_visible() and not hud.result.visible and not hud.pause_menu.visible:
		open_shop()
		return true
	if keycode == KEY_F1 and battle.winner == -1 and not growth_visible() and not shop_visible():
		open_help()
		return true
	if keycode == KEY_G and not hud.pause_menu.visible and not help_visible() and not shop_visible() and battle.winner == -1:
		open_growth()
		return true
	if not _accepts_commands():
		return false
	match keycode:
		KEY_D: return use_consumable()
		KEY_A: return arm_attack_move()
		KEY_Q: return arm_ability("Q")
		KEY_W: return arm_ability("W")
		KEY_E: return arm_ability("E")
		KEY_R: return arm_ability("R")
		KEY_S:
			_clear_aim()
			selected_target_id = -1
			_destination = null
			battle.command_stop(battle.controlled_id)
			return true
		KEY_B:
			_clear_aim()
			return _move_to(battle.map.spawn_points[0])
		KEY_SPACE:
			_camera_follow = true
			_camera_focus = battle.units[battle.controlled_id].pos
			_update_camera(0)
			return true
	return false


func _resume() -> void:
	if not has_active_match or battle.winner != -1:
		return
	paused = false
	hud.pause_menu.hide()
	hud.growth.hide()
	hud.help_panel.hide()
	hud.shop.hide()


func _accepts_commands() -> bool:
	return has_active_match and not paused and battle.winner == -1 and not hud.selection.visible and not hud.growth.visible and not hud.pause_menu.visible and not hud.result.visible and not help_visible() and not shop_visible()


func ui_blocks_point(point: Vector2) -> bool:
	if not point.is_finite() or not get_viewport().get_visible_rect().has_point(point):
		return true
	return hud.blocks_point(point)


func world_click(screen: Vector2, button: int) -> bool:
	if not _accepts_commands() or ui_blocks_point(screen):
		return false
	var ground: Variant = screen_to_ground(screen)
	if not ground is Vector2:
		return false
	if button == MOUSE_BUTTON_LEFT and attack_move_aim:
		var accepted: bool = battle.command_attack_move(battle.controlled_id, ground)
		if accepted:
			_clear_aim()
			selected_target_id = -1
			_destination = ground
			_destination_left = 1.5
		else:
			_show_error()
		return accepted
	if button == MOUSE_BUTTON_LEFT and aim_slot != "":
		var accepted: bool = battle.command_cast(battle.controlled_id, aim_slot, ground)
		if accepted:
			_clear_aim()
			selected_target_id = -1
			_destination = null
		else:
			_show_error()
		return accepted
	var target: int = pick_visible_target(screen)
	if button == MOUSE_BUTTON_RIGHT:
		_clear_aim()
		if target >= 0:
			selected_target_id = target
			_destination = null
			var accepted: bool = battle.command_attack(battle.controlled_id, target)
			if not accepted:
				_show_error()
			return accepted
		return _move_to(ground)
	if button == MOUSE_BUTTON_LEFT:
		selected_target_id = target
		return true
	return false


func screen_to_ground(screen: Vector2) -> Variant:
	if not screen.is_finite() or not get_viewport().get_visible_rect().has_point(screen):
		return null
	var point: Variant = Plane(Vector3.UP, 0).intersects_ray(camera.project_ray_origin(screen), camera.project_ray_normal(screen))
	if point is Vector3 and point.is_finite():
		return Vector2(point.x, -point.z)
	return null


func pick_visible_target(screen: Vector2) -> int:
	var best_id: int = -1
	var best_distance: float = INF
	var best_priority: int = 100
	var priorities: Dictionary = {"hero": 0, "minion": 1, "tower": 2, "core": 2, "cell": 3, "pin": 4}
	var team: int = int(battle.units[battle.controlled_id].team) if battle.units.has(battle.controlled_id) else 0
	for id: int in battle.units:
		var unit: Dictionary = battle.units[id]
		if not battle.is_attackable_target(team, id):
			continue
		var floor_position := Vector3(unit.pos.x, 0, -unit.pos.y)
		if camera.is_position_behind(floor_position):
			continue
		var foot: Vector2 = camera.unproject_position(floor_position)
		var height: float = 1.6 if unit.kind == "hero" else (2.7 if unit.kind in ["tower", "core"] else 0.7)
		var head: Vector2 = camera.unproject_position(floor_position + Vector3.UP * height)
		var closest: Vector2 = Geometry2D.get_closest_point_to_segment(screen, foot, head)
		var edge: Vector2 = camera.unproject_position(floor_position + Vector3.RIGHT * unit.radius)
		var radius: float = maxf(10.0, foot.distance_to(edge) + 4.0)
		var distance: float = screen.distance_to(closest)
		var priority: int = int(priorities.get(unit.kind, 100))
		if distance <= radius and (priority < best_priority or (priority == best_priority and (distance < best_distance - 0.001 or (absf(distance - best_distance) <= 0.001 and id < best_id)))):
			best_distance = distance
			best_priority = priority
			best_id = id
	return best_id


func _move_to(point: Vector2) -> bool:
	var accepted: bool = battle.command_move(battle.controlled_id, point)
	if accepted:
		selected_target_id = -1
		_destination = point
		_destination_left = 1.5
	else:
		_show_error()
	return accepted


func _on_minimap_point(point: Vector2, button: int) -> void:
	if not _accepts_commands():
		return
	if button == MOUSE_BUTTON_LEFT:
		_camera_follow = false
		_camera_focus = point
		_update_camera(0)
	elif button == MOUSE_BUTTON_RIGHT:
		_clear_aim()
		_move_to(point)


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and not event.ctrl_pressed and not event.alt_pressed and not event.meta_pressed:
		var keycode: int = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		if handle_hotkey(keycode):
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_MIDDLE and not event.pressed:
		_camera_drag = false
	if event is InputEventMouseMotion and _camera_drag and _accepts_commands():
		_camera_follow = false
		var units_per_pixel: float = camera.size / maxf(1, get_viewport().get_visible_rect().size.y)
		_camera_focus += Vector2(-event.relative.x, event.relative.y * 1.35) * units_per_pixel
		_update_camera(0)
		get_viewport().set_input_as_handled()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton or not event.pressed or not _accepts_commands():
		return
	if ui_blocks_point(event.position):
		return
	match event.button_index:
		MOUSE_BUTTON_WHEEL_UP:
			camera.size = clampf(camera.size - 3.0, 24.0, 70.0)
		MOUSE_BUTTON_WHEEL_DOWN:
			camera.size = clampf(camera.size + 3.0, 24.0, 70.0)
		MOUSE_BUTTON_MIDDLE:
			_camera_drag = true
		MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT:
			world_click(event.position, event.button_index)
		_:
			return
	get_viewport().set_input_as_handled()


func _update_camera(delta: float) -> void:
	if _camera_follow and battle.units.has(battle.controlled_id):
		var target: Vector2 = battle.units[battle.controlled_id].pos
		_camera_focus = _camera_focus.lerp(target, minf(1.0, delta * 8.0)) if delta > 0 else target
	_camera_focus.x = clampf(_camera_focus.x, -45.0, 45.0)
	_camera_focus.y = clampf(_camera_focus.y, -27.0, 27.0)
	var look := Vector3(_camera_focus.x, 0, -_camera_focus.y)
	camera.position = look + Vector3(0, 48, 34)
	camera.look_at(look, Vector3.UP)


func _sync_visuals(delta: float) -> void:
	var mouse: Vector2 = get_viewport().get_mouse_position()
	var allow_hover: bool = _accepts_commands() and not ui_blocks_point(mouse) and aim_slot == "" and not attack_move_aim
	vision_view.update_view(camera, 0, delta, allow_hover)
	Input.set_default_cursor_shape(Input.CURSOR_CROSS if (attack_move_aim or aim_slot != "") and _accepts_commands() and not ui_blocks_point(mouse) else Input.CURSOR_ARROW)
	for id: int in _unit_nodes.keys():
		if not battle.units.has(id):
			_unit_nodes[id].queue_free()
			_unit_nodes.erase(id)
	for id: int in battle.units:
		var unit: Dictionary = battle.units[id]
		if not _unit_nodes.has(id):
			_unit_nodes[id] = arena.create_unit(unit, units_view)
		var node: Node3D = _unit_nodes[id]
		# Structure positions/destruction are public. Current enemy HP is not.
		node.visible = unit.alive and (unit.team == 0 or unit.kind in ["tower", "core"] or battle.is_visible(0, id))
		if not node.visible:
			continue
		node.position = Vector3(unit.pos.x, 0, -unit.pos.y)
		var model: Node3D = node.get_node("Model")
		if unit.kind in ["hero", "minion"]:
			model.rotation.y = atan2(-unit.facing.x, unit.facing.y)
			model.position.y = sin(battle.time * 13.0 + id) * 0.035 if unit.order in ["move", "attack_move"] else 0.0
	if selected_target_id >= 0:
		if not battle.units.has(selected_target_id) or not battle.units[selected_target_id].alive or not battle.is_visible(0, selected_target_id):
			selected_target_id = -1
	hud.show_target(battle.units[selected_target_id] if selected_target_id >= 0 else {})
	if _destination_left > 0:
		_destination_left -= delta
		if _destination_left <= 0:
			_destination = null
	var preview: Dictionary = {}
	if aim_slot != "" and _accepts_commands():
		var screen: Vector2 = get_viewport().get_mouse_position()
		var ground: Variant = screen_to_ground(screen)
		if ground is Vector2 and not ui_blocks_point(screen):
			preview = battle.get_cast_preview(battle.controlled_id, aim_slot, ground)
	var aim_destination: Variant = _destination
	if attack_move_aim and _accepts_commands() and not ui_blocks_point(mouse):
		aim_destination = screen_to_ground(mouse)
	effects_view.redraw(battle, preview, selected_target_id, aim_destination)
	hud.unit_overlay.update_feedback(delta if has_active_match and not paused else 0.0)


func _clear_models() -> void:
	for node: Node3D in _unit_nodes.values():
		units_view.remove_child(node)
		node.queue_free()
	_unit_nodes.clear()


func _show_error() -> void:
	var translations: Dictionary = {
		"R requires level 3 and one growth point": "R은 레벨 3부터 성장 1포인트로 해금합니다.",
		"Ability is cooling down": "아직 기술의 재사용 대기 중입니다.",
		"Not enough energy": "에너지가 부족합니다.",
		"Aim outside legal range or terrain / pins not linked": "사거리·지형을 확인하세요. 네마는 핀의 연결도 필요합니다.",
		"Place two linked pins": "서로 연결된 핀 2개가 필요합니다.",
		"Place a pin first": "먼저 Q로 핀을 설치하세요.",
		"Choose a direction": "시전할 방향을 선택하세요.",
		"Finish the current action first": "현재 동작이 끝나면 기술을 사용할 수 있습니다.",
		"Target unavailable, hidden, allied, or locked": "공격할 수 없는 대상입니다. 잠긴 구조물은 앞선 탑을 먼저 파괴하세요.",
		"Growth point unavailable or upgrade locked": "성장 포인트·투자 상한·레벨 조건을 확인하세요.",
		"Match ended or hero defeated": "경기가 끝났거나 영웅이 부활 대기 중입니다.",
		"Stunned": "기절 중에는 명령을 실행할 수 없습니다.",
		"Rooted: movement skill unavailable": "속박 중에는 이동 기술을 사용할 수 없습니다.",
		"Cannot cast now": "지금은 기술을 사용할 수 없습니다.",
	}
	var reason: String = str(battle.last_error)
	hud.show_message(str(translations.get(reason, "이 지점으로 이동하거나 기술을 사용할 수 없습니다.")))
