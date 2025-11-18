extends Node2D

var node_positions = {
	"S": Vector2(100, 300),
	"A": Vector2(300, 150),
	"B": Vector2(300, 450),
	"C": Vector2(500, 300),
	"D": Vector2(700, 150),
	"E": Vector2(700, 450),
	"F": Vector2(900, 300),
	"T": Vector2(1100, 300)
}

var flow_graph: FlowGraph

func _ready():
	flow_graph = get_parent() as FlowGraph
	update()

func _draw():
	# Dibujar nodos
	for node in flow_graph.nodes:
		var pos = node_positions[node]
		draw_circle(pos, 20, Color(0.6, 0.8, 1))
		draw_string(get_font("font"), pos - Vector2(10, -5), node, Color.BLACK)

	# Dibujar aristas
	for from_node in flow_graph.edges.keys():
		for conn in flow_graph.edges[from_node]:
			var to_node = conn["to"]
			var cap = conn["capacity"]
			var from_pos = node_positions[from_node]
			var to_pos = node_positions[to_node]
			draw_line(from_pos, to_pos, Color.DARK_GRAY, 2)

			# Flecha simple
			var dir = (to_pos - from_pos).normalized()
			var arrow_base = to_pos - dir * 20
			var perp = Vector2(-dir.y, dir.x) * 6
			draw_line(arrow_base + perp, to_pos, Color.DARK_GRAY, 2)
			draw_line(arrow_base - perp, to_pos, Color.DARK_GRAY, 2)

			# Capacidad
			var mid = (from_pos + to_pos) / 2
			draw_string(get_font("font"), mid, str(cap), Color.RED)

func get_font(name):
	return preload("res://default_font.tres") # Asegúrate de tener esta fuente
