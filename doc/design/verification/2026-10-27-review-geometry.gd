extends SceneTree
var samples: int = 0
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var state: Variant = load("res://scripts/battle/battle_state.gd").new()
	state.reset("bas", true)
	state.bots_enabled = false
	var hero: Dictionary = state.units[state.controlled_id]
	var ally: Dictionary = {}
	for unit: Dictionary in state.units.values():
		unit.alive = unit.id == hero.id
		if unit.team == 0 and unit.kind == "hero" and unit.id != hero.id:
			ally = unit
	var view: MeshInstance3D = load("res://scripts/presentation/effects_view.gd").new()
	root.add_child(view)
	await process_frame
	var rng := RandomNumberGenerator.new()
	rng.seed = 462718
	var fixtures: int = 0
	for n: int in range(72):
		var origin := Vector2(rng.randf_range(-31, 31), rng.randf_range(-17, 17))
		if not state.map.has_line_of_sight(origin, origin):
			continue
		hero.pos = origin + Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(3, 14)
		ally.alive = n % 3 == 0
		ally.pos = origin + Vector2.from_angle(rng.randf_range(0, TAU)) * rng.randf_range(3, 14)
		var shape := {"shape": "circle" if n % 2 == 0 else "cone", "origin": origin, "target": origin + Vector2.from_angle(rng.randf_range(0, TAU)) * 6, "radius": rng.randf_range(1.2, 6), "angle": 70.0, "team": 1}
		state.effects = [shape]
		view.redraw(state, {}, -1, null)
		var faces := view.mesh.get_faces()
		fixtures += 1
		for i: int in range(0, faces.size(), 3):
			var a := Vector2(faces[i].x, -faces[i].z)
			var b := Vector2(faces[i+1].x, -faces[i+1].z)
			var c := Vector2(faces[i+2].x, -faces[i+2].z)
			if absf((b-a).cross(c-a)) < 0.000001:
				continue
			for u: int in range(4):
				for v: int in range(4-u):
					var p: Vector2 = a + (b-a) * (float(u)/3) + (c-a) * (float(v)/3)
					samples += 1
					if not state.is_point_visible(0, p) or not state.map.has_line_of_sight(origin, p):
						print("FAIL fixture=", n, " shape=", shape, " hero=", hero.pos, " ally=", ally.pos, " sample=", p)
						quit(1)
						return
	print("PASS randomized native geometry: ", fixtures, " fixtures; ", samples, " triangle samples; no enemy sight or effect LOS leak")
	view.queue_free()
	await process_frame
	quit(0)
