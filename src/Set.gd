extends Node

class_name Set

var dict = Dictionary()

func contains(key):
	return dict.has(key)

func add(key):
	dict[key] = true
	
func elements():
	return dict.keys()

func is_empty():
	return dict.size() == 0

func size():
	return dict.size()
