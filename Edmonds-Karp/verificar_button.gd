extends TextureButton


func _on_pressed() -> void:
	print("VerificarButton presionado")

	# El FlowGraph es el nodo padre del botón
	var root = get_parent()

	if root and root.has_method("_on_verify_pressed"):
		root._on_verify_pressed()
	else:
		print("❌ No encontré el método _on_verify_pressed en el padre")
