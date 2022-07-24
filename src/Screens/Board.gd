class_name Model
extends Node2D

# These are not used yet
var TURN_XA = 0
var TURN_XB = 1
var TURN_O_RESOLVE = 2
var TURN_OA = 3
var TURN_OB = 4
var TURN_X_RESOLVE = 5
var TURN_GAME_OVER = 6
var turn
var TURN_DISPLAY = ["XA", "XB", "O_RESOLVE", "OA", "OB", "X_RESOLVE", "GAME_OVER"]

onready var cross_quantum: = preload("res://asset/x_small.png")
onready var circle_quantum: = preload("res://asset/o_small.png")
onready var cross_grey: = preload("res://asset/x_grey.png")
onready var circle_grey: = preload("res://asset/o_grey.png")
onready var cross_small: = preload("res://asset/x_grey_small.png")
onready var circle_small: = preload("res://asset/o_grey_small.png")
onready var quantum_cell_scene = preload("res://src/QuantumCell.tscn")

const QuantumGraph = preload("../QuantumGraph.gd")
const QuantumNode = preload("../QuantumNode.gd")
const Set = preload("../Set.gd")
const ComputerStrategy = preload("../ComputerStrategyReal.gd")

var rng = RandomNumberGenerator.new()

class Move:
	var player: int        # 1 = X, -1 = O, 0 = nobody
	var order: int         # the nth move of the game
	var is_classical: int  # 1 = yes, 0 = false
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
	func number_of_moves():
		return moves.size()
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

export(int) var width: = 3
export(int) var height: = 3

var turn_number
var matrix
var quantum_graph
var move_key_list
var resolve_key
var resolve_cells
var resolve_chain
var computer_move_1
var computer_move_2
var computer_strategy

# Old agent variables
var stats = {}
var visited_nodes: = 0


# _init() and _ready()
func _ready():
	$HistoryText.text = ""
	quantum_graph = QuantumGraph.new()
	matrix = []
	move_key_list = []
	turn = TURN_XA
	turn_number = 1
	resolve_cells = Set.new()
	computer_strategy = ComputerStrategy.new()
	for cell in get_tree().get_nodes_in_group("cells"):
		cell.board_index = matrix.size()
		cell.connect("clicked", self, "on_cell_clicked")
		cell.connect("focus", self, "on_cell_focus")
		var new_cell = CellInfo.new()
		new_cell.board_index = matrix.size()
		matrix.append(new_cell)

func _process(delta):
	$ModeValue.text = TURN_DISPLAY[turn]
	$TurnNumber.text = str(turn_number)
	$PlayerLetter.text = player_letter()

func get_classical_board():
	var list = []
	for cell_info in matrix:
		list.append(cell_info.get_value())
	return list

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

func player_letter():
	if turn < TURN_OA:
		return "X"
	if turn < TURN_GAME_OVER:
		return "O"
	return "-"

func player_value():
	if turn < TURN_OA:
		return 1
	return -1

func choice_letter():
	if turn == TURN_XA or turn == TURN_OA:
		return "A"
	if turn == TURN_XB or turn == TURN_OB:
		return "B"
	return "-"

func update_move_history(board_index):
	if is_first_choice():
		$HistoryText.text = $HistoryText.text + player_letter() + str(turn_number) + ": " + str(board_index)
	else:
		$HistoryText.text = $HistoryText.text + ", " + str(board_index) + "\n"

func increment_turn():
	if check_for_collapse():
		if turn == TURN_XA or turn == TURN_XB:
			turn = TURN_O_RESOLVE
			if GameState.vs_computer:
				make_computer_move()
		elif turn == TURN_OA or turn == TURN_OB:
			turn = TURN_X_RESOLVE
		else:
			print("ERROR do not know how move to collapse ", TURN_DISPLAY[turn])
	else:
		if turn == TURN_XA:
			turn = TURN_XB
		elif turn == TURN_XB or turn == TURN_O_RESOLVE:
			turn = TURN_OA
			turn_number = turn_number + 1
		elif turn == TURN_OA:
			turn = TURN_OB
		elif turn == TURN_OB or turn == TURN_X_RESOLVE:
			turn = TURN_XA
			turn_number = turn_number + 1
		else:
			print("ERROR do not know how to increement turn ", TURN_DISPLAY[turn])

