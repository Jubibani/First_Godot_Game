extends CharacterBody3D

var player = null
var speed = 5
var accel = 10

@onready var nav: NavigationAgent3D = $NavigationAgent3D
@onready var player_path := "../../../player"

func _ready():
	# Assuming you have a root node in the scene named "Player"
	player = get_node(player_path)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	
	
func _input(event):
	if event.is_action_pressed("ui_cancel"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
func _physics_process(delta):
	if player_path:
		var direction = Vector3()
		
		nav.target_position = player.global_transform.origin
		
		direction = nav.get_next_path_position() - global_position
		direction = direction.normalized()
		
		velocity = velocity.lerp(direction * speed, accel * delta)

		
		move_and_slide()


func _on_navigation_agent_3d_target_reached():
	get_tree().change_scene_to_file("res://game_over.tscn")
