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

# flag para indicar si esta arista pertenece al MST calculado (usada internamente, no visible)
var es_mst: bool = false

@onready var line: Line2D = $Line2D
@onready var lbl: Label = $Label
@onready var area: Area2D = $Area2D
@onready var colshape: CollisionShape2D = $Area2D/CollisionShape2D

func _ready() -> void:
	for a in get_tree().get_nodes_in_group("aristas"):
		if not is_instance_valid(a.nodo_origen) or not is_instance_valid(a.nodo_destino):
			continue
			print("ARISTA:", a.nodo_origen.nombre, "-", a.nodo_destino.nombre, "instancia:", a)

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
	es_mst = false
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
	var gp1: Vector2 = nodo_origen.global_position
	var gp2: Vector2 = nodo_destino.global_position
	var lp1: Vector2 = to_local(gp1)
	var lp2: Vector2 = to_local(gp2)
	line.points = [lp1, lp2]
	var mid := (gp1 + gp2) * 0.5
	var dir := gp2 - gp1
	var perp := Vector2(-dir.y, dir.x)
	if perp.length() > 0:
		perp = perp.normalized()
	var offset_amount := 12.0
	# Posición label: ajusta especialmente para la arista b-d
	var custom_offset := offset_amount
	if (
		(nodo_origen.nombre == "b" and nodo_destino.nombre == "d") or
		(nodo_origen.nombre == "d" and nodo_destino.nombre == "b")
		):
			custom_offset = -10.0 # prueba este valor, puedes aumentarlo si quieres
	lbl.global_position = mid + perp * custom_offset
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
		var origen: String = nodo_origen.nombre if "nombre" in nodo_origen else nodo_origen.name
		var destino: String = nodo_destino.nombre if "nombre" in nodo_destino else nodo_destino.name
		var ok: bool = grafo_ref.intentar_conectar(origen, destino, peso)
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

func reiniciar_visual() -> void:
	# soft reset visual: vuelve al aspecto por defecto independientemente de es_mst
	disabled = false
	if is_instance_valid(area):
		area.monitoring = true
	line.default_color = color_default
	line.width = line_width

# marcar_mst solo cambia la flag interna, NO altera color ni visual
func marcar_mst() -> void:
	es_mst = true

func desmarcar_mst() -> void:
	es_mst = false
	# no alterar apariencia aquí (reiniciar_visual deja el visual por defecto)
