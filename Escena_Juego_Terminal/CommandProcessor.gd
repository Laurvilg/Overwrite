extends Node
class_name CommandProcessor

@export var terminal_path: NodePath = NodePath("Terminal")
@export var graph_manager_path: NodePath = NodePath("GraphManager")

const LISTENER_METHOD: String = "on_terminal_command_received"
var terminal_ref: Node = null
var _registered: bool = false
var gm_ref: GraphManager = null

func _ready() -> void:
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
	if terminal_ref == null: return
	if terminal_ref.has_method("add_command_listener"):
		if terminal_ref.add_command_listener(self, LISTENER_METHOD):
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

func _resolve_graph_manager() -> void:
	if graph_manager_path != NodePath("") and get_tree().get_root().has_node(str(graph_manager_path)):
		gm_ref = get_tree().get_root().get_node(str(graph_manager_path)) as GraphManager
		return
	var found = _find_node_with_method("list_files")
	if found is GraphManager:
		gm_ref = found

func _get_graph_manager() -> GraphManager:
	if gm_ref != null: return gm_ref
	_resolve_graph_manager()
	return gm_ref

func on_terminal_command_received(cmd: String) -> void:
	if cmd == null: return
	var parts: Array = []
	for p in str(cmd).strip_edges().split(" "):
		var s: String = str(p).strip_edges()
		if s != "": parts.append(s)
	if parts.size() == 0: return
	var verb: String = parts[0].to_lower()
	
	if verb == "add" and parts.size() > 1 and parts[1].to_lower() == "file":
		parts.remove_at(1); parts[0] = "add_file"; verb = "add_file"
		
	if verb == "help": _handle_help(); return
	if verb == "list" or verb == "packages": _handle_list_files(); return
	if verb == "add_file": _handle_add_file(parts); return
	if verb == "shrink": _handle_shrink(parts); return
	if verb == "clean": _handle_clean(parts); return
	if verb == "send": _handle_send(parts); return
	if verb == "restart" or verb == "reset": _handle_restart(); return
	if verb == "compute_flow": _handle_compute_flow(parts); return
	if verb == "scan" or verb == "info": _handle_scan(parts); return

func _handle_help() -> void:
	var lines: Array = [
		"help - muestra esta ayuda",
		"list - ver archivos en cola",
		"clean <file_id> - eliminar malware (código termina en 'A')",
		"shrink <file_id> <new_weight> - reducir tamaño",
		"send <file_id> - enviar al grafo (de 's' a 't')",
		"scan <node_id> - ver capacidad de un nodo",
		"compute_flow <source> <sink>",
		"restart - reiniciar juego"
	]
	for l in lines: _send_to_terminal(l)

func _handle_list_files() -> void:
	var gm: GraphManager = _get_graph_manager()
	if gm == null: _send_to_terminal("GraphManager no encontrado."); return
	var arr: Array = gm.list_files()
	if arr.size() == 0: _send_to_terminal("No hay paquetes en cola."); return
	_send_to_terminal("Archivos en Cola (" + str(arr.size()) + "):")
	for item in arr:
		if typeof(item) == TYPE_DICTIONARY:
			var code = str(item.get("code",""))
			var status = str(item.get("status", "waiting"))
			# Solo mostramos el código, sin etiquetas visuales de virus
			_send_to_terminal(" - ID: " + str(item.get("id")) + " | Code: " + code + " | w: " + str(item.get("weight")) + " | St: " + status)
		else: _send_to_terminal(" - " + str(item))

func _handle_add_file(parts: Array) -> void:
	if parts.size() < 5:
		_send_to_terminal("uso: add file <id> <user> <code> <weight>")
		return
	var fid: String = str(parts[1]); var user: String = str(parts[2])
	var code: String = str(parts[3]); var weight_txt: String = str(parts[4])
	var weight_val: float = 0.0
	if weight_txt.is_valid_float(): weight_val = float(weight_txt)
	else:
		var w2 = weight_txt.replace(",", ".")
		if w2.is_valid_float(): weight_val = float(w2)
		else: _send_to_terminal("weight no válido"); return
	
	var gm: GraphManager = _get_graph_manager()
	if gm == null: return
	var res: Dictionary = gm.add_file(fid, user, code, weight_val)
	_send_to_terminal("add_file -> " + str(res))

