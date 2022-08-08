extends Node

var vs_computer

func _ready():
	vs_computer = true
	
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
