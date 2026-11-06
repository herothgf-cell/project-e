extends SceneTree
## Fetch presentation from a running match, then its isolated review room.
var output: String
var scene: Variant
var lab: Variant
var video := false

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): output = arg.trim_prefix("--output=")
		if arg == "--video": video = true
	call_deferred("_run")

func _run() -> void:
	if output.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await _save("selection")
	scene.start_match("bas", true)
	scene.paused = true
	scene.battle.bots_enabled = false
	scene.edge_pan_enabled = false
	scene.set_physics_process(false)
	scene.set_process(false)
	var player: Dictionary = scene.battle.units[scene.battle.controlled_id]
	player.pos = Vector2(-18, 22)
	player.facing = Vector2.RIGHT
	for unit in scene.battle.units.values():
		if unit.kind != "hero" or unit.id == player.id: continue
		if unit.team == 0: unit.pos = Vector2(-22 if unit.hero == "rio" else -21, 18)
		else: unit.pos = Vector2(-13 if unit.hero == "bas" else -10, 18 if unit.hero == "bas" else 17)
	scene.battle.time = 29.99
	scene.battle.step(1.0 / 30.0)
	scene._camera_follow = false
	scene._camera_focus = Vector2(-16, 20)
	scene.set_camera_mode("combat")
	scene._process(0)
	scene.hud._toast.hide()
	scene.hud._toast_left = 0.0
	await _save("combat")
	await _clash()
	scene.open_review_lab()
	await process_frame
	lab = scene.review_lab
	lab.set_process(false)
	lab.layer.hide()
	for key: String in ["bas", "rio", "nema"]:
		lab.select_hero(key)
		lab.advance_review(0.12)
		var hero: Dictionary = lab.stage.battle.units[lab.stage.battle.controlled_id]
		var target := Vector3(hero.pos.x, lab.stage.battle.map.ground_height(hero.pos) + 1.52, -hero.pos.y)
		_close_camera(target)
		await _save(key)
	lab.set_map_view(true)
	await _save("map")
	var lane_target := Vector3(-16, 0.7, -20)
	lab.stage.camera.size = 20
	lab.stage.camera.position = lane_target + Vector3(3, 24, 16)
	lab.stage.camera.look_at(lane_target, Vector3.UP)
	await _save("lane")
	if video: await _motion()
	print("CAPTURE_ART_OK")
	quit(0)

# Arrange the two real teams on mid and cast a real input, preserving normal HUD, vision and camera.
func _clash() -> void:
	var player: Dictionary = scene.battle.units[scene.battle.controlled_id]
	var positions := [
		{"bas": Vector2(-3.8, .4), "rio":Vector2(-8.8, 1.3), "nema":Vector2(-6, -1.65)},
		{"bas": Vector2(.7, 1.5), "rio":Vector2(5.9, -.7), "nema":Vector2(7.3, 1.8)}]
	var counts := [0, 0]
	for u: Dictionary in scene.battle.units.values():
		if u.kind == "hero":
			u.pos = positions[u.team][u.hero]
			u.facing = Vector2.RIGHT if u.team == 0 else Vector2.LEFT
			u.protected = 0
		elif u.kind == "minion" and counts[u.team] < 3:
			var n: int = counts[u.team]
			u.pos = Vector2((-2.0 - n * 1.3) if u.team == 0 else (2.6 + n * 1.5), -1.4 + n * .7)
			counts[u.team] += 1
	scene.battle._visibility_cache.clear()
	if not scene.battle.command_cast(player.id, "R", Vector2(.8, .65)):
		push_error("Mid demonstration cast rejected"); quit(1); return
	var windup: float = player.cast.windup
	scene.battle.step(windup + .06)
	scene._camera_focus = Vector2(-.7, -.8)
	scene.set_camera_mode("combat")
	scene._process(0)
	await _save("mid-clash")
	scene.set_camera_mode("detail")
	scene._process(0)
	await _save("mid-detail")

func _close_camera(target: Vector3) -> void:
	lab.stage.camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	lab.stage.camera.size = 4.25
	lab.stage.camera.position = target + Vector3(1.15, 2.7, 8.7)
	lab.stage.camera.look_at(target, Vector3.UP)

func _motion() -> void:
	DirAccess.make_dir_recursive_absolute(output.path_join("motion"))
	var count := 0
	for key: String in ["bas", "rio", "nema"]:
		lab.select_hero(key)
		for action: String in ["idle", "walk", "Q", "R"]:
			if not lab.play_action(action): push_error("Action failed"); quit(1); return
			for frame in range(20):
				lab.advance_review(1.0 / 24)
				var h: Dictionary = lab.stage.battle.units[lab.stage.battle.controlled_id]
				if action == "idle" or action == "walk":
					_close_camera(Vector3(h.pos.x, 1.46 + lab.stage.battle.map.ground_height(h.pos), -h.pos.y))
				await _save("motion/%04d" % count)
				count += 1

func _save(stem: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	if stem in ["combat", "map", "bas"]:
		print("VIEW_METRIC ", stem, " draw_calls=", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME), " primitives=", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	var err := root.get_texture().get_image().save_png(output.path_join(stem + ".png"))
	if err != OK: push_error("Failed saving " + stem); quit(1)
