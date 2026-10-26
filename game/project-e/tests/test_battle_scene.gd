extends SceneTree
## Integration checks use the real state, scene, and command routing.

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists("res://scenes/battlefield.tscn"):
		_check(false, "Playable battlefield scene must exist")
		_finish()
		return
	var packed: PackedScene = load("res://scenes/battlefield.tscn") as PackedScene
	if packed == null:
		_check(false, "Playable battlefield scene must load")
		_finish()
		return
	var scene: Variant = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_check(scene.get_node("Camera3D").current, "Battlefield has an active 3D camera")
	_check(not scene.has_active_match, "Selection is shown before the first match")
	_check(scene.battle.units.size() >= 20, "Scene uses the populated real simulation")
	_check(scene.get_node("Arena").get_child_count() > 20, "Arena is built from real map data")

	scene.start_match("bas", false)
	scene.battle.bots_enabled = false
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	_check(hero.hero == "bas" and hero.level == 1 and hero.points == 2, "Normal Bas starts at level one with two points")
	_check(not hero.r_unlocked, "Normal match preserves the R gate")
	_check(not scene.arm_ability("R"), "Locked R cannot be armed through UI")
	_check(scene.arm_ability("Q"), "Ready Q can enter aiming")
	_check(is_zero_approx(hero.cooldowns.Q) and is_equal_approx(hero.energy, 100), "Aiming alone spends no energy or cooldown")
	scene.handle_hotkey(KEY_ESCAPE)
	_check(scene.aim_slot == "" and not scene.paused, "Escape cancels aim before pausing")
	scene.handle_hotkey(KEY_ESCAPE)
	_check(scene.paused, "Escape pauses when no aim is active")
	var paused_time: float = scene.battle.time
	await physics_frame
	await physics_frame
	_check(is_equal_approx(scene.battle.time, paused_time), "Pause actually freezes simulation time")
	scene.handle_hotkey(KEY_ESCAPE)
	_check(not scene.paused, "Escape resumes a paused match")

	scene.open_growth()
	_check(scene.growth_visible(), "Growth panel can be opened")
	var before_power: float = hero.power
	_check(scene.spend_growth("power"), "Growth button submits a legal investment")
	_check(hero.power > before_power and hero.points == 1, "Investment changes actual simulation stats")
	_check(not scene.spend_growth("R"), "Growth panel cannot bypass level-three R requirement")
	scene.handle_hotkey(KEY_ESCAPE)
	_check(not scene.growth_visible(), "Escape closes growth panel")

	var before_position: Vector2 = hero.pos
	var blocked_point: Vector2 = scene.get_growth_button_rect().get_center()
	_check(scene.ui_blocks_point(blocked_point), "HUD explicitly blocks world input")
	scene.world_click(blocked_point, MOUSE_BUTTON_RIGHT)
	for _i: int in range(5):
		await physics_frame
	_check(hero.pos.distance_to(before_position) < 0.01, "Right click on HUD does not move the hero")
	_check(not scene.world_click(Vector2(-100, -100), MOUSE_BUTTON_RIGHT), "Off-viewport clicks cannot issue world commands")

	var camera: Camera3D = scene.get_node("Camera3D")
	var destination: Vector2 = Vector2(-52, -5)
	var click: Vector2 = camera.unproject_position(Vector3(destination.x, 0, -destination.y))
	_check(scene.world_click(click, MOUSE_BUTTON_RIGHT), "Floor right click routes to move command")
	for _i: int in range(20):
		await physics_frame
	_check(hero.pos.distance_to(before_position) > 0.3, "Floor click advances the real hero")
	scene.handle_hotkey(KEY_S)
	var stopped_at: Vector2 = hero.pos
	for _i: int in range(5):
		await physics_frame
	_check(hero.pos.distance_to(stopped_at) < 0.02, "S stops real movement")

	var energy_before_cast: float = hero.energy
	_check(scene.arm_ability("Q"), "Q can be armed for a confirmed world cast")
	_check(not scene.world_click(blocked_point, MOUSE_BUTTON_LEFT), "Aiming cannot cast through a HUD button")
	_check(scene.aim_slot == "Q" and is_equal_approx(hero.energy, energy_before_cast), "Blocked confirmation keeps aim and resources intact")
	var cast_point: Vector2 = hero.pos + Vector2(2, 0)
	var cast_screen: Vector2 = camera.unproject_position(Vector3(cast_point.x, 0, -cast_point.y))
	_check(scene.world_click(cast_screen, MOUSE_BUTTON_LEFT), "Left click confirms the actual armed ability")
	_check(scene.aim_slot == "" and hero.energy < energy_before_cast and hero.cooldowns.Q > 0, "Accepted cast clears aim and consumes authoritative resources")
	_check(not scene.arm_ability("Q"), "Cooldown prevents immediately rearming the spent skill")
	for _i: int in range(16):
		await physics_frame

	scene.battle.award_xp(hero.id, 100)
	await process_frame
	await process_frame
	_check(scene.hud._xp.text.contains("0 / 125"), "Level-two HUD shows the actual next-level XP requirement: " + scene.hud._xp.text)
	scene.battle.award_xp(hero.id, 125)
	scene.open_growth()
	_check(scene.spend_growth("R") and hero.r_unlocked, "Normal match can unlock R after actual level-three progression")
	scene.handle_hotkey(KEY_ESCAPE)
	_check(scene.arm_ability("R"), "Unlocked R is usable through normal-match aiming")
	scene.handle_hotkey(KEY_ESCAPE)

	var enemy_id: int = -1
	for id: int in scene.battle.units:
		if scene.battle.units[id].team == 1 and scene.battle.units[id].kind == "hero":
			enemy_id = id
			break
	var enemy: Dictionary = scene.battle.units[enemy_id]
	enemy.pos = hero.pos + Vector2(2.4, 0)
	scene.battle.step(1.0 / 30.0)
	await process_frame
	var enemy_screen: Vector2 = camera.unproject_position(Vector3(enemy.pos.x, 0.7, -enemy.pos.y))
	_check(scene.world_click(enemy_screen, MOUSE_BUTTON_RIGHT), "Right-clicking a visible enemy routes an attack order")
	_check(hero.target_id == enemy_id and scene.selected_target_id == enemy_id, "Attack routing selects the actual visible opponent")
	enemy.pos = Vector2(55, 0)
	scene.battle.step(1.0 / 30.0)
	await process_frame
	_check(scene.selected_target_id == -1 and not scene.hud._target.visible, "Losing vision clears target selection and the enemy status panel")
	_check(not scene.get_node("Units/Unit_%d" % enemy_id).visible, "Enemy model is hidden immediately outside allied vision")

	var text_input := LineEdit.new()
	scene.hud.root_control.add_child(text_input)
	text_input.grab_focus()
	_check(not scene.handle_hotkey(KEY_E) and scene.aim_slot == "", "Typing focus does not also arm a game skill")
	text_input.queue_free()
	await process_frame

	for key: String in ["rio", "nema"]:
		scene.start_match(key, true)
		scene.battle.bots_enabled = false
		var practiced: Dictionary = scene.battle.units[scene.battle.controlled_id]
		_check(practiced.hero == key and practiced.level == 3 and practiced.r_unlocked, "Practice selection unlocks actual " + key + " R")
		_check(scene.aim_slot == "" and scene.selected_target_id == -1, "Restart clears aiming and previous target")
		_check(scene.is_practice, "Practice conditions remain explicitly identified")

	var shown: Array = scene.minimap.visible_unit_ids()
	for id: int in shown:
		var unit: Dictionary = scene.battle.units[id]
		_check(unit.team == 0 or unit.kind in ["tower", "core"] or scene.battle.is_visible(0, id), "Minimap never shows a hidden nonpublic enemy")
	var east_core: int = -1
	for id: int in scene.battle.units:
		if scene.battle.units[id].kind == "core" and scene.battle.units[id].team == 1:
			east_core = id
	_check(east_core in shown and not scene.battle.is_visible(0, east_core), "Known enemy core position remains public without exposing its live HP")

	# A friendly basic projectile tracks an enemy and must not reveal its hidden path.
	# An own skill projectile has a known trajectory and may remain observable.
	scene.paused = true
	scene.battle.projectiles = [{"kind": "basic", "team": 0, "pos": Vector2(54, 0)}]
	scene.get_node("Effects").redraw(scene.battle, {}, -1, null)
	var hidden_bounds: AABB = scene.get_node("Effects").mesh.get_aabb()
	_check(hidden_bounds.end.x < 50, "Friendly basic projectile geometry does not track hidden enemies through fog")
	scene.battle.projectiles = [{"kind": "rio_disc", "team": 0, "pos": Vector2(54, 0)}]
	scene.get_node("Effects").redraw(scene.battle, {}, -1, null)
	var known_bounds: AABB = scene.get_node("Effects").mesh.get_aabb()
	_check(known_bounds.end.x > 53, "The player's known skill trajectory remains visible")
	scene.battle.projectiles.clear()
	scene.paused = false
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "core":
			unit.hp = 0
			unit.alive = false
	scene.battle.step(1.0 / 30.0)
	await process_frame
	_check(scene.battle.winner == 2 and scene.hud.result.visible, "Simultaneous core destruction opens the actual draw result")
	_check(scene.paused and not scene.world_click(cast_screen, MOUSE_BUTTON_RIGHT), "Result modal prevents post-match world commands")
	scene.restart_match()
	_check(scene.battle.winner == -1 and not scene.paused and not scene.hud.result.visible, "Restart clears the result and resumes a fresh real match")
	_test_persistent_cues(scene.get_node("Effects"))

	scene.return_to_selection()
	_check(not scene.has_active_match and scene.selection_visible(), "Return to selection closes the match")
	scene.queue_free()
	await process_frame
	_finish()


