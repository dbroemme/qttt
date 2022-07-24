extends Node

class_name QuantumGraph

var next_id = 1
var node_list = []
var forward_dict = Dictionary()
var backward_dict = Dictionary()	

func add_links(new_node):
	# Setup forward links
	if forward_dict.has(new_node.end_key):
		# TODO ignore anyone in your same board index
		# that includes yourself
		var other_nodes = forward_dict[new_node.end_key]
		for other_node in other_nodes:
			if new_node.board_index != other_node.board_index:
				new_node.add_link(other_node)
				#print("(forward) Adding link from ", new_node.end_key, " to ", other_node.begin_key)
	# Setup backward links
	if backward_dict.has(new_node.begin_key):
		# TODO ignore anyone in your same board index
		# that includes yourself
		var other_nodes = backward_dict[new_node.begin_key]
		for other_node in other_nodes:
			if new_node.board_index != other_node.board_index:
				other_node.add_link(new_node)
				#print("(forward) Adding link from ", new_node.end_key, " to ", other_node.begin_key)
# We need to be able to lookup multiple record by the begin key,
# I guess technically only two (because you are allowed two moves)
# because they could be in different board indexes

func add_nodes(list):
	for node in list:
		add_node(node)

func add_node(new_node):
	new_node.node_id = next_id
	next_id = next_id + 1
	node_list.append(new_node)
	if forward_dict.has(new_node.begin_key):
		forward_dict[new_node.begin_key].append(new_node)
	else:
		var map_value = []
		map_value.append(new_node)
		forward_dict[new_node.begin_key] = map_value
	# Add to backward dictionary
	if backward_dict.has(new_node.end_key):
		backward_dict[new_node.end_key].append(new_node)
	else:
		var map_value = []
		map_value.append(new_node)
		backward_dict[new_node.end_key] = map_value

func size():
	return node_list.size()
	
func to_display():
	var d = ""
	for node in node_list:
		d = d + node.to_display() + "\n"
	return d

func is_cycle(key):
	# A move will be of the form X1.
	# there should be at least two nodes when you
	# look for that. Then start from each of thoese
	# and look for a cycle
	if !forward_dict.has(key):
		#print("INFO: cycle key ", key, " not found in map")
		return QuantumTraverse.new()
	var list = forward_dict[key]
	for node in list:
		#print("Check cycle for ", node.to_display())
		var traversal_data = QuantumTraverse.new()
		traversal_data.add_traversed_node(node)
		is_cycle_for_node(node, traversal_data)
		if traversal_data.is_cycle:
			return traversal_data
	return QuantumTraverse.new()

func is_cycle_for_node(node, traversal_data):
	for child in node.children:
		#print("  child: ", child.to_display())
		traversal_data.is_cycle = traversal_data.have_traversed(child)
		if traversal_data.is_cycle:
			#print("    found a cycle with ", child.begin_key)
			return traversal_data
		traversal_data.add_traversed_node(child)
		return is_cycle_for_node(child, traversal_data)
	return traversal_data

func remove_key(delete_key):
	if forward_dict.has(delete_key):
		var nodes_to_delete = forward_dict[delete_key]
		for other_node in nodes_to_delete:
			var index_to_delete = node_list.find(other_node)
			node_list.remove(index_to_delete)
		forward_dict.erase(delete_key)

	if backward_dict.has(delete_key):
		var nodes_to_delete = backward_dict[delete_key]
		for other_node in nodes_to_delete:
			var index_to_delete = node_list.find(other_node)
			node_list.remove(index_to_delete)
			other_node.clear_children()
		backward_dict.erase(delete_key)

class QuantumTraverse:
	var is_cycle
	var keys: Array
	var list: Array
	func _init():
		is_cycle = false
		keys = []
		list = []
	func add_traversed_node(node):
		keys.append(node.begin_key)
		list.append(node)
	func have_traversed(node):
		if keys.has(node.begin_key):
			return true
		return false
	

