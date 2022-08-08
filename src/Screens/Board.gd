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

var message_1 = ""
var message_2 = ""
var current_cell_focus = -1

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

const QuantumGraph = preload("../QuantumGraph.gd")
const QuantumNode = preload("../QuantumNode.gd")
const Set = preload("../Set.gd")

var rng = RandomNumberGenerator.new()
var msg_initial_1 = """
You are X, and you get to go first.
Click in one of the nine spaces to make your first quantum move.

Each player makes two quantum moves on each turn. Think of these as multiple potential games being played at once.
"""
var msg_initial_2 = "Each of your two moves will have a numeric subscript. This is the turn number of those moves."
var msg_you_made_first_move = """
Great! Now go ahead and choose a second space for your other quantum move of this turn.
"""
var msg_not_real = "At this point, neither of your moves is \"real\", or what we call a classical move. Only classical moves can win the game."
var msg_computer_first_move = "The computer made its first quantum move, now for the second ..."
var msg_computer_second_move = "The computer finished its quantum moves for that round. Now it is your turn again."
var msg_your_turn = "Go ahead and click in a non-classical space to make your first quantum move of the turn."
var msg_you_get_to_resolve = """
The computer chose a move that resulted in a conflict, so now some of the quantum moves need to be resolved into real (or classical) moves.
Some of the earlier possible games are no longer possible, so one resolved space often leads to other spaces being resolved.
"""
var msg_you_get_to_resolve_2 = """
You get to choose which of the conflict spots the computer should take. Click on a highlighted space to choose.
"""

var msg_computer_get_to_resolve = """
You chose a move that resulted in a conflict, so now some of the quantum moves need to be resolved into real (or classical) moves.

The computer gets to choose which of the conflict spots you should take.
"""
var msg_computer_get_to_resolve_2 = ""

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
		var new_nodes = []
		for existing_move in moves:
			# First create the forward direction
			var forward_node = QuantumNode.new()
			forward_node.board_index = board_index
			forward_node.begin_key = new_move.key()
			forward_node.end_key = existing_move.key()
			new_nodes.append(forward_node)
			# Then create the backwards direction
			var backward_node = QuantumNode.new()
			backward_node.board_index = board_index
			backward_node.begin_key = existing_move.key()
			backward_node.end_key = new_move.key()
			new_nodes.append(backward_node)
		moves.append(new_move)
		return new_nodes
		
class GameState:
	var turn_number
	var turn
	var matrix
	var quantum_graph
	var move_key_list
	var resolve_key
	var resolve_cells
	var resolve_chain
	var board_indexes_that_will_collapse
	var TURN_XA = 0
	var TURN_XB = 1
	var TURN_O_RESOLVE = 2
	var TURN_OA = 3
	var TURN_OB = 4
	var TURN_X_RESOLVE = 5
	var TURN_GAME_OVER = 6
	var TURN_DISPLAY = ["XA", "XB", "O_RESOLVE", "OA", "OB", "X_RESOLVE", "GAME_OVER"]

	func _init(turn_num, turn_state, matrix_copy, graph, move_list):
		self.turn_number = turn_num
		self.turn = turn_state
		self.matrix = matrix_copy
		self.quantum_graph = graph
		self.move_key_list = move_list
		self.resolve_key = null
		self.resolve_cells = Set.new()
		self.resolve_chain = []
		
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

	func get_classical_board():
		var list = []
		for cell_info in matrix:
			list.append(cell_info.get_value())
		return list

	func derive_resolve_cells(key):
		# Get the two tiles where this move exists
		var nodes_with_key = quantum_graph.forward_dict[key]
		var cell_set = Set.new()
		for node_with_key in nodes_with_key:
			cell_set.add(node_with_key.board_index)
		return cell_set

	func find_cells_with_quantum_move(key):
		var result = []
		for index in matrix.size():
			var cell_info = matrix[index]
			if cell_info.has_move(key):
				result.append(index)
		return result

	func find_all_cells_that_will_collapse(resolve_chain):
		# I don't think it matters which of the two we use
		board_indexes_that_will_collapse = Set.new()
		print("find cells that will collapse ", resolve_key)
		recurse_find_all_collapse(resolve_key, Set.new(), board_indexes_that_will_collapse)
		print("found number ", board_indexes_that_will_collapse.size())

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
		var cycle_display = ""
		for x in move_key_list.size():
			var move_key = move_key_list[-x-1]
			var traverse = quantum_graph.is_cycle(move_key)
			if traverse.is_cycle:
				print(move_key, " caused a cycle. Need to resolve")
				#$TextLabel.text = quantum_graph.to_display()
				resolve_chain = traverse.list
				print("The resolve chain is ", resolve_chain.size(), " items")
				GameSingleton.display_nodes(resolve_chain)
				prepare_for_collapse_move(move_key)
				find_all_cells_that_will_collapse(resolve_chain)
				return true
			else:
				cycle_display = cycle_display + move_key + ": " + str(traverse.is_cycle) + "\n"
		print(cycle_display)
		#$TextLabel.text = game_state.quantum_graph.to_display()
		#for k in game_state.quantum_graph.forward_dict.keys():
		#	$TextLabel.text = $TextLabel.text + "\n" + k
		return false

	func prepare_for_collapse_move(move_key):
		resolve_key = move_key
		resolve_cells = derive_resolve_cells(resolve_key)

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
	message_1 = text_value
	#$MessagesLabel1.bbcode_text = "[center]" + message_1 + "[center]"	
	$MessagesLabel1.text = message_1	

