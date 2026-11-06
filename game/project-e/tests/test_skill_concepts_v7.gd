extends SceneTree
## Shared player-facing ability data and the native icons consumed by the HUD.

const AbilityScript = preload("res://scripts/battle/hero_abilities.gd")
const SLOTS: Array[String] = ["Q", "W", "E", "R"]

var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var icon_images: Dictionary = {}
	var ability_names: Dictionary = {}
	for hero: String in AbilityScript.CONFIG:
		_check(AbilityScript.SKILLS.has(hero), hero + " has names for playable abilities")
		_check(AbilityScript.SKILL_HELP.has(hero), hero + " has help for playable abilities")
		_check(AbilityScript.PASSIVES.has(hero), hero + " has passive help")
		if not AbilityScript.SKILLS.has(hero) or not AbilityScript.SKILL_HELP.has(hero) or not AbilityScript.PASSIVES.has(hero):
			continue
		var names: Array = AbilityScript.SKILLS[hero]
		var help: Array = AbilityScript.SKILL_HELP[hero]
		_check(names.size() == SLOTS.size(), hero + " has one display name per input slot")
		_check(help.size() == SLOTS.size(), hero + " has one help entry per input slot")
		if names.size() != SLOTS.size() or help.size() != SLOTS.size():
			continue
		var passive: Dictionary = AbilityScript.PASSIVES[hero]
		_check(not str(passive.get("name", "")).is_empty(), hero + " passive name is visible")
		_check(not str(passive.get("description", "")).is_empty(), hero + " passive describes its trigger")
		_check_help(str(passive.get("description", "")), hero + " passive")
		for index: int in SLOTS.size():
			var slot: String = SLOTS[index]
			var label: String = hero + slot
			var display_name: String = str(names[index])
			_check(AbilityScript.CONFIG[hero].has(slot), label + " maps to an executable input slot")
			_check(not display_name.is_empty() and not ability_names.has(display_name), label + " has an unambiguous display name")
			ability_names[display_name] = true
			_check_help(str(help[index]), label)
			var icon_path: String = "res://assets/ui/skills/%s_%s.svg" % [hero, slot.to_lower()]
			_check(ResourceLoader.exists(icon_path), label + " icon imports")
			var texture: Texture2D = load(icon_path) as Texture2D
			_check(texture != null, label + " icon can be used in a button")
			if texture == null:
				continue
			_check(texture.get_size() == Vector2(144.0, 144.0), label + " retains HUD icon dimensions")
			var icon_hash: int = hash(texture.get_image().get_data())
			_check(not icon_images.has(icon_hash), label + " has distinct rendered artwork")
			icon_images[icon_hash] = true
			var source: String = FileAccess.get_file_as_string(icon_path)
			_check(source.contains("<title>" + display_name + "</title>"), label + " native artwork identifies its corresponding ability")
	print("Skill concepts V7: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _check_help(help: String, label: String) -> void:
	_check(not help.strip_edges().is_empty(), label + " help is populated")
	_check(not help.contains("핀") and not help.contains("에너지"), label + " help uses current player vocabulary")
	for line: String in help.split("\n"):
		_check(line.length() <= 38, label + " tooltip line fits compact displays")


func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
