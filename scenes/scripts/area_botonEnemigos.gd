extends Area2D

var EnemyScene = preload("res://scenes/enemigo1/enemigo1.tscn")
var Arbol = preload("res://scenes/scripts/arbol.gd")

var zonas_completadas := {1: false, 2: false, 3: false, 4: false, 5: false, 6: false}
var juego_finalizado := false
var puede_activar_nodo_central := false
var shape_idx_nodo_central := 0
var arbol := Arbol.new()

var zonas := {
	1: {"max_enemigos": 3, "spawn": "Enemy1Spawn"},
	2: {"max_enemigos": 1, "spawn": "Enemy1Spawn2"},
	3: {"max_enemigos": 4, "spawn": "Enemy1Spawn3"},
	4: {"max_enemigos": 7, "spawn": "Enemy1Spawn4"},
	5: {"max_enemigos": 6, "spawn": "Enemy1Spawn5"},
	6: {"max_enemigos": 8, "spawn": "Enemy1Spawn6"},
}

var enemigos_generados := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
var enemigos_vivos :=     {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
var enemigos_removidos := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
var zona_activada :=      {1: false, 2: false, 3: false, 4: false, 5: false, 6: false}

var escenas_por_zona := {
	1: preload("res://minijuego/juego.tscn"),
	2: preload("res://pantallasPreguntas/preg1.tscn"),
	3: preload("res://pantallasPreguntas/preg2.tscn"),
	4: preload("res://minijuego/juego.tscn"),
	5: preload("res://pantallasPreguntas/preg3.tscn"),
	6: preload("res://pantallasPreguntas/preg4.tscn"),
}

func _ready():
	set_pickable(true)
	print("Area2D lista. Esperando clic en shape_idx=1,2,3,4,5,6")

	# Árbol ABB por dificultad
	for zona_id in zonas.keys():
		var dificultad = int(zonas[zona_id]["max_enemigos"])
		var nodo_data = {
			"valor": dificultad,
			"zona_id": zona_id,
			"activado": false,
			"completado": false
		}
		arbol.agregar_nodo(nodo_data)

	print("Árbol ABB por dificultad creado. In-order:", arbol.inorder_list())

func _input_event(viewport, event, shape_idx):
	if event is InputEventMouseButton and event.pressed:
		if zonas.has(shape_idx):
			# ⛔ Si ya se completó, no permite volver a iniciar
			if zonas_completadas[shape_idx]:
				print("La zona", shape_idx, "ya fue completada. No se puede reiniciar.")
				return

			if !zona_activada[shape_idx]:
				zona_activada[shape_idx] = true
				generar_un_enemigo(shape_idx)
		elif shape_idx == shape_idx_nodo_central:
			if puede_activar_nodo_central:
				mostrar_pantalla_victoria()
			else:
				print("Aún no puedes activar el nodo central")


func generar_un_enemigo(shape_idx):
	# ⛔ Seguridad extra: no generar si la zona ya está completada
	if zonas_completadas[shape_idx]:
		return

	var zona = zonas[shape_idx]
	if enemigos_generados[shape_idx] < zona["max_enemigos"]:
		var root = get_parent().get_parent()
		var spawn_marker = root.get_node(zona["spawn"])
		if spawn_marker:
			var enemy_instance = EnemyScene.instantiate()
			enemy_instance.global_position = spawn_marker.global_position
			enemy_instance.connect("enemy_defeated", Callable(self, "_on_enemy_defeated").bind(shape_idx))
			enemy_instance.connect("enemy_fully_removed", Callable(self, "_on_enemy_fully_removed").bind(shape_idx))
			root.add_child(enemy_instance)
			enemigos_generados[shape_idx] += 1
			enemigos_vivos[shape_idx] += 1
	else:
		print("Ya se generaron todos los enemigos de esta zona.")


func _on_enemy_defeated(shape_idx):
	enemigos_vivos[shape_idx] -= 1
	if enemigos_generados[shape_idx] < zonas[shape_idx]["max_enemigos"]:
		generar_un_enemigo(shape_idx)

func _on_enemy_fully_removed(shape_idx):
	enemigos_removidos[shape_idx] += 1
	if enemigos_removidos[shape_idx] == zonas[shape_idx]["max_enemigos"]:
		arbol.cambiar_estado_por_zona(shape_idx, true)
		print("Zona", shape_idx, "completada en ABB (por dificultad).")

		enemigos_generados[shape_idx] = 0
		enemigos_vivos[shape_idx] = 0
		enemigos_removidos[shape_idx] = 0
		zona_activada[shape_idx] = false
		zonas_completadas[shape_idx] = true

		var escena = escenas_por_zona[shape_idx].instantiate()
		var overlay = get_tree().get_current_scene().get_node("Overlay")
		overlay.add_child(escena)
		escena.connect("minijuego_completado", Callable(self, "_on_minijuego_completado").bind(shape_idx))

		if arbol.verificar_todos_completados() and not juego_finalizado:
			juego_finalizado = true
			_mostrar_mensaje_final()
			_activar_nodo_central()

func _on_minijuego_completado(shape_idx):
	arbol.cambiar_estado_por_zona(shape_idx, true)
	if arbol.verificar_todos_completados() and not juego_finalizado:
		juego_finalizado = true
		_mostrar_mensaje_final()
		_activar_nodo_central()

func _mostrar_mensaje_final():
	var overlay = get_tree().get_current_scene().get_node("Overlay")
	var label = Label.new()
	label.text = "¡Dirígete al nodo central y activa la palanca para ganar!"
	label.name = "MensajeFinal"
	label.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(label)

func _activar_nodo_central():
	puede_activar_nodo_central = true
	print("Nodo central ACTIVADO, ahora puedes darle click.")

func mostrar_pantalla_victoria():
	var win_scene = preload("res://inicio/win.tscn").instantiate()
	var overlay = get_tree().get_current_scene().get_node("Overlay")
	overlay.add_child(win_scene)
	if overlay.has_node("MensajeFinal"):
		overlay.get_node("MensajeFinal").queue_free()
