extends Node2D
class_name FlowGraph

# ==============================
#  GRAFO LÓGICO (CAPACIDADES)
# ==============================

var edges: Dictionary = {
	"S": {"A": 12, "B": 10, "C": 4},
	"A": {"B": 3, "D": 7, "E": 5},
	"B": {"C": 2, "D": 10},
	"C": {"E": 8},
	"D": {"F": 10, "T": 5},
	"E": {"D": 3, "F": 7, "T": 8},
	"F": {"T": 15},
}

func get_neighbors(node: String) -> Dictionary:
	return edges.get(node, {})

func get_capacity(from_node: String, to_node: String) -> int:
	return int(edges.get(from_node, {}).get(to_node, 0))


# ==============================
#  NODOS VISUALES
# ==============================

@onready var vertex_buttons: Dictionary = {
	"S": $"S-Button",
	"A": $"A-Button",
	"B": $"B-Button",
	"C": $"C-Button",
	"D": $"D-Button",
	"E": $"E-Button",
	"F": $"F-Button",
	"T": $"T-Button",
}

@onready var edge_nodes: Dictionary = {
	"S-A": $Edge_S_A,
	"S-B": $Edge_S_B,
	"S-C": $Edge_S_C,
	"A-B": $Edge_A_B,
	"A-D": $Edge_A_D,
	"A-E": $Edge_A_E,
	"B-C": $Edge_B_C,
	"B-D": $Edge_B_D,
	"C-E": $Edge_C_E,
	"D-F": $Edge_D_F,
	"D-T": $Edge_D_T,
	"E-D": $Edge_E_D,
	"E-F": $Edge_E_F,
	"E-T": $Edge_E_T,
	"F-T": $Edge_F_T,
}

@onready var verify_button: BaseButton = $"VerificarButton"
@onready var reset_button: BaseButton  = $"ReiniciarButton"

@onready var status_label: Label = get_node_or_null("Panel/Label")

# ==============================
#  ESTADO DEL JUEGO
# ==============================

var selected_vertices: Array = []      # camino del jugador
var solution_path: Array = []          # camino óptimo de Edmonds-Karp
var ek_result: Dictionary = {}         # resultado de Edmonds


# ==============================
#  CICLO DE VIDA
# ==============================

func _ready() -> void:
	print("--- DEBUG _ready FlowGraph ---")

	# Asegurar layout de los labels del InfoPanel
	_setup_info_labels()

	# Conectar botones de vértices
	for vertex_id in vertex_buttons.keys():
		var btn: BaseButton = vertex_buttons[vertex_id]
		btn.pressed.connect(_on_vertex_pressed.bind(vertex_id))

	# Conectar botones de verificar / reiniciar
	if is_instance_valid(verify_button):
		verify_button.pressed.connect(_on_verify_pressed)
	if is_instance_valid(reset_button):
		reset_button.pressed.connect(_on_reset_pressed)

	_reset_vertices_visual()
	_reset_edges_visual()
	_clear_info_labels()

	# Calcular solución con Edmonds-Karp
	_compute_solution()

	_update_status("Selecciona el vértice de inicio (por ejemplo S).")


# ==============================
#  EDMONDS–KARP: SOLUCIÓN
# ==============================

func _compute_solution() -> void:
	var ek := EdmondsKarp.new()
	ek_result = ek.compute(edges, "S", "T")
	solution_path = ek_result["best_path"]

	print("=== EDMONDS-KARP ===")
	print("Flujo máximo =", ek_result["max_flow"])
	print("Camino óptimo (solución) =", solution_path)
	print("====================")
	# _highlight_solution_path()


func _highlight_solution_path() -> void:
	for i in range(solution_path.size() - 1):
		var u = solution_path[i]
		var v = solution_path[i + 1]
		_highlight_edge(u, v)
		_highlight_vertex(v)
	_highlight_vertex(solution_path[0])


# ==============================
#  CLICS EN VÉRTICES (CAMINO DEL JUGADOR)
# ==============================

func _on_vertex_pressed(vertex_id: String) -> void:
	print("Botón", vertex_id, "presionado")

	# Primer vértice: empezamos nuevo camino
	if selected_vertices.is_empty():
		_reset_edges_visual()
		_reset_vertices_visual()
		selected_vertices.clear()
		selected_vertices.append(vertex_id)
		_highlight_vertex(vertex_id)
		_update_path_label()
		_update_status("Inicio del camino en " + vertex_id + ". Selecciona el siguiente vértice.")
		return

	var last = selected_vertices.back()

	# ¿Existe arista last -> vertex_id?
	if edges.has(last) and edges[last].has(vertex_id):
		selected_vertices.append(vertex_id)
		var cap = edges[last][vertex_id]
		_highlight_vertex(vertex_id)
		_highlight_edge(last, vertex_id)
		_update_path_label()
		_update_status("Salto válido: %s -> %s (capacidad %d)." % [last, vertex_id, cap])
	else:
		_update_status("Movimiento inválido: %s -> %s. Deben ser vértices adyacentes." % [last, vertex_id])


# ==============================
#  VERIFICAR / REINICIAR
# ==============================