# functions
func play(cell: Area2D):
	# Verify there is not already a classical move here
	var cell_info = matrix[cell.board_index]
	if !cell_info.is_quantum():
		print("ERROR cannot make a move in a quantum spot ", cell.board_index)
		return true
	
	var new_move = create_move_instance(player_value())
	if cell_info.has_move(new_move.key()):
		return

	make_move(cell, cell_info, new_move)

	update_move_history(cell.board_index)

	print("--- After play ", turn_number, new_move.key())
	print("Classical board: ", get_classical_board())
	
	increment_turn()


func create_move_instance(player_val):
	var new_move = Move.new()
	new_move.player = player_val
	new_move.order = turn_number
	new_move.is_classical = false
	return new_move
	
func make_move(cell: Area2D, cell_info, new_move):
	var new_quantum_scene = quantum_cell_scene.instance()
	var new_quantum_sign = new_quantum_scene.get_node("Sign")
	var new_quantum_label = new_quantum_scene.get_node("OrderLabel")
	new_quantum_label.text = str(turn_number)
	if is_x_turn():
		new_quantum_sign.visible = true
		new_quantum_sign.texture = cross_quantum
	else:
		new_quantum_sign.visible = true
		new_quantum_sign.texture = circle_quantum

	cell.add_quantum_cell(new_quantum_scene)
	if is_first_choice():
		move_key_list.append(new_move.key())

	# If this is the only cell left, then make it classical and be done
	var empty_tiles = get_empty_tiles(get_classical_board())
	if empty_tiles.size() == 1 and empty_tiles[0] == cell.board_index:
		# This was the last open cell, so it goes to the player whose turn it is
		cell_info.make_classical(new_move.key())
		collapse_move(cell.board_index, new_move.key(), true)
		var result = check_victory(get_classical_board())
		end_game(result)
		return

	var new_nodes = cell_info.add_move(turn_number, player_value())
	quantum_graph.add_nodes(new_nodes)
	for new_node in new_nodes:
		quantum_graph.add_links(new_node)
	$TextLabel.text = quantum_graph.to_display()

func check_for_collapse() -> bool:
	var cycle_display = ""
	for x in move_key_list.size():
		var move_key = move_key_list[-x-1]
		var traverse = quantum_graph.is_cycle(move_key)
		if traverse.is_cycle:
			print(move_key, " caused a cycle")
			$CycleLabel.text = "Need to resolve " + move_key
			$TextLabel.text = quantum_graph.to_display()
			resolve_chain = traverse.list
			print("The resolve chain is ", resolve_chain.size(), " items")
			display_nodes(resolve_chain)
			prepare_for_collapse_move(move_key)
			find_all_cells_that_will_collapse(resolve_chain)
			return true
		else:
			cycle_display = cycle_display + move_key + ": " + str(traverse.is_cycle) + "\n"
	$CycleLabel.text = cycle_display
	$TextLabel.text = quantum_graph.to_display()
	for k in quantum_graph.forward_dict.keys():
		$TextLabel.text = $TextLabel.text + "\n" + k
	return false

func find_all_cells_that_will_collapse(resolve_chain):
	# I don't think it matters which of the two we use
	var board_indexes = Set.new()
	print("find cells that will collapse ", resolve_key)
	recurse_find_all_collapse(resolve_key, Set.new(), board_indexes)
	print("found number ", board_indexes.size())
	for n in board_indexes.elements():
		var the_cell = get_cell_by_index(n)
		the_cell.highlight()

func get_cell_infos_with_move(key):
	var cell_info_with_key = []
	for index in matrix.size():
		var cell_info = matrix[index]
		if cell_info.has_move(key):
			cell_info_with_key.append(cell_info)
	return cell_info_with_key

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
				
func is_move_player(key):
	var player_part_of_str = key.left(1)
	if player_part_of_str == "X":
		return true
	elif player_part_of_str == "O":
		return false

