extends Node3D
## Original game meshes, not concept-image billboards. Visual joints only;
## pose() reads authority state and never writes collision or combat data.
const MODELS := {
	"bas": preload("res://assets/heroes/bas.glb"),
	"rio": preload("res://assets/heroes/rio.glb"),
	"nema": preload("res://assets/heroes/nema.glb"),
	"orin": preload("res://assets/heroes/orin.glb"),
	"tere": preload("res://assets/heroes/tere.glb"),
	"mua": preload("res://assets/heroes/mua.glb"),
	"sera": preload("res://assets/heroes/sera.glb"),
	"lume": preload("res://assets/heroes/lume.glb"),
}
const PAINT_SHADER := preload("res://assets/heroes/painted.gdshader")
static var _outlined: ShaderMaterial
static var _paint: ShaderMaterial
static var _illustration_materials: Dictionary = {}
var hero_key: String = "bas"
var _parts: Dictionary = {}
var _swing_panel: Node3D
var _knees: Array[Node3D] = []
var _elbows: Array[Node3D] = []
var _player: AnimationPlayer
var _rest: Dictionary = {}
var _previous_alive: bool = true
var _death_at: float = -100.0
var _respawn_at: float = -100.0
var current_clip: String = "idle"

func build(key: String, team_color: Color) -> void:
	hero_key = key
	if _paint == null:
		_paint = ShaderMaterial.new()
		_paint.shader = PAINT_SHADER
		_outlined = _paint.duplicate() as ShaderMaterial
		_outlined.set_shader_parameter("ink_edges", true)
	var art: Node3D = MODELS[key].instantiate()
	for mesh: MeshInstance3D in art.find_children("*", "MeshInstance3D", true, false):
		mesh.owner = null
		var source := mesh.mesh.surface_get_material(0) as StandardMaterial3D
		if source != null and source.albedo_texture != null:
			var texture := source.albedo_texture
			if not _illustration_materials.has(texture):
				var illustrated := _paint.duplicate() as ShaderMaterial
				illustrated.set_shader_parameter("textured", true)
				illustrated.set_shader_parameter("pigment", texture)
				_illustration_materials[texture] = illustrated
			mesh.material_override = _illustration_materials[texture]
		else:
			mesh.material_override = _outlined if mesh.name in [&"HairDetail", &"WeaponDetail", &"LeftWeapon", &"LeftArm", &"RightArm"] else _paint
	var crest := StandardMaterial3D.new()
	crest.albedo_color = team_color
	crest.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	art.get_node("Torso/TeamMark").material_override = crest
	for joint: Node3D in art.get_children():
		art.remove_child(joint)
		add_child(joint)
		_parts[str(joint.name)] = joint
		_rest[str(joint.name)] = joint.position
	art.free()
	_swing_panel = get_node("Torso/SwingPanel")
	_knees.assign([get_node("LeftLeg/Shin"), get_node("RightLeg/RightShin")])
	_elbows.assign([get_node("LeftArm/LeftWeapon"), get_node("RightArm/WeaponDetail")])
	_build_animations()

func _secondary_motion(unit: Dictionary, time: float, clip: String, sample: float) -> void:
	# Nonauthoritative body bob: no movement orders or collision changes.
	match clip:
		"walk":
			var tempo: float = 10.2 if hero_key == "rio" else (8.8 if hero_key == "nema" else 9.0)
			var stride: float = time * tempo
			position.y = 0.095 * absf(sin(stride))
			rotation.z += 0.036 * sin(stride)
			_parts["Head"].rotation.x -= 0.036 * sin(stride)
		"idle":
			position.y = 0.013 * sin(time * 2.7)
			_parts["Head"].rotation.z += 0.016 * sin(time * 1.8)
			_parts["Torso"].rotation.x += 0.016 * sin(time * 2.4)
		"basic":
			var strike: float = sin(PI * clampf(sample, 0.0, 1.0))
			position.y = 0.035 * strike
			position.z = -0.06 * strike
			_parts["Head"].rotation.x -= 0.045 * strike
		"Q", "W", "E", "R":
			var power: float = 0.075 if clip == "R" else 0.045
			position.y = power * sin(PI * clampf(sample, 0.0, 1.0))
			rotation.z += (0.05 if hero_key == "bas" else -0.035) * sin(PI * sample)
		"hit":
			position.y = -0.09 * sin(PI * clampf(sample / 0.26, 0.0, 1.0))
		"respawn":
			position.y = 0.07 * sin(PI * clampf(sample / 0.65, 0.0, 1.0))
		"death":
			position.y = -0.05 * clampf(sample / 0.85, 0.0, 1.0)
	# A frozen or dead visual state does not drift over wall-clock time.
	if not bool(unit.alive) and clip != "death":
		position = Vector3.ZERO


