extends SceneTree
## Eight playable heroes must remain selectable and visually distinct.
const KEYS := ["bas", "rio", "nema", "orin", "tere", "mua", "sera", "lume"]
var checks := 0
var failures := 0
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var hud: Variant = load("res://scripts/presentation/battle_hud.gd").new()
	root.add_child(hud)
	await process_frame
	await process_frame
	var rig_script: Variant = load("res://scripts/presentation/hero_rig.gd")
	var vfx: Variant = load("res://scripts/presentation/skill_vfx.gd").new()
	root.add_child(vfx)
	var motifs := {}
	for key: String in KEYS:
		_check(hud._hero_buttons.has(key), key + " has a selectable card")
		if hud._hero_buttons.has(key):
			hud._hero_buttons[key].pressed.emit()
			_check(hud.selected_hero == key and hud._start.text.contains(hud.HEROES[key][0]), key + " selects the correct start action")
			var portrait: TextureRect = hud._hero_buttons[key].get_node("HeroIllustration")
			_check(portrait.hero_key == key and portrait.texture != null, key + " binds its portrait")
			if key in ["orin", "tere", "mua", "sera", "lume"]:
				_check(portrait.get_node_or_null("ModelPortrait") != null, key + " portrait renders its real model")
				var portrait_camera: Camera3D = portrait.get_node("ModelPortrait").get_camera_3d()
				_check(portrait_camera != null and portrait_camera.size <= 2.2, key + " portrait frames expressive head and upper body")
				var model: Node3D = rig_script.MODELS[key].instantiate()
				for part: String in ["Head", "Torso"]:
					var material: StandardMaterial3D = model.get_node(part).mesh.surface_get_material(0)
					_check(material.albedo_texture != null, key + " preserves illustrated " + part + " detail")
				model.free()
			for index: int in range(4):
				_check(hud._selection_skills[index].text.contains(hud.SKILLS[key][index]) and not hud._selection_skill_help[index].text.is_empty(), key + " presents skill " + str(index))
		_check(rig_script.MODELS.has(key), key + " has an articulated model")
		if rig_script.MODELS.has(key):
			var rig: Variant = rig_script.new()
			root.add_child(rig)
			rig.build(key, Color.WHITE)
			_check(rig.get_node_or_null("RightArm/WeaponDetail") != null, key + " has weapon articulation")
			for slot: String in ["Q", "W", "E", "R"]:
				_check(rig._player.has_animation(slot), key + slot + " has an articulated cast pose")
			rig.queue_free()
		for slot: String in ["Q", "W", "E", "R"]:
			var style: Dictionary = vfx.style_for(key, slot)
			_check(not str(style.motif).is_empty() and not motifs.has(style.motif), key + slot + " has a unique motif")
			motifs[style.motif] = true
			_check(FileAccess.file_exists("res://assets/ui/skills/%s_%s.svg" % [key, slot.to_lower()]), key + slot + " has its own icon")
	for dimensions: Vector2i in [Vector2i(960,540), Vector2i(1280,720), Vector2i(1366,768)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		await process_frame
		await process_frame
		for key: String in hud._hero_buttons:
			var rect: Rect2 = hud._hero_buttons[key].get_global_rect()
			_check(root.get_visible_rect().encloses(rect), key + " card fits " + str(dimensions))
			_check(rect.size.y >= 110 and rect.size.x >= 110, key + " has a useful pointer target")
		_check(root.get_visible_rect().encloses(hud._start.get_global_rect()), "start fits " + str(dimensions))
		_check(not hud._start.get_global_rect().intersects(hud._practice.get_global_rect()), "mode and start do not overlap")
	_check_motifs(vfx)
	_check_persistent_cues(hud)
	await _check_review()
	hud.queue_free()
	vfx.queue_free()
	await process_frame
	print("Roster presentation V8: %d checks, %d failures" % [checks,failures])
	quit(0 if failures == 0 else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)

func _check_motifs(view: Variant) -> void:
	var state: Variant = load("res://scripts/battle/battle_state.gd").new()
	state.reset("bas", true)
	var hero: Dictionary = state.units[state.controlled_id]
	for unit: Dictionary in state.units.values(): unit.alive = unit.id == hero.id
	hero.pos = Vector2.ZERO
	var signatures := {}
	for key: String in KEYS:
		hero.hero = key
		for slot: String in ["Q", "W", "E", "R"]:
			state.effects = [{"shape":"circle", "origin":Vector2.ZERO, "target":Vector2(1,0), "direction":Vector2.RIGHT, "radius":2.0, "telegraph":false, "owner_id":hero.id, "team":0, "remaining":0.12, "duration":0.22, "slot":slot}]
			view.refresh(state)
			var faces: PackedVector3Array = view.mesh.get_faces()
			_check(faces.size() > 3, key + slot + " renders visible geometry")
			_check(not signatures.has(hash(faces)), key + slot + " has distinct rendered geometry")
			signatures[hash(faces)] = true
			var bounded := true
			for vertex: Vector3 in faces:
				bounded = bounded and Vector2(vertex.x, -vertex.z).length() <= 2.001
			_check(bounded, key + slot + " motif fits the authority footprint")
			state.effects[0].origin = Vector2(54,25)
			state.effects[0].target = Vector2(54,25)
			view.refresh(state)
			_check(view.rendered_points.is_empty(), key + slot + " hides outside sight")

func _check_persistent_cues(hud: Variant) -> void:
	var state: Variant = load("res://scripts/battle/battle_state.gd").new()
	state.reset("mua", true)
	state.bots_enabled = false
	var hero: Dictionary = state.units[state.controlled_id]
	var enemy: Dictionary = {}
	for unit: Dictionary in state.units.values():
		if unit.kind == "hero" and unit.team == 1 and enemy.is_empty(): enemy = unit
	for unit: Dictionary in state.units.values(): unit.alive = unit.id in [hero.id, enemy.id]
	hero.pos = Vector2.ZERO
	enemy.pos = Vector2(2,0)
	var view: Variant = load("res://scripts/presentation/effects_view.gd").new()
	root.add_child(view)
	view.terrain_map = state.map
	hero.zones = [{"id":1,"pos":Vector2(1,0),"radius":2.0,"expires":100.0,"active":true}]
	view.redraw(state, {}, -1, null)
	var active: PackedVector3Array = view.mesh.get_faces()
	_check(active.size() > 3 and hud._passive_text(state,hero).contains("활성 1"), "active Mua pool appears in world and HUD")
	hero.zones[0].active = false
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces() != active, "inactive Mua pool uses different geometry")
	hero.zones.clear()
	enemy.hero = "mua"
	enemy.zones = [{"id":2,"pos":Vector2(54,25),"radius":2.0,"expires":100.0,"active":true}]
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() == 3, "hostile pool in fog has no geometry")
	enemy.zones.clear()
	hero.hero = "sera"
	hero.marks = {enemy.id: {"stacks":2,"expires":100.0}}
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() > 3, "visible marked enemy has world cue")
	enemy.pos = Vector2(54,25)
	state._visibility_cache.clear()
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() == 3 and hud._passive_text(state,hero).contains("0중첩"), "hidden enemy mark disappears from world and HUD")
	hero.marks.clear()
	hero.hero = "orin"
	hero.wind_ready_until = 10.0
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() > 3 and hud._passive_text(state,hero).contains("10.0"), "Orin readiness appears in world and HUD")
	hero.hero = "lume"
	hero.heat_count = 3
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() > 3 and hud._passive_text(state,hero).contains("다음 공격 강화"), "Lume charged heat appears in world and HUD")
	view.queue_free()

