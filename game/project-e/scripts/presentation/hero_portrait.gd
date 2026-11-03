extends Control
## V3 original vector hero cards; portraits are directly used in hero selection.
const PORTRAITS: Dictionary = {
	"bas": preload("res://assets/portraits/bas.svg"),
	"rio": preload("res://assets/portraits/rio.svg"),
	"nema": preload("res://assets/portraits/nema.svg"),
}
var hero_key: String = "bas"
var accent := Color("73d4e6")

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	if not PORTRAITS.has(hero_key):
		return
	var image: Texture2D = PORTRAITS[hero_key]
	if image == null:
		return
	var original := Vector2(image.get_width(), image.get_height())
	var zoom: float = minf(size.x / original.x, size.y / original.y)
	var dest: Vector2 = original * zoom
	draw_texture_rect(image, Rect2((size - dest) * 0.5, dest), false, Color.WHITE)
