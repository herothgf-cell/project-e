extends SceneTree
var out: String = ""
var scene: Variant
var lab: Variant
var frame_index: int = 0
func _initialize() -> void:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--output="): out = arg.trim_prefix("--output=")
	call_deferred("_run")
func _run() -> void:
	if out.is_empty(): quit(1); return
	DirAccess.make_dir_recursive_absolute(out.path_join("frames"))
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.open_review_lab()
	await process_frame
	lab = scene.review_lab
	lab.set_process(false)
	for key: String in ["bas", "rio", "nema"]:
		lab.select_hero(key)
		lab.advance_review(0.1)
		await _save(key + "-character.png")
		for slot: String in ["Q", "W", "E", "R"]:
			if not lab.play_action(slot):
				push_error("Real review cast failed: " + key + slot)
				quit(1); return
			var hero: Dictionary = lab.stage.battle.units[lab.stage.battle.controlled_id]
			var windup: float = hero.cast.windup
			lab.advance_review(windup * 0.5)
			await _save(key + "-" + slot + "-windup.png")
			lab.advance_review(windup * 0.5 + 0.05)
			await _save(key + "-" + slot + "-active.png")
			lab.play_action(slot)
			for frame: int in range(18):
				lab.advance_review(1.0 / 15.0)
				await _save("frames/%04d.png" % frame_index)
				frame_index += 1
		lab.play_action("hit")
		lab.advance_review(0.10)
		await _save(key + "-hit.png")
		lab.play_action("death")
		for frame: int in range(12):
			lab.advance_review(1.0 / 15.0)
			if frame == 5: await _save(key + "-death.png")
			await _save("frames/%04d.png" % frame_index)
			frame_index += 1
		lab.play_action("respawn")
		lab.advance_review(0.25)
		await _save(key + "-respawn.png")
	lab.select_hero("bas")
	lab.play_action("hill")
	for frame: int in range(30):
		lab.advance_review(1.0 / 15.0)
		if frame == 7: await _save("hill-ramp.png")
		if frame == 22: await _save("hill-plateau.png")
		await _save("frames/%04d.png" % frame_index)
		frame_index += 1
	lab.set_map_view(true)
	await _save("map-layout-unmasked.png")
	lab.close_review()
	await process_frame
	scene.start_match("bas", true)
	scene.paused = true
	scene.battle.bots_enabled = false
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-18, 21)
	scene._camera_focus = Vector2(-16, 20)
	scene.set_camera_mode("combat")
	scene._sync_visuals(0)
	scene._process(0)
	await _save("normal-gameplay.png")
	print("INTEGRATED_CAPTURE_OK: all 12 real casts, 3 heroes, hit/death/respawn, terrain and %d frames" % frame_index)
	scene.queue_free()
	await process_frame
	quit(0)
func _save(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var err: Error = root.get_texture().get_image().save_png(out.path_join(name))
	if err != OK: push_error("Could not save " + name)
	if not name.begins_with("frames/"): print("CAPTURE " + name)
