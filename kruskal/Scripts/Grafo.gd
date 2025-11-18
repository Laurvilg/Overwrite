extends Node2D

@export var AristaScene: PackedScene
@export var NodoScene: PackedScene

var nodos: Array[Node] = []
var aristas: Array[Node] = []

var cantidad_nodos := 0
var aceptadas := 0
var costo_total := 0
var mst_weight := 0

var dsu_parent := {}
var dsu_rank := {}

var accepted_aristas: Array = []
var accepted_nodes: Array = []

# -------------------------------------------------------
# READY
# -------------------------------------------------------
func _ready() -> void:
	resetear_grafo()

# -------------------------------------------------------
# RESET TOTAL
# -------------------------------------------------------
func resetear_grafo() -> void:
	for a in aristas:
		if is_instance_valid(a):
			a.queue_free()
	aristas.clear()

	for n in nodos:
		if is_instance_valid(n):
			n.queue_free()
	nodos.clear()

	aceptadas = 0
	costo_total = 0
	mst_weight = 0
	accepted_aristas.clear()
	accepted_nodes.clear()

	_crear_nodos_y_aristas_fijos()
	_iniciar_dsu()
	_calcular_mst_precargado()
	_update_status("Listo. Construye tu MST.")

# -------------------------------------------------------
# CREAR NODOS Y ARISTAS FIJOS PARA GRAFO CUADRADO
# -------------------------------------------------------
func _crear_nodos_y_aristas_fijos():
	nodos.clear()
	aristas.clear()
	var posiciones = {
		"a": Vector2(150, 380),
		"b": Vector2(480, 420),
		"c": Vector2(800, 200),
		"d": Vector2(1020, 330),
		"e": Vector2(620, 200),
		"f": Vector2(340, 180),
		"g": Vector2(100, 230),
		"h": Vector2(380, 300)
	}
	var nombres = ["a", "b", "c", "d", "e", "f", "g", "h"]

	# Crear cada nodo en su posición ideal para grafo cuadrado de Kruskal
	for nombre in nombres:
		var n = NodoScene.instantiate()
		add_child(n)
		n.set_nombre(nombre)
		n.position = posiciones[nombre]
		nodos.append(n)

	cantidad_nodos = nodos.size()

	# Definir conexiones grafo de ejemplo (NO paralelas)
	var edges = [
		["a","g"],
		["a","b"],
		["g","f"],
		["f","e"],
		["e","c"],
		["c","d"],
		["d","b"],
		["g","h"],
		["h","e"],
		["h","b"],
		["a","h"],
		["b","c"]
	]

	for edge in edges:
		var n1 = _find_node_by_name(edge[0])
		var n2 = _find_node_by_name(edge[1])
		var peso = randi() % 10 + 1
		_crear_arista_entre(n1, n2, peso)

# -------------------------------------------------------
# BUSQUEDA NODO POR NOMBRE
# -------------------------------------------------------
func _find_node_by_name(nombre):
	for n in nodos:
		if is_instance_valid(n) and n.nombre == nombre:
			return n
	return null

# -------------------------------------------------------
# CREAR ARISTA entre nodos, sin paralelas
# -------------------------------------------------------
func _crear_arista_entre(n1: Node, n2: Node, peso: int) -> void:
	var name1 = n1.nombre
	var name2 = n2.nombre
	var key = "%s|%s" % [name1, name2] if name1 < name2 else "%s|%s" % [name2, name1]

	for a in aristas:
		if not is_instance_valid(a): continue
		var aa = a.nodo_origen.nombre
		var bb = a.nodo_destino.nombre
		var existing = "%s|%s" % [aa, bb] if aa < bb else "%s|%s" % [bb, aa]
		if existing == key:
			return

	var ar = AristaScene.instantiate()
	var cont = $AristaContainer if has_node("AristaContainer") else self
	cont.add_child(ar)
	ar.configurar(n1, n2, peso, self)
	ar.connect("clicked", Callable(self, "_on_arista_clicked"))
	aristas.append(ar)

# -------------------------------------------------------
# DSU
# -------------------------------------------------------
func _iniciar_dsu() -> void:
	dsu_parent.clear()
	dsu_rank.clear()
	for n in nodos:
		var name = n.nombre
		dsu_parent[name] = name
		dsu_rank[name] = 0

func dsu_find(x: String) -> String:
	if dsu_parent[x] != x:
		dsu_parent[x] = dsu_find(dsu_parent[x])
	return dsu_parent[x]

func dsu_union(a: String, b: String) -> void:
	var pa = dsu_find(a)
	var pb = dsu_find(b)
	if pa == pb:
		return

	if dsu_rank[pa] < dsu_rank[pb]:
		dsu_parent[pa] = pb
	elif dsu_rank[pb] < dsu_rank[pa]:
		dsu_parent[pb] = pa
	else:
		dsu_parent[pb] = pa
		dsu_rank[pa] += 1

