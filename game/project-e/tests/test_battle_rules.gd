extends SceneTree
## Exercises observable combat behavior; the fixture uses the real match state.

const STATE_PATH: String = "res://scripts/battle/battle_state.gd"
var checks: int = 0
var failures: int = 0
var state_script: Script


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists(STATE_PATH):
		_check(false, "Battle state is not implemented yet")
		_finish()
		return
	state_script = load(STATE_PATH)
	if state_script == null or not state_script.can_instantiate():
		_check(false, "Battle state must load")
		_finish()
		return
	_test_damage_and_shields()
	_test_command_validation()
	_test_bas_kit()
	_test_rio_kit()
	_test_nema_kit()
	_test_cc_and_death()
	_test_rooted_dash_windup()
	_test_queued_ability()
	_test_new_attack_replaces_queued_cast()
	_test_cone_outer_corner()
	_test_growth()
	_finish()


func _fixture(hero: String = "bas") -> Variant:
	var state: Variant = state_script.new()
	state.reset(hero)
	state.bots_enabled = false
	for id: int in state.units:
		var unit: Dictionary = state.units[id]
		if unit.kind == "hero":
			unit.pos = Vector2(-56.0 if unit.team == 0 else 56.0, float(unit.lane - 1) * 2.0)
			unit.protected = 0.0
	state.units[state.controlled_id].pos = Vector2(-2.0, 0.0)
	_enemy(state).pos = Vector2(0.0, 0.0)
	return state


func _enemy(state: Variant) -> Dictionary:
	for id: int in state.units:
		var unit: Dictionary = state.units[id]
		if unit.kind == "hero" and unit.team == 1 and unit.hero == "bas":
			return unit
	return {}


func _ally(state: Variant) -> Dictionary:
	for id: int in state.units:
		var unit: Dictionary = state.units[id]
		if unit.kind == "hero" and unit.team == 0 and id != state.controlled_id:
			return unit
	return {}


func _test_damage_and_shields() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	enemy.armor = 100.0
	state.add_shield(enemy.id, "test", 30.0, 2.0)
	state.apply_damage(actor.id, enemy.id, 100.0, 700, "one")
	_near(enemy.hp, 1080.0, "armor applies before 30 shield absorbs 50 damage")
	_near(enemy.shield, 0.0, "shield is consumed first")
	state.apply_damage(actor.id, enemy.id, 100.0, 700, "one")
	_near(enemy.hp, 1080.0, "same cast-stage cannot hit twice")
	state.apply_damage(actor.id, enemy.id, 100.0, 700, "two")
	_near(enemy.hp, 1030.0, "different explicit stage can hit once")
	var ally: Dictionary = _ally(state)
	state.apply_damage(actor.id, ally.id, 500.0, 701, "one")
	_near(ally.hp, ally.max_hp, "friendly fire rejected by damage authority")
	state.add_shield(actor.id, "a", 100.0, 2.0)
	state.add_shield(actor.id, "a", 80.0, 2.0)
	state.add_shield(actor.id, "b", 40.0, 1.0)
	_near(actor.shield, 140.0, "same source refreshes max and distinct source stacks")
	state.step(1.1)
	_near(actor.shield, 100.0, "shield source expires independently")


func _test_command_validation() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	_check(not state.command_cast(actor.id, "Q", Vector2(NAN, 0.0)), "NaN cast rejected")
	_check(not state.command_cast(actor.id, "W", Vector2(20.0, 0.0)), "out-of-range ground cast rejected")
	_check(not state.command_cast(actor.id, "R", Vector2(5.0, 0.0)), "level-one R remains locked")
	_near(actor.energy, 100.0, "rejected casts cost no energy")
	_near(actor.cooldowns.Q, 0.0, "rejected casts start no cooldown")
	actor.energy = 15.0
	_check(not state.command_cast(actor.id, "Q", Vector2(1.0, 0.0)), "insufficient energy rejected")
	_check(not state.command_attack(actor.id, _ally(state).id), "friendly attack command rejected")
	_enemy(state).pos = Vector2(32.0, 0.0)
	_check(not state.command_attack(actor.id, _enemy(state).id), "unseen target cannot be selected")
	_check(not state.command_move(actor.id, Vector2(0.0, 9.0)), "wall/water move rejected")
	_check(not state.command_move(actor.id, Vector2(INF, 0.0)), "infinite move rejected")