func _test_persistent_cues(view: MeshInstance3D) -> void:
	# Real casts leave devices after their short impact visuals have expired.
	var state: Variant = _cue_state("nema")
	var owner: Dictionary = state.units[state.controlled_id]
	_check(state.command_cast(owner.id, "Q", Vector2(-2, 0)), "Persistent-link fixture accepts its first real pin cast")
	state.step(2.7)
	_check(state.command_cast(owner.id, "Q", Vector2(2, 0)), "Persistent-link fixture accepts its second real pin cast")
	state.step(0.8)
	_check(state.effects.is_empty() and owner.pins.size() == 2, "Both pins outlive the transient Q effects")
	view.redraw(state, {}, -1, null)
	var bounds: AABB = _ground_bounds(view)
	_check(_ground_vertices(view).size() > 6 and bounds.position.x <= -1.99 and bounds.end.x >= 1.99, "Live Nema pins retain a ground connection after cast effects expire")
	_check(is_equal_approx(bounds.size.z, 0.5), "Persistent Nema connection shows its authoritative 0.5m passive width")
	state.remove_pin(owner.pins[0])
	view.redraw(state, {}, -1, null)
	_check(_ground_vertices(view).is_empty(), "Losing either pin removes the persistent connection")
	state.spawn_pin(owner, Vector2(-2, 0))
	state.apply_damage(_enemy_hero(state, "bas"), owner.id, 10000, state.next_action_id())
	view.redraw(state, {}, -1, null)
	_check(not owner.alive and owner.pins.is_empty() and _ground_vertices(view).is_empty(), "Owner death removes both pins and their persistent connection")

	state = _cue_state("rio")
	owner = state.units[state.controlled_id]
	_check(state.command_cast(owner.id, "W", Vector2(3, 0)), "Persistent-mark fixture casts actual Rio W")
	state.step(0.8)
	_check(state.effects.is_empty() and not owner.return_mark.is_empty(), "Rio return mark remains after its impact effect expires")
	view.redraw(state, {}, -1, null)
	var early_vertices: int = _ground_vertices(view).size()
	_check(early_vertices > 20 and _ground_bounds(view).position.x > 2.0, "Active Rio W has a persistent ground ring at the authoritative mark")
	state.step(0.6)
	view.redraw(state, {}, -1, null)
	_check(not _ground_vertices(view).is_empty() and _ground_vertices(view).size() < early_vertices, "Return-mark timing arc shrinks with authoritative remaining lifetime")
	state.step(1.0)
	view.redraw(state, {}, -1, null)
	_check(owner.return_mark.is_empty() and _ground_vertices(view).is_empty(), "Expired return marks leave no stale ground ring")

	state = _cue_state("rio")
	owner = state.units[state.controlled_id]
	state.command_cast(owner.id, "Q", Vector2(8, 0))
	state.step(0.35)
	state.command_cast(owner.id, "W", Vector2(3, 0))
	state.step(0.7)
	_check(state.projectiles.size() == 1 and state.projectiles[0].phase == "return" and owner.return_mark.is_empty(), "Real returning disc consumes W and fixes the return destination")
	view.redraw(state, {}, -1, null)
	bounds = _ground_bounds(view)
	_check(_ground_vertices(view).size() > 6 and bounds.position.x > 2.6 and bounds.position.x < 3.1 and bounds.end.x > 7.0, "Returning disc draws a ground route and endpoint while the consumed W ring is gone")
	owner.pos = Vector2(-2, 0)
	view.redraw(state, {}, -1, null)
	_check(is_equal_approx(_ground_bounds(view).position.x, bounds.position.x), "Moving Rio cannot move the already fixed return endpoint cue")
	state.apply_damage(_enemy_hero(state, "bas"), owner.id, 10000, state.next_action_id())
	state.step(1.0 / 30.0)
	view.redraw(state, {}, -1, null)
	_check(state.projectiles.is_empty() and _ground_vertices(view).is_empty(), "Rio death removes the disc and its persistent route")

	# Enemy devices can be observed independently from their hidden owner.
	state = _cue_state("bas")
	owner = state.units[_enemy_hero(state, "nema")]
	owner.pos = Vector2(30, 0)
	state.spawn_pin(owner, Vector2(4, 0))
	state.spawn_pin(owner, Vector2(8, 0))
	_check(not state.is_point_visible(0, owner.pos) and state.is_point_visible(0, Vector2(4, 0)) and state.is_point_visible(0, Vector2(8, 0)), "Enemy-link fixture sees both pins but not their owner")
	view.redraw(state, {}, -1, null)
	bounds = _ground_bounds(view)
	_check(_ground_vertices(view).size() > 6 and bounds.position.x <= 4.01 and bounds.end.x >= 7.99, "Visible enemy pin connection is drawn even when Nema is hidden")
	state.units[owner.pins[0]].pos = Vector2(11, 0)
	state.units[owner.pins[1]].pos = Vector2(19, 0)
	view.redraw(state, {}, -1, null)
	bounds = _ground_bounds(view)
	_check(not _ground_vertices(view).is_empty() and bounds.position.x > 10.9 and bounds.end.x <= 12.001, "Persistent enemy connection keeps visible segments and conceals the hidden endpoint")
	_check(_ground_is_visible(state, view), "Every rendered enemy connection triangle stays within allied vision")
	var link: Dictionary = state.get_pin_link(owner.id)
	state.remove_pin(owner.pins[0])
	state.effects = [link]
	view.redraw(state, {}, -1, null)
	bounds = _ground_bounds(view)
	_check(not _ground_vertices(view).is_empty() and bounds.end.x <= 12.001 and _ground_is_visible(state, view), "Transient enemy line with visible origin also clips its hidden endpoint and segments")
	link.origin = Vector2(19, 0)
	link.target = Vector2(11, 0)
	view.redraw(state, {}, -1, null)
	_check(not _ground_vertices(view).is_empty() and _ground_is_visible(state, view), "Visible end of an enemy line remains readable even when its origin is hidden")

	# Two visible ends must not bridge an unobserved interval between observers.
	state.effects.clear()
	state.spawn_pin(owner, Vector2(9, 0))
	state.units[owner.pins[0]].pos = Vector2(17, 0)
	for hero: Dictionary in state.units.values():
		if hero.team == 0 and hero.id != state.controlled_id:
			hero.pos = Vector2(26, 0)
			break
	owner.pos = Vector2(45, 0)
	view.redraw(state, {}, -1, null)
	_check(not _ground_vertices(view).is_empty() and _ground_bounds(view).size.x > 7.9 and _ground_is_visible(state, view), "Enemy link can show two observed pieces without drawing across their hidden middle")

	state = _cue_state("bas")
	owner = state.units[_enemy_hero(state, "rio")]
	owner.pos = Vector2(30, 0)
	owner.return_mark = {"pos": Vector2(20, 0), "expires": state.time + 1.4}
	view.redraw(state, {}, -1, null)
	_check(_ground_vertices(view).is_empty(), "Hidden enemy return mark does not reveal its ground position")
	owner.return_mark.pos = Vector2(11, 0)
	view.redraw(state, {}, -1, null)
	_check(not _ground_vertices(view).is_empty() and _ground_is_visible(state, view), "Observed enemy return mark is visible independently of its hidden owner")
	owner.return_mark.clear()
	state.projectiles = [{"kind": "rio_disc", "owner_id": owner.id, "team": 1, "pos": Vector2(11, 0), "target_pos": Vector2(19, 0), "phase": "return"}]
	view.redraw(state, {}, -1, null)
	_check(not _ground_vertices(view).is_empty() and _ground_bounds(view).end.x <= 12.001 and _ground_is_visible(state, view), "Enemy disc route reveals visible portions without exposing its hidden return endpoint")
	state.projectiles[0].pos = Vector2(19, 0)
	state.projectiles[0].target_pos = Vector2(11, 0)
	view.redraw(state, {}, -1, null)
	_check(not _ground_vertices(view).is_empty() and _ground_is_visible(state, view), "An observed return endpoint remains readable when the enemy disc is hidden")
	state.projectiles.clear()
	view.redraw(state, {}, -1, null)
	_check(_ground_vertices(view).is_empty(), "Removing the disc removes all of its ground route geometry")


