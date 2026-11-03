extends SceneTree
## V3 art integration contract: real 3D rigs, selectable SVGs and existing authority.
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	for path: String in ["res://assets/portraits/bas.svg", "res://assets/portraits/rio.svg", "res://assets/portraits/nema.svg"]:
		_check(ResourceLoader.exists(path), "game contains imported portrait " + path)
	for hero_key: String in ["bas", "rio", "nema"]:
		for slot: String in ["q", "w", "e", "r"]:
			var path: String = "res://assets/ui/skills/%s_%s.svg" % [hero_key, slot]
			_check(ResourceLoader.exists(path), "game contains actual skill icon " + path)
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	_check(scene.arena.has_node("WorkshopDetail/FantasyDecor"), "fantasy scenery lives in cosmetic-only layer")
	for key: String in ["bas", "rio", "nema"]:
		scene.start_match(key, true)
		scene.paused = true
		scene.battle.bots_enabled = false
		var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
		var model: Node3D = scene.get_node("Units/Unit_%d/Model" % hero.id)
		var rig: Node3D = model.get_node("HeroRig")
		var head: Node3D = rig.get_node("Head")
		var actual_head: MeshInstance3D = head.get_child(0) as MeshInstance3D
		_check(actual_head != null and actual_head.mesh is SphereMesh and (actual_head.mesh as SphereMesh).radius >= 0.39, "three-head fantasy silhouette for " + key)
		_check(head.has_node("FantasyFace"), "personalized fantasy face for " + key)
		_check(rig.get_node("AnimationPlayer").has_animation("walk") and rig.get_node("AnimationPlayer").has_animation("R"), "retains walking and ultimate animation for " + key)
		_check(is_equal_approx(hero.radius, 0.45), "fantasy art does not change hit box")
		scene.hud.update_state(scene.battle, "", true)
		for slot: String in ["Q", "W", "E", "R"]:
			var icon: TextureRect = scene.hud._skill_icons.get(slot) as TextureRect
			_check(icon != null and icon.texture != null, "%s %s icon bound to gameplay HUD" % [key,slot])
			if icon != null and icon.texture != null:
				_check(icon.texture.resource_path.ends_with("%s_%s.svg" % [key, slot.to_lower()]), "HUD icon switches with %s %s" % [key,slot])
	scene.queue_free()
	await process_frame
	print("Fantasy V3: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
