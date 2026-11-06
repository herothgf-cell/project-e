extends SceneTree
## Fantasy item metadata is shared by the shop, inventory, recovery VFX and audio.
const CATALOG_PATH: String = "res://scripts/battle/battle_consumables.gd"
var checks: int = 0
var failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var catalog: Script = load(CATALOG_PATH)
	_check(catalog != null, "consumable catalog loads")
	if catalog == null:
		_finish()
		return
	var items: Dictionary = catalog.ITEMS
	_check(items.size() == 2 and items.has("I01") and items.has("I02"), "implemented roster contains both recovery items")
	_check(catalog.CAPACITY == 2, "combined inventory capacity is two")
	_check(catalog.USE_COOLDOWN == 12.0, "both items share twelve-second cooldown")
	_check_item(items.get("I01", {}), "I01", {
		"name": "별샘 영약",
		"cost": 40,
		"resource": "energy",
		"amount": 40.0,
		"duration": 2.0,
		"icon": "res://assets/ui/items/starlight_elixir.svg",
		"description": "마나 40을 2초 동안 회복",
		"condition": "적 영웅 피해에도 회복 유지",
		"effect_name": "별샘의 마력",
		"tint": Color("#9fdfff"),
		"motif": "starlight",
		"cue": "arcane",
	})
	_check_item(items.get("I02", {}), "I02", {
		"name": "숲빛 치유약",
		"cost": 50,
		"resource": "hp",
		"amount": 200.0,
		"duration": 4.0,
		"icon": "res://assets/ui/items/grove_salve.svg",
		"description": "체력 200을 4초 동안 회복",
		"condition": "적 영웅에게 피해를 받으면 회복 중단",
		"effect_name": "숲빛 재생",
		"tint": Color("#9ce3a8"),
		"motif": "nature",
		"cue": "nature",
	})
	_finish()


func _check_item(item: Dictionary, item_id: String, expected: Dictionary) -> void:
	for field: String in expected:
		_check(item.get(field) == expected[field], "%s shares expected %s" % [item_id, field])
	var icon_path: String = item.get("icon", "")
	var icon_exists: bool = not icon_path.is_empty() and ResourceLoader.exists(icon_path)
	_check(icon_exists, item_id + " icon resource exists")
	if not icon_exists:
		return
	var texture: Texture2D = load(icon_path) as Texture2D
	_check(texture != null, item_id + " icon loads as a texture")
	if texture != null:
		_check(texture.get_size() == Vector2(144, 144), item_id + " icon matches the skill icon resolution")
		var pixels: Image = texture.get_image()
		_check(pixels != null and not pixels.is_empty(), item_id + " icon has rendered pixels")


func _check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)


func _finish() -> void:
	print("Item concepts V7: %d checks, %d failures" % [checks, failures])
	quit(1 if failures else 0)
