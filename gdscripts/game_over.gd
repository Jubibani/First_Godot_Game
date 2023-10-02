extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED	
	
func _input(event): 
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
