# IntroScreen.gd
extends Node

# Escena destino a la que se cambiará
@export var next_scene: PackedScene

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventKey:
		_go_to_next_scene()

func _go_to_next_scene() -> void:
	if next_scene != null:
		get_tree().change_scene_to_packed(next_scene)
	else:
		push_warning("IntroScreen: No se ha asignado la escena destino en el inspector.")
