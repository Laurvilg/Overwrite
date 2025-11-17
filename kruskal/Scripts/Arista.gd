extends Node2D

signal clicked(arista)

@export var hit_width: float = 10.0
@export var line_width: float = 2.0
@export var color_default: Color = Color(0.85, 0.85, 0.85)
@export var color_accept: Color = Color(0.1, 0.85, 0.25)
@export var color_reject: Color = Color(1, 0.35, 0.35)

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
	# z-order: aristas debajo
	z_index = 0
	line.z_index = 0
	lbl.z_index = 1
	line.width = line_width
	line.default_color = color_default
	lbl.scale = Vector2(0.85, 0.85)
	if is_instance_valid(area):
		area.input_event.connect(Callable(self, "_on_area_input_event"))

func configurar(nodo_a: Node, nodo_b: Node, peso_valor: int, grafo_node: Node) -> void:
	nodo_origen = nodo_a
	nodo_destino = nodo_b
	peso = peso_valor
	grafo_ref = grafo_node
	lbl.text = str(peso)
	_actualizar_dibujo()
	disabled = false
	if is_instance_valid(area):
		area.monitoring = true

func _process(_delta: float) -> void:
	_actualizar_dibujo()

func _actualizar_dibujo() -> void:
	if not is_instance_valid(nodo_origen) or not is_instance_valid(nodo_destino):
		line.visible = false
		lbl.visible = false
		return
	line.visible = true
	lbl.visible = true

	# posiciones globales
	var gp1: Vector2 = nodo_origen.global_position
	var gp2: Vector2 = nodo_destino.global_position

	# convertir a locales (Line2D espera puntos relativos al Node2D)
	var lp1: Vector2 = to_local(gp1)
	var lp2: Vector2 = to_local(gp2)
	line.points = [lp1, lp2]

	# label: medio + desplazamiento perpendicular para evitar solapamiento
	var mid := (gp1 + gp2) * 0.5
	var dir := gp2 - gp1
	var perp := Vector2(-dir.y, dir.x)
	if perp.length() > 0:
		perp = perp.normalized()
	var offset_amount := 12.0
	lbl.global_position = mid + perp * offset_amount

	# collision shape (rect centrado y rotado)
	var length := dir.length()
	if is_instance_valid(colshape):
		var rect_shape := RectangleShape2D.new()
		rect_shape.extents = Vector2(length * 0.5, hit_width * 0.5)
		colshape.shape = rect_shape
		area.global_position = mid
		area.global_rotation = dir.angle()

func _on_area_input_event(_viewport, event: InputEvent, _shape_idx: int) -> void:
	if disabled:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not is_instance_valid(grafo_ref) or not grafo_ref.has_method("intentar_conectar"):
			return
		if not is_instance_valid(nodo_origen) or not is_instance_valid(nodo_destino):
			return
		var ok: bool = grafo_ref.intentar_conectar(nodo_origen.nombre, nodo_destino.nombre, peso)
		if ok:
			_marcar_aceptada()
			emit_signal("clicked", self)
		else:
			_marcar_rechazada_temporal()
			emit_signal("clicked", self)

func _marcar_aceptada() -> void:
	disabled = true
	if is_instance_valid(area):
		area.monitoring = false
	line.default_color = color_accept
	line.width = line_width * 1.2

func _marcar_rechazada_temporal() -> void:
	line.default_color = color_reject
	await get_tree().create_timer(0.35).timeout
	if not disabled:
		line.default_color = color_default
		line.width = line_width

# Método público para restaurar la arista a su estado inicial (soft-reset)
func reiniciar_visual() -> void:
	disabled = false
	if is_instance_valid(area):
		area.monitoring = true
	line.default_color = color_default
	line.width = line_width
