# UI.gd
extends Control

@export var manager_path: NodePath
@onready var manager: Node = null
@onready var mode_option: OptionButton = $ModeOption
@onready var start_btn: Button = $StartButton
@onready var info_label: Label = $InfoLabel

func _ready() -> void:
	# Asignar manager correctamente
	if manager_path != NodePath("") and has_node(manager_path):
		manager = get_node(manager_path)

	# asegurar opciones
	if mode_option and mode_option.get_item_count() == 0:
		mode_option.add_item("BFS")
		mode_option.add_item("DFS")
		mode_option.add_item("RANDOM")

	if start_btn:
		start_btn.pressed.connect(_on_start_pressed)

func _on_start_pressed() -> void:
	if not manager:
		push_error("UI: manager no asignado")
		return

	var selected = mode_option.get_item_text(mode_option.selected)
	manager.start_minigame(selected)