func is_players_resolve_choice():
	var player_part_of_str = resolve_key.left(1)
	if player_part_of_str == "X":
		return false
	elif player_part_of_str == "O":
		return true
	else:
		print("ERROR ", player_part_of_str, " is not X or O")

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
	
func prepare_for_collapse_move(move_key):
	resolve_key = move_key
	resolve_cells = derive_resolve_cells(resolve_key)

	for cell in get_tree().get_nodes_in_group("cells"):
		cell.clear_placeholder()
		if !resolve_cells.contains(cell.board_index):
			cell.modulate = Color(1,1,1,0.5)
		else:
			var cell_info = matrix[cell.board_index]
			cell.modulate_all_but_key(resolve_key, cell_info)

func collapse_move(chosen_board_index, key, is_top_level):
	var cell = get_cell_by_index(chosen_board_index)
	cell.highlight_chosen()
	# The resolve_key move exists in both resolve_cells.elements()
	# but the chosen_board_index was chosen
	# That means the other one probably goes to another move in the chain node
	print("Collapse cell ", chosen_board_index, " for move ", key)
	# Update the data structures
	var cell_info = matrix[chosen_board_index]
	var other_moves = cell_info.make_classical(key)
	quantum_graph.remove_key(key)
	var index_to_delete = move_key_list.find(key)
	move_key_list.remove(index_to_delete)
	var resolved_node = null
	for possible_index in range(0, resolve_chain.size()):
		var possible_node = resolve_chain[possible_index]
		if possible_node.begin_key == key:
			resolved_node = possible_node
	if resolved_node != null:
		resolve_chain.erase(resolved_node)
		print("Removed chain node: ", resolved_node)
	# Update the GUI
	cell.make_classical(is_move_player(key))
	var classical_board = get_classical_board()
	print("Classical board: ", classical_board)

	var win_result = check_victory(classical_board)
	if win_result != 0 or get_empty_tiles(classical_board).size() == 0:
		end_game(win_result)
	else:
		print("Other moves: ", other_moves.size())
		for other_move in other_moves:
			print("  consider ", other_move)
			if move_key_list.has(other_move):
				print("  do need to recon ", other_move)
				var possible_board_indexes = find_cells_with_quantum_move(other_move)
				var next_chosen_board_index = -1
				for i in possible_board_indexes:
					var possible_cell_info = matrix[i]
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
		print("The move list is ", move_key_list, ", mode: ", TURN_DISPLAY[turn])
		var classical_board_2 = get_classical_board()
		var result = check_victory(classical_board_2)
		if result != 0 or get_empty_tiles(classical_board_2).size() == 0:
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
		return winner
	winner = all_have_value(classical_board, 1, 4, 7)		
	if winner != 0:
		return winner
	winner = all_have_value(classical_board, 2, 6, 8)
	if winner != 0:
		return winner
	winner = all_have_value(classical_board, 0, 1, 2)
	if winner != 0:
		return winner
	winner = all_have_value(classical_board, 3, 4, 5)		
	if winner != 0:
		return winner
	winner = all_have_value(classical_board, 6, 7, 8)
	if winner != 0:
		return winner
	winner = all_have_value(classical_board, 0, 4, 8)
	if winner != 0:
		return winner
	return all_have_value(classical_board, 2, 4, 6)

func is_game_over(classical_board) -> bool:
	if get_score(classical_board) != 0 or get_empty_tiles(classical_board).size() == 0:
		return true
	else:
		return false

func get_empty_tiles(classical_board) -> Array:
	var _tiles: Array
	for n in range(0,9):
		if classical_board[n] == 0:
			_tiles.append(n)
	return _tiles

func get_score(classical_board) -> int:
	var score: int
	score = check_victory(classical_board)
	return score * (matrix.size() + 1)

func end_game(value: int) -> void:
	if value == 1:
		$WinLabel.text = "X win!"
	elif value == -1:
		$WinLabel.text = "O win!"
	else: # value == 0
		$WinLabel.text = "Tie game"
	for the_cell in get_tree().get_nodes_in_group("cells"):
		the_cell.clear_focus()
	turn = TURN_GAME_OVER
	#get_tree().change_scene("res://src/Screens/Main.tscn")


