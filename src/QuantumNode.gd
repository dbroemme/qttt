extends Node

class_name QuantumNode

var node_id: int
var board_index: int
var begin_key: String
var end_key: String
var children = []

func is_link(other_node):
	return (end_key == begin_key)
func add_link(other_node):
	children.append(other_node)
func clear_children():
	children = []
func to_display():
	var dis_str = "[" + str(node_id) + "]  Board " + str(board_index) + ":  " + begin_key + " - " + end_key
	for child in children:
		dis_str = dis_str + "  link: " + str(child.node_id)
	return dis_str
