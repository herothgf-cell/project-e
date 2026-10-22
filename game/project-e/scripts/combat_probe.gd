extends Node3D
## Local input and presentation for M0; no network or combat authority claims.

const SPAWN: Vector3 = Vector3(-8.0, 0.0, 3.0)
const GROUND: Plane = Plane(Vector3.UP, 0.0)
const FIELD_X: float = 13.0
const FIELD_Z: float = 9.0

@onready var _player = $Player
@onready var _camera: Camera3D = $Camera3D
@onready var _destination: MeshInstance3D = $Destination
@onready var _aim_path: MeshInstance3D = $AimPath
@onready var _status: Label = $HUD/Root/StatusPanel/Margin/VBox/Status
@onready var _energy: ProgressBar = $HUD/Root/StatusPanel/Margin/VBox/Energy
@onready var _hint: Label = $HUD/Root/HelpPanel/Margin/VBox/Hint
var _aiming: bool = false
var _hint_remaining: float = 0.0


func _ready() -> void:
	_camera.look_at(Vector3.ZERO, Vector3.UP)
	reset_probe()


func _process(delta: float) -> void:
	_energy.value = _player.motion.energy
	var cooldown: float = _player.motion.cooldown_remaining
	var ready_text: String = "READY" if cooldown <= 0.0 else "%.1fs" % cooldown
	_status.text = "ENERGY  %03d / 100     E  %s\n%s" % [roundi(_player.motion.energy), ready_text, _player.motion.phase.to_upper()]
	_destination.visible = _player.motion.phase == "walk"
	_aim_path.visible = _aiming or _player.motion.phase == "windup"
	if _aim_path.visible:
		var direction: Vector3 = Vector3(_player.motion.facing.x, 0.0, _player.motion.facing.y)
		if _aiming:
			var point: Variant = _ground_point(get_viewport().get_mouse_position())
			if point != null:
				var offset: Vector3 = point - _player.position
				if offset.length_squared() > 0.001:
					direction = offset.normalized()
		_aim_path.position = _player.position + direction * 2.1 + Vector3.UP * 0.04
		_aim_path.rotation.y = atan2(direction.x, direction.z)
	_hint_remaining = maxf(0.0, _hint_remaining - delta)
	if _hint_remaining <= 0.0:
		_hint.text = "Choose E direction with left click. Esc cancels." if _aiming else "Move around the wall. Try an E dash into it, then through open ground."


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("reset_probe"):
		reset_probe()
	elif event.is_action_pressed("cancel_aim"):
		_set_aiming(false)
	elif event.is_action_pressed("stop_move"):
		_set_aiming(false)
		_player.stop_moving()
	elif event.is_action_pressed("aim_dash"):
		if _player.motion.is_busy() or _player.motion.cooldown_remaining > 0.0 or _player.motion.energy < 20.0:
			_show_hint("E is not ready. Wait for the action, energy or cooldown.")
		else:
			_set_aiming(true)
	elif event.is_action_pressed("move_click"):
		_set_aiming(false)
		var point: Variant = _ground_point(event.position)
		if point != null and _player.request_move(point):
			_destination.position = point + Vector3.UP * 0.035
	elif event.is_action_pressed("confirm_aim") and _aiming:
		var point: Variant = _ground_point(event.position)
		if point != null and _player.request_dash(point):
			_set_aiming(false)
		else:
			_show_hint("Choose a direction on the floor away from Bas.")


func _ground_point(screen_position: Vector2) -> Variant:
	var hit: Variant = GROUND.intersects_ray(_camera.project_ray_origin(screen_position), _camera.project_ray_normal(screen_position))
	if hit == null:
		return null
	var point: Vector3 = hit
	# The probe floor has a fixed boundary; full walkability/pathfinding is M1 work.
	point.x = clampf(point.x, -FIELD_X, FIELD_X)
	point.z = clampf(point.z, -FIELD_Z, FIELD_Z)
	point.y = 0.0
	return point


func _set_aiming(value: bool) -> void:
	_aiming = value
	Input.set_default_cursor_shape(Input.CURSOR_CROSS if value else Input.CURSOR_ARROW)


func _show_hint(message: String) -> void:
	_hint.text = message
	_hint_remaining = 2.5


func reset_probe() -> void:
	_set_aiming(false)
	_player.reset_to(SPAWN)
	_destination.visible = false
	_aim_path.visible = false
	_hint_remaining = 0.0


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT and is_node_ready():
		_set_aiming(false)
		_player.stop_moving()
