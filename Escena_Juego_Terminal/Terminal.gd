extends Control
class_name Terminal

signal terminal_command_entered(cmd)

@export var output_path: NodePath = NodePath("VBoxContainer/OutputScroll/Output")
@export var input_path: NodePath = NodePath("VBoxContainer/Input")

var _output_node: Node = null
var _input_node: Node = null
var _listeners: Array = [] # elementos: {obj, method_name}

func _ready() -> void:
	# Resolver nodo de salida (Output)
	if output_path != NodePath("") and has_node(str(output_path)):
		_output_node = get_node_or_null(str(output_path))
	else:
		# Compatibilidad Godot 4
		_output_node = get_tree().get_root().find_child("Output", true, false)

	# Resolver nodo de entrada (LineEdit)
	if input_path != NodePath("") and has_node(str(input_path)):
		_input_node = get_node_or_null(str(input_path))
	else:
		# Compatibilidad Godot 4
		_input_node = get_tree().get_root().find_child("Input", true, false)

	# Asegurar foco y conectar la señal adecuada
	if _input_node != null:
		if _input_node.has_method("grab_focus"):
			_input_node.grab_focus()
		if _input_node.has_signal("text_submitted"):
			if not _input_node.is_connected("text_submitted", Callable(self, "_on_input_submitted")):
				_input_node.connect("text_submitted", Callable(self, "_on_input_submitted"))
		elif _input_node.has_signal("text_entered"):
			if not _input_node.is_connected("text_entered", Callable(self, "_on_input_entered")):
				_input_node.connect("text_entered", Callable(self, "_on_input_entered"))

# Añadir listener que recibe llamadas cuando se envía un comando.
func add_command_listener(obj: Object, method_name: String) -> bool:
	if obj == null:
		return false
	if not obj.has_method(method_name):
		return false
	_listeners.append({"obj": obj, "method": method_name})
	return true

func remove_command_listener(obj: Object, method_name: String) -> void:
	for i in range(_listeners.size()-1, -1, -1):
		var it = _listeners[i]
		if it["obj"] == obj and it["method"] == method_name:
			_listeners.remove_at(i)

# Método para que otros scripts muestren texto en la Terminal UI
func append_output(text: String) -> void:
	if _output_node == null:
		print(text)
		return
	if _output_node.has_method("append_bbcode"):
		_output_node.append_bbcode(str(text) + "\n")
	elif _output_node.has_method("add_text"):
		_output_node.add_text(str(text) + "\n")
	else:
		if _output_node.has_method("get_text") and _output_node.has_method("set_text"):
			var cur = str(_output_node.get("text"))
			_output_node.set("text", cur + str(text) + "\n")
		else:
			print(text)
	
	# Auto-scroll
	var sc = _output_node.get_parent()
	if sc != null and sc is ScrollContainer:
		if sc.has_method("get_v_scrollbar"):
			var vs = sc.get_v_scrollbar()
			if vs != null:
				await get_tree().process_frame # Esperar a que la UI se actualice
				sc.scroll_vertical = vs.max_value

# Conexión interna al LineEdit text_submitted
func _on_input_submitted(new_text: String) -> void:
	_emit_command(str(new_text))
	if _input_node != null:
		if _input_node.has_method("clear"):
			_input_node.clear()
		else:
			_input_node.set("text", "")

func _on_input_entered(text: String) -> void:
	_emit_command(str(text))
	if _input_node != null:
		if _input_node.has_method("clear"):
			_input_node.clear()
		else:
			_input_node.set("text", "")

func _emit_command(cmd: String) -> void:
	# Muestra el comando escrito en la pantalla
	append_output("> " + cmd)
	emit_signal("terminal_command_entered", cmd)
	for it in _listeners:
		var obj = it.get("obj", null)
		var method_name = it.get("method", "")
		if obj != null and method_name != "" and obj.has_method(method_name):
			obj.call(method_name, cmd)
