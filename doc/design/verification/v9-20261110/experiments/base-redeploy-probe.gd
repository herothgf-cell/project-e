extends SceneTree
## Read-only instrumentation. All gameplay calls delegate to unchanged main scripts.

const State = preload("res://scripts/battle/battle_state.gd")
var output_dir: String = ""

class ObservedRules:
	extends "res://scripts/battle/battle_rules.gd"
	var audit: Variant

	func damage(state: Variant, source_id: int, target_id: int, raw: float, cast_id: int, stage: String) -> float:
		var source: Dictionary = state.units.get(source_id, {})
		var target: Dictionary = state.units.get(target_id, {})
		var supported: bool = not target.is_empty() and not source.is_empty() and target.kind in ["tower", "core"] and state.has_siege_minion(source.team, target.pos)
		var applied: float = super.damage(state, source_id, target_id, raw, cast_id, stage)
		if applied > 0.0:
			audit.record_damage(state, source, target, raw, applied, supported, stage)
		return applied

	func award_xp(state: Variant, unit_id: int, amount: float, context: Dictionary = {}) -> float:
		var previous_level: int = int(state.units.get(unit_id, {}).get("level", 0))
		var applied: float = super.award_xp(state, unit_id, amount, context)
		if previous_level < 12 and int(state.units.get(unit_id, {}).get("level", 0)) == 12:
			audit.record_level_cap(state, unit_id)
		return applied

class ObservedAI:
	extends "res://scripts/battle/tactical_ai.gd"
	var audit: Variant
	var decisions: Dictionary = {}
	var stop_max_level_cells: bool = false

	func _best_cell(state: Variant, actor: Dictionary) -> Dictionary:
		if stop_max_level_cells and actor.level >= 12:
			return {}
		return super._best_cell(state, actor)

	func _begin(state: Variant, actor: Dictionary, target: Dictionary, kind: String) -> void:
		super._begin(state, actor, target, kind)
		audit.record_task_start(state, actor, target, kind)

	func _hero(state: Variant, actor: Dictionary) -> void:
		var busy: bool = actor.phase in ["basic", "windup", "dash", "recovery"] or actor.stun_left > 0.0
		decisions[actor.id] = {"busy": busy, "kind": "", "target_id": -1}
		_redeploy_from_base(state, actor)
		super._hero(state, actor)
		audit.record_decision(state, actor, decisions[actor.id])

	func _redeploy_from_base(state: Variant, actor: Dictionary) -> void:
		if actor.hp < actor.max_hp * 0.85 or not state.is_in_home_base(actor.id):
			return
		if not _core_threat(state, actor).is_empty():
			return
		var exposed: bool = false
		var breached: Array[int] = []
		for structure: Dictionary in state.units.values():
			if structure.team == actor.team:
				continue
			if structure.kind == "core" and structure.alive and not structure.locked:
				exposed = true
			if structure.kind == "tower" and structure.get("subtype", "") == "inner" and not structure.alive:
				breached.append(int(structure.lane))
		if not exposed or breached.is_empty() or breached.has(int(actor.lane)):
			return
		breached.sort()
		var previous_lane: int = int(actor.lane)
		actor.lane = breached[0]
		actor.objective_kind = ""
		actor.objective_id = -1
		actor.objective_until = 0.0
		actor.erase("objective_return")
		state.stats["siege_redeployments"] = int(state.stats.get("siege_redeployments", 0)) + 1
		audit._event("siege_redeployment", state.time, {"hero_id": actor.id, "team": actor.team, "from_lane": previous_lane, "to_lane": actor.lane})

	func _hero_skill(state: Variant, actor: Dictionary, target: Dictionary) -> bool:
		decisions[actor.id].kind = target.kind
		decisions[actor.id].target_id = target.id
		return super._hero_skill(state, actor, target)

	func _advance_lane(state: Variant, actor: Dictionary) -> void:
		if actor.kind == "hero":
			decisions[actor.id].kind = "lane_advance"
			decisions[actor.id].target_id = -1
		super._advance_lane(state, actor)

	func _return_home(state: Variant, actor: Dictionary) -> void:
		decisions[actor.id].kind = "objective_return"
		decisions[actor.id].target_id = -1
		super._return_home(state, actor)

