extends SceneTree
## PDF p4 ordinary lane units reserve the final blow for heroes or major units.

const StateScript: Script = preload("res://scripts/battle/battle_state.gd")
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_test_regular_basic_attacks_and_last_hit()
	_test_armor_shields_and_fractional_health()
	_test_minions_resume_lane()
	_test_minions_retarget_and_strip_shields()
	_test_siege_and_tower_finish()
	_test_structure_last_hit()
	print("COT reference V6: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _fixture() -> Variant:
	var state: Variant = StateScript.new()
	state.reset("bas")
	state.bots_enabled = false
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero":
			unit.pos = Vector2(-56.0 if unit.team == 0 else 56.0, float(unit.lane - 1) * 2.0)
			unit.protected = 0.0
	state.units[state.controlled_id].pos = Vector2(-2.0, 0.0)
	state._wave = 3
	state._spawn_wave()
	return state


func _minion(state: Variant, team: int, subtype: String) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.kind == "minion" and unit.team == team and unit.lane == 1 and unit.subtype == subtype:
			return unit
	return {}


func _enemy_hero(state: Variant) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 1 and unit.hero == "bas":
			return unit
	return {}


func _tower(state: Variant, team: int) -> Dictionary:
	for unit: Dictionary in state.units.values():
		if unit.kind == "tower" and unit.team == team and unit.lane == 1 and unit.subtype == "outer":
			return unit
	return {}


func _test_regular_basic_attacks_and_last_hit() -> void:
	for subtype: String in ["melee", "ranged"]:
		var state: Variant = _fixture()
		var actor: Dictionary = _minion(state, 0, subtype)
		var target: Dictionary = _minion(state, 1, "melee")
		var hero: Dictionary = state.units[state.controlled_id]
		actor.pos = Vector2(-1.0, 0.0)
		target.pos = Vector2.ZERO
		target.hp = 5.0
		state._start_basic(actor, target)
		state._release_basic(actor)
		if subtype == "ranged":
			_check(state.projectiles.size() == 1, "ranged basic creates a real projectile")
			if not state.projectiles.is_empty():
				_check(not state._basic_projectile_step(state.projectiles[0], 0.1), "ranged projectile resolves its impact")
		_check(target.alive, "%s basic reserves the last hit" % subtype)
		_near(target.hp, 1.0, "%s basic leaves one HP" % subtype)
		_near(state.stats.damage, 4.0, "%s records only applied damage" % subtype)
		_near(state.apply_damage(actor.id, target.id, 100.0, state.next_action_id()), 0.0, "repeated attack at reserve deals no damage")
		_near(target.hp, 1.0, "repeat attack preserves reserve")
		_near(hero.xp, 0.0, "reserved target grants no early experience")
		_near(hero.credits, 100.0, "reserved target grants no early credits")
		state.apply_damage(hero.id, target.id, 1.0, state.next_action_id())
		_check(not target.alive, "hero finishes the reserved target")
		_near(hero.xp, 20.0, "hero receives nearby minion experience")
		_near(hero.credits, 116.0, "hero receives twelve shared credits plus four last-hit credits")


func _test_armor_shields_and_fractional_health() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _minion(state, 0, "ranged")
	var target: Dictionary = _enemy_hero(state)
	target.pos = Vector2.ZERO
	target.hp = 10.0
	target.armor = 100.0
	state.add_shield(target.id, "reference", 6.0, 5.0)
	_near(state.apply_damage(actor.id, target.id, 10.0, state.next_action_id()), 5.0, "armor mitigates before shield absorption")
	_near(target.hp, 10.0, "shield absorbs the initial hit")
	_near(target.shield, 1.0, "initial hit consumes five shield")
	_near(state.apply_damage(actor.id, target.id, 100.0, state.next_action_id()), 10.0, "lethal hit spends remaining shield and nine HP")
	_near(target.shield, 0.0, "reserve permits full shield depletion")
	_near(target.hp, 1.0, "armored hero retains one HP")
	_check(target.alive and state.stats.hero_deaths == 0, "regular minion cannot finish a hero")
	target.hp = 0.5
	_near(state.apply_damage(actor.id, target.id, 100.0, state.next_action_id()), 0.0, "fractional reserve receives no damage")
	_near(target.hp, 0.5, "reserve never heals a fractional HP target")


func _test_minions_resume_lane() -> void:
	for subtype: String in ["melee", "ranged"]:
		var state: Variant = _fixture()
		var actor: Dictionary = _minion(state, 0, subtype)
		var target: Dictionary = _minion(state, 1, "melee")
		actor.pos = Vector2(-1.0, 0.0)
		target.pos = Vector2.ZERO
		target.hp = 1.0
		state.command_attack(actor.id, target.id)
		state._ai._minion(state, actor)
		_check(actor.target_id == -1 and actor.order == "move", "%s releases the exhausted target and resumes its lane" % subtype)
		_check(actor.goal.x > actor.pos.x and not actor.path.is_empty(), "%s receives a forward lane path" % subtype)
		state.step(1.2)
		_check(actor.pos.x > -0.5, "%s advances instead of swinging forever at one HP" % subtype)
		_check(actor.target_id != target.id, "%s does not reacquire the exhausted target" % subtype)


func _test_minions_retarget_and_strip_shields() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _minion(state, 0, "melee")
	var exhausted: Dictionary = _minion(state, 1, "melee")
	var eligible: Dictionary = _enemy_hero(state)
	actor.pos = Vector2(-1.0, 0.0)
	exhausted.pos = Vector2.ZERO
	exhausted.hp = 1.0
	eligible.pos = Vector2(2.0, 0.0)
	state.command_attack(actor.id, exhausted.id)
	state._ai._minion(state, actor)
	_check(actor.target_id == eligible.id, "minion selects a damageable hero over an exhausted minion")
	eligible.hp = 1.0
	state.add_shield(eligible.id, "reference", 5.0, 5.0)
	state._ai._minion(state, actor)
	_check(actor.target_id == eligible.id, "one-HP target remains eligible while shielded")
	_near(state.apply_damage(actor.id, eligible.id, 100.0, state.next_action_id()), 5.0, "minion removes the shield at the HP reserve")
	_near(eligible.hp, 1.0, "shield stripping preserves final HP")
	state._ai._minion(state, actor)
	_check(actor.target_id == -1 and actor.order == "move", "minion advances after the remaining shield is spent")


func _test_siege_and_tower_finish() -> void:
	var state: Variant = _fixture()
	var siege: Dictionary = _minion(state, 0, "siege")
	var target: Dictionary = _minion(state, 1, "melee")
	siege.pos = Vector2(-1.0, 0.0)
	target.pos = Vector2.ZERO
	target.hp = 1.0
	state._ai._minion(state, siege)
	_check(siege.target_id == target.id, "siege unit can select a one-HP target")
	state.apply_damage(siege.id, target.id, 100.0, state.next_action_id())
	_check(not target.alive, "siege unit can deliver a lethal hit")
	var hero: Dictionary = _enemy_hero(state)
	hero.hp = 1.0
	state.apply_damage(_tower(state, 0).id, hero.id, 100.0, state.next_action_id())
	_check(not hero.alive and state.stats.hero_deaths == 1, "tower can deliver a lethal hit")


func _test_structure_last_hit() -> void:
	var state: Variant = _fixture()
	var actor: Dictionary = _minion(state, 0, "melee")
	var target: Dictionary = _tower(state, 1)
	target.hp = 5.0
	state.apply_damage(actor.id, target.id, 100.0, state.next_action_id())
	_check(target.alive, "regular minion reserves a structure's final hit")
	_near(target.hp, 1.0, "structure retains one HP after siege mitigation")
	state.apply_damage(state.controlled_id, target.id, 100.0, state.next_action_id())
	_check(not target.alive, "hero can finish the reserved structure")


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.02, "%s (expected %.3f, got %.3f)" % [label, expected, actual])


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