func set_message_2(text_value):
	message_2 = text_value
	#$MessagesLabel2.bbcode_text = "[center]" + message_2 + "[center]"	
	$MessagesLabel2.text = message_2
	
func set_message_image(img):
	$HelpImage1.texture = img
	
func set_message_image_invisible():
	$HelpImage1.visible = false
	
# _init() and _ready()
func _ready():
	game_state = GameState.new(1, TURN_XA, [], QuantumGraph.new(), [])
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
	set_message_1(msg_initial_1)
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

func player_letter(state):
	if state.turn < TURN_OA:
		return "X"
	if state.turn < TURN_GAME_OVER:
		return "O"
	return "-"

func player_value(state):
	if state.turn < TURN_OA:
		return 1
	return -1

func increment_turn():
	current_cell_focus = -1
	if game_state.check_for_collapse():
		set_message_image(help_image_empty)
		set_message_image_invisible()
		$AudioPlayer.stream = resolve_sound
		$AudioPlayer.play()
		$BoardCamera.add_trauma(0.5)
		if game_state.turn == TURN_XA or game_state.turn == TURN_XB:
			game_state.turn = TURN_O_RESOLVE
			set_message_1(msg_computer_get_to_resolve)
			set_message_2(msg_computer_get_to_resolve_2)
			if GameSingleton.vs_computer:
				make_computer_move()
		elif game_state.turn == TURN_OA or game_state.turn == TURN_OB:
			game_state.turn = TURN_X_RESOLVE
			set_message_1(msg_you_get_to_resolve)
			set_message_2(msg_you_get_to_resolve_2)
		else:
			print("ERROR do not know how move to collapse ", TURN_DISPLAY[game_state.turn])
	else:
		if game_state.turn == TURN_XA:
			game_state.turn = TURN_XB
			$AudioPlayer.stream = first_move_sound
			$AudioPlayer.play()
			if game_state.turn_number == 1:
				set_message_1(msg_you_made_first_move)
				set_message_2(msg_not_real)
			else:
				set_message_image(help_image_empty)
				set_message_image_invisible()
				set_message_2("")
				set_message_1(msg_you_made_first_move)
		elif game_state.turn == TURN_XB or game_state.turn == TURN_O_RESOLVE:
			if game_state.turn == TURN_O_RESOLVE:
				set_message_2("The computer chose a resolution.")				
			else:
				set_message_1("Now it is the computers turn")
				set_message_2("")

			game_state.turn = TURN_OA
			game_state.turn_number = game_state.turn_number + 1
			$AudioPlayer.stream = second_move_sound
			$AudioPlayer.play()
			set_message_image(help_image_empty)
			set_message_image_invisible()
		elif game_state.turn == TURN_OA:
			$AudioPlayer.stream = computer_first_move_sound
			$AudioPlayer.play()
			game_state.turn = TURN_OB
			set_message_2("")
			set_message_1(msg_computer_first_move)
		elif game_state.turn == TURN_OB or game_state.turn == TURN_X_RESOLVE:
			game_state.turn = TURN_XA
			game_state.turn_number = game_state.turn_number + 1
			$AudioPlayer.stream = computer_second_move_sound
			$AudioPlayer.play()
			set_message_1(msg_computer_second_move)
			set_message_2(msg_your_turn)
		elif game_state.turn == TURN_GAME_OVER:
			set_message_1("The game is over.")
			set_message_2($WinLabel.text)
		else:
			print("ERROR do not know how to increment turn ", TURN_DISPLAY[game_state.turn])
	# Update the display
	#$ModeValue.text = TURN_DISPLAY[game_state.turn]
	$TurnNumberInfo/ValueSprite.texture = NUMBER_IMAGES[game_state.turn_number]
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
	# Set the messages accordingly

