extends Node2D

@export var nombre: String = ""
@export var sprite_texture: Texture2D
@export var base_scale: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var label: Label = $Label

func _ready() -> void:
	# poner nodos encima de las aristas
	z_index = 10
	sprite.z_index = 10
	label.z_index = 11

	# asigna textura exportada (si se colocó)
	if sprite_texture:
		sprite.texture = sprite_texture
		sprite.scale = Vector2.ONE * base_scale
	# si ya hay texture (Atlas en tscn), sólo ajustar escala
	if sprite.texture:
		sprite.scale = Vector2.ONE * base_scale

	# label pequeño y fuera del sprite
	label.text = nombre
	label.scale = Vector2(0.95, 0.95)
	if sprite.texture:
		label.position = Vector2(0, sprite.texture.get_height() * 0.5 * base_scale + 6)
	else:
		label.position = Vector2(0, 24)

func set_texture_from_atlas(atlas: Texture2D, region: Rect2) -> void:
	var at := AtlasTexture.new()
	at.atlas = atlas
	at.region = region
	sprite.texture = at
	sprite.scale = Vector2.ONE * base_scale

func set_nombre(n: String) -> void:
	nombre = n
	if is_instance_valid(label):
		label.text = n
