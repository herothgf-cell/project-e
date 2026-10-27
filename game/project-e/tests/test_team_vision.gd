extends SceneTree
## Independent fixtures assert real visibility and the texture/geometry used by presentation.

const StateScript = preload("res://scripts/battle/battle_state.gd")
const MapScript = preload("res://scripts/battle/battle_map.gd")
var _checks: int = 0
var _failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	if not FileAccess.file_exists("res://scripts/presentation/team_vision_view.gd"):
		_check(false, "Current team vision ground mask presentation exists")
		_finish()
		return
	var view: Variant = load("res://scripts/presentation/team_vision_view.gd").new()
	root.add_child(view)
	var state: Variant = _fixture()
	var hero: Dictionary = state._entity("hero", 0, Vector2(-5.5, 1.5), 100, 0.45)
	state.map.blockers = [Rect2(0, -8, 1, 16)] as Array[Rect2]
	view.configure(state)
	view.update_view(null, 0, 1.0, false)
	_check(state.is_point_visible(0, Vector2(-1.5, 1.5)), "Real allied hero sees the near wall side")
	_check(not state.is_point_visible(0, Vector2(3.5, 1.5)), "Real wall blocks the opposite side within 12m")
	_check(view.mask_visibility_at(Vector2(-1.5, 1.5)) > 0.99, "Rendered mask keeps observed near wall side bright")
	_check(view.mask_visibility_at(Vector2(3.5, 1.5)) < 0.01, "Rendered mask darkens wall shadow")
	_check(view.mask_visibility_at(Vector2(-19.5, 1.5)) < 0.01, "Rendered mask darkens outside allied sight")
	var static_refreshes: int = view.refresh_count
	view.update_view(null, 0, 1.0, false)
	_check(view.refresh_count == static_refreshes, "Static source frames do not rebuild the raster")
	hero.pos += Vector2(0, 0.25)
	view.update_view(null, 0, 0.01, false)
	_check(view.refresh_count == static_refreshes + 1, "Moved source updates after the elapsed refresh interval")
	static_refreshes = view.refresh_count
	hero.pos -= Vector2(0, 0.25)
	view.update_view(null, 0, 0.01, false)
	_check(view.refresh_count == static_refreshes, "Movement cannot rebuild the full mask every frame")
	view.update_view(null, 0, 0.25, false)
	var image: Image = view.mask_texture.get_image()
	_check(image.get_pixel(60, 41).r > 0.99 and image.get_pixel(65, 41).r < 0.01, "Actual uploaded texture contains near-side white and wall-shadow black texels")
	_check(view.get_node_or_null("Sources/Source_%d" % hero.id) != null, "A live allied observer has a rendered common source marker")
	_check(view.source_ids() == [hero.id], "Only the live allied hero gets a source marker")
	var boundary: PackedVector2Array = view.source_boundary(hero.id)
	_check(boundary.size() >= 96, "Hover outline has a sampled full range contour")
	for point: Vector2 in boundary:
		_check(state.map.has_line_of_sight(hero.pos, point) and point.distance_to(hero.pos) <= 12.001, "Every hover contour endpoint obeys wall LOS and the actual 12m radius")
	_check(boundary[0].x < 0, "Hover contour clips against the wall rather than drawing a full circle")
	_check(view._tooltip_label.get_theme_font("font").has_char("시".unicode_at(0)), "World source tooltip font can render Korean vision labels")
	_check(view.source_tooltip(hero.id).contains("12") and view.source_tooltip(hero.id).contains("팀 공유 시야"), "Source hover explains shared 12m vision")
	var ally: Dictionary = state._entity("tower", 0, Vector2(9.5, 1.5), 100, 1.0)
	ally.attack_range = 8.5
	view.update_view(null, 0, 1.0, false)
	for x: int in range(-17, 23, 2):
		for y: int in range(-13, 16, 2):
			var sample := Vector2(x + 0.5, y + 0.5)
			_check((view.mask_visibility_at(sample) > 0.99) == state.is_point_visible(0, sample), "Raster upload values match real shared sight across wall edges and overlapping sources")
	_check(view.mask_visibility_at(Vector2(3.5, 1.5)) > 0.99, "A second allied source reveals overlapping wall shadow from the opposite side")
	_check(view.source_tooltip(ally.id).contains("8.5") and view.source_tooltip(ally.id).contains("공격 사거리"), "Tower tooltip distinguishes 12m vision from 8.5m attack range")
	ally.alive = false
	view.update_view(null, 0, 1.0, false)
	_check(view.mask_visibility_at(Vector2(3.5, 1.5)) < 0.01 and ally.id not in view.source_ids(), "Destroyed source loses marker and current visibility")
	hero.alive = false
	var minion: Dictionary = state._entity("minion", 0, Vector2(-25.5, 1.5), 100, 0.3)
	var enemy: Dictionary = state._entity("tower", 1, Vector2(25.5, 1.5), 100, 1.0)
	state._entity("pin", 0, Vector2(15.5, 1.5), 100, 0.2)
	var cell: Dictionary = state._entity("cell", 2, Vector2(19.5, 1.5), 180, 0.55)
	cell.merge({"cell_tier": "high", "xp_reward": 40.0})
	view.update_view(null, 0, 1.0, false)
	_check(view.source_ids() == [minion.id], "Cells, pins, enemies and dead allies do not grant markers or vision")
	_check(view.mask_visibility_at(Vector2(-17.5, 1.5)) > 0.99 and view.mask_visibility_at(Vector2(-15.5, 1.5)) < 0.01, "Minion mask uses 8m rather than hero radius")
	_check(view.mask_visibility_at(enemy.pos) < 0.01, "Public enemy structure icon cannot reveal its surroundings")
	var tactical: Variant = load("res://scripts/presentation/tactical_map.gd").new()
	tactical.battle = state
	tactical.vision_view = view
	root.add_child(tactical)
	_check(enemy.id in tactical.visible_unit_ids() and cell.id not in tactical.visible_unit_ids(), "Minimap preserves public structure locations and hides unseen cells")
	_check(tactical.vision_at(Vector2(-17.5, 1.5)) > 0.99 and tactical.vision_at(Vector2(25.5, 1.5)) < 0.01, "Minimap reads the actual shared fog mask")
	_test_cell_models(state, view)
	_test_stationary_minimap_hover(tactical, state, view, minion)
	state.units.erase(minion.id)
	view.update_view(null, 0, 0.01, false)
	_check(view.source_ids().is_empty() and view.mask_visibility_at(Vector2(-25.5, 1.5)) < 0.01, "Removing the last live observer clears shared sight immediately")
	_check(view.get_node("Sources").get_child_count() == 0, "Removing observers removes their rendered markers")
	var core: Dictionary = state._entity("core", 0, Vector2(-5.5, -20.5), 100, 2.0)
	view.update_view(null, 0, 0.01, false)
	_check(view.source_ids() == [core.id] and view.mask_visibility_at(Vector2(6.5, -20.5)) > 0.99, "Living allied core grants the same real 12m sight")
	core.alive = false
	view.update_view(null, 0, 0.01, false)
	_check(view.mask_visibility_at(Vector2(6.5, -20.5)) < 0.01, "Destroyed core cannot leave stale vision")
	_test_marker_layout(view)
	tactical.queue_free()
	view.queue_free()
	await process_frame
	_finish()


