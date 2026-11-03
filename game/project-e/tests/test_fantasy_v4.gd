extends SceneTree
## Red/green V4 presentation tests; do not change authority for prettier visuals.
var checks: int = 0
var failures: int = 0
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	# Source audio must exist as original mono wav; reference binding is tested in-scene.
	for sound: String in ["slash", "arcane", "nature", "hit", "level"]:
		_check(ResourceLoader.exists("res://assets/audio/%s.wav" % sound), "original cue imported: " + sound)
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	for key: String in ["bas", "rio", "nema"]:
		scene.start_match(key, true)
		scene.paused = true
		scene.battle.bots_enabled = false
		var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
		var rig: Node3D = scene._unit_nodes[hero.id].get_node("Model/HeroRig")
		_check(rig.get_node_or_null("RightArm/WeaponDetail") != null, key + " weapon follows arm")
		_check(rig.get_node_or_null("Head/HairDetail") != null, key + " head has volumetric hair detail")
		_check(rig.get_node_or_null("Torso/RuneEmblem") != null, key + " armor has role emblem")
		var snapshot: Dictionary = hero.duplicate(true)
		hero.phase = "walk"
		rig.pose(hero, 1.13)
		var pos_a: Vector3 = rig.position
		rig.pose(hero, 1.34)
		var pos_b: Vector3 = rig.position
		_check(pos_a.distance_to(pos_b) > 0.008, key + " locomotion has visible body motion")
		_check(absf(pos_a.y) < 0.14 and absf(pos_b.y) < 0.14, key + " locomotion remains grounded")
		hero.phase = "idle"
		rig.pose(hero, 1.13)
		_check(absf(rig.position.y) < 0.04, key + " idle pose removes walk bob")
		hero.phase = snapshot.phase
		_check(hero == snapshot, key + " rendering does not change state")
	var vfx: Variant = scene.get_node("SkillVFX")
	_check(vfx.has_method("style_for"), "VFX exposes kit specific visual profile")
	if vfx.has_method("style_for"):
		var variants: Dictionary = {}
		for key: String in ["bas", "rio", "nema"]:
			for slot: String in ["Q", "W", "E", "R"]:
				var style: Dictionary = vfx.style_for(key, slot)
				var label: String = str(style.get("motif", ""))
				_check(not label.is_empty() and not variants.has(label), key + slot + " distinct motif")
				variants[label] = true
	_check(scene.has_node("FantasyAudio"), "gameplay integrates local audio observer")
	if scene.has_node("FantasyAudio"):
		var audio: Node = scene.get_node("FantasyAudio")
		_check(audio.has_method("observe"), "audio observes actual controlled authority")
		var cues: Array[String] = []
		audio.cue_played.connect(func(name: String) -> void: cues.append(name))
		scene.start_match("bas", true)
		scene.paused = true
		var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
		audio.observe(scene.battle, true, false)
		hero.phase = "basic"
		audio.observe(scene.battle, true, false)
		audio.observe(scene.battle, true, false)
		_check(cues.count("slash") == 1, "basic attack sounds once, not every frame")
		hero.phase = "idle"
		audio.observe(scene.battle, true, false)
		hero.phase = "windup"
		hero.cast = {"slot":"Q", "windup":0.25}
		audio.observe(scene.battle, true, false)
		audio.observe(scene.battle, true, false)
		_check(cues.count("slash") == 2, "Bas Q cast sounds once")
		hero.phase = "idle"
		hero.cast = {}
		audio.observe(scene.battle, true, false)
		hero.phase = "windup"
		hero.cast = {"slot":"Q", "windup":0.25}
		audio.observe(scene.battle, true, false)
		_check(cues.count("slash") == 3, "second same-slot cast sounds again")
		hero.last_damage = 4.0
		audio.observe(scene.battle, true, false)
		audio.observe(scene.battle, true, false)
		_check(cues.count("hit") == 1, "player damage cue deduplicates")
		hero.level += 1
		audio.observe(scene.battle, true, false)
		_check(cues.count("level") == 1, "level-up cue triggers exactly once")
		var count_before: int = cues.size()
		audio.observe(scene.battle, true, true)
		_check(cues.size() == count_before, "paused match is silent")
		var enemy: Dictionary = {}
		for unit: Dictionary in scene.battle.units.values():
			if unit.kind == "hero" and unit.team == 1:
				enemy = unit
				break
		enemy.phase = "windup"
		enemy.cast = {"slot":"R"}
		audio.observe(scene.battle, true, false)
		_check(cues.size() == count_before, "enemy actor never triggers local cue")
	scene.queue_free()
	await process_frame
	print("Fantasy V4: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)
func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
