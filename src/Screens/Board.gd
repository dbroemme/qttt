class_name Model
extends Node2D

var TURN_XA = 0
var TURN_XB = 1
var TURN_O_RESOLVE = 2
var TURN_OA = 3
var TURN_OB = 4
var TURN_X_RESOLVE = 5
var TURN_GAME_OVER = 6
var TURN_DISPLAY = ["XA", "XB", "O_RESOLVE", "OA", "OB", "X_RESOLVE", "GAME_OVER"]

var current_cell_focus = -1
var win_label = ""

var first_move_sound = preload("res://asset/audio/FirstMove.ogg")
var second_move_sound = preload("res://asset/audio/SecondMove.ogg")
var computer_first_move_sound = preload("res://asset/audio/ComputerFirstMove.ogg")
var computer_second_move_sound = preload("res://asset/audio/ComputerSecondMove.ogg")
var resolve_sound = preload("res://asset/audio/ResolveSound.ogg")

onready var cross_quantum: = preload("res://asset/x_small.png")
onready var circle_quantum: = preload("res://asset/o_small.png")
onready var cross_grey: = preload("res://asset/x_grey.png")
onready var circle_grey: = preload("res://asset/o_grey.png")
onready var cross_small: = preload("res://asset/x_grey_small.png")
onready var circle_small: = preload("res://asset/o_grey_small.png")
onready var player_x_small: = preload("res://asset/x_small.png")
onready var player_o_small: = preload("res://asset/o_small.png")
onready var player_x: = preload("res://asset/x.png")
onready var player_o: = preload("res://asset/o.png")
onready var quantum_cell_scene = preload("res://src/QuantumCell.tscn")

onready var img_number_0: = preload("res://asset/number_0.png")
onready var img_number_1: = preload("res://asset/number_1.png")
onready var img_number_2: = preload("res://asset/number_2.png")
onready var img_number_3: = preload("res://asset/number_3.png")
onready var img_number_4: = preload("res://asset/number_4.png")
onready var img_number_5: = preload("res://asset/number_5.png")
onready var img_number_6: = preload("res://asset/number_6.png")
onready var img_number_7: = preload("res://asset/number_7.png")
onready var img_number_8: = preload("res://asset/number_8.png")
onready var img_number_9: = preload("res://asset/number_9.png")
onready var NUMBER_IMAGES = [img_number_0, img_number_1, img_number_2, img_number_3,
					 img_number_4, img_number_5, img_number_6, img_number_7,
					 img_number_8, img_number_9]

onready var help_image_subscript: = preload("res://asset/HelpSubscript.png")
onready var help_image_resolve: = preload("res://asset/HelpResolve.png")
onready var help_image_classical: = preload("res://asset/HelpClassical.png")
onready var help_image_empty: = preload("res://asset/LittleBlackBox.png")

const Set = preload("../Set.gd")

var rng = RandomNumberGenerator.new()
var msg_initial_1 = """You are X, and you get to go first.

Each player makes two quantum moves on each turn. Think of these as multiple potential games being played at once.
"""
var human_msg_initial_1 = """The first player is X.

Each player makes two quantum moves on each turn. Think of these as multiple potential games being played at once.
"""


var msg_initial_2 = "Click in one of the nine spaces to make your first quantum move."
var msg_you_made_first_move = """Great, you made your first quantum move. 

At this point, your quantum move is not \"real\", or what we call a classical move. Only classical moves can win the game.

Each quantum move has a numeric subscript that indicates the turn number.
"""
var msg_you_made_first_move_2 = """Now choose a second space for your other quantum move of this turn.
"""

var msg_you_made_a_move = """Great, you made your first quantum move of this turn.
"""
var msg_you_made_a_move_2 = """Now choose a second space for your other quantum move of this turn.
"""

var msg_human_made_a_move = """Great, player O made the first quantum move of this turn.
"""

var msg_you_resolved_conflict = """Great, you resolved the conflict and there are additional classical moves on the board.

Remember that only classical moves can win the game.
"""
var msg_you_resolved_conflict_2 = "Now make your first quantum move of the turn."

var msg_computer_first_move = "The computer made its first quantum move, now for the second ..."
var msg_computer_second_move = "The computer finished its quantum moves for that round. Now it is your turn again."

var msg_human_first_move = "Player O made its first quantum move, now for the second ..."
var msg_human_second_move = "Player O finished its quantum moves for that round. Now it is player X again."
var msg_human_turn = "Player X, its your turn. Go ahead and click in a non-classical space for your next quantum move."


var msg_your_turn = "Go ahead and click in a non-classical space to make your first quantum move of the turn."
var msg_you_get_to_resolve = """The computer chose a move that resulted in a conflict, so now some of the quantum moves need to be resolved into real (or classical) moves.

Some of the earlier possible games are no longer possible, so one resolved space often leads to other spaces being resolved.
"""
var msg_you_get_to_resolve_2 = """You get to choose which of the conflict spots the computer should take. Click on a highlighted space to choose.
"""

var msg_you_get_to_resolve_human = """Player O chose a move that resulted in a conflict, so now some of the quantum moves need to be resolved into real (or classical) moves.

Some of the earlier possible games are no longer possible, so one resolved space often leads to other spaces being resolved.
"""
var msg_you_get_to_resolve_2_human = """Player X gets to choose which of the conflict spots Player O should take. Click on a highlighted space to choose.
"""

var msg_computer_get_to_resolve = "You chose a move that resulted in a conflict, so now some of the quantum moves need to be resolved into real (or classical) moves."
var msg_computer_get_to_resolve_2 = "The computer gets to choose which of the conflict spots you should take."

var msg_human_get_to_resolve = "Player X chose a move that resulted in a conflict, so now some of the quantum moves need to be resolved into real (or classical) moves."
var msg_human_get_to_resolve_2 = "Player O gets to choose which of the conflict spots Player X should take."

class Move:
	var player: int        # 1 = X, -1 = O, 0 = nobody
	var order: int         # the nth move of the game
	var is_classical: int  # 1 = yes, 0 = false
	func duplicate():
		var new_move = Move.new()
		new_move.player = self.player
		new_move.order = self.order
		new_move.is_classical = self.is_classical
		return new_move
	func to_debug():
		print("  Move ", player, "  order: ", order, "  classical: ", is_classical)
	func key():
		var player_str = ""
		if player == 1:
			player_str = "X"
		elif player == -1:
			player_str = "O"
		return player_str + str(order)

#  0  1  2
#  3  4  5
#  6  7  8