func _build_animations() -> void:
	_player = AnimationPlayer.new()
	_player.name = "AnimationPlayer"
	_player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	add_child(_player)
	var library := AnimationLibrary.new()
	_player.add_animation_library("", library)
	var amplitude: float = 0.48 if hero_key == "bas" else 0.65
	_add_clip(library, "idle", 2.0, {"Torso": Vector3(0.025, 0, 0), "Head": Vector3(0, 0.025, 0), "LeftArm": Vector3(0.03, 0, 0), "RightArm": Vector3(-0.03, 0, 0)}, true)
	_add_clip(library, "walk", 0.58 if hero_key == "rio" else 0.72, {"LeftLeg": Vector3(amplitude, 0, 0), "RightLeg": Vector3(-amplitude, 0, 0), "LeftArm": Vector3(-amplitude * 0.55, 0, 0), "RightArm": Vector3(amplitude * 0.55, 0, 0), "Torso": Vector3(-0.08, 0.05, 0)}, true)
	var basic := {"RightArm": Vector3(-1.55, 0, -0.15), "LeftArm": Vector3(-0.25, 0, 0.15), "Torso": Vector3(0.10, 0.32, 0), "Head": Vector3(0, -0.12, 0)}
	if hero_key == "rio":
		basic = {"RightArm": Vector3(-1.24, -0.26, 0.84), "LeftArm": Vector3(0.24, 0, -0.49), "Torso": Vector3(0.09, -0.41, 0.11), "Head": Vector3(0, 0.18, 0)}
	elif hero_key == "nema":
		basic = {"RightArm": Vector3(-1.33, 0.19, -0.14), "LeftArm": Vector3(-0.62, -0.22, 0.26), "Torso": Vector3(0.17, 0.21, -0.04), "Head": Vector3(-0.09, -0.14, 0)}
	_add_clip(library, "basic", 1.0, basic)
	var poses: Dictionary
	if hero_key == "bas":
		poses = {"Q": [Vector3(-1.55, 0, -0.55),Vector3(-1.9, 0, 0.3),Vector3(0.24, 0.35, 0)], "W": [Vector3(-1.30, 0, 0.62),Vector3(-1.30, 0, -0.62),Vector3(0.10, 0, 0)], "E": [Vector3(-0.4, 0, -0.2),Vector3(-1.85, 0, 0),Vector3(-0.35, -0.15, 0)], "R": [Vector3(-2.85, 0, -0.20),Vector3(-2.85, 0, 0.20),Vector3(-0.20, 0, 0)]}
	elif hero_key == "rio":
		poses = {"Q": [Vector3(-0.3, 0, -0.55),Vector3(-1.4, 0, 0.8),Vector3(0, -0.60, 0.15)], "W": [Vector3(-1.8, 0, -0.2),Vector3(-0.6, 0, 0.25),Vector3(0.22, 0.22, 0)], "E": [Vector3(0.5, 0, -0.65),Vector3(0.5, 0, 0.65),Vector3(-0.48, 0, 0.25)], "R": [Vector3(-1.4, 0, -1.2),Vector3(-1.4, 0, 1.2),Vector3(-0.08, 0.60, 0)]}
	elif hero_key == "orin":
		poses = {
			"Q": [Vector3(-0.2, 0.12, -0.35), Vector3(-1.6, -0.2, 0.45), Vector3(0.12, 0.1, 0.05)],
			"W": [Vector3(-1.3, 0.12, -0.35), Vector3(-1.8, -0.2, 0.45), Vector3(0.12, -0.2, 0.05)],
			"E": [Vector3(0.6, 0.12, -0.35), Vector3(0.4, -0.2, 0.45), Vector3(0.12, -0.4, 0.05)],
			"R": [Vector3(-2.0, 0.12, -0.35), Vector3(-2.3, -0.2, 0.45), Vector3(0.12, 0.3, 0.05)],
		}
	elif hero_key == "tere":
		poses = {
			"Q": [Vector3(-1.7, 0.12, -0.35), Vector3(-0.8, -0.2, 0.45), Vector3(0.12, 0.2, 0.05)],
			"W": [Vector3(-1.5, 0.12, -0.35), Vector3(-1.2, -0.2, 0.45), Vector3(0.12, -0.1, 0.05)],
			"E": [Vector3(-1.3, 0.12, -0.35), Vector3(0.7, -0.2, 0.45), Vector3(0.12, -0.35, 0.05)],
			"R": [Vector3(-2.4, 0.12, -0.35), Vector3(-0.9, -0.2, 0.45), Vector3(0.12, 0.1, 0.05)],
		}
	elif hero_key == "mua":
		poses = {
			"Q": [Vector3(-0.5, 0.12, -0.35), Vector3(-1.8, -0.2, 0.45), Vector3(0.12, 0.4, 0.05)],
			"W": [Vector3(-1.5, 0.12, -0.35), Vector3(-0.6, -0.2, 0.45), Vector3(0.12, -0.4, 0.05)],
			"E": [Vector3(-1.7, 0.12, -0.35), Vector3(-1.7, -0.2, 0.45), Vector3(0.12, 0.0, 0.05)],
			"R": [Vector3(-2.7, 0.12, -0.35), Vector3(-2.0, -0.2, 0.45), Vector3(0.12, 0.25, 0.05)],
		}
	elif hero_key == "sera":
		poses = {
			"Q": [Vector3(-1.3, 0.12, -0.35), Vector3(-1.9, -0.2, 0.45), Vector3(0.12, 0.6, 0.05)],
			"W": [Vector3(-2.1, 0.12, -0.35), Vector3(-0.3, -0.2, 0.45), Vector3(0.12, -0.6, 0.05)],
			"E": [Vector3(0.5, 0.12, -0.35), Vector3(-1.0, -0.2, 0.45), Vector3(0.12, -0.5, 0.05)],
			"R": [Vector3(-2.4, 0.12, -0.35), Vector3(-2.8, -0.2, 0.45), Vector3(0.12, 0.7, 0.05)],
		}
	elif hero_key == "lume":
		poses = {
			"Q": [Vector3(-1.4, 0.12, -0.35), Vector3(-0.6, -0.2, 0.45), Vector3(0.12, -0.3, 0.05)],
			"W": [Vector3(-0.4, 0.12, -0.35), Vector3(-1.9, -0.2, 0.45), Vector3(0.12, 0.3, 0.05)],
			"E": [Vector3(-1.3, 0.12, -0.35), Vector3(-1.0, -0.2, 0.45), Vector3(0.12, -0.1, 0.05)],
			"R": [Vector3(-2.6, 0.12, -0.35), Vector3(-0.5, -0.2, 0.45), Vector3(0.12, 0.2, 0.05)],
		}
	else:
		poses = {"Q": [Vector3(-0.4, 0, -0.25),Vector3(-1.9, 0, 0.15),Vector3(0.25, -0.20, 0)], "W": [Vector3(-1.5, 0, -0.75),Vector3(-1.5, 0, 0.75),Vector3(0.12, 0, 0)], "E": [Vector3(-1.3, 0, 0.25),Vector3(-1.0, 0, -0.50),Vector3(-0.10, 0.25, 0)], "R": [Vector3(-2.45, 0, -0.8),Vector3(-2.45, 0, 0.8),Vector3(-0.22, 0, 0)]}
	for slot: String in poses:
		_add_clip(library, slot, 1.0, {"LeftArm": poses[slot][0], "RightArm": poses[slot][1], "Torso": poses[slot][2], "Head": Vector3(-0.08, 0, 0)})
	_add_clip(library, "hit", 0.26, {"LeftArm": Vector3(0.30, 0, -0.15), "RightArm": Vector3(0.30, 0, 0.15), "Torso": Vector3(-0.3, 0, 0.16), "Head": Vector3(-0.25, 0, 0)})
	_add_clip(library, "death", 0.85, {"LeftArm": Vector3(0.30, 0, -0.50), "RightArm": Vector3(0.30, 0, 0.50), "Torso": Vector3(0.6, 0, 0.2), "Head": Vector3(0.3, 0, 0.15)})
	var death: Animation = library.get_animation("death")
	var root_track: int = death.add_track(Animation.TYPE_VALUE)
	death.track_set_path(root_track, NodePath(".:rotation"))
	death.track_insert_key(root_track, 0, Vector3.ZERO)
	death.track_insert_key(root_track, 0.85, Vector3(0, 0, -1.48))
	_add_clip(library, "respawn", 0.65, {"LeftArm": Vector3(-0.6, 0, -0.3), "RightArm": Vector3(-0.6, 0, 0.3), "Torso": Vector3(0.24, 0, 0), "Head": Vector3(0.22, 0, 0)})

