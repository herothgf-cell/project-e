extends Control
## Small code-native portrait, matching the in-world equipment silhouette.

var hero_key: String = "bas"
var accent := Color("43b9aa")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.53)
	var scale_value: float = minf(size.x / 180.0, size.y / 142.0)
	draw_set_transform(center, 0, Vector2.ONE * scale_value)
	draw_circle(Vector2(0, -4), 59, Color("e6e1c9"))
	draw_arc(Vector2(0, -4), 62, 0.15, 2.85, 40, accent, 2, true)
	var cream := Color("f8efd5")
	var copper := Color("ae7550")
	var dark := Color("304b4b")
	if hero_key == "nema":
		draw_style_box(_box(Color("8e674b"), 7), Rect2(-30, -26, 60, 67))
		for side: float in [-1.0, 1.0]:
			draw_line(Vector2(side * 24, -50), Vector2(side * 24, 24), cream, 6, true)
			draw_circle(Vector2(side * 24, -50), 7, accent)
	if hero_key == "rio":
		draw_colored_polygon(PackedVector2Array([Vector2(-7, -17), Vector2(-55, 5), Vector2(-39, 30), Vector2(1, 0)]), accent)
		draw_colored_polygon(PackedVector2Array([Vector2(0, -8), Vector2(54, 28), Vector2(32, 42), Vector2(-4, 8)]), Color("d7a578"))
	var width: float = 35 if hero_key == "rio" else 51
	draw_style_box(_box(cream, 9), Rect2(-width * 0.5, -20, width, 58))
	draw_rect(Rect2(-width * 0.5, 23, width, 9), copper)
	draw_style_box(_box(accent, 3), Rect2(-width * 0.36, -9, width * 0.72, 15))
	for side: float in [-1.0, 1.0]:
		draw_style_box(_box(dark, 4), Rect2(side * 14 - 8, 33, 16, 24))
		if hero_key == "bas":
			draw_style_box(_box(copper, 6), Rect2(side * 42 - 17, -18, 34, 48))
			draw_style_box(_box(cream, 8), Rect2(side * 47 - 20, -5, 40, 41))
			draw_rect(Rect2(side * 47 - 12, 4, 24, 7), accent)
		elif hero_key == "rio":
			draw_line(Vector2(side * 24, -9), Vector2(side * 37, 22), copper, 8, true)
			draw_arc(Vector2(side * 49, 13), 17, 0, TAU, 30, copper, 5, true)
			draw_arc(Vector2(side * 49, 13), 10, 0, TAU, 30, cream, 2, true)
		else:
			draw_style_box(_box(cream, 5), Rect2(side * 33 - 8, -12, 16, 40))
	draw_circle(Vector2(0, -32), 18, Color("d4a77a"))
	draw_style_box(_box(accent, 6), Rect2(-21, -53, 42, 17))
	draw_style_box(_box(dark, 3), Rect2(-16, -35, 32, 9))
	draw_rect(Rect2(-11, -33, 7, 3), Color("dff7dc"))
	draw_rect(Rect2(4, -33, 7, 3), Color("dff7dc"))
	draw_set_transform(Vector2.ZERO)


func _box(color: Color, radius: int) -> StyleBoxFlat:
	var result := StyleBoxFlat.new()
	result.bg_color = color
	result.set_corner_radius_all(radius)
	return result