func _cue_state(hero_key: String) -> Variant:
	var state: Variant = load("res://scripts/battle/battle_state.gd").new()
	state.reset(hero_key, true)
	state.bots_enabled = false
	for id: int in state.units.keys():
		var unit: Dictionary = state.units[id]
		if unit.kind != "hero":
			state.units.erase(id)
		else:
			unit.pos = Vector2(-56, 0) if unit.team == 0 else Vector2(56, 0)
	state.units[state.controlled_id].pos = Vector2.ZERO
	return state


func _enemy_hero(state: Variant, hero_key: String) -> int:
	for id: int in state.units:
		if state.units[id].team == 1 and state.units[id].hero == hero_key:
			return id
	return -1


func _ground_vertices(view: MeshInstance3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	var faces: PackedVector3Array = view.mesh.get_faces()
	for index: int in range(0, faces.size(), 3):
		var a: Vector3 = faces[index]
		var b: Vector3 = faces[index + 1]
		var c: Vector3 = faces[index + 2]
		if maxf(a.y, maxf(b.y, c.y)) < 0.2 and (b - a).cross(c - a).length_squared() > 0.000000001:
			result.append_array(PackedVector3Array([a, b, c]))
	return result


func _ground_bounds(view: MeshInstance3D) -> AABB:
	var vertices: PackedVector3Array = _ground_vertices(view)
	if vertices.is_empty():
		return AABB()
	var result := AABB(vertices[0], Vector3.ZERO)
	for vertex: Vector3 in vertices:
		result = result.expand(vertex)
	return result


func _ground_is_visible(state: Variant, view: MeshInstance3D) -> bool:
	var vertices: PackedVector3Array = _ground_vertices(view)
	for index: int in range(0, vertices.size(), 3):
		var a := Vector2(vertices[index].x, -vertices[index].z)
		var b := Vector2(vertices[index + 1].x, -vertices[index + 1].z)
		var c := Vector2(vertices[index + 2].x, -vertices[index + 2].z)
		for point: Vector2 in [a, b, c, (a + b) * 0.5, (b + c) * 0.5, (c + a) * 0.5, (a + b + c) / 3.0]:
			if not state.is_point_visible(0, point):
				return false
	return true


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)


func _finish() -> void:
	print("Battle scene: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