func _add_clip(library: AnimationLibrary, title: String, length: float, joints: Dictionary, loop: bool = false) -> void:
	var anim := Animation.new()
	anim.length = length
	anim.loop_mode = Animation.LOOP_LINEAR if loop else Animation.LOOP_NONE
	for part: String in joints:
		var track: int = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track, NodePath(part + ":rotation"))
		var peak: Vector3 = joints[part]
		if part.ends_with("Arm") and title != "walk":
			peak.x = -peak.x
		anim.track_insert_key(track, 0.0, -peak * 0.6 if title == "walk" else Vector3.ZERO)
		if title in ["basic", "Q", "W", "E", "R"]:
			# Anticipate on the wind-up, land on the authority's impact, then settle.
			anim.track_insert_key(track, length * 0.24, -peak * 0.18)
			anim.track_insert_key(track, length * (0.68 if title == "basic" else 0.60), peak)
			anim.track_insert_key(track, length * 0.80, peak * 0.82)
		else:
			anim.track_insert_key(track, length * 0.38, peak)
			anim.track_insert_key(track, length * 0.68, -peak * 0.6 if title == "walk" else peak * 0.82)
		anim.track_insert_key(track, length, -peak * 0.6 if title == "walk" else Vector3.ZERO)
	library.add_animation(title, anim)

