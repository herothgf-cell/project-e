extends SceneTree
## Actual renderer review harness; deliberately separate from the production scene.
var output: String = ""
var scene: Variant

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
	call_deferred("_run")

func _run() -> void:
	if output.is_empty():
		push_error("Provide --output for review captures")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.start_match("bas", true)
	scene.paused = true
	scene.edge_pan_enabled = false
	scene.battle.bots_enabled = false
	scene.set_physics_process(false)
	scene.set_process(false)
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-18, 22)
	hero.facing = Vector2(1, 0)
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "hero" and unit.team == 0 and unit.id != hero.id:
			unit.pos = Vector2(-22 if unit.hero == "rio" else -21, 18)
		if unit.kind == "hero" and unit.team == 1:
			unit.pos = Vector2(-13 if unit.hero == "bas" else -10, 18 if unit.hero == "bas" else 17)
	scene.battle.time = 29.99
	scene.battle.step(1.0 / 30.0)
	scene._camera_follow = false
	scene._camera_focus = Vector2(-16, 20)
	scene.set_camera_mode("combat")
	await _save("combat.png")
	scene.set_camera_mode("tactical")
	await _save("tactical.png")

	# These are the actual playable rigs; the art review alone hides the HUD.
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "hero" and unit.team == 0:
			unit.pos = Vector2({"bas": -3.3, "rio": 0.0, "nema": 3.3}[str(unit.hero)], 0)
			unit.facing = Vector2(0, -1)
			unit.order = "idle"
			unit.phase = "idle"
		if unit.kind == "hero" and unit.team == 1:
			unit.pos = Vector2(55, 0)
	scene.battle._visibility_cache.clear()
	scene._camera_focus = Vector2(0, 0)
	scene.set_camera_mode("detail")
	scene.camera.size = 12.5
	scene._update_camera(0)
	await _save("hero-lineup.png", true)
	var review_labels: Array[Label3D] = []
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "hero" and unit.team == 0:
			var label := Label3D.new()
			label.font = scene.hud.ui_font
			label.text = {"bas": "바스", "rio": "리오", "nema": "네마"}[str(unit.hero)]
			label.font_size = 42
			label.pixel_size = 0.013
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.position = Vector3(unit.pos.x, 3.2, -unit.pos.y)
			scene.add_child(label)
			review_labels.append(label)
	await _save("hero-lineup-labelled.png", true)
	for label: Label3D in review_labels:
		label.queue_free()
	await process_frame

	# Four real Bas casts, with authority-generated telegraphs and effects.
	for slot: String in ["Q", "W", "E", "R"]:
		scene.start_match("bas", true)
		scene.paused = true
		scene.edge_pan_enabled = false
		scene.battle.bots_enabled = false
		hero = scene.battle.units[scene.battle.controlled_id]
		hero.pos = Vector2(-3, 0)
		hero.facing = Vector2.RIGHT
		for unit: Dictionary in scene.battle.units.values():
			if unit.kind == "hero" and unit.team == 1 and unit.hero == "bas":
				unit.pos = Vector2(1, 0)
		scene.battle._visibility_cache.clear()
		scene._camera_follow = false
		scene._camera_focus = Vector2(0, 0)
		scene.set_camera_mode("detail")
		var accepted: bool = scene.battle.command_cast(hero.id, slot, Vector2(2, 0) if slot != "W" else hero.pos)
		if not accepted:
			push_error("Review cast rejected: " + slot + ": " + str(scene.battle.last_error))
			quit(1)
			return
		scene.battle.step(0.10)
		await _save("bas-" + slot + "-windup.png")
		scene.battle.step(0.20)
		await _save("bas-" + slot + "-active.png")

	DirAccess.make_dir_recursive_absolute(output.path_join("frames"))
	scene.start_match("bas", true)
	scene.paused = true
	scene.battle.bots_enabled = false
	hero = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-4, 0)
	scene._camera_follow = false
	scene._camera_focus = Vector2(0, 0)
	scene.set_camera_mode("detail")
	for frame: int in range(90):
		if frame == 0: scene.battle.command_move(hero.id, Vector2(-1, 0))
		if frame == 25: scene.battle.command_cast(hero.id, "Q", Vector2(2, 0))
		if frame == 45: scene.battle.command_cast(hero.id, "W", hero.pos)
		if frame == 65: scene.battle.command_cast(hero.id, "E", Vector2(3, 0))
		scene.battle.step(1.0 / 30.0)
		await _save("frames/%03d.png" % frame)
	print("CAPTURE_OK: real renderer combat, tactical, lineup, four skill pairs and 90 animation frames")
	scene.queue_free()
	await process_frame
	quit(0)

func _save(filename: String, art_review: bool = false) -> void:
	scene.battle._visibility_cache.clear()
	scene._process(0.0)
	scene.hud._toast.hide()
	scene.hud._toast_left = 0.0
	scene.hud.root_control.visible = not art_review
	if art_review:
		scene.camera.position = Vector3(0, 5.8, 11.8)
		scene.camera.look_at(Vector3(0, 1.1, 0), Vector3.UP)
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var error: Error = image.save_png(output.path_join(filename))
	if error != OK:
		push_error("Capture failed: " + filename)
		quit(1)
	print("CAPTURE " + filename + " " + str(image.get_size()))