var structures: Dictionary = {}
var heroes: Dictionary = {}
var milestones: Dictionary = {}
var transition_counts: Dictionary = {}
var decision_counts: Dictionary = {}
var nearby_decisions: Dictionary = {}
var eligible_decisions: Dictionary = {}
var structure_target_decisions: Dictionary = {}
var event_file: FileAccess
var sample_file: FileAccess
var selected_hero: String = "bas"
var variant: String = "baseline"
var output_key: String = "bas"
var observation_limit: float = 3000.0
var first_siege: float = -1.0
var last_sample: float = 0.0
var next_snapshot: float = 0.0
var next_progress: float = 120.0
var retreat_events: Array = []
var structure_switches: Array = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var arguments: PackedStringArray = OS.get_cmdline_user_args()
	if arguments.size() > 0:
		selected_hero = arguments[0]
	if arguments.size() > 1:
		variant = arguments[1]
	output_dir = arguments[2] if arguments.size() > 2 else OS.get_user_data_dir().path_join("cot-audit")
	if DirAccess.make_dir_recursive_absolute(output_dir) != OK:
		push_error("Cannot create audit output directory")
		quit(2)
		return
	print("AUDIT_OUTPUT ", output_dir)
	output_key = selected_hero if variant == "baseline" else selected_hero + "-" + variant
	observation_limit = 2100.0
	event_file = FileAccess.open(output_dir + "/siege-" + output_key + "-events.jsonl", FileAccess.WRITE)
	sample_file = FileAccess.open(output_dir + "/siege-" + output_key + "-samples.jsonl", FileAccess.WRITE)
	var state: Variant = State.new()
	var rules: Variant = ObservedRules.new()
	rules.audit = self
	state._rules = rules
	var ai: Variant = ObservedAI.new()
	ai.audit = self
	ai.stop_max_level_cells = variant == "no-max-cell"
	state._ai = ai
	state.reset(selected_hero, false)
	state.controlled_id = -1
	for unit: Dictionary in state.units.values():
		if unit.kind in ["tower", "core"]:
			structures[unit.id] = {
				"id": unit.id, "name": unit.name, "team": unit.team, "kind": unit.kind,
				"subtype": unit.get("subtype", "core"), "lane": unit.lane,
				"max_hp": unit.max_hp, "position": [unit.pos.x, unit.pos.y],
				"exposed_at": -1.0 if unit.locked else 0.0, "first_damage_at": -1.0,
				"destroyed_at": -1.0, "last_damage_at": -1.0, "damage": 0.0,
				"hits": 0, "damage_by_source": {}, "supported_damage": 0.0,
				"unsupported_damage": 0.0, "damage_by_stage": {}, "bursts": 0,
				"longest_hit_gap": 0.0, "unlocked_alive_seconds": 0.0,
				"supported_seconds": 0.0, "near_enemy_hero_seconds": 0.0,
				"supported_near_hero_seconds": 0.0, "unsupported_near_hero_seconds": 0.0,
				"one_hp_seconds": 0.0, "last_support": false, "support_windows": 0,
				"hero_target_seconds": 0.0, "minion_target_seconds": 0.0,
				"first_supported_at": -1.0,
			}
		elif unit.kind == "hero":
			heroes[unit.id] = {
				"id": unit.id, "hero": unit.hero, "team": unit.team, "lane": unit.lane,
				"retreats": 0, "siege_retreats": 0, "retreat_active": false,
				"retreat_start": -1.0, "retreat_seconds": 0.0, "dead_seconds": 0.0,
				"siege_retreat_seconds": 0.0, "structure_damage": 0.0,
				"last_structure_damage": -100.0, "incoming_damage": {},
				"last_decision": {}, "post_first_siege_seconds": 0.0,
				"post_first_siege_retreat_seconds": 0.0, "post_first_siege_dead_seconds": 0.0,
				"home_base_seconds": 0.0, "deaths": 0,
			}
	_event("metadata", 0.0, {"engine": Engine.get_version_info(), "hero_selection": selected_hero, "variant": variant, "observation_limit": observation_limit, "source_commit": "eb022135baf95046e1b1145bec45f5c26bab5b8a", "outer_step": 0.5, "inner_hz": 30, "method": "isolated scratch: recovered bots at home redeploy into a breached lane; original tactical AI otherwise"})
	var wall_start: int = Time.get_ticks_msec()
	while state.winner == -1 and state.time < observation_limit:
		state.step(0.5)
		_sample(state)
		if state.time >= next_progress:
			print("SIEGE_PROGRESS t=%.1f elapsed=%.1f towers=%d" % [state.time, (Time.get_ticks_msec() - wall_start) / 1000.0, _destroyed_towers()])
			next_progress += 120.0
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero":
			heroes[unit.id].final_level = unit.level
			heroes[unit.id].deaths = unit.deaths
			if heroes[unit.id].retreat_active:
				_end_retreat(state, unit, "end_of_observation")
		elif unit.kind in ["tower", "core"]:
			structures[unit.id].final_hp = unit.hp
	milestones.victory = state.time if state.winner != -1 else -1.0
	var summary: Dictionary = {
		"engine": Engine.get_version_info(), "source_commit": "eb022135baf95046e1b1145bec45f5c26bab5b8a",
		"selection": selected_hero, "variant": variant, "observation_limit": observation_limit, "winner": state.winner, "match_seconds": state.time,
		"wall_seconds": (Time.get_ticks_msec() - wall_start) / 1000.0,
		"stats": state.stats, "milestones": milestones, "structures": structures.values(),
		"heroes": heroes.values(), "decision_counts": decision_counts,
		"nearby_decisions": nearby_decisions, "eligible_decisions": eligible_decisions,
		"structure_target_decisions": structure_target_decisions,
		"structure_switch_counts": transition_counts, "structure_switches": structure_switches,
		"retreat_events": retreat_events,
		"sampling": {"snapshot_interval_seconds": 5.0, "occupancy_interval_seconds": 0.5, "decision_interval_seconds": 0.4, "near_structure_radius": 12.0, "siege_retreat_radius": 18.0, "hit_burst_gap_seconds": 3.0},
	}
	var output: FileAccess = FileAccess.open(output_dir + "/siege-" + output_key + "-summary.json", FileAccess.WRITE)
	output.store_string(JSON.stringify(summary, "  "))
	output.close()
	event_file.close()
	sample_file.close()
	print("SIEGE_COMPLETE " + JSON.stringify({"selection": selected_hero, "time": state.time, "winner": state.winner, "stats": state.stats, "milestones": milestones}))
	quit(0 if state.winner != -1 else 1)

