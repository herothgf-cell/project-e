extends SceneTree
const State = preload("res://scripts/battle/battle_state.gd")
const Abilities = preload("res://scripts/battle/hero_abilities.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	preview_contracts()
	orin()
	tere()
	mua()
	sera()
	lume()
	lifecycle()
	boundaries()
	sera_basic_power_snapshot()
	print("Hero abilities V8: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)

func arena(hero: String) -> Variant:
	var state = State.new()
	state.reset(hero, true)
	state.bots_enabled = false
	var actor: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = {}
	var ally: Dictionary = {}
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 1 and enemy.is_empty():
			enemy = unit
		if unit.kind == "hero" and unit.team == 0 and unit.id != actor.id and ally.is_empty():
			ally = unit
	for id: int in state.units.keys():
		if id not in [actor.id, enemy.id, ally.id]:
			state.units.erase(id)
	actor.pos = Vector2.ZERO
	actor.power = 100.0
	actor.energy_regen = 0.0
	enemy.pos = Vector2(2, 0)
	enemy.hp = 10000.0
	enemy.max_hp = 10000.0
	ally.pos = Vector2(-2, 0)
	state.set_meta("enemy_id", enemy.id)
	state.set_meta("ally_id", ally.id)
	state._visibility_cache.clear()
	return state

func player(state: Variant) -> Dictionary:
	return state.units[state.controlled_id]
func enemy(state: Variant) -> Dictionary:
	return state.units[state.get_meta("enemy_id")]
func ally(state: Variant) -> Dictionary:
	return state.units[state.get_meta("ally_id")]
func cast(state: Variant, slot: String, target: Vector2 = Vector2(2, 0), elapsed: float = 1.2) -> void:
	var actor: Dictionary = player(state)
	state.cancel_action(actor)
	actor.order = "idle"
	actor.path.clear()
	actor.energy = 100.0
	actor.cooldowns[slot] = 0.0
	check(state.command_cast(actor.id, slot, target), actor.hero + slot + " accepted")
	state.step(elapsed)
func near(actual: float, expected: float, label: String) -> void:
	check(absf(actual - expected) < 0.01, "%s (%0.2f / %0.2f)" % [label, actual, expected])
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)

func preview_contracts() -> void:
	for hero: String in ["orin", "tere", "mua", "sera", "lume"]:
		var state = arena(hero)
		var actor: Dictionary = player(state)
		if hero == "mua":
			check(not state.get_cast_preview(actor.id, "R", Vector2(2, 0)).valid, "Mua needs a zone")
			cast(state, "Q")
		for slot: String in ["Q", "W", "E", "R"]:
			actor.cooldowns[slot] = 0.0
			actor.energy = 100.0
			var plan: Dictionary = state.get_cast_preview(actor.id, slot, Vector2(2, 0))
			check(plan.valid, hero + slot + " valid preview")
			check(plan.radius > 0.0 or plan.width > 0.0, hero + slot + " explicit nonzero geometry")
			check(plan.movement == (hero in ["tere", "sera"] and slot == "E"), hero + slot + " movement contract")
			check(plan.cost == Abilities.CONFIG[hero][slot][0], hero + slot + " configured cost")

func orin() -> void:
	var state = arena("orin")
	var actor: Dictionary = player(state)
	var target: Dictionary = enemy(state)
	cast(state, "W")
	near(target.hp, 9945.0, "Orin W damage")
	check(actor.wind_ready_until > state.time, "Orin W prepares")
	actor.cooldowns.Q = 0.0
	var wave: Dictionary = state.get_cast_preview(actor.id, "Q", target.pos)
	near(wave.width, 2.4, "Orin prepared width")
	near(wave.origin.distance_to(wave.target), 5.0, "Orin prepared range")
	cast(state, "Q")
	near(target.hp, 9830.0, "Orin Q damage")
	check(actor.wind_ready_until == 0.0 and actor.empowered_left > 0.0, "Orin Q consumes and arms passive")
	state.cancel_action(actor)
	state._start_basic(actor, target)
	state._release_basic(actor)
	check(actor.empowered_left == 0.0, "Orin passive consumed once on shot")
	near(state.projectiles.back().damage, 140.0, "Orin empowered basic")
	state.projectiles.clear()
	state.cancel_action(actor)
	var base_speed: float = actor.speed
	cast(state, "E", Vector2(5, 0), 0.2)
	near(actor.speed, base_speed, "Orin haste leaves base speed")
	check(actor.speed_buffs.size() == 1, "Orin haste exists")
	ally(state).pos = Vector2(-5, 0)
	target.pos = Vector2(6, 0)
	state.cancel_action(actor)
	state.command_move(actor.id, Vector2(4, 0))
	state.step(0.5)
	check(actor.pos.x > base_speed * 0.5, "Orin haste affects actual walking")
	state.command_stop(actor.id)
	actor.pos = Vector2.ZERO
	target.pos = Vector2(2, 0)
	var before: float = target.hp
	cast(state, "R", target.pos, 0.65)
	near(before - target.hp, 125.0, "Orin R first wave")
	check(state.scheduled_hits.size() == 1, "Orin R pending second")
	var hit: Dictionary = state.scheduled_hits[0].duplicate(true)
	state.step(0.5)
	near(before - target.hp, 250.0, "Orin R two waves")
	state._abilities.area_damage(state, actor, hit, hit.amount, "", 0.0, 0.0, hit.hit_stage)
	near(before - target.hp, 250.0, "Orin stage cannot double hit")
	state.step(2.0)
	check(actor.speed_buffs.is_empty(), "Orin haste expires")

func tere() -> void:
	var state = arena("tere")
	var actor: Dictionary = player(state)
	cast(state, "Q", Vector2(2, 0), 0.3)
	near(enemy(state).hp, 9900.0, "Tere Q damage")
	check(not enemy(state).slows.is_empty(), "Tere Q slow")
	cast(state, "W", Vector2(2, 0), 0.2)
	near(ally(state).shield, 140.0, "Tere backward ally shield")
	near(actor.shield, 205.0, "Tere self and passive shield")
	near(enemy(state).shield, 0.0, "Tere ignores enemies")
	ally(state).pos = Vector2(-5, 4)
	enemy(state).pos = Vector2(-2, 0)
	cast(state, "E", Vector2(4, 0), 0.45)
	check(actor.pos.x > 2.0, "Tere retreat travels")
	check(state.scheduled_hits.size() == 1, "Tere retreat telegraphed")
	var before: float = enemy(state).hp
	state.step(0.5)
	near(before - enemy(state).hp, 95.0, "Tere fan strikes opposite at departure")
	actor.pos = Vector2.ZERO
	enemy(state).pos = Vector2(4, 0)
	cast(state, "R", Vector2(4, 0), 0.85)
	near(enemy(state).hp, before - 95.0 - 175.0, "Tere R damage")
	check(enemy(state).root_left > 0.0 and enemy(state).root_left <= 0.8, "Tere R root")

func mua() -> void:
	var state = arena("mua")
	var actor: Dictionary = player(state)
	var unit_count: int = state.units.size()
	cast(state, "Q", Vector2(2, 0), 0.3)
	near(enemy(state).hp, 9915.0, "Mua Q installation damage")
	check(actor.zones.size() == 1 and actor.zones[0].active, "Mua first zone active")
	check(state.units.size() == unit_count, "Mua zones are not units")
	var first_id: int = actor.zones[0].id
	cast(state, "Q", Vector2(-2, 0), 0.3)
	check(actor.zones.size() == 2 and actor.zones[1].active and not actor.zones[0].active, "Mua latest active")
	cast(state, "W", Vector2(2, 0), 0.2)
	check(actor.zones[0].active and not actor.zones[1].active, "Mua W switches zone")
	check(not actor.speed_buffs.is_empty(), "Mua W applies actual haste")
	cast(state, "Q", Vector2(1, 0), 0.3)
	check(actor.zones.size() == 2 and actor.zones[0].id != first_id, "Mua third replaces oldest")
	ally(state).pos = Vector2(1, 0)
	state.step(0.1)
	near(ally(state).shield, 50.0, "Mua passive entry shield")
	var ready: float = actor.passive_ready[ally(state).id]
	ally(state).pos = Vector2(-5, 0)
	state.step(0.1)
	ally(state).pos = Vector2(1, 0)
	state.step(0.1)
	near(actor.passive_ready[ally(state).id], ready, "Mua target entry cooldown")
	cast(state, "E", Vector2(2, 0), 0.2)
	near(ally(state).shield, 215.0, "Mua E active-zone bonus plus passive")
	var before: float = enemy(state).hp
	cast(state, "R", Vector2(2, 0), 0.7)
	near(before - enemy(state).hp, 190.0, "Mua R expanded damage")
	check(actor.zones.size() == 1 and actor.zones[0].active, "Mua R consumes only chosen zone")
	state.step(8.1)
	check(actor.zones.is_empty(), "Mua zones expire at eight seconds")
	# Independent same-team owners keep zones and passive cooldowns isolated.
	var second: Dictionary = ally(state)
	second.hero = "mua"
	second.pos = Vector2(-2, 0)
	second.power = 100.0
	second.r_unlocked = true
	second.energy = 100.0
	check(state.command_cast(second.id, "Q", Vector2(-2, 0)), "second Mua cast")
	state.step(0.3)
	check(second.zones.size() == 1 and actor.zones.is_empty(), "Mua owner isolation")
	actor.pos = Vector2(25, 0)
	second.pos = Vector2(25, 1)
	enemy(state).pos = Vector2(-2, 0)
	state._visibility_cache.clear()
	check(not state.is_visible(0, enemy(state).id), "Mua zones grant no vision")

func sera() -> void:
	var state = arena("sera")
	var actor: Dictionary = player(state)
	var target: Dictionary = enemy(state)
	cast(state, "Q")
	near(target.hp, 9895.0, "Sera Q damage")
	check(actor.marks[target.id].stacks == 1, "Sera Q mark")
	cast(state, "W", Vector2.ZERO, 0.2)
	near(actor.shield, 120.0, "Sera W shield")
	cast(state, "E", target.pos, 0.5)
	near(target.hp, 9815.0, "Sera E contact damage")
	check(actor.pos.x < target.pos.x - 0.89, "Sera dash respects hero collision")
	check(actor.marks[target.id].stacks == 2, "Sera E second mark")
	state.cancel_action(actor)
	state._start_basic(actor, target)
	state._release_basic(actor)
	near(target.hp, 9640.0, "Sera basic passive damage")
	check(actor.marks.is_empty(), "Sera passive consumes marks")
	cast(state, "Q")
	var before: float = target.hp
	cast(state, "R", target.pos, 0.45)
	near(before - target.hp, 200.0, "Sera R mark bonus")
	check(actor.marks.is_empty(), "Sera R consumes mark")
	state._abilities.expanded.add_mark(state, actor, target)
	state.step(5.1)
	check(actor.marks.is_empty(), "Sera marks expire")
	state._abilities.expanded.add_mark(state, actor, target)
	target.pos = Vector2(25, 0)
	state._visibility_cache.clear()
	check(state._abilities.expanded.mark_stacks(state, actor, target) == 0, "hidden Sera marks inaccessible")
	actor.marks.clear()
	state._abilities.expanded.add_mark(state, actor, target)
	check(actor.marks.is_empty(), "hidden enemy cannot gain mark")

func lume() -> void:
	var state = arena("lume")
	var actor: Dictionary = player(state)
	var target: Dictionary = enemy(state)
	cast(state, "Q", target.pos, 0.3)
	near(target.hp, 10000.0, "Lume Q remains telegraphed")
	state.step(0.3)
	near(target.hp, 9875.0, "Lume Q delayed explosion")
	cast(state, "W", target.pos, 0.2)
	near(target.hp, 9820.0, "Lume W damage")
	check(not target.slows.is_empty(), "Lume W slow")
	cast(state, "E", Vector2.ZERO, 0.2)
	near(actor.shield, 105.0, "Lume E shield")
	check(actor.speed_buffs.size() == 1 and actor.heat_count == 2, "Lume E haste does not count heat")
	var before: float = target.hp
	cast(state, "R", target.pos, 0.7)
	near(before - target.hp, 100.0, "Lume R first shell")
	check(state.scheduled_hits.size() == 2 and actor.heat_count == 3, "Lume R queues distinct shells and heat")
	for hit: Dictionary in state.scheduled_hits:
		check(hit.owner_id == actor.id and hit.slot == "R" and hit.duration > 0.0 and hit.remaining > 0.0, "scheduled telegraph contract")
	state.step(1.0)
	near(before - target.hp, 300.0, "Lume R three shell damage")
	before = target.hp
	cast(state, "Q", target.pos, 0.6)
	near(before - target.hp, 156.25, "Lume fourth offensive spell amplified")
	check(actor.heat_count == 0, "Lume heat consumed")

func lifecycle() -> void:
	for hero: String in ["tere", "sera"]:
		var state = arena(hero)
		var actor: Dictionary = player(state)
		state.apply_cc(actor.id, "root", 0.8)
		check(not state.command_cast(actor.id, "E", Vector2(4, 0)), hero + " root rejects movement")
		actor.root_left = 0.0
		check(state.command_cast(actor.id, "E", Vector2(4, 0)), hero + " movement windup starts")
		state.apply_cc(actor.id, "root", 0.8)
		check(actor.cast.is_empty() and actor.phase == "idle", hero + " root cancels movement windup")
	for hero: String in ["orin", "tere", "mua", "sera", "lume"]:
		var state = arena(hero)
		var actor: Dictionary = player(state)
		actor.stun_left = 0.8
		check(not state.command_cast(actor.id, "Q", Vector2(2, 0)), hero + " stun rejects")
		actor.stun_left = 0.0
		actor.protected = 3.0
		var support: String = "W" if hero in ["tere", "sera"] else "E"
		check(state.command_cast(actor.id, support, Vector2(2, 0)), hero + " support starts")
		check(actor.protected > 0.0, hero + " support preserves spawn protection")
		state.cancel_action(actor)
		actor.energy = 100.0
		check(state.command_cast(actor.id, "Q", Vector2(2, 0)), hero + " offense starts")
		near(actor.protected, 0.0, hero + " offense removes protection")
		state.apply_cc(actor.id, "stun", 0.5)
		check(actor.cast.is_empty(), hero + " stun cancels windup")
		actor.wind_ready_until = 100.0
		actor.heat_count = 3
		actor.zones.append({"id": 999, "pos": Vector2.ZERO, "radius": 2.0, "expires": 100.0, "active": true})
		actor.marks[enemy(state).id] = {"stacks": 2, "expires": 100.0}
		state._abilities.expanded.haste(state, actor, "test", 0.3, 2.0)
		state.apply_damage(enemy(state).id, actor.id, 100000.0, state.next_action_id())
		check(not actor.alive and actor.zones.is_empty() and actor.marks.is_empty() and actor.speed_buffs.is_empty() and actor.heat_count == 0 and actor.wind_ready_until == 0.0, hero + " death clears owned state")
		state.reset(hero)
		check(state.scheduled_hits.is_empty() and player(state).zones.is_empty(), hero + " reset clears pending state")
	var state = arena("lume")
	var actor: Dictionary = player(state)
	cast(state, "R", Vector2(2, 0), 0.7)
	check(state.scheduled_hits.size() == 2, "death fixture has pending shells")
	state.apply_damage(enemy(state).id, actor.id, 100000.0, state.next_action_id())
	check(state.scheduled_hits.is_empty(), "death cancels scheduled shells")
	var hp: float = enemy(state).hp
	state.step(1.0)
	near(enemy(state).hp, hp, "dead owner cannot hit later")

func boundaries() -> void:
	for hero: String in ["orin", "tere", "mua", "sera", "lume"]:
		var state = arena(hero)
		var actor: Dictionary = player(state)
		state.map = load("res://scripts/battle/battle_map.gd").new()
		state.map.blockers = [Rect2(1.4, -8, 0.5, 16)] as Array[Rect2]
		enemy(state).pos = Vector2(2.6, 0)
		state._visibility_cache.clear()
		if hero in ["mua", "lume"]:
			check(not state.command_cast(actor.id, "Q", enemy(state).pos), hero + " rejects ground beyond wall")
		else:
			cast(state, "Q", enemy(state).pos)
			near(enemy(state).hp, 10000.0, hero + " attack cannot cross wall")
		if hero in ["tere", "sera"]:
			cast(state, "E", Vector2(5, 0), 0.6)
			check(actor.pos.x < 1.0 and state.map.is_walkable(actor.pos, actor.radius), hero + " dash wall clearance")
		if hero == "mua":
			ally(state).pos = Vector2(2.6, 0)
			cast(state, "E", Vector2.ZERO, 0.2)
			near(ally(state).shield, 0.0, "Mua shields respect wall")
	var state = arena("sera")
	var actor: Dictionary = player(state)
	var target: Dictionary = enemy(state)
	state._abilities.expanded.add_mark(state, actor, target)
	state._abilities.expanded.add_mark(state, actor, target)
	state._start_basic(actor, target)
	target.pos = Vector2(8, 0)
	state._release_basic(actor)
	check(actor.marks[target.id].stacks == 2, "Sera basic miss retains marks")
	target.pos = Vector2(1, 0)
	target.protected = 3.0
	state._start_basic(actor, target)
	state._release_basic(actor)
	check(actor.marks[target.id].stacks == 2, "Sera protected basic retains marks")
	target.protected = 0.0
	var second: Dictionary = ally(state)
	second.hero = "sera"
	second.power = 100.0
	state._abilities.expanded.add_mark(state, second, target)
	check(second.marks[target.id].stacks == 1 and actor.marks[target.id].stacks == 2, "Sera marks are owner specific")
	state._abilities.expanded.basic_bonus(state, actor, target, actor.power)
	check(actor.marks.is_empty() and second.marks[target.id].stacks == 1, "Sera consumes only own marks")
	state = arena("lume")
	actor = player(state)
	cast(state, "R", Vector2(2, 0), 0.7)
	state.apply_cc(actor.id, "stun", 0.5)
	var warnings: int = 0
	for effect: Dictionary in state.effects:
		if effect.get("scheduled", false) and effect.telegraph:
			warnings += 1
	check(warnings == 2, "released shells retain warnings after stun")
	state.step(1.0)
	near(enemy(state).hp, 9700.0, "released shells survive later stun")
	state = arena("mua")
	actor = player(state)
	cast(state, "Q", Vector2.ZERO, 0.3)
	var zone_id: int = actor.zones[0].id
	state.step(4.1)
	var ready: float = actor.passive_ready[actor.id]
	cast(state, "W", Vector2.ZERO, 0.2)
	near(actor.passive_ready[actor.id], ready, "Mua one-zone W is no reentry")
	check(actor.zones[0].id == zone_id, "Mua W retains sole zone")
	state.cancel_action(actor)
	actor.energy = 100.0
	actor.zones[0].expires = state.time + 0.2
	check(state.command_cast(actor.id, "R", Vector2.ZERO), "Mua R starts before expiry")
	state.step(0.7)
	check(actor.zones.is_empty(), "Mua expired zone cancels R")
	near(enemy(state).hp, 9915.0, "Mua expired R causes no damage")

func sera_basic_power_snapshot() -> void:
	var state = arena("sera")
	var actor: Dictionary = player(state)
	var target: Dictionary = enemy(state)
	state._abilities.expanded.add_mark(state, actor, target)
	state._abilities.expanded.add_mark(state, actor, target)
	check(state.command_attack(actor.id, target.id), "Sera snapshot attack accepted")
	state.step(State.FIXED_STEP)
	check(actor.phase == "basic", "Sera snapshot enters real windup")
	near(actor.cast.power, 100.0, "Sera basic stores approval power")
	check(state.invest(actor.id, "power"), "Sera can invest during basic windup")
	near(actor.power, 110.0, "Sera current power increases during windup")
	state.step(actor.attack_windup + State.FIXED_STEP)
	near(10000.0 - target.hp, 175.0, "Sera basic and mark bonus use approval power")
	check(actor.marks.is_empty(), "Sera snapped basic consumes own marks")
