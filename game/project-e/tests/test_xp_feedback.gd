extends SceneTree
## Real rewards, creation-time fog authorization, and the real HUD consume the same events.

const StateScript = preload("res://scripts/battle/battle_state.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_sharing()
	_test_level_cap()
	_test_spawns()
	_test_event_retention()
	if not ResourceLoader.exists("res://scripts/presentation/xp_feedback_view.gd"):
		_check(false, "R29 observable XP feedback view exists")
	else:
		await _test_visibility_and_lifecycle()
		await _test_scene()
	print("XP feedback: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _fixture() -> Variant:
	var state: Variant = StateScript.new()
	state.reset("bas", false)
	state.bots_enabled = false
	state._next_wave = INF
	state._next_ai = INF
	state._next_income = INF
	for id: int in state.units.keys():
		var unit: Dictionary = state.units[id]
		if unit.kind != "hero":
			state.units.erase(id)
		else:
			unit.pos = Vector2(-50 if unit.team == 0 else 50, 0)
	state.units[state.controlled_id].pos = Vector2.ZERO
	return state


func _allies(state: Variant) -> Array:
	return state.units.values().filter(func(unit: Dictionary) -> bool: return unit.team == 0)


func _cell(state: Variant, position: Vector2, reward: float = 40.0) -> Dictionary:
	var cell: Dictionary = state._entity("cell", 2, position, 180.0, 0.55)
	cell.xp_reward = reward
	cell.cell_tier = "high" if reward == 40.0 else "medium"
	return cell


func _events(state: Variant, kind: String) -> Array:
	return state.events.filter(func(event: Dictionary) -> bool: return event.type == kind)


func _feedback(state: Variant) -> Array:
	var result: Variant = state.get("feedback_events")
	return result if result is Array else []


func _kill_cell(state: Variant, cell: Dictionary) -> void:
	state.apply_damage(state.controlled_id, cell.id, 10000.0, state.next_action_id())


func _test_sharing() -> void:
	var state: Variant = _fixture()
	var allies: Array = _allies(state)
	allies[0].pos = Vector2.ZERO
	allies[1].pos = Vector2(1, 0)
	var cell: Dictionary = _cell(state, Vector2(2, 0))
	_kill_cell(state, cell)
	var gains: Array = _events(state, "xp_gain")
	_check(gains.size() == 2, "one real 40 XP cell kill emits exactly two personal grants")
	for unit: Dictionary in [allies[0], allies[1]]:
		_near(unit.xp, 20.0, "two recipients really receive 20 XP each")
		_near(unit.credits, 105.0, "credit sharing remains five per eligible recipient")
	for event: Dictionary in gains:
		_near(float(event.get("amount", -1)), 20.0, "feedback reports actual individual XP rather than object reward")
		_check(event.get("share_count", 0) == 2 and event.get("source_kind", "") == "cell", "cell grants explain the actual shared recipient count")
		_check(not event.has("source_pos") and not event.has("source_id"), "personal grant contains no hidden source location or identifier")
		_check(event.get("pos", Vector2.INF) == state.units[event.target_id].pos, "reward position belongs to the recipient")
	_kill_cell(state, cell)
	_check(_events(state, "xp_gain").size() == gains.size(), "already defeated cell cannot duplicate XP feedback")

	state = _fixture()
	allies = _allies(state)
	for index: int in range(3):
		allies[index].pos = Vector2(index, 0)
	cell = _cell(state, Vector2(2, 0))
	_kill_cell(state, cell)
	gains = _events(state, "xp_gain")
	_check(gains.size() == 3, "three-way sharing generates one real award per recipient")
	var total: float = 0.0
	for event: Dictionary in gains:
		total += float(event.amount)
		_near(float(event.amount), 40.0 / 3.0, "nonintegral awards retain full precision")
	_near(total, 40.0, "unrounded feedback grants conserve the full cell reward")

	state = _fixture()
	allies = _allies(state)
	allies[0].pos = Vector2.ZERO
	allies[1].pos = Vector2(14, 0)
	allies[2].pos = Vector2(14.01, 0)
	cell = _cell(state, Vector2.ZERO)
	_kill_cell(state, cell)
	_check(_events(state, "xp_gain").size() == 2, "14m boundary is eligible but 14.01m is excluded")
	_near(allies[2].xp, 0.0, "distant ally receives neither XP nor a grant event")
	state = _fixture()
	allies = _allies(state)
	allies[1].pos = Vector2.ZERO
	allies[1].alive = false
	_kill_cell(state, _cell(state, Vector2.ZERO))
	_near(allies[0].xp, 40.0, "dead ally does not dilute living recipient XP")
	_check(_events(state, "xp_gain").size() == 1, "dead ally gets no shared reward notification")


func _test_level_cap() -> void:
	var state: Variant = _fixture()
	var hero: Dictionary = state.units[state.controlled_id]
	hero.xp = 90.0
	state.award_xp(hero.id, 20.0)
	_check(hero.level == 2 and hero.points == 3, "real threshold crossing still grants one growth point")
	_near(hero.xp, 10.0, "XP remainder survives threshold crossing")
	var gains: Array = _events(state, "xp_gain")
	_check(gains.size() == 1, "threshold crossing emits a single personal grant")
	if not gains.is_empty():
		var event: Dictionary = gains[0]
		_near(float(event.get("amount", -1)), 20.0, "award is not incorrectly computed as a negative gauge delta")
		_check(event.get("level_before", 0) == 1 and event.get("level_after", 0) == 2 and event.get("points_gained", 0) == 1, "grant snapshot carries actual level and growth deltas")
	state.award_xp(hero.id, 275.0)
	_check(hero.level == 4 and hero.points == 5, "one award can cross two levels without losing growth points")
	gains = _events(state, "xp_gain")
	if not gains.is_empty():
		_check(gains.back().get("points_gained", 0) == 2, "multi-level grant explains both points in one snapshot")

	state = _fixture()
	hero = state.units[state.controlled_id]
	hero.level = 11
	hero.xp = 340.0
	state.award_xp(hero.id, 40.0)
	_check(hero.level == 12 and is_zero_approx(hero.xp), "level cap retains the existing zero-remainder rule")
	gains = _events(state, "xp_gain")
	_check(gains.size() == 1, "last progression award emits once")
	if not gains.is_empty():
		_near(float(gains[0].get("amount", -1)), 10.0, "level cap reports only ten applied XP, not discarded overflow")
	state.award_xp(hero.id, 40.0)
	_check(_events(state, "xp_gain").size() == gains.size(), "already capped hero gets no fictitious XP popup")
	var credits_before: float = hero.credits
	_kill_cell(state, _cell(state, Vector2.ZERO))
	_near(hero.credits, credits_before + 10.0, "level cap does not remove existing credit eligibility")
	_check(_events(state, "xp_gain").size() == gains.size(), "capped cell recipient still gets no XP event")

	state = _fixture()
	hero = state.units[state.controlled_id]
	for amount: float in [0.0, -1.0, INF, NAN]:
		state.award_xp(hero.id, amount)
	state.award_xp(-999, 20.0)
	_check(_events(state, "xp_gain").is_empty() and is_zero_approx(hero.xp), "invalid awards change neither progression nor feedback")


func _spawn_cells(state: Variant) -> void:
	state.time = 30.0 - 1.0 / 30.0
	state.step(1.0 / 30.0)


func _test_spawns() -> void:
	var state: Variant = _fixture()
	var hero: Dictionary = state.units[state.controlled_id]
	hero.pos = Vector2(-18, 24)
	_spawn_cells(state)
	var spawns: Array = _events(state, "cell_spawn")
	_check(spawns.size() == 6, "first 30-second spawn records every cell exactly once")
	var high: Dictionary = {}
	for unit: Dictionary in state.units.values():
		if unit.kind == "cell" and unit.pos == Vector2(-18, 24):
			high = unit
	for event: Dictionary in spawns:
		_near(float(event.time), 30.0, "initial spawn event uses simulation time")
		_check(not event.get("is_respawn", true), "initial appearance is not marked as a respawn")
		if event.target_id == high.get("id", -1):
			_check(0 in event.get("visible_to", []), "creation snapshot authorizes the observing high-ground team")
		else:
			_check(0 not in event.get("visible_to", []), "creation snapshot conceals distant or occluded cells")
	_check(not high.is_empty(), "real high-ground cell exists")
	if high.is_empty():
		return
	_kill_cell(state, high)
	state.step(44.9)
	_check(not high.alive, "cell does not respawn before its 45-second cooldown")
	state.step(0.2)
	var renewed: Array = _events(state, "cell_spawn").filter(func(event: Dictionary) -> bool: return event.get("is_respawn", false))
	_check(renewed.size() == 1 and high.alive, "actual respawn emits one new appearance event")
	if not renewed.is_empty():
		_check(renewed[0].target_id == high.id and 0 in renewed[0].get("visible_to", []), "respawn reuses the cell but records fresh visibility")
		_near(float(renewed[0].time), 75.0, "respawn timestamp follows the unchanged cooldown")


func _test_event_retention() -> void:
	var state: Variant = _fixture()
	state.award_xp(state.controlled_id, 20.0)
	for _index: int in range(200):
		state.log_event("damage", "unrelated combat")
	var rewards: Array = _feedback(state)
	_check(rewards.size() == 1 and rewards[0].get("amount", 0) == 20.0, "damage burst cannot evict the recent personal reward")
	for _index: int in range(200):
		state.award_xp(state.controlled_id, 0.01)
	_check(_feedback(state).size() == 128 and state.events.size() <= 96, "feedback and general event buffers remain bounded")


func _view(state: Variant) -> Variant:
	var view: Variant = load("res://scripts/presentation/xp_feedback_view.gd").new()
	root.add_child(view)
	view.battle = state
	view.enabled = true
	return view


func _cues(view: Variant, kind: String) -> Array:
	return view.cues.filter(func(cue: Dictionary) -> bool: return cue.kind == kind)


func _test_visibility_and_lifecycle() -> void:
	var state: Variant = _fixture()
	_spawn_cells(state)
	var view: Variant = _view(state)
	view.update_feedback(0.0)
	_check(_cues(view, "spawn").is_empty(), "hidden creation has no visible spawn pulse")
	state.units[state.controlled_id].pos = Vector2(-18, 24)
	view.update_feedback(0.0)
	_check(_cues(view, "spawn").is_empty(), "later reveal does not replay a hidden spawn")
	view.queue_free()
	await process_frame

	state = _fixture()
	state.units[state.controlled_id].pos = Vector2(-18, 24)
	_spawn_cells(state)
	view = _view(state)
	view.update_feedback(0.0)
	_check(_cues(view, "spawn").size() == 1, "visible high-ground creation gets one pulse")
	view.update_feedback(0.0)
	_check(_cues(view, "spawn").size() == 1, "repeated render never duplicates the event")
	state.units[state.controlled_id].pos = Vector2(-18, 18)
	view.update_feedback(0.0)
	_check(_cues(view, "spawn").is_empty(), "losing high-ground vision removes an active pulse")
	state.units[state.controlled_id].pos = Vector2(-18, 24)
	view.update_feedback(0.0)
	_check(_cues(view, "spawn").is_empty(), "reacquiring vision does not replay a removed pulse")

	state.award_xp(state.controlled_id, 40.0 / 3.0)
	view.update_feedback(0.0)
	var gain: Array = _cues(view, "gain")
	_check(gain.size() == 1, "personal reward creates one recipient cue")
	if not gain.is_empty():
		_check(view.reward_text(gain[0]).contains("13.33") and view.reward_text(gain[0]).contains("≈"), "fractional display explicitly identifies rounding")
		_check(view.cue_world_position(gain[0]).y > 2.4, "reward projection stands above high ground")
		var life: float = gain[0].life
		view.update_feedback(0.0)
		_near(_cues(view, "gain")[0].life, life, "paused rendering preserves feedback lifetime")
	var enemy_id: int = -1
	for unit: Dictionary in state.units.values():
		if unit.team == 1:
			enemy_id = unit.id
			break
	state.award_xp(enemy_id, 100.0)
	view.update_feedback(0.0)
	_check(_cues(view, "gain").size() == 1, "enemy XP and level gains never create local cues")
	state.reset("bas", false)
	state.award_xp(state.controlled_id, 5.0)
	view.update_feedback(0.0)
	gain = _cues(view, "gain")
	_check(gain.size() == 1 and gain[0].amount == 5.0, "match serial prevents stale/reused-sequence feedback after reset")
	view.update_feedback(4.0)
	_check(view.cues.is_empty(), "cue lifetime expires without permanent overlays")
	view.queue_free()
	await process_frame


func _test_scene() -> void:
	var packed: PackedScene = load("res://scenes/battlefield.tscn")
	var scene: Variant = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.start_match("bas", false)
	scene.paused = true
	scene.battle.bots_enabled = false
	var feedback: Variant = scene.hud.unit_overlay.get_node_or_null("XPFeedback")
	_check(feedback != null, "actual battlefield installs the XP feedback Control")
	if feedback != null:
		_check(feedback.mouse_filter == Control.MOUSE_FILTER_IGNORE, "new overlay cannot swallow movement or attack clicks")
		var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
		hero.xp = 90.0
		scene.battle.award_xp(hero.id, 20.0)
		scene.hud.update_state(scene.battle, "", false)
		scene.hud.unit_overlay.update_feedback(0.0)
		_check(scene.hud._xp.text.contains("10 / 125"), "existing HUD still displays actual post-level progression")
		_near(feedback.progression_ratio(), 0.08, "new meter uses actual level-two requirement")
		var gains: Array = _cues(feedback, "gain")
		_check(gains.size() == 1 and feedback.reward_text(gains[0]).contains("G"), "level notification explains growth action")
		scene.battle.award_xp(hero.id, 115.0)
		scene.hud.unit_overlay.update_feedback(0.0)
		gains = _cues(feedback, "gain")
		_check(not hero.r_unlocked and feedback.reward_text(gains.back()).contains("R"), "level three explains R eligibility without automatically unlocking it")
		var old_size: Vector2i = root.size
		for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = dimensions
			await process_frame
			await process_frame
			scene.hud.unit_overlay.update_feedback(0.0)
			var meter: Rect2 = feedback.progress_rect()
			_check(meter.size.x > 0 and meter.position.y >= 0 and meter.end.y <= root.get_visible_rect().size.y, "XP meter stays inside the actual viewport")
			_check(not meter.intersects(scene.hud.growth_button.get_global_rect()), "XP meter does not cover the growth button")
		root.size = old_size
		scene.restart_match()
		scene.paused = true
		scene.hud.unit_overlay.update_feedback(0.0)
		_check(feedback.cues.is_empty(), "real restart clears reward and level cues")
		scene.return_to_selection()
		scene.hud.unit_overlay.update_feedback(0.0)
		_check(not feedback.enabled, "hero selection screen never displays match reward feedback")
	scene.queue_free()
	await process_frame


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.0001, "%s (%.6f vs %.6f)" % [label, actual, expected])


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
