extends Area2D

signal clicked
signal focus

onready var cross: = preload("res://asset/x.png")
onready var circle: = preload("res://asset/o.png")
onready var particle_scene = preload("res://src/ParticleEffect.tscn")

var board_index
var quantum_cells
var classical
var new_particle_effect

func _ready():
	board_index = -1
	quantum_cells = []
	classical = false
	$Placeholder/OrderLabel.visible = false

func make_classical(is_player):
	$Placeholder/OrderLabel.visible = false
	for qc in quantum_cells:
		qc.queue_free()
	quantum_cells = []
	classical = true
	if is_player:
		$Sign.texture = cross
	else:
		$Sign.texture = circle
	$Sign.visible = true

func set_focus(cell_index, player_val):
	# It may be the next possible move, in which case the cell does not exist
	if cell_index >= quantum_cells.size():
		$Placeholder.set_focus(player_val)
	else:
		var qc = quantum_cells[cell_index]
		qc.set_focus(player_val)
		# If we set focus to 0, that means all other quantum cells
		# are modulated
		if player_val == 0:
			for i in quantum_cells.size():
				if i == cell_index:
					pass
				else:
					quantum_cells[i].modulate = Color(1,1,1,0.5)

func highlight():
	$Highlight.visible = true
func unhighlight():
	$Highlight.visible = false
func highlight_chosen():
	$Highlight/ColorRect1.color = Color(1,0,0,1)
	$Highlight/ColorRect2.color = Color(1,0,0,1)
	$Highlight/ColorRect3.color = Color(1,0,0,1)
	$Highlight/ColorRect4.color = Color(1,0,0,1)
func clear_focus():
	$Placeholder.clear_focus()
	modulate = Color(1,1,1)
	for qc in quantum_cells:
		qc.clear_focus()
	#unhighlight()

func clear_placeholder():
	$Placeholder.clear_focus()

func modulate_all_but_key(key, cell_info):
	if classical:
		print("ERROR cant modulate a classical cell")
		return
	var count = 0
	for move in cell_info.moves:
		if move.key() != key:
			var qc = quantum_cells[count]
			qc.modulate = Color(1,1,1,0.5)
			qc.is_modulated = true
		count = count + 1
	
func add_quantum_cell(quantum_cell, is_x_turn):
	var x_extent = ($CollisionShape2D.shape.extents).x
	var y_extent = ($CollisionShape2D.shape.extents).y
	var x_base = -x_extent + 30
	var y_base = -y_extent + 30
	quantum_cells.append(quantum_cell)

	# Reposition based on the number
	var number_of_rows = quantum_cells.size() / 3
	#print("Number of rows: ", number_of_rows)
	var row_number = 0
	var column_number = 0
	add_child(quantum_cell)
	for qc in quantum_cells:
		qc.position.x = x_base + (column_number * 36)
		qc.position.y = y_base + (row_number * 36)
		column_number = column_number + 1
		if column_number == 3:
			column_number = 0
			row_number = row_number + 1
	$Placeholder.position.x = x_base + (column_number * 36)
	$Placeholder.position.y = y_base + (row_number * 36)

	# Add animation for juice
	new_particle_effect = particle_scene.instance()
		
	new_particle_effect.position.x = $Placeholder.position.x - 36
	new_particle_effect.position.y = $Placeholder.position.y
	new_particle_effect.frame = 0
	add_child(new_particle_effect)
	new_particle_effect.show()
	new_particle_effect.playing = true

func _on_mouse_entered():
	if not classical:
		#Input.set_default_cursor_shape(2)
		emit_signal("focus", self)

func _on_mouse_exited():
	if not classical:
		#Input.set_default_cursor_shape(0)
		if get_parent().is_resolve_mode():
			if get_parent().resolve_cells.contains(board_index):
				# TODO we just want to clear the focus on the one quantum cell
				# The rest we want to stay blurred out
				clear_focus()
		else:
			clear_focus()

func _on_input_event(_viewport, event, _shape_idx):
	if not classical:
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_LEFT and event.pressed:
				emit_signal("clicked", self)



func _on_ParticleAnimatedSprite_animation_finished():
	new_particle_effect.playing = false
	new_particle_effect.hide()
