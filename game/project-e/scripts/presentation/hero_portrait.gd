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
		if is_inside_tree() and not PORTRAITS.has(value):
			_build_model_portrait()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	texture = PORTRAITS.get(hero_key)
	if not PORTRAITS.has(hero_key):
		_build_model_portrait()

func _build_model_portrait() -> void:
	var viewport := SubViewport.new()
	viewport.name = "ModelPortrait"
	viewport.size = Vector2i(320, 256)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(viewport)
	var rig: Node3D = preload("res://scripts/presentation/hero_rig.gd").new()
	viewport.add_child(rig)
	rig.build(hero_key, Color("75d6d3"))
	rig.rotation.y = -0.16
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0, 1.65, -5.2)
	camera.look_at(Vector3(0, 1.45, 0), Vector3.UP)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 3.1
	camera.current = true
	texture = viewport.get_texture()
