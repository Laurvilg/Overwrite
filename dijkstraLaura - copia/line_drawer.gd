extends Node2D

signal clicked(arista)

@export var hit_width: float = 25.0
@export var line_width: float = 6.0
@export var color_default: Color = Color(0.85, 0.85, 0.85)
@export var color_accept: Color = Color(0.1, 0.85, 0.25)
@export var color_reject: Color = Color(1, 0.35, 0.35)

@export_range(1, 20) var peso_min: int = 1  # peso mínimo
@export_range(1, 20) var peso_max: int = 10 # peso máximo

var nodo_origen: Node = null
var nodo_destino: Node = null
var peso: int = 0
var grafo_ref: Node = null
var disabled: bool = false
var es_mst: bool = false

# Nodos hijos
@onready var line: Line2D = $Line2D if has_node("Line2D") else null
@onready var lbl: Label = $Label if has_node("Label") else null
@onready var area: Area2D = $Area2D if has_node("Area2D") else null
@onready var colshape: CollisionShape2D = $Area2D/CollisionShape2D if has_node("Area2D/CollisionShape2D") else null

func _ready() -> void:
	if line:
		line.width = line_width
		line.default_color = color_default
		line.z_index = 0
	if lbl:
		lbl.scale = Vector2(0.85, 0.85)
		lbl.z_index = 1

	if area:
		area.input_pickable = true
		area.monitorable = true
		var cb := Callable(self, "_on_area_2d_input_event")
		if not area.is_connected("input_event", cb):
			area.input_event.connect(cb)

func configurar(nodo_a: Node, nodo_b: Node, grafo_node: Node) -> void:
	nodo_origen = nodo_a
	nodo_destino = nodo_b
	grafo_ref = grafo_node
	# Generar peso aleatorio cada vez que se crea la arista
	peso = randi() % (peso_max - peso_min + 1) + peso_min
	if lbl:
		lbl.text = str(peso)
	_actualizar_dibujo()
	disabled = false
	es_mst = false
	if area:
		area.monitoring = true
		area.input_pickable = true
	if colshape:
		colshape.disabled = false

func _process(_delta: float) -> void:
	_actualizar_dibujo()

func _actualizar_dibujo() -> void:
	if not is_instance_valid(nodo_origen) or not is_instance_valid(nodo_destino):
		if line:
			line.visible = false
		if lbl:
			lbl.visible = false
		return

	var gp1: Vector2 = nodo_origen.global_position
	var gp2: Vector2 = nodo_destino.global_position

	if line:
		line.visible = true
		line.points = [to_local(gp1), to_local(gp2)]

	if lbl:
		lbl.visible = true
		var mid = (gp1 + gp2) * 0.5
		var dir = gp2 - gp1
		var perp = Vector2(-dir.y, dir.x).normalized() if dir.length() > 0 else Vector2.ZERO
		lbl.global_position = mid + perp * 12.0

	if colshape:
		var length = (gp2 - gp1).length()
		var rect_shape = RectangleShape2D.new()
		rect_shape.extents = Vector2(length * 0.5, hit_width * 0.5)
		colshape.shape = rect_shape
		colshape.disabled = false
		if area:
			area.global_position = (gp1 + gp2) * 0.5
			area.global_rotation = (gp2 - gp1).angle()

func _on_area_2d_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_instance_valid(grafo_ref):
			return
		var ok = false
		if grafo_ref.has_method("intentar_conectar"):
			ok = grafo_ref.intentar_conectar(nodo_origen.name, nodo_destino.name, peso)
		if ok:
			_marcar_aceptada()
		else:
			_marcar_rechazada_temporal()
		emit_signal("clicked", self)

func _marcar_aceptada() -> void:
	disabled = true
	if area:
		area.monitoring = false
	if line:
		line.default_color = color_accept
		line.width = line_width * 1.2

func _marcar_rechazada_temporal() -> void:
	if line:
		line.default_color = color_reject
	await get_tree().create_timer(0.35).timeout
	if not disabled and line:
		line.default_color = color_default
		line.width = line_width

func reiniciar_visual() -> void:
	disabled = false
	if area:
		area.monitoring = true
		area.input_pickable = true
	if colshape:
		colshape.disabled = false
	if line:
		line.default_color = color_default
		line.width = line_width

func marcar_mst() -> void:
	es_mst = true

func desmarcar_mst() -> void:
	es_mst = false
