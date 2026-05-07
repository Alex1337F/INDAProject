extends Area2D

const SPEED = 180.0
const DAMAGE = 15
var direction: Vector2 = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	position += direction * SPEED * delta
	# Destroy if too far
	if global_position.length() > 3000.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE)
		call_deferred("queue_free")
	elif not body.is_in_group("enemy"):
		call_deferred("queue_free")
