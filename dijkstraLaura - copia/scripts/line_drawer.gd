extends Node2D

signal clicked(arista)

@export var hit_width: float = 25.0
@export var line_width: float = 6.0
@export var color_default: Color = Color(0.85, 0.85, 0.85)
@export var color_accept: Color = Color(0.1, 0.85, 0.25)
@export var color_reject: Color = Color(1, 0.35, 0.35)

@export_range(5, 50) var peso_min: int = 5
@export_range(5, 50) var peso_max: int = 20

var nodo_origen: Node = null
var nodo_destino: Node = null
var peso: int = 0
var grafo_ref: Node = null
var disabled: bool = false

@onready var line: Line2D = $Line2D
@onready var lbl: Label = $Label
@onready var area: Area2D = $Area2D
@onready var colshape: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	line.width = line_width
	line.default_color = color_default
	line.z_index = 0
	
	lbl.scale = Vector2(1, 1)
	lbl.z_index = 1
	lbl.add_theme_color_override("font_color", Color.BLACK)
	lbl.add_theme_font_size_override("font_size", 20)
	
	var cb := Callable(self, "_on_area_2d_input_event")
	if not area.is_connected("input_event", cb):
		area.input_event.connect(cb)

func configurar(nodo_a: Node, nodo_b: Node, grafo_node: Node) -> void:
	nodo_origen = nodo_a
	nodo_destino = nodo_b
	grafo_ref = grafo_node

	peso = randi() % (peso_max - peso_min + 1) + peso_min
	lbl.text = str(peso)

	_actualizar_dibujo()
	disabled = false
	area.monitoring = true
	area.input_pickable = true
	colshape.disabled = false

func _process(_delta: float) -> void:
	# Solo actualizamos dibujo si tenemos ambos nodos válidos
	if is_instance_valid(nodo_origen) and is_instance_valid(nodo_destino):
		_actualizar_dibujo()
	else:
		# Si no son válidos, ocultamos elementos para que no den errores visuales
		if line:
			line.visible = false
		if lbl:
			lbl.visible = false
		return


func _actualizar_dibujo() -> void:
	var gp1: Vector2 = nodo_origen.global_position
	var gp2: Vector2 = nodo_destino.global_position

	line.points = [to_local(gp1), to_local(gp2)]

	var mid = (gp1 + gp2) * 0.5
	var dir = gp2 - gp1
	var perp = Vector2(-dir.y, dir.x).normalized()
	lbl.global_position = mid + perp * 12.0

	var length = (gp2 - gp1).length()
	var rect_shape = RectangleShape2D.new()
	rect_shape.extents = Vector2(length * 0.5, hit_width * 0.5)
	colshape.shape = rect_shape

	area.global_position = mid
	area.global_rotation = dir.angle()

func _on_area_2d_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_marcar_aceptada()
		grafo_ref.registrar_arista(self)   # ← NUEVO Y CORRECTO

func _marcar_aceptada() -> void:
	disabled = true
	area.monitoring = false
	line.default_color = color_accept
	line.width = line_width * 1.2

func reiniciar_visual() -> void:
	disabled = false
	area.monitoring = true
	colshape.disabled = false
	line.default_color = color_default
	line.width = line_width
