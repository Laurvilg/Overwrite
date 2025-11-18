extends Node
class_name EdmondsKarp

const INF := 1_000_000_000
func compute(edges: Dictionary, source: String, sink: String) -> Dictionary:
	var residual: Dictionary = {}
	var flow: Dictionary = {}
	var max_flow := 0
	var augmenting_paths: Array = []

	# ---------- 1. Inicializar residual y flow ----------
	for u_key in edges.keys():
		var u = u_key
		residual[u] = {}
		flow[u] = {}
		for v_key in edges[u].keys():
			var v = v_key
			var cap: int = int(edges[u][v])

			# arista directa
			residual[u][v] = cap
			flow[u][v] = 0

			# asegurar nodos inversos
			if not residual.has(v):
				residual[v] = {}
			if not residual[v].has(u):
				residual[v][u] = 0

	# ---------- 2. Repetir mientras haya camino aumentante ----------
	while true:
		var path: Array = _bfs_path(residual, source, sink)
		if path.is_empty():
			break

		# 2.1 cuello de botella
		var path_flow: int = INF
		for i in range(path.size() - 1):
			var u = path[i]
			var v = path[i + 1]
			# usar get para evitar reventar
			var cap_uv: int = int(residual.get(u, {}).get(v, 0))
			path_flow = min(path_flow, cap_uv)

		if path_flow <= 0 or path_flow == INF:
			break  # por seguridad

		# 2.2 actualizar residual y flujo
		for i in range(path.size() - 1):
			var u = path[i]
			var v = path[i + 1]

			# asegurar claves en residual
			if not residual.has(u):
				residual[u] = {}
			if not residual[u].has(v):
				residual[u][v] = 0

			if not residual.has(v):
				residual[v] = {}
			if not residual[v].has(u):
				residual[v][u] = 0

			# actualizar capacidades residuales
			residual[u][v] = int(residual[u].get(v, 0)) - path_flow
			residual[v][u] = int(residual[v].get(u, 0)) + path_flow

			# actualizar flujo
			if not flow.has(u):
				flow[u] = {}
			flow[u][v] = int(flow[u].get(v, 0)) + path_flow

		max_flow += path_flow

		augmenting_paths.append({
			"path": path.duplicate(),
			"flow": path_flow,
		})

	# ---------- 3. Escoger camino "óptimo" ----------
	var best_path: Array = []
	var best_flow := -1
	for entry in augmenting_paths:
		var pf: int = entry["flow"]
		if pf > best_flow:
			best_flow = pf
			best_path = entry["path"]

	return {
		"max_flow": max_flow,
		"augmenting_paths": augmenting_paths,
		"best_path": best_path,
		"flow": flow,
		"residual": residual,
	}


# BFS sobre grafo residual: devuelve [S, ..., T] o [] si no hay camino
func _bfs_path(residual: Dictionary, source: String, sink: String) -> Array:
	var queue: Array = [source]
	var parent: Dictionary = {}
	parent[source] = null

	while queue.size() > 0:
		var u = queue.pop_front()
		var neighbors: Dictionary = residual.get(u, {})

		for v_key in neighbors.keys():
			var v = v_key
			if not parent.has(v) and neighbors[v] > 0:
				parent[v] = u
				if v == sink:
					# reconstruir camino
					var path: Array = [sink]
					while parent[path[0]] != null:
						path.insert(0, parent[path[0]])
					return path
				queue.append(v)

	return []
