extends RefCounted
## Offline movement rules. Position/collision are owned by ProbePlayer.
## These are the C01 movement and E timing values from the design documents.
## Damage, hero contact, CC, prediction and command buffering are not implemented.

const MOVE_SPEED: float = 5.8
const DASH_SPEED: float = 14.0
const DASH_DISTANCE: float = 4.2
const DASH_WINDUP: float = 0.12
const DASH_RECOVERY: float = 0.16
const DASH_COST: float = 20.0
const DASH_COOLDOWN: float = 5.0
const MAX_ENERGY: float = 100.0
const ENERGY_REGEN: float = 8.0
const EPSILON: float = 0.000001

var energy: float = MAX_ENERGY
var cooldown_remaining: float = 0.0
var phase: String = "idle"
var facing: Vector2 = Vector2.RIGHT
var _move_goal: Vector2 = Vector2.ZERO
var _phase_remaining: float = 0.0
var _dash_remaining: float = 0.0


func is_busy() -> bool:
	return phase == "windup" or phase == "dash" or phase == "recovery"


func set_move_goal(point: Vector2) -> bool:
	if not point.is_finite() or is_busy():
		return false
	_move_goal = point
	phase = "walk"
	return true


func stop(position: Vector2) -> bool:
	if not position.is_finite() or is_busy():
		return false
	_move_goal = position
	phase = "idle"
	return true


func try_dash(position: Vector2, aim_point: Vector2) -> bool:
	if not position.is_finite() or not aim_point.is_finite():
		return false
	var direction: Vector2 = aim_point - position
	if not direction.is_finite() or direction.length_squared() < EPSILON:
		return false
	if is_busy() or cooldown_remaining > EPSILON or energy < DASH_COST:
		return false
	facing = direction.normalized()
	_move_goal = position
	energy -= DASH_COST
	cooldown_remaining = DASH_COOLDOWN
	phase = "windup"
	_phase_remaining = DASH_WINDUP
	_dash_remaining = DASH_DISTANCE
	return true


func step(delta: float, position: Vector2) -> Vector2:
	if not is_finite(delta) or delta <= 0.0 or not position.is_finite():
		return Vector2.ZERO
	energy = minf(MAX_ENERGY, energy + ENERGY_REGEN * delta)
	cooldown_remaining = maxf(0.0, cooldown_remaining - delta)
	var remaining: float = delta
	var displacement: Vector2 = Vector2.ZERO
	# At most windup -> dash -> recovery -> idle. Consume leftover frame time.
	for _transition: int in range(4):
		if remaining <= EPSILON:
			break
		match phase:
			"walk":
				var offset: Vector2 = _move_goal - position
				var distance: float = offset.length()
				if distance <= EPSILON:
					phase = "idle"
					break
				facing = offset / distance
				var travel: float = minf(distance, MOVE_SPEED * remaining)
				displacement = facing * travel
				if travel >= distance - EPSILON:
					phase = "idle"
				break
			"windup", "recovery":
				var elapsed: float = minf(remaining, _phase_remaining)
				_phase_remaining -= elapsed
				remaining -= elapsed
				if _phase_remaining <= EPSILON:
					phase = "dash" if phase == "windup" else "idle"
			"dash":
				var elapsed: float = minf(remaining, _dash_remaining / DASH_SPEED)
				var travel: float = minf(_dash_remaining, DASH_SPEED * elapsed)
				displacement += facing * travel
				_dash_remaining = maxf(0.0, _dash_remaining - travel)
				remaining -= elapsed
				if _dash_remaining <= EPSILON:
					phase = "recovery"
					_phase_remaining = DASH_RECOVERY
			_:
				break
	return displacement


func on_dash_blocked(position: Vector2) -> void:
	_move_goal = position
	_dash_remaining = 0.0
	if phase == "dash":
		phase = "recovery"
		_phase_remaining = DASH_RECOVERY


func reset(position: Vector2) -> void:
	energy = MAX_ENERGY
	cooldown_remaining = 0.0
	phase = "idle"
	facing = Vector2.RIGHT
	_move_goal = position
	_phase_remaining = 0.0
	_dash_remaining = 0.0
