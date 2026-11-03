extends SceneTree
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.start_match("bas", true)
	scene.paused = true
	scene.battle.bots_enabled = false
	_check(scene.has_node("SkillVFX"), "main scene integrates kit-specific skill VFX")
	_check(scene.arena.has_node("TerrainRelief"), "real map has height-field aligned cliff and ramp supports")
	if not scene.has_node("SkillVFX") or not scene.arena.has_node("TerrainRelief"):
		scene.queue_free()
		await process_frame
		_finish()
		return
	scene.open_review_lab()
	await process_frame
	var lab: Variant = scene.review_lab
	lab.running = false
	for key: String in ["bas", "rio", "nema"]:
		lab.select_hero(key)
		for slot: String in ["Q", "W", "E", "R"]:
			_check(lab.play_action(slot), "visual fixture accepts " + key + slot)
			var hero: Dictionary = lab.stage.battle.units[lab.stage.battle.controlled_id]
			lab.advance_review(float(hero.cast.windup) + 0.05)
			var vfx: Variant = lab.stage.get_node("SkillVFX")
			_check(vfx.rendered_points.size() > 0, "active " + key + slot + " draws actual kit geometry")
			for point: Vector2 in vfx.rendered_points:
				_check(lab.stage.battle.is_point_visible(0, point), "every added effect sample respects current team sight")
	lab.close_review()
	await process_frame
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-3, 0)
	var enemy: Dictionary = {}
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "hero" and unit.team == 1:
			enemy = unit
			break
	enemy.pos = Vector2(4, 0)
	enemy.protected = 0
	scene.battle._visibility_cache.clear()
	scene._sync_visuals(0)
	scene.battle.apply_damage(hero.id, enemy.id, 99999, scene.battle.next_action_id())
	scene._sync_visuals(0)
	_check(scene._unit_nodes[enemy.id].visible, "observed enemy death has a short visible fall")
	for unit: Dictionary in scene.battle.units.values():
		if unit.team == 0 and unit.kind in ["hero", "minion"]: unit.pos = Vector2(-55, 0)
	# Fixed structures are far from the fixture; no friendly observer remains.
	scene.battle._visibility_cache.clear()
	scene._sync_visuals(0)
	_check(not scene.battle.is_point_visible(0, enemy.pos), "fixture removes all allied observers including towers")
	_check(not scene._unit_nodes[enemy.id].visible, "death animation vanishes immediately when its sight is lost")
	hero.pos = Vector2(-3, 0)
	scene.battle._visibility_cache.clear()
	scene._sync_visuals(0)
	_check(not scene._unit_nodes[enemy.id].visible, "regaining sight does not replay discarded enemy death")
	scene.battle.effects = [{"shape":"circle", "origin":Vector2(54, 25), "target":Vector2(54, 25), "radius":2.0, "telegraph":false, "owner_id":enemy.id, "team":1, "remaining":0.2, "duration":0.22, "slot":"Q"}]
	scene.get_node("SkillVFX").refresh(scene.battle)
	_check(scene.get_node("SkillVFX").rendered_points.is_empty(), "new effects do not reveal an unobserved remote cast")
	scene.queue_free()
	await process_frame
	_finish()
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _finish() -> void:
	print("V2 visual contract: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