func _test_marker_layout(view: Variant) -> void:
	if not view.has_method("source_marker_screen_position") or not view.has_method("source_at_screen_position"):
		_check(false, "Visible source badge exposes the same projection and hit-test contract used by hover")
		return
	var state: Variant = _fixture()
	var fixtures: Array = []
	for spec: Array in [["hero", Vector2(-5, 0), 2.35, 70], ["tower", Vector2(5, 0), 3.6, 82], ["minion", Vector2(0, -5), 1.25, 49], ["core", Vector2(0, 5), 3.6, 82]]:
		var unit: Dictionary = state._entity(spec[0], 0, spec[1], 100, 0.45)
		fixtures.append([unit, spec[2], spec[3]])
	var cell: Dictionary = state._entity("cell", 2, Vector2(0, 0), 180, 0.55)
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.position = Vector3(0, 48, 34)
	camera.look_at(Vector3.ZERO, Vector3.UP)
	view.configure(state)
	for zoom: float in [26.0, 34.0, 42.0]:
		camera.size = zoom
		view.update_view(camera, 0, 0.01, false)
		for spec: Array in fixtures:
			var unit: Dictionary = spec[0]
			var badge: Vector2 = view.source_marker_screen_position(camera, unit.id)
			var anchor: Vector2 = camera.unproject_position(Vector3(unit.pos.x, spec[1], -unit.pos.y))
			var hp_and_name := Rect2(anchor - Vector2(spec[2] * 0.5, 22), Vector2(spec[2], 35))
			_check(not Rect2(badge - Vector2(8, 8), Vector2(16, 16)).intersects(hp_and_name), "Source badge remains clear of its actual HP/name plate at zoom %.0f" % zoom)
			_check(view.source_at_screen_position(camera, badge) == unit.id, "Source hover hit aligns with the displayed badge at zoom %.0f" % zoom)
		_check(not view.source_marker_screen_position(camera, cell.id).is_finite(), "Cells do not receive a provider badge at zoom %.0f" % zoom)
	camera.queue_free()


