extends Node2D

@export var nodo_scene: PackedScene  = load("res://dijkstraLaura - copia/NodoVertice.tscn") # Escena de NodoVertice
@export var edge_scene: PackedScene  = load("res://dijkstraLaura - copia/LineDrawer.tscn")

# Datos de ejemplo para instanciar nodos (x,y)
var vertices_data := [
	{"name": "A", "position": Vector2(120, 120)},
	{"name": "B", "position": Vector2(300, 150)},
	{"name": "C", "position": Vector2(200, 300)},
	{"name": "D", "position": Vector2(400, 300)},
	{"name": "E", "position": Vector2(500, 150)},
	{"name": "F", "position": Vector2(600, 300)}
]

# Definición de conexiones (aristas) entre nodos
var aristas_data := [
	["A", "B"],
	["A", "C"],
	["B", "C"],
	["B", "D"],
	["C", "D"],
	["C", "F"],
	["D", "E"],
	["E", "F"]
]

# Diccionarios para almacenar referencias
var vertices := {}   # "A": nodo_instance
var aristas := []    # Lista de LineDrawer instanciados

func _ready():
	_crear_vertices()
	_crear_aristas()

func _crear_vertices():
	if nodo_scene == null:
		push_error("Nodo scene no asignada en VisualGrafo.gd")
		return

	for v_data in vertices_data:
		var nodo = nodo_scene.instantiate()
		nodo.name = v_data["name"]
		nodo.position = v_data["position"]
		add_child(nodo)
		vertices[v_data["name"]] = nodo

func _crear_aristas():
	if edge_scene == null:
		push_error("Edge scene no asignada en VisualGrafo.gd")
		return

	for a_data in aristas_data:
		var origen_name = a_data[0]
		var destino_name = a_data[1]
		if not vertices.has(origen_name) or not vertices.has(destino_name):
			continue
		var origen = vertices[origen_name]
		var destino = vertices[destino_name]

		var edge = edge_scene.instantiate()
		add_child(edge)
		edge.configurar(origen, destino, self)  # LineDrawer ahora asigna peso aleatorio
		aristas.append(edge)

# Método que podría ser usado por LineDrawer para validar click
func intentar_conectar(origen_name: String, destino_name: String, peso_valor: int) -> bool:
	# Aquí podrías implementar reglas de validación, Dijkstra, MST, etc.
	# Por ahora simplemente retorna true para permitir click
	print("Intentar conectar:", origen_name, "-", destino_name, "peso:", peso_valor)
	return true
