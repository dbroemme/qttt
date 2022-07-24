extends Node

class_name Set

var dict = Dictionary()

func contains(key):
	return dict.has(key)

func add(key):
	dict[key] = true
	
func elements():
	return dict.keys()
	
func size():
	return dict.size()
