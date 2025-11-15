extends RefCounted
class_name Vertice

var dato = ""
var adyacentes = []
var id = 0
static var cid = 0

func _init(_dato):
	dato = _dato
	adyacentes = []
	id = cid
	cid += 1

# Métodos get/set
func get_dato():
	return dato

func set_dato(nuevo_dato):
	dato = nuevo_dato

func get_adyacentes():
	return adyacentes

func set_adyacentes(lista):
	adyacentes = lista

func get_id():
	return id

func set_id(nuevo_id):
	id = nuevo_id

static func get_cid():
	return cid

static func set_cid(nuevo_cid):
	cid = nuevo_cid

func agregar_adyacente(vertice):
	if not adyacentes.has(vertice):
		adyacentes.append(vertice)

func mostrar():
	var nombres = []
	for v in adyacentes:
		nombres.append(v.get_dato())
	return "Vertice{nombre='%s', adyacentes=[%s]}" % [dato, ", ".join(nombres)]
