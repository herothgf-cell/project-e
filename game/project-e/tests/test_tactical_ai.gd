extends SceneTree
## Real authority commands, no mock combat or fabricated observation.
const State = preload("res://scripts/battle/battle_state.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "res://scripts/battle/tactical_ai.gd"
	_check(ResourceLoader.exists(path), "playable bots have bounded visible-objective policy")
	if not ResourceLoader.exists(path):
		_finish()
		return
	var script: Variant = load(path)
	var ai: Variant = script.new()
	var state: Variant = _fixture()
	var bot: Dictionary = state.units[2]
	var cell: Dictionary = _cell(state, Vector2(-18, 24))
	_check(state.is_point_visible(0, cell.pos), "fixture really observes high-ground cell")
	ai.think(state)
	_check(bot.get("objective_kind", "") == "cell" and bot.target_id == cell.id, "healthy bot attacks a visible cell with a real command")
	var player: Dictionary = state.units[state.controlled_id]
	_check(player.order == "idle" and not player.has("objective_kind"), "objective AI does not take over controlled hero")
	var held_id: int = int(bot.get("objective_id", -1))
	ai.think(state)
	_check(int(bot.get("objective_id", -2)) == held_id, "repeated think retains the selected cell")
	state.apply_damage(bot.id, cell.id, 10000.0, state.next_action_id())
	ai.think(state)
	_check(bot.get("objective_kind", "") == "return", "completed cell task returns to home lane")
	_check(bot.lane == 0 and bot.goal.distance_to(Vector2(-18, 18)) < 0.2, "return preserves lane and uses the lane projection")
	bot.pos = bot.goal
	bot.path.clear()
	ai.think(state)
	_check(bot.get("objective_kind", "") == "" and float(bot.get("objective_cooldown", 0)) > state.time, "arriving home ends task and prevents immediate oscillation")

	state = _fixture()
	bot = state.units[2]
	cell = _cell(state, Vector2(-18, 24))
	bot.pos = Vector2(-18, 18)
	state._visibility_cache.clear()
	_check(not state.is_point_visible(0, cell.pos), "fixture hides plateau from low observer")
	ai.think(state)
	_check(bot.get("objective_kind", "") != "cell", "bot cannot choose an unseen high-ground cell")
	bot.pos = Vector2(-18, 22.5)
	state._visibility_cache.clear()
	ai.think(state)
	_check(bot.get("objective_kind", "") == "cell", "climbing enables observed-cell acquisition")
	bot.pos = Vector2(-18, 18)
	state._visibility_cache.clear()
	ai.think(state)
	_check(bot.get("objective_kind", "") == "return", "lost sight abandons task without chasing hidden position")

	state = _fixture()
	bot = state.units[2]
	cell = _cell(state, Vector2(-18, 24))
	bot.hp = bot.max_hp * 0.25
	ai.think(state)
	_check(bot.ai_retreat and bot.get("objective_kind", "") != "cell", "low HP retains recovery priority over XP")

	state = _fixture()
	bot = state.units[2]
	cell = _cell(state, Vector2(-18, 24))
	ai.think(state)
	state.time = float(bot.get("objective_until", 0)) + 0.1
	ai.think(state)
	_check(bot.get("objective_kind", "") == "return", "objective timeout guarantees a route back")

	state = _fixture()
	bot = state.units[2]
	bot.pos = Vector2(0, 0)
	var ally: Dictionary = state._entity("hero", 0, Vector2(12, 0), 500.0, 0.45)
	ally.hero = "bas"
	ally.lane = 1
	var enemy: Dictionary = state._entity("hero", 1, Vector2(13, 0), 500.0, 0.45)
	enemy.hero = "bas"
	state._visibility_cache.clear()
	ai.think(state)
	_check(bot.get("objective_kind", "") == "support" and bot.target_id == enemy.id, "team-visible nearby ally fight creates bounded support task")

	state = _fixture()
	bot = state.units[2]
	bot.pos = Vector2(-40, 0)
	var core: Dictionary = state._entity("core", 0, Vector2(-50, 0), 4000, 2)
	core.locked = false
	enemy = state._entity("hero", 1, Vector2(-44, 0), 500, 0.45)
	enemy.hero = "bas"
	state._visibility_cache.clear()
	ai.think(state)
	_check(bot.get("objective_kind", "") == "defend", "visible own-core danger outranks farming")

	state = _fixture()
	bot = state.units[2]
	cell = _cell(state, Vector2(-18, 24))
	var second: Dictionary = state._entity("hero", 0, Vector2(-18.8, 22.6), 1000, 0.45)
	second.merge({"hero": "nema", "lane": 0, "speed": 6.0, "attack_range": 5.5, "max_energy": 100.0, "energy": 100.0, "points": 0}, true)
	ai.think(state)
	_check(not (bot.get("objective_kind", "") == "cell" and second.get("objective_kind", "") == "cell" and bot.get("objective_id", -1) == second.get("objective_id", -2)), "two bots do not reserve the same cell")
	_finish()

func _fixture() -> Variant:
	var state: Variant = State.new()
	state.reset("bas", false)
	var player: Dictionary = state.units[1]
	var bot: Dictionary = state.units[2]
	state.units.clear()
	state.units[1] = player
	state.units[2] = bot
	state.controlled_id = 1
	state.time = 35.0
	bot.pos = Vector2(-18, 22.5)
	bot.lane = 0
	bot.points = 0
	bot.order = "idle"
	bot.path.clear()
	return state

func _cell(state: Variant, position: Vector2) -> Dictionary:
	var cell: Dictionary = state._entity("cell", 2, position, 180, 0.55)
	cell.xp_reward = 40.0
	cell.cell_tier = "high"
	return cell

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _finish() -> void:
	print("Tactical objectives: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
