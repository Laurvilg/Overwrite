extends Node
class_name Dijkstra

const INF = 999999

# Retorna un diccionario con la distancia mínima desde el nodo origen
func dijkstra(grafo_dict: Dictionary, origen: String) -> Dictionary:
	var dist = {}
	var visitado = {}

	# Inicializar distancias
	for nodo in grafo_dict.keys():
		dist[nodo] = INF
		visitado[nodo] = false

	dist[origen] = 0

	while true:
		var actual = null
		var min_dist = INF

		# Buscar nodo no visitado con menor distancia
		for nodo in dist.keys():
			if not visitado[nodo] and dist[nodo] < min_dist:
				min_dist = dist[nodo]
				actual = nodo

		if actual == null:
			break

		visitado[actual] = true

		for vecino in grafo_dict[actual].keys():
			var peso = grafo_dict[actual][vecino]
			var nueva = dist[actual] + peso
			if nueva < dist[vecino]:
				dist[vecino] = nueva

	return dist
