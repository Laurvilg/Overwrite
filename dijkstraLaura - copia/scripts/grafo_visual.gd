extends Node2D

@export var nodo_scene: PackedScene = load("res://dijkstraLaura - copia/NodoVertice.tscn")
@export var edge_scene: PackedScene = load("res://dijkstraLaura - copia/LineDrawer.tscn")
@onready var salir_panel = $"../../salirPanel"


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

var aristas_data := [
	["A", "B"], ["A", "H"], ["B", "D"], ["F", "D"],
	["C", "A"], ["C", "B"], ["E", "F"], ["G", "B"],
	["B", "E"], ["D", "E"], ["G","C"],["F","G"], ["E","H"] 
]

var vertices := {}
var aristas := []
var ruta_usuario := []   # ← ahora guarda aristas reales

var peso_minimo := 0

@onready var resultado_label: Label = $"../../resultadosLabel"

func _ready():
	_crear_vertices()
	_crear_aristas()
	_calcular_peso_minimo()
	resultado_label.text = "Selecciona el camino desde el nodo morado al nodo rojo."

func _crear_vertices():
	for v in vertices_data:
		var nodo = nodo_scene.instantiate()
		nodo.name = v["name"]
		nodo.position = v["position"]
		add_child(nodo)
		vertices[v["name"]] = nodo

		var sprite = nodo.get_node("Sprite2D")
		sprite.z_index = 10
		nodo.z_index = 10

		if nodo.name == "F":
			sprite.texture = load("res://dijkstraLaura - copia/image/ordenador malo.png")

func _crear_aristas():
	for a in aristas_data:
		var o = a[0]
		var d = a[1]

		if not vertices.has(o) or not vertices.has(d):
			continue

		var edge = edge_scene.instantiate()
		add_child(edge)
		edge.configurar(vertices[o], vertices[d], self)
		aristas.append(edge)

func _calcular_peso_minimo():
	var grafo = {}
	for edge in aristas:
		var o = edge.nodo_origen.name
		var d = edge.nodo_destino.name
		var p = edge.peso

		if not grafo.has(o):
			grafo[o] = {}
		if not grafo.has(d):
			grafo[d] = {}

		grafo[o][d] = p
		grafo[d][o] = p

	var dj = Dijkstra.new()
	var dist = dj.dijkstra(grafo, "A")
	peso_minimo = dist["F"]

# NUEVA FORMA → Guarda las ARISTAS directamente
func registrar_arista(arista):
	ruta_usuario.append(arista)

func _on_repeat_button_pressed() -> void:
	for edge in aristas:
		edge.reiniciar_visual()

	ruta_usuario.clear()
	resultado_label.text = "Selecciona el camino desde el nodo morado al nodo rojo."

func _on_verificar_button_pressed() -> void:
	if ruta_usuario.is_empty():
		resultado_label.text = "Selecciona al menos una arista."
		return

	var peso_usuario = 0
	print("\n===== VERIFICANDO RUTA =====")

	for edge in ruta_usuario:
		peso_usuario += edge.peso
		print("Arista seleccionada: %s - %s | Peso: %d" %
			[edge.nodo_origen.name, edge.nodo_destino.name, edge.peso])

	print("Total usuario:", peso_usuario)
	print("Peso mínimo:", peso_minimo)

	if peso_usuario == peso_minimo:
		resultado_label.text = "Seleccionaste el camino correcto. Presiona salir."
		salir_panel.visible = true
	else:
		resultado_label.text = "No es el camino mínimo. Presiona en repetir."