class CellInfo:
	var board_index: int         # index on the board (0-8)
	var moves: Array
	func _init():
		moves = []
	func duplicate():
		var new_cell_info = CellInfo.new()
		new_cell_info.board_index = self.board_index
		var copy_of_moves = []
		for existing_move in moves:
			copy_of_moves.append(existing_move.duplicate())
		new_cell_info.moves = copy_of_moves
		return new_cell_info
	func number_of_moves():
		return moves.size()
	func to_display():
		if !is_quantum():
			if get_value() == 1:
				return "X"
			else:
				return "O"
		var str1 = ""
		for move in moves:
			str1 = str1 + move.key() + ", "
		return str1
	func to_debug():
		print("Cell ", board_index, "  moves: ", moves)
		for move in moves:
			move.to_debug()
	func get_value():
		if moves.empty():
			return 0
		for move in moves:
			if move.is_classical == 1:
				return move.player
		return 0
	func make_classical(chosen_key):
		var other_keys = []
		for move in moves:
			if move.key() == chosen_key:
				move.is_classical = 1
			else:
				other_keys.append(move.key())
		return other_keys
	func hypothetical_classical(chosen_key):
		var other_keys = []
		for move in moves:
			if move.key() != chosen_key:
				other_keys.append(move.key())
		return other_keys
	func is_quantum():
		return (get_value() == 0)
	func has_move(a_key):
		for move in moves:
			if move.key() == a_key:
				return true
		return false
	func moves_except(a_key):
		var other_moves = []
		for move in moves:
			if move.key() != a_key:
				other_moves.append(move)
		return other_moves
	func has_quantum_player(player_val):
		var the_value = get_value()
		if the_value == 0:
			for move in moves:
				if move.player == player_val:
					return true
			return false
		return false
	func has_classical_player(player_val):
		var the_value = get_value()
		return the_value == player_val
	func add_move(order, player):
		var new_move = Move.new()
		new_move.player = player
		new_move.order = order
		new_move.is_classical = false
		moves.append(new_move)
		
