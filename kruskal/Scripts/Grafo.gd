extends Node2D

@export var NodoScene: PackedScene
@export var AristaScene: PackedScene

@export var cantidad_nodos: int = 6
@export var prob_arista: float = 0.35
@export var peso_min: int = 1
@export var peso_max: int = 10
@export var margin: int = 80

# Atlas opcional (si usas un atlas)
@export var atlas_texture: Texture2D
@export var atlas_cell_w: int = 64
@export var atlas_cell_h: int = 64
@export var base_sprite_scale: float = 1.0

var nodos: Array = []
var aristas: Array = []

var padre := {}
var rank := {}
var aceptadas: int = 0
var costo_total: int = 0

var rng := RandomNumberGenerator.new()
var status_label: Label = null

func _ready() -> void:
	rng.randomize()
	if NodoScene == null:
		NodoScene = preload("res://kruskal/Scenes/Nodo.tscn")
	if AristaScene == null:
		AristaScene = preload("res://kruskal/Scenes/Arista.tscn")
	if has_node("../UI/Label_Status"):
		status_label = $"../UI/Label_Status"
	else:
		status_label = get_tree().get_root().find_node("Label_Status", true, false)
	generar_grafo()

func resetear_grafo() -> void:
	for n in nodos:
		if is_instance_valid(n):
			n.queue_free()
	for a in aristas:
		if is_instance_valid(a):
			a.queue_free()
	nodos.clear()
	aristas.clear()
	padre.clear()
	rank.clear()
	aceptadas = 0
	costo_total = 0
	generar_grafo()
	_update_status("Nueva red generada.")

func generar_grafo() -> void:
	var nodo_container := $NodoContainer if has_node("NodoContainer") else null
	var arista_container := $AristaContainer if has_node("AristaContainer") else null
	if nodo_container == null:
		nodo_container = Node2D.new()
		nodo_container.name = "NodoContainer"
		add_child(nodo_container)
	if arista_container == null:
		arista_container = Node2D.new()
		arista_container.name = "AristaContainer"
		add_child(arista_container)

	var rect := Rect2(Vector2(margin, margin), get_viewport_rect().size - Vector2(margin*2, margin*2))

	# crear nodos
	for i in range(cantidad_nodos):
		var nscene: Node2D = NodoScene.instantiate()
		var name_chr := char(65 + i)
		# asignar textura desde atlas si corresponde
		if atlas_texture and nscene.has_method("set_texture_from_atlas"):
			var atlas_size := atlas_texture.get_size()
			var cols = max(1, int(atlas_size.x / atlas_cell_w))
			var rows = max(1, int(atlas_size.y / atlas_cell_h))
			var idx := rng.randi_range(0, cols * rows - 1)
			var cx = idx % cols
			var cy := int(idx / cols)
			var region := Rect2(cx * atlas_cell_w, cy * atlas_cell_h, atlas_cell_w, atlas_cell_h)
			nscene.call_deferred("set_texture_from_atlas", atlas_texture, region)
			if "base_scale" in nscene:
				nscene.base_scale = base_sprite_scale
		# nombre y posición
		if "nombre" in nscene:
			nscene.nombre = name_chr
		else:
			if nscene.has_method("set"):
				nscene.set("nombre", name_chr)
		nscene.position = Vector2(rng.randi_range(int(rect.position.x), int(rect.end.x)), rng.randi_range(int(rect.position.y), int(rect.end.y)))
		nodo_container.add_child(nscene)
		nodos.append(nscene)
		padre[name_chr] = name_chr
		rank[name_chr] = 0

	# asegurar conectividad: crear array de indices y barajarlo
	var indices: Array = []
	for j in range(cantidad_nodos):
		indices.append(j)
	indices.shuffle()

	for k in range(1, cantidad_nodos):
		var a_idx = indices[k]
		var b_idx := rng.randi_range(0, k - 1)
		_crear_arista_entre(nodos[a_idx], nodos[b_idx], rng.randi_range(peso_min, peso_max))

	# añadir aristas extra sin duplicados
	for i in range(cantidad_nodos):
		for j in range(i + 1, cantidad_nodos):
			if rng.randf() < prob_arista:
				var exists := false
				for ar in aristas:
					if (ar.nodo_origen == nodos[i] and ar.nodo_destino == nodos[j]) or (ar.nodo_origen == nodos[j] and ar.nodo_destino == nodos[i]):
						exists = true
						break
				if not exists:
					_crear_arista_entre(nodos[i], nodos[j], rng.randi_range(peso_min, peso_max))

	_update_status("Selecciona las aristas para reconstruir la red.")

func _crear_arista_entre(n1: Node, n2: Node, peso_val: int) -> void:
	var ar := AristaScene.instantiate()
	add_child(ar)
	if ar.has_method("configurar"):
		ar.configurar(n1, n2, peso_val, self)
	aristas.append(ar)
	if ar.has_signal("clicked"):
		ar.connect("clicked", Callable(self, "_on_arista_clicked"))

func _on_arista_clicked(arista) -> void:
	pass

# ---- DSU ----
func find(x: String) -> String:
	if padre[x] != x:
		padre[x] = find(padre[x])
	return padre[x]

func union(x: String, y: String) -> void:
	var rx := find(x)
	var ry := find(y)
	if rx == ry:
		return
	if rank[rx] < rank[ry]:
		padre[rx] = ry
	elif rank[rx] > rank[ry]:
		padre[ry] = rx
	else:
		padre[ry] = rx
		rank[rx] += 1

func intentar_conectar(origen: String, destino: String, peso_valor: int) -> bool:
	if origen == "" or destino == "":
		return false
	if find(origen) != find(destino):
		union(origen, destino)
		aceptadas += 1
		costo_total += peso_valor
		_update_status("✔ Conexión %s–%s aceptada. Total: %d" % [origen, destino, costo_total])
		if aceptadas == cantidad_nodos - 1:
			_update_status("🌐 Red reconstruida. Costo total: %d" % costo_total)
		return true
	else:
		_update_status("❌ Conexión inválida: forma ciclo")
		return false

func _update_status(text: String) -> void:
	if status_label and is_instance_valid(status_label):
		status_label.text = text
	else:
		var ui = get_tree().get_root().find_node("Label_Status", true, false)
		if ui:
			ui.text = text

func _on_button_reset_pressed() -> void:
	resetear_grafo()
