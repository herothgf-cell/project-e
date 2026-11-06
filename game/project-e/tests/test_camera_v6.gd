extends SceneTree
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set_process(false)
	scene.set_physics_process(false)
	_check(not scene._review_button.visible, "selection keeps the review button out of the hero choices")
	scene.start_match("bas", true)
	scene.battle.bots_enabled = false
	_check(scene._camera_follow, "new matches follow the controlled hero")
	_check(scene._review_button.visible, "review button remains available during the match")
	if not scene.has_method("edge_pan_axis"):
		_check(false, "camera exposes the shared edge input calculation")
		scene.queue_free()
		await process_frame
		_finish()
		return

	var bounds := Rect2(0, 0, 1280, 720)
	for point: Vector2 in [Vector2(1, 360), Vector2(1279, 360), Vector2(640, 1), Vector2(640, 719)]:
		var axis: Vector2 = scene.edge_pan_axis(point, bounds, true)
		_check(axis.length() > 0.9, "every exterior edge remains usable over the HUD %s" % point)
	_check(scene.edge_pan_axis(Vector2(16, 360), bounds).is_equal_approx(Vector2(-0.5, 0)), "edge speed ramps across the full 32 pixel margin")
	_check(scene.edge_pan_axis(Vector2(24, 360), bounds).x < 0, "panning begins before the old 12 pixel boundary")
	_check(scene.edge_pan_axis(Vector2(16, 360), bounds, true) == Vector2.ZERO, "HUD interactions outside the exterior gutter do not pan")
	_check(scene.edge_pan_axis(Vector2(640, 360), bounds) == Vector2.ZERO, "the viewport interior does not pan")
	_check(scene.edge_pan_axis(Vector2(-1, 360), bounds) == Vector2.ZERO, "off-window pointer does not pan")
	_check(scene.edge_pan_axis(Vector2(1280, 360), bounds) == Vector2.ZERO, "right boundary outside the viewport does not pan")
	_check(scene.edge_pan_axis(Vector2(NAN, 360), bounds) == Vector2.ZERO, "invalid pointer coordinates do not pan")
	_check(scene.edge_pan_axis(Vector2.ZERO, Rect2()) == Vector2.ZERO, "empty viewports do not pan")
	var diagonal: Vector2 = scene.edge_pan_axis(Vector2(1, 1), bounds)
	_check(is_equal_approx(diagonal.length(), 1.0) and diagonal.x < 0 and diagonal.y < 0, "corner panning preserves direction and caps diagonal speed")
	var offset_bounds := Rect2(100, 50, 1280, 720)
	_check(scene.edge_pan_axis(Vector2(116, 410), offset_bounds).is_equal_approx(Vector2(-0.5, 0)), "edge coordinates respect the viewport origin")
	var scaled_bounds := Rect2(100, 50, 2560, 1440)
	_check(scene.edge_pan_axis(Vector2(132, 770), scaled_bounds).is_equal_approx(Vector2(-0.5, 0)), "edge margins scale with the visible viewport")

	scene._camera_focus = Vector2.ZERO
	scene.pan_camera(Vector2.RIGHT, 0.1)
	_check(not scene._camera_follow and scene._camera_focus.x > 0, "manual panning releases follow")
	var one_step: Vector2 = scene._camera_focus
	scene._camera_focus = Vector2.ZERO
	for _step: int in range(10):
		scene.pan_camera(Vector2.RIGHT, 0.01)
	_check(scene._camera_focus.is_equal_approx(one_step), "pan displacement is independent of frame subdivision")
	scene._camera_focus = Vector2.ZERO
	scene.pan_camera(Vector2(1, 1), 0.1)
	_check(is_equal_approx(scene._camera_focus.length(), one_step.length()), "diagonal pan speed matches straight pan speed")
	var before: Vector2 = scene._camera_focus
	scene.pan_camera(Vector2.ZERO, 0.1)
	_check(scene._camera_focus == before, "zero input does not move the camera")
	scene.paused = true
	scene.pan_camera(Vector2.RIGHT, 0.1)
	_check(scene._camera_focus == before, "paused gameplay rejects camera panning")
	scene.paused = false
	scene.open_growth()
	scene.pan_camera(Vector2.RIGHT, 0.1)
	_check(scene._camera_focus == before, "growth modal rejects camera panning")
	scene.close_growth()

	scene._camera_focus = Vector2.ZERO
	scene._camera_follow = false
	_check(scene.handle_hotkey(KEY_Y) and scene._camera_follow, "Y enables hero follow")
	_check(scene._camera_focus == Vector2.ZERO, "enabling follow starts a smooth transition")
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-20, 0)
	scene._update_camera(1.0 / 60.0)
	_check(scene._camera_focus.x < 0 and scene._camera_focus.x > -20, "follow converges smoothly toward the hero")
	scene.handle_hotkey(KEY_Y)
	_check(not scene._camera_follow, "Y also releases hero follow")
	scene.handle_hotkey(KEY_SPACE)
	_check(scene._camera_follow and scene._camera_focus.is_equal_approx(hero.pos), "Space recenters on the controlled hero")
	_check(not scene._edge_pan_armed, "recenter requires a fresh edge entry before releasing follow")
	scene._camera_drag = true
	scene._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	_check(not scene._camera_drag and not scene._edge_pan_armed, "losing window focus clears camera gestures")
	scene.queue_free()
	await process_frame
	_finish()

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _finish() -> void:
	print("Camera V6: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