func _on_verify_pressed() -> void:
	var lbl_res := _get_result_label()
	var lbl_flow := _get_flow_label()

	if selected_vertices.is_empty():
		_update_status("Primero selecciona un camino desde S hasta T.")
		if lbl_res:
			lbl_res.text = "Resultado: selecciona un camino primero."
		return

	if selected_vertices[0] != "S" or selected_vertices.back() != "T":
		_update_status("Tu camino debe empezar en S y terminar en T.")
		if lbl_res:
			lbl_res.text = "Resultado: el camino debe ir de S hasta T."
		return

	print("Camino jugador:", selected_vertices)
	print("Camino solución:", solution_path)

	if selected_vertices == solution_path:
		_update_status("✅ ¡Correcto! Has encontrado el camino óptimo.")
		if lbl_res:
			lbl_res.text = "Resultado: ✅ Correcto"
		if lbl_flow:
			var pretty_sol := _format_path(solution_path)
			var max_flow: int = int(ek_result.get("max_flow", 0))
			lbl_flow.text = "Flujo máximo = %d\nCamino óptimo = %s" % [max_flow, pretty_sol]
	else:
		_update_status("❌ Camino incorrecto. Intenta de nuevo.")
		if lbl_res:
			lbl_res.text = "Resultado: ❌ Incorrecto, intenta de nuevo."
		if lbl_flow:
			lbl_flow.text = ""
		_restart_player_path()


func _on_reset_pressed() -> void:
	_restart_player_path()


func _restart_player_path() -> void:
	selected_vertices.clear()
	_reset_edges_visual()
	_reset_vertices_visual()
	_clear_info_labels()
	_update_status("Camino reiniciado. Selecciona de nuevo desde S.")


# ==============================
#  VISUAL: VÉRTICES
# ==============================

func _reset_vertices_visual() -> void:
	for vertex_id in vertex_buttons.keys():
		var btn := vertex_buttons[vertex_id] as CanvasItem
		btn.modulate = Color(1, 1, 1)

func _highlight_vertex(vertex_id: String) -> void:
	if vertex_buttons.has(vertex_id):
		var btn := vertex_buttons[vertex_id] as CanvasItem
		btn.modulate = Color(0.4, 1.0, 0.4)


# ==============================
#  VISUAL: ARISTAS (Line2D TUYAS)
# ==============================

func _reset_edges_visual() -> void:
	for key in edge_nodes.keys():
		var line := edge_nodes[key] as Line2D
		line.visible = false
		line.modulate = Color(0.2, 0.9, 0.2, 1)
		line.width = 6.0

func _highlight_edge(from_id: String, to_id: String) -> void:
	var key := "%s-%s" % [from_id, to_id]
	if edge_nodes.has(key):
		var line := edge_nodes[key] as Line2D
		line.visible = true
		line.z_index = 50
	else:
		print("NO existe Line2D para", key)


# ==============================
#  MENSAJES + LABELS DE INFO
# ==============================

func _update_status(msg: String) -> void:
	if status_label:
		status_label.text = msg
	else:
		print(msg)


func _format_path(path: Array) -> String:
	if path.is_empty():
		return "—"
	return " -> ".join(path)


# ---- Helpers para LABELS ----

func _get_path_label() -> Label:
	var lbl := get_node_or_null("InfoPanel/PathLabel") as Label
	if not lbl:
		print("❌ No se encontró InfoPanel/PathLabel")
	return lbl

func _get_result_label() -> Label:
	var lbl := get_node_or_null("InfoPanel/ResultLabel") as Label
	if not lbl:
		print("❌ No se encontró InfoPanel/ResultLabel")
	return lbl

func _get_flow_label() -> Label:
	var lbl := get_node_or_null("InfoPanel/FlowLabel") as Label
	if not lbl:
		print("❌ No se encontró InfoPanel/FlowLabel")
	return lbl


func _update_path_label() -> void:
	var lbl := _get_path_label()
	if lbl:
		lbl.text = "Camino seleccionado: " + _format_path(selected_vertices)


func _clear_info_labels() -> void:
	var lbl_path := _get_path_label()
	var lbl_res  := _get_result_label()
	var lbl_flow := _get_flow_label()

	if lbl_path:
		lbl_path.text = "Camino seleccionado: —"
	if lbl_res:
		lbl_res.text = ""
	if lbl_flow:
		lbl_flow.text = ""


# ==============================
#  FORZAR LAYOUT / COLOR DE LABELS
# ==============================

func _setup_info_labels() -> void:
	var panel := get_node_or_null("InfoPanel") as Control
	if not panel:
		print("❌ No se encontró InfoPanel")
		return

	var lbl_path := _get_path_label()
	var lbl_res  := _get_result_label()
	var lbl_flow := _get_flow_label()

	var labels := [lbl_path, lbl_res, lbl_flow]
	var y := 10.0

	for lbl in labels:
		if lbl:
			# que estén visibles, en blanco y con tamaño decente
			lbl.visible = true
			lbl.modulate = Color(1, 1, 1, 1)
			lbl.self_modulate = Color(1, 1, 1, 1)
			lbl.add_theme_color_override("font_color", Color(1, 1, 1))

			lbl.anchor_left = 0.0
			lbl.anchor_right = 1.0
			lbl.anchor_top = 0.0
			lbl.anchor_bottom = 0.0

			lbl.position = Vector2(10, y)
			lbl.size = Vector2(panel.size.x - 20, 24)

			y += 28.0
