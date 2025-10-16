extends Area2D                         # Este script pertenece a un nodo Area2D, que detecta clics de mouse sobre zonas del mapa.

var EnemyScene = preload("res://scenes/enemigo1/enemigo1.tscn")   # Carga en memoria la escena del enemigo base que se instanciará en cada zona.
var zonas_completadas := {1: false, 2: false, 3: false, 4: false, 5: false, 6: false}   # Diccionario para marcar si cada zona ya fue completada.
var juego_finalizado := false          # Variable booleana que indica si ya se completó el juego.
var puede_activar_nodo_central := false   # Controla si el nodo central puede activarse (solo cuando todas las zonas estén completas).
var shape_idx_nodo_central := 0        # Índice del área del nodo central (para detectar clics sobre él).
var raiz: Nodo = null                  # Variable que guardará la raíz del árbol ABB (inicia vacío).

var zonas := {                         # Configuración de cada zona del mapa.
	1: {"max_enemigos": 3, "spawn": "Enemy1Spawn"},      # Zona 1 con máximo 3 enemigos y punto de spawn llamado “Enemy1Spawn”.
	2: {"max_enemigos": 1, "spawn": "Enemy1Spawn2"},     # Zona 2, máximo 1 enemigo.
	3: {"max_enemigos": 4, "spawn": "Enemy1Spawn3"},     # Zona 3, máximo 4 enemigos.
	4: {"max_enemigos": 7, "spawn": "Enemy1Spawn4"},     # Zona 4, máximo 7 enemigos.
	5: {"max_enemigos": 6, "spawn": "Enemy1Spawn5"},     # Zona 5, máximo 6 enemigos.
	6: {"max_enemigos": 8, "spawn": "Enemy1Spawn6"},     # Zona 6, máximo 8 enemigos.
}

var enemigos_generados := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}   # Cuántos enemigos se han generado por zona.
var enemigos_vivos :=     {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}   # Cuántos enemigos siguen activos en cada zona.
var enemigos_removidos := {1: 0, 2: 0, 3: 0, 4: 0, 5: 0, 6: 0}   # Cuántos enemigos ya fueron eliminados por completo.
var zona_activada :=      {1: false, 2: false, 3: false, 4: false, 5: false, 6: false}   # Evita activar dos veces una misma zona.

var escenas_por_zona := {                                       # Asocia cada zona con la escena que se abrirá al completarla.
	1: preload("res://minijuego/juego.tscn"),                   # Zona 1 abre un minijuego.
	2: preload("res://pantallasPreguntas/preg1.tscn"),          # Zona 2 abre una pantalla de pregunta 1.
	3: preload("res://pantallasPreguntas/preg2.tscn"),          # Zona 3 abre la pregunta 2.
	4: preload("res://minijuego/juego.tscn"),                   # Zona 4 vuelve a minijuego.
	5: preload("res://pantallasPreguntas/preg3.tscn"),          # Zona 5 muestra pregunta 3.
	6: preload("res://pantallasPreguntas/preg4.tscn"),          # Zona 6 muestra pregunta 4.
}

func agregar_recursivo(nodo: Nodo, nuevo: Nodo) -> void:          # Inserta un nuevo nodo en el árbol ABB de manera recursiva
	if nuevo.dato["valor"] < nodo.dato["valor"]:                 # Si el valor del nuevo nodo es menor al actual, va por la izquierda
		if nodo.izq == null:                                    # Si no hay hijo izquierdo, lo asigna
			nodo.izq = nuevo
		else:                                                    # Si sí hay, vuelve a llamar la función recursiva
			agregar_recursivo(nodo.izq, nuevo)
	else:                                                         # Si el valor es mayor o igual, va por la derecha
		if nodo.der == null:
			nodo.der = nuevo
		else:
			agregar_recursivo(nodo.der, nuevo)

func buscar_nodo(valor: int) -> Nodo:                             # Busca un nodo dentro del árbol por su valor
	return _buscar_recursivo(raiz, valor)                         # Llama a la función interna de búsqueda desde la raíz

func _buscar_recursivo(nodo: Nodo, valor: int) -> Nodo:           # Función recursiva que recorre el árbol buscando el valor
	if nodo == null:                                              # Si el nodo es nulo, significa que no se encontró
		return null
	var actual_valor = nodo.dato["valor"]                         # Obtiene el valor almacenado en el nodo actual
	if valor == actual_valor:                                     # Si coincide, retorna el nodo
		return nodo
		
	elif valor < actual_valor:                                    # Si es menor, busca en el subárbol izquierdo
		return _buscar_recursivo(nodo.izq, valor)
	else:                                                         # Si es mayor, busca en el subárbol derecho
		return _buscar_recursivo(nodo.der, valor)