func pose(unit: Dictionary, time: float) -> void:
	if _player == null: return
	if bool(unit.alive) != _previous_alive:
		if unit.alive: _respawn_at = time
		else: _death_at = time
		_previous_alive = bool(unit.alive)
	rotation = Vector3.ZERO
	position = Vector3.ZERO
	for part: String in _parts:
		_parts[part].rotation = Vector3.ZERO
		_parts[part].position = _rest[part]
	var clip: String = "idle"
	var sample: float = fposmod(time, 2.0)
	if not unit.alive:
		clip = "death"
		sample = clampf(time - _death_at, 0, 0.849)
	elif time - _respawn_at < 0.65:
		clip = "respawn"
		sample = maxf(0.0, time - _respawn_at)
	elif str(unit.phase) in ["windup", "recovery", "dash"] and not unit.cast.is_empty():
		clip = str(unit.cast.get("slot", "idle"))
		if unit.phase == "windup":
			sample = clampf(1.0 - float(unit.phase_left) / maxf(0.001, float(unit.cast.get("windup", 0.2))), 0, 1) * 0.60
		elif unit.phase == "recovery":
			sample = 0.60 + clampf(1.0 - float(unit.phase_left) / maxf(0.001, float(unit.cast.get("recovery", 0.2))), 0, 1) * 0.39
		else: sample = 0.55
	elif str(unit.phase) == "basic":
		clip = "basic"
		sample = clampf(1.0 - float(unit.phase_left) / maxf(0.01, float(unit.attack_windup)), 0.0, 1.0) * 0.7
	elif time - float(unit.last_damage) < 0.26:
		clip = "hit"
		sample = maxf(0.0, time - float(unit.last_damage))
	elif str(unit.phase) == "walk":
		clip = "walk"
		sample = fposmod(time, _player.get_animation(clip).length)
	current_clip = clip if _player.has_animation(clip) else "idle"
	_player.play(current_clip)
	_player.seek(sample, true)
	_secondary_motion(unit, time, current_clip, sample)
	if float(unit.stun_left) > 0:
		_parts.Head.rotation.z += 0.23
	if _parts.has("Cloth"):
		_parts.Cloth.rotation.x = 0.12 + sin(time * 5) * (0.16 if unit.phase in ["walk", "dash"] else 0.04)
	_articulate(current_clip, sample)
	var flutter := 0.11 if current_clip == "walk" else 0.034
	var cloth_time := sample if current_clip == "death" else time
	_swing_panel.rotation = Vector3(-0.07 - flutter * absf(sin(cloth_time * 5.5)), 0.035 * sin(cloth_time * 3.1), -rotation.z * 0.7)
	if current_clip in ["Q", "W", "E", "R", "basic"]:
		_swing_panel.rotation.y += 0.17 * sin(PI * sample)