class GameState:
	var turn_number: int 
	var turn: int 
	var matrix
	var move_key_list
	var resolve_key
	var resolve_cells
	var board_indexes_that_will_collapse
	var TURN_XA = 0
	var TURN_XB = 1
	var TURN_O_RESOLVE = 2
	var TURN_OA = 3
	var TURN_OB = 4
	var TURN_X_RESOLVE = 5
	var TURN_GAME_OVER = 6
	var TURN_DISPLAY = ["XA", "XB", "O_RESOLVE", "OA", "OB", "X_RESOLVE", "GAME_OVER"]
	var simulation = false
	var both_win = false
	var copy_text

	func _init():
		self.resolve_key = null
		self.resolve_cells = []
		self.board_indexes_that_will_collapse = Set.new()
		self.copy_text = ""

	func duplicate():
		var new_matrix = []
		for existing_cell_info in matrix:
			new_matrix.append(existing_cell_info.duplicate())
		
		var new_game_state = GameState.new()
		new_game_state.turn_number = self.turn_number
		new_game_state.turn = self.turn
		new_game_state.matrix = new_matrix
		new_game_state.move_key_list = self.move_key_list.duplicate(true)
		new_game_state.resolve_key = self.resolve_key
		new_game_state.resolve_cells = self.resolve_cells.duplicate(true)
		new_game_state.both_win = self.both_win
		return new_game_state

	func increment_turn_number():
		turn_number = turn_number + 1

	func create_empty_board():
		for n in range(0,9):
			var new_cell = CellInfo.new()
			new_cell.board_index = n
			matrix.append(new_cell)

	func is_x_turn():
		if turn == TURN_XA or turn == TURN_XB or turn == TURN_X_RESOLVE:
			return true
		return false

	func is_first_choice():
		if turn == TURN_XA or turn == TURN_OA:
			return true
		return false
	
	func is_resolve_mode():
		if turn == TURN_X_RESOLVE or turn == TURN_O_RESOLVE:
			return true
		return false

	func choice_letter():
		if turn == TURN_XA or turn == TURN_OA:
			return "A"
		if turn == TURN_XB or turn == TURN_OB:
			return "B"
		return "-"

	func get_empty_tiles() -> Array:
		var classical_board = get_classical_board()
		var _tiles: Array
		for n in range(0,9):
			if classical_board[n] == 0:
				_tiles.append(n)
		return _tiles

	func all_have_value(classical_board, index1, index2, index3):
		var value_1 = classical_board[index1]
		var value_2 = classical_board[index2]
		var value_3 = classical_board[index3]
		if value_1 == 0 or value_2 == 0 or value_3 == 0:
			return 0
		if value_1 == value_2 and value_2 == value_3:
			return value_1
		return 0
	
	func get_classical_board():
		var list = []
		for cell_info in matrix:
			list.append(cell_info.get_value())
		return list

	func is_game_over() -> bool:
		if get_score() != 0 or get_empty_tiles().size() == 0 or both_win:
			return true
		else:
			return false

	func get_score() -> int:
		var score: int
		score = check_victory()
		return score * (matrix.size() + 1)

	func check_victory() -> int:
		var winner_score = 0
		var classical_board = get_classical_board()
		var winner = 0
		winner = all_have_value(classical_board, 0, 3, 6)
		if winner != 0:
			winner_score = winner
		winner = all_have_value(classical_board, 1, 4, 7)		
		if winner != 0:
			if winner != winner_score and winner_score != 0:
				both_win = true
				return 0
			winner_score = winner
		winner = all_have_value(classical_board, 2, 5, 8)
		if winner != 0:
			if winner != winner_score and winner_score != 0:
				both_win = true
				return 0
			winner_score = winner
		winner = all_have_value(classical_board, 0, 1, 2)
		if winner != 0:
			if winner != winner_score and winner_score != 0:
				both_win = true
				return 0
			winner_score = winner
		winner = all_have_value(classical_board, 3, 4, 5)		
		if winner != 0:
			if winner != winner_score and winner_score != 0:
				both_win = true
				return 0
			winner_score = winner
		winner = all_have_value(classical_board, 6, 7, 8)
		if winner != 0:
			if winner != winner_score and winner_score != 0:
				both_win = true
				return 0
			winner_score = winner
		winner = all_have_value(classical_board, 0, 4, 8)
		if winner != 0:
			if winner != winner_score and winner_score != 0:
				both_win = true
				return 0
			winner_score = winner
		winner = all_have_value(classical_board, 2, 4, 6)
		if winner != 0:
			if winner != winner_score and winner_score != 0:
				both_win = true
				return 0
			winner_score = winner
		return winner_score

	func find_cells_with_quantum_move(key):
		var result = []
		for index in matrix.size():
			var cell_info = matrix[index]
			if cell_info.has_move(key):
				result.append(index)
		return result

	func find_all_cells_that_will_collapse():
		# I don't think it matters which of the two we use
		#print("find cells that will collapse ", resolve_key)
		recurse_find_all_collapse(resolve_key, Set.new(), board_indexes_that_will_collapse)
		#print("found number ", board_indexes_that_will_collapse.size())

	func recurse_find_all_collapse(key, key_set, board_indexes):
		# Return a list of board indexes that will collapse
		# Just walk the tree of moves through cell info
		key_set.add(key)
		var cell_infos = get_cell_infos_with_move(key)
		for ci in cell_infos:
			board_indexes.add(ci.board_index)
			var other_moves = ci.hypothetical_classical(key)
			for other_move in other_moves:
				if !key_set.contains(other_move):
					recurse_find_all_collapse(other_move, key_set, board_indexes)

	func get_cell_infos_with_move(key):
		var cell_info_with_key = []
		for index in matrix.size():
			var cell_info = matrix[index]
			if cell_info.has_move(key):
				cell_info_with_key.append(cell_info)
		return cell_info_with_key

	func check_for_collapse() -> bool:
		for move_key in move_key_list:
			var two_board_indices = get_cells_with_move(move_key)
			#print(move_key, " was found in two board indices ", two_board_indices)
			var cell_1 = matrix[two_board_indices[0]]
			var cell_2 = matrix[two_board_indices[1]]
			# Resolve cells are the two board indexes where this move exists
			# Resolve chain are all the cells that formed the cycle
			# Not exactly sure why we need it though
			var traversed_set_1 = Set.new()
			traversed_set_1.add(str(cell_1.board_index) + move_key)
			if recurse_check_for_collapse(move_key, cell_1.board_index, traversed_set_1):
				resolve_key = move_key_list.back()
				print("The resolve key is ", resolve_key)
				resolve_cells = get_cells_with_move(resolve_key)
				print("The resolve cells are ", resolve_cells)
				find_all_cells_that_will_collapse()
				return true
			else:
				var traversed_set_2 = Set.new()
				traversed_set_2.add(str(cell_2.board_index) + move_key)
				if recurse_check_for_collapse(move_key, cell_2.board_index, traversed_set_2):
					resolve_key = move_key_list.back()
					print("The resolve key is ", resolve_key)
					resolve_cells = get_cells_with_move(resolve_key)
					print("The resolve cells are ", resolve_cells)
					find_all_cells_that_will_collapse()
					return true
		return false
	
	func recurse_check_for_collapse(move_key, last_spot, traversed_set):
		#print("Recurse check ", move_key, " set: ", traversed_set)
		var two_board_indices = get_cells_with_move(move_key)
		var cell_to_process = two_board_indices[0]
		#if two_board_indices.size() == 1:
		#	print("WARN: get cells with move ", move_key, " only has one: ", two_board_indices)
		if cell_to_process == last_spot and two_board_indices.size() > 1:
			cell_to_process = two_board_indices[1]

		var the_cell_info = matrix[cell_to_process]
		var other_moves = the_cell_info.moves_except(move_key)
		for other_move in other_moves:
			var new_traverse_key = str(the_cell_info.board_index) + other_move.key()
			if traversed_set.contains(new_traverse_key):
				#print("  ", new_traverse_key, " was in the traversed set ", traversed_set)
				return true
			else:
				traversed_set.add(new_traverse_key)
				if recurse_check_for_collapse(other_move.key(), cell_to_process, traversed_set):
					return true
				
		return false

	func get_cells_with_move(move_key):
		var list = []
		for cell_info in matrix:
			if cell_info.is_quantum() and cell_info.has_move(move_key):
				list.append(cell_info.board_index)
		return list

	func player_value():
		if turn < TURN_OA:
			return 1
		return -1

	func player_letter():
		if turn < TURN_OA:
			return "X"
		if turn < TURN_GAME_OVER:
			return "O"
		return "-"

	func create_move_instance():
		var new_move = Move.new()
		new_move.player = player_value()
		new_move.order = turn_number
		new_move.is_classical = false
		return new_move
	
	func play_move(board_index):
		# Verify there is not already a classical move here
		var cell_info = matrix[board_index]
		if !cell_info.is_quantum():
			print("ERROR cannot make a move in classical cell ", board_index)
			return [false, -1, -1, -1]
	
		var new_move = create_move_instance()
		if cell_info.has_move(new_move.key()):
			return [false, -1, -1, -1]
			
		if is_first_choice():
			move_key_list.append(new_move.key())

		cell_info.add_move(turn_number, player_value())
		if !simulation:
			print("--- After play ", turn_number, " mode: ", TURN_DISPLAY[turn], "     key: ", new_move.key(), " history: ", move_key_list)

		var old_turn = increment_turn()
		return [true, old_turn, turn, turn_number]
		
	func play_resolve(board_index, key, return_moves):
		#print("play resolve")
		# Update the data structures
		var cell_info = matrix[board_index]
		var other_moves = cell_info.make_classical(key)
		return_moves.append([cell_info.board_index, cell_info.get_value()])

		var index_to_delete = move_key_list.find(key)
		move_key_list.remove(index_to_delete)

		# Now recursively keep going
		#print("play resolve other moves: ", other_moves.size())
		for other_move in other_moves:
			#print("  consider ", other_move)
			if move_key_list.has(other_move):
				#print("  do need to recon ", other_move)
				var possible_board_indexes = find_cells_with_quantum_move(other_move)
				var next_chosen_board_index = -1
				for i in possible_board_indexes:
					var possible_cell_info = matrix[i]
					#print("   check if quantum: ", i)
					if possible_cell_info.is_quantum():
						next_chosen_board_index = i
				if next_chosen_board_index == -1:
					print("ERROR we were never able to resolve ", other_move)
				else:
					play_resolve(next_chosen_board_index, other_move, return_moves)

	func print_matrix():
		print(pad(matrix[0].to_display()), "  |  ", pad(matrix[1].to_display()), "  |  ", pad(matrix[2].to_display()))
		print("----------------  |  ----------------  |  ----------------")
		print(pad(matrix[3].to_display()), "  |  ", pad(matrix[4].to_display()), "  |  ", pad(matrix[5].to_display()))
		print("----------------  |  ----------------  |  ----------------")
		print(pad(matrix[6].to_display()), "  |  ", pad(matrix[7].to_display()), "  |  ", pad(matrix[8].to_display()))

	func pad(val):
		return "%16s" % val

	func increment_turn():
		board_indexes_that_will_collapse = Set.new()
		var old_turn = turn 
		if !is_first_choice() and check_for_collapse():
			if turn == TURN_XA or turn == TURN_XB:
				turn = TURN_O_RESOLVE
			elif turn == TURN_OA or turn == TURN_OB:
				turn = TURN_X_RESOLVE
			else:
				if !simulation:
					print("ERROR do not know how move to collapse ", TURN_DISPLAY[turn])
		else:
			if turn == TURN_XA:
				turn = TURN_XB
			elif turn == TURN_XB or turn == TURN_O_RESOLVE:
				turn = TURN_OA
				increment_turn_number()
			elif turn == TURN_OA:
				turn = TURN_OB
			elif turn == TURN_OB or turn == TURN_X_RESOLVE:
				turn = TURN_XA
				increment_turn_number()
			elif turn == TURN_GAME_OVER:
				pass
			else:
				print("ERROR do not know how to increment turn ", TURN_DISPLAY[turn])
		return old_turn
