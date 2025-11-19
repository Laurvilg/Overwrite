extends Node2D

func _on_texture_button_pressed() -> void:
	AudioManager.SFXPlayer.stream = preload("res://inicio/audio/button-305770.mp3")
	AudioManager.SFXPlayer.play()
	get_tree().change_scene_to_file("res://dijkstraLaura - copia/dijkstra.tscn")
