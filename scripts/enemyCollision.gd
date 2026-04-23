extends Area2D

#@export var player: CharacterBody2D
@onready var player: CharacterBody2D = $"../../player"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == player:
		print("Player hit!")
