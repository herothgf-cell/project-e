extends SceneTree
## New fantasy identities must reach the controls players actually use.
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var scene: Variant = load("res://scenes/battlefield.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	await process_frame
	scene.set_physics_process(false)
	scene.set_process(false)
	for key: String in ["bas", "rio", "nema"]:
		scene.start_match(key, true)
		scene.battle.bots_enabled = false
		var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
		scene.hud.update_state(scene.battle, "", true)
		_check(scene.hud._energy_text.text.begins_with("마나"), key + " resource bar uses mana")
		_check(scene.hud._inventory_credits.text.contains("골드"), key + " inventory uses gold")
		var passive_detail: String = {"bas": "기본 공격", "rio": "마나", "nema": "보호막"}[key]
		_check(scene.hud._passive.tooltip_text.contains(passive_detail), key + " passive tooltip explains its actual trigger and reward")
		for slot: String in ["Q", "W", "E", "R"]:
			var button: Button = scene.hud._skill_buttons[slot]
			_check(button.tooltip_text.contains("마나"), key + slot + " tooltip uses mana")
			_check(not button.tooltip_text.contains("핀"), key + slot + " tooltip uses current fantasy entities")
			_check(scene.hud._skill_labels[slot][2].text.begins_with("마나"), key + slot + " compact cost uses mana")
		for item_id: String in ["I01", "I02"]:
			var button: Button = scene.hud._item_buttons[item_id]
			_check(button.icon != null, item_id + " inventory displays its dedicated icon")
			_check(button.tooltip_text.contains("회복"), item_id + " inventory explains its recovery effect")
			var art := scene.hud.shop.find_child("ItemArt" + item_id, true, false) as TextureRect
			_check(art != null and art.texture != null, item_id + " shop displays its dedicated illustration")
		_check(not scene.hud._growth_stats.text.contains("에너지"), key + " growth uses the current resource label")
	var hero: Dictionary = scene.battle.units[scene.battle.controlled_id]
	hero.pos = Vector2(-56, 0)
	scene.open_shop()
	for size: Vector2i in [Vector2i(1280, 720), Vector2i(960, 540)]:
		root.size = size
		await process_frame
		await process_frame
		var viewport: Rect2 = root.get_visible_rect()
		for item_id: String in ["I01", "I02"]:
			_check(viewport.encloses(scene.hud._shop_buy_buttons[item_id].get_global_rect()), item_id + " purchase fits " + str(size))
		_check(viewport.encloses(scene.hud._shop_close.get_global_rect()), "shop close fits " + str(size))
	scene.close_shop()
	scene.open_review_lab()
	await process_frame
	var lab: Variant = scene.review_lab
	for key: String in ["bas", "rio", "nema"]:
		lab.select_hero(key)
		for index: int in range(4):
			var slot: String = ["Q", "W", "E", "R"][index]
			_check(lab.play_action(slot), key + slot + " review action is accepted")
			_check(lab.status.text.contains(scene.hud.SKILLS[key][index]), key + slot + " review identifies the current skill")
	lab.close_review()
	scene.queue_free()
	await process_frame
	print("Fantasy HUD V7: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
