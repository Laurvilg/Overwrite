extends Control
<<<<<<< Updated upstream
signal minijuegoBFS_completado

=======
@onready var salir_panel = $"../salirPanel"
>>>>>>> Stashed changes
# --- Inspector Variables ---
@export var buttons: Array[Button] = []       # Botones de los nodos (drag & drop)
@export var mode_option: OptionButton         # OptionButton (modos)
@export var start_button: Button              # Botón de inicio
@export var info_label: Label                 # Label para mensajes
@export var start_node: int = 0               # Nodo inicial
@export var error_limit: int = 3              # Errores permitidos
# --- Sonidos ---
@export var correct_sound: AudioStream
@export var wrong_sound: AudioStream
@export var win_sound: AudioStream
@export var lose_sound: AudioStream

# --- Escena a cargar al ganar ---
@export var next_scene: PackedScene

# --- Grafo fijo (adjacency list) ---
var adjacency: Array = [
	[2, 5],    # nodo 0 → conecta con 2 y 5
	[3],       # nodo 1 → conecta con 3
	[0, 3, 4], # nodo 2 → conecta con 0, 3 y 4
	[1, 2, 5], # nodo 3 → conecta con 1, 2 y 5
	[2],       # nodo 4 → conecta con 2
	[0, 3]     # nodo 5 → conecta con 0 y 3
]


# --- Runtime ---
var traversal_order: Array[int] = []
var player_index: int = 0
var errors: int = 0

# --- Ready ---
func _ready() -> void:
	# Asignar números a botones y conectar señal
	for i in range(buttons.size()):
		var btn: Button = buttons[i]
		btn.text = str(i)
		if not btn.is_connected("pressed", Callable(self, "_on_button_pressed")):
			btn.connect("pressed", Callable(self, "_on_button_pressed").bind(i))

	# Llenar modo si está vacío
	if mode_option.get_item_count() == 0:
		mode_option.add_item("BFS")
		mode_option.add_item("DFS")
		mode_option.add_item("RANDOM")

	# Conectar start button
	start_button.pressed.connect(Callable(self, "_on_start_pressed"))

	# Estado inicial
	_reset_state_ui()

# --- Resetear UI ---
func _reset_state_ui() -> void:
	traversal_order.clear()
	player_index = 0
	errors = 0
	for b in buttons:
		b.disabled = false
	if info_label != null:
		info_label.text = "Elige el modo y presione Start."

# --- Start pressed ---
func _on_start_pressed() -> void:
	var selected_mode = mode_option.get_item_text(mode_option.selected)
	start_minigame(selected_mode)

# --- Iniciar minijuego ---
func start_minigame(selected_mode: String) -> void:
	_reset_state_ui()

	var mode = selected_mode
	if mode == "RANDOM":
		mode = ["BFS","DFS"].pick_random()

	# Calcular secuencia
	if mode == "BFS":
		traversal_order = _bfs(start_node)
	else:
		traversal_order = _dfs(start_node)

	if info_label != null:
		info_label.text = "Modo: " + mode

# --- Presionar botón ---
func _on_button_pressed(id: int) -> void:
	if traversal_order.size() == 0:
		info_label.text = "Presiona Start primero"
		return

	var expected: int = traversal_order[player_index]
	var btn: Button = buttons[id]

	if id == expected:
		btn.disabled = true
		player_index += 1
		_play_sound(correct_sound)
		if player_index >= traversal_order.size():
			info_label.text = "¡Ganaste! 🎉"
			_play_sound(win_sound)
			# Esperar un segundo antes de cambiar de escena
<<<<<<< Updated upstream
			await get_tree().create_timer(1.0).timeout
			_emitir_victoria()
			
=======
			salir_panel.visible = true
>>>>>>> Stashed changes
		else:
			info_label.text = "Correcto."
	else:
		errors += 1
		info_label.text = "Incorrecto."
		_play_sound(wrong_sound)
		if errors >= error_limit:
			info_label.text = "Perdiste ❌ Reiniciando..."
			_play_sound(lose_sound)
			_reset_after_delay(0.8)

# --- Reproducir sonido ---
func _play_sound(s: AudioStream) -> void:
	if s != null:
		var player = AudioStreamPlayer.new()
		add_child(player)
		player.stream = s
		player.play()
		player.connect("finished", Callable(player, "queue_free"))

# --- Reinicio después de delay ---
func _reset_after_delay(sec: float) -> void:
	var t = get_tree().create_timer(sec)
	await t.timeout
	_reset_state_ui()

# --- Cambiar escena después de delay ---
#func _change_scene_after_delay(sec: float) -> void:
#	await t.timeout
#	if next_scene != null:
#		self.visible = false

# --- BFS ---
func _bfs(start: int) -> Array[int]:
	var n: int = buttons.size()
	var visited: Array[bool] = []
	for i in range(n):
		visited.append(false)

	var q: Array[int] = []
	var order: Array[int] = []
	q.append(start)
	visited[start] = true

	while q.size() > 0:
		var u: int = q.pop_front()
		order.append(u)

		for v in adjacency[u]:
			if v >= 0 and v < n and not visited[v]:
				visited[v] = true
				q.append(v)
	return order

# --- DFS ---
func _dfs(start: int) -> Array[int]:
	var n: int = buttons.size()
	var visited: Array[bool] = []
	for i in range(n):
		visited.append(false)

	var order: Array[int] = []
	_dfs_rec(start, visited, order)
	return order

func _dfs_rec(u: int, visited: Array[bool], order: Array[int]) -> void:
	visited[u] = true
	order.append(u)

	for v in adjacency[u]:
		if v >= 0 and v < visited.size() and not visited[v]:
			_dfs_rec(v, visited, order)
			
func _emitir_victoria():
	emit_signal("minijuegoBFS_completado")
	queue_free()  # cerrar solo el minijuego, NO el overlay
