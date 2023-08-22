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
const RUN_SPEED = 7.0
const CROUCH_SPEED = 3.5
const LOOK_SENSITIVITY = 0.1

const JUMP_VELOCITY = 3.5
const WALL_JUMP = 300
const WALL_SLIDE_FALL = 100

var is_on_wallsliding = false

var can_jump = true  # Flag to track if the character can jump
var trueSpeed = MOVE_SPEED
var isCrouching = false
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
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		if is_on_wall() and Input.is_action_pressed("forward"):
			velocity.y = JUMP_VELOCITY
			velocity.x = WALL_JUMP
		if is_on_wall() and Input.is_action_pressed("backward"):
			velocity.y = JUMP_VELOCITY
			velocity.x = WALL_JUMP
		if is_on_wall() and Input.is_action_pressed("ui_right"):
			velocity.y = JUMP_VELOCITY
			velocity.x = WALL_JUMP
		if is_on_wall() and Input.is_action_pressed("ui_left"):
			velocity.y = JUMP_VELOCITY
			velocity.x = WALL_JUMP
	if Input.is_action_just_pressed("crouch"):
		if isCrouching == false:
			movementStateChange("crouch")
			trueSpeed = CROUCH_SPEED
			
		elif isCrouching == true:
			movementStateChange("uncrouch")
			trueSpeed = MOVE_SPEED
		
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
	wall_slide(delta)
func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time*BOB_FREQ)*BOB_AMP
	pos.x = cos(time*BOB_FREQ)/2 * BOB_AMP
	return pos
func _on_jump_pressed():
	velocity.y = JUMP_VELOCITY
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		if is_on_wall() and Input.is_action_pressed("forward"):
			velocity.y = JUMP_VELOCITY
			velocity.x = WALL_JUMP
func wall_slide(delta):
	if is_on_wall() and !is_on_floor():
		if Input.is_action_just_pressed("forward"):
			is_on_wallsliding = true
		else:
			is_on_wallsliding = false
	else:
		is_on_wallsliding = false
	if is_on_wallsliding:
		velocity.y += (WALL_SLIDE_FALL * delta)
		velocity.x = min(velocity.y, WALL_SLIDE_FALL)
func _on_sprint_pressed():
	if Input.is_action_pressed("run"):
		print("running")
		speed = RUN_SPEED
	else:
		print("walking")
		speed = MOVE_SPEED
		
# crouching
func movementStateChange(changeType):
	match changeType:
		"crouch":
			isCrouching = true
			$AnimationPlayer.play("StandingToCrouch")
			changeCollisionShapeTo("crouching")
		"uncrouch":
			$AnimationPlayer.play("RESET")
			isCrouching = false
			changeCollisionShapeTo("standing")
#Change collision shapes for standing, crouch
func changeCollisionShapeTo(shape):
	match shape:
		"crouching":
			#Disabled == false is enabled!
			$CrouchingCollisionShape3D.disabled = false
			$StandingCollisionShape3D.disabled = true
		"standing":
			#Disabled == false is enabled!
			$StandingCollisionShape3D.disabled = false
			$CrouchingCollisionShape3D.disabled = true


