extends SceneTree
## Staged inspection, not a natural-match recording. Uses the shipped scene,
## actual authority cast, fog, HUD and cameras in a checkout or exported PCK.

var output: String = ""
var capture_source: String = "source checkout"
var checks: int = 0
var failures: int = 0
var records: Array[Dictionary] = []
var scene: Variant


func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		if argument == "--exported-pck":
			capture_source = "exported PCK"
	call_deferred("_run")


func _run() -> void:
	if output.is_empty() or not output.is_absolute_path():
		push_error("Provide an absolute --output directory for staged vertical-map captures")
		quit(1)
		return
	if DisplayServer.get_name() == "headless":
		push_error("Vertical-map captures require a real rendering display")
		quit(1)
		return
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(output)
	if directory_error != OK:
		push_error("Cannot create capture directory: " + error_string(directory_error))
		quit(1)
		return
	var packed: PackedScene = load("res://scenes/battlefield.tscn")
	if packed == null:
		push_error("Cannot load the shipped battlefield scene")
		quit(1)
		return
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	scene = packed.instantiate()
	root.add_child(scene)
	scene.edge_pan_enabled = false
	await _settle()
	scene.start_match("bas", true)
	scene.battle.bots_enabled = false
	scene.set_physics_process(false)
	scene.set_process(false)
	scene.battle._next_ai = INF
	scene.battle._next_wave = INF
	scene.battle._next_income = INF
	_stage_mid_clash()
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		scene._camera_follow = false
		scene._camera_focus = Vector2(-0.7, 0.0)
		scene.set_camera_mode("combat")
		scene._process(0.0)
		scene.hud._toast_left = 0.0
		scene.hud._toast.hide()
		await _settle()
		var content: Rect2 = scene.minimap.content_rect()
		_check(content.size.x >= 124.0 and content.size.y > content.size.x, "portrait minimap retains a readable width at " + str(dimensions))
		_check(not scene.hud._map_panel.get_global_rect().intersects(scene.hud._inventory.get_global_rect()), "minimap clears inventory at " + str(dimensions))
		_check(not scene.hud._map_panel.get_global_rect().intersects(scene._camera_hint.get_global_rect()), "minimap clears camera hints at " + str(dimensions))
		for control: Control in [scene.hud._map_panel, scene.hud._bottom, scene.hud._inventory]:
			_check(root.get_visible_rect().encloses(control.get_global_rect()), "battle control fits " + control.name + " " + str(dimensions))
		_check_vertical_camera(scene.camera)
		await _save("vertical-battle-%dx%d" % [dimensions.x, dimensions.y], "Staged mid-lane battle; real cast, normal fog and playable camera")
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var original_time: float = scene.battle.time
	scene.open_review_lab()
	await _settle()
	var lab: Variant = scene.review_lab
	lab.set_process(false)
	lab.set_map_view(true)
	await _settle()
	_check_vertical_camera(lab.stage.camera)
	_check(scene.battle.time == original_time, "whole-map inspection leaves the original match frozen")
	await _save("vertical-overview-1280x720", "F7 isolated whole-map review; terrain and objectives revealed for layout inspection")
	lab.close_review()
	await process_frame
	var manifest: FileAccess = FileAccess.open(output.path_join("vertical-review.json"), FileAccess.WRITE)
	if manifest == null:
		_check(false, "capture manifest can be written")
	else:
		manifest.store_string(JSON.stringify({
			"project_version": str(ProjectSettings.get_setting("application/config/version", "")),
			"engine": Engine.get_version_info().string,
			"source": capture_source,
			"display": DisplayServer.get_name(),
			"scenario": "Staged presentation inspection, not a natural match or balance measurement",
			"checks": checks, "failures": failures, "captures": records,
		}, "\t"))
		manifest.close()
	scene.queue_free()
	await process_frame
	print("VERTICAL_CAPTURE_%s %d checks, %d failures" % ["OK" if failures == 0 else "FAILED", checks, failures])
	quit(0 if failures == 0 else 1)


func _stage_mid_clash() -> void:
	# Direct placement creates a repeatable view. Combat itself uses the normal
	# authority command and timestep, with autonomous AI disabled only here.
	var positions: Array = [
		{"bas": Vector2(-3.8, 0.4), "rio": Vector2(-8.8, 1.3), "nema": Vector2(-6, -1.65)},
		{"bas": Vector2(0.7, 1.5), "rio": Vector2(5.9, -0.7), "nema": Vector2(7.3, 1.8)},
	]
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "hero":
			unit.pos = positions[unit.team][unit.hero]
			unit.facing = Vector2.RIGHT if unit.team == 0 else Vector2.LEFT
			unit.protected = 0.0
	scene.battle._spawn_wave()
	var counts: Array[int] = [0, 0]
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "minion" and unit.lane == 1:
			var index: int = counts[unit.team]
			unit.pos = Vector2(-4.2 - index * 1.2 if unit.team == 0 else 2.6 + index * 1.2, -1.3 + index * 0.7)
			counts[unit.team] += 1
	scene.battle._visibility_cache.clear()
	var player: Dictionary = scene.battle.units[scene.battle.controlled_id]
	var accepted: bool = scene.battle.command_cast(player.id, "R", Vector2(0.8, 0.65))
	_check(accepted, "staged player submits a real R cast")
	if accepted:
		scene.battle.step(float(player.cast.windup) + 0.06)


func _check_vertical_camera(camera: Camera3D) -> void:
	var home: Vector2 = camera.unproject_position(Vector3(-50, 0, 0))
	var enemy: Vector2 = camera.unproject_position(Vector3(50, 0, 0))
	_check(absf(home.x - enemy.x) < 0.1 and home.y > enemy.y, "rendered camera presents allied base below enemy base")


func _settle() -> void:
	for _frame: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw


func _save(stem: String, description: String) -> void:
	await _settle()
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		_check(false, "renderer provides pixels for " + stem)
		return
	_check(image.get_size() == root.size, "capture has the requested native pixel dimensions " + stem)
	var path: String = output.path_join(stem + ".png")
	var result: Error = image.save_png(path)
	_check(result == OK, "PNG writes successfully " + stem)
	if result == OK:
		records.append({"file": stem + ".png", "width": image.get_width(), "height": image.get_height(), "description": description})


func _check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)