func _test_stationary_minimap_hover(tactical: Variant, state: Variant, view: Variant, minion: Dictionary) -> void:
	# Keep the real viewport pointer stationary; move the source underneath/away
	# from it, then exercise the regular presentation callback without a new event.
	tactical.size = Vector2(230, 148)
	tactical.position = root.get_mouse_position() - tactical.size * 0.5
	var pointer: Vector2 = tactical.get_local_mouse_position()
	var original: Vector2 = minion.pos
	minion.pos = tactical.from_map(pointer + Vector2(0, 6))
	var under_pointer: Vector2 = minion.pos
	view.update_view(null, 0, 0.01, false)
	var motion := InputEventMouseMotion.new()
	motion.position = pointer
	tactical._gui_input(motion)
	_check(tactical._hovered_source == minion.id, "Source halo is initially selected under the stationary real pointer")
	_check(tactical.tooltip_text.contains("팀 공유 시야") and tactical.tooltip_text.contains("8m"), "Minimap source tooltip localizes shared vision and preserves range")
	minion.pos += Vector2(20, 0)
	view.update_view(null, 0, 0.01, false)
	if tactical.has_method("_process"):
		tactical._process(0)
	_check(tactical._hovered_source == -1, "Stationary pointer drops a source that moves away")
	_check(not tactical.tooltip_text.contains("8m"), "Moving source leaves no stale source range tooltip")
	minion.pos = under_pointer
	view.update_view(null, 0, 0.01, false)
	if tactical.has_method("_process"):
		tactical._process(0)
	_check(tactical._hovered_source == minion.id, "A source moving under a stationary pointer becomes hovered without mouse motion")
	minion.alive = false
	view.update_view(null, 0, 0.01, false)
	if tactical.has_method("_process"):
		tactical._process(0)
	_check(tactical._hovered_source == -1 and not tactical.tooltip_text.contains("8m"), "Source death clears stationary hover identity and source tooltip")
	minion.alive = true
	minion.pos = original
	view.update_view(null, 0, 0.01, false)


func _test_cell_models(state: Variant, view: Variant) -> void:
	var arena: Variant = load("res://scripts/presentation/arena_view.gd").new()
	root.add_child(arena)
	arena.build(state.map, state.units)
	arena.set_vision_texture(view.mask_texture)
	var terrain_material: ShaderMaterial = arena.get_child(0).material_override
	_check(terrain_material.get_shader_parameter("vision_mask") == view.mask_texture, "Static terrain shader samples the same real-team mask as the minimap")
	var overlay: Variant = load("res://scripts/presentation/unit_overlay.gd").new()
	overlay.battle = state
	root.add_child(overlay)
	var signatures: Array = []
	for reward: int in [20, 30, 40]:
		var cell: Dictionary = state._entity("cell", 2, Vector2(-25.5, 1.5), 180, 0.55)
		cell.merge({"cell_tier": ["low", "medium", "high"][[20, 30, 40].find(reward)], "xp_reward": float(reward)})
		var model: Node3D = arena.create_unit(cell, arena)
		_check(model.get_node("Footprint").mesh.get_aabb().size.x < 1.2 and is_equal_approx(float(cell.radius), 0.55), "Cell tier %d retains the physical footprint" % reward)
		signatures.append(model.get_node("Model").get_child_count())
		_check(overlay.cell_label(cell.id) == "%d XP" % reward, "Observed cell label shows tier reward %d XP" % reward)
		cell.pos = Vector2(45.5, 1.5)
		_check(overlay.cell_label(cell.id).is_empty(), "Hidden cell %d reveals neither reward label nor alive status" % reward)
	_check(signatures[0] != signatures[1] and signatures[1] != signatures[2], "Cell tiers have independently distinguishable crystal silhouettes")
	arena.queue_free()
	overlay.queue_free()


func _fixture() -> Variant:
	var state: Variant = StateScript.new()
	state.reset()
	state.units.clear()
	state.map = MapScript.new()
	state.bots_enabled = false
	return state


func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)


func _finish() -> void:
	print("Team vision: %d checks, %d failures" % [_checks, _failures])
	quit(0 if _failures == 0 else 1)
