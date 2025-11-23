extends Node
class_name GraphManager

@export var files_path: String = "res://Niveles/data/files.json"
@export var graph_path: String = "res://Niveles/data/graph.json"
@export var terminal_path: NodePath = NodePath("Terminal")
@export var initial_global_counter: int = 3

const EPS: float = 1e-6
const INF: float = 1e18

var nodes: Array = []
var adj: Dictionary = {}
var capacity: Dictionary = {}
var initial_capacity: Dictionary = {}

var files: Dictionary = {}
var global_counter: int = 0
var game_over: bool = false

func _ready() -> void:
	global_counter = initial_global_counter
	if FileAccess.file_exists(files_path):
		load_files_from_json(files_path)
	if FileAccess.file_exists(graph_path):
		load_graph_from_file(graph_path)
	_show_files_in_terminal()

# --------------------
# Utilidades del grafo
# --------------------
func _ensure_node(id: String) -> void:
	if not nodes.has(id):
		nodes.append(id)
		adj[id] = []
		capacity[id] = {}
		initial_capacity[id] = {}

func add_edge(u: String, v: String, cap: float) -> void:
	_ensure_node(u)
	_ensure_node(v)
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

# --------------------
# Carga de archivos JSON (robusta)
# --------------------
func load_files_from_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "msg": "file not found", "path": path}
	var fh: FileAccess = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if fh == null:
		return {"ok": false, "msg": "cannot open file", "path": path}
	var text: String = fh.get_as_text()
	var parsed = JSON.parse_string(text)

	# Normalizar distintas formas de retorno de parse
	var arr: Array = []
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("error") and parsed.has("result"):
		if int(parsed.get("error")) != OK:
			return {"ok": false, "msg": "json parse error", "err": parsed.get("error")}
		arr = parsed.get("result")
	elif typeof(parsed) == TYPE_ARRAY:
		arr = parsed
	elif typeof(parsed) == TYPE_DICTIONARY:
		# intentar convertir a array tomando valores del diccionario
		var maybe_arr: Array = []
		for k in parsed.keys():
			maybe_arr.append(parsed[k])
		if maybe_arr.size() > 0:
			arr = maybe_arr
		else:
			return {"ok": false, "msg": "files.json parse returned unexpected Dictionary"}
	else:
		return {"ok": false, "msg": "json parse returned unexpected type", "type": typeof(parsed)}

	if typeof(arr) != TYPE_ARRAY:
		return {"ok": false, "msg": "files.json debe contener un array"}
	for entry in arr:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var fid: String = str(entry.get("id",""))
		if fid == "":
			continue
		var user: String = str(entry.get("user",""))
		var code: String = str(entry.get("code",""))
		var weight: float = float(entry.get("weight", 1.0))
		var node: String = str(entry.get("current_node", fid))
		add_file(fid, user, code, weight, node)
	return {"ok": true}

func load_graph_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {"ok": false, "msg": "file not found", "path": path}
	var fh: FileAccess = FileAccess.open(path, FileAccess.ModeFlags.READ)
	if fh == null:
		return {"ok": false, "msg": "cannot open file", "path": path}
	var text: String = fh.get_as_text()
	var parsed = JSON.parse_string(text)

	# Normalizar resultado
	var root: Dictionary = {}
	if typeof(parsed) == TYPE_DICTIONARY and parsed.has("error") and parsed.has("result"):
		if int(parsed.get("error")) != OK:
			return {"ok": false, "msg": "json parse error", "err": parsed.get("error")}
		var maybe = parsed.get("result")
		if typeof(maybe) != TYPE_DICTIONARY:
			return {"ok": false, "msg": "graph.json root unexpected type", "type": typeof(maybe)}
		root = maybe
	elif typeof(parsed) == TYPE_DICTIONARY:
		root = parsed
	else:
		return {"ok": false, "msg": "graph.json parse returned unexpected type", "type": typeof(parsed)}

	if root.has("nodes") and typeof(root.get("nodes")) == TYPE_ARRAY:
		for n in root["nodes"]:
			_ensure_node(str(n))
	if root.has("edges") and typeof(root["edges"]) == TYPE_ARRAY:
		for e in root["edges"]:
			if typeof(e) == TYPE_DICTIONARY:
				var u: String = str(e.get("u",""))
				var v: String = str(e.get("v",""))
				var cap: float = float(e.get("capacity", 1.0))
				if u != "" and v != "":
					add_edge(u, v, cap)
	return {"ok": true}

# --------------------
# Gestión de paquetes
# --------------------
func list_files() -> Array:
	var out: Array = []
	for k in files.keys():
		out.append(files[k])
	return out

func add_file(file_id: String, user: String, code: String, weight: float, current_node: String) -> Dictionary:
	if files.has(file_id):
		return {"ok": false, "msg": "file_id exists"}
	_ensure_node(current_node)
	var f: Dictionary = {
		"id": file_id,
		"user": user,
		"code": code,
		"weight": float(weight),
		"current_node": current_node,
		"status": "ok"
	}
	files[file_id] = f
	return {"ok": true, "file": f}

func shrink_file(file_id: String, new_weight: float) -> Dictionary:
	if not files.has(file_id):
		return {"ok": false, "msg": "file not found"}
	var f: Dictionary = files[file_id]
	var curw: float = float(f.get("weight", 0.0))
	if new_weight > curw:
		return {"ok": false, "msg": "new weight must be <= current weight"}
	f["weight"] = float(new_weight)
	files[file_id] = f
	return {"ok": true, "file": f}