func play(cell: Area2D):
	# Verify there is not already a classical move here
	var cell_info = game_state.matrix[cell.board_index]
	if !cell_info.is_quantum():
		print("ERROR cannot make a move in classical cell ", cell.board_index)
		return true
	
	var new_move = create_move_instance(player_value(game_state))
	if cell_info.has_move(new_move.key()):
		return

	make_move(cell, cell_info, new_move)

	print("--- After play ", game_state.turn_number, "  key: ", new_move.key())
	print("Classical board: ", game_state.get_classical_board())
	
	increment_turn()


func create_move_instance(player_val):
	var new_move = Move.new()
	new_move.player = player_val
	new_move.order = game_state.turn_number
	new_move.is_classical = false
	return new_move
	
func make_move(cell: Area2D, cell_info, new_move):
	var new_quantum_scene = quantum_cell_scene.instance()
	var new_quantum_sign = new_quantum_scene.get_node("Sign")
	var new_quantum_label = new_quantum_scene.get_node("OrderLabel")
	new_quantum_label.text = str(game_state.turn_number)
	if game_state.is_x_turn():
		new_quantum_sign.visible = true
		new_quantum_sign.texture = cross_quantum
	else:
		new_quantum_sign.visible = true
		new_quantum_sign.texture = circle_quantum

	cell.add_quantum_cell(new_quantum_scene, game_state.is_x_turn())
	if game_state.is_first_choice():
		game_state.move_key_list.append(new_move.key())

	# If this is the only cell left, then make it classical and be done
	var empty_tiles = game_state.get_empty_tiles()
	if empty_tiles.size() == 1 and empty_tiles[0] == cell.board_index:
		# This was the last open cell, so it goes to the player whose turn it is
		cell_info.make_classical(new_move.key())
		collapse_move(cell.board_index, new_move.key(), true)
		var result = check_victory(game_state.get_classical_board())
		end_game(result)
		return

	var new_nodes = cell_info.add_move(game_state.turn_number, player_value(game_state))
	game_state.quantum_graph.add_nodes(new_nodes)
	for new_node in new_nodes:
		game_state.quantum_graph.add_links(new_node)
	#$TextLabel.text = game_state.quantum_graph.to_display()

func is_move_player(key):
	var player_part_of_str = key.left(1)
	if player_part_of_str == "X":
		return true
	elif player_part_of_str == "O":
		return false



