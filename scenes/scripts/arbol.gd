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
	if nuevo.dato["valor"] < nodo.dato["valor"]:
		if nodo.izq == null:
			nodo.izq = nuevo
		else:
			_agregar_recursivo(nodo.izq, nuevo)
	else:
		if nodo.der == null:
			nodo.der = nuevo
		else:
			_agregar_recursivo(nodo.der, nuevo)

func buscar_nodo(valor: int) -> Nodo:
	return _buscar_recursivo(raiz, valor)

func _buscar_recursivo(nodo: Nodo, valor: int) -> Nodo:
	if nodo == null:
		return null
	var actual_valor = nodo.dato["valor"]
	if valor == actual_valor:
		return nodo
	elif valor < actual_valor:
		return _buscar_recursivo(nodo.izq, valor)
	else:
		return _buscar_recursivo(nodo.der, valor)

func cambiar_estado(valor: int, nuevo_estado: bool) -> bool:
	var nodo = buscar_nodo(valor)
	if nodo == null:
		return false
	nodo.dato["completado"] = nuevo_estado
	return true

func verificar_todos_completados(nodo: Nodo = raiz) -> bool:
	if nodo == null:
		return true
	if not nodo.dato["completado"]:
		return false
	return verificar_todos_completados(nodo.izq) and verificar_todos_completados(nodo.der)
