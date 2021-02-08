extends Spatial

const MOUSE_SENSITIVITY = 0.002
const RUN_SPEED = 2
const JUMP_VELOCITY = 0.24
const GRAVITY = 34

onready var kinematic_body := $KinematicBody as KinematicBody
onready var pivot := $Smoothing/Pivot as Spatial
onready var raycast := $KinematicBody/RayCast as RayCast

var velocity := Vector3()


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _process(delta: float) -> void:
	# Apply Doom-style friction.
	velocity.x *= 1 - 10 * delta
	velocity.y *= 1 - 0.5 * delta
	velocity.z *= 1 - 10 * delta

	# Apply movement keys.
	velocity += (
			pivot.transform.basis.x * (Input.get_action_strength("move_right") - Input.get_action_strength("move_left")) * RUN_SPEED +
			pivot.transform.basis.z * (Input.get_action_strength("move_backward") - Input.get_action_strength("move_forward")) * RUN_SPEED
	)

	# Apply jumping.
	if Input.is_action_just_pressed("jump") and raycast.is_colliding():
		# Movement is is applied only once.
		# Compensate for `move_and_slide()`'s automatic delta calculation.
		velocity.y += JUMP_VELOCITY / delta

	# Apply gravity.
	if not raycast.is_colliding():
		velocity.y -= GRAVITY * delta

	# warning-ignore:return_value_discarded
	kinematic_body.move_and_slide(velocity)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			pivot.rotate(Vector3.UP, -event.relative.x * MOUSE_SENSITIVITY)

	if event.is_action_pressed("toggle_mouse_capture"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