func collapse_move(chosen_board_index, key, is_top_level):
	var cell = get_gui_cell_by_index(chosen_board_index)
	cell.highlight_chosen()
	# The resolve_key move exists in both resolve_cells.elements()
	# but the chosen_board_index was chosen
	# That means the other one probably goes to another move in the chain node
	print("Collapse cell ", chosen_board_index, " for move ", key)
	# Update the data structures
	var cell_info = game_state.matrix[chosen_board_index]
	var other_moves = cell_info.make_classical(key)
	game_state.quantum_graph.remove_key(key)
	var index_to_delete = game_state.move_key_list.find(key)
	game_state.move_key_list.remove(index_to_delete)
	var resolved_node = null
	for possible_index in range(0, game_state.resolve_chain.size()):
		var possible_node = game_state.resolve_chain[possible_index]
		if possible_node.begin_key == key:
			resolved_node = possible_node
	if resolved_node != null:
		game_state.resolve_chain.erase(resolved_node)
		print("Removed chain node: ", resolved_node)
	# Update the GUI
	cell.make_classical(is_move_player(key))
	var classical_board = game_state.get_classical_board()
	print("Classical board: ", classical_board)

	var win_result = check_victory(classical_board)
	if win_result != 0 or game_state.get_empty_tiles().size() == 0:
		end_game(win_result)
	else:
		print("Other moves: ", other_moves.size())
		for other_move in other_moves:
			print("  consider ", other_move)
			if game_state.move_key_list.has(other_move):
				print("  do need to recon ", other_move)
				var possible_board_indexes = game_state.find_cells_with_quantum_move(other_move)
				var next_chosen_board_index = -1
				for i in possible_board_indexes:
					var possible_cell_info = game_state.matrix[i]
					print("   check if quantum: ", i)
					if possible_cell_info.is_quantum():
						next_chosen_board_index = i
				if next_chosen_board_index == -1:
					print("ERROR we were never able to resolve ", other_move)
				else:
					collapse_move(next_chosen_board_index, other_move, false)

	if is_top_level:
		for the_cell in get_tree().get_nodes_in_group("cells"):
			the_cell.clear_focus()
			the_cell.unhighlight()
		print("The move list is ", game_state.move_key_list, ", mode: ", TURN_DISPLAY[game_state.turn])
		var classical_board_2 = game_state.get_classical_board()
		var result = check_victory(classical_board_2)
		if result != 0 or get_empty_tiles_for_classical(classical_board_2).size() == 0:
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

func check_victory(classical_board) -> int:
	var winner = 0
	winner = all_have_value(classical_board, 0, 3, 6)
	if winner != 0:
		$Cell1/WinHighlight.visible = true
		$Cell4/WinHighlight.visible = true
		$Cell7/WinHighlight.visible = true
		return winner
	winner = all_have_value(classical_board, 1, 4, 7)		
	if winner != 0:
		$Cell2/WinHighlight.visible = true
		$Cell5/WinHighlight.visible = true
		$Cell8/WinHighlight.visible = true
		return winner
	winner = all_have_value(classical_board, 2, 5, 8)
	if winner != 0:
		$Cell3/WinHighlight.visible = true
		$Cell6/WinHighlight.visible = true
		$Cell9/WinHighlight.visible = true
		return winner
	winner = all_have_value(classical_board, 0, 1, 2)
	if winner != 0:
		$Cell1/WinHighlight.visible = true
		$Cell2/WinHighlight.visible = true
		$Cell3/WinHighlight.visible = true
		return winner
	winner = all_have_value(classical_board, 3, 4, 5)		
	if winner != 0:
		$Cell4/WinHighlight.visible = true
		$Cell5/WinHighlight.visible = true
		$Cell6/WinHighlight.visible = true
		return winner
	winner = all_have_value(classical_board, 6, 7, 8)
	if winner != 0:
		$Cell7/WinHighlight.visible = true
		$Cell8/WinHighlight.visible = true
		$Cell9/WinHighlight.visible = true
		return winner
	winner = all_have_value(classical_board, 0, 4, 8)
	if winner != 0:
		$Cell1/WinHighlight.visible = true
		$Cell5/WinHighlight.visible = true
		$Cell9/WinHighlight.visible = true
		return winner
	winner = all_have_value(classical_board, 2, 4, 6)
	if winner != 0:
		$Cell3/WinHighlight.visible = true
		$Cell5/WinHighlight.visible = true
		$Cell7/WinHighlight.visible = true
	return winner

func is_game_over(classical_board) -> bool:
	if get_score(classical_board) != 0 or game_state.get_empty_tiles().size() == 0:
		return true
	else:
		return false

func get_score(classical_board) -> int:
	var score: int
	score = check_victory(classical_board)
	return score * (game_state.matrix.size() + 1)

func end_game(value: int) -> void:
	if value == 1:
		$WinLabel.text = "X has won the game!"
	elif value == -1:
		$WinLabel.text = "O has won the game!!"
	else: # value == 0
		$WinLabel.text = "It was a tie game"
	for the_cell in get_tree().get_nodes_in_group("cells"):
		the_cell.clear_focus()
	game_state.turn = TURN_GAME_OVER
	$PlayAgainButton.visible = true


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
		if game_state.resolve_cells.contains(cell.board_index):
			collapse_move(cell.board_index, game_state.resolve_key, true)
			increment_turn()
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
			if game_state.resolve_cells.contains(cell.board_index):
				collapse_move(cell.board_index, game_state.resolve_key, true)
				game_state.turn = TURN_OA
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
		print("Resolve cells:")
		GameSingleton.display_nodes(game_state.resolve_cells)
		var computer_selected_cell
		if rng.randi_range(0, 9) > 5:
			computer_selected_cell = game_state.resolve_cells.elements()[0]
		else:
			computer_selected_cell = game_state.resolve_cells.elements()[1]
		print("Computer selected ", computer_selected_cell)
		computer_move_1 = computer_selected_cell
		var timer = get_tree().create_timer(4)
		timer.connect("timeout",self,"delayed_computer_resolve")
	else:
		make_regular_computer_move()

