extends Node
class_name CommandProcessor

@export var terminal_path: NodePath = NodePath("Terminal")
@export var graph_manager_path: NodePath = NodePath("GraphManager")

const LISTENER_METHOD: String = "on_terminal_command_received"
var terminal_ref: Node = null
var gm_ref: GraphManager = null
var _registered: bool = false

func _ready() -> void:
	# Intentar conectar con la terminal
	if terminal_path != NodePath("") and get_tree().get_root().has_node(str(terminal_path)):
		terminal_ref = get_tree().get_root().get_node(str(terminal_path))
	else:
		terminal_ref = _find_node_by_name(get_tree().get_root(), "Terminal")
	
	_register_to_terminal()
	_resolve_graph_manager()

# Registro seguro para recibir comandos
func _register_to_terminal() -> void:
	if terminal_ref == null: return
	
	if terminal_ref.has_method("add_command_listener"):
		terminal_ref.add_command_listener(self, LISTENER_METHOD)
		_registered = true
	elif terminal_ref.has_signal("terminal_command_entered"):
		if not terminal_ref.is_connected("terminal_command_entered", Callable(self, LISTENER_METHOD)):
			terminal_ref.connect("terminal_command_entered", Callable(self, LISTENER_METHOD))
		_registered = true

# Buscar el GraphManager en la escena
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

# --- PROCESAMIENTO DE COMANDOS ---
func on_terminal_command_received(cmd: String) -> void:
	if cmd.strip_edges() == "": return
	
	var parts: Array = []
	for p in cmd.strip_edges().split(" "):
		if p.strip_edges() != "": parts.append(p.strip_edges())
		
	if parts.size() == 0: return
	var verb: String = parts[0].to_lower()
	
	# Alias y correcciones
	if verb == "add" and parts.size() > 1 and parts[1].to_lower() == "file":
		verb = "add_file"; parts.remove_at(1)
	
	# Despacho de comandos
	match verb:
		"help": _handle_help()
		"list", "ls", "files": _handle_list_files()
		"scan", "info": _handle_scan(parts)
		"clean": _handle_clean(parts)
		"shrink": _handle_shrink(parts)
		"send": _handle_send(parts)
		"compute_flow": _handle_compute_flow(parts)
		"restart", "reset": _handle_restart()
		_: _send_to_terminal("Comando desconocido: " + verb + ". Escribe 'help'.")

# --- MANEJADORES ---

func _handle_help() -> void:
	var lines: Array = [
		"--- MANUAL DE COMANDOS FLOW CONTROL ---",
		" list          - Ver cola de paquetes y estado.",
		" scan <s>      - Ver capacidad de salida del nodo s.",
		" clean <id>    - Eliminar malware (código termina en 'A').",
		" shrink <id> <w> - Reducir peso de un archivo.",
		" send <id>     - Enviar archivo a la red.",
		" compute_flow s t - Calcular capacidad total de la red.",
		" restart       - Reiniciar nivel."
	]
	for l in lines: _send_to_terminal(l)

func _handle_list_files() -> void:
	var gm = _get_graph_manager()
	if gm == null: return
	
	var arr = gm.list_files()
	if arr.size() == 0:
		_send_to_terminal("No hay archivos en el sistema.")
		return
		
	_send_to_terminal("--- COLA DE ENVÍO ---")
	for f in arr:
		var info = "ID: " + str(f.id) + " | Code: " + str(f.code) + " | Peso: " + str(f.weight) + " | Estado: " + str(f.status)
		_send_to_terminal(info)

func _handle_scan(parts: Array) -> void:
	if parts.size() < 2: _send_to_terminal("Uso: scan <nodo_id>"); return
	var node_id = str(parts[1])
	var gm = _get_graph_manager()
	if gm == null: return
	
	var conns = gm.get_node_connections(node_id)
	if conns.size() == 0:
		_send_to_terminal("El nodo '" + node_id + "' no tiene salidas activas.")
	else:
		_send_to_terminal("Salidas desde '" + node_id + "':")
		for c in conns:
			_send_to_terminal(" -> Destino: " + str(c.target) + " | Capacidad: " + str(c.capacity))

func _handle_clean(parts: Array) -> void:
	if parts.size() < 2: _send_to_terminal("Uso: clean <file_id>"); return
	var gm = _get_graph_manager()
	if gm == null: return
	var res = gm.clean_file(str(parts[1]))
	_send_to_terminal(str(res.msg))

func _handle_shrink(parts: Array) -> void:
	if parts.size() < 3: _send_to_terminal("Uso: shrink <file_id> <nuevo_peso>"); return
	var w_str = str(parts[2]).replace(",", ".")
	if not w_str.is_valid_float(): _send_to_terminal("Error: Peso inválido."); return
	
	var gm = _get_graph_manager()
	if gm == null: return
	var res = gm.shrink_file(str(parts[1]), float(w_str))
	
	if res.ok:
		_send_to_terminal("Archivo comprimido. Nuevo peso: " + str(res.file.weight))
	else:
		_send_to_terminal("Error: " + str(res.msg))

func _handle_send(parts: Array) -> void:
	if parts.size() < 2: _send_to_terminal("Uso: send <file_id>"); return
	var gm = _get_graph_manager()
	if gm == null: return
	
	var res = gm.send_packet(str(parts[1]))
	
	if res.ok:
		_send_to_terminal("ENVÍO EXITOSO. Ruta: " + str(res.path))
	else:
		if res.result == "fatal_virus":
			_send_to_terminal("!!! ALERTA DE SEGURIDAD !!!")
			_send_to_terminal(res.msg)
		elif res.result == "lost_life":
			_send_to_terminal("FALLO DE RED: " + res.msg)
			_send_to_terminal("Vidas restantes: " + str(gm.global_counter))
		else:
			_send_to_terminal("Error: " + str(res.msg))
			
	_check_game_state(gm)

func _handle_compute_flow(parts: Array) -> void:
	if parts.size() < 3: _send_to_terminal("Uso: compute_flow <s> <t>"); return
	var gm = _get_graph_manager()
	if gm == null: return
	var res = gm.compute_max_flow(str(parts[1]), str(parts[2]))
	_send_to_terminal("Flujo Máximo Actual: " + str(res.flow))

func _handle_restart() -> void:
	var gm = _get_graph_manager()
	if gm == null: return
	gm.reset_game()
	_send_to_terminal("--- SISTEMA REINICIADO ---")

# --- UTILIDADES ---

func _check_game_state(gm: GraphManager) -> void:
	if gm.game_won:
		_send_to_terminal("\n********************************")
		_send_to_terminal("* ¡MISIÓN CUMPLIDA!            *")
		_send_to_terminal("* Todos los datos evacuados.   *")
		_send_to_terminal("********************************\n")
	elif gm.game_over:
		_send_to_terminal("\n--------------------------------")
		_send_to_terminal("|      GAME OVER - FALLO       |")
		_send_to_terminal("| Escribe 'restart' para volver|")
		_send_to_terminal("--------------------------------\n")

func _send_to_terminal(text: String) -> void:
	if terminal_ref != null and terminal_ref.has_method("append_output"):
		terminal_ref.append_output(text)
	else:
		print(text)

func _find_node_with_method(method_name: String) -> Node:
	var stack = [get_tree().get_root()]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n.has_method(method_name): return n
		stack.append_array(n.get_children())
	return null

func _find_node_by_name(root: Node, target: String) -> Node:
	if root.name == target: return root
	for c in root.get_children():
		var res = _find_node_by_name(c, target)
		if res: return res
	return null
