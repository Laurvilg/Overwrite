extends Node2D

# Grafo.gd - soporte presets + fallback a generación aleatoria
# Incluye limpiar_selecciones() => soft reset (no regenerar grafo)

@export var use_presets: bool = true
@export var presets_path: String = "res://kruskal/Graphs"

@export var NodoScene: PackedScene
@export var AristaScene: PackedScene

@export var cantidad_nodos: int = 6
@export var prob_arista: float = 0.35
@export var peso_min: int = 1
@export var peso_max: int = 10
@export var margin: int = 80

# Atlas opcional
@export var atlas_texture: Texture2D
@export var atlas_cell_w: int = 64
@export var atlas_cell_h: int = 64
@export var base_sprite_scale: float = 1.0

# Evitar solapamiento (si se genera aleatorio)
@export var min_node_distance: float = 48.0
@export var max_position_attempts: int = 30

# adjacency mode (puedes activarlo desde el Inspector)
@export var adjacency_mode: bool = true

# Estado
var nodos: Array = []
var aristas: Array = []
var padre := {}
var rank := {}
var aceptadas: int = 0
var costo_total: int = 0
var accepted_nodes: Array = []

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
	# hard reset: borrar y regenerar
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
	accepted_nodes.clear()
	generar_grafo()
	_update_status("Nueva red generada.")

# SOFT RESET: limpiar sólo selecciones (no borrar nodos/aristas)
func limpiar_selecciones() -> void:
	# Restaurar visual de cada arista
	for ar in aristas:
		if is_instance_valid(ar) and ar.has_method("reiniciar_visual"):
			ar.reiniciar_visual()

	# Resetear estructuras DSU usando los nombres actuales de los nodos
	padre.clear()
	rank.clear()
	for n in nodos:
		if is_instance_valid(n):
			var nombre := ""
			if "nombre" in n:
				nombre = n.nombre
			else:
				nombre = n.name
			padre[nombre] = nombre
			rank[nombre] = 0

	# Resetar contadores y lista de nodos aceptados
	aceptadas = 0
	costo_total = 0
	accepted_nodes.clear()

	_update_status("Selecciones borradas. Continúa con el mismo grafo.")

func generar_grafo() -> void:
	print("--- Grafo.generar_grafo() llamado ---")
	var nodo_container: Node = $NodoContainer if has_node("NodoContainer") else null
	if nodo_container == null:
		nodo_container = Node2D.new()
		nodo_container.name = "NodoContainer"
		add_child(nodo_container)

	# Intentar cargar preset si está activado
	if use_presets:
		print("use_presets = true: intentando cargar preset desde ", presets_path)
		var ok := _load_random_preset()
		if ok:
			print("Preset cargado correctamente. Salgo de generar_grafo()")
			return
		else:
			print("No se pudo cargar preset (o no hay .json). Haré fallback a generación aleatoria.")
	else:
		print("use_presets = false -> generación aleatoria")

	# --- generación aleatoria (fallback) ---
	var arista_container: Node = $AristaContainer if has_node("AristaContainer") else null
	if arista_container == null:
		arista_container = Node2D.new()
		arista_container.name = "AristaContainer"
		add_child(arista_container)

	var rect: Rect2 = Rect2(Vector2(margin, margin), get_viewport_rect().size - Vector2(margin*2, margin*2))

	# crear nodos
	for i in range(cantidad_nodos):
		var nscene: Node2D = NodoScene.instantiate()
		var name_chr: String = char(65 + i)
		# atlas (opcional)
		if atlas_texture and nscene.has_method("set_texture_from_atlas"):
			var atlas_size: Vector2 = atlas_texture.get_size()
			var cols: int = max(1, int(atlas_size.x / atlas_cell_w))
			var rows: int = max(1, int(atlas_size.y / atlas_cell_h))
			var idx: int = rng.randi_range(0, cols * rows - 1)
			var cx: int = idx % cols
			var cy: int = int(idx / cols)
			var region: Rect2 = Rect2(cx * atlas_cell_w, cy * atlas_cell_h, atlas_cell_w, atlas_cell_h)
			nscene.call_deferred("set_texture_from_atlas", atlas_texture, region)
			if "base_scale" in nscene:
				nscene.base_scale = base_sprite_scale
		# nombre
		if "nombre" in nscene:
			nscene.nombre = name_chr
		else:
			if nscene.has_method("set"):
				nscene.set("nombre", name_chr)
		# posicion intentando evitar solapamiento
		var pos := _find_free_position(rect, min_node_distance, max_position_attempts)
		nscene.position = pos
		nodo_container.add_child(nscene)
		nodos.append(nscene)
		padre[name_chr] = name_chr
		rank[name_chr] = 0

	# asegurar conectividad: árbol aleatorio
	var indices: Array = []
	for j in range(cantidad_nodos):
		indices.append(j)
	indices.shuffle()
	for k in range(1, cantidad_nodos):
		var a_idx: int = indices[k]
		var b_idx: int = rng.randi_range(0, k - 1)
		_crear_arista_entre(nodos[a_idx], nodos[b_idx], rng.randi_range(peso_min, peso_max))

	# aristas extra sin duplicados
	for i in range(cantidad_nodos):
		for j in range(i + 1, cantidad_nodos):
			if rng.randf() < prob_arista:
				var exists: bool = false
				for ar in aristas:
					if (ar.nodo_origen == nodos[i] and ar.nodo_destino == nodos[j]) or (ar.nodo_origen == nodos[j] and ar.nodo_destino == nodos[i]):
						exists = true
						break
				if not exists:
					_crear_arista_entre(nodos[i], nodos[j], rng.randi_range(peso_min, peso_max))

	accepted_nodes.clear()
	aceptadas = 0
	costo_total = 0
	_update_status("Selecciona las aristas para reconstruir la red.")