# End game state class


export(int) var width: = 3
export(int) var height: = 3


var computer_move_1
var computer_move_2

# Old agent variables
var stats = {}
var visited_nodes: = 0

var game_state

func set_message_1(text_value):
	#$MessagesLabel1.bbcode_text = "[center]" + message_1 + "[center]"	
	$MessagesLabel1.text = text_value	

func set_message_2(text_value):
	#$MessagesLabel2.bbcode_text = "[center]" + message_2 + "[center]"	
	$MessagesLabel2.text = text_value
	
func set_message_image(img):
	$HelpImage1.texture = img
	
func set_message_image_invisible():
	$HelpImage1.visible = false

func clear_help_image():
	set_message_image(help_image_empty)
	set_message_image_invisible()

# _init() and _ready()
func _ready():
	game_state = GameState.new()
	game_state.turn_number = 1
	game_state.turn = TURN_XA
	game_state.matrix = []
	game_state.move_key_list = []
	
	game_state.create_empty_board()

	$HistoryText.text = ""
	$TurnNumberInfo/Label.bbcode_text = "[center]Turn Number[center]"
	$TurnPlayerInfo/Label.bbcode_text = "[center]Player Turn[center]"
	$TurnDetailInfo/Label.bbcode_text = "[center]Move[center]"
	$TurnDetailInfo/ValueSprite.texture = null
	$TurnNumberInfo/ValueSprite.scale = Vector2(0.8, 0.8)
	$TurnPlayerInfo/ValueSprite.scale = Vector2(0.5, 0.5)
	$MessagesLabel1.get_child(0).modulate.a = 0
	$MessagesLabel2.get_child(0).modulate.a = 0
	
	# Bootstrap the turn related display elements
	# This then gets adjusted in the increment_turn method from here on out
	$TurnPlayerInfo/ValueSprite.texture = player_x
	$LabelFirstMove.visible = true
	$LabelSecondMove.modulate = Color(1,1,1,0.5)
	if GameSingleton.vs_computer:
		set_message_1(msg_initial_1)
	else:
		set_message_1(human_msg_initial_1)
	set_message_2(msg_initial_2)
	
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.connect("clicked", self, "on_cell_clicked")
		cell.connect("focus", self, "on_cell_focus")

func _process(delta):
	pass

func get_empty_tiles_for_classical(classical_board) -> Array:
	var _tiles: Array
	for n in range(0,9):
		if classical_board[n] == 0:
			_tiles.append(n)
	return _tiles

func resolve_effects():
	clear_help_image()
	$AudioPlayer.stream = resolve_sound
	$AudioPlayer.play()
	$BoardCamera.add_trauma(0.5)

func play(cell: Area2D):
	# Verify there is not already a classical move here
	var old_is_x = game_state.is_x_turn()
	var old_turn_num = game_state.turn_number
	var result_array = game_state.play_move(cell.board_index)
	var move_made = result_array[0]
	if !move_made:
		return
	
	#print("play screen old_is_x: ", old_is_x, " for ", old_turn_num)
	var new_quantum_scene = quantum_cell_scene.instance()
	var new_quantum_sign = new_quantum_scene.get_node("Sign")
	var new_quantum_label = new_quantum_scene.get_node("OrderLabel")
	new_quantum_label.text = str(old_turn_num)
	if old_is_x:
		new_quantum_sign.visible = true
		new_quantum_sign.texture = cross_quantum
	else:
		new_quantum_sign.visible = true
		new_quantum_sign.texture = circle_quantum
	cell.add_quantum_cell(new_quantum_scene)
	
	var old_turn = result_array[1]
	var new_turn = result_array[2]
	var new_turn_num = result_array[3]
	current_cell_focus = -1
	update_gui_after_turn(old_turn, new_turn, new_turn_num)

