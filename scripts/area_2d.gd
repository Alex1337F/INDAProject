extends Area2D  # or RigidBody2D, CharacterBody2D, etc.

const SPEED = 600.0
var direction = Vector2.RIGHT

func _process(delta: float) -> void:
	position += direction * SPEED * delta
