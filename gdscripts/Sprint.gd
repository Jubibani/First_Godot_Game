extends Button
@export var speed : float = 100
@export var joystick_right : VirtualJoystick
var move_vector := Vector2.ZERO
const MOVE_SPEED = 5.0
const RUN_SPEED = 9.0
const CROUCH_SPEED = 3.5

func _on_Sprint_pressed():
	if Input.is_action_pressed("run"):
		print("running")
		speed = RUN_SPEED
	else:
		print("walking")
		speed = MOVE_SPEED
		
