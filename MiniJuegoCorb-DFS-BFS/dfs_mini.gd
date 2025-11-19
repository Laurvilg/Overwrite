# GameManager.gd
extends Control

# Manager central del minijuego: recibe lista de botones por Inspector,
# define la adyacencia (grafo fijo) y verifica orden BFS/DFS.

@export var button_paths: Array = []           # NodePath de cada botón
@export var mode_option_path: NodePath         # OptionButton
@export var info_label_path: NodePath          # Label para mensajes
@export var start_node: int = 0                # Nodo de inicio
@export var error_limit: int = 3

# grafo fijo: array de arrays (solo tipado exterior)
@export var adjacency: Array = [
	[1, 5],
	[0, 2],
	[1, 3],
	[2, 4],
	[3, 5],
	[4, 0]
]

# runtime
var buttons: Array = []
var traversal_order: Array = []
var player_index: int = 0
var errors: int = 0

@onready var mode_option: OptionButton = null
@onready var info_label: Label = null

func _ready() -> void:
	# resolver referencias del inspector
	if mode_option_path != null and has_node(mode_option_path):
		mode_option = get_node(mode_option_path) as OptionButton
	if info_label_path != null and has_node(info_label_path):
		info_label = get_node(info_label_path) as Label

	# cargar botones desde NodePaths
	buttons.clear()
	for p in button_paths:
		if typeof(p) == TYPE_NODE_PATH:
			if has_node(p):
				var b: Button = get_node(p) as Button
				buttons.append(b)
			else:
				push_error("GameManager: Path no encontrado: %s" % str(p))
		else:
			var b_any = p
			buttons.append(b_any)

	# configurar botones: mostrar id y conectar señal pressed
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		if btn == null:
			continue
		btn.set("node_id", i)
		if "text" in btn:
			btn.text = str(i)
		if not btn.is_connected("pressed", Callable(self, "_on_button_pressed")):
			btn.connect("pressed", Callable(self, "_on_button_pressed").bind(i))

	_reset_state_ui()

func _reset_state_ui() -> void:
	traversal_order.clear()
	player_index = 0
	errors = 0
	for b_any in buttons:
		var b: Button = b_any
		if b == null:
			continue
		b.disabled = false
		if b.has_method("_update_visual"):
			b._update_visual()
	if info_label:
		info_label.text = "Elige modo y presiona Start"

# PUBLIC
func start_minigame(selected_mode: String = "RANDOM") -> void:
	_reset_state_ui()
	var mode: String = selected_mode
	if mode == "RANDOM":
		mode = ["BFS","DFS"].pick_random()
	var s: int = clamp(start_node, 0, max(buttons.size() - 1, 0))
	if mode == "BFS":
		traversal_order = _bfs(s)
	else:
		traversal_order = _dfs(s)

	player_index = 0
	errors = 0
	if info_label:
		info_label.text = "Modo: %s — Empieza. Toca el nodo %d" % [mode, traversal_order[0]]

	_preview_sequence()

func _preview_sequence() -> void:
	for id_any in traversal_order:
		var id: int = int(id_any)
		if id >=0 and id < buttons.size():
			var b: Button = buttons[id]
			if b.has_method("highlight_once"):
				b.call("highlight_once")

func _on_button_pressed(id_any:int) -> void:
	var id: int = int(id_any)
	if traversal_order.size() == 0:
		if info_label:
			info_label.text = "Presiona Start primero"
		return
	if player_index >= traversal_order.size():
		return
	var expected_raw: Variant = traversal_order[player_index]
	var expected: int = int(expected_raw)
	if id == expected:
		# correcto
		var b: Button = buttons[id]
		if b != null:
			if b.has_method("mark_cleaned"):
				b.call("mark_cleaned")
			else:
				b.disabled = true
		player_index += 1
		if player_index >= traversal_order.size():
			if info_label:
				info_label.text = "¡Ganaste! 🎉"
			_reset_after_delay(1.0)
		else:
			if info_label:
				info_label.text = "Correcto. Siguiente: %d" % traversal_order[player_index]
	else:
		# incorrecto
		errors += 1
		var bwrong: Button = buttons[id]
		if bwrong != null and bwrong.has_method("play_wrong"):
			bwrong.call("play_wrong")
		if info_label:
			info_label.text = "Incorrecto. Errores: %d/%d" % [errors, error_limit]
		if errors >= error_limit:
			if info_label:
				info_label.text = "Perdiste ❌ Reiniciando..."
			_reset_after_delay(0.8)

func _reset_after_delay(sec: float) -> void:
	var t = get_tree().create_timer(sec)
	await t.timeout
	_reset_state_ui()

# BFS y DFS
func _bfs(start:int) -> Array:
	var n: int = buttons.size()
	var visited := []
	for i in range(n):
		visited.append(false)
	var q := []
	var order := []
	q.append(start)
	visited[start] = true
	while q.size() > 0:
		var u: int = int(q.pop_front())
		order.append(u)
		if u >=0 and u < adjacency.size():
			var neigh_raw = adjacency[u]
			for v_raw in neigh_raw:
				var v: int = int(v_raw)
				if v >=0 and v < n and not visited[v]:
					visited[v] = true
					q.append(v)
	return order

func _dfs(start:int) -> Array:
	var n: int = buttons.size()
	var visited := []
	for i in range(n):
		visited.append(false)
	var order := []
	_dfs_rec(start, visited, order)
	return order

func _dfs_rec(u:int, visited:Array, order:Array) -> void:
	visited[u] = true
	order.append(u)
	if u >=0 and u < adjacency.size():
		var neigh_raw = adjacency[u]
		for v_raw in neigh_raw:
			var v: int = int(v_raw)
			if v >=0 and v < visited.size() and not visited[v]:
				_dfs_rec(v, visited, order)
