extends RefCounted
class_name Nodo

var dato: Dictionary
var izq: Nodo = null
var der: Nodo = null

func _init(_dato: Dictionary):
	dato = _dato