func make_regular_computer_move():
	var classical_board = game_state.get_classical_board()
	if GameSingleton.vs_computer and !is_game_over(classical_board):
		var computer_indexes = real_agent_moves(game_state.matrix, game_state.turn_number)
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
	collapse_move(computer_move_1, game_state.resolve_key, true)
	increment_turn()
	var timer = get_tree().create_timer(3)
	timer.connect("timeout",self,"make_regular_computer_move")

func delayed_computer_play_1():
	print("computer move (1) ms ", OS.get_ticks_msec())
	var computer_cell: Area2D = get_gui_cell_by_index(computer_move_1)
	play(computer_cell)

func delayed_computer_play_2():
	print("computer move (2) ms ", OS.get_ticks_msec())
	var computer_cell: Area2D = get_gui_cell_by_index(computer_move_2)
	play(computer_cell)

# Old Agent methods
func agent_move(classical_board: Array, player: bool) -> int:
	var start_time: = OS.get_ticks_msec()
	var move: int = alpha_beta_search(classical_board, game_state.get_empty_tiles().size(), -INF, INF, player)[0]
	print_stats(start_time)
	return move

func copy_board_with_move(classical_board: Array, move: int, is_player: bool):
	var copy = classical_board.duplicate(true)
	var value_to_set = -1
	if is_player:
		value_to_set = 1
	copy[move] = value_to_set	
	return copy

func alpha_beta_search(classical_board: Array, depth: int, alpha, beta, is_max: bool) -> Array:
	#print("abs ", depth)
	visited_nodes += 1
	if is_game_over(classical_board) or depth == 0:
		var utility: = get_utility(classical_board, depth)
		return [-1, utility]
	var best_value: Array
	if is_max:
		best_value = [-1, -INF]
	else:
		best_value = [-1, INF]

	for move in get_empty_tiles_for_classical(classical_board):
		var cell: Area2D = get_gui_cell_by_index(move)
		# TODO This needs to be, make a copy of the board with the given move applied
		var board_copy = copy_board_with_move(classical_board, move, is_max)
		var value: Array = [move, alpha_beta_search(board_copy, depth-1, alpha, beta, not is_max)[1]]
		# Not needed because we are not modifying the actual game board
		#state.undo_move(cell)
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

func get_utility(classical_board: Array, depth: int) -> int:
	return get_score(classical_board) - depth

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
	print("STATS:\n", stats)


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

	game_state = GameState.new(1, TURN_XA, [], QuantumGraph.new(), [])
	game_state.create_empty_board()

#
# Real computer strategy
#
var matrix_copy
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
		still_quantum.append(index1)
		if cell_info_1.has_quantum_player(player_val):
			count = count + 1
		
	if check_2:
		count = count + 2
	else:
		still_quantum.append(index2)
		if cell_info_2.has_quantum_player(player_val):
			count = count + 1

	if check_3:
		count = count + 2
	else:
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

func real_agent_moves(matrix, turn_number):
	print_matrix(matrix)
	var new_moves = []
	if turn_number == 2:
		# On the first move, grab two open corners
		var open_corners = get_remaining_corners(matrix)
		if open_corners.size() > 2:
			new_moves.append(open_corners[0])
			new_moves.append(open_corners[2])
		elif open_corners.size() > 1:
			new_moves.append(open_corners[0])
			new_moves.append(open_corners[1])
	else:
		# Is there somewhere that X can win right away? Defense first
		for possible_win in ALL_WINS:
			var check_list = win_check(matrix, 1, possible_win)
			if check_list[0] > 1:
				print("Gotta block at ", check_list[1][0])
				print("Still quantum: ", check_list[1])
				if check_list[1].size() > 1:
					return [check_list[1][0], check_list[1][1]]
				new_moves.append(check_list[1][0])
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
	#var computer_moves = computer_search(matrix)
	#print("The computer search moves are ", computer_moves)
	
	var available_moves = game_state.get_empty_tiles()
	if new_moves.size() < 2:
		if new_moves.size() == 0:
			return [available_moves[0], available_moves[1]]
		elif new_moves.size() == 1:
			new_moves.append(available_moves[0])

	return new_moves

