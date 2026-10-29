extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.start_match("bas", true)
	scene.battle.bots_enabled = false
	scene.paused = true
	_check(scene.has_method("set_camera_mode"), "real playable scene exposes combat and review camera presets")
	if not scene.has_method("set_camera_mode"):
		scene.queue_free()
		await process_frame
		_finish()
		return
	var cam: Camera3D = scene.get_node("Camera3D")
	scene.set_camera_mode("combat")
	_check(cam.projection == Camera3D.PROJECTION_PERSPECTIVE, "combat preset uses oblique perspective")
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	for pos: Vector2 in [Vector2(-52, -3), Vector2(-18, 24), Vector2(-18, 20), Vector2(-15, 21)]:
		scene._camera_follow = false
		scene._camera_focus = pos
		scene._update_camera(0.0)
		var world := Vector3(pos.x, float(scene.battle.map.ground_height(pos)), -pos.y)
		var screen: Vector2 = cam.unproject_position(world)
		var picked: Variant = scene.screen_to_ground(screen)
		_check(picked is Vector2 and picked.distance_to(pos) < 0.15, "camera click roundtrip on flat/ramp/high ground %s" % pos)
	var before: Vector3 = cam.position
	scene.set_camera_mode("detail")
	_check(cam.position.distance_to(before) > 1.0, "detail preset actually changes camera framing")
	scene.set_camera_mode("tactical")
	_check(cam.size > 40.0, "tactical framing shows more space than combat")
	scene.set_camera_mode("combat")
	var focus: Vector2 = scene._camera_focus
	scene.pan_camera(Vector2.RIGHT, 0.5)
	_check(scene._camera_focus == focus, "paused/modal gameplay rejects edge pan")
	scene.paused = false
	scene.pan_camera(Vector2.RIGHT, 0.5)
	_check(scene._camera_focus.x > focus.x and not scene._camera_follow, "manual pan moves camera and releases hero follow")
	scene.open_growth()
	focus = scene._camera_focus
	scene.pan_camera(Vector2.LEFT, 0.5)
	_check(scene._camera_focus == focus, "growth modal blocks camera pan")
	scene.close_growth()
	scene.paused = true

	for key: String in ["bas", "rio", "nema"]:
		scene.start_match(key, true)
		scene.paused = true
		scene.battle.bots_enabled = false
		hero = scene.battle.units[scene.battle.controlled_id]
		hero.pos = Vector2(-18, 24)
		scene._sync_visuals(0)
		var model: Node3D = scene.get_node("Units/Unit_%d/Model" % hero.id)
		var rig: Variant = model.get_node_or_null("HeroRig")
		_check(rig != null and rig.has_method("pose"), "actual %s uses an articulated game mesh" % key)
		if rig != null and rig.has_method("pose"):
			var radius: float = hero.radius
			var limb: Node3D = rig.get_node("LeftLeg")
			hero.phase = "walk"
			rig.pose(hero, 0.1)
			var first: Vector3 = limb.rotation
			rig.pose(hero, 0.3)
			_check(first.distance_to(limb.rotation) > 0.03, "walking changes actual %s leg pose" % key)
			hero.phase = "basic"
			hero.phase_left = 0.08
			rig.pose(hero, 0.3)
			_check(absf(rig.get_node("RightArm").rotation.x) > 0.1, "basic attack has a distinct %s arm pose" % key)
			_check(is_equal_approx(hero.radius, radius) and is_equal_approx(radius, 0.45), "art never changes authority collision radius")
			_check(model.get_parent().position.y > 2.3, "hero art remains grounded on elevated cell platform")
		var enemy: Dictionary = {}
		for unit: Dictionary in scene.battle.units.values():
			if unit.kind == "hero" and unit.team == 1:
				enemy = unit
				break
		enemy.pos = Vector2(55, 0)
		scene.battle._visibility_cache.clear()
		scene._sync_visuals(0)
		_check(not scene.get_node("Units/Unit_%d" % enemy.id).visible, "new %s model inherits hidden-unit concealment" % key)
	_check(scene.get_node("Arena").has_node("WorkshopDetail"), "playable map contains actual cosmetic workshop detail")
	_check(scene.has_node("CombatAccents"), "playable scene contains observed skill/status accent renderer")
	if scene.has_node("CombatAccents"):
		var accents: Variant = scene.get_node("CombatAccents")
		scene.battle.projectiles = [{"kind": "basic", "team": 0, "pos": Vector2(54, 0), "id": 900}]
		accents.refresh(scene.battle)
		_check(accents.visible_projectile_count == 0, "extra projectile art cannot trace hidden homing targets")
		scene.battle.projectiles = [{"kind": "rio_disc", "team": 0, "pos": Vector2(-18, 24), "id": 901}]
		accents.refresh(scene.battle)
		_check(accents.visible_projectile_count == 1, "visible skill projectile receives matching model")
	scene.restart_match()
	_check(scene.battle.winner == -1 and scene.battle.units[scene.battle.controlled_id].hp > 0, "visual slice preserves normal restart")
	scene.queue_free()
	await process_frame
	_finish()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _finish() -> void:
	print("Playable slice: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
