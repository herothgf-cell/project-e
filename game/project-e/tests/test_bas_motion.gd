extends SceneTree
## Behavioral checks for the rules used by the offline movement probe.

const MOTION_PATH: String = "res://scripts/bas_motion.gd"
var _checks: int = 0
var _failures: int = 0
var _motion_script: Script


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists(MOTION_PATH):
		_check(false, "Bas movement rules are not implemented yet")
		quit(1)
		return
	_motion_script = load(MOTION_PATH) as Script
	if _motion_script == null or not _motion_script.can_instantiate():
		_check(false, "Bas movement rules must load")
		quit(1)
		return
	_test_walk()
	_test_dash_timeline()
	_test_rejected_commands()
	_test_large_step_and_collision()
	_test_reset()
	print("Bas motion: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)


func _test_walk() -> void:
	var motion: Variant = _motion_script.new()
	_check(motion.set_move_goal(Vector2(10.0, 0.0)), "valid move accepted")
	_check_vec(motion.step(1.0, Vector2.ZERO), Vector2(5.8, 0.0), "walk covers 5.8m in one second")
	motion.set_move_goal(Vector2(0.1, 0.0))
	_check_vec(motion.step(1.0, Vector2.ZERO), Vector2(0.1, 0.0), "walk never overshoots destination")
	motion.set_move_goal(Vector2(5.0, 0.0))
	motion.stop(Vector2.ZERO)
	_check_vec(motion.step(1.0, Vector2.ZERO), Vector2.ZERO, "stop clears movement")
	_check(not motion.set_move_goal(Vector2(NAN, 0.0)), "NaN destination rejected")
	_check_vec(motion.step(-1.0, Vector2.ZERO), Vector2.ZERO, "negative time cannot move")


func _test_dash_timeline() -> void:
	var motion: Variant = _motion_script.new()
	_check(motion.try_dash(Vector2.ZERO, Vector2.RIGHT), "E accepted while ready")
	_check_close(motion.energy, 80.0, "E spends 20 on approval")
	_check_close(motion.cooldown_remaining, 5.0, "E cooldown starts on approval")
	_check(motion.phase == "windup", "E starts in windup")
	_check_vec(motion.step(0.12, Vector2.ZERO), Vector2.ZERO, "windup does not move")
	_check(motion.phase == "dash", "windup enters dash")
	_check_vec(motion.step(0.30, Vector2.ZERO), Vector2(4.2, 0.0), "dash covers 4.2m in 0.30s")
	_check(motion.phase == "recovery", "dash enters recovery")
	_check_vec(motion.step(0.16, Vector2(4.2, 0.0)), Vector2.ZERO, "recovery does not move")
	_check(motion.phase == "idle", "recovery finishes")
	_check_close(motion.energy, 84.64, "energy recovers at 8 per second")
	_check_close(motion.cooldown_remaining, 4.42, "cooldown advances during the entire cast")
	_check(not motion.try_dash(Vector2.ZERO, Vector2.RIGHT), "cooldown blocks a second E")
	motion.step(5.0, Vector2.ZERO)
	_check_close(motion.energy, 100.0, "energy recovery is capped")
	_check(motion.try_dash(Vector2.ZERO, Vector2.RIGHT), "E can be used after cooldown")


func _test_rejected_commands() -> void:
	var motion: Variant = _motion_script.new()
	_check(not motion.try_dash(Vector2.ZERO, Vector2.ZERO), "zero direction rejected")
	_check(not motion.try_dash(Vector2.ZERO, Vector2(INF, 0.0)), "infinite aim rejected")
	_check_close(motion.energy, 100.0, "invalid aim does not spend energy")
	_check_close(motion.cooldown_remaining, 0.0, "invalid aim does not start cooldown")
	motion.energy = 19.0
	_check(not motion.try_dash(Vector2.ZERO, Vector2.RIGHT), "insufficient energy rejected")
	_check_close(motion.energy, 19.0, "failed cast preserves energy")
	motion.reset(Vector2.ZERO)
	motion.try_dash(Vector2.ZERO, Vector2.RIGHT)
	_check(not motion.try_dash(Vector2.ZERO, Vector2.UP), "busy cast cannot be replaced")
	_check(not motion.set_move_goal(Vector2.UP), "movement cannot cancel committed windup")
	_check_close(motion.energy, 80.0, "repeated E does not spend twice")
	motion.step(0.12, Vector2.ZERO)
	_check_vec(motion.step(0.30, Vector2.ZERO), Vector2(4.2, 0.0), "direction stays fixed after approval")


func _test_large_step_and_collision() -> void:
	var motion: Variant = _motion_script.new()
	motion.try_dash(Vector2.ZERO, Vector2.RIGHT)
	_check_vec(motion.step(2.0, Vector2.ZERO), Vector2(4.2, 0.0), "large frame cannot exceed dash range")
	_check(motion.phase == "idle", "large frame consumes windup and recovery too")
	motion.reset(Vector2.ZERO)
	motion.try_dash(Vector2.ZERO, Vector2.RIGHT)
	motion.step(0.13, Vector2.ZERO)
	motion.on_dash_blocked(Vector2(0.1, 0.0))
	_check(motion.phase == "recovery", "wall contact ends dash")
	_check_vec(motion.step(0.16, Vector2(0.1, 0.0)), Vector2.ZERO, "wall contact leaves no remaining dash motion")
	_check(motion.cooldown_remaining > 0.0, "wall contact does not refund cooldown")


func _test_reset() -> void:
	var motion: Variant = _motion_script.new()
	motion.try_dash(Vector2.ZERO, Vector2.RIGHT)
	motion.step(0.13, Vector2.ZERO)
	motion.reset(Vector2(3.0, 2.0))
	_check_close(motion.energy, 100.0, "reset restores energy")
	_check_close(motion.cooldown_remaining, 0.0, "reset clears cooldown")
	_check(motion.phase == "idle", "reset clears action")
	_check_vec(motion.step(1.0, Vector2(3.0, 2.0)), Vector2.ZERO, "reset clears old destination")


func _check_vec(actual: Vector2, expected: Vector2, label: String) -> void:
	_check(actual.distance_to(expected) < 0.0001, "%s: expected %s, got %s" % [label, expected, actual])


func _check_close(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.0001, "%s: expected %.4f, got %.4f" % [label, expected, actual])


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
