extends SceneTree
const State = preload("res://scripts/battle/battle_state.gd")
var checks: int = 0
var failures: int = 0
func _initialize() -> void:
	for hero: String in ["bas", "rio", "nema", "orin", "tere", "mua", "sera", "lume"]:
		var state = State.new()
		state.reset(hero)
		check(state.units[state.controlled_id].hero == hero, hero + " selected")
		check(state.units[state.controlled_id].lane == 1, hero + " center")
		for team: int in range(2):
			var names: Array = []
			var lanes: Array = []
			for unit: Dictionary in state.units.values():
				if unit.kind == "hero" and unit.team == team:
					names.append(unit.hero)
					lanes.append(unit.lane)
			check(names.size() == 3 and names[0] != names[1] and names[1] != names[2] and names[0] != names[2], hero + " three unique teammates")
			lanes.sort()
			check(lanes == [0, 1, 2], hero + " three lanes")
	print("Roster V8: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)
