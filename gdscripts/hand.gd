extends Node3D

const ADS_LERP = 20

@export var camera_path : NodePath = "ShapeCast3D/MainCamera"

var camera : Camera3D
@export var default_position : Vector3
@export var ads_position : Vector3

@export var Default: float = 90
@export var ads_accelaration : float = 0.3
@export var ADS: float = 50

# Store the original FOV when the script starts
var original_fov: float

# Called when the node enters the scene tree for the first time.
func _ready():
	camera = get_node(camera_path)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("ads"):
		transform.origin = transform.origin.lerp(ads_position, ADS_LERP * delta)
		camera.fov = ADS 
	else:
		transform.origin = transform.origin.lerp(default_position, ADS_LERP * delta)
		camera.fov = Default