func _destroyed_towers() -> int:
	var count: int = 0
	for structure: Dictionary in structures.values():
		if structure.kind == "tower" and structure.destroyed_at >= 0.0:
			count += 1
	return count

func _event(kind: String, at: float, details: Dictionary) -> void:
	var entry: Dictionary = {"event": kind, "time": at}
	entry.merge(details)
	event_file.store_line(JSON.stringify(entry))

func _count(mapping: Dictionary, key: String, amount: float = 1.0) -> void:
	mapping[key] = float(mapping.get(key, 0.0)) + amount

func _source_label(source: Dictionary) -> String:
	if source.kind == "hero":
		return "%d:%s:%d" % [source.team, source.hero, source.id]
	return "%d:%s:%s" % [source.team, source.kind, source.get("subtype", "")]

func record_level_cap(state: Variant, unit_id: int) -> void:
	heroes[unit_id].level_12_at = state.time
	_event("level_cap", state.time, {"hero_id": unit_id})

func record_task_start(state: Variant, actor: Dictionary, target: Dictionary, kind: String) -> void:
	var hero: Dictionary = heroes[actor.id]
	if not hero.has("task_starts"):
		hero.task_starts = {}
	_count(hero.task_starts, kind)
	if actor.level >= 12:
		if not hero.has("max_level_task_starts"):
			hero.max_level_task_starts = {}
		_count(hero.max_level_task_starts, kind)
	_event("task_start", state.time, {"hero_id": actor.id, "target_id": target.id, "kind": kind, "level": actor.level})

func record_damage(state: Variant, source: Dictionary, target: Dictionary, raw: float, applied: float, supported: bool, stage: String) -> void:
	if target.kind == "hero":
		_count(heroes[target.id].incoming_damage, _source_label(source), applied)
		if not target.alive:
			_event("hero_death", state.time, {"id": target.id, "source": _source_label(source), "position": [target.pos.x, target.pos.y]})
			if heroes[target.id].retreat_active:
				_end_retreat(state, target, "death")
	if target.kind not in ["tower", "core"]:
		return
	var structure: Dictionary = structures[target.id]
	var owner: Dictionary = state.units.get(source.get("owner_id", source.id), source)
	if first_siege < 0.0:
		first_siege = state.time
		milestones.first_structure_damage = state.time
	if structure.first_damage_at < 0.0:
		structure.first_damage_at = state.time
		var milestone: String = "first_" + structure.subtype + "_damage"
		if not milestones.has(milestone):
			milestones[milestone] = state.time
	if structure.last_damage_at < 0.0 or state.time - structure.last_damage_at > 3.0:
		structure.bursts += 1
	if structure.last_damage_at >= 0.0:
		structure.longest_hit_gap = maxf(structure.longest_hit_gap, state.time - structure.last_damage_at)
	structure.last_damage_at = state.time
	structure.damage += applied
	structure.hits += 1
	_count(structure.damage_by_source, _source_label(source), applied)
	_count(structure.damage_by_stage, stage, applied)
	structure.supported_damage += applied if supported else 0.0
	structure.unsupported_damage += 0.0 if supported else applied
	if owner.kind == "hero":
		heroes[owner.id].structure_damage += applied
		heroes[owner.id].last_structure_damage = state.time
	_event("structure_hit", state.time, {"id": target.id, "source": _source_label(source), "source_id": source.id, "owner_id": owner.id, "raw": raw, "applied": applied, "hp": target.hp, "supported": supported, "stage": stage})
	if not target.alive:
		structure.destroyed_at = state.time
		var milestone: String = "first_" + structure.subtype + "_destroyed"
		if not milestones.has(milestone):
			milestones[milestone] = state.time
		_event("structure_destroyed", state.time, {"id": target.id, "name": target.name, "source": _source_label(source)})
		_check_locks(state)

