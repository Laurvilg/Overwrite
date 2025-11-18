# NodeButton.gd
extends Button
# Prefab para cada nodo del grafo (debe ser un Button/Control)

@export var node_id: int = -1

# valor que indica en qué posición de la secuencia debería tocarse este botón
var expected_index: int = -1

# estado visual
var default_color := Color(0.95, 0.95, 0.95)
var highlight_color := Color(1, 1, 0.6)
var wrong_color := Color(1, 0.4, 0.4)
var cleaned_color := Color(0.6, 1, 0.6)

func _ready() -> void:
	# asegurar tamaño/hitbox opcional
	if Engine.is_editor_hint():
		return
	# mostrar id para que el jugador sepa cuál es cada botón
	text = str(node_id)
	_update_visual()

func set_expected_index(idx: int) -> void:
	expected_index = idx

func clear_expected_index() -> void:
	expected_index = -1
	_update_visual()

func mark_cleaned() -> void:
	disabled = true
	modulate = cleaned_color

func highlight_once() -> void:
	# pulso visual
	var prev = modulate
	modulate = highlight_color
	var t = create_tween()
	t.tween_property(self, "modulate", prev, 0.28)

func play_wrong() -> void:
	var prev = modulate
	modulate = wrong_color
	var t = create_tween()
	t.tween_property(self, "modulate", prev, 0.28)

func _update_visual() -> void:
	modulate = default_color
