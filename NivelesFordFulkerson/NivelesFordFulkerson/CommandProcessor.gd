extends Node
class_name CommandProcessor

# Rutas exportables para facilitar enlace desde el Inspector
@export var terminal_path: NodePath = NodePath("Terminal")
@export var graph_manager_path: NodePath = NodePath("GraphManager")

const LISTENER_METHOD: String = "on_terminal_command_received"
var terminal_ref: Node = null
var _registered: bool = false
var gm_ref: Node = null

func _ready() -> void:
	# Resolver terminal
	if terminal_path != NodePath("") and get_tree().get_root().has_node(str(terminal_path)):
		terminal_ref = get_tree().get_root().get_node(str(terminal_path))
	else:
		terminal_ref = _find_node_by_name(get_tree().get_root(), "Terminal")
	_register_to_terminal()
	_resolve_graph_manager()

func _deferred_try_register() -> void:
	if terminal_ref == null:
		terminal_ref = _find_node_by_name(get_tree().get_root(), "Terminal")
	if terminal_ref == null:
		call_deferred("_deferred_try_register")
		return
	_register_to_terminal()

func _register_to_terminal() -> void:
	if terminal_ref == null:
		return
	if terminal_ref.has_method("add_command_listener"):
		var ok: bool = terminal_ref.add_command_listener(self, LISTENER_METHOD)
		if ok:
			_registered = true
			if terminal_ref.has_method("append_output"):
				terminal_ref.append_output("[CmdProc] registrado")
	elif terminal_ref.has_signal("terminal_command_entered"):
		terminal_ref.connect("terminal_command_entered", Callable(self, LISTENER_METHOD))
		_registered = true
		if terminal_ref.has_method("append_output"):
			terminal_ref.append_output("[CmdProc] conectado a señal")

func _exit_tree() -> void:
	if terminal_ref != null and _registered:
		if terminal_ref.has_method("remove_command_listener"):
			terminal_ref.remove_command_listener(self, LISTENER_METHOD)
		elif terminal_ref.is_connected("terminal_command_entered", Callable(self, LISTENER_METHOD)):
			terminal_ref.disconnect("terminal_command_entered", Callable(self, LISTENER_METHOD))
		_registered = false

# Resolver GraphManager (ruta exportada o búsqueda por método)
func _resolve_graph_manager() -> void:
	if graph_manager_path != NodePath("") and get_tree().get_root().has_node(str(graph_manager_path)):
		gm_ref = get_tree().get_root().get_node(str(graph_manager_path))
		return
	gm_ref = _find_node_with_method("list_files")

func _get_graph_manager() -> Node:
	if gm_ref != null:
		return gm_ref
	_resolve_graph_manager()
	return gm_ref

# Entrada principal: llamada por Terminal al enviar texto
func on_terminal_command_received(cmd: String) -> void:
	if cmd == null:
		return
	var parts: Array = []
	for p in str(cmd).strip_edges().split(" "):
		var s: String = str(p).strip_edges()
		if s != "":
			parts.append(s)
	if parts.size() == 0:
		return
	var verb: String = parts[0].to_lower()
	# alias "add file"
	if verb == "add" and parts.size() > 1 and parts[1].to_lower() == "file":
		parts.remove_at(1)
		parts[0] = "add_file"
		verb = "add_file"
	if verb == "help":
		_handle_help()
		return
	if verb == "list" or verb == "packages":
		_handle_list_files()
		return
	if verb == "add_file":
		_handle_add_file(parts)
		return
	if verb == "shrink":
		_handle_shrink(parts)
		return
	if verb == "send_file":
		_handle_send_file(parts)
		return
	if verb == "compute_flow":
		_handle_compute_flow(parts)
		return

# Comandos
func _handle_help() -> void:
	var lines: Array = [
		"help - muestra esta ayuda",
		"list / packages - listar paquetes",
		"add file <id> <user> <code> <weight> <node>",
		"shrink <file_id> <new_weight>",
		"send_file <file_id> <target_node>",
		"compute_flow <source> <sink> - calcula flujo máximo"
	]
	for l in lines:
		_send_to_terminal(l)