func _check_locks(state: Variant) -> void:
	for id: int in structures:
		var unit: Dictionary = state.units[id]
		if not unit.locked and structures[id].exposed_at < 0.0:
			structures[id].exposed_at = state.time
			_event("structure_exposed", state.time, {"id": id, "name": unit.name})
			if unit.kind == "core" and not milestones.has("first_core_exposed"):
				milestones.first_core_exposed = state.time

func _visible_without_cache_mutation(state: Variant, actor: Dictionary, target: Dictionary) -> bool:
	var key: String = "%d:%d" % [actor.team, target.id]
	if state._visibility_cache.has(key):
		return state._visibility_cache[key]
	return state.is_point_visible(actor.team, target.pos)

func record_decision(state: Variant, actor: Dictionary, decision: Dictionary) -> void:
	var hero: Dictionary = heroes[actor.id]
	if actor.ai_retreat and not hero.retreat_active:
		_begin_retreat(state, actor)
	elif not actor.ai_retreat and hero.retreat_active:
		_end_retreat(state, actor, "recovered")
	var category: String = str(decision.kind)
	if decision.busy:
		category = "busy"
	elif actor.ai_retreat:
		category = "retreat"
	elif category.is_empty():
		category = "objective_" + str(actor.get("objective_kind", "none"))
	_count(decision_counts, category)
	var near: Array = []
	var eligible: Array = []
	for id: int in structures:
		var target: Dictionary = state.units[id]
		if target.team == actor.team or not target.alive or target.locked or actor.pos.distance_squared_to(target.pos) > 144.0:
			continue
		near.append(id)
		if state.has_siege_minion(actor.team, target.pos) and _visible_without_cache_mutation(state, actor, target):
			eligible.append(id)
	if not near.is_empty():
		_count(nearby_decisions, category)
	if not eligible.is_empty():
		_count(eligible_decisions, category)
		for id: int in eligible:
			var per_structure: Dictionary = structure_target_decisions.get(str(id), {})
			_count(per_structure, category)
			structure_target_decisions[str(id)] = per_structure
	if decision.busy:
		return
	var current: Dictionary = {"time": state.time, "category": category, "target_id": int(decision.target_id), "eligible": eligible}
	var previous: Dictionary = hero.last_decision
	if not previous.is_empty() and previous.category in ["tower", "core"] and (category not in ["tower", "core"] or previous.target_id != current.target_id):
		var old: Dictionary = state.units.get(previous.target_id, {})
		var reason: String = category
		if not old.is_empty() and not old.alive:
			reason = "target_destroyed"
		elif category == "retreat":
			reason = "retreat"
		elif not old.is_empty() and not state.has_siege_minion(actor.team, old.pos):
			reason = "minion_support_lost"
		elif category in ["hero", "minion"] and previous.target_id in eligible:
			reason = "priority_" + category
		_count(transition_counts, reason)
		var entry: Dictionary = {"time": state.time, "hero_id": actor.id, "from": previous.target_id, "to": current.target_id, "reason": reason, "hp_fraction": actor.hp / actor.max_hp, "eligible": eligible}
		structure_switches.append(entry)
		_event("structure_target_switch", state.time, entry)
	hero.last_decision = current