# -------------------------------------------------------
# BÚSQUEDA DE ARISTA
# -------------------------------------------------------
func _buscar_arista(a: String, b: String):
	for ar in aristas:
		if not is_instance_valid(ar): continue
		var aa = ar.nodo_origen.nombre
		var bb = ar.nodo_destino.nombre
		if (aa==a and bb==b) or (aa==b and bb==a):
			return ar
	return null

# -------------------------------------------------------
# CALCULO DEL MST REAL (Kruskal)
# -------------------------------------------------------
func _calcular_mst_precargado() -> void:
	var lista = []
	for ar in aristas:
		if is_instance_valid(ar):
			lista.append({"a":ar.nodo_origen.nombre, "b":ar.nodo_destino.nombre, "p": ar.peso})

	lista.sort_custom(func(a,b):
		return a["p"] < b["p"]
	)

	var parent2 = {}
	var rank2 = {}
	for n in nodos:
		parent2[n.nombre] = n.nombre
		rank2[n.nombre] = 0

	mst_weight = 0
	for e in lista:
		if fnd(e["a"], parent2) != fnd(e["b"], parent2):
			un(e["a"], e["b"], parent2, rank2)
			mst_weight += e["p"]

func fnd(x, parent2):
	if parent2[x] != x:
		parent2[x] = fnd(parent2[x], parent2)
	return parent2[x]

func un(a, b, parent2, rank2):
	var pa = fnd(a, parent2)
	var pb = fnd(b, parent2)
	if pa == pb:
		return
	if rank2[pa] < rank2[pb]:
		parent2[pa] = pb
	elif rank2[pb] < rank2[pa]:
		parent2[pb] = pa
	else:
		parent2[pb] = pa
		rank2[pa] += 1

# -------------------------------------------------------
# CLIC EN ARISTA
# -------------------------------------------------------
func _on_arista_clicked(arista):
	pass

# -------------------------------------------------------
# INTENTAR CONECTAR NODOS AL HACER CLIC
# -------------------------------------------------------
func intentar_conectar(origen: String, destino: String, peso_valor: int) -> bool:
	if origen == "" or destino == "":
		return false

	for existing in accepted_aristas:
		if not is_instance_valid(existing): continue
		var ex_a = existing.nodo_origen.nombre
		var ex_b = existing.nodo_destino.nombre
		if (ex_a == origen and ex_b == destino) or (ex_a == destino and ex_b == origen):
			_update_status("❌ Ya has aceptado una arista entre estos dos nodos.")
			return false

	if dsu_find(origen) != dsu_find(destino):
		dsu_union(origen, destino)
		aceptadas += 1
		costo_total += int(peso_valor)

		if origen not in accepted_nodes:
			accepted_nodes.append(origen)
		if destino not in accepted_nodes:
			accepted_nodes.append(destino)

		accepted_aristas.append(_buscar_arista(origen, destino))

		_update_status("✔ Conexión %s–%s aceptada. Total: %d\nCosto mínimo (MST): %d"
			% [origen, destino, costo_total, mst_weight])

		if _buscar_arista(origen, destino).has_method("_marcar_aceptada"):
			_buscar_arista(origen, destino)._marcar_aceptada()

		if aceptadas == cantidad_nodos - 1:

			var root_set = {}
			for n in nodos:
				if is_instance_valid(n):
					var nombre = n.nombre
					var root = dsu_find(nombre)
					root_set[root] = true

			if root_set.size() != 1:
				_update_status("❌ Has quedado bloqueado.\nCosto mínimo (MST): %d" % mst_weight)
				return false

			if victoria_jugador():
				_update_status("🌐 ¡Red reconstruida! Costo: %d (mínimo: %d)" % [costo_total, mst_weight])
				_on_victory()
			else:
				_update_status("⚠️ Red conectada pero NO mínima"
					% [costo_total, calcular_mst_actual()["suma"]])
		return true

	else:
		_update_status("❌ Conexión inválida: forma ciclo")
		return false

# -------------------------------------------------------
# CALCULAR MST ACTUAL DEL JUGADOR
# -------------------------------------------------------
func calcular_mst_actual():
	return {"suma": costo_total}

# -------------------------------------------------------
# VICTORIA
# -------------------------------------------------------
func victoria_jugador() -> bool:
	return costo_total == mst_weight

func _on_victory():
	print("Victoria alcanzada.")

# -------------------------------------------------------
# TEXTO INFO
# -------------------------------------------------------
var status_text := ""  # historial de mensajes

func _update_status(t: String) -> void:
	var label = get_node("../UI/Label_Status")
	if label:
		label.text = t
	else:
		print("❌ No se encontró Label_Status")

	
# -------------------------------------------------------
# LIMPIAR SELECCIONES DEL JUGADOR (Soft reset)
# -------------------------------------------------------
func limpiar_selecciones() -> void:
	# limpiar datos internos
	aceptadas = 0
	costo_total = 0
	accepted_aristas.clear()
	accepted_nodes.clear()

	# restaurar visual en TODAS las aristas
	for ar in aristas:
		if is_instance_valid(ar) and ar.has_method("reiniciar_visual"):
			ar.reiniciar_visual()