# --------------------
# Envío: busca ruta con capacidad suficiente y consume capacidad
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
				if res_cap + EPS >= need:
					parent[v] = u
					visited[v] = true
					if v == sink:
						var path: Array = []
						var cur: String = sink
						while cur != null:
							path.insert(0, cur)
							if cur == source:
								break
							cur = parent[cur]
						return path
					q.push_back(v)
	return []

func send_file(file_id: String, target_node: String) -> Dictionary:
	if game_over:
		return {"ok": false, "result": "blocked", "msg": "Game over"}
	if not files.has(file_id):
		return {"ok": false, "result": "error", "msg": "file not found"}
	var f: Dictionary = files[file_id]
	var weight: float = float(f.get("weight", 0.0))
	var source: String = str(f.get("current_node",""))
	_ensure_node(source)
	_ensure_node(target_node)
	var path: Array = _find_path_with_capacity(source, target_node, weight)
	if path.size() == 0:
		f["status"] = "lost"
		files[file_id] = f
		global_counter = max(0, global_counter - 1)
		if global_counter <= 0:
			game_over = true
		return {"ok": false, "result": "lost", "msg": "no path with sufficient capacity"}
	for i in range(path.size() - 1):
		var u: String = path[i]
		var v: String = path[i + 1]
		if not capacity[u].has(v):
			capacity[u][v] = 0.0
		if not capacity[v].has(u):
			capacity[v][u] = 0.0
		capacity[u][v] = float(capacity[u].get(v,0.0)) - weight
		if capacity[u][v] < 0.0 and capacity[u][v] > -EPS:
			capacity[u][v] = 0.0
		capacity[v][u] = float(capacity[v].get(u,0.0)) + weight
	f["current_node"] = target_node
	f["status"] = "ok"
	files[file_id] = f
	return {"ok": true, "result": "success", "path": path}

# --------------------
# Flujo máximo (Edmonds–Karp)
# --------------------
func compute_max_flow(source: String, sink: String) -> Dictionary:
	if not nodes.has(source) or not nodes.has(sink):
		return {"flow": 0.0, "flows": {}}
	var residual: Dictionary = {}
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
		for id in nodes:
			visited[id] = false
			parent[id] = null
		var q: Array = []
		q.push_back(source)
		visited[source] = true
		var found_path: bool = false
		while q.size() > 0:
			var u2: String = q.pop_front()
			for v2_item in adj.get(u2, []):
				var v2: String = String(v2_item)
				if not visited.get(v2, false):
					var cap_avail: float = float(residual[u2].get(v2, 0.0))
					if cap_avail > EPS:
						parent[v2] = u2
						visited[v2] = true
						if v2 == sink:
							found_path = true
							break
						q.push_back(v2)
			if found_path:
				break
		if not found_path:
			break
		var path_flow: float = INF
		var vcur: String = sink
		while vcur != source:
			var ucur: String = parent.get(vcur, null)
			if ucur == null:
				path_flow = 0.0
				break
			var avail2: float = float(residual[ucur].get(vcur, 0.0))
			if avail2 < path_flow:
				path_flow = avail2
			vcur = ucur
		if path_flow <= EPS:
			break
		vcur = sink
		while vcur != source:
			var ucur2: String = parent.get(vcur, null)
			residual[ucur2][vcur] = float(residual[ucur2].get(vcur, 0.0)) - path_flow
			if not residual[vcur].has(ucur2):
				residual[vcur][ucur2] = 0.0
			residual[vcur][ucur2] = float(residual[vcur].get(ucur2, 0.0)) + path_flow
			vcur = ucur2
		max_flow += path_flow
	var flows_map: Dictionary = {}
	for u_item2 in nodes:
		var ustr: String = String(u_item2)
		if initial_capacity.has(ustr):
			for v_key2 in initial_capacity[ustr].keys():
				var vstr2: String = String(v_key2)
				var capinit: float = float(initial_capacity[ustr].get(v_key2, 0.0))
				if capinit > 0.0:
					var residual_forward: float = float(residual[ustr].get(vstr2, 0.0))
					var fval: float = capinit - residual_forward
					if fval < 0.0 and fval > -EPS:
						fval = 0.0
					flows_map[ustr + "|" + vstr2] = fval
	return {"flow": max_flow, "flows": flows_map}

# --------------------
# Mostrar paquetes en la Terminal si existe
# --------------------
func _show_files_in_terminal() -> void:
	var term: Node = null
	if terminal_path != NodePath("") and get_tree().get_root().has_node(str(terminal_path)):
		term = get_tree().get_root().get_node(str(terminal_path))
	else:
		term = get_tree().get_root().find_node("Terminal", true, false)
	var arr: Array = list_files()
	if term != null and term.has_method("append_output"):
		if arr.size() == 0:
			term.append_output("No hay paquetes cargados.")
			return
		term.append_output("Paquetes cargados: " + str(arr.size()))
		for item in arr:
			if typeof(item) == TYPE_DICTIONARY:
				term.append_output(" - " + str(item.get("id","")) + " | w:" + str(item.get("weight","")) + " | node:" + str(item.get("current_node","")) + " | " + str(item.get("status","")))
			else:
				term.append_output(" - " + str(item))
	else:
		if arr.size() == 0:
			print("No hay paquetes cargados.")
		else:
			print("Paquetes cargados: " + str(arr.size()))
			for item in arr:
				print(" - ", item)