func _handle_list_files() -> void:
	var gm: Node = _get_graph_manager()
	if gm == null:
		_send_to_terminal("GraphManager no encontrado. Añade un nodo GraphManager con el script.")
		return
	var arr: Array = gm.call("list_files")
	if arr.size() == 0:
		_send_to_terminal("No hay paquetes cargados.")
		return
	_send_to_terminal("Paquetes (" + str(arr.size()) + "):")
	for item in arr:
		if typeof(item) == TYPE_DICTIONARY:
			_send_to_terminal(" - " + str(item.get("id","")) + " | user:" + str(item.get("user","")) + " | w:" + str(item.get("weight","")) + " | node:" + str(item.get("current_node","")) + " | " + str(item.get("status","")))
		else:
			_send_to_terminal(" - " + str(item))

func _handle_add_file(parts: Array) -> void:
	if parts.size() < 6:
		_send_to_terminal("uso: add file <id> <user> <code> <weight> <node>")
		return
	var fid: String = str(parts[1]); var user: String = str(parts[2])
	var code: String = str(parts[3]); var weight_txt: String = str(parts[4])
	var weight_val: float = 0.0
	if weight_txt.is_valid_float():
		weight_val = float(weight_txt)
	else:
		var w2: String = weight_txt.replace(",", ".")
		if w2.is_valid_float():
			weight_val = float(w2)
		else:
			_send_to_terminal("weight no válido: " + weight_txt)
			return
	var node: String = str(parts[5])
	var gm: Node = _get_graph_manager()
	if gm == null:
		_send_to_terminal("GraphManager no encontrado")
		return
	var res: Dictionary = gm.call("add_file", fid, user, code, weight_val, node)
	_send_to_terminal("add_file -> " + str(res))

func _handle_shrink(parts: Array) -> void:
	if parts.size() < 3:
		_send_to_terminal("uso: shrink <file_id> <new_weight>")
		return
	var fid: String = str(parts[1])
	var nw_txt: String = str(parts[2]); var nw: float = 0.0
	if nw_txt.is_valid_float():
		nw = float(nw_txt)
	else:
		var n2: String = nw_txt.replace(",", ".")
		if n2.is_valid_float():
			nw = float(n2)
		else:
			_send_to_terminal("new_weight no válido: " + nw_txt)
			return
	var gm: Node = _get_graph_manager()
	if gm == null:
		_send_to_terminal("GraphManager no encontrado")
		return
	var result: Dictionary = gm.call("shrink_file", fid, nw)
	_send_to_terminal("shrink -> " + str(result))

func _handle_send_file(parts: Array) -> void:
	if parts.size() < 3:
		_send_to_terminal("uso: send_file <file_id> <target_node>")
		return
	var fid: String = str(parts[1]); var target: String = str(parts[2])
	var gm: Node = _get_graph_manager()
	if gm == null:
		_send_to_terminal("GraphManager no encontrado")
		return
	var res: Dictionary = gm.call("send_file", fid, target)
	_send_to_terminal("send_file -> " + str(res))
	if res.has("result") and str(res["result"]) == "lost":
		# Reemplazo correcto del ternario: usar 'if else' en GDScript
		var counter: String = (str(gm.get("global_counter")) if gm.has("global_counter") else "N/A")
		_send_to_terminal("Vidas restantes: " + counter)
		if gm.has("game_over") and gm.get("game_over"):
			_send_to_terminal("Game Over")

func _handle_compute_flow(parts: Array) -> void:
	if parts.size() < 3:
		_send_to_terminal("uso: compute_flow <source> <sink>")
		return
	var source: String = str(parts[1]); var sink: String = str(parts[2])
	var gm: Node = _get_graph_manager()
	if gm == null:
		_send_to_terminal("GraphManager no encontrado")
		return
	var res: Dictionary = gm.call("compute_max_flow", source, sink)
	_send_to_terminal("max_flow: " + str(res.get("flow", 0.0)))

# Enviar texto a la Terminal o consola
func _send_to_terminal(text: String) -> void:
	if terminal_ref != null and terminal_ref.has_method("append_output"):
		terminal_ref.append_output(text)
	else:
		print(text)

# Buscar nodo por método
func _find_node_with_method(method_name: String) -> Node:
	var root: Node = get_tree().get_root()
	var stack: Array = [root]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is Node:
			if n.has_method(method_name):
				return n
			for c in n.get_children():
				stack.append(c)
	return null

# Buscar nodo por nombre
func _find_node_by_name(root: Object, target_name: String) -> Node:
	if root == null:
		return null
	if root is Node:
		var maybe = root.get("name")
		if maybe != null and str(maybe) == target_name:
			return root
		for child in root.get_children():
			if child is Node:
				var found = _find_node_by_name(child, target_name)
				if found != null:
					return found
	return null