func cambiar_estado(valor: int, nuevo_estado: bool) -> bool:      # Cambia el estado de completado de una zona en el árbol.
	var nodo = buscar_nodo(valor)                                 # Busca el nodo que corresponde al valor.
	if nodo == null:                                              # Si no lo encuentra, retorna falso.
		return false
	nodo.dato["completado"] = nuevo_estado                        # Actualiza el campo 'completado' en el diccionario del nodo.
	return true

func agregar_nodo(dato: Dictionary) -> void:                      # Agrega un nuevo nodo al ABB usando un diccionario con datos.
	var nuevo_nodo = Nodo.new(dato)                               # Crea una instancia del nodo con el diccionario dado.
	if raiz == null:                                              # Si la raíz está vacía, este será el primer nodo.
		raiz = nuevo_nodo
	else:                                                         # Si ya hay raíz, se inserta recursivamente en su posición.
		agregar_recursivo(raiz, nuevo_nodo)

func _ready():                                                    # Se ejecuta cuando el nodo se inicia en la escena.
	set_pickable(true)                                            # Hace que el Area2D detecte clics del mouse.
	print("Area2D lista. Esperando clic en shape_idx=1,2,3,4,5,6") # Mensaje de depuración en consola.
	for zona_id in zonas.keys():                                  # Recorre todas las zonas definidas.
		var nodo_data = {                                         # Crea los datos del nodo para el árbol.
			"valor": zona_id,                                     # Guarda el número de la zona como valor clave.
			"activado": false,                                    # Marca si se activó (no se usa mucho aquí).
			"completado": false                                  # Marca si ya se completó.
		}
		agregar_nodo(nodo_data)                                   # Inserta ese nodo en el ABB.
	print("Árbol ABB creado con zonas:", zonas.keys())             # Confirma en consola que el árbol se generó.

func _input_event(viewport, event, shape_idx):                    # Captura eventos de clic en el área.
	print("Input event recibido. shape_idx:", shape_idx, "zona_activada:", zona_activada) # Imprime debug.
	if event is InputEventMouseButton and event.pressed:           # Solo responde a clics del mouse.
		if zonas.has(shape_idx) and !zona_activada[shape_idx]:     # Si el clic corresponde a una zona aún no activada...
			zona_activada[shape_idx] = true                        # La marca como activada.
			generar_un_enemigo(shape_idx)                          # Llama a la función para generar el primer enemigo.
		elif shape_idx == shape_idx_nodo_central:                  # Si se hace clic en el nodo central...
			if puede_activar_nodo_central:                         # Solo si ya está permitido.
				mostrar_pantalla_victoria()                        # Muestra la pantalla de victoria.
			else:
				print("Aún no puedes activar el nodo central")     # Si no, muestra mensaje en consola.

func generar_un_enemigo(shape_idx):                               # Genera un enemigo en la zona indicada.
	var zona = zonas[shape_idx]                                   # Obtiene los datos de esa zona.
	if enemigos_generados[shape_idx] < zona["max_enemigos"]:      # Comprueba si aún no alcanzó el máximo de enemigos.
		var root = get_parent().get_parent()                      # Sube dos niveles en la jerarquía para acceder al nodo raíz del mapa.
		var spawn_marker = root.get_node(zona["spawn"])           # Busca el punto de spawn según el nombre guardado.
		if spawn_marker:                                          # Si lo encuentra...
			var enemy_instance = EnemyScene.instantiate()          # Crea una instancia del enemigo.
			enemy_instance.global_position = spawn_marker.global_position   # Posiciona al enemigo en el punto de spawn.
			enemy_instance.connect("enemy_defeated", Callable(self, "_on_enemy_defeated").bind(shape_idx))  # Conecta señal cuando es derrotado.
			enemy_instance.connect("enemy_fully_removed", Callable(self, "_on_enemy_fully_removed").bind(shape_idx)) # Señal al eliminarse.
			root.add_child(enemy_instance)                         # Añade el enemigo a la escena.
			enemigos_generados[shape_idx] += 1                      # Suma al contador de generados.
			enemigos_vivos[shape_idx] += 1                          # Suma al contador de vivos.
	else:
		print("Ya se generaron todos los enemigos de esta zona.")  # Si ya llegó al máximo, muestra aviso.

