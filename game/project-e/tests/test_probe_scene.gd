extends SceneTree

var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists("res://scenes/combat_probe.tscn"):
		_check(false, "Movement probe scene is not implemented yet")
		quit(1)
		return
	var packed: PackedScene = load("res://scenes/combat_probe.tscn") as PackedScene
	if packed == null:
		_check(false, "Movement probe scene must load")
		quit(1)
		return
	var probe: Node = packed.instantiate()
	root.add_child(probe)
	await physics_frame
	await physics_frame
	var player: Variant = probe.get_node("Player")
	_check(player is CharacterBody3D, "probe has a physical player")
	_check(probe.get_node("Camera3D").current, "probe camera is active")
	for action: String in ["move_click", "confirm_aim", "aim_dash", "cancel_aim", "stop_move", "reset_probe"]:
		_check(InputMap.has_action(action) and not InputMap.action_get_events(action).is_empty(), "input is bound: " + action)
	_check(InputMap.action_get_events("reset_probe")[0].physical_keycode == KEY_F2, "reset binding is F2")

	player.reset_to(Vector3(-8.0, 0.0, 5.0))
	_check(player.request_move(Vector3(-5.0, 0.0, 5.0)), "physical player accepts click destination")
	await _frames(25)
	_check(player.position.distance_to(Vector3(-5.0, 0.0, 5.0)) < 0.02, "physical walking reaches destination")

	player.reset_to(Vector3(-8.0, 0.0, 5.0))
	_check(player.request_dash(Vector3(-1.0, 0.0, 5.0)), "physical player accepts E")
	await _frames(25)
	_check(absf(player.position.x - -3.8) < 0.02, "physical dash travels 4.2m in open space")
	_check(absf(player.position.z - 5.0) < 0.02, "physical dash keeps aimed direction")

	player.reset_to(Vector3(-3.0, 0.0, 0.0))
	player.request_dash(Vector3(5.0, 0.0, 0.0))
	await _frames(25)
	_check(player.position.x <= -0.94 and player.position.x >= -1.10, "E stops before wall with capsule clearance")
	_check(player.motion.phase == "idle", "wall hit recovery finishes")
	_check(player.motion.cooldown_remaining > 0.0, "wall hit keeps cooldown")

	probe.reset_probe()
	_check(player.position.distance_to(Vector3(-8.0, 0.0, 3.0)) < 0.02, "probe reset returns to spawn")
	_check(player.motion.energy == 100.0 and player.motion.cooldown_remaining == 0.0, "probe reset clears resources")
	probe.queue_free()
	await process_frame
	print("Probe scene: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _frames(count: int) -> void:
	for _i: int in range(count):
		await physics_frame


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
