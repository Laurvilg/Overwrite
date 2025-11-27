extends Node

class_name GraphManager

@export var terminal_path: NodePath = NodePath("Terminal")
@export var initial_global_counter: int = 3

# Definición de nodos principales
const SOURCE_NODE: String = "s"
const SINK_NODE: String = "t"

const EPS: float = 1e-6
const INF: float = 1e18

# ---------------------------------------------------------
# CONFIGURACIÓN DEL NIVEL
# Datos integrados para evitar dependencias de archivos externos
# ---------------------------------------------------------

# Estructura: [nodo_origen, nodo_destino, capacidad]
var LEVEL_EDGES: Array = [
	["s", "1", 5.0],
	["s", "2", 4.0],
	["1", "3", 3.0],
	["1", "2", 2.0],
	["2", "4", 4.0],
	["3", "t", 4.0],
	["4", "t", 5.0],
	["2", "3", 1.0]
]

# Estructura: {id, user, code, weight}
# Nota: Si 'code' termina en "A", el sistema lo marcará como amenaza.
var LEVEL_FILES: Array = [
	{"id": "pack_alpha", "user": "admin", "code": "sys_32",   "weight": 3.0},
	{"id": "pack_beta",  "user": "root",  "code": "worm_x1A", "weight": 2.0}, 
	{"id": "pack_gama",  "user": "guest", "code": "data_log", "weight": 5.5}, 
	{"id": "pack_delta", "user": "user1", "code": "img_001",  "weight": 2.0},
	{"id": "pack_omega", "user": "admin", "code": "trojan_A", "weight": 1.0}, 
	{"id": "pack_zeta",  "user": "root",  "code": "backup_z", "weight": 4.0}
]

# ---------------------------------------------------------

var nodes: Array = []
var adj: Dictionary = {}
var capacity: Dictionary = {}
var initial_capacity: Dictionary = {}

var files: Dictionary = {}
var global_counter: int = 0
var game_over: bool = false
var game_won: bool = false

func _ready() -> void:
	load_internal_level()

func reset_game() -> void:
	global_counter = initial_global_counter
	game_over = false
	game_won = false
	
	nodes.clear()
	adj.clear()
	capacity.clear()
	initial_capacity.clear()
	files.clear()
	
	load_internal_level()

# Carga inicial de grafo y archivos desde las constantes definidas arriba
func load_internal_level() -> void:
	# Construcción del grafo
	for edge in LEVEL_EDGES:
		var u = str(edge[0])
		var v = str(edge[1])
		var cap = float(edge[2])
		_ensure_node(u)
		_ensure_node(v)
		add_edge(u, v, cap)
	
	# Registro de archivos
	for f_data in LEVEL_FILES:
		add_file(f_data.id, f_data.user, f_data.code, f_data.weight)
	
	_show_files_in_terminal()

# --------------------
# Gestión del Grafo
# --------------------
func _ensure_node(id: String) -> void:
	if not nodes.has(id):
		nodes.append(id)
		adj[id] = []
		capacity[id] = {}
		initial_capacity[id] = {}

func add_edge(u: String, v: String, cap: float) -> void:
	if not adj[u].has(v):
		adj[u].append(v)
	if not adj[v].has(u):
		adj[v].append(u)
		
	capacity[u][v] = float(cap)
	if not capacity[v].has(u):
		capacity[v][u] = 0.0
		
	initial_capacity[u][v] = float(cap)
	if not initial_capacity[v].has(u):
		initial_capacity[v][u] = 0.0

func get_node_connections(node_id: String) -> Array:
	if not nodes.has(node_id):
		return []
	
	var connections: Array = []
	if capacity.has(node_id):
		for neighbor_id in capacity[node_id].keys():
			var current_cap = capacity[node_id][neighbor_id]
			if current_cap > EPS:
				connections.append({
					"target": neighbor_id,
					"capacity": current_cap
				})
	return connections

# --------------------
# Lógica de Archivos y Seguridad
# --------------------
func is_file_contaminated(file_id: String) -> bool:
	if not files.has(file_id): return false
	var code = str(files[file_id].get("code", ""))
	return code.ends_with("A")

