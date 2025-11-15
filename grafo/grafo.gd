extends RefCounted
class_name Grafo

var vertices := []

func agregar_vertice(v):
	vertices.append(v)

func conectar_vertice(v1, v2):
	if not v1.adyacentes.has(v2):
		v1.agregar_adyacente(v2)
	if not v2.adyacentes.has(v1):
		v2.agregar_adyacente(v1)

func imprimir():
	for v in vertices:
		print(v.mostrar())
