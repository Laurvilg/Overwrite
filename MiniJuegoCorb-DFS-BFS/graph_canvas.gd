extends Node2D
# GraphCanvas visualizer: dibuja aristas entre botones que ya existen.
# No instancia botones; sólo dibuja líneas y ayuda a hacer preview.

@export var manager_path: NodePath = NodePath("")    # opcional: si se le pasa el GameManager, usará su 'adjacency' y 'buttons'
@export var button_paths: Array = []                 # opcional: lista de NodePath a Buttons (si no usas manager)
@export var adjacency: Array = []                    # opcional: si no usas manager, define tu grafo aquí (array de arrays)

@export var line_width: float = 4.0
@export var preview_delay: float = 0.45

@onready var manager: Node = null
var buttons: Array = []        # referencias reales a botones (Controls)
@onready var lines_parent: Node2D = null

func _ready() -> void:
	randomize()
	# buscar el parent para las líneas: busca hijo llamado "Lines" si existe
	if has_node("Lines") and $Lines is Node2D:
		lines_parent = $Lines
	else:
		# crear contenedor Lines (Node2D) para las Line2D
		var lp: Node2D = Node2D.new()
		lp.name = "Lines"
		add_child(lp)
		lines_parent = lp

	# intentar tomar manager si se exportó
	if manager_path != NodePath("") and has_node(manager_path):
		manager = get_node(manager_path)
		# si el manager tiene 'buttons' y 'adjacency', usar esas referencias dinámicamente
		if manager != null and "buttons" in manager and "adjacency" in manager:
			_update_from_manager()

	# si no, resolver button_paths (inspector)
	if buttons.size() == 0 and button_paths.size() > 0:
		_resolve_button_paths()

	# dibujar inicial
	_draw_all_edges()

	# si las posiciones cambian en runtime, refrescar periódicamente (opcional)
	set_process(true)

func _process(_delta: float) -> void:
	# refrescar líneas si los nodos se mueven; para evitar borrar/redibujar cada frame
	# podrías agregar lógica de debounce o comparar posiciones anteriores; 
	# aquí usamos la implementación simple.
	_update_lines_positions()

# ---------- helpers ----------
func _resolve_button_paths() -> void:
	buttons.clear()
	for p in button_paths:
		if typeof(p) == TYPE_NODE_PATH:
			if has_node(p):
				buttons.append(get_node(p))
			else:
				push_error("GraphCanvas: button path no encontrado: %s" % str(p))
		else:
			# si usuario pasó directamente la referencia al Node en el array
			buttons.append(p)
	_draw_all_edges()

func _update_from_manager() -> void:
	# toma referencias del manager dinámicamente
	buttons.clear()
	if manager != null and "buttons" in manager:
		# duplicamos la lista para no modificar original
		buttons = manager.buttons.duplicate()
	# tomar adjacency del manager (si existe)
	if manager != null and "adjacency" in manager:
		adjacency = manager.adjacency.duplicate()
	_draw_all_edges()

func _draw_all_edges() -> void:
	# limpiar líneas previas
	if lines_parent != null:
		for c in lines_parent.get_children():
			c.queue_free()
	# dibujar según adjacency y botones
	for a in range(adjacency.size()):
		for b in adjacency[a]:
			if b > a:
				if a < buttons.size() and b < buttons.size():
					_draw_line_between_indices(a, b)

func _draw_line_between_indices(ai:int, bi:int) -> void:
	if ai < 0 or bi < 0 or ai >= buttons.size() or bi >= buttons.size():
		return
	_draw_line_between(buttons[ai], buttons[bi])

func _draw_line_between(a:Node, b:Node) -> void:
	# ambos deben ser Controls o Nodes con global positions
	if lines_parent == null:
		return
	var line: Line2D = Line2D.new()
	line.width = line_width

	# puntos en espacio global (centro de cada botón)
	var pa_global: Vector2 = _get_node_center_global(a)
	var pb_global: Vector2 = _get_node_center_global(b)

	# convertir al espacio local de lines_parent (Node2D)
	if lines_parent is Node2D:
		var pa_local: Vector2 = lines_parent.to_local(pa_global)
		var pb_local: Vector2 = lines_parent.to_local(pb_global)
		line.add_point(pa_local)
		line.add_point(pb_local)
	else:
		# fallback: añadir puntos globales
		line.add_point(pa_global)
		line.add_point(pb_global)

	lines_parent.add_child(line)

func _get_node_center_global(node_ref: Node) -> Vector2:
	# intenta obtener bounding box/size; soporte para Control (custom_minimum_size) y Node2D
	if node_ref == null:
		return Vector2.ZERO
	# si es Control
	if node_ref is Control:
		var size: Vector2 = Vector2.ZERO
		# prefer custom_minimum_size si existe
		if "custom_minimum_size" in node_ref:
			size = node_ref.custom_minimum_size
		else:
			# fallback a rect_size si existe
			if "rect_size" in node_ref:
				size = node_ref.rect_size
		return node_ref.get_global_position() + size * 0.5
	# si es Node2D
	if node_ref is Node2D:
		if "custom_minimum_size" in node_ref:
			return node_ref.get_global_position() + node_ref.custom_minimum_size * 0.5
		return node_ref.get_global_position()
	# fallback
	return node_ref.get_global_position()

# ---------- runtime update ----------
func _update_lines_positions() -> void:
	# Simplificación: redibujamos todo; en proyectos grandes reemplaza por actualización puntual.
	_draw_all_edges()

# ---------- API ----------
func refresh() -> void:
	# fuerza recarga de botones desde manager (si existe) y redibuja
	if manager != null:
		_update_from_manager()
	else:
		_resolve_button_paths()
	_draw_all_edges()

func preview_order(order:Array) -> void:
	# resalta en orden; espera preview_delay entre cada uno
	for id in order:
		if id >= 0 and id < buttons.size():
			var b = buttons[id]
			if b != null and b.has_method("highlight_once"):
				b.call("highlight_once")
		await get_tree().create_timer(preview_delay).timeout
