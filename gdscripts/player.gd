extends CharacterBody3D
@onready var shape_cast_3d = $ShapeCast3D
@onready var camera = $ShapeCast3D/MainCamera
@onready var gun_animation = $ShapeCast3D/MainCamera/hand/Rifle/AnimationGun
@onready var gun_barrel = $ShapeCast3D/MainCamera/hand/Rifle/bullets
@onready var nav_agent = $NavigationAgent3D
# from joystick
@export var speed : float = 100
@export var joystick_right : VirtualJoystick
var move_vector := Vector3.ZERO
# from end of joystick

# the bullets
var bullet  = load("res://bullets.tscn")
var instance
#bobbing
const BOB_FREQ = 2.0
const BOB_AMP = 0.05	
var t_bob = 0.0
const BASE_FOV = 100.0
const FOV_CHANGE = 1.5
#end of bobbing 
const MOVE_SPEED = 5.0
const RUN_SPEED = 7.0
const CROUCH_SPEED = 2.5
const SLIDE_SPEED = 20.0
# for looking sensitivity
const LOOK_SENSITIVITY = 0.1 # for mouse sensitivity
# for touch screen sensitivity
const TOUCHSCREEN_SENSITIVITY = 0.1 
const JUMP_VELOCITY = 3.5
const DOUBLE_JUMP_VELOCITY = 5.5
const WALL_JUMP = 300
const WALL_SLIDE_FALL = 100

var is_on_wallsliding = false
# for touch screen sensitivity(2)
var initialTouchPosition: Vector2 = Vector2.ZERO

var can_jump = true  # Flag to track if the character can jump
var trueSpeed = MOVE_SPEED
var isCrouching = false
var sens_horizontal = 0.1
var sens_vertical = 0.1
var isSprinting = false
var isSliding = false
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
# a func to simulate mobile touch screen with mouse click
func handle_camera_rotation(delta):
	rotate_x(deg_to_rad(delta.y * TOUCHSCREEN_SENSITIVITY))
	rotate_x(deg_to_rad(-delta.x * TOUCHSCREEN_SENSITIVITY))
func _input(event): 
#{end} cursor show	
	#if event is InputEventMouseMotion:
		#rotate_y(deg_to_rad(-event.relative.x * sens_horizontal))
		#shape_cast_3d.rotate_x(deg_to_rad(-event.relative.y * sens_vertical))
		# for touch screen
	if event is InputEventMouseButton:
		var mouse_click = event as InputEventMouseButton
		if mouse_click.button_index == MOUSE_BUTTON_LEFT and mouse_click.pressed:
			if mouse_click.pressed:
				print("Left mouse button clicked")
			else:
				print("Left mouse button released")
			var delta = mouse_click.position - initialTouchPosition
			
	elif event is InputEventScreenTouch:
		var touch = event as InputEventScreenTouch
		if touch.index == 0:
			initialTouchPosition = touch.position #store the touch position
			
		elif touch.is_pressed():
			var delta = touch.position - initialTouchPosition #calculate the delta between the current and initial touch position
			handle_camera_rotation(delta)
			
			rotate_x(deg_to_rad(delta.y * TOUCHSCREEN_SENSITIVITY))
			rotate_y(deg_to_rad(-delta.x * TOUCHSCREEN_SENSITIVITY))
	# crouch (1)	
	if event.is_action_released("crouch") and isCrouching:
		movementStateChange("uncrouch")
		trueSpeed = SLIDE_SPEED
		isCrouching = false
	# for touch screen (2)
func handle_mouse_click(mouse_click):
	# Simulate touch input based on the mouse click
	var delta = Vector2(0, 0)  # Set the desired delta values for rotation here
	rotate_x(deg_to_rad(delta.y * TOUCHSCREEN_SENSITIVITY))
	rotate_y(deg_to_rad(-delta.x * TOUCHSCREEN_SENSITIVITY))
	
func _physics_process(delta):
	if Input.is_action_pressed("run"):
		print("running")
		isSprinting = true
		speed = RUN_SPEED
	else:
		print("walking")
		isSprinting = false
		speed = MOVE_SPEED
		
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta
			
	var velocity_clamped = clamp(velocity.length(), 0.5, speed * 5)
		# Calculate the target FOV based on sprinting and non-sprinting states
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clamped
	if isSprinting:
		target_fov += FOV_CHANGE * velocity_clamped * 0.25  # Adjust this multiplier as needed
		# Transition the camera FOV
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)
		# If not sprinting, gradually transition the FOV back to the default
	if not isSprinting:
		camera.fov = lerp(camera.fov, BASE_FOV, delta * 2.0)  # Adjust the multiplier for transition speed			
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept"):
		if is_on_floor():
			velocity.y = JUMP_VELOCITY
		if is_on_wall() and Input.is_action_pressed("forward"):
			velocity.y = DOUBLE_JUMP_VELOCITY
			velocity.x = WALL_JUMP
			print("double jump")
		if is_on_wall() and Input.is_action_pressed("backward"):
			velocity.y = DOUBLE_JUMP_VELOCITY
			velocity.x = WALL_JUMP
		if is_on_wall() and Input.is_action_pressed("ui_right"):
			velocity.y = DOUBLE_JUMP_VELOCITY
			velocity.x = WALL_JUMP
		if is_on_wall() and Input.is_action_pressed("ui_left"):
			velocity.y = DOUBLE_JUMP_VELOCITY
			velocity.x = WALL_JUMP
	# crouching (2)
	if Input.is_action_just_pressed("crouch"):
		if isCrouching == false:
			if !isCrouching:
				movementStateChange("crouch")
				trueSpeed = CROUCH_SPEED
				isCrouching = true
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
	# sliding
	
	if isSliding:
		trueSpeed = SLIDE_SPEED
	else:
		trueSpeed = speed
	#end of sliding
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




func _on_crouch__slide_pressed() -> void:
	pass # Replace with function body.
