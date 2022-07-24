extends Node

class_name ComputerStrategy

var matrix_copy

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