func _on_enemy_defeated(shape_idx):                               # Función cuando un enemigo muere en combate.
	enemigos_vivos[shape_idx] -= 1                                # Resta uno al contador de vivos.
	if enemigos_generados[shape_idx] < zonas[shape_idx]["max_enemigos"]:  # Si aún faltan por generar...
		generar_un_enemigo(shape_idx)                             # Crea el siguiente enemigo.

func _on_enemy_fully_removed(shape_idx):                          # Se ejecuta cuando el enemigo es completamente eliminado.
	enemigos_removidos[shape_idx] += 1                            # Suma al contador de removidos.
	if enemigos_removidos[shape_idx] == zonas[shape_idx]["max_enemigos"]:  # Si ya se eliminaron todos los de la zona...
		cambiar_estado(shape_idx, true)                           # Marca el nodo del árbol como completado.
		print("Zona", shape_idx, "marcada como completada en el árbol ABB")  # Mensaje de confirmación.

		enemigos_generados[shape_idx] = 0                         # Reinicia los contadores de esa zona.
		enemigos_vivos[shape_idx] = 0
		enemigos_removidos[shape_idx] = 0
		zona_activada[shape_idx] = false
		zonas_completadas[shape_idx] = true                        # Marca la zona como completada globalmente.

		var escena = escenas_por_zona[shape_idx].instantiate()     # Carga la escena correspondiente (pregunta o minijuego).
		var overlay = get_tree().get_current_scene().get_node("Overlay") # Busca el overlay principal donde se agregan escenas.
		overlay.add_child(escena)                                 # Añade la escena al overlay.
		escena.connect("minijuego_completado", Callable(self, "_on_minijuego_completado").bind(shape_idx))  # Conecta la señal de completado.

		if verificar_todos_completados(raiz) and not juego_finalizado:   # Si todas las zonas del ABB están completadas y no ha finalizado...
			juego_finalizado = true                                    # Marca el juego como finalizado.
			_mostrar_mensaje_final()                                   # Muestra el mensaje final.
			_activar_nodo_central()                                    # Activa el nodo central.

func _on_minijuego_completado(shape_idx):                          # Se ejecuta al completar un minijuego o pregunta.
	cambiar_estado(shape_idx, true)                                # Marca la zona como completada en el árbol.
	if verificar_todos_completados(raiz) and not juego_finalizado: # Si todo el ABB está completado...
		juego_finalizado = true
		_mostrar_mensaje_final()
		_activar_nodo_central()

class Nodo:                                                       # Definición de la clase Nodo (estructura del árbol ABB).
	var dato: Dictionary                                           # Guarda un diccionario con los datos del nodo (valor, completado...).
	var izq: Nodo = null                                           # Referencia al hijo izquierdo.
	var der: Nodo = null                                           # Referencia al hijo derecho.
	func _init(_dato: Dictionary):                                 # Constructor del nodo.
		dato = _dato                                                # Asigna el diccionario recibido.

func verificar_todos_completados(nodo: Nodo) -> bool:             # Recorre todo el árbol para verificar si todos los nodos están completados.
	if nodo == null:                                               # Caso base: si no hay nodo, devuelve verdadero.
		return true
	if not nodo.dato["completado"]:                                # Si encuentra uno que no está completado, devuelve falso.
		return false
	return verificar_todos_completados(nodo.izq) and verificar_todos_completados(nodo.der)  # Revisa recursivamente izquierda y derecha.

func _mostrar_mensaje_final():                                    # Muestra en pantalla el mensaje de victoria.
	var overlay = get_tree().get_current_scene().get_node("Overlay")
	var label = Label.new()
	label.text = "¡Dirígete al nodo central y activa la palanca para ganar!"
	label.name = "MensajeFinal"
	label.set_anchors_preset(Control.PRESET_CENTER)
	overlay.add_child(label)

func _activar_nodo_central():                                     # Permite activar el nodo central al finalizar todas las zonas.
	puede_activar_nodo_central = true
	print("Nodo central ACTIVADO, ahora puedes darle click.")

func mostrar_pantalla_victoria():                                 # Muestra la pantalla de victoria final.<
	var win_scene = preload("res://inicio/win.tscn").instantiate() # Carga la escena de victoria.
	var overlay = get_tree().get_current_scene().get_node("Overlay")
	overlay.add_child(win_scene)
	if overlay.has_node("MensajeFinal"):                           # Si aún hay mensaje final en pantalla, lo elimina.
		overlay.get_node("MensajeFinal").queue_free()