func clean_file(file_id: String) -> Dictionary:
	if not files.has(file_id):
		return {"ok": false, "msg": "Archivo no encontrado"}
	
	var f: Dictionary = files[file_id]
	var code: String = str(f.get("code", ""))
	
	if not code.ends_with("A"):
		return {"ok": false, "msg": "El archivo ya está limpio."}
	
	# Eliminamos el marcador de virus
	var new_code: String = code.substr(0, code.length() - 1)
	f["code"] = new_code
	files[file_id] = f
	
	return {"ok": true, "msg": "Archivo desinfectado. Nuevo código: " + new_code}

func _check_victory() -> void:
	var all_delivered = true
	if files.size() == 0: all_delivered = false
	
	for key in files.keys():
		if files[key]["status"] != "delivered":
			all_delivered = false
			break
	
	if all_delivered:
		game_won = true

func list_files() -> Array:
	var out: Array = []
	for k in files.keys():
		out.append(files[k])
	return out

func add_file(file_id: String, user: String, code: String, weight: float) -> Dictionary:
	if files.has(file_id):
		return {"ok": false, "msg": "ID duplicado"}
	
	var f: Dictionary = {
		"id": file_id,
		"user": user,
		"code": code,
		"weight": float(weight),
		"status": "waiting"
	}
	files[file_id] = f
	return {"ok": true, "file": f}

func shrink_file(file_id: String, new_weight: float) -> Dictionary:
	if not files.has(file_id):
		return {"ok": false, "msg": "Archivo no encontrado"}
	var f: Dictionary = files[file_id]
	var curw: float = float(f.get("weight", 0.0))
	
	if new_weight > curw:
		return {"ok": false, "msg": "El nuevo peso debe ser menor al actual"}
		
	f["weight"] = float(new_weight)
	files[file_id] = f
	return {"ok": true, "file": f}

# --------------------
# Algoritmo de Envío (Búsqueda de ruta)
# --------------------
func _find_path_with_capacity(source: String, sink: String, need: float) -> Array:
	if not nodes.has(source) or not nodes.has(sink):
		return []
	
	var visited: Dictionary = {}
	var parent: Dictionary = {}
	for id in nodes:
		visited[id] = false
		parent[id] = null
		
	var q: Array = []
	q.push_back(source)
	visited[source] = true
	
	while q.size() > 0:
		var u: String = q.pop_front()
		for v_item in adj.get(u, []):
			var v: String = String(v_item)
			if not visited.get(v, false):
				var res_cap: float = float(capacity[u].get(v, 0.0))
				# Solo consideramos rutas que soporten el peso actual
				if res_cap + EPS >= need:
					parent[v] = u
					visited[v] = true
					if v == sink:
						# Reconstruir ruta
						var path: Array = []
						var cur: String = sink
						while cur != null:
							path.insert(0, cur)
							if cur == source: break
							cur = parent[cur]
						return path
					q.push_back(v)
	return []

func send_packet(file_id: String) -> Dictionary:
	if game_over:
		return {"ok": false, "result": "blocked", "msg": "Game over"}
	if not files.has(file_id):
		return {"ok": false, "result": "error", "msg": "Archivo no encontrado"}
	
	var f: Dictionary = files[file_id]
	
	if f["status"] == "delivered":
		return {"ok": false, "msg": "Archivo ya enviado."}

	# Control de seguridad (Malware)
	if is_file_contaminated(file_id):
		game_over = true
		global_counter = 0
		return {
			"ok": false, 
			"result": "fatal_virus", 
			"msg": "ERROR CRÍTICO: Malware detectado. Sistema comprometido."
		}
	
	var weight: float = float(f.get("weight", 0.0))
	var path: Array = _find_path_with_capacity(SOURCE_NODE, SINK_NODE, weight)
	
	# Control de capacidad (Sobrecarga)
	if path.size() == 0:
		global_counter = max(0, global_counter - 1)
		if global_counter <= 0:
			game_over = true
		return {
			"ok": false, 
			"result": "lost_life", 
			"msg": "Ancho de banda insuficiente. Paquete descartado."
		}
	
	# Actualizar capacidades del grafo
	for i in range(path.size() - 1):
		var u: String = path[i]
		var v: String = path[i + 1]
		capacity[u][v] = float(capacity[u].get(v,0.0)) - weight
		if capacity[u][v] < 0.0: capacity[u][v] = 0.0
		capacity[v][u] = float(capacity[v].get(u,0.0)) + weight
		
	f["status"] = "delivered"
	files[file_id] = f
	
	_check_victory()
	return {"ok": true, "result": "success", "path": path}

