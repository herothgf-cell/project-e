extends SceneTree
## First high-ground slice: map authority, sight, clicking and presentation share one height field.

const StateScript = preload("res://scripts/battle/battle_state.gd")
const MapScript = preload("res://scripts/battle/battle_map.gd")

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var map: Variant = MapScript.new()
	var north_high := Vector2(-18, 24)
	var north_lane := Vector2(-18, 18)
	var north_ramp := Vector2(-18, 20)
	var south_high := Vector2(18, -24)
	_near(map.ground_height(north_lane), 0.0, "north lane remains low ground")
	_near(map.ground_height(north_ramp), 1.2, "north ramp interpolates halfway to the plateau")
	_near(map.ground_height(north_high), 2.4, "northwest 40 XP cell is on 2.4m high ground")
	_near(map.ground_height(south_high), 2.4, "southeast 40 XP cell mirrors the same height")
	_check(map.is_walkable(north_lane) and map.is_walkable(north_ramp) and map.is_walkable(north_high), "existing cell approach remains continuously walkable")
	var path: Array = map.find_path(north_lane, north_high)
	_check(not path.is_empty() and Vector2(path.back()).distance_to(north_high) < 0.01, "pathfinding reaches the raised cell through the existing ramp")
	_check(not map.has_line_of_sight(north_lane, north_high), "low observer cannot see onto the plateau")
	_check(map.has_line_of_sight(north_high, north_lane), "high observer can see down from the plateau")
	_check(map.has_line_of_sight(north_high, north_high + Vector2(1.0, 0)), "same high plateau keeps local line of sight")

	var state: Variant = StateScript.new()
	state.reset("bas", false)
	state.units.clear()
	state.map = map
	state.bots_enabled = false
	var low: Dictionary = state._entity("hero", 0, north_lane, 100, 0.45)
	var high_enemy: Dictionary = state._entity("hero", 1, north_high, 100, 0.45)
	_check(not state.is_visible(0, high_enemy.id), "team sight respects low-to-high occlusion")
	low.pos = north_high
	high_enemy.pos = north_lane
	state._visibility_cache.clear()
	_check(state.is_visible(0, high_enemy.id), "high-ground observer reveals low target within range")

	var packed: PackedScene = load("res://scenes/battlefield.tscn")
	_check(packed != null, "battlefield scene loads for elevation integration")
	if packed != null:
		var scene: Variant = packed.instantiate()
		root.add_child(scene)
		await process_frame
		await process_frame
		scene.start_match("bas", true)
		scene.battle.bots_enabled = false
		var camera: Camera3D = scene.get_node("Camera3D")
		scene._camera_follow = false
		scene._camera_focus = north_high
		scene._update_camera(0.0)
		var high_world := Vector3(north_high.x, map.ground_height(north_high), -north_high.y)
		var high_screen: Vector2 = camera.unproject_position(high_world)
		var projected: Variant = scene.screen_to_ground(high_screen)
		_check(projected is Vector2 and projected.distance_to(north_high) < 0.08, "screen click resolves against the raised surface instead of y=0")
		var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
		hero.pos = north_high
		scene._sync_visuals(0.0)
		var hero_node: Node3D = scene.get_node("Units/Unit_%d" % hero.id)
		_near(hero_node.position.y, 2.4, "unit model stands on authority ground height")
		var preview := {"shape": "circle", "origin": north_high, "target": north_high, "radius": 1.0, "valid": true}
		scene.get_node("Effects").redraw(scene.battle, preview, -1, null)
		_check(scene.get_node("Effects").mesh.get_aabb().position.y > 2.3, "ground telegraph is lifted onto the plateau")
		scene.queue_free()
		await process_frame

	_finish()


func _near(actual: float, expected: float, label: String) -> void:
	_check(absf(actual - expected) < 0.03, "%s: expected %.2f, got %.2f" % [label, expected, actual])


func _check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(label)


func _finish() -> void:
	print("Elevation: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