func _begin_retreat(state: Variant, actor: Dictionary) -> void:
	var hero: Dictionary = heroes[actor.id]
	var nearest: float = INF
	var nearby_structure: int = -1
	for id: int in structures:
		var structure: Dictionary = state.units[id]
		if structure.team != actor.team and structure.alive:
			var distance: float = actor.pos.distance_to(structure.pos)
			if distance < nearest:
				nearest = distance
				nearby_structure = id
	var siege_related: bool = nearest <= 18.0 or state.time - hero.last_structure_damage <= 15.0
	hero.retreats += 1
	hero.siege_retreats += 1 if siege_related else 0
	hero.retreat_active = true
	hero.retreat_start = state.time
	hero.active_retreat_siege = siege_related
	var entry: Dictionary = {"time": state.time, "hero_id": actor.id, "hero": actor.hero, "team": actor.team, "hp_fraction": actor.hp / actor.max_hp, "position": [actor.pos.x, actor.pos.y], "nearest_enemy_structure": nearby_structure, "nearest_distance": nearest, "since_own_structure_hit": state.time - hero.last_structure_damage, "siege_related": siege_related}
	retreat_events.append(entry)
	_event("retreat_start", state.time, entry)

func _end_retreat(state: Variant, actor: Dictionary, reason: String) -> void:
	var hero: Dictionary = heroes[actor.id]
	hero.retreat_active = false
	_event("retreat_end", state.time, {"hero_id": actor.id, "duration": state.time - hero.retreat_start, "reason": reason, "position": [actor.pos.x, actor.pos.y], "hp_fraction": actor.hp / actor.max_hp})

func _sample(state: Variant) -> void:
	var delta: float = state.time - last_sample
	last_sample = state.time
	_check_locks(state)
	var hero_snapshots: Array = []
	for id: int in heroes:
		var unit: Dictionary = state.units[id]
		var hero: Dictionary = heroes[id]
		if unit.alive and unit.ai_retreat:
			hero.retreat_seconds += delta
			if hero.get("active_retreat_siege", false):
				hero.siege_retreat_seconds += delta
		if not unit.alive:
			hero.dead_seconds += delta
		if state.is_in_home_base(id):
			hero.home_base_seconds += delta
		if first_siege >= 0.0:
			hero.post_first_siege_seconds += delta
			if unit.alive and unit.ai_retreat:
				hero.post_first_siege_retreat_seconds += delta
			if not unit.alive:
				hero.post_first_siege_dead_seconds += delta
		if state.time >= next_snapshot:
			hero_snapshots.append({"id": id, "hero": unit.hero, "team": unit.team, "pos": [unit.pos.x, unit.pos.y], "hp": unit.hp, "max_hp": unit.max_hp, "alive": unit.alive, "level": unit.level, "retreat": unit.ai_retreat, "target": unit.target_id, "order": unit.order, "phase": unit.phase, "objective": unit.get("objective_kind", ""), "decision": hero.last_decision})
	var structure_snapshots: Array = []
	for id: int in structures:
		var unit: Dictionary = state.units[id]
		var structure: Dictionary = structures[id]
		if not unit.alive or unit.locked:
			continue
		var support: int = 0
		var nearby_heroes: int = 0
		var hero_targets: int = 0
		var minion_targets: int = 0
		for other: Dictionary in state.units.values():
			if other.team == unit.team or not other.alive:
				continue
			if other.kind == "minion" and other.pos.distance_squared_to(unit.pos) <= 144.0:
				support += 1
			if other.kind == "hero" and other.pos.distance_squared_to(unit.pos) <= 144.0:
				nearby_heroes += 1
			if other.target_id == id:
				hero_targets += 1 if other.kind == "hero" else 0
				minion_targets += 1 if other.kind == "minion" else 0
		structure.unlocked_alive_seconds += delta
		structure.supported_seconds += delta if support > 0 else 0.0
		structure.near_enemy_hero_seconds += delta if nearby_heroes > 0 else 0.0
		structure.supported_near_hero_seconds += delta if support > 0 and nearby_heroes > 0 else 0.0
		structure.unsupported_near_hero_seconds += delta if support == 0 and nearby_heroes > 0 else 0.0
		structure.one_hp_seconds += delta if unit.hp <= 1.00001 else 0.0
		structure.hero_target_seconds += delta if hero_targets > 0 else 0.0
		structure.minion_target_seconds += delta if minion_targets > 0 else 0.0
		if support > 0 and not structure.last_support:
			structure.support_windows += 1
			if structure.first_supported_at < 0.0:
				structure.first_supported_at = state.time
		if (support > 0) != structure.last_support:
			_event("support_changed", state.time, {"id": id, "supported": support > 0, "minions": support, "heroes": nearby_heroes, "hp": unit.hp})
		structure.last_support = support > 0
		if state.time >= next_snapshot:
			structure_snapshots.append({"id": id, "hp": unit.hp, "support": support, "near_heroes": nearby_heroes, "hero_targets": hero_targets, "minion_targets": minion_targets})
	if state.time >= next_snapshot:
		sample_file.store_line(JSON.stringify({"time": state.time, "heroes": hero_snapshots, "structures": structure_snapshots}))
		next_snapshot += 5.0
