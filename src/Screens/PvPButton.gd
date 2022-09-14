extends Button

export(bool) var vs_computer
export(bool) var easy_mode


func _on_button_up():
	GameSingleton.vs_computer = vs_computer
	GameSingleton.easy_mode = easy_mode
	get_tree().change_scene("res://src/Screens/Board.tscn")
