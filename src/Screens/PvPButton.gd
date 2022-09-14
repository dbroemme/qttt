extends Button

export(bool) var vs_computer
export(bool) var easy_mode
export(bool) var quit_game


func _on_button_up():
	if quit_game:
		get_tree().quit()

	GameSingleton.vs_computer = vs_computer
	GameSingleton.easy_mode = easy_mode
	get_tree().change_scene("res://src/Screens/Board.tscn")