# --------------------
# Cálculo de Flujo Máximo (Edmonds–Karp)
# --------------------
func compute_max_flow(source: String, sink: String) -> Dictionary:
	if not nodes.has(source) or not nodes.has(sink):
		return {"flow": 0.0, "flows": {}}
		
	var residual: Dictionary = {}
	# Crear grafo residual
	for u_item in nodes:
		var u: String = String(u_item)
		residual[u] = {}
		if capacity.has(u):
			for v_key in capacity[u].keys():
				var vstr: String = String(v_key)
				residual[u][vstr] = float(capacity[u].get(v_key, 0.0))
				
	var max_flow: float = 0.0
	
	while true:
		var visited: Dictionary = {}
		var parent: Dictionary = {}
		for id in nodes: visited[id] = false; parent[id] = null
		
		var q: Array = []; q.push_back(source); visited[source] = true
		var found_path: bool = false
		
		while q.size() > 0:
			var u2: String = q.pop_front()
			for v2_item in adj.get(u2, []):
				var v2: String = String(v2_item)
				if not visited.get(v2, false):
					var cap_avail: float = float(residual[u2].get(v2, 0.0))
					if cap_avail > EPS:
						parent[v2] = u2; visited[v2] = true
						if v2 == sink: found_path = true; break
						q.push_back(v2)
			if found_path: break
			
		if not found_path: break
		
		var path_flow: float = INF
		var vcur: String = sink
		while vcur != source:
			var ucur: String = parent.get(vcur, null)
			if ucur == null: path_flow = 0.0; break
			var avail2: float = float(residual[ucur].get(vcur, 0.0))
			if avail2 < path_flow: path_flow = avail2
			vcur = ucur
			
		if path_flow <= EPS: break
		
		vcur = sink
		while vcur != source:
			var ucur2: String = parent.get(vcur, null)
			residual[ucur2][vcur] -= path_flow
			if not residual[vcur].has(ucur2): residual[vcur][ucur2] = 0.0
			residual[vcur][ucur2] += path_flow
			vcur = ucur2
			
		max_flow += path_flow
		
	var flows_map: Dictionary = {}
	for u in nodes:
		if initial_capacity.has(u):
			for v in initial_capacity[u].keys():
				var capinit = initial_capacity[u][v]
				if capinit > 0.0:
					var fval = capinit - residual[u][v]
					flows_map[u + "|" + v] = fval
					
	return {"flow": max_flow, "flows": flows_map}

func _show_files_in_terminal() -> void:
	var term: Node = null
	if terminal_path != NodePath("") and get_tree().get_root().has_node(str(terminal_path)):
		term = get_tree().get_root().get_node(str(terminal_path))
	else:
		term = get_tree().get_root().find_child("Terminal", true, false)
		
	var arr: Array = list_files()
	if term != null and term.has_method("append_output"):
		if arr.size() == 0:
			term.append_output("Cola de envíos vacía.")
			return
		term.append_output("Paquetes en cola: " + str(arr.size()))
		for item in arr:
			if typeof(item) == TYPE_DICTIONARY:
				term.append_output(" - " + str(item.get("id","")) + " | Code: " + str(item.get("code","")) + " | w:" + str(item.get("weight","")) + " | " + str(item.get("status","")))
			else:
				term.append_output(" - " + str(item))
	else:
		if arr.size() == 0: print("Cola vacía.")
		else: print("Paquetes: " + str(arr.size()))
