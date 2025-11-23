extends Node2D
class_name FlowGraph

# ==============================
#  LABEL ÚNICO DE INFO
# ==============================

# PathLabel es hijo DIRECTO de este nodo (FlowGraph)
@onready var info_label: Label = $"PathLabel"
@onready var salir_panel = $salirPanel
# Si tienes un panel de estado, bien; si no, será null y no pasa nada
@onready var status_label: Label = get_node_or_null("Panel/Label")


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

@onready var reset_button: BaseButton = $"ReiniciarButton"


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
	print("info_label =", info_label)

	_setup_info_label()   # Ajustar SOLO estilo del label (no posición/size)

	# Conectar botones de vértices
	for vertex_id in vertex_buttons.keys():
		var btn: BaseButton = vertex_buttons[vertex_id]
		btn.pressed.connect(_on_vertex_pressed.bind(vertex_id))

	# Conectar botón de reinicio
	if is_instance_valid(reset_button):
		reset_button.pressed.connect(_on_reset_pressed)

	_reset_vertices_visual()
	_reset_edges_visual()
	_clear_info_label()

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
		_update_status("Inicio del camino en " + vertex_id + ". Selecciona el siguiente vértice.")
		return

	var last = selected_vertices.back()

	# ¿Existe arista last -> vertex_id?
	if edges.has(last) and edges[last].has(vertex_id):
		selected_vertices.append(vertex_id)
		var cap = edges[last][vertex_id]
		_highlight_vertex(vertex_id)
		_highlight_edge(last, vertex_id)
		_update_status("Salto válido: %s -> %s (capacidad %d)." % [last, vertex_id, cap])
	else:
		_update_status("Movimiento inválido: %s -> %s. Deben ser vértices adyacentes." % [last, vertex_id])


# ==============================
#  FUNCIÓN QUE LLAMA EL BOTÓN VERIFICAR
# ==============================

func _on_verify_pressed() -> void:
	print(">>> _on_verify_pressed llamado")

	if info_label == null:
		print("❌ PathLabel no encontrado (asegúrate que se llama exactamente 'PathLabel' y es hijo de FlowGraph)")
		return

	if selected_vertices.is_empty():
		_update_status("Primero selecciona un camino desde S hasta T.")
		info_label.text = "Selecciona un camino desde S hasta T."
		return

	var path_str := _format_path(selected_vertices)

	if selected_vertices[0] != "S" or selected_vertices.back() != "T":
		_update_status("Tu camino debe empezar en S y terminar en T.")
		info_label.text = "Camino elegido: %s\n❌ Debe empezar en S y terminar en T." % path_str
		return

	print("Camino jugador:", selected_vertices)
	print("Camino solución:", solution_path)

	var optimal_str := _format_path(solution_path)
	var max_flow: int = int(ek_result.get("max_flow", 0))

	if selected_vertices == solution_path:
		# ✅ Caso correcto: mostramos TODO
		_update_status("✅ ¡Correcto! Has encontrado el camino óptimo.")
		info_label.text = "Camino elegido: %s\n✅ Correcto\nFlujo máximo = %d\nCamino óptimo = %s" \
			% [path_str, max_flow, optimal_str]
		salir_panel.visible = true
	else:
		# ❌ Caso incorrecto: SOLO mostramos el camino elegido y el mensaje de error
		_update_status("❌ Camino incorrecto. Intenta de nuevo.")
		info_label.text = "Camino elegido: %s\n❌ Incorrecto, intenta de nuevo." % path_str
		_restart_player_path()



# ==============================
#  REINICIAR
# ==============================

func _on_reset_pressed() -> void:
	_restart_player_path()


func _restart_player_path() -> void:
	selected_vertices.clear()
	_reset_edges_visual()
	_reset_vertices_visual()
	# NO llamamos _clear_info_label aquí, para que se siga viendo el mensaje
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
#  VISUAL: ARISTAS
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
#  MENSAJES / FORMATO
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


func _clear_info_label() -> void:
	if info_label:
		info_label.text = ""


# ==============================
#  CONFIG VISUAL DEL LABEL
# ==============================

func _setup_info_label() -> void:
	if info_label == null:
		print("❌ PathLabel sigue sin encontrarse")
		return

	# Que se vea y esté encima del fondo
	info_label.visible = true
	info_label.z_index = 100

	# Texto blanco
	info_label.modulate = Color(1, 1, 1, 1)
	info_label.self_modulate = Color(1, 1, 1, 1)
	info_label.add_theme_color_override("font_color", Color(1, 1, 1))

	# Que el texto se quede dentro del rectángulo y salte de línea
	info_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP

	# Limpia texto inicial
	info_label.text = ""


func _on_texture_button_pressed() -> void:
	AudioManager.SFXPlayer.stream = preload("res://inicio/audio/button-305770.mp3")
	AudioManager.SFXPlayer.play()
	self.visible = false

@onready var Inicio = $LevelIntro
func _on_start_button_2_pressed() -> void:
	AudioManager.SFXPlayer.stream = preload("res://inicio/audio/button-305770.mp3")
	AudioManager.SFXPlayer.play()
	Inicio.visible = false
