extends Control
class_name Terminal

signal terminal_command_entered(cmd)

# Rutas a los nodos de la UI (RichTextLabel y LineEdit)
@export var output_path: NodePath = NodePath("VBoxContainer/OutputScroll/Output")
@export var input_path: NodePath = NodePath("VBoxContainer/Input")

var _output_node: Node = null
var _input_node: Node = null
var _listeners: Array = [] 

func _ready() -> void:
	# Obtener referencias a nodos
	if has_node(str(output_path)):
		_output_node = get_node(str(output_path))
	if has_node(str(input_path)):
		_input_node = get_node(str(input_path))
	
	# Configurar input
	if _input_node:
		_input_node.grab_focus()
		# Conectar señal text_submitted (Godot 4)
		if not _input_node.is_connected("text_submitted", Callable(self, "_on_input_submitted")):
			_input_node.connect("text_submitted", Callable(self, "_on_input_submitted"))

# API para otros scripts
func add_command_listener(obj: Object, method_name: String) -> bool:
	if not obj.has_method(method_name): return false
	_listeners.append({"obj": obj, "method": method_name})
	return true

func append_output(text: String) -> void:
	if _output_node:
		# Soporte para RichTextLabel (append_text en Godot 4)
		if _output_node.has_method("append_text"):
			_output_node.append_text(text + "\n")
		elif _output_node.has_method("add_text"):
			_output_node.add_text(text + "\n")
		elif _output_node.has_method("set_text"): # Label simple
			_output_node.text += text + "\n"
			
		# Auto-scroll
		await get_tree().process_frame
		var scroll = _output_node.get_parent()
		if scroll is ScrollContainer:
			scroll.scroll_vertical = scroll.get_v_scroll_bar().max_value

# Evento interno
func _on_input_submitted(new_text: String) -> void:
	if new_text.strip_edges() == "": return
	
	# Mostrar lo que escribió el usuario
	append_output("> " + new_text)
	
	# Notificar a listeners
	emit_signal("terminal_command_entered", new_text)
	for listener in _listeners:
		var obj = listener["obj"]
		if is_instance_valid(obj):
			obj.call(listener["method"], new_text)
	
	# Limpiar input
	_input_node.clear()
