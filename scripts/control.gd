extends Control

func _ready():
	$Label.text = "Choose Your Class"
	$ArcherButton.text = "Archer"
	$WarriorButton.text = "Warrior"

func _on_ArcherButton_pressed():
	GameState.chosen_class = "archer"
	get_tree().change_scene_to_file("res://scenes/game.tscn")

func _on_WarriorButton_pressed():
	GameState.chosen_class = "warrior"
	get_tree().change_scene_to_file("res://scenes/game.tscn")


func _on_warrior_button_pressed() -> void:
	pass # Replace with function body.


func _on_archer_button_pressed() -> void:
	pass # Replace with function body.
