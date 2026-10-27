extends SceneTree
## Real-render evidence using reproducible staged states, not a human playtest.
## Requires a graphical display. Output: build/screenshots-next by default.

var _out: String
var _scene: Variant
var _saved: int = 0
var _failed: bool = false


func _initialize() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A graphical display is required for rendered evidence.")
		quit(1)
		return
	_out = ProjectSettings.globalize_path("res://../../build/screenshots-next")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_out = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(_out)
	root.size = Vector2i(1280, 720)
	_scene = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(_scene)
	_scene.set_physics_process(false)
	await _frame()
	await _save("01-selection.png")
	_start("bas", Vector2(-28, 0), 42.0)
	await _frame()
	await _save("02-start-vision.png")
	_scene.open_help()
	await _frame()
	await _save("03-first-play-guide.png")
	_scene.close_help()

	# Show all three real tier models together; no altered rewards or collisions.
	_start("bas", Vector2.ZERO, 26.0)
	_scene.battle.step(30.1)
	var hero: Dictionary = _scene.battle.units[_scene.battle.controlled_id]
	hero.pos = Vector2(-1, -2)
	var seen: Dictionary = {}
	for unit: Dictionary in _scene.battle.units.values():
		if unit.kind == "minion":
			unit.alive = false
		if unit.kind != "cell":
			continue
		unit.alive = not seen.has(unit.cell_tier)
		if unit.alive:
			seen[unit.cell_tier] = true
			unit.pos = Vector2((float(unit.xp_reward) - 30.0) * 0.5, 0)
	if seen.size() != 3:
		_failed = true
		push_error("Cell capture requires all three real spawned tiers")
	_refresh()
	await _frame()
	await _save("04-cell-tiers.png")

	# Identical camera: wall occlusion, allied overlap, then source removal.
	_start("bas", Vector2(0, 7), 35.0)
	hero = _scene.battle.units[_scene.battle.controlled_id]
	hero.pos = Vector2(0, 3)
	_refresh()
	await _frame()
	_verify_gpu_mask(Vector2(0.5, 14.5), false)
	await _save("05-wall-vision-before.png")
	var ally: Dictionary = {}
	for unit: Dictionary in _scene.battle.units.values():
		if unit.kind == "hero" and unit.team == 0 and unit.id != hero.id:
			ally = unit
			break
	ally.pos = Vector2(0, 15)
	_refresh()
	await _frame()
	_verify_gpu_mask(Vector2(0.5, 14.5), true)
	await _save("06-wall-vision-overlap.png")
	ally.alive = false
	_refresh()
	Input.warp_mouse(_scene.vision_view.source_marker_screen_position(_scene.camera, hero.id))
	await _frame()
	_verify_hover(hero.id)
	_verify_gpu_mask(Vector2(0.5, 14.5), false)
	await _save("07-source-hover-after-removal.png")

	_start("bas", Vector2(-13, 3.5), 32.0)
	var tower: Dictionary = {}
	for unit: Dictionary in _scene.battle.units.values():
		if unit.kind == "tower" and unit.team == 0 and unit.lane == 1 and unit.subtype == "outer":
			tower = unit
			break
	_scene._camera_focus = tower.pos
	_scene._update_camera(0)
	Input.warp_mouse(_scene.vision_view.source_marker_screen_position(_scene.camera, tower.id))
	await _frame()
	_verify_hover(tower.id)
	await _save("08-tower-sight-and-attack.png")

	_start("bas", Vector2.ZERO, 26.0)
	hero = _scene.battle.units[_scene.battle.controlled_id]
	hero.pos = Vector2(-4, 0)
	_refresh()
	_scene.handle_hotkey(KEY_A)
	Input.warp_mouse(_scene.camera.unproject_position(Vector3(5, 0, 0)))
	await _frame()
	await _save("09-attack-move-aim.png")
	_scene.handle_hotkey(KEY_ESCAPE)
	hero.pos = Vector2(0, 4)
	_refresh()
	_scene.arm_ability("Q")
	Input.warp_mouse(_scene.camera.unproject_position(Vector3(0, 0, -8)))
	await _frame()
	_verify_preview("Q")
	await _save("10-wall-clipped-cone.png")
	_scene.handle_hotkey(KEY_ESCAPE)
	_scene.arm_ability("W")
	Input.warp_mouse(_scene.camera.unproject_position(Vector3(0, 0, -4.2)))
	await _frame()
	_verify_preview("W")
	await _save("11-wall-clipped-circle.png")
	_scene.queue_free()
	await process_frame
	print("Next features render: %d frames; GPU mask transitions %s" % [_saved, "FAIL" if _failed else "PASS"])
	quit(1 if _failed else 0)


func _start(hero_key: String, focus: Vector2, zoom: float) -> void:
	_scene.start_match(hero_key, true)
	_scene.battle.bots_enabled = false
	_scene._camera_follow = false
	_scene._camera_focus = focus
	_scene.camera.size = zoom
	_scene._update_camera(0)
	_scene.hud._toast_left = 0.0
	_scene.hud._toast.hide()
	Input.warp_mouse(Vector2(1000, 100))


func _refresh() -> void:
	_scene.battle._visibility_cache.clear()
	_scene.vision_view._force_refresh = true
	_scene._sync_visuals(0.3)


func _verify_gpu_mask(point: Vector2, expected: bool) -> void:
	var mask: Image = _scene.vision_view.mask_texture.get_image()
	var fog: Image = _scene.vision_view.minimap_fog_texture.get_image()
	var pixel := Vector2i((point - Vector2(-62, -40)).floor())
	var actual: bool = mask.get_pixel(pixel.x, pixel.y).r > 0.5
	var map_actual: bool = fog.get_pixel(pixel.x, pixel.y).a < 0.1
	if actual != expected or map_actual != expected:
		_failed = true
		push_error("GPU ground/minimap visibility does not match expected source transition at %s" % point)


func _verify_preview(slot: String) -> void:
	var point: Variant = _scene.screen_to_ground(root.get_mouse_position())
	if not point is Vector2 or not _scene.battle.get_cast_preview(_scene.battle.controlled_id, slot, point).get("valid", false):
		_failed = true
		push_error("Wall capture requires a valid " + slot + " preview")


func _verify_hover(id: int) -> void:
	if _scene.vision_view.hovered_source_id != id:
		_failed = true
		push_error("Source badge capture requires the corresponding visible hover contour")


func _frame() -> void:
	for _index: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw


func _save(filename: String) -> void:
	var frame: Image = root.get_texture().get_image()
	if frame.is_empty() or frame.save_png(_out.path_join(filename)) != OK:
		_failed = true
		push_error("Could not save " + filename)
		return
	_saved += 1
	print("Saved " + filename)