func update_gui_after_turn(old_turn, new_turn, new_turn_num):
	if new_turn == TURN_O_RESOLVE:
		resolve_effects()
		if GameSingleton.vs_computer:
			set_message_1(msg_computer_get_to_resolve)
			set_message_2(msg_computer_get_to_resolve_2)
		else:
			set_message_1(msg_human_get_to_resolve)
			set_message_2(msg_human_get_to_resolve_2)			
		if GameSingleton.vs_computer:
			make_computer_move()
	elif new_turn == TURN_X_RESOLVE:
		resolve_effects()
		if GameSingleton.vs_computer:
			set_message_1(msg_you_get_to_resolve)
			set_message_2(msg_you_get_to_resolve_2)
		else:
			set_message_1(msg_you_get_to_resolve_human)
			set_message_2(msg_you_get_to_resolve_2_human)
	elif new_turn == TURN_XA:
		$AudioPlayer.stream = computer_second_move_sound
		$AudioPlayer.play()
		if GameSingleton.vs_computer:
			set_message_1(msg_computer_second_move)
			set_message_2(msg_your_turn)
		else:
			set_message_1(msg_human_second_move)
			set_message_2(msg_human_turn)
			
	elif new_turn == TURN_XB:
		$AudioPlayer.stream = first_move_sound
		$AudioPlayer.play()
		if new_turn_num == 1:
			set_message_1(msg_you_made_first_move)
			set_message_2(msg_you_made_first_move_2)
		else:
			clear_help_image()
			set_message_1(msg_you_made_a_move)
			set_message_2(msg_you_made_a_move_2)
	elif new_turn == TURN_OA:
		if GameSingleton.vs_computer:
			set_message_1("Now it is the computers turn")
			set_message_2("")
		else:
			set_message_1("Now it is player Os turn")
			set_message_2(msg_initial_2)
		$AudioPlayer.stream = second_move_sound
		$AudioPlayer.play()
		clear_help_image()
	elif new_turn == TURN_OB:
		$AudioPlayer.stream = computer_first_move_sound
		$AudioPlayer.play()
		if GameSingleton.vs_computer:
			set_message_1(msg_computer_first_move)
			set_message_2("")
		else:
			set_message_1(msg_human_first_move)
			set_message_2("")
			
	elif new_turn == TURN_GAME_OVER:
		set_message_1(win_label)
		set_message_2("The game is over.")
	# Update the display
	#$ModeValue.text = TURN_DISPLAY[game_state.turn]
	if new_turn_num < 10:
		$TurnNumberInfo/ValueSprite.texture = NUMBER_IMAGES[new_turn_num]
		if game_state.is_x_turn():
			$TurnPlayerInfo/ValueSprite.texture = player_x
		else:
			$TurnPlayerInfo/ValueSprite.texture = player_o
		if game_state.is_first_choice():
			$LabelFirstMove.visible = true
			$LabelFirstMove.modulate = Color(1,1,1,1)
			$LabelSecondMove.visible = false
			$LabelResolveMove.visible = false
		elif game_state.is_resolve_mode():
			$LabelFirstMove.visible = false
			$LabelSecondMove.visible = false
			$LabelResolveMove.visible = true		
		else:
			$LabelFirstMove.modulate = Color(1,1,1,0.4)
			$LabelSecondMove.modulate = Color(1,1,1,1)
			$LabelSecondMove.visible = true
			$LabelResolveMove.visible = false
		
		for n in game_state.board_indexes_that_will_collapse.elements():
			var the_cell = get_gui_cell_by_index(n)
			the_cell.highlight()
		if game_state.board_indexes_that_will_collapse.is_empty():
			for the_cell in get_tree().get_nodes_in_group("cells"):
				the_cell.clear_focus()
				the_cell.unhighlight()
		
	# Set the messages accordingly

	# If this is the only cell left, then make it classical and be done
	#var empty_tiles = game_state.get_empty_tiles()
	#if empty_tiles.size() == 1 and empty_tiles[0] == cell.board_index:
		# This was the last open cell, so it goes to the player whose turn it is
	#	cell_info.make_classical(new_move.key())
	#	collapse_move(cell.board_index, new_move.key(), true)
	#	var result = check_victory(game_state.get_classical_board())
	#	end_game(result)
	#	return

func is_move_player(key):
	var player_part_of_str = key.left(1)
	if player_part_of_str == "X":
		return true
	elif player_part_of_str == "O":
		return false

func collapse_move(chosen_board_index, key):
	#var cell = get_gui_cell_by_index(chosen_board_index)
	#cell.highlight_chosen()
	# The resolve_key move exists in both resolve_cells.elements()
	# but the chosen_board_index was chosen
	# That means the other one probably goes to another move in the chain node
	#print("Collapse cell ", chosen_board_index, " for move ", key)

	var collapse_moves = []
	game_state.play_resolve(chosen_board_index, key, collapse_moves)

	# Update the GUI
	for collapse_move in collapse_moves:
		var collapse_board_index = collapse_move[0]
		var collapse_player_val = collapse_move[1]
		var gui_cell = self.get_gui_cell_by_index(collapse_move[0])
		gui_cell.make_classical(collapse_player_val == 1)
		yield(get_tree().create_timer(1.0), "timeout")

	for the_cell in get_tree().get_nodes_in_group("cells"):
		the_cell.clear_focus()
		the_cell.unhighlight()
	#print("The move list is ", game_state.move_key_list, ", mode: ", TURN_DISPLAY[game_state.turn])
	var classical_board = game_state.get_classical_board()
	var result = game_state.check_victory()
	if game_state.is_game_over():
		end_game(result)

func all_have_value(classical_board, index1, index2, index3):
	var value_1 = classical_board[index1]
	var value_2 = classical_board[index2]
	var value_3 = classical_board[index3]
	if value_1 == 0 or value_2 == 0 or value_3 == 0:
		return 0
	if value_1 == value_2 and value_2 == value_3:
		return value_1
	return 0

func highlight_victory(classical_board):
	var winner = 0
	winner = all_have_value(classical_board, 0, 3, 6)
	if winner != 0:
		$Cell1/WinHighlight.visible = true
		$Cell4/WinHighlight.visible = true
		$Cell7/WinHighlight.visible = true
	winner = all_have_value(classical_board, 1, 4, 7)		
	if winner != 0:
		$Cell2/WinHighlight.visible = true
		$Cell5/WinHighlight.visible = true
		$Cell8/WinHighlight.visible = true
	winner = all_have_value(classical_board, 2, 5, 8)
	if winner != 0:
		$Cell3/WinHighlight.visible = true
		$Cell6/WinHighlight.visible = true
		$Cell9/WinHighlight.visible = true
	winner = all_have_value(classical_board, 0, 1, 2)
	if winner != 0:
		$Cell1/WinHighlight.visible = true
		$Cell2/WinHighlight.visible = true
		$Cell3/WinHighlight.visible = true
	winner = all_have_value(classical_board, 3, 4, 5)		
	if winner != 0:
		$Cell4/WinHighlight.visible = true
		$Cell5/WinHighlight.visible = true
		$Cell6/WinHighlight.visible = true
	winner = all_have_value(classical_board, 6, 7, 8)
	if winner != 0:
		$Cell7/WinHighlight.visible = true
		$Cell8/WinHighlight.visible = true
		$Cell9/WinHighlight.visible = true
	winner = all_have_value(classical_board, 0, 4, 8)
	if winner != 0:
		$Cell1/WinHighlight.visible = true
		$Cell5/WinHighlight.visible = true
		$Cell9/WinHighlight.visible = true
	winner = all_have_value(classical_board, 2, 4, 6)
	if winner != 0:
		$Cell3/WinHighlight.visible = true
		$Cell5/WinHighlight.visible = true
		$Cell7/WinHighlight.visible = true


func end_game(value: int) -> void:
	if value == 1:
		win_label = "X has won the game!"
		highlight_victory(game_state.get_classical_board())
	elif value == -1:
		win_label = "O has won the game!"
		highlight_victory(game_state.get_classical_board())
	else: # value == 0
		if game_state.both_win == true:
			win_label = "Both players won!"
			highlight_victory(game_state.get_classical_board())
		else:
			win_label = "It was a tie game"
	for the_cell in get_tree().get_nodes_in_group("cells"):
		the_cell.clear_focus()
	game_state.turn = TURN_GAME_OVER
	$PlayAgainButton.visible = true
	set_message_1(win_label)
	set_message_2("The game is over. Click the button above to play again.")



