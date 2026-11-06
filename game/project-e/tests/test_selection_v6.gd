extends SceneTree
## Presentation contract for illustrated selection and compact battle controls.
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var hud: Variant = load("res://scripts/presentation/battle_hud.gd").new()
	root.add_child(hud)
	await process_frame
	await process_frame
	_check(hud.selection.visible, "selection opens before a match")
	_check(ResourceLoader.exists("res://assets/ui/canal-backdrop.webp"), "selection includes the scenic canal illustration")
	var portraits: Array[Node] = hud.selection.find_children("*", "TextureRect", true, false)
	for key: String in ["bas", "rio", "nema"]:
		var found: bool = false
		for node: Node in portraits:
			var portrait := node as TextureRect
			if portrait.texture != null and portrait.texture.resource_path == "res://assets/portraits/%s.webp" % key:
				found = true
				_check(portrait.size.y >= 180.0, key + " illustration has room for the hero")
		_check(found, key + " uses the shipped illustrated portrait")
		hud._hero_buttons[key].pressed.emit()
		_check(hud.selected_hero == key and hud._hero_buttons[key].button_pressed, key + " card selects its hero")
		_check(hud._start.text.contains(hud.HEROES[key][0]), key + " start control identifies the selected hero")
	var requests: Array = []
	hud.match_requested.connect(func(key: String, practice: bool) -> void: requests.append([key, practice]))
	hud._practice.button_pressed = true
	hud._start.pressed.emit()
	_check(requests == [["nema", true]], "start preserves hero and practice choice")
	hud._practice.button_pressed = false
	hud._start.pressed.emit()
	_check(requests == [["nema", true], ["nema", false]], "regular match remains selectable")
	hud.show_match()
	hud.show_message("기술 체험 · 레벨 3 / R 해금 · P 상점 / D 사용 · F1 도움말", 5.0)
	var feedback_point: Vector2 = hud._toast.get_global_rect().get_center()
	_check(not hud.blocks_point(feedback_point), "informational toast is click-through immediately after opening a match at %s, rect %s" % [feedback_point, hud._toast.get_global_rect()])
	await process_frame
	await process_frame
	_check(hud._bottom.size.y <= 120.0, "battle dock leaves the field visible")
	_check(hud._skill_buttons.size() == 4, "compact dock retains all four skills")
	_check(hud._passive.mouse_filter == Control.MOUSE_FILTER_PASS, "passive tooltip receives pointer hover")
	_check(hud._xp.mouse_filter == Control.MOUSE_FILTER_PASS, "score tooltip receives pointer hover")
	for slot: String in ["Q", "W", "E", "R"]:
		_check(hud._skill_labels[slot][0].get_theme_font_size("font_size") >= 12, slot + " skill name remains readable")
		_check(hud._skill_labels[slot][1].get_theme_font_size("font_size") >= 11, slot + " skill state remains readable")
		_check(hud._skill_labels[slot][2].get_theme_font_size("font_size") >= 10, slot + " skill cost remains readable")
	_check(hud._inventory.size.y <= 60.0, "consumables use a compact dock")
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(960, 540)]:
		root.content_scale_size = dimensions
		root.size = dimensions
		await process_frame
		await process_frame
		var visible: Rect2 = root.get_visible_rect()
		_check(visible.encloses(hud._bottom.get_global_rect()), "battle dock fits " + str(dimensions))
		_check(visible.encloses(hud._inventory.get_global_rect()), "inventory fits " + str(dimensions))
		var toast_rect: Rect2 = hud._toast.get_global_rect()
		_check(toast_rect.position.y >= 124.0, "toast clears the camera controls " + str(dimensions))
		_check(not toast_rect.intersects(hud._target.get_global_rect()), "toast clears target details " + str(dimensions))
		_check(not toast_rect.intersects(hud._map_panel.get_global_rect()), "toast clears minimap " + str(dimensions))
	hud.queue_free()
	await process_frame
	print("Selection V6: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
