extends Area2D  # Este script controla el mapa/área clickeable y la lógica de enemigos por zona.

# ---------- Precargas y estructuras base ----------
var EnemyScene = preload("res://scenes/enemigo1/enemigo1.tscn")   # Escena del enemigo a instanciar.
var Arbol = preload("res://scenes/scripts/arbol.gd")              # Clase del ABB (progreso por dificultad).

# Estados globales de juego
var zonas_completadas := {1: false, 2: false, 3: false, 4: false, 5: false, 6: false}  # True cuando una zona ya se superó (no rejugable).
var juego_finalizado := false
var puede_activar_nodo_central := false
var shape_idx_nodo_central := 0  # Índice de colisión para el "nodo central" (palanca de victoria).
var arbol := Arbol.new()         # Instancia del Árbol Binario de Búsqueda (ABB) ordenado por dificultad.

# Configuración por zona: dificultad = max_enemigos, y el Marker donde spawnean
var zonas := {
	1: {"max_enemigos": 3, "spawn": "Enemy1Spawn"},
	2: {"max_enemigos": 1, "spawn": "Enemy1Spawn2"},
	3: {"max_enemigos": 4, "spawn": "Enemy1Spawn3"},
	4: {"max_enemigos": 7, "spawn": "Enemy1Spawn4"},
	5: {"max_enemigos": 6, "spawn": "Enemy1Spawn5"},
	6: {"max_enemigos": 8, "spawn": "Enemy1Spawn6"},
}

# Contadores de combate por zona
var enemigos_generados := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
var enemigos_vivos :=     {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
var enemigos_removidos := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}
var zona_activada :=      {1: false, 2: false, 3: false, 4: false, 5: false, 6: false}  # Evita doble activación simultánea.

# Qué minijuego/pantalla se abre al completar cada zona
var escenas_por_zona := {
	1: preload("res://minijuego/juego.tscn"),
	2: preload("res://pantallasPreguntas/preg1.tscn"),
	3: preload("res://pantallasPreguntas/preg2.tscn"),
	4: preload("res://minijuego/juego.tscn"),
	5: preload("res://pantallasPreguntas/preg3.tscn"),
	6: preload("res://pantallasPreguntas/preg4.tscn"),
}

func _ready():
	set_pickable(true)  # Permite que el Area2D reciba clics.
	print("Area2D lista. Esperando clic en shape_idx=1,2,3,4,5,6")

	# Por cada zona se crea un nodo en el ABB con:
	# valor = dificultad (max_enemigos), zona_id, y flags iniciales.
	for zona_id in zonas.keys():
		var dificultad = int(zonas[zona_id]["max_enemigos"])
		var nodo_data = {
			"valor": dificultad,   # Clave del ABB (ordena izquierda=fácil, derecha=difícil)
			"zona_id": zona_id,    # Referencia a la zona del mapa
			"activado": false,     # (no lo usas aquí, pero queda para futuro)
			"completado": false
		}
		arbol.agregar_nodo(nodo_data)


func _input_event(viewport, event, shape_idx):
	# Maneja click del mouse en las zonas o en el nodo central.
	if event is InputEventMouseButton and event.pressed:
		if zonas.has(shape_idx):
			# Si la zona ya fue completada, no se permite rejugar.
			if zonas_completadas[shape_idx]:
				print("La zona", shape_idx, "ya fue completada. No se puede reiniciar.")
				return

			# Evita re-activar si ya está en curso
			if !zona_activada[shape_idx]:
				zona_activada[shape_idx] = true
				generar_un_enemigo(shape_idx)  # Arranca la ronda para esa zona
		elif shape_idx == shape_idx_nodo_central:
			# Palanca final: solo funciona si se activó tras completar todas las zonas
			if puede_activar_nodo_central:
				mostrar_pantalla_victoria()
			else:
				print("Aún no puedes activar el nodo central")

