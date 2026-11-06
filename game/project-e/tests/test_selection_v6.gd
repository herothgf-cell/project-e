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
	await process_frame
	await process_frame
	_check(hud._bottom.size.y <= 120.0, "battle dock leaves the field visible")
	_check(hud._skill_buttons.size() == 4, "compact dock retains all four skills")
	_check(hud._inventory.size.y <= 60.0, "consumables use a compact dock")
	hud.queue_free()
	await process_frame
	print("Selection V6: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
