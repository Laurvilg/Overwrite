extends TextureButton
func _on_pressed() -> void:
	print("Botón presionado")
	get_tree().change_scene_to_file("res://Edmonds-Karp/FlowGraph.tscn")
