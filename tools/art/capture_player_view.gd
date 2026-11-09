extends SceneTree
## Review the same visible UI in a source checkout and the exported Windows PCK.
const Roster = preload("res://scripts/battle/hero_roster.gd")
var output := ""
var inline_preview := false
var capture_source := "source checkout"
var failures := 0
var checks := 0
var scene: Variant
var records: Array[Dictionary] = []

func _initialize() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			output = argument.trim_prefix("--output=")
		if argument == "--inline-preview":
			inline_preview = true
		if argument == "--exported-pck":
			capture_source = "exported PCK"
	call_deferred("_run")

func _run() -> void:
	if output.is_empty():
		push_error("Provide --output for player-view captures")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(output)
	root.size = Vector2i(1280, 720)
	scene = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	scene.edge_pan_enabled = false
	await _settle()
	_check(scene.hud.selection.visible, "Hero selection is the initial screen")
	_check(str(ProjectSettings.get_setting("application/config/version", "")) == "0.8.0", "V8 build identity")
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(960, 540)]:
		root.size = size
		await _settle()
		var bounds: Rect2 = root.get_visible_rect()
		_check(bounds.encloses(scene.hud._start.get_global_rect()), "Start button fits " + str(size))
		for key: String in Roster.KEYS:
			var card: Control = scene.hud._hero_buttons[key]
			_check(card.is_visible_in_tree(), "Visible hero choice " + key)
			_check(bounds.encloses(card.get_global_rect()), "Hero choice fits " + key + " " + str(size))
			var illustrated := false
			for art in card.find_children("*", "TextureRect", true, false):
				if art.name == "HeroIllustration" and art.texture != null:
					illustrated = art.get_global_rect().size.y >= minf(140.0, bounds.size.y * 0.20)
			_check(illustrated, "Readable hero portrait " + key + " " + str(size))
		await _save("selection-%dx%d" % [size.x, size.y])
	for key: String in Roster.KEYS:
		var portrait: TextureRect = scene.hud._hero_buttons[key].get_node("HeroIllustration")
		if key in ["bas", "rio", "nema"]:
			_check(portrait.texture.resource_path == "res://assets/portraits/" + key + ".webp", "Illustrated portrait is rendered " + key)
		else:
			var rendered: Image = portrait.texture.get_image()
			_check(rendered != null and rendered.get_used_rect().has_area(), "Native model portrait contains rendered pixels " + key)
			_check(portrait.has_node("ModelPortrait"), "Portrait uses the shipped hero model " + key)
	# Route actual GUI pointer events at the smallest supported window size.
	for key: String in Roster.KEYS:
		await _click(scene.hud._hero_buttons[key])
		_check(scene.hud.selected_hero == key, "Pointer selects " + key + " at 960x540")
		for candidate: String in Roster.KEYS:
			_check(scene.hud._selection_tags[candidate].visible == (candidate == key), "Exclusive selection tag " + candidate)
	var regular: BaseButton
	for mode: BaseButton in scene.hud._practice.button_group.get_buttons():
		if mode != scene.hud._practice:
			regular = mode
	await _click(scene.hud._practice)
	_check(scene.hud._practice.button_pressed and not regular.button_pressed, "Pointer chooses practice exclusively")
	await _click(regular)
	_check(regular.button_pressed and not scene.hud._practice.button_pressed, "Pointer returns to regular match")
	await _click(scene.hud._practice)
	await _click(scene.hud._start)
	_check(scene.has_active_match and scene.is_practice, "Pointer starts the selected match mode")
	_check(scene.battle.units[scene.battle.controlled_id].hero == "lume", "Pointer start uses selected hero")
	scene.return_to_selection()
	await _settle()
	_check(scene.hud.selection.visible and not scene.has_active_match, "Returning to selection enables another match")
	root.size = Vector2i(1280, 720)
	for key: String in Roster.KEYS:
		scene.hud.select_hero(key)
		await _settle()
		await _save("selection-" + key)
	scene.start_match("bas", true)
	scene.edge_pan_enabled = false
	scene.battle.bots_enabled = false
	scene.set_physics_process(false)
	scene.set_process(false)
	var player: Dictionary = scene.battle.units[scene.battle.controlled_id]
	player.pos = Vector2(-3.8, 0.4)
	player.facing = Vector2.RIGHT
	for unit: Dictionary in scene.battle.units.values():
		if unit.kind != "hero" or unit.id == player.id:
			continue
		var west: bool = int(unit.team) == 0
		var offset: float = -1.6 if str(unit.hero) == "rio" else 1.8
		unit.pos = Vector2(-8.0 if west else 4.0, offset)
	scene.battle._visibility_cache.clear()
	scene._camera_follow = false
	scene._camera_focus = Vector2(-0.7, -0.8)
	scene.set_camera_mode("combat")
	scene._process(0.0)
	scene.hud._toast_left = 0.0
	scene.hud._toast.hide()
	await _settle()
	await _save("battle-v8")
	var bottom: Control = scene.hud._bottom
	_check(bottom.get_global_rect().size.y <= 128.0, "Compact battle HUD")
	_check(root.get_visible_rect().encloses(bottom.get_global_rect()), "Battle HUD fits viewport")
	root.size = Vector2i(960, 540)
	player.hp = 48.0
	player.energy = 7.0
	scene.hud.update_state(scene.battle, "", true)
	scene.hud.show_message("일반 병사는 마지막 체력을 남깁니다. 영웅으로 마무리하세요.", 8.0)
	for enemy: Dictionary in scene.battle.units.values():
		if enemy.kind == "hero" and enemy.team == 1:
			scene.hud.show_target(enemy)
			break
	await _settle()
	for control: Control in [scene.hud._bottom, scene.hud._inventory, scene.hud._toast, scene.hud._target, scene._review_button, scene._camera_hint]:
		_check(root.get_visible_rect().encloses(control.get_global_rect()), "Small-window battle control fits " + control.name)
	_check(not scene.hud._toast.get_global_rect().intersects(scene.hud._target.get_global_rect()), "Small-window toast avoids target")
	_check(not scene._camera_hint.get_global_rect().intersects(scene.hud._toast.get_global_rect()), "Camera hint avoids toast")
	_check(not scene._camera_hint.get_global_rect().intersects(scene.hud._map_panel.get_global_rect()), "Small-window camera hint avoids minimap")
	for camera_control: Control in [scene._camera_hint, scene._review_button]:
		for panel: Control in [scene.hud._top, scene.hud._target]:
			_check(not camera_control.get_global_rect().intersects(panel.get_global_rect()), "Small-window camera row avoids HUD panels")
	await _save("battle-low-health-960x540")
	await _capture_fantasy_kits()
	var document := {"version": "0.8.0", "engine": Engine.get_version_info().string,
		"source": capture_source,
		"checks": checks, "failures": failures, "captures": records}
	var manifest := FileAccess.open(output.path_join("player-review.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify(document, "\t"))
	manifest.close()
	scene.queue_free()
	await process_frame
	await process_frame
	if failures == 0:
		print("PLAYER_REVIEW_OK ", checks, " checks")
	quit(0 if failures == 0 else 1)

func _capture_fantasy_kits() -> void:
	root.size = Vector2i(1280, 720)
	scene.start_match("bas", true)
	scene.battle.bots_enabled = false
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-56, 0)
	hero.credits = 200
	scene.open_shop()
	for item_id: String in ["I01", "I02"]:
		_check(scene.buy_consumable(item_id), "Shop buys fantasy item " + item_id)
		_check(scene.hud._item_buttons[item_id].icon != null, "Inventory binds item icon " + item_id)
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = size
		await _settle()
		_check(root.get_visible_rect().encloses(scene.hud._shop_close.get_global_rect()), "Shop fits " + str(size))
		for item_id: String in ["I01", "I02"]:
			_check(root.get_visible_rect().encloses(scene.hud._shop_buy_buttons[item_id].get_global_rect()), "Shop item fits " + item_id + str(size))
		await _save("shop-%dx%d" % [size.x, size.y])
	scene.close_shop()
	root.size = Vector2i(1280, 720)
	for item_id: String in ["I01", "I02"]:
		scene.start_match("rio" if item_id == "I01" else "nema", true)
		scene.battle.bots_enabled = false
		hero = scene.battle.units[scene.battle.controlled_id]
		hero.pos = Vector2(-56, 0)
		hero.credits = 100
		scene.open_shop()
		_check(scene.buy_consumable(item_id), "Recovery capture buys " + item_id)
		scene.close_shop()
		hero.pos = Vector2(-3, 0)
		hero.energy = 10.0
		hero.hp -= 320.0
		_check(scene.select_consumable(item_id) and scene.use_consumable(), "Real item activation " + item_id)
		scene.battle.step(0.6)
		_check(hero.consumable_effect.get("item_id", "") == item_id, "Real recovery is active " + item_id)
		scene._camera_follow = false
		scene._camera_focus = hero.pos
		scene.set_camera_mode("detail")
		scene._process(0.0)
		scene.hud._toast.hide()
		await _settle()
		await _save("item-" + item_id.to_lower() + "-active")
	scene.open_review_lab()
	await process_frame
	var lab: Variant = scene.review_lab
	lab.set_process(false)
	for key: String in Roster.KEYS:
		lab.select_hero(key)
		await _settle()
		await _save("hero-" + key)
		for index: int in range(4):
			var slot: String = ["Q", "W", "E", "R"][index]
			_check(lab.play_action(slot), "V8 actual cast " + key + slot)
			hero = lab.stage.battle.units[lab.stage.battle.controlled_id]
			var capture_time := float(hero.cast.windup) + 0.14
			if key == "tere" and slot == "E":
				capture_time += float(hero.cast.dash_distance) / float(hero.cast.dash_speed) + 0.35
			lab.advance_review(capture_time)
			_check(lab.status.text.contains(scene.hud.SKILLS[key][index]), "V8 review skill identity " + key + slot)
			await _settle()
			await _save("skill-" + key + "-" + slot.to_lower())
	lab.close_review()
	await process_frame

func _click(control: Control) -> void:
	var point: Vector2 = control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	root.push_input(motion, true)
	for pressed: bool in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = point
		event.global_position = point
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
		event.pressed = pressed
		root.push_input(event, true)
		await process_frame

func _settle() -> void:
	for index in range(15):
		await process_frame
	await RenderingServer.frame_post_draw

func _check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		print("PLAYER_REVIEW_FAIL ", label)

func _save(stem: String) -> void:
	await RenderingServer.frame_post_draw
	var snapshot: Image = root.get_texture().get_image()
	var path := output.path_join(stem + ".webp")
	var error := snapshot.save_webp(path, false, 0.88)
	_check(error == OK, "Saved " + stem)
	var entry: Dictionary = {"name": stem, "width": snapshot.get_width(),
		"height": snapshot.get_height(), "sha256": FileAccess.get_sha256(path)}
	records.append(entry)
	if inline_preview and stem in ["selection-1280x720", "selection-960x540", "selection-mua", "battle-v8", "shop-1280x720", "hero-orin", "hero-tere", "hero-mua", "hero-sera", "hero-lume", "skill-orin-r", "skill-tere-e", "skill-mua-r", "skill-sera-r", "skill-lume-r"]:
		snapshot.resize(1024, 576, Image.INTERPOLATE_LANCZOS)
		print("PLAYER_PREVIEW_IMAGE ", stem, " ", Marshalls.raw_to_base64(snapshot.save_webp_to_buffer(false, 0.74)))
