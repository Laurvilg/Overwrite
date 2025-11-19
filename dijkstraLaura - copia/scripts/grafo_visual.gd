extends Node2D

@export var nodo_scene: PackedScene = load("res://dijkstraLaura - copia/NodoVertice.tscn")
@export var edge_scene: PackedScene = load("res://dijkstraLaura - copia/LineDrawer.tscn")

# Datos de nodos
var vertices_data := [
	{"name": "A", "position": Vector2(120, 120)},
	{"name": "B", "position": Vector2(280, 196)},
	{"name": "C", "position": Vector2(120, 390)},
	{"name": "D", "position": Vector2(450, 330)},
	{"name": "E", "position": Vector2(600, 120)},
	{"name": "F", "position": Vector2(610, 423)},
	{"name": "G", "position": Vector2(303, 423)},
	{"name": "H", "position": Vector2(350, 100)}
]

# Conexiones
var aristas_data := [
	["A", "B"], ["A", "H"], ["B", "D"], ["F", "D"],
	["C", "A"], ["C", "B"], ["E", "F"], ["G", "B"],
	["B", "E"], ["D", "E"], ["G","C"],["F","G"], ["E","H"] 
]

# Variables de control
var vertices := {}
var aristas := []
var ruta_usuario := []

# Peso mínimo precomputado para A -> F
var peso_minimo := 0

@onready var resultado_label: Label = $"../../resultadosLabel"

func _ready():
	_crear_vertices()
	_crear_aristas()
	_calcular_peso_minimo()
	resultado_label.text = "Selecciona el camino desde el nodo morado al nodo rojo."

# Crear nodos
func _crear_vertices():
	for v_data in vertices_data:
		var nodo = nodo_scene.instantiate()
		nodo.name = v_data["name"]
		nodo.position = v_data["position"]
		add_child(nodo)
		vertices[v_data["name"]] = nodo

		# Obtener el Sprite2D del nodo
		var sprite_node := nodo.get_node_or_null("Sprite2D")
		if sprite_node == null:
			for c in nodo.get_children():
				if c is Sprite2D:
					sprite_node = c
					break

		# Ajustar z_index
		if sprite_node:
			sprite_node.z_index = 10
			nodo.z_index = 10

			# Cambiar la textura del vértice F a una imagen invisible
			if nodo.name == "F":
				var tex = load("res://dijkstraLaura - copia/image/ordenador malo.png")
				sprite_node.texture = tex


# Crear aristas
func _crear_aristas():
	for a_data in aristas_data:
		var origen_name = a_data[0]
		var destino_name = a_data[1]
		if not vertices.has(origen_name) or not vertices.has(destino_name):
			continue
		var origen = vertices[origen_name]
		var destino = vertices[destino_name]

		var edge = edge_scene.instantiate()
		add_child(edge)
		edge.configurar(origen, destino, self)
		aristas.append(edge)

# Precalcular peso mínimo usando Dijkstra
func _calcular_peso_minimo():
	var grafo = {}
	for edge in aristas:
		if not is_instance_valid(edge):
			continue
		var o = edge.nodo_origen.name
		var d = edge.nodo_destino.name
		var p = edge.peso
		if not grafo.has(o):
			grafo[o] = {}
		if not grafo.has(d):
			grafo[d] = {}
		grafo[o][d] = p
		grafo[d][o] = p  # Grafo no dirigido

	var dj = Dijkstra.new()
	var dist = dj.dijkstra(grafo, "A")  # distancia mínima desde A
	peso_minimo = dist["F"] if dist.has("F") else 0

# Registrar ruta del usuario
func registrar_ruta(origen: String, destino: String):
	if ruta_usuario.size() == 0:
		ruta_usuario.append(origen)
	ruta_usuario.append(destino)

# Reiniciar visual
func _on_repeat_button_pressed() -> void:
	for edge in aristas:
		if is_instance_valid(edge) and edge.has_method("reiniciar_visual"):
			edge.reiniciar_visual()
	ruta_usuario.clear()
	resultado_label.text = "Selecciona el camino desde el nodo morado al nodo rojo."

# Verificar camino
func _on_verificar_button_pressed() -> void:
	if ruta_usuario.size() < 2:
		resultado_label.text = "Selecciona al menos una arista."
		return

	var peso_usuario = 0
	for i in range(ruta_usuario.size() - 1):
		var o = ruta_usuario[i]
		var d = ruta_usuario[i + 1]
		var encontrado = false
		for edge in aristas:
			if (edge.nodo_origen.name == o and edge.nodo_destino.name == d) or (edge.nodo_origen.name == d and edge.nodo_destino.name == o):
				peso_usuario += edge.peso
				encontrado = true
				break
		if not encontrado:
			resultado_label.text = "Ruta inválida. Presione en repetir." 
			return

	if peso_usuario == peso_minimo:
		resultado_label.text = "✅ Seleccionaste el camino correcto."
		print("✅ Correcto! Peso mínimo de A a F: %d" % peso_usuario)
	else:
		resultado_label.text = "❌ No es el camino mínimo. Presiona en repetir."
		print("❌ No es el camino mínimo. Usuario: %d, Mínimo: %d" % [peso_usuario, peso_minimo])
