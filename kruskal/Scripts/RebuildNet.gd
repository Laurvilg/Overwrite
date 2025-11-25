extends Node2D

# Script "GameManager" para la escena RebuildNet.
# Controla el botón Reset (soft reset) y delega en el nodo Grafo.

@onready var grafo := $Grafo if has_node("Grafo") else null
@onready var ui_label := $UI/Label_Status if has_node("UI/Label_Status") else null
@onready var btn_reset := $UI/Button_Reset if has_node("UI/Button_Reset") else null
@onready var reset = $UI
@onready var inicio = $InicioPanel
@onready var grafo1  = $Grafo

func _ready() -> void:
	# conectar botón Reset (si no está conectado en el .tscn - dejar una sola conexión)
	if btn_reset and not btn_reset.pressed.is_connected(Callable(self, "_on_reset_pressed")):
		btn_reset.pressed.connect(Callable(self, "_on_reset_pressed"))
	# si el grafo existe, actualizar status inicial
	if is_instance_valid(grafo):
		if ui_label:
			grafo.call_deferred("_update_status", "Generando red...")
			if "status_label" in grafo:
				grafo.status_label = ui_label

# Soft reset: limpia selecciones, no regenera grafo ni randomiza pesos
func _on_reset_pressed() -> void:
	if is_instance_valid(grafo):
		if grafo.has_method("limpiar_selecciones"):
			grafo.limpiar_selecciones()
			_show_status("Selecciones reiniciadas.")
		else:
			# fallback: si no existe el método, regeneramos completo
			if grafo.has_method("resetear_grafo"):
				grafo.resetear_grafo()
				_show_status("Grafo regenerado (fallback).")

func _show_status(text: String) -> void:
	if is_instance_valid(ui_label):
		ui_label.text = text
	else:
		var u = get_tree().get_root().find_node("Label_Status", true, false)
		if u:
			u.text = text

func generar_grafo() -> void:
	if is_instance_valid(grafo) and grafo.has_method("generar_grafo"):
		grafo.generar_grafo()

func resetear_grafo() -> void:
	_on_reset_pressed()


func _on_texture_button_pressed() -> void:
	AudioManager.SFXPlayer.stream = preload("res://inicio/audio/button-305770.mp3")
	AudioManager.SFXPlayer.play()
	inicio.visible = false
	reset.visible = true
	grafo1.visible = true
