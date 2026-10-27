extends SceneTree
## Real renderer and reproducible authority fixtures; this is not a human match.
## DISPLAY=:97 LIBGL_ALWAYS_SOFTWARE=1 Godot --path game/project-e \
##   --script tests/capture_consumables.gd --audio-driver Dummy -- --output=ABSOLUTE_DIRECTORY
var _out: String
var _scene: Variant
var _saved: int = 0
var _failed: bool = false

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("A graphical display is required for actual rendered consumable evidence.")
		quit(1)
		return
	_out = ProjectSettings.globalize_path("res://../../build/base-consumables/screenshots")
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_out = argument.trim_prefix("--output=")
	DirAccess.make_dir_recursive_absolute(_out)
	_scene = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(_scene)
	_scene.set_physics_process(false)
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		await _frame()
		var suffix: String = "720p" if dimensions.y == 720 else "1080p"
		_scene.return_to_selection()
		await _frame()
		await _save("00-selection-" + suffix + ".png")
		var hero: Dictionary = _start()
		_scene.open_shop()
		await _frame()
		await _save("01-shop-" + suffix + ".png")
		_scene.hud._shop_buy_buttons.I01.pressed.emit()
		_scene.hud._shop_buy_buttons.I02.pressed.emit()
		_verify(hero.consumables.I01 == 1 and hero.consumables.I02 == 1 and hero.credits == 120, "two authority purchases")
		_scene.close_shop()
		_scene.hud._item_buttons.I02.pressed.emit()
		_clear_toast()
		await _frame()
		await _save("02-inventory-" + suffix + ".png")
		_scene.hud._item_buttons.I01.pressed.emit()
		hero.energy = hero.max_energy - 60.0
		_scene.handle_hotkey(KEY_D)
		_scene.battle.step(0.5)
		_verify(hero.consumable_effect.get("item_id", "") == "I01" and absf(hero.consumable_cooldown - 11.5) < 0.01, "active bottle recovery")
		await _frame()
		await _save("03-recovery-" + suffix + ".png")
		hero = _start()
		_scene.open_shop()
		_scene.hud._shop_buy_buttons.I02.pressed.emit()
		_scene.close_shop()
		hero.pos = Vector2(-45, 0)
		hero.hp = hero.max_hp - 300.0
		_scene.select_consumable("I02")
		_scene.use_consumable()
		_scene.battle.step(0.5)
		var enemy: Dictionary = {}
		for unit: Dictionary in _scene.battle.units.values():
			if unit.kind == "hero" and unit.team == 1:
				enemy = unit
				break
		_scene.battle.apply_damage(enemy.id, hero.id, 10.0, 94001)
		_verify(hero.consumable_effect.is_empty(), "actual hero-owned patch interruption")
		await _frame()
		_verify(_scene.hud._toast_text.text.contains("중단"), "Korean interruption event feedback")
		await _save("04-interruption-" + suffix + ".png")
		_clear_toast()
		_scene.handle_hotkey(KEY_F1)
		await _frame()
		await _save("05-help-" + suffix + ".png")
		_scene.close_help()
		_scene.open_shop()
		await _frame()
		_verify(_scene.hud._shop_buy_buttons.I01.disabled, "offbase shop is inspectable and disabled")
		await _save("06-offbase-shop-" + suffix + ".png")
		_scene.close_shop()
		_scene.battle.apply_damage(enemy.id, hero.id, 10000.0, 94002)
		_scene.open_shop()
		await _frame()
		_verify(not hero.alive and _scene.shop_visible() and _scene.hud._shop_buy_buttons.I02.disabled, "dead shop is inspectable and disabled")
		await _save("07-dead-shop-" + suffix + ".png")
	_scene.queue_free()
	await process_frame
	print("Consumables render: %d frames, %s" % [_saved, "FAIL" if _failed else "PASS"])
	quit(1 if _failed else 0)

func _start() -> Dictionary:
	_scene.start_match("bas", true)
	_scene.battle.bots_enabled = false
	var hero: Dictionary = _scene.battle.units[_scene.battle.controlled_id]
	# Fixed local-state fixtures only: normal catalog, prices, commands and damage.
	hero.credits = 210
	hero.pos = Vector2(-56, 0)
	_scene._camera_follow = true
	_scene._update_camera(0)
	_clear_toast()
	Input.warp_mouse(Vector2(1100, 120))
	return hero

func _clear_toast() -> void:
	_scene.hud._toast_left = 0.0
	_scene.hud._toast.hide()

func _verify(condition: bool, label: String) -> void:
	if not condition:
		_failed = true
		push_error("Capture fixture failed: " + label)

func _frame() -> void:
	for _index: int in range(6):
		await process_frame
	await RenderingServer.frame_post_draw

func _save(filename: String) -> void:
	var frame: Image = root.get_texture().get_image()
	if frame.is_empty() or frame.save_png(_out.path_join(filename)) != OK:
		_failed = true
		push_error("Could not save " + filename)
		return
	_saved += 1
	print("Saved " + filename + " " + str(frame.get_size()))
