extends SceneTree
const State = preload("res://scripts/battle/battle_state.gd")
const AI = preload("res://scripts/battle/tactical_ai.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Variant = State.new()
	state.reset()
	var ai: Variant = AI.new()
	state._ai = ai
	var bot: Dictionary = state.units[2]
	var player: Dictionary = state.units[1]
	state.units.clear()
	state.units[1] = player
	state.units[2] = bot
	bot.pos = Vector2(-18, 22.5)
	bot.points = 0
	bot.lane = 0
	var cell: Dictionary = state._entity("cell", 2, Vector2(-18, 24), 180, 0.55)
	cell.xp_reward = 40.0
	ai.think(state)
	_check(bot.get("objective_kind", "") == "cell", "lifecycle fixture starts an actual farming task")
	var foe: Dictionary = state._entity("hero", 1, Vector2(-18, 23.5), 1000, 0.45)
	foe.hero = "bas"
	state.apply_damage(foe.id, bot.id, 10000, state.next_action_id())
	_check(not bot.alive and bot.deaths == 1, "real damage kills objective-taking bot")
	state.bots_enabled = false
	state._timers(bot, 20.0)
	_check(bot.alive and bot.pos.distance_to(state.map.spawn_points[0]) < 3.0, "authority respawns the bot at home")
	state.bots_enabled = true
	ai.think(state)
	_check(bot.get("objective_kind", "") == "" and int(bot.get("objective_id", -1)) == -1, "respawn clears stale off-lane objective instead of walking back to the old task")

	state = State.new()
	state._ai = AI.new()
	state.reset("bas", false)
	state.controlled_id = -1
	var rewards: int = 0
	var seen_sequence: int = 0
	while state.winner == -1 and state.time < 1860.0:
		state.step(0.5)
		for event: Dictionary in state.feedback_events:
			if int(event.seq) > seen_sequence and event.type == "xp_gain" and event.get("source_kind", "") == "cell":
				rewards += 1
			seen_sequence = maxi(seen_sequence, int(event.seq))
	var heroes: int = 0
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero":
			heroes += 1
			_check(unit.pos.is_finite() and is_finite(unit.hp) and unit.hp >= 0.0, "tactical match keeps hero coordinates and health finite")
	_check(heroes == 6, "tactical match retains all six hero identities")
	_check(state.winner in [0, 1, 2], "tactical six-bot match reaches actual core victory without forced end")
	_check(float(state.stats.damage) > 0.0, "tactical bots continue fighting rather than only rotating")
	print("TACTICAL_MATCH time=%.1f winner=%d damage=%.1f cells=%d support=%d defend=%d cell_grants=%d" % [state.time, state.winner, state.stats.damage, int(state.stats.get("objective_cell", 0)), int(state.stats.get("objective_support", 0)), int(state.stats.get("objective_defend", 0)), rewards])
	print("Tactical lifecycle: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
