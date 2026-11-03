extends SceneTree
const State = preload("res://scripts/battle/battle_state.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_check(scene.has_method("open_review_lab"), "real battlefield exposes an isolated integrated review lab")
	if not scene.has_method("open_review_lab"):
		scene.queue_free()
		await process_frame
		_finish()
		return
	scene.start_match("bas", true)
	scene.battle.bots_enabled = false
	scene.paused = true
	var original_time: float = scene.battle.time
	var original_hero: Dictionary = scene.battle.units[scene.battle.controlled_id].duplicate(true)
	scene.open_review_lab()
	await process_frame
	var lab: Variant = scene.review_lab
	_check(lab != null and is_instance_valid(lab), "review opens inside the actual main scene")
	_check(lab.stage.battle != scene.battle, "review has an independent authority instance")
	for key: String in ["bas", "rio", "nema"]:
		lab.select_hero(key)
		var hero: Dictionary = lab.stage.battle.units[lab.stage.battle.controlled_id]
		var rig: Variant = lab.stage._unit_nodes[hero.id].get_node("Model/HeroRig")
		var anim: AnimationPlayer = rig.get_node_or_null("AnimationPlayer")
		_check(anim != null, key + " has a real animation library")
		if anim == null: continue
		for clip: String in ["idle", "walk", "basic", "Q", "W", "E", "R", "hit", "death", "respawn"]:
			_check(anim.has_animation(clip), key + " has " + clip + " clip")
			if anim.has_animation(clip):
				_check(anim.get_animation(clip).get_track_count() >= 3, key + "/" + clip + " drives joints rather than a label")
		var authority_before: Dictionary = hero.duplicate(true)
		rig.pose(hero, lab.stage.battle.time)
		_check(hero == authority_before, "posing " + key + " never changes authoritative state")
		var poses: Array = []
		for slot: String in ["Q", "W", "E", "R"]:
			_check(lab.play_action(slot), key + " " + slot + " routes a valid real cast")
			hero = lab.stage.battle.units[lab.stage.battle.controlled_id]
			_check(str(hero.cast.get("slot", "")) == slot, "actual authority records " + key + slot)
			_check(hero.energy < hero.max_energy and hero.cooldowns[slot] > 0, "review cast still consumes authority energy and cooldown")
			lab.advance_review(float(hero.cast.windup) * 0.5)
			rig = lab.stage._unit_nodes[hero.id].get_node("Model/HeroRig")
			poses.append([rig.get_node("LeftArm").rotation, rig.get_node("RightArm").rotation, rig.get_node("Torso").rotation])
		for i: int in range(poses.size()):
			for j: int in range(i + 1, poses.size()):
				_check(poses[i] != poses[j], key + " skills have distinct actual joint poses")
		_check(lab.play_action("hit"), key + " receives a real hit")
		lab.advance_review(0.06)
		hero = lab.stage.battle.units[lab.stage.battle.controlled_id]
		_check(hero.hp < hero.max_hp, "hit decreases authoritative HP")
		_check(lab.play_action("death"), key + " enters real death")
		lab.advance_review(0.25)
		hero = lab.stage.battle.units[lab.stage.battle.controlled_id]
		_check(not hero.alive, "death is not only an animation")
		_check(lab.stage._unit_nodes[hero.id].visible, "observed death remains visible for its short animation")
		_check(lab.play_action("respawn"), "respawn action available")
		lab.advance_review(0.10)
		hero = lab.stage.battle.units[lab.stage.battle.controlled_id]
		_check(hero.alive, "respawn returns a live authoritative hero")
	lab.select_hero("bas")
	lab.play_action("hill")
	var reached_high: bool = false
	var seen_intermediate: bool = false
	for i: int in range(180):
		lab.advance_review(1.0 / 30.0)
		var hero: Dictionary = lab.stage.battle.units[lab.stage.battle.controlled_id]
		var y: float = lab.stage.battle.map.ground_height(hero.pos)
		var foot: float = lab.stage._unit_nodes[hero.id].position.y
		_check(absf(foot - y) < 0.01, "hill animation feet use the authority height")
		reached_high = reached_high or y > 2.35
		seen_intermediate = seen_intermediate or (y > 0.1 and y < 2.3)
	_check(reached_high and seen_intermediate, "real path traverses low ground, ramp and plateau")
	lab.set_map_view(true)
	_check(lab.map_view and lab.stage.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "map inspection uses a stable overview")
	_check(scene.battle.time == original_time and scene.battle.units[scene.battle.controlled_id] == original_hero, "all reviews leave original match untouched")
	lab.close_review()
	await process_frame
	_check(scene.paused and scene.review_lab == null, "exit restores original paused state")
	scene.paused = false
	scene.open_review_lab()
	await process_frame
	scene.review_lab.close_review()
	await process_frame
	_check(not scene.paused, "exit restores a previously running match")
	scene.queue_free()
	await process_frame
	_finish()
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
func _finish() -> void:
	print("Integrated V2: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
