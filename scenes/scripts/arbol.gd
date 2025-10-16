extends RefCounted
class_name Arbol

const Nodo = preload("res://scenes/scripts/nodo.gd")

var raiz: Nodo = null

func agregar_nodo(dato: Dictionary) -> void:
	var nuevo_nodo = Nodo.new(dato)
	if raiz == null:
		raiz = nuevo_nodo
	else:
		_agregar_recursivo(raiz, nuevo_nodo)

func _agregar_recursivo(nodo: Nodo, nuevo: Nodo) -> void:
	# ABB por dificultad: menor a la izquierda, mayor/igual a la derecha
	if nuevo.dato["valor"] < nodo.dato["valor"]:
		if nodo.izq == null:
			nodo.izq = nuevo
		else:
			_agregar_recursivo(nodo.izq, nuevo)
	elif nuevo.dato["valor"] > nodo.dato["valor"]:
		if nodo.der == null:
			nodo.der = nuevo
		else:
			_agregar_recursivo(nodo.der, nuevo)
	else:
		# Empate de dificultad: desempata por zona_id (opcional)
		if nuevo.dato.get("zona_id", 0) < nodo.dato.get("zona_id", 0):
			if nodo.izq == null: nodo.izq = nuevo
			else: _agregar_recursivo(nodo.izq, nuevo)
		else:
			if nodo.der == null: nodo.der = nuevo
			else: _agregar_recursivo(nodo.der, nuevo)

# ---- Búsquedas/actualizaciones por zona ----
func buscar_por_zona(zona_id: int, nodo: Nodo = raiz) -> Nodo:
	if nodo == null:
		return null
	if nodo.dato.get("zona_id") == zona_id:
		return nodo
	var izq = buscar_por_zona(zona_id, nodo.izq)
	return izq if izq != null else buscar_por_zona(zona_id, nodo.der)

func cambiar_estado_por_zona(zona_id: int, nuevo_estado: bool) -> bool:
	var n = buscar_por_zona(zona_id)
	if n == null:
		return false
	n.dato["completado"] = nuevo_estado
	return true

# ---- Verificaciones ----
func verificar_todos_completados(nodo: Nodo = raiz) -> bool:
	if nodo == null:
		return true
	if not nodo.dato.get("completado", false):
		return false
	return verificar_todos_completados(nodo.izq) and verificar_todos_completados(nodo.der)


func todos_menores_completados(d: int, nodo: Nodo = raiz) -> bool: #zonas menores completadas
	if nodo == null:
		return true
	var ok_este = true
	if nodo.dato["valor"] < d:
		ok_este = nodo.dato.get("completado", false)
	return ok_este and todos_menores_completados(d, nodo.izq) and todos_menores_completados(d, nodo.der)
