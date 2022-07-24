extends Area2D

signal quantum_clicked
signal quantum_focus

onready var selected_image: = preload("res://asset/cell_selected_small.png")
onready var cross_small: = preload("res://asset/x_grey_small.png")
onready var circle_small: = preload("res://asset/o_grey_small.png")
onready var cross: = preload("res://asset/x_small.png")
onready var circle: = preload("res://asset/o_small.png")

var is_modulated

func _ready():
	is_modulated = false

func set_focus(player_val):
	#print("QC set focus to ", player_val)
	if player_val == 1:
		$Focus.texture = cross_small
	elif player_val == 0:
		$Focus.texture = selected_image
	elif player_val == -1:
		$Focus.texture = circle_small
	$Focus.visible = true
		
func clear_focus():
	if is_modulated:
		return
	$Focus.visible = false
	modulate = Color(1,1,1)

func _on_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton:
		if event.button_index == BUTTON_LEFT and event.pressed:
			emit_signal("quantum_clicked", self)

