extends Node
class_name Dijkstra

const INF = 999999

func dijkstra(grafo_dict: Dictionary, origen: String):

	var dist = {}
	var visitado = {}

	# Inicializar todo
	for v in grafo_dict.keys():
		dist[v] = INF
		visitado[v] = false

	dist[origen] = 0

	while true:
		var actual = null
		var min_dist = INF

		# Buscar nodo no visitado con menor distancia
		for v in dist.keys():
			if not visitado[v] and dist[v] < min_dist:
				min_dist = dist[v]
				actual = v

		if actual == null:
			break

		visitado[actual] = true

		for vecino in grafo_dict[actual].keys():
			var peso = grafo_dict[actual][vecino]
			var nueva = dist[actual] + peso
			if nueva < dist[vecino]:
				dist[vecino] = nueva

	return dist
