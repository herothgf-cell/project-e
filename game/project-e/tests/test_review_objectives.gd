extends SceneTree
## Full-map review must include objective cells without exposing the live match.
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.start_match("bas", true)
	scene.paused = true
	scene.battle.bots_enabled = false
	var original_time: float = scene.battle.time
	scene.open_review_lab()
	await process_frame
	var lab: Variant = scene.review_lab
	lab.set_process(false)
	var rewards: Array[float] = []
	for unit: Dictionary in lab.stage.battle.units.values():
		if unit.kind == "cell": rewards.append(float(unit.xp_reward))
	rewards.sort()
	_check(rewards == [20.0,20.0,30.0,30.0,40.0,40.0], "review instantiates six actual authority XP cells with unchanged rewards")
	lab.set_map_view(true)
	var shown: int = 0
	for unit: Dictionary in lab.stage.battle.units.values():
		if unit.kind == "cell" and lab.stage._unit_nodes.has(unit.id) and lab.stage._unit_nodes[unit.id].visible: shown += 1
	_check(shown == 6, "review-only full map shows all six objective models")
	lab.set_map_view(false)
	var hidden: bool = true
	for unit: Dictionary in lab.stage.battle.units.values():
		if unit.kind == "cell" and not lab.stage.battle.is_visible(0,unit.id):
			hidden = hidden and not lab.stage._unit_nodes[unit.id].visible
	_check(hidden, "leaving full map restores current sight concealment")
	lab.play_action("hill")
	lab.advance_review(2.0)
	var visible_high: int = 0
	for unit: Dictionary in lab.stage.battle.units.values():
		if unit.kind == "cell" and unit.pos.distance_to(Vector2(-18,24)) < 0.1 and lab.stage._unit_nodes[unit.id].visible: visible_high += 1
	_check(visible_high == 1, "hill demonstration reveals the real 40XP cell on its plateau")
	_check(scene.battle.time == original_time and not scene.battle._cells_spawned, "review does not advance live match or reveal its objectives")
	lab.close_review()
	await process_frame
	scene.queue_free()
	await process_frame
	print("Review objectives: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1; push_error(message)
