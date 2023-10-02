extends Button

func _on_pressed():
	print("goint to control")
	get_tree().change_scene_to_file("res://scenes/control.tscn")
