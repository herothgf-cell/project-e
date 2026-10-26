extends Control
## Visible-unit status and short damage feedback from observed simulation changes.

var battle: Variant
var camera: Camera3D
var ui_font: Font
var use_korean: bool = false
var enabled: bool = false
var _previous: Dictionary = {}
var _floaters: Array[Dictionary] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func reset_feedback() -> void:
	_previous.clear()
	_floaters.clear()


func update_feedback(delta: float) -> void:
	if battle == null:
		return
	for floater: Dictionary in _floaters:
		floater.life -= delta
	_floaters = _floaters.filter(func(entry: Dictionary) -> bool: return entry.life > 0)
	var fresh: Dictionary = {}
	for id: int in battle.units:
		var unit: Dictionary = battle.units[id]
		# Snapshot only continuously visible units. Returning from fog never invents damage.
		if not battle.is_visible(0, id):
			continue
		if _previous.has(id):
			var old: Dictionary = _previous[id]
			var damage: float = maxf(0, float(old.hp) - float(unit.hp))
			var shield_damage: float = maxf(0, float(old.shield) - float(unit.shield))
			if damage > 0.4:
				_floaters.append({"pos": unit.pos, "amount": ceili(damage), "life": 0.85, "shield": false})
			# Shield loss can also be expiration, so only HP loss generates a damage number.
			if shield_damage > 0.4 and damage > 0.4:
				_floaters.append({"pos": unit.pos + Vector2(0.45, 0), "amount": ceili(shield_damage), "life": 0.72, "shield": true})
		fresh[id] = {"hp": unit.hp, "shield": unit.shield}
	_previous = fresh
	while _floaters.size() > 40:
		_floaters.pop_front()
	queue_redraw()


func _draw() -> void:
	if not enabled or battle == null or camera == null or ui_font == null:
		return
	for id: int in battle.units:
		var unit: Dictionary = battle.units[id]
		if not unit.alive or not battle.is_visible(0, id):
			continue
		var kind: String = str(unit.kind)
		if kind == "minion" and float(unit.hp) >= float(unit.max_hp):
			continue
		var height: float = 2.35 if kind == "hero" else 1.25
		if kind in ["tower", "core"]:
			height = 3.6
		var world := Vector3(unit.pos.x, height, -unit.pos.y)
		if camera.is_position_behind(world):
			continue
		var point: Vector2 = camera.unproject_position(world)
		if not Rect2(Vector2(8, 78), size - Vector2(16, 190)).has_point(point):
			continue
		var width: float = 70.0 if kind == "hero" else 49.0
		if kind in ["tower", "core"]:
			width = 82.0
		var color := Color("4dd4bb") if int(unit.team) == 0 else Color("f8985e")
		if int(unit.team) == 2:
			color = Color("e8c96d")
		var rect := Rect2(point - Vector2(width * 0.5, 0), Vector2(width, 6))
		draw_style_box(_plate(), rect.grow(2))
		draw_rect(Rect2(rect.position, Vector2(width * clampf(float(unit.hp) / maxf(1, float(unit.max_hp)), 0, 1), 6)), color)
		if float(unit.shield) > 0:
			draw_rect(Rect2(rect.position - Vector2(0, 3), Vector2(width * clampf(float(unit.shield) / maxf(1, float(unit.max_hp)), 0, 1), 2)), Color("d6f8ed"))
		if kind == "hero":
			draw_rect(Rect2(rect.position + Vector2(0, 8), Vector2(width * clampf(float(unit.energy) / maxf(1, float(unit.max_energy)), 0, 1), 2)), Color("6fbcec"))
			var hero_names: Dictionary = {"bas": "바스" if use_korean else "BAS", "rio": "리오" if use_korean else "RIO", "nema": "네마" if use_korean else "NEMA"}
			var text: String = "%s  %d" % [hero_names.get(str(unit.hero), ""), int(unit.level)]
			if id == battle.controlled_id:
				text = ("나 · " if use_korean else "YOU · ") + text
			_text_center(text, point - Vector2(0, 6), 12, Color("fff5d8"))
		elif kind in ["tower", "core"] and (unit.get("locked", false) or unit.get("siege_protected", false)):
			var text: String = ("잠금" if use_korean else "LOCKED") if unit.get("locked", false) else ("병력 보호" if use_korean else "GUARDED")
			_text_center(text, point - Vector2(0, 5), 11, Color("fff0cc"))
	for floater: Dictionary in _floaters:
		var world := Vector3(floater.pos.x, 2.5 + (0.85 - float(floater.life)) * 1.5, -floater.pos.y)
		if camera.is_position_behind(world):
			continue
		var point: Vector2 = camera.unproject_position(world)
		var color := Color("cbf3f6") if floater.shield else Color("fff2c6")
		color.a = minf(1, float(floater.life) * 3)
		_text_center(("−%d" % int(floater.amount)), point, 19, color)


func _text_center(text: String, point: Vector2, font_size: int, color: Color) -> void:
	var width: float = ui_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	var position_value: Vector2 = point - Vector2(width * 0.5, 0)
	draw_string_outline(ui_font, position_value, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("284342"))
	draw_string(ui_font, position_value, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


func _plate() -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = Color("253e3d")
	result.set_corner_radius_all(2)
	return result