func _handle_shrink(parts: Array) -> void:
	if parts.size() < 3: _send_to_terminal("uso: shrink <file_id> <new_weight>"); return
	var fid = str(parts[1])
	var nw_txt = str(parts[2]); var nw: float = 0.0
	if nw_txt.is_valid_float(): nw = float(nw_txt)
	else:
		var n2 = nw_txt.replace(",", ".")
		if n2.is_valid_float(): nw = float(n2)
		else: _send_to_terminal("peso no válido"); return
	var gm = _get_graph_manager()
	if gm == null: return
	var result = gm.shrink_file(fid, nw)
	_send_to_terminal("shrink -> " + str(result))

func _handle_clean(parts: Array) -> void:
	if parts.size() < 2: _send_to_terminal("uso: clean <file_id>"); return
	var gm = _get_graph_manager()
	if gm == null: return
	var res = gm.clean_file(str(parts[1]))
	_send_to_terminal("clean -> " + str(res.get("msg")))

func _handle_send(parts: Array) -> void:
	if parts.size() < 2:
		_send_to_terminal("uso: send <file_id>")
		return
	var fid: String = str(parts[1])
	var gm: GraphManager = _get_graph_manager()
	if gm == null: return
	
	var res: Dictionary = gm.send_packet(fid)
	
	if res.get("result") == "fatal_virus":
		_send_to_terminal("!!! GAME OVER !!!")
		_send_to_terminal(str(res.get("msg")))
	elif res.get("result") == "lost_life":
		_send_to_terminal("FALLO DE ENVÍO: " + str(res.get("msg")))
	elif res.get("ok") == true:
		_send_to_terminal("ENVÍO EXITOSO: Ruta utilizada " + str(res.get("path")))
	else:
		_send_to_terminal("Error: " + str(res.get("msg")))

	if gm.game_over:
		_send_to_terminal("--- JUEGO TERMINADO (PERDISTE) ---")
	elif gm.game_won:
		_send_to_terminal("***********************************")
		_send_to_terminal("*   ¡FELICIDADES! HAS GANADO      *")
		_send_to_terminal("* Todos los archivos entregados.  *")
		_send_to_terminal("***********************************")
	elif res.get("result") == "lost_life":
		_send_to_terminal("Vidas restantes: " + str(gm.global_counter))

func _handle_restart() -> void:
	var gm = _get_graph_manager()
	if gm == null: return
	_send_to_terminal("Reiniciando sistema...")
	gm.reset_game()
	_send_to_terminal("¡Juego reiniciado! Vidas: " + str(gm.global_counter))

func _handle_compute_flow(parts: Array) -> void:
	if parts.size() < 3: _send_to_terminal("uso: compute_flow <s> <t>"); return
	var gm = _get_graph_manager()
	if gm == null: return
	var res = gm.compute_max_flow(str(parts[1]), str(parts[2]))
	_send_to_terminal("max_flow: " + str(res.get("flow", 0.0)))

func _handle_scan(parts: Array) -> void:
	if parts.size() < 2: _send_to_terminal("uso: scan <node_id>"); return
	var node_id = str(parts[1])
	var gm = _get_graph_manager()
	if gm == null: return
	
	if not gm.nodes.has(node_id):
		_send_to_terminal("Nodo no encontrado en el grafo.")
		return

	var connections = gm.get_node_connections(node_id)
	if connections.size() == 0:
		_send_to_terminal("Nodo [" + node_id + "] sin salidas disponibles.")
		return
	
	_send_to_terminal("Conexiones desde [" + node_id + "]:")
	for c in connections:
		_send_to_terminal(" -> [" + str(c.target) + "] Capacidad: " + str(c.capacity))

func _send_to_terminal(text: String) -> void:
	if terminal_ref != null and terminal_ref.has_method("append_output"):
		terminal_ref.append_output(text)
	else: print(text)

func _find_node_with_method(method_name: String) -> Node:
	var root = get_tree().get_root()
	var stack = [root]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n is Node:
			if n.has_method(method_name): return n
			for c in n.get_children(): stack.append(c)
	return null

func _find_node_by_name(root: Object, target_name: String) -> Node:
	if root == null: return null
	if root is Node:
		if root.name == target_name: return root
		for child in root.get_children():
			var found = _find_node_by_name(child, target_name)
			if found != null: return found
	return null