func _check_review() -> void:
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	scene.start_match("bas", true)
	scene.paused = true
	scene.open_review_lab()
	await process_frame
	var lab: Variant = scene.review_lab
	lab.set_process(false)
	for key: String in KEYS:
		lab.select_hero(key)
		_check(lab.selected_hero == key, key + " is selectable in F7 review")
		for slot: String in ["Q", "W", "E", "R"]:
			_check(lab.play_action(slot), key + slot + " starts through real F7 authority")
			var hero: Dictionary = lab.stage.battle.units[lab.stage.battle.controlled_id]
			var origin: Vector2 = hero.pos
			var dummy: Dictionary = lab.stage.battle.units[lab._dummy_id]
			var dummy_hp: float = dummy.hp
			var initial_distance: float = hero.pos.distance_to(dummy.pos)
			if key == "mua" and slot in ["W", "E", "R"]:
				_check(hero.zones.size() == 2, key + slot + " uses real pool preparation")
			if key == "sera" and slot == "R":
				_check(not hero.marks.is_empty(), "Sera R review uses actual marked hits")
			lab.advance_review(1.0)
			if key in ["tere", "sera"] and slot == "E":
				_check(hero.pos.distance_to(origin) > 1.0, key + " review E really moves")
			if key == "tere" and slot == "E":
				_check(hero.pos.distance_to(dummy.pos) > initial_distance, "Tere E review visibly retreats from the opponent")
				_check(dummy.hp < dummy_hp, "Tere E review delayed counter actually damages the opponent")
	lab.close_review()
	await process_frame
	scene.queue_free()
	await process_frame
