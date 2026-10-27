extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var state: Variant = load("res://scripts/battle/battle_state.gd").new()
	state.reset("bas", true)
	state.bots_enabled = false
	var view: MeshInstance3D = load("res://scripts/presentation/effects_view.gd").new()
	root.add_child(view)
	await process_frame
	var fixtures: Array = [
		{"shape":"circle", "origin":Vector2(-15,0), "radius":2.2,"team":0},
		{"shape":"circle", "origin":Vector2(-15,0), "radius":2.2,"team":1},
		{"shape":"cone", "origin":Vector2(-15,0), "target":Vector2(-9,0),"angle":70.0, "radius":6.0,"team":1},
		{"shape":"cone", "origin":Vector2(15,0), "target":Vector2(9,0),"angle":70.0, "radius":6.0,"team":1}
	]
	for shape: Dictionary in fixtures:
		state.effects = [shape]
		var start: int = Time.get_ticks_usec()
		for i: int in range(8):
			view.redraw(state, {}, -1, null)
		print("BENCH ",shape," redraw_us=",(Time.get_ticks_usec()-start)/8.0," triangles=",view.mesh.get_faces().size()/3)
	quit()
