
extends Node2D

@export var nombre: String = ""

func _ready():
	$Label.text = nombre