#signal functions
func on_cell_focus(cell: Area2D):
	var cell_info = matrix[cell.board_index]
	if turn == TURN_X_RESOLVE:
		#print("its resolve mode and the key is ", resolve_key, ".")
		var count = 0
		for move in cell_info.moves:
			if move.key() == resolve_key:
				#print("Found cell to focus ", count)
				cell.set_focus(count, 0)
			count = count + 1
	elif turn == TURN_XA or turn == TURN_XB:
		if cell_info.is_quantum():
			cell.set_focus(cell_info.number_of_moves(), 1)
	elif turn == TURN_OA or turn == TURN_OB:
		if !GameState.vs_computer:
			if cell_info.is_quantum():
				cell.set_focus(cell_info.number_of_moves(), -1)

func get_cell_by_index(index: int):
	for cell in get_tree().get_nodes_in_group("cells"):
		if cell.board_index == index:
			return cell
	return null

func on_cell_clicked(cell: Area2D):
	if turn == TURN_X_RESOLVE:
		if resolve_cells.contains(cell.board_index):
			collapse_move(cell.board_index, resolve_key, true)
			turn = TURN_XA
		else:
			print("The cell ", cell.board_index, " is not a resolve cell")
			display_nodes(resolve_cells)
		return

	if turn == TURN_OA or turn == TURN_OB:
		if !GameState.vs_computer:
			play(cell)
		return
	elif turn == TURN_O_RESOLVE:
		if !GameState.vs_computer:
			if resolve_cells.contains(cell.board_index):
				collapse_move(cell.board_index, resolve_key, true)
				turn = TURN_OA
			else:
				print("The cell ", cell.board_index, " is not a resolve cell")
				display_nodes(resolve_cells)
		return

	# regular moves
	play(cell)
	
	if turn == TURN_OA:
		make_computer_move()


func make_computer_move():
	if turn == TURN_O_RESOLVE:
		print("Its resolve mode, so the computer has to decide resolution")
		print("Resolve cells:")
		display_nodes(resolve_cells)
		var computer_selected_cell
		if rng.randi_range(0, 9) > 5:
			computer_selected_cell = resolve_cells.elements()[0]
		else:
			computer_selected_cell = resolve_cells.elements()[1]
		print("Computer selected ", computer_selected_cell)
		computer_move_1 = computer_selected_cell
		var timer = get_tree().create_timer(2)
		timer.connect("timeout",self,"delayed_computer_resolve")
	else:
		make_regular_computer_move()

func make_regular_computer_move():
	var classical_board = get_classical_board()
	if GameState.vs_computer and !is_game_over(classical_board):
		var computer_indexes = computer_strategy.fake_agent_moves(matrix, turn_number)
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
	collapse_move(computer_move_1, resolve_key, true)
	increment_turn()
	var timer = get_tree().create_timer(2)
	timer.connect("timeout",self,"make_regular_computer_move")

func delayed_computer_play_1():
	print("computer move (1) ", OS.get_ticks_msec())
	var computer_cell: Area2D = get_cell_by_index(computer_move_1)
	play(computer_cell)

func delayed_computer_play_2():
	print("computer move (2) ", OS.get_ticks_msec())
	var computer_cell: Area2D = get_cell_by_index(computer_move_2)
	play(computer_cell)

func display_nodes(nodes):
	var count = 0
	if nodes is Set:
		for node in nodes.elements():
			if node is String:
				print(count, ") ", node)
			elif node is int:
				print(count, ") ", str(node))
			else:
				print(count, ") ", node.to_display())
			count = count + 1
		return
	for node in nodes:
		if node is String:
			print(count, ") ", node)
		elif node is int:
			print(count, ") ", str(node))
		else:
			print(count, ") ", node.to_display())
		count = count + 1

# Old Agent methods
func agent_move(classical_board: Array, player: bool) -> int:
	var start_time: = OS.get_ticks_msec()
	var move: int = alpha_beta_search(classical_board, get_empty_tiles(classical_board).size(), -INF, INF, player)[0]
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

	for move in get_empty_tiles(classical_board):
		var cell: Area2D = get_cell_by_index(move)
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
	#print("STATS:\n", stats)
