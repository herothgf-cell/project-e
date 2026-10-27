extends SceneTree
## Run outside the source project with --main-pack PATH/ProjectE.pck.
## Tests the exported game's real scene and authority, not a Windows executable.

var _checks: int = 0
var _failures: int = 0
var _frames_saved: int = 0
var _output: String = ""

func _initialize() -> void:
	for argument: String in OS.get_cmdline_user_args():
		if argument.begins_with("--output="):
			_output = argument.trim_prefix("--output=")
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var packed: PackedScene = load("res://scenes/battlefield.tscn")
	_check(packed != null, "exported battlefield resource loads")
	if packed == null:
		quit(1)
		return
	var scene: Variant = packed.instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	await _capture("01-pack-selection.png")
	_check(scene.selection_visible(), "exported game opens selection")
	scene.start_match("bas", false)
	scene.battle.bots_enabled = false
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	_check(hero.credits == 100.0 and hero.level == 1, "normal exported match starts with original credits and level")
	_check(scene.handle_hotkey(KEY_P) and scene.shop_visible() and scene.paused, "P opens exported shop")
	await _capture("02-pack-shop.png")
	scene.hud._shop_buy_buttons.I01.pressed.emit()
	scene.hud._shop_buy_buttons.I02.pressed.emit()
	_check(hero.credits == 10.0 and hero.consumables.I01 == 1 and hero.consumables.I02 == 1, "exported scene buys both items through actual UI authority")
	scene.close_shop()
	_check(not scene.paused and not scene.shop_visible(), "closing exported shop resumes match")
	hero.pos = Vector2(-45, 0)
	hero.energy = 50.0
	scene.hud._item_buttons.I01.pressed.emit()
	_check(scene.handle_hotkey(KEY_D), "D reaches exported selected-item command")
	scene.battle.step(0.5)
	_check(hero.consumables.I01 == 0 and hero.consumables.I02 == 1, "exported use consumes exactly selected item")
	_check(absf(hero.energy - 64.0) < 0.001, "exported bottle adds 10 energy plus 4 ordinary regen in half second")
	_check(absf(hero.consumable_cooldown - 11.5) < 0.001, "exported shared cooldown ticks")
	await _capture("03-pack-recovery.png")
	scene.queue_free()
	await process_frame
	print("Exported pack consumables: %d checks, %d failures; %d frames" % [_checks, _failures, _frames_saved])
	quit(0 if _failures == 0 else 1)

func _capture(filename: String) -> void:
	for _index: int in range(6):
		await process_frame
	if DisplayServer.get_name() == "headless" or _output.is_empty():
		return
	DirAccess.make_dir_recursive_absolute(_output)
	await RenderingServer.frame_post_draw
	var frame: Image = root.get_texture().get_image()
	_check(not frame.is_empty() and frame.save_png(_output.path_join(filename)) == OK, "exported pack frame saved: " + filename)
	_frames_saved += 1

func _check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error(label)