# Cargar JSON aleatorio desde presets_path
func _load_random_preset() -> bool:
	var dir := DirAccess.open(presets_path)
	if dir == null:
		print("Grafo: no se pudo abrir presets_path: ", presets_path)
		return false
	dir.list_dir_begin()
	var files: Array = []
	var fname := dir.get_next()
	while fname != "":
		if not dir.current_is_dir():
			if fname.to_lower().ends_with(".json"):
				files.append(fname)
		fname = dir.get_next()
	dir.list_dir_end()
	if files.is_empty():
		print("Grafo: no hay archivos .json en ", presets_path)
		return false
	var chosen = files[rng.randi_range(0, files.size() - 1)]
	print("Grafo: elegido preset -> ", chosen)
	var fullpath = presets_path + "/" + chosen
	var f := FileAccess.open(fullpath, FileAccess.READ)
	if f == null:
		print("Grafo: no se pudo abrir el archivo ", fullpath)
		return false
	var json_text = f.get_as_string()
	f.close()
	var parsed = JSON.parse_string(json_text)
	if parsed.error != OK:
		print("Grafo: error parseando JSON: ", parsed.error_string())
		return false
	var data = parsed.result
	if not data.has("nodes") or not data.has("edges"):
		print("Grafo: preset inválido (no nodes/edges): ", chosen)
		return false

	# limpiar si hay algo previo
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
	accepted_nodes.clear()
	aceptadas = 0
	costo_total = 0

	var nodo_container: Node = $NodoContainer if has_node("NodoContainer") else null
	if nodo_container == null:
		nodo_container = Node2D.new()
		nodo_container.name = "NodoContainer"
		add_child(nodo_container)

	# crear nodos y posiciones desde preset
	for nd in data["nodes"]:
		var nscene: Node2D = NodoScene.instantiate()
		var name_chr: String = str(nd.get("name", ""))
		var pos_arr = nd.get("pos", [0,0])
		var pos := Vector2(float(pos_arr[0]), float(pos_arr[1]))
		if nd.has("atlas_region") and nscene.has_method("set_texture_from_atlas") and atlas_texture:
			var r = nd["atlas_region"]
			var region := Rect2(float(r[0]), float(r[1]), float(r[2]), float(r[3]))
			nscene.call_deferred("set_texture_from_atlas", atlas_texture, region)
		if "nombre" in nscene:
			nscene.nombre = name_chr
		else:
			if nscene.has_method("set"):
				nscene.set("nombre", name_chr)
		nscene.position = pos
		nodo_container.add_child(nscene)
		nodos.append(nscene)
		padre[name_chr] = name_chr
		rank[name_chr] = 0

	# crear aristas desde preset
	for ed in data["edges"]:
		var a_name := str(ed.get("a", ""))
		var b_name := str(ed.get("b", ""))
		var w := int(ed.get("w", 1))
		var na := _find_node_by_name(a_name)
		var nb := _find_node_by_name(b_name)
		if na != null and nb != null:
			_crear_arista_entre(na, nb, w)

	_update_status("Preset cargado: %s" % chosen)
	return true

func _find_node_by_name(name: String) -> Node:
	for n in nodos:
		if is_instance_valid(n) and ("nombre" in n and n.nombre == name):
			return n
	for n in nodos:
		if is_instance_valid(n):
			if n.name == name:
				return n
	return null

func _find_free_position(rect: Rect2, min_dist: float, attempts: int) -> Vector2:
	var best_candidate := Vector2(rect.position.x + rect.size.x * 0.5, rect.position.y + rect.size.y * 0.5)
	for a in range(attempts):
		var px := rng.randi_range(int(rect.position.x), int(rect.end.x))
		var py := rng.randi_range(int(rect.position.y), int(rect.end.y))
		var cand := Vector2(px, py)
		var ok := true
		for n in nodos:
			if is_instance_valid(n):
				if n.position.distance_to(cand) < min_dist:
					ok = false
					break
		if ok:
			return cand
		best_candidate = cand
	return best_candidate

func _crear_arista_entre(n1: Node, n2: Node, peso_val: int) -> void:
	var ar: Node = AristaScene.instantiate()
	var arista_container: Node = $AristaContainer if has_node("AristaContainer") else self
	arista_container.add_child(ar)
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
	var rx: String = find(x)
	var ry: String = find(y)
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

	if adjacency_mode and aceptadas > 0:
		var origen_in := origen in accepted_nodes
		var destino_in := destino in accepted_nodes
		if not origen_in and not destino_in:
			_update_status("❌ Conexión inválida: debe ser adyacente a la red actual")
			return false

	if find(origen) != find(destino):
		union(origen, destino)
		aceptadas += 1
		costo_total += peso_valor
		if origen not in accepted_nodes:
			accepted_nodes.append(origen)
		if destino not in accepted_nodes:
			accepted_nodes.append(destino)
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
		var ui: Label = get_tree().get_root().find_node("Label_Status", true, false)
		if ui:
			ui.text = text

func _on_button_reset_pressed() -> void:
	resetear_grafo()
