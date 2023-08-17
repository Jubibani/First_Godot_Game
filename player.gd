extends CharacterBody3D
@onready var shape_cast_3d = $ShapeCast3D
@onready var camera = $ShapeCast3D/MainCamera

# from joystick
@export var speed : float = 100
@export var joystick_right : VirtualJoystick
var move_vector := Vector2.ZERO
# from end of joystick

#bobbing
const BOB_FREQ = 2.0
const BOB_AMP = 0.05
var t_bob = 0.0
#end of bobbing 
const MOVE_SPEED = 5.0
const RUN_SPEED = 9.0
const LOOK_SENSITIVITY = 0.1

const JUMP_VELOCITY = 4.5

var sens_horizontal = 0.1
var sens_vertical = 0.1
#-----
var relative   : Vector2
var fingers    : int
var raw_gesture : RawGesture

func _init(_raw_gesture : RawGesture = null, event : InputEventScreenDrag = null) -> void:
	raw_gesture = _raw_gesture
	if raw_gesture:
		fingers  = raw_gesture.size()
		position = raw_gesture.centroid("drags", "position")
		relative = event.relative/fingers 

func as_string() -> String:
	return "position=" + str(position) + "|relative=" + str(relative) + "|fingers=" + str(fingers)

#-----
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
#{start} cursor show
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	

func _input(event): 
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
#{end} cursor show	
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
		shape_cast_3d.rotate_x(deg_to_rad(-event.relative.y * sens_vertical))
	
func _physics_process(delta):
	if Input.is_action_pressed("run"):
		print("running")
		speed = RUN_SPEED
	else:
		print("walking")
		speed = MOVE_SPEED
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)
	
	# Head bob
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	# end of head bob
	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time*BOB_FREQ)*BOB_AMP
	pos.x = cos(time*BOB_FREQ)/2 * BOB_AMP
	return pos


func _on_jump_pressed():
	velocity.y = JUMP_VELOCITY
	
