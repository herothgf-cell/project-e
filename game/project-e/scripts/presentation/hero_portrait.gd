extends TextureRect
## Cropped from the illustrated selection cards at their native aspect ratio.
const PORTRAITS := {
	"bas": preload("res://assets/portraits/bas.webp"),
	"rio": preload("res://assets/portraits/rio.webp"),
	"nema": preload("res://assets/portraits/nema.webp"),
}

var hero_key := "bas":
	set(value):
		hero_key = value
		texture = PORTRAITS.get(value)

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture = PORTRAITS.get(hero_key)