#signal functions
func on_cell_focus(cell: Area2D):
	#print("on cell focus  turn: ", game_state.turn, "  cell: ", cell.board_index)
	if cell.board_index == current_cell_focus:
		return

	current_cell_focus = cell.board_index

	var cell_info = game_state.matrix[cell.board_index]
	if game_state.turn == TURN_X_RESOLVE:
		#print("its resolve mode and the key is ", resolve_key, ".")
		var count = 0
		for move in cell_info.moves:
			if move.key() == game_state.resolve_key:
				#print("Found cell to focus ", count)
				cell.set_focus(count, 0)
			count = count + 1
	elif game_state.turn == TURN_XA or game_state.turn == TURN_XB:
		if cell_info.is_quantum():
			cell.set_focus(cell_info.number_of_moves(), 1)
	elif game_state.turn == TURN_OA or game_state.turn == TURN_OB:
		if !GameSingleton.vs_computer:
			if cell_info.is_quantum():
				cell.set_focus(cell_info.number_of_moves(), -1)

func get_gui_cell_by_index(index: int):
	for cell in get_tree().get_nodes_in_group("cells"):
		if cell.board_index == index:
			return cell
	return null

func on_cell_clicked(cell: Area2D):
	if game_state.turn == TURN_X_RESOLVE:
		if game_state.resolve_cells.has(cell.board_index):
			collapse_move(cell.board_index, game_state.resolve_key)
			game_state.turn = TURN_XA
			game_state.increment_turn_number()
			update_gui_after_turn(TURN_X_RESOLVE, TURN_XA, game_state.turn_number)
			set_message_1(msg_you_resolved_conflict)
			set_message_2(msg_you_resolved_conflict_2)
		else:
			print("The cell ", cell.board_index, " is not a resolve cell")
			GameSingleton.display_nodes(game_state.resolve_cells)
		return

	if game_state.turn == TURN_OA or game_state.turn == TURN_OB:
		if !GameSingleton.vs_computer:
			play(cell)
		return
	elif game_state.turn == TURN_O_RESOLVE:
		if !GameSingleton.vs_computer:
			if game_state.resolve_cells.has(cell.board_index):
				collapse_move(cell.board_index, game_state.resolve_key)
				game_state.turn = TURN_OA
				game_state.increment_turn_number()
				update_gui_after_turn(TURN_O_RESOLVE, TURN_XA, game_state.turn_number)
			else:
				print("The cell ", cell.board_index, " is not a resolve cell")
				GameSingleton.display_nodes(game_state.resolve_cells)
		return

	# regular moves
	play(cell)
	
	if game_state.turn == TURN_OA:
		make_computer_move()


func make_computer_move():
	if game_state.turn == TURN_O_RESOLVE:
		print("Its resolve mode, so the computer has to decide resolution")
		#print("Resolve cells:")
		#GameSingleton.display_nodes(game_state.resolve_cells)
		var computer_selected_cell
		if rng.randi_range(0, 9) > 5:
			computer_selected_cell = game_state.resolve_cells[0]
		else:
			computer_selected_cell = game_state.resolve_cells[1]
		print("Computer selected resolve node", computer_selected_cell)
		computer_move_1 = computer_selected_cell
		var timer = get_tree().create_timer(4)
		timer.connect("timeout",self,"delayed_computer_resolve")
	else:
		make_regular_computer_move()

func make_regular_computer_move():
	if GameSingleton.vs_computer and !game_state.is_game_over():
		var computer_indexes = real_agent_moves(game_state)
		print("The computer wants moves ", computer_indexes)
		# If the length is not two, we have a problem
		if computer_indexes.size() != 2:
			print("ERROR computer moves are not size two, they are ", computer_indexes.size())
		else:
			computer_move_1 = computer_indexes[0]
			computer_move_2 = computer_indexes[1]
			var timer_1 = get_tree().create_timer(2)
			timer_1.connect("timeout",self,"delayed_computer_play_1")
			var timer_2 = get_tree().create_timer(4)
			timer_2.connect("timeout",self,"delayed_computer_play_2")
			
func delayed_computer_resolve():
	print("computer resolve ", OS.get_ticks_msec())
	collapse_move(computer_move_1, game_state.resolve_key)
	if game_state.turn != TURN_GAME_OVER:
		game_state.turn = TURN_OA
		game_state.increment_turn_number()
		update_gui_after_turn(TURN_O_RESOLVE, TURN_XA, game_state.turn_number)
		var timer = get_tree().create_timer(3)
		timer.connect("timeout",self,"make_regular_computer_move")

func delayed_computer_play_1():
	#print("computer move (1) ms ", OS.get_ticks_msec())
	var computer_cell: Area2D = get_gui_cell_by_index(computer_move_1)
	play(computer_cell)

func delayed_computer_play_2():
	#print("computer move (2) ms ", OS.get_ticks_msec())
	var computer_cell: Area2D = get_gui_cell_by_index(computer_move_2)
	play(computer_cell)

# Agent methods
func copy_board_with_move(classical_board: Array, move: int, is_player: bool):
	var copy = classical_board.duplicate(true)
	var value_to_set = -1
	if is_player:
		value_to_set = 1
	copy[move] = value_to_set	
	return copy

func min_array(first: Array, second: Array, pos: int) -> Array:
	if first[pos] < second[pos]:
		return first
	else:
		return second

func max_array(first: Array, second: Array, pos: int) -> Array:
	if first[pos] > second[pos]:
		return first
	else:
		return second

func print_stats(start_time: int) -> void:
	stats.elapsed_time = str(OS.get_ticks_msec() - start_time) + " ms"
	stats.nodes = visited_nodes
	visited_nodes = 0
	print("STATS:  ", stats)


func _on_HyperLinkButton_pressed():
	OS.shell_open("https://darren-broemmer.medium.com/")


func _on_PlayAgainButton_pressed():
	current_cell_focus = -1
	$PlayAgainButton.visible = false
	$HistoryText.text = ""
	$TurnPlayerInfo/ValueSprite.texture = player_x
	$LabelFirstMove.visible = true
	$LabelSecondMove.modulate = Color(1,1,1,0.5)
	set_message_1(msg_initial_1)
	set_message_2(msg_initial_2)

	game_state = GameState.new()
	game_state.turn_number = 1
	game_state.turn = TURN_XA
	game_state.matrix = []
	game_state.move_key_list = []
	game_state.create_empty_board()
	for the_cell in get_tree().get_nodes_in_group("cells"):
		the_cell.clear_focus()
		the_cell.unhighlight()
		for qc in the_cell.quantum_cells:
			qc.queue_free()
		the_cell.quantum_cells = []
		the_cell.classical = false
		the_cell.initial_hide()
	update_gui_after_turn(TURN_XA, TURN_XA, 1)
	
