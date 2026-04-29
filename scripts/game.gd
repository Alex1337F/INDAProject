
extends Node2D

const SCENES = {
	"archer":  preload("res://scenes/archer.tscn"),
	"warrior": preload("res://scenes/warrior.tscn"),
}

func _ready():
	var player_scene

	if GameState.chosen_class == "archer":
		player_scene = preload("res://scenes/archer.tscn")
	else:
		player_scene = preload("res://scenes/warrior.tscn")

	var player = player_scene.instantiate()
	add_child(player)
	player.global_position = Vector2(0, 0)

func _on_archer_button_pressed() -> void:
	pass # Replace with function body.


func _on_warrior_button_pressed() -> void:
	pass # Replace with function body.
