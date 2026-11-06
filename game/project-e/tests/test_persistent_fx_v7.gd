extends SceneTree
## Persistent fantasy cues read real cast/item state and disappear with it.
const StateScript = preload("res://scripts/battle/battle_state.gd")
const ItemsScript = preload("res://scripts/battle/battle_consumables.gd")
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var view: Variant = load("res://scripts/presentation/effects_view.gd").new()
	var audio: Variant = load("res://scripts/presentation/fantasy_audio.gd").new()
	root.add_child(view)
	root.add_child(audio)
	await process_frame
	var cues: Array[String] = []
	audio.cue_played.connect(func(cue: String) -> void: cues.append(cue))
	var item_shapes: Array = []
	for item_id: String in ["I01", "I02"]:
		var state: Variant = _fixture("bas")
		var hero: Dictionary = state.units[state.controlled_id]
		hero.pos = Vector2(-56, 0)
		hero.credits = 100
		_check(state.command_buy_consumable(hero.id, item_id), item_id + " is bought through authority")
		_check(state.command_select_consumable(hero.id, item_id), item_id + " is selected through authority")
		hero.pos = Vector2.ZERO
		hero.hp -= 350
		hero.energy = 10
		audio.reset()
		cues.clear()
		audio.observe(state, true, false)
		_check(state.command_use_consumable(hero.id), item_id + " starts an actual effect")
		audio.observe(state, true, false)
		audio.observe(state, true, false)
		_check(cues == [ItemsScript.ITEMS[item_id].cue], item_id + " plays one matching activation cue")
		var snapshot: Dictionary = hero.duplicate(true)
		view.terrain_map = state.map
		view.redraw(state, {}, -1, null)
		var faces: PackedVector3Array = view.mesh.get_faces()
		_check(faces.size() > 3, item_id + " recovery produces visible geometry")
		item_shapes.append(faces)
		_check(hero == snapshot, item_id + " rendering leaves authority state intact")
		_check(_bounded_visible(state, faces, hero.pos, 1.1), item_id + " cue stays near its visible caster")
		view.redraw(state, {}, -1, null)
		_check(view.mesh.get_faces() == faces, item_id + " frozen battle time freezes recovery motion")
		state.step(ItemsScript.ITEMS[item_id].duration + 0.1)
		view.redraw(state, {}, -1, null)
		_check(view.mesh.get_faces().size() == 3, item_id + " completed effect leaves no stale particles")
	_check(item_shapes[0] != item_shapes[1], "Mana stars and healing leaves have different geometry")
	var state: Variant = _fixture("rio")
	var hero: Dictionary = state.units[state.controlled_id]
	_check(state.command_cast(hero.id, "Q", Vector2(4, 0)), "Actual comet cast is accepted")
	state.step(0.2)
	state.effects.clear()
	view.terrain_map = state.map
	view.redraw(state, {}, -1, null)
	_check(_max_height(view.mesh.get_faces()) > 0.72, "Flying comet has a raised star core")
	state.projectiles[0].pos = Vector2(38, 24)
	state._visibility_cache.clear()
	_check(not state.is_point_visible(0, state.projectiles[0].pos), "Comet fixture is beyond friendly sight")
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() > 3, "Friendly known comet trajectory remains readable")
	state.projectiles[0].team = 1
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() == 3, "Hidden hostile comet remains concealed")
	state.projectiles.clear()
	state.cancel_action(hero)
	_check(state.command_cast(hero.id, "W", Vector2(2, 0)), "Actual star anchor cast is accepted")
	state.step(0.3)
	state.effects.clear()
	view.redraw(state, {}, -1, null)
	_check(_max_height(view.mesh.get_faces()) > 0.12, "Persistent return anchor contains its star sigil")
	hero.return_mark.clear()
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() == 3, "Consumed star anchor clears its sigil")
	state = _fixture("nema")
	hero = state.units[state.controlled_id]
	state.spawn_pin(hero, Vector2(-1, 0))
	state.spawn_pin(hero, Vector2(1, 0))
	view.terrain_map = state.map
	view.redraw(state, {}, -1, null)
	_check(_max_height(view.mesh.get_faces()) > 0.12, "Living link contains raised leaves")
	for point: Vector3 in view.mesh.get_faces():
		_check(absf(point.z) <= 0.251, "Living link decorations fit its 0.5m protective strip")
	state.remove_pin(hero.pins[0])
	view.redraw(state, {}, -1, null)
	_check(view.mesh.get_faces().size() == 3, "Broken living link clears immediately")
	view.queue_free()
	audio.reset()
	audio.queue_free()
	await process_frame
	var deadline: int = Time.get_ticks_msec() + 1500
	while Time.get_ticks_msec() < deadline and ["arcane", "nature"].any(
			func(cue: String) -> bool: return ResourceLoader.has_cached("res://assets/audio/%s.wav" % cue)):
		await process_frame
	print("Persistent FX V7: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _fixture(key: String) -> Variant:
	var state: Variant = StateScript.new()
	state.reset(key, true)
	state.bots_enabled = false
	state._next_wave = INF
	state._next_income = INF
	state.units[state.controlled_id].pos = Vector2.ZERO
	return state

func _max_height(faces: PackedVector3Array) -> float:
	var highest: float = 0.0
	for point: Vector3 in faces:
		highest = maxf(highest, point.y)
	return highest

func _bounded_visible(state: Variant, faces: PackedVector3Array, origin: Vector2, radius: float) -> bool:
	for vertex: Vector3 in faces:
		var point := Vector2(vertex.x, -vertex.z)
		if point.distance_to(origin) > radius or not state.is_point_visible(0, point):
			return false
	return true

func _check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		push_error(message)