func _articulate(clip: String, sample: float) -> void:
	# Knees and hinged weapon-hands add a planted stride and class-specific guards.
	var stride := TAU * sample / _player.get_animation("walk").length
	var guard := 0.30
	if clip in ["idle", "walk"]:
		var rest_weight := 1.0 if clip == "idle" else 0.48
		match hero_key:
			"bas":
				_parts.RightArm.rotation += Vector3(0.34, -0.21, 0.29) * rest_weight
				_parts.LeftArm.rotation += Vector3(0.26, 0.16, -0.14) * rest_weight
				_parts.RightLeg.rotation.z += 0.088 * rest_weight
				_parts.Head.rotation.y -= 0.09 * rest_weight
				guard = 0.54
			"rio":
				_parts.RightArm.rotation += Vector3(0.21, 0.19, 0.26) * rest_weight
				_parts.LeftArm.rotation += Vector3(-0.05, 0.11, -0.34) * rest_weight
				_parts.Head.rotation.z += 0.072 * rest_weight
				_parts.RightLeg.rotation.x += 0.18 * rest_weight
			"nema":
				_parts.RightArm.rotation += Vector3(0.15, -0.05, 0.20) * rest_weight
				_parts.LeftArm.rotation += Vector3(0.34, 0.10, -0.09) * rest_weight
				_parts.Head.rotation.y += 0.115 * rest_weight
				_parts.LeftLeg.rotation.x -= 0.10 * rest_weight
	for i: int in range(2):
		var sign_value := -1.0 if i == 0 else 1.0
		var wave := sin(stride + float(i) * PI) if clip == "walk" else 0.0
		_knees[i].rotation.x = -0.08 - 0.49 * maxf(0.0, wave)
		_elbows[i].rotation.x = guard + maxf(0.0, -wave) * 0.17
		_elbows[i].rotation.z = sign_value * (0.19 if hero_key == "rio" else 0.09)
		if clip in ["basic", "Q", "W", "E", "R"]:
			var tension := sin(PI * clampf(sample / 0.6, 0.0, 1.0))
			_elbows[i].rotation.x += tension * (0.78 if hero_key == "bas" else 0.45)
			_knees[i].rotation.x -= 0.26 * tension
	# Keep both shoulders and the neck attached when the chest twists and lunges.
	var torso: Node3D = _parts["Torso"]
	for link: String in ["Head", "LeftArm", "RightArm", "Cloth"]:
		var joint: Node3D = _parts[link]
		joint.position = torso.position + torso.basis * (Vector3(_rest[link]) - torso.position)
		joint.basis = torso.basis * joint.basis
