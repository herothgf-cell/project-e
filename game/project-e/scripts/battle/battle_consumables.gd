extends RefCounted
## Small item authority shared by human commands and bots.

const ITEMS: Dictionary = {
	"I01": {"name": "에너지 병", "cost": 40, "resource": "energy", "amount": 40.0, "duration": 2.0},
	"I02": {"name": "수리 패치", "cost": 50, "resource": "hp", "amount": 200.0, "duration": 4.0},
}
const CAPACITY: int = 2
const USE_COOLDOWN: float = 12.0


func is_in_home_base(state: Variant, actor_id: int) -> bool:
	var actor: Dictionary = _hero(state, actor_id)
	if actor.is_empty() or actor.get("team", -1) not in [0, 1] or not actor.get("pos") is Vector2:
		return false
	var position: Vector2 = actor.pos
	if not position.is_finite():
		return false
	var base: Rect2 = Rect2(-59, -6, 6, 12) if actor.team == 0 else Rect2(53, -6, 6, 12)
	return base.has_point(position)


func purchase_error(state: Variant, actor_id: int, item_id: String) -> String:
	var reason: String = _actor_error(state, actor_id)
	if not reason.is_empty():
		return reason
	if not ITEMS.has(item_id):
		return "Unknown consumable"
	var actor: Dictionary = state.units[actor_id]
	if not _valid_inventory(actor) or not _finite_number(actor.get("credits")):
		return "Invalid consumable state"
	if not is_in_home_base(state, actor_id):
		return "Return to home base"
	if actor.consumables.I01 + actor.consumables.I02 >= CAPACITY:
		return "Consumable inventory full"
	if actor.credits < ITEMS[item_id].cost:
		return "Not enough credits"
	return ""


func use_error(state: Variant, actor_id: int, item_id: String = "") -> String:
	var reason: String = _actor_error(state, actor_id)
	if not reason.is_empty():
		return reason
	var actor: Dictionary = state.units[actor_id]
	if not _valid_inventory(actor) or not actor.get("consumable_selected") is String or not _finite_number(actor.get("consumable_cooldown")) or not actor.get("consumable_effect") is Dictionary:
		return "Invalid consumable state"
	if actor.consumable_cooldown < 0.0:
		return "Invalid consumable state"
	if item_id.is_empty():
		item_id = actor.consumable_selected
	if not ITEMS.has(item_id):
		return "Unknown consumable"
	if actor.consumables[item_id] <= 0:
		return "No selected consumable"
	if actor.consumable_cooldown > 0.0:
		return "Consumable cooldown"
	var resource: String = ITEMS[item_id].resource
	if not _finite_number(actor.get(resource)) or not _finite_number(actor.get("max_" + resource)):
		return "Invalid consumable state"
	if actor[resource] >= actor["max_" + resource]:
		return "Health already full" if resource == "hp" else "Energy already full"
	return ""


func buy(state: Variant, actor_id: int, item_id: String) -> bool:
	var reason: String = purchase_error(state, actor_id, item_id)
	if not reason.is_empty():
		return state._reject(actor_id, reason)
	var actor: Dictionary = state.units[actor_id]
	actor.credits -= ITEMS[item_id].cost
	actor.consumables[item_id] += 1
	_event(state, actor, "consumable_purchase", item_id, "Purchased " + ITEMS[item_id].name)
	return true


func select(state: Variant, actor_id: int, item_id: String) -> bool:
	var actor: Dictionary = _hero(state, actor_id)
	if actor.is_empty():
		return state._reject(actor_id, "Invalid hero")
	if not ITEMS.has(item_id):
		return state._reject(actor_id, "Unknown consumable")
	if not _valid_inventory(actor):
		return state._reject(actor_id, "Invalid consumable state")
	actor.consumable_selected = item_id
	return true


func use_selected(state: Variant, actor_id: int) -> bool:
	var reason: String = use_error(state, actor_id)
	if not reason.is_empty():
		return state._reject(actor_id, reason)
	var actor: Dictionary = state.units[actor_id]
	var item_id: String = actor.consumable_selected
	var item: Dictionary = ITEMS[item_id]
	actor.consumables[item_id] -= 1
	actor.consumable_cooldown = USE_COOLDOWN
	actor.consumable_effect = {"item_id": item_id, "remaining": item.duration, "rate": item.amount / item.duration}
	_event(state, actor, "consumable_use", item_id, "Used " + item.name)
	return true


func tick_cooldown(actor: Dictionary, delta: float) -> void:
	actor.consumable_cooldown = maxf(0.0, actor.consumable_cooldown - delta)
	# Repeated 1/30 subtraction must unlock on the 360th tick.
	if actor.consumable_cooldown <= 0.00000001:
		actor.consumable_cooldown = 0.0


func tick_effect(state: Variant, actor: Dictionary, delta: float) -> void:
	var effect: Dictionary = actor.consumable_effect
	if not actor.alive or effect.is_empty():
		return
	var resource: String = ITEMS[effect.item_id].resource
	# Pay the final partial interval before reducing remaining time.
	var elapsed: float = minf(delta, effect.remaining)
	actor[resource] = minf(actor["max_" + resource], actor[resource] + effect.rate * elapsed)
	effect.remaining = maxf(0.0, effect.remaining - delta)
	if effect.remaining <= 0.00000001:
		end_effect(state, actor, "completed")


func interrupt_patch(state: Variant, target: Dictionary, owner: Dictionary) -> void:
	if target.kind != "hero" or owner.kind != "hero" or owner.team == target.team:
		return
	if target.consumable_effect.get("item_id", "") == "I02":
		end_effect(state, target, "interrupted")


func end_effect(state: Variant, actor: Dictionary, reason: String) -> void:
	if actor.consumable_effect.is_empty():
		return
	var item_id: String = actor.consumable_effect.item_id
	actor.consumable_effect = {}
	_event(state, actor, "consumable_end", item_id, ITEMS[item_id].name + " " + reason, {"reason": reason})


func _event(state: Variant, actor: Dictionary, type: String, item_id: String, message: String, extra: Dictionary = {}) -> void:
	if actor.id != state.controlled_id:
		return
	extra.merge({"target_id": actor.id, "item_id": item_id})
	state.log_event(type, message, extra)


func _hero(state: Variant, actor_id: int) -> Dictionary:
	var candidate: Variant = state.units.get(actor_id)
	if not candidate is Dictionary or candidate.get("kind", "") != "hero" or not candidate.get("id") is int or candidate.id != actor_id:
		return {}
	return candidate


func _actor_error(state: Variant, actor_id: int) -> String:
	if state.winner != -1:
		return "Match ended"
	var actor: Dictionary = _hero(state, actor_id)
	if actor.is_empty():
		return "Invalid hero"
	if not actor.get("alive") is bool:
		return "Invalid consumable state"
	if not actor.alive:
		return "Hero defeated"
	return ""


func _finite_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func _valid_inventory(actor: Dictionary) -> bool:
	var inventory: Variant = actor.get("consumables")
	if not inventory is Dictionary:
		return false
	for item_id: String in ITEMS:
		if not inventory.get(item_id) is int or inventory[item_id] < 0:
			return false
	return true