func _test_bas_kit() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	_check(state.command_cast(actor.id, "Q", enemy.pos), "Bas Q accepted")
	_near(actor.energy, 84.0, "Bas Q exact approval cost")
	state.step(0.19)
	_near(enemy.hp, 1100.0, "Bas Q cannot damage before warning ends")
	state.step(0.23)
	_near(enemy.hp, 965.0, "Bas Q applies 135 once")
	_check(actor.pressure == 1, "Bas Q gains one visible pressure")
	_check(state.command_cast(actor.id, "W", actor.pos), "Bas W accepted")
	state.step(0.3)
	_near(actor.shield, 135.0, "Bas W grants 135 shield")
	_check(state.command_cast(actor.id, "E", enemy.pos), "Bas E accepted")
	state.step(0.65)
	_near(enemy.hp, 880.0, "Bas E contacts first hero for 85")
	_check(actor.pressure == 2, "two distinct hit casts prepare Bas passive")
	_check(actor.pos.distance_to(enemy.pos) >= 0.89, "dash does not overlap hero capsules")
	_check(state.command_attack(actor.id, enemy.id), "Bas basic attack accepted")
	state.step(0.5)
	_near(enemy.hp, 790.0, "Bas basic attack resolves for 90")
	_check(actor.pressure == 0 and actor.shield >= 105.0, "Bas basic consumes pressure for passive shield")
	state = _fixture()
	actor = state.units[state.controlled_id]
	enemy = _enemy(state)
	actor.level = 3
	state.invest(actor.id, "R")
	_check(state.command_cast(actor.id, "R", Vector2(5.0, 0.0)), "Bas R unlocked with point")
	state.step(0.7)
	_near(enemy.hp, 865.0, "Bas R deals one 235 hit")
	_check(enemy.root_left > 0.0, "Bas R roots")


func _test_rio_kit() -> void:
	var state: Variant = _fixture("rio")
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	actor.energy_regen = 0.0
	_check(state.command_cast(actor.id, "Q", Vector2(6.0, 0.0)), "Rio Q accepted")
	state.step(2.0)
	_near(enemy.hp, 900.0, "Rio outbound and return hit exactly once each")
	_near(actor.energy, 88.0, "Rio double hero hit refunds 8 exactly once")
	_check(state.projectiles.is_empty(), "Rio disc reaches fixed destination and expires")
	_check(state.command_cast(actor.id, "W", enemy.pos), "Rio W accepted")
	state.step(0.4)
	_near(enemy.hp, 835.0, "Rio W installation pulse deals 65 once")
	_check(not actor.return_mark.is_empty(), "Rio W leaves timed return marker")
	_check(state.command_cast(actor.id, "E", Vector2(-5.0, 0.0)), "Rio E accepted")
	state.step(0.5)
	_check(actor.empowered_left > 0.0, "Rio normal E completion grants enhanced attack")
	state.command_attack(actor.id, enemy.id)
	state.step(0.8)
	_near(enemy.hp, 680.0, "Rio enhanced attack deals 90+65")
	state = _fixture("rio")
	actor = state.units[state.controlled_id]
	enemy = _enemy(state)
	actor.level = 3
	state.invest(actor.id, "R")
	actor.pos = Vector2(-3.0, 0.0)
	enemy.pos = Vector2(0.0, 0.0)
	var inside: Dictionary = _ally(state)
	inside.team = 1
	inside.pos = Vector2(0.0, 1.25)
	_check(state.command_cast(actor.id, "R", Vector2(3.0, 0.0)), "Rio legal triangle accepted")
	state.step(0.8)
	_near(enemy.hp, 880.0, "Rio R border deals 220")
	_near(inside.hp, inside.max_hp, "Rio R interior is safe")
	_near(actor.energy, 74.4, "Rio R costs 32 and recovers normally")


