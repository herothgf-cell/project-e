extends SceneTree
## Reproduce fixed-lane siege stalls through real tactical commands and movement.
const State = preload("res://scripts/battle/battle_state.gd")
const AI = preload("res://scripts/battle/tactical_ai.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Variant = _fixture()
	_open_lane(state, 1, 0)
	var bot: Dictionary = state.units[1]
	var core: Dictionary = _core(state, 1)
	_check(not state.is_visible(0, core.id), "enemy core is actually outside current team sight")
	state._ai.think(state)
	_check(bot.lane == 0, "recovered bot leaves home through the publicly breached lane")
	_check(state.units[3].lane == 2, "one bot keeps the third lane when two heroes already cover the breach")
	_check(int(state.stats.get("siege_redeployments", 0)) == 1, "one departure creates one redeployment, not a repeated task")
	_check(bot.order == "move" and bot.target_id == -1, "public breach planning issues movement without attacking a hidden core")
	for index: int in range(120):
		state.step(1.0 / 30.0)
	_check(bot.pos.y > 8.0 and bot.pos.x > -45.0, "the real hero walks into the opened left lane rather than resuming the blocked center")
	_check(state.map.is_walkable(bot.pos, bot.radius), "redeployment remains on authoritative walkable terrain")
	_check(int(state.stats.get("siege_redeployments", 0)) == 1, "moving along the selected lane does not repeatedly redeploy")

	state = _fixture()
	bot = state.units[1]
	state._ai._hero(state, bot)
	_check(bot.lane == 1, "locked enemy base does not redirect an early-game lane")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[2]
	state._ai._hero(state, bot)
	_check(bot.lane == 0 and int(state.stats.get("siege_redeployments", 0)) == 0, "a hero already assigned to the opened lane keeps its role")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	bot.pos = Vector2(-15, 0)
	state._ai._hero(state, bot)
	_check(bot.lane == 1, "a healthy hero in the field does not cut across defended lanes")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	bot.hp = bot.max_hp * 0.84
	bot.ai_retreat = true
	state._ai._hero(state, bot)
	_check(bot.lane == 1 and bot.ai_retreat, "recovering hero continues recovery before a new lane assignment")
	bot.hp = bot.max_hp * 0.85
	state._ai._hero(state, bot)
	_check(bot.lane == 0, "existing 85-percent recovery threshold enables the next departure")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	state.units[2].lane = 0
	state.controlled_id = 2
	state.units[3].lane = 0
	state.units[3].alive = false
	state._ai.think(state)
	_check(bot.lane == 1, "controlled and dead allied heroes reserve their lane slots")
	_check(state.units[2].order == "idle", "redeployment never issues commands for the controlled hero")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	state.controlled_id = bot.id
	state._ai.think(state)
	_check(bot.lane == 1 and bot.order == "idle", "the player's own assignment and orders remain under player control")

	state = _fixture()
	_open_lane(state, 1, 0)
	_open_lane(state, 0, 1)
	bot = state.units[1]
	var defender: Dictionary = state.units[4]
	defender.pos = Vector2(-46.5, 0)
	state._visibility_cache.clear()
	state._ai._hero(state, bot)
	_check(bot.lane == 1 and bot.get("objective_kind", "") == "defend", "observed danger to our exposed core retains defense priority")
	_check(bot.target_id == defender.id, "defense submits an actual attack command against the visible intruder")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	bot.objective_kind = "defend"
	bot.objective_id = 4
	bot.objective_until = 999.0
	state._ai._hero(state, bot)
	_check(bot.lane == 1, "an existing defense task is resolved before a fresh departure assignment")

	state = _fixture()
	_open_lane(state, 1, 0)
	_open_lane(state, 1, 2)
	bot = state.units[1]
	state._ai._hero(state, bot)
	_check(bot.lane == 0, "equal opened-lane options use stable left-to-right assignment")

	state = _fixture()
	_open_lane(state, 0, 2)
	bot = state.units[4]
	state._ai._hero(state, bot)
	_check(bot.lane == 2, "the opposing team uses the same safe-home redeployment rule")

	# A lane reassignment does not grant sight, minion support, or damage bypasses.
	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	state._ai._hero(state, bot)
	bot.pos = Vector2(44, 0)
	bot.path.clear()
	bot.order = "idle"
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 1:
			unit.alive = false
	core = _core(state, 1)
	state._visibility_cache.clear()
	state._ai._hero(state, bot)
	_check(bot.target_id != core.id, "arriving without a wave retains the existing unsupported-core gate")
	var minion: Dictionary = state._entity("minion", 0, Vector2(45, 0), 240.0, 0.3)
	minion.subtype = "melee"
	state._visibility_cache.clear()
	state._ai._hero(state, bot)
	_check(bot.target_id == core.id and bot.order == "attack", "visible supported core still receives the normal attack command")
	minion.alive = false
	state._ai._hero(state, bot)
	_check(bot.target_id != core.id, "support loss re-enters normal lane logic instead of holding a special siege task")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	bot.objective_kind = "support"
	bot.objective_id = 4
	bot.objective_until = 999.0
	bot.objective_deaths = bot.deaths
	state.apply_damage(4, bot.id, 100000.0, state.next_action_id())
	_check(not bot.alive, "lifecycle scenario uses an actual combat death")
	state._timers(bot, bot.respawn_left + 1.0)
	_check(bot.alive and state.is_in_home_base(bot.id), "authority respawns the hero at home")
	state._ai._hero(state, bot)
	_check(bot.lane == 0 and bot.get("objective_kind", "") == "" and int(bot.get("objective_id", -1)) == -1, "respawn clears the old task and permits a fresh safe departure")

	_test_task_precedence()

	print("Siege V9: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_task_precedence() -> void:
	var state: Variant = _fixture()
	var bot: Dictionary = state.units[1]
	var ally: Dictionary = state.units[2]
	var foe: Dictionary = state.units[4]
	bot.pos = Vector2(-56, 0)
	ally.pos = Vector2(-45, 0)
	foe.pos = Vector2(-43, 0)
	state._visibility_cache.clear()
	state._ai._hero(state, bot)
	_check(bot.get("objective_kind", "") == "support" and bot.target_id == foe.id, "a visible ally fight actually starts a support attack from home")
	state.apply_damage(foe.id, ally.id, 100000.0, state.next_action_id())
	_open_lane(state, 1, 0)
	state._ai._hero(state, bot)
	_check(bot.lane == 1 and bot.get("objective_kind", "") == "support", "a new breach cannot cancel an active support assignment")
	_check(bot.order == "attack" and bot.target_id == foe.id, "support retains its real attack command after the aided ally dies")
	_check(int(state.stats.get("siege_redeployments", 0)) == 0, "continuing a support task does not record a new departure")

	state = _fixture()
	bot = state.units[1]
	bot.pos = Vector2(-42, 0)
	state._ai._begin(state, bot, state.units[4], "support")
	bot.pos = Vector2(-56, 0)
	state._ai._abort(state, bot)
	_check(bot.get("objective_kind", "") == "return" and bot.goal.is_equal_approx(Vector2(-42, 0)), "aborting a real task produces a lane-return movement order")
	_open_lane(state, 1, 0)
	state._ai._hero(state, bot)
	_check(bot.lane == 1 and bot.get("objective_kind", "") == "return" and bot.goal.is_equal_approx(Vector2(-42, 0)), "a new breach does not replace an active return route")

	state = _fixture()
	bot = state.units[1]
	var cell: Dictionary = state._entity("cell", 2, Vector2(-55, 0), 180.0, 0.55)
	cell.xp_reward = 40.0
	state._visibility_cache.clear()
	state._ai._hero(state, bot)
	_check(bot.get("objective_kind", "") == "cell" and bot.target_id == cell.id, "home-side visible cell fixture starts a real resource task")
	_open_lane(state, 1, 0)
	state._ai._hero(state, bot)
	_check(bot.lane == 1 and bot.get("objective_kind", "") == "cell" and bot.target_id == cell.id, "resource-task commitment is resolved before a fresh departure")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	bot.cooldowns.Q = 0.0
	_check(state.command_cast(bot.id, "Q", bot.pos + Vector2(3, 0)) and bot.phase == "windup", "busy fixture uses an actual authoritative skill cast")
	var cast_id: int = int(bot.cast.id)
	state._ai._hero(state, bot)
	_check(bot.lane == 1 and bot.phase == "windup" and int(bot.cast.id) == cast_id, "ongoing cast precedes any home-departure reassignment")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	_check(state.apply_cc(bot.id, "stun", 0.5) > 0.0, "stun fixture uses the combat control authority")
	state._ai._hero(state, bot)
	_check(bot.lane == 1 and bot.stun_left > 0.0 and bot.order == "idle", "stunned heroes do not begin a new departure assignment")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	bot.objective_kind = "defend"
	bot.objective_id = 4
	bot.objective_until = 999.0
	bot.objective_deaths = bot.deaths
	state.apply_damage(4, bot.id, 100000.0, state.next_action_id())
	state._timers(bot, bot.respawn_left + 1.0)
	state._ai._hero(state, bot)
	_check(bot.alive and bot.lane == 0 and bot.get("objective_kind", "") == "", "previous-life defense is cleared before choosing the respawn departure")

	state = _fixture()
	_open_lane(state, 1, 0)
	bot = state.units[1]
	bot.pos = Vector2(-53.1, 0)
	bot.hp = bot.max_hp * 0.84
	bot.ai_retreat = true
	state._ai._hero(state, bot)
	_check(bot.lane == 1 and bot.ai_retreat, "hero at the forward base edge still recovers below 85 percent")
	state._timers(bot, 0.05)
	state._ai._hero(state, bot)
	_check(bot.lane == 0 and not bot.ai_retreat, "actual base healing to 85 percent enables redeployment before leaving the base edge")

func _fixture() -> Variant:
	var state: Variant = State.new()
	state._ai = AI.new()
	state.reset("bas", false)
	state.controlled_id = -1
	state._next_wave = INF
	state._next_income = INF
	state._cells_spawned = true
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero":
			unit.points = 0
			unit.credits = 0.0
			unit.cooldowns = {"Q": 999.0, "W": 999.0, "E": 999.0, "R": 999.0}
	return state

func _open_lane(state: Variant, team: int, lane: int) -> void:
	for unit: Dictionary in state.units.values():
		if unit.kind == "tower" and unit.team == team and unit.lane == lane:
			unit.hp = 0.0
			unit.alive = false
	state.refresh_locks()
	state._visibility_cache.clear()

func _core(state: Variant, team: int) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.kind == "core" and unit.team == team:
			return unit
	return {}

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
