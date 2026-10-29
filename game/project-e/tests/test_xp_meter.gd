extends SceneTree
## A progress rectangle under an opaque sibling is not a visible HUD meter.

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var packed: PackedScene = load("res://scenes/battlefield.tscn")
	var scene: Variant = packed.instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.start_match("bas", false)
	scene.paused = true
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	scene.battle.award_xp(hero.id, 40.0 / 3.0)
	scene.hud.update_state(scene.battle, "", false)
	scene.hud.unit_overlay.update_feedback(0.0)
	var meter: ProgressBar = scene.hud._xp.get_node_or_null("XPProgress") as ProgressBar
	_check(meter != null, "XP meter is an actual HUD child, not hidden under the opaque bottom panel")
	if meter != null:
		_check(meter.is_visible_in_tree(), "in-match progression meter is visible in the real scene")
		_check(meter.mouse_filter == Control.MOUSE_FILTER_IGNORE, "HUD progress meter does not intercept input")
		_check(absf(meter.value - 0.1333333333) < 0.000001, "HUD meter retains fractional authority XP without range-step rounding")
		_check(scene.hud._bottom.is_ancestor_of(meter), "meter is drawn inside the HUD branch rather than the world overlay")
		var original_size: Vector2i = root.size
		for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
			root.size = dimensions
			await process_frame
			await process_frame
			scene.hud.unit_overlay.update_feedback(0.0)
			var bounds: Rect2 = meter.get_global_rect()
			_check(bounds.has_area() and scene.hud._bottom.get_global_rect().encloses(bounds), "actual XP meter stays inside the HUD panel after resizing")
			_check(not bounds.intersects(scene.hud._passive.get_global_rect()), "progress meter does not cover passive information")
			_check(not bounds.intersects(scene.hud._xp.get_global_rect()), "progress meter does not cover existing XP text")
		root.size = original_size
		scene.open_help()
		_check(scene.hud.help_panel.visible and scene.hud.help_panel.get_index() > scene.hud._bottom.get_index(), "modal help retains draw priority over the HUD meter")
		scene.close_help()
		scene.battle.award_xp(hero.id, 10000.0)
		scene.hud.unit_overlay.update_feedback(0.0)
		_check(hero.level == 12 and is_equal_approx(meter.value, 1.0), "max-level meter is complete rather than showing an empty fictitious level")
		scene.return_to_selection()
		scene.hud.unit_overlay.update_feedback(0.0)
		_check(not meter.is_visible_in_tree(), "selection screen hides the real meter with its HUD parent")
	scene.queue_free()
	await process_frame
	print("XP meter: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(label)
