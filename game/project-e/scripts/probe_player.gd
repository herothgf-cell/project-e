extends CharacterBody3D
## Physical adapter for the offline rules. All motion stays on the X/Z plane.

const BasMotionScript: Script = preload("res://scripts/bas_motion.gd")
var motion = BasMotionScript.new()
@onready var _visual: Node3D = $Visual


func _ready() -> void:
	motion.reset(_plane_position())


func _physics_process(delta: float) -> void:
	var prior_phase: String = motion.phase
	var displacement: Vector2 = motion.step(delta, _plane_position())
	if displacement.length_squared() > 0.0:
		var collision: KinematicCollision3D = move_and_collide(Vector3(displacement.x, 0.0, displacement.y))
		if collision != null:
			if prior_phase == "windup" or prior_phase == "dash":
				motion.on_dash_blocked(_plane_position())
			else:
				motion.stop(_plane_position())
	_visual.rotation.y = atan2(motion.facing.x, motion.facing.y)


func request_move(point: Vector3) -> bool:
	if not point.is_finite():
		return false
	return motion.set_move_goal(Vector2(point.x, point.z))


func request_dash(point: Vector3) -> bool:
	if not point.is_finite():
		return false
	return motion.try_dash(_plane_position(), Vector2(point.x, point.z))


func stop_moving() -> void:
	motion.stop(_plane_position())


func reset_to(point: Vector3) -> void:
	position = point
	velocity = Vector3.ZERO
	motion.reset(_plane_position())


func _plane_position() -> Vector2:
	return Vector2(position.x, position.z)
