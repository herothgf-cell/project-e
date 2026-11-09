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
		if is_inside_tree():
			_refresh_portrait()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_refresh_portrait()

func _refresh_portrait() -> void:
	var previous := get_node_or_null("ModelPortrait")
	if previous != null:
		remove_child(previous)
		previous.queue_free()
	material = null
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
	rig.rotation.y = -0.12
	rig.pose({"alive":true, "phase":"idle", "cast":{}, "last_damage":-100.0, "stun_left":0.0}, 0.4)
	var camera := Camera3D.new()
	viewport.add_child(camera)
	camera.position = Vector3(0, 2.20, -5.2)
	camera.look_at(Vector3(0, 2.13, 0), Vector3.UP)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 2.1
	camera.current = true
	texture = viewport.get_texture()

	var backdrop := Shader.new()
	backdrop.code = """
shader_type canvas_item;
uniform vec4 accent : source_color = vec4(0.5, 0.8, 0.8, 1.0);
void fragment() {
	vec4 portrait = texture(TEXTURE, UV);
	vec2 center = (UV - vec2(0.5, 0.40)) * vec2(1.0, 0.8);
	float radius = length(center);
	float halo = 1.0 - smoothstep(0.08, 0.65, radius);
	vec3 background = mix(vec3(0.035, 0.085, 0.12), accent.rgb * 0.34, halo);
	float ring = 1.0 - smoothstep(0.002, 0.008, abs(radius - 0.34));
	float inner_ring = 1.0 - smoothstep(0.001, 0.004, abs(radius - 0.31));
	float rays = pow(max(0.0, cos(atan(center.y, center.x) * 16.0)), 24.0);
	background += accent.rgb * (ring * 0.24 + inner_ring * 0.10 + rays * halo * 0.06);
	COLOR = vec4(mix(background, portrait.rgb, portrait.a), 1.0);
}
"""
	var portrait_material := ShaderMaterial.new()
	portrait_material.shader = backdrop
	portrait_material.set_shader_parameter("accent", Color(preload("res://scripts/battle/hero_roster.gd").ACCENTS[hero_key]))
	material = portrait_material
