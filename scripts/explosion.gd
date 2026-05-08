extends Node2D

var t: float = 0.0
var circle: ColorRect

func _ready() -> void:
	circle = ColorRect.new()
	circle.color = Color(1.0, 0.5, 0.1, 0.85)
	circle.size = Vector2(24, 24)
	circle.position = Vector2(-12, -12)
	add_child(circle)

func _process(delta: float) -> void:
	t += delta
	scale = Vector2(1.0 + t * 3.0, 1.0 + t * 3.0)
	circle.color.a = max(0.0, 0.85 - t * 2.0)
	if t >= 0.5:
		queue_free()
