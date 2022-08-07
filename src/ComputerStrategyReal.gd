extends Node

class_name ComputerStrategy

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
	matrix_copy = matrix
	var new_moves = []
	var available_moves = get_empty_tiles(get_classical_board())
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
	
	if new_moves.size() < 2:
		if new_moves.size() == 0:
			return [available_moves[0], available_moves[1]]
		elif new_moves.size() == 1:
			new_moves.append(available_moves[0])

	return new_moves
	
func fake_agent_moves(matrix, turn_number):
	matrix_copy = matrix
	var available_moves = get_empty_tiles(get_classical_board())
	if turn_number == 2:
		if 0 in available_moves and 1 in available_moves:
			return [0, 1]
	elif turn_number == 4:
		if 1 in available_moves and 2 in available_moves:
			return [1, 2]
	#elif turn_number == 6:
	#	if 7 in available_moves and 8 in available_moves:
	#		return [7, 8]
	if available_moves.size() == 1:
		return [available_moves[0], available_moves[0]]
	return [available_moves[0], available_moves[1]]

func get_classical_board():
	var list = []
	for cell_info in matrix_copy:
		list.append(cell_info.get_value())
	return list
	
func get_empty_tiles(classical_board) -> Array:
	var _tiles: Array
	for n in range(0,9):
		if classical_board[n] == 0:
			_tiles.append(n)
	return _tiles
