class_name Interactable
extends Node3D
## Qualquer coisa com que o jogador interage apertando E (NPC, baú, portal).

var prompt := "Interagir"
var on_interact: Callable
var once := false


func _ready() -> void:
	add_to_group("interactable")


func interact(player: Player) -> void:
	if on_interact.is_valid():
		on_interact.call(player)
	if once:
		remove_from_group("interactable")
