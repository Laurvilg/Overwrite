extends Node2D

# Script "GameManager" para tu escena principal RebuildNet.
# Adjunta este script al root de tu escena RebuildNet.tscn.
# - Debe tener un hijo "Grafo" (Node2D) con el script Grafo.gd.
# - Debe tener un hijo "UI" (CanvasLayer) con Label "Label_Status" y Button "Button_Reset".
# Este script conecta el botón Reset y provee una función simple para mostrar texto en la UI.

@onready var grafo := $Grafo if has_node("Grafo") else null
@onready var ui_label := $UI/Label_Status if has_node("UI/Label_Status") else null
@onready var btn_reset := $UI/Button_Reset if has_node("UI/Button_Reset") else null

func _ready() -> void:
	# Conectar botón Reset
	if btn_reset:
		btn_reset.pressed.connect(Callable(self, "_on_reset_pressed"))
	# Si el grafo existe y declara una propiedad status_label, podemos intentar asignarla
	# (esto es opcional y seguro si Grafo.gd declara `var status_label`).
	if is_instance_valid(grafo):
		# Intentamos asignar la referencia al label para que Grafo pueda actualizarlo directamente.
		# Si Grafo no tiene esa variable, la asignación no provoca nada crítico si se hace con set().
		# Usamos call_deferred para evitar problemas de orden de _ready.
		if ui_label:
			grafo.call_deferred("_update_status", "Listo. Generando red...")
			# también intentamos asignar la propiedad status_label si existe en el script de grafo
			if "status_label" in grafo: # comprobación segura en tiempo de ejecución (GDScript permite esto)
				grafo.status_label = ui_label
			else:
				# si la propiedad no existe, Grafo.gd ya busca Label_Status globalmente; no hacemos nada.
				pass

func _on_reset_pressed() -> void:
	if is_instance_valid(grafo):
		grafo.resetear_grafo()
		_show_status("Nueva red generada.")

# Método público para que otros nodos muestren texto en el UI
func _show_status(text: String) -> void:
	if is_instance_valid(ui_label):
		ui_label.text = text
	else:
		# si el label no está en esta escena, buscar globalmente
		var u = get_tree().get_root().find_node("Label_Status", true, false)
		if u:
			u.text = text

# Helpers opcionales que puedes usar desde el editor o desde otros scripts:
# Llamar grafo.generar_grafo() manualmente
func generar_grafo() -> void:
	if is_instance_valid(grafo) and grafo.has_method("generar_grafo"):
		grafo.generar_grafo()

# Llamar grafo.resetear_grafo() manualmente (alias)
func resetear_grafo() -> void:
	_on_reset_pressed()
