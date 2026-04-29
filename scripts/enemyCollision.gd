extends Area2D

@export var DAMAGE: int = 10
@onready var player_archer = $"../../player/Archer"

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is PlayerBase:
		body.take_damage(DAMAGE)
