extends RefCounted #No es node porque  no va en el árbol de nodos de Godot sino es un objeto lógico
class_name Nodo

var dato: Dictionary
var izq: Nodo = null
var der: Nodo = null

func _init(_dato: Dictionary):
	dato = _dato
