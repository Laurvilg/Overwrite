extends Node2D

signal clicked(arista)

var nodo_origen: Node = null
var nodo_destino: Node = null
var peso: int = 0
var grafo_ref: Node = null
var disabled: bool = false

@onready var line: Line2D = $Line2D
@onready var lbl: Label = $Label
@onready var area: Area2D = $Area2D

func _ready() -> void:
	# conectar signal del Area2D de forma robusta
	if is_instance_valid(area):
		area.connect("input_event", Callable(self, "_on_area_input_event"))

func configurar(nodo_a: Node, nodo_b: Node, peso_valor: int, grafo_node: Node) -> void:
	nodo_origen = nodo_a
	nodo_destino = nodo_b
	peso = peso_valor
	grafo_ref = grafo_node
	lbl.text = str(peso)
	_actualizar_dibujo()
	if is_instance_valid(area):
		area.monitoring = true
	disabled = false

func _process(_delta: float) -> void:
	_actualizar_dibujo()

func _actualizar_dibujo() -> void:
	# protección contra nodos nulos/eliminados
	if not is_instance_valid(nodo_origen) or not is_instance_valid(nodo_destino):
		line.visible = false
		lbl.visible = false
		return
	line.visible = true
	lbl.visible = true
	var p1: Vector2 = nodo_origen.global_position
	var p2: Vector2 = nodo_destino.global_position
	line.points = [p1, p2]
	lbl.global_position = (p1 + p2) * 0.5

func _on_area_input_event(viewport, event: InputEvent, shape_idx: int) -> void:
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
		else:
			_marcar_rechazada_temporal()

func _marcar_aceptada() -> void:
	disabled = true
	if is_instance_valid(area):
		area.monitoring = false
	line.default_color = Color(0, 1, 0)

func _marcar_rechazada_temporal() -> void:
	line.default_color = Color(1, 0, 0)
	await get_tree().create_timer(0.35).timeout
	if not disabled:
		line.default_color = Color(0.5, 0.5, 0.5)