#
# Real computer strategy
#
var CORNER_CELLS = [0, 2, 6, 8]
var MIDDLE_CELL = 4
var WIN_L_V = [0, 3, 6]
var WIN_M_V = [1, 4, 7]
var WIN_R_V = [2, 5, 8]
var WIN_H_T = [0, 1, 2]
var WIN_H_M = [3, 4, 5]
var WIN_H_B = [6, 7, 8]
var WIN_D_L = [0, 4, 8]
var WIN_D_R = [2, 4, 7]
var ALL_WINS = [WIN_L_V, WIN_M_V, WIN_R_V, WIN_H_T, WIN_H_M, WIN_H_B, WIN_D_L, WIN_D_R]


func win_check(matrix, player_val, list):
	return win_check_internal(matrix, player_val, list[0], list[1], list[2])

func win_check_internal(matrix, player_val, index1, index2, index3):
	var cell_info_1 = matrix[index1]
	var cell_info_2 = matrix[index2]
	var cell_info_3 = matrix[index3]
	var count = 0
	var check_1 = cell_info_1.has_classical_player(player_val)
	var check_2 = cell_info_2.has_classical_player(player_val)
	var check_3 = cell_info_3.has_classical_player(player_val)
	var still_quantum = []
	if check_1:
		count = count + 2
	else:
		if cell_info_1.is_quantum():
			still_quantum.append(index1)
		if cell_info_1.has_quantum_player(player_val):
			count = count + 1
		
	if check_2:
		count = count + 2
	else:
		if cell_info_2.is_quantum():
			still_quantum.append(index2)
		if cell_info_2.has_quantum_player(player_val):
			count = count + 1

	if check_3:
		count = count + 2
	else:
		if cell_info_3.is_quantum():
			still_quantum.append(index3)
		if cell_info_3.has_quantum_player(player_val):
			count = count + 1

	return [count, still_quantum]	

func is_empty(matrix, index):
	return matrix[index].number_of_moves() == 0

func get_remaining_corners(matrix):
	var list = []
	for corner_index in CORNER_CELLS:
		if is_empty(matrix, corner_index):
			list.append(corner_index)
	return list

func real_agent_moves(game_state):
	game_state.print_matrix()
	var new_moves = []
	if game_state.turn_number == 2:
		# On the first move, grab two open corners
		var open_corners = get_remaining_corners(game_state.matrix)
		if open_corners.size() > 3:
			new_moves.append(open_corners[0])
			new_moves.append(open_corners[3])
		elif open_corners.size() > 2:
			new_moves.append(open_corners[0])
			new_moves.append(open_corners[2])
		elif open_corners.size() > 1:
			new_moves.append(open_corners[0])
			new_moves.append(open_corners[1])
	else:
		# Is there somewhere that X can win right away? Defense first
		# TODO try the search here and see
		# TODO Need to stack rank the options here
		var computer_moves = computer_search(game_state.duplicate())
		print("The computer search moves are ", computer_moves)
		if !computer_moves.empty():
			# TODO just use the first one for right now
			# but maybe we have a better heuristic
			new_moves = computer_moves[0]
		print("------ end search ------")
		#game_state.print_matrix()
		#for possible_win in ALL_WINS:
		#	var check_list = win_check(game_state.matrix, 1, possible_win)
		#	if check_list[0] > 1:
		#		if check_list[1].size() > 1:
		#			print("Gotta block at ", check_list[1][0])
		#			print("Still quantum: ", check_list[1])
		#			if check_list[1].size() > 1:
		#				return [check_list[1][0], check_list[1][1]]
		#			new_moves.append(check_list[1][0])
	#if turn_number == 4:
	#	var open_corners = get_remaining_corners(matrix)
	#	if open_corners.size() > 1:
	#		new_moves.append(open_corners[0])
	#		new_moves.append(open_corners[1])
	#	elif open_corners.size() == 1:
	#		new_moves.append(open_corners[0])

	#	if new_moves.size() < 2 and is_empty(matrix, MIDDLE_CELL):
	#		new_moves.append(MIDDLE_CELL)
	
	# Don't entangle yourself unless about to win
	
	# TODO Prefer at least one empty square

	
	var available_moves = game_state.get_empty_tiles()
	if new_moves.size() < 2:
		if new_moves.size() == 0:
			return [available_moves[0], available_moves[1]]
		elif new_moves.size() == 1:
			new_moves.append(available_moves[0])

	return new_moves