func generar_un_enemigo(shape_idx):
	# Seguridad extra: nunca genera si la zona ya está completada (bloqueo pos-ronda)
	if zonas_completadas[shape_idx]:
		return

	var zona = zonas[shape_idx]
	# Genera enemigos hasta llegar al máximo de esa zona
	if enemigos_generados[shape_idx] < zona["max_enemigos"]:
		var root = get_parent().get_parent()              # Sube a un nodo común que contiene los Markers
		var spawn_marker = root.get_node(zona["spawn"])   # Busca el Marker/Position2D correspondiente
		if spawn_marker:
			var enemy_instance = EnemyScene.instantiate()
			enemy_instance.global_position = spawn_marker.global_position

			# Señales del enemigo:
			# enemy_fully_removed: desapareció del árbol de nodos (limpieza completa)
			enemy_instance.connect("enemy_defeated", Callable(self, "_on_enemy_defeated").bind(shape_idx))
			enemy_instance.connect("enemy_fully_removed", Callable(self, "_on_enemy_fully_removed").bind(shape_idx))

			root.add_child(enemy_instance)

			# Actualiza contadores
			enemigos_generados[shape_idx] += 1
			enemigos_vivos[shape_idx] += 1
	else:
		print("Ya se generaron todos los enemigos de esta zona.")  # No genera más de los permitidos.

func _on_enemy_defeated(shape_idx):
	# Cuando un enemigo “muere” pero se vuelven a regenerar
	enemigos_vivos[shape_idx] -= 1

	# Si aún no se alcanza el máximo de esa zona se genera el siguiente
	if enemigos_generados[shape_idx] < zonas[shape_idx]["max_enemigos"]:
		generar_un_enemigo(shape_idx)

func _on_enemy_fully_removed(shape_idx):
	
	enemigos_removidos[shape_idx] += 1 # Cuando la instancia del enemigo ya fue removida completamente del árbol de nodos

	# Si ya se removieron tantos como el máximo de la zona, la zona se considera “limpia”
	if enemigos_removidos[shape_idx] == zonas[shape_idx]["max_enemigos"]:
		arbol.cambiar_estado_por_zona(shape_idx, true)  # Marca la zona como completada dentro del ABB (progreso)
		print("Zona", shape_idx, "completada en ABB (por dificultad).")

		# Resetea contadores operativos de esa zona pero NO permite rejugar porque zonas_completadas queda en true
		enemigos_generados[shape_idx] = 0
		enemigos_vivos[shape_idx] = 0
		enemigos_removidos[shape_idx] = 0
		zona_activada[shape_idx] = false
		zonas_completadas[shape_idx] = true  # Bloquea futuros intentos

		# Abre el minijuego/pregunta asociada a esa zona
		var escena = escenas_por_zona[shape_idx].instantiate()
		var overlay = get_tree().get_current_scene().get_node("Overlay")
		overlay.add_child(escena)
		# Cuando el minijuego emite “minijuego_completado”, llamamos a nuestro handler con el shape_idx
		escena.connect("minijuego_completado", Callable(self, "_on_minijuego_completado").bind(shape_idx))

		# Si TODAS las zonas están completadas (según el ABB), activamos el nodo central y mostramos mensaje final
		if arbol.verificar_todos_completados() and not juego_finalizado:
			juego_finalizado = true
			_mostrar_mensaje_final()
			_activar_nodo_central()

func _on_minijuego_completado(shape_idx):
	# Redundancia segura: marca completado por si el flujo llega directo del minijuego
	arbol.cambiar_estado_por_zona(shape_idx, true)

	# Si todo está completo en el ABB, activamos el final
	if arbol.verificar_todos_completados() and not juego_finalizado:
		juego_finalizado = true
		_mostrar_mensaje_final()
		_activar_nodo_central()

func _mostrar_mensaje_final():
	# Muestra un label centrado avisando que ya puedes ir al nodo central
	var overlay = get_tree().get_current_scene().get_node("Overlay")
	var label = Label.new()
	label.text = "¡Dirígete al nodo central y activa la palanca para ganar!"
	label.name = "MensajeFinal"
	label.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(label)

func _activar_nodo_central():
	# Habilita la interacción con el nodo central (palanca de victoria)
	puede_activar_nodo_central = true
	print("Nodo central ACTIVADO, ahora puedes darle click.")

func mostrar_pantalla_victoria():
	# Carga la escena de victoria y limpia el mensaje final si estaba en pantalla
	var win_scene = preload("res://inicio/win.tscn").instantiate()
	var overlay = get_tree().get_current_scene().get_node("Overlay")
	overlay.add_child(win_scene)
	if overlay.has_node("MensajeFinal"):
		overlay.get_node("MensajeFinal").queue_free()
