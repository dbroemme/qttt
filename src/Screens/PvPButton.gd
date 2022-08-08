extends Button

export(bool) var vs_computer


func _on_button_up():
	GameSingleton.vs_computer = vs_computer
	get_tree().change_scene("res://src/Screens/Board.tscn")