func computer_search(gstate):
	var start_time: = OS.get_ticks_msec()
	# -1 is the computer, so start with that for the search tree
	#   matrix, depth = 0, min, max, player is computer -1
	#var moves = computer_alpha_beta_search(game_state, -INF, INF, false)
	var empty_tiles_array = gstate.get_empty_tiles()
	var possible_move_permutations = []
	print("SEARCH: Empty tiles:  ", empty_tiles_array, " game st: ", TURN_DISPLAY[game_state.turn])
	get_permutations(empty_tiles_array, possible_move_permutations)
	#print("SEARCH: Permutations: ", possible_move_permutations, " game st: ", TURN_DISPLAY[game_state.turn])
	var overall_worst_score = 10
	var overall_worst_moves = []
	var overall_best_score = -10
	var overall_best_moves = []
	for moves in possible_move_permutations:
		print("------ START ", moves, " ------")
		print("SEARCH: Before copy state:  game st: ", TURN_DISPLAY[game_state.turn])
		var copy_state = copy_state_with_moves(gstate, moves)
		var copy_score = copy_state.check_victory()
		# If this move will win the game, do it
		# TODO consider ties also
		# Keep track not just a single best move, but a list
		# then randomly choose between them
		print("SEARCH: (A) Moves ", moves, "  => ", copy_score, "    turn: ", TURN_DISPLAY[copy_state.turn], "   ", copy_state.copy_text)
		if copy_score == -1:
			return [moves]

		# TODO Check if the game is over at this point.
		# If so, we don't need to keep going
		if copy_state.is_game_over():
			continue

		var next_empty_tiles_array = copy_state.get_empty_tiles()
		var next_possible_move_permutations = []
		get_permutations(next_empty_tiles_array, next_possible_move_permutations)
		# TODO use these to see what move we should do
		var worst_move_score = 10
		var worst_moves = null
		var best_move_score = -10
		var best_moves = null
		for next_moves in next_possible_move_permutations:
			visited_nodes += 1
			#if moves == [0,6]:
			#	print("Before state: turn ", TURN_DISPLAY[copy_state.turn])
			#	copy_state.print_matrix()
			var next_copy_state = copy_state_with_moves(copy_state, next_moves)
			var next_copy_score = computer_quantum_score(next_copy_state, next_moves)
			if next_copy_score < worst_move_score:
				worst_move_score = next_copy_score
				worst_moves = next_moves
			if next_copy_score > best_move_score:
				best_move_score = next_copy_score
				best_moves = next_moves
			print("    (B) Computer: ", moves, "  Player: ", next_moves,  " => ", next_copy_score, "     turn: ", TURN_DISPLAY[next_copy_state.turn], "   ", next_copy_state.copy_text)
			#if moves == [0,6]:
			#	print("After state: turn ", TURN_DISPLAY[next_copy_state.turn])
			#	next_copy_state.print_matrix()
		print("Worst move score: ", moves, worst_moves, " => ", worst_move_score)
		print("Best move score:  ", moves, best_moves, " => ", best_move_score)
		if overall_worst_score > worst_move_score:
			overall_worst_score = worst_move_score
			overall_worst_moves = [moves]
		elif overall_worst_score == worst_move_score:
			overall_worst_moves.append(moves)
		if overall_best_score < best_move_score:
			overall_best_score = best_move_score
			overall_best_moves = [moves]
		elif overall_best_score == best_move_score:
			overall_best_moves.append(moves)
		
		#print(" ")
		#copy_state.print_matrix()
		#print("------ END   ", moves, " ------")
	print("Overall worst:  ", overall_worst_moves, " => ", overall_worst_score)
	print("Overall best:   ", overall_best_moves, " => ", overall_best_score)
	var feasible_moves = []
	for a_move in overall_worst_moves:
		if overall_best_moves.find(a_move) == -1:
			feasible_moves.append(a_move)
	print("Feasible moves: ", feasible_moves)
	print_stats(start_time)
	if feasible_moves.empty():
		print("There are no feasible moves")
		if overall_worst_moves.empty():
			print("There are no worst moves")
			return [possible_move_permutations[0]]
		else:
			print("Taking the first of the worst (or best) moves")
			return [overall_worst_moves[0]]
	return feasible_moves
	
func computer_quantum_score(cstate, moves):
	# First get the real score
	var classical_score = cstate.check_victory()
	if classical_score != 0:
		return classical_score * 10
		
	return 0
	

func computer_alpha_beta_search(gstate, alpha, beta, is_max) -> Array:
	# This method returns array [moves_array, utility]
	visited_nodes += 1 
	var empty_tiles_array = gstate.get_empty_tiles()
	#print("cabs ", empty_tiles_array.size())
	if gstate.is_game_over() or empty_tiles_array.size() == 0:
		var utility: = computer_get_utility(gstate)
		return [[-1, -1], utility]
	var best_value: Array
	if is_max:
		# The human player is trying to get the highest value
		best_value = [[-1, -1], -INF]
	else:
		# The computer player is trying to get the lowest value
		best_value = [[-1, -1], INF]

	# TODO what I really want here is each permutation of 2s of the empty tiles
	var possible_move_permutations = []
	print("Perms of ", empty_tiles_array)
	get_permutations(empty_tiles_array, possible_move_permutations)
	print(possible_move_permutations)
	for moves in possible_move_permutations:
		var copy_state = copy_state_with_moves(gstate, moves)
		var value: Array = [moves, computer_alpha_beta_search(copy_state, alpha, beta, not is_max)[1]]
		if is_max:
			best_value = max_array(value, best_value, 1)
			alpha = max(alpha, best_value[1])
			if alpha >= beta:
				break # return [move,alpha]
		else:
			best_value = min_array(value, best_value, 1)
			beta = min(beta, best_value[1])
			if alpha >= beta:
				break # return [move,beta]
	return best_value

func computer_get_utility(gstate) -> int:
	return gstate.get_score() - gstate.get_empty_tiles().size()

func copy_state_with_moves(state, moves):
	var new_state = state.duplicate()
	new_state.simulation = true
	new_state.play_move(moves[0])
	new_state.play_move(moves[1])
	
	if new_state.turn == TURN_X_RESOLVE or new_state.turn == TURN_O_RESOLVE:
		#print("in copy state, we need to resolve from moves ", new_state.resolve_cells)
		var option_one_state = new_state.duplicate()
		var collapse_moves = []
		# TODO not random, make a copy and check the score of both to decide which
		# If its a tie, then I guess random
		# but our quantums scoring should try to do better than that
		option_one_state.play_resolve(option_one_state.resolve_cells[0], option_one_state.resolve_key, collapse_moves)
		var option_one_score = option_one_state.get_score()
		#print("Score for option 1 move ", option_one_state.resolve_cells[0], " is ", option_one_score)
		new_state.copy_text = "   resolve [" + str(option_one_state.resolve_cells[0]) + "] = " + str(option_one_score)

		var option_two_state = new_state.duplicate()
		collapse_moves = []
		# TODO If its a tie, then I guess random
		# but our quantums scoring should try to do better than that
		option_two_state.play_resolve(option_two_state.resolve_cells[1], option_two_state.resolve_key, collapse_moves)
		var option_two_score = option_two_state.get_score()
		#print("Score for option 2 move ", option_two_state.resolve_cells[1], " is ", option_two_score)
		new_state.copy_text = new_state.copy_text + ",  [" + str(option_two_state.resolve_cells[1]) + "] = " + str(option_two_score)

		collapse_moves = []
		if new_state.turn == TURN_X_RESOLVE:
			if option_one_score > option_two_score:
				new_state.play_resolve(new_state.resolve_cells[0], new_state.resolve_key, collapse_moves)
			else:
				new_state.play_resolve(new_state.resolve_cells[1], new_state.resolve_key, collapse_moves)
			new_state.turn = TURN_XA
		else:
			if option_one_score < option_two_score:
				new_state.play_resolve(new_state.resolve_cells[0], new_state.resolve_key, collapse_moves)
			else:
				new_state.play_resolve(new_state.resolve_cells[1], new_state.resolve_key, collapse_moves)
			new_state.turn = TURN_OA
	else:
		new_state.copy_text = ""

	return new_state
	
func get_permutations(source_array, target_array):
	if source_array.size() < 2:
		return
	for i in range (1, source_array.size()):
		target_array.append([source_array[0], source_array[i]])
	source_array.pop_front()
	#print("Size of source array ", source_array.size())
	get_permutations(source_array, target_array)