func _test_nema_kit() -> void:
	var state: Variant = _fixture("nema")
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	_check(not state.command_cast(actor.id, "W", enemy.pos), "Nema W requires pins")
	_check(state.command_cast(actor.id, "Q", Vector2(-1.0, 0.0)), "Nema first pin accepted")
	state.step(0.4)
	_check(actor.pins.size() == 1, "Nema Q creates a pin")
	_near(enemy.hp, 1000.0, "Nema Q pulse deals 100")
	state.step(2.2)
	_check(state.command_cast(actor.id, "Q", Vector2(2.0, 0.0)), "Nema second pin accepted")
	state.step(0.4)
	_check(actor.pins.size() == 2, "Nema retains exactly two pins")
	var pin: Dictionary = state.units[actor.pins[0]]
	pin.hp = 80.0
	var expiry: float = pin.expires
	_check(state.command_cast(actor.id, "E", Vector2(2.0, 0.0)), "Nema E accepted")
	state.step(0.35)
	_near(pin.hp, 130.0, "Nema E repairs own pin by 50")
	_near(pin.expires, expiry, "Nema E never extends device lifetime")
	_check(actor.shield >= 140.0, "Nema E shields herself without healing HP")
	_check(state.command_cast(actor.id, "W", enemy.pos), "Nema linked W accepted")
	state.step(0.5)
	_near(enemy.hp, 880.0, "Nema linked W deals 120 once")
	actor.level = 3
	state.invest(actor.id, "R")
	_check(state.command_cast(actor.id, "R", enemy.pos), "Nema linked R accepted")
	state.step(0.8)
	_near(enemy.hp, 695.0, "Nema R deals 185")
	_check(actor.pins.is_empty(), "Nema R consumes both pins")
	_check(enemy.root_left > 0.0, "Nema R roots its target")
	state = _fixture("nema")
	actor = state.units[state.controlled_id]
	state.command_cast(actor.id, "Q", Vector2(-1.0, 0.0))
	state.step(0.4)
	state.command_cast(actor.id, "W", Vector2.ZERO)
	state.apply_damage(_enemy(state).id, actor.pins[0], 200.0, 800, "one")
	state.step(0.5)
	_near(_enemy(state).hp, 1000.0, "destroyed participating pin cancels queued W damage")
	_check(actor.cooldowns.W > 0.0, "pin cancellation does not refund cooldown")


func _test_cc_and_death() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	state.command_cast(actor.id, "Q", enemy.pos)
	state.apply_cc(actor.id, "stun", 1.0)
	state.step(0.4)
	_near(enemy.hp, 1100.0, "stun cancels windup damage")
	_check(actor.energy < 100.0 and actor.cooldowns.Q > 0.0, "interrupted accepted cast retains cost and cooldown")
	state.step(0.7)
	state.apply_cc(actor.id, "root", 1.0)
	_check(actor.root_left <= 0.5001, "rolling CC budget caps a second disable")
	_check(not state.command_cast(actor.id, "E", Vector2.RIGHT), "root blocks dash")
	_check(state.command_cast(actor.id, "W", actor.pos), "root permits stationary shield skill")
	state.apply_damage(enemy.id, actor.id, 10000.0, 801, "one")
	_check(not actor.alive, "lethal damage causes death")
	_check(not state.command_move(actor.id, Vector2(2.0, 0.0)), "dead actor cannot move")
	_check(not state.command_cast(actor.id, "Q", enemy.pos), "dead actor cannot cast")
	_near(actor.respawn_left, 10.0, "level-one death uses ten-second respawn")
	state.step(10.1)
	_check(actor.alive and actor.hp == actor.max_hp, "respawn restores full HP")
	_check(actor.protected > 0.0, "respawn grants temporary protection")
	_check(actor.pressure == 0 and actor.shield == 0.0, "death clears transient combat state")


func _test_growth() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	_check(actor.level == 1 and actor.points == 2 and not actor.r_unlocked, "normal match starts without ultimate")
	_check(state.invest(actor.id, "hp"), "HP investment accepted")
	_near(actor.max_hp, 1180.0, "HP investment adds 80 max and current HP")
	state.award_xp(actor.id, 225.0)
	_check(actor.level == 3 and actor.points == 3, "225 XP reaches level three and awards two points")
	_near(actor.power, 106.0, "two level gains add six power")
	_check(not actor.r_unlocked, "level alone never unlocks R")
	_check(state.invest(actor.id, "R") and actor.r_unlocked, "one point explicitly unlocks R")
	_check(not state.invest(actor.id, "R"), "R cannot be bought twice")
	state.reset("rio", true)
	actor = state.units[state.controlled_id]
	_check(actor.level == 3 and actor.r_unlocked, "explicit practice mode starts with ultimate")


