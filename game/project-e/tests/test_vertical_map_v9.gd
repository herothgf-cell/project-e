extends SceneTree
## Actual camera, command, minimap and fog contracts for the north-south display.

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
		await _test_scene(dimensions)
	print("Vertical map V9: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_scene(dimensions: Vector2i) -> void:
	root.content_scale_size = dimensions
	root.size = dimensions
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set_process(false)
	scene.set_physics_process(false)
	scene.start_match("bas", true)
	scene.battle.bots_enabled = false
	scene._camera_follow = false
	scene._camera_focus = Vector2.ZERO
	scene.set_camera_mode("tactical")
	var camera: Camera3D = scene.camera
	var home: Vector2 = camera.unproject_position(Vector3(-50, 0, 0))
	var enemy: Vector2 = camera.unproject_position(Vector3(50, 0, 0))
	_check(absf(home.x - enemy.x) < 0.1 and home.y > enemy.y, "both bases share the vertical advance axis " + str(dimensions))
	var left: Vector2 = camera.unproject_position(Vector3(0, 0, -18))
	var middle: Vector2 = camera.unproject_position(Vector3.ZERO)
	var right: Vector2 = camera.unproject_position(Vector3(0, 0, 18))
	_check(left.x < middle.x and middle.x < right.x and absf(left.y - right.y) < 0.1, "lane 0/1/2 read left/center/right in the real camera " + str(dimensions))
	for position: Vector2 in [Vector2(-52, -3), Vector2(-18, 24), Vector2(-18, 20), Vector2(-15, 21), Vector2(18, -24)]:
		scene._camera_focus = position
		scene._update_camera(0.0)
		var world := Vector3(position.x, float(scene.battle.map.ground_height(position)), -position.y)
		var screen: Vector2 = camera.unproject_position(world)
		var hit: Variant = scene.screen_to_ground(screen)
		_check(hit is Vector2 and hit.distance_to(position) < 0.12, "actual ray returns flat/ramp/high ground after the display rotation " + str(position))
	for input: Array in [[Vector2.UP, Vector2.RIGHT], [Vector2.DOWN, Vector2.LEFT], [Vector2.LEFT, Vector2.DOWN], [Vector2.RIGHT, Vector2.UP]]:
		scene._camera_focus = Vector2.ZERO
		scene.pan_camera(input[0], 0.1)
		var expected: Vector2 = input[1] * 2.3
		_check(scene._camera_focus.is_equal_approx(expected), "screen edge %s moves along the matching view axis" % input[0])
	# Screen drag displacement is the inverse of a screen pan; this handler is
	# the one used after the real event path has checked capture/window focus.
	_check(scene.has_method("drag_camera"), "camera exposes the actual captured-drag action")
	if scene.has_method("drag_camera"):
		scene._camera_focus = Vector2.ZERO
		scene._camera_follow = false
		scene._update_camera(0.0)
		var origin_before: Vector2 = camera.unproject_position(Vector3.ZERO)
		scene.drag_camera(Vector2(40, 0))
		var origin_after: Vector2 = camera.unproject_position(Vector3.ZERO)
		_check(origin_after.x > origin_before.x and absf(origin_after.y - origin_before.y) < 0.1, "dragging right pulls the world right")
		scene._camera_focus = Vector2.ZERO
		scene._update_camera(0.0)
		origin_before = camera.unproject_position(Vector3.ZERO)
		scene.drag_camera(Vector2(0, 30))
		origin_after = camera.unproject_position(Vector3.ZERO)
		_check(origin_after.y > origin_before.y and absf(origin_after.x - origin_before.x) < 0.1, "dragging down pulls the world down")
		var before: Vector2 = scene._camera_focus
		scene.paused = true
		scene.drag_camera(Vector2(40, 30))
		_check(scene._camera_focus == before, "paused match rejects captured-drag movement")
		scene.paused = false
	_test_target_selection(scene)
	await _test_minimap(scene, dimensions)
	scene.open_review_lab()
	await process_frame
	var lab: Variant = scene.review_lab
	lab.set_process(false)
	lab.set_map_view(true)
	home = lab.stage.camera.unproject_position(Vector3(-50, 0, 0))
	enemy = lab.stage.camera.unproject_position(Vector3(50, 0, 0))
	_check(absf(home.x - enemy.x) < 0.1 and home.y > enemy.y, "full-map review shares the playable vertical orientation")
	for team_point: Vector2 in [home, enemy]:
		_check(Rect2(Vector2(0, 110), Vector2(dimensions.x, dimensions.y - 220)).has_point(team_point), "full-map review keeps both bases between its UI rows")
	lab.close_review()
	await process_frame
	scene.queue_free()
	await process_frame


func _test_target_selection(scene: Variant) -> void:
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-4, 0)
	var target: Dictionary = {}
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind == "core" and unit.team == 1:
			target = unit
		elif unit.id != hero.id:
			unit.alive = false
	target.pos = Vector2.ZERO
	target.locked = false
	scene.battle._visibility_cache.clear()
	scene._camera_follow = false
	scene._camera_focus = Vector2.ZERO
	scene.set_camera_mode("detail")
	for side: float in [-1.0, 1.0]:
		var world: Vector3 = scene.camera.global_basis.x * (float(target.radius) * side * 0.97)
		var screen: Vector2 = scene.camera.unproject_position(world)
		_check(scene.pick_visible_target(screen) == target.id, "visible structure edge remains selectable from the rotated camera")