func copy_matrix_with_moves(matrix, moves, player_val, turn_number):
	var matrix_copy = copy_matrix(matrix)
	play_in_matrix(matrix_copy, moves[0], player_val, turn_number)
	play_in_matrix(matrix_copy, moves[1], player_val, turn_number)
	# TODO perform any resolutions
	# Can we encapsulate that logic
	return matrix_copy

func play_in_matrix(matrix, move_index, player_val, turn_number):
	var cell_info = matrix_copy[move_index]
	if !cell_info.is_quantum():
		print("ERROR computer strategy cannot make a move in classical cell ", move_index)
		return
	var new_move = computer_create_move_instance(player_val, turn_number)
	if cell_info.has_move(new_move.key()):
		print("ERROR computer strategy trying to make a duplicate move in cell ", move_index)		
		return

func computer_search(matrix):
	var start_time: = OS.get_ticks_msec()
	# -1 is the computer, so start with that for the search tree
	#   matrix, depth = 0, min, max, player is computer -1
	var moves = computer_alpha_beta_search(matrix, 0, -INF, INF, -1)
	print_stats(start_time)
	return moves

func computer_alpha_beta_search(matrix, depth, alpha, beta, player) -> Array:
	print("cabs ", depth)
	visited_nodes += 1
	var classical_board = computer_get_classical_board(matrix_copy)
	if is_game_over(classical_board) or depth == 0:
		var utility: = computer_get_utility(classical_board, depth)
		return [-1, utility]
	var best_value: Array
	if player == 1:
		# The human player is trying to get the highest value
		best_value = [-1, -INF]
	else:
		# The computer player is trying to get the lowest value
		best_value = [-1, INF]

	#for move in get_empty_tiles(classical_board):
	#	var cell: Area2D = get_cell_by_index(move)
		# TODO This needs to be, make a copy of the board with the given move applied
	#	var board_copy = copy_board_with_move(classical_board, move, is_max)
	#	var value: Array = [move, alpha_beta_search(board_copy, depth-1, alpha, beta, not is_max)[1]]
		# Not needed because we are not modifying the actual game board
		#state.undo_move(cell)
	#	if is_max:
	#		best_value = max_array(value, best_value, 1)
	#		alpha = max(alpha, best_value[1])
	#		if alpha >= beta:
	#			break # return [move,alpha]
	#	else:
	#		best_value = min_array(value, best_value, 1)
	#		beta = min(beta, best_value[1])
	#		if alpha >= beta:
	#			break # return [move,beta]
	return best_value

func computer_get_utility(classical_board: Array, depth: int) -> int:
	return get_score(classical_board) - depth

#
# Many of these are essentially copies of methods from Board.gd
# We should really encapsulate this better
#
func copy_matrix(matrix):
	var new_matrix = []
	for existing_cell_info in matrix:
		new_matrix.append(existing_cell_info.duplicate())
	return new_matrix

func computer_get_classical_board(matrix_copy):
	var list = []
	for cell_info in matrix_copy:
		list.append(cell_info.get_value())
	return list

func computer_create_move_instance(player_val, turn_number):
	var new_move = Move.new()
	new_move.player = player_val
	new_move.order = turn_number
	new_move.is_classical = false
	return new_move

func print_matrix(matrix):
	print(pad(matrix[0].to_display()), "  |  ", pad(matrix[1].to_display()), "  |  ", pad(matrix[2].to_display()))
	print("----------------  |  ----------------  |  ----------------")
	print(pad(matrix[3].to_display()), "  |  ", pad(matrix[4].to_display()), "  |  ", pad(matrix[5].to_display()))
	print("----------------  |  ----------------  |  ----------------")
	print(pad(matrix[6].to_display()), "  |  ", pad(matrix[7].to_display()), "  |  ", pad(matrix[8].to_display()))

func pad(val):
	return "%16s" % val
	