func _test_rooted_dash_windup() -> void:
	for hero: String in ["bas", "rio"]:
		var state: Variant = _fixture(hero)
		var actor: Dictionary = state.units[state.controlled_id]
		_enemy(state).pos = Vector2(5.0, 0.0)
		var start: Vector2 = actor.pos
		_check(state.command_cast(actor.id, "E", Vector2(4.0, 0.0)), hero + " E windup accepted")
		state.apply_cc(actor.id, "root", 1.0)
		state.step(0.4)
		_check(actor.pos.distance_to(start) < 0.001, hero + " cannot begin a dash after being rooted in windup")
		_check(actor.cooldowns.E > 0.0 and actor.energy < 100.0, hero + " interrupted E keeps its approved cost")
		_check(actor.empowered_left == 0.0, "interrupted E cannot grant Rio empowerment")


func _test_queued_ability() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	actor.energy_regen = 0.0
	_check(state.command_cast(actor.id, "Q", _enemy(state).pos), "first skill starts immediately")
	_check(state.command_cast(actor.id, "W", actor.pos), "one next skill can be queued during windup")
	_near(actor.energy, 84.0, "queued skill is not charged before approval")
	_near(actor.cooldowns.W, 0.0, "queued skill does not start cooldown early")
	state.step(0.8)
	_near(actor.shield, 135.0, "queued shield executes after prior recovery")
	_near(actor.energy, 66.0, "queued shield is charged once on execution")
	state = _fixture()
	actor = state.units[state.controlled_id]
	state.command_cast(actor.id, "Q", _enemy(state).pos)
	state.command_cast(actor.id, "W", actor.pos)
	state.command_stop(actor.id)
	state.step(0.8)
	_near(actor.shield, 0.0, "latest stop replaces a queued skill")


func _test_new_attack_replaces_queued_cast() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = _enemy(state)
	actor.energy_regen = 0.0
	_check(state.command_attack(actor.id, enemy.id), "initial attack starts")
	state.step(1.0 / 30.0)
	_check(actor.phase == "basic", "fixture reaches a real basic windup")
	_check(state.command_cast(actor.id, "W", actor.pos), "shield queues during basic windup")
	_check(state.command_attack(actor.id, enemy.id), "newer attack command is accepted")
	_check(actor.queued.is_empty(), "newer attack replaces the queued skill")
	state.step(0.6)
	_near(actor.energy, 100.0, "replaced shield never consumes energy")
	_near(actor.cooldowns.W, 0.0, "replaced shield never starts cooldown")
	_near(actor.shield, 0.0, "replaced shield never executes")
	_check(enemy.hp < enemy.max_hp, "replacement preserves the valid basic attack")
	# A newer invalid target must leave an accepted next action intact.
	state = _fixture()
	actor = state.units[state.controlled_id]
	state.command_attack(actor.id, _enemy(state).id)
	state.step(1.0 / 30.0)
	state.command_cast(actor.id, "W", actor.pos)
	_check(not state.command_attack(actor.id, _ally(state).id), "invalid newer friendly attack is rejected")
	_check(actor.queued.get("slot", "") == "W", "rejected input does not erase the accepted queued skill")


func _test_cone_outer_corner() -> void:
	var state: Variant = _fixture()
	var shape: Dictionary = {"shape": "cone", "origin": Vector2.ZERO, "target": Vector2(3.2, 0), "radius": 3.2, "angle": 80.0}
	# A center 3.64m away at 47 degrees is 0.606m from the 40-degree corner.
	_check(not state._abilities.contains(shape, Vector2(2.482460, 2.662150), 0.45), "cone outer corner cannot hit a capsule outside the actual sector")
	_check(state._abilities.contains(shape, Vector2(2.545110, 2.373530), 0.45), "cone accepts a capsule actually overlapping its outer corner")


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.02, "%s (expected %.3f, got %.3f)" % [label, expected, actual])


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)


func _finish() -> void:
	print("Battle rules: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
