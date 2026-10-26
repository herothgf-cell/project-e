extends SceneTree
## Optional real-render evidence helper. Run with a graphical display, not --headless.
## Output defaults to repository build/screenshots; override with -- --output=/path.

var _out: String = ""


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A graphical display is required to capture real gameplay frames.")
		quit(1)
		return
	_out = ProjectSettings.globalize_path("res://../../build/screenshots")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_out = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(_out)
	root.size = Vector2i(1280, 720)
	var packed: PackedScene = load("res://scenes/battlefield.tscn")
	var scene: Variant = packed.instantiate()
	root.add_child(scene)
	await _frame()
	await _save("01-selection.png")
	scene.start_match("bas", false)
	scene.paused = true
	await _frame()
	await _save("02-start.png")
	scene.open_growth()
	await _frame()
	await _save("03-growth.png")
	scene.close_growth()
	scene.paused = true
	# This is a fast-forwarded simulation capture, not a human playtest.
	var player_id: int = scene.battle.controlled_id
	scene.battle.controlled_id = -1
	for _step: int in range(750):
		scene.battle.step(0.1)
	scene.battle.controlled_id = player_id
	scene.handle_hotkey(KEY_SPACE)
	scene.hud._toast_left = 0.0
	scene.hud._toast.hide()
	await _frame()
	await _save("04-battle.png")
	scene.paused = false
	scene.arm_ability("Q")
	scene.paused = true
	var hero: Dictionary = scene.battle.units[player_id]
	var aim: Vector2 = scene.camera.unproject_position(Vector3(hero.pos.x + 3.0, 0, -hero.pos.y))
	Input.warp_mouse(aim)
	await _frame()
	await _save("05-aim.png")
	# Staged ability frames use real movement/cast commands and unchanged rules.
	for hero_key: String in ["nema", "rio"]:
		scene.start_match(hero_key, true)
		scene.paused = true
		scene.battle.bots_enabled = false
		hero = scene.battle.units[scene.battle.controlled_id]
		scene.battle.command_move(hero.id, Vector2(-2, 0))
		for _i: int in range(30):
			scene.battle.step(0.5)
		scene._camera_focus = hero.pos
		scene.camera.size = 30.0
		scene._update_camera(0)
		scene.hud._toast_left = 0.0
		scene.hud._toast.hide()
		if hero_key == "nema":
			scene.battle.command_cast(hero.id, "Q", Vector2(-5, 3))
			scene.battle.step(2.6)
			scene.battle.command_cast(hero.id, "Q", Vector2(1, 3))
			scene.battle.step(0.6)
			if scene.battle.get_pin_link(hero.id).is_empty():
				push_error("Capture requires an active Nema connection.")
				quit(1)
				return
			await _frame()
			await _save("06-nema-link.png")
		else:
			scene.battle.command_cast(hero.id, "W", Vector2(1, 1))
			scene.battle.step(0.5)
			await _frame()
			await _save("07-rio-mark.png")
			scene.battle.command_cast(hero.id, "Q", Vector2(6, 0))
			scene.battle.step(1.1)
			var returning: bool = false
			for projectile: Dictionary in scene.battle.projectiles:
				if projectile.owner_id == hero.id and projectile.get("phase", "") == "return":
					returning = true
			if not returning:
				push_error("Capture requires Rio Q in its returning phase.")
				quit(1)
				return
			await _frame()
			await _save("08-rio-return.png")
	scene.queue_free()
	await process_frame
	print("Captured eight real rendered frames: " + _out)
	quit(0)


func _frame() -> void:
	for _i: int in range(4):
		await process_frame
	await RenderingServer.frame_post_draw


func _save(filename: String) -> void:
	var frame: Image = root.get_texture().get_image()
	if frame.is_empty() or frame.save_png(_out.path_join(filename)) != OK:
		push_error("Could not save " + filename)
		quit(1)
		return
	print("Saved " + filename)