func _test_minimap(scene: Variant, dimensions: Vector2i) -> void:
	var map: Variant = scene.minimap
	await process_frame
	var home: Vector2 = map.to_map(Vector2(-50, 0))
	var enemy: Vector2 = map.to_map(Vector2(50, 0))
	_check(absf(home.x - enemy.x) < 0.01 and home.y > enemy.y, "minimap agrees with camera on the two bases " + str(dimensions))
	var left: Vector2 = map.to_map(Vector2(0, 18))
	var right: Vector2 = map.to_map(Vector2(0, -18))
	_check(left.x < right.x and absf(left.y - right.y) < 0.01, "minimap keeps left and right lanes in order")
	var center: Vector2 = map.to_map(Vector2.ZERO)
	_check(is_equal_approx(center.distance_to(map.to_map(Vector2(10, 0))), center.distance_to(map.to_map(Vector2(0, 10)))), "minimap preserves distance and circle proportions")
	for point: Vector2 in [Vector2(-56, 0), Vector2(56, 0), Vector2(-18, 24), Vector2(18, -24), Vector2.ZERO]:
		_check(map.from_map(map.to_map(point)).distance_to(point) < 0.001, "minimap click roundtrip " + str(point))
	_check(map.has_method("content_rect") and map.has_method("fog_transform"), "minimap uses one fitted rectangle and fog transform")
	if not map.has_method("content_rect") or not map.has_method("fog_transform"):
		return
	var content: Rect2 = map.content_rect()
	_check(content.size.y > content.size.x and Rect2(Vector2.ZERO, map.size).encloses(content), "portrait map fits within the existing HUD panel")
	var fog_transform: Transform2D = map.fog_transform()
	# Fog source texel centers are independent fixtures in the authoritative
	# 124 x 80 texture (x=east, y=north). Both must cover the matching map icon.
	for sample: Array in [[Vector2(12.5, 40.5), Vector2(-49.5, 0.5)], [Vector2(112.5, 40.5), Vector2(50.5, 0.5)], [Vector2(62.5, 58.5), Vector2(0.5, 18.5)]]:
		_check((fog_transform * sample[0]).distance_to(map.to_map(sample[1])) < 0.001, "fog texel lands on its actual world point " + str(sample[1]))
	var click := InputEventMouseButton.new()
	click.pressed = true
	click.button_index = MOUSE_BUTTON_LEFT
	click.position = map.to_map(Vector2(20, 0))
	map._gui_input(click)
	_check(not scene._camera_follow and scene._camera_focus.distance_to(Vector2(20, 0)) < 0.001, "minimap camera click uses the rotated world coordinates")
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-45, 0)
	scene.battle.command_stop(hero.id)
	click.button_index = MOUSE_BUTTON_RIGHT
	click.position = map.to_map(Vector2(-35, 0))
	map._gui_input(click)
	_check(hero.order == "move" and hero.goal.distance_to(Vector2(-35, 0)) < 0.001, "minimap movement submits the matching legal world command")
	var previous_goal: Vector2 = hero.goal
	var previous_focus: Vector2 = scene._camera_focus
	click.position = Vector2(1, map.size.y * 0.5)
	_check(not content.has_point(click.position), "test click is in the portrait letterbox")
	map._gui_input(click)
	click.button_index = MOUSE_BUTTON_LEFT
	map._gui_input(click)
	_check(hero.goal == previous_goal and scene._camera_focus == previous_focus, "portrait letterbox consumes clicks without moving hero or camera")
	click.position = Vector2(NAN, 1)
	map._gui_input(click)
	_check(scene._camera_focus == previous_focus, "nonfinite minimap pointer cannot corrupt the camera")
	var map_bounds: Rect2 = scene.hud._map_panel.get_global_rect()
	_check(map_bounds.end.y <= scene.hud._inventory.get_global_rect().position.y, "map remains clear of inventory at " + str(dimensions))


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(message)
