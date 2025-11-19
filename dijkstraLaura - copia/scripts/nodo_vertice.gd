extends Node2D

@export var nombre: String = "X"

func _ready():
	if has_node("Label"):
		var lbl = $Label
		lbl.text = nombre
		# Usar enteros directamente
		lbl.horizontal_alignment = 1  # 0=Left, 1=Center, 2=Right
		lbl.vertical_alignment = 1    # 0=Top, 1=Center, 2=Bottom
