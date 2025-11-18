extends Node

class_name FlowGraph

var nodes = ["S", "A", "B", "C", "D", "E", "F", "T"]

var edges = {
	"S": [{"to": "A", "capacity": 12}, {"to": "B", "capacity": 10}, {"to": "C", "capacity": 4}],
	"A": [{"to": "B", "capacity": 3}, {"to": "D", "capacity": 7}, {"to": "E", "capacity": 5}],
	"B": [{"to": "C", "capacity": 2}, {"to": "D", "capacity": 10}],
	"C": [{"to": "E", "capacity": 8}],
	"D": [{"to": "F", "capacity": 10}, {"to": "T", "capacity": 5}],
	"E": [{"to": "D", "capacity": 3}, {"to": "F", "capacity": 7}, {"to": "T", "capacity": 8}],
	"F": [{"to": "T", "capacity": 15}]
}

func get_neighbors(node: String) -> Array:
	return edges.get(node, [])
