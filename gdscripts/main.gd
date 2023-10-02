extends Node3D
@onready var spawns = $map/spawns
@onready var navigation_region = $map/NavigationRegion3D

var enemy = load("res://scenes/enemy.tscn")
var instance
var cursor_action_pressed = false
# Called when the node enters the scene tree for the first time.
func _ready():
	randomize()
func _get_random_child(parent_node):
	var random_id = randi() % parent_node.get_child_count()
	return parent_node.get_child(random_id)
func _input(event): 
	if event.is_action_pressed("cursor"):
		cursor_action_pressed = true
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	elif event.is_action_released("cursor"):
		cursor_action_pressed = false
func pause(): # to pause
	get_tree().paused = true
	$PauseMenu.show()
func unpause():
	get_tree().paused = false
	$PauseMenu.hide()

func _on_enemy_spawns_timeout():
	var spawn_point = _get_random_child(spawns).global_position
	instance = enemy.instantiate()
	instance.position = spawn_point
	navigation_region.add_child(instance)


func _on_menu_pressed() -> void:
	print("goin to control")
	get_tree().change_scene_to_file("res://scenes/control.tscn")
