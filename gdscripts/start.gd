extends Button

func _on_pressed():
	print("start")
	get_tree().change_scene_to_file("res://scenes/menu.tscn")
