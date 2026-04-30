extends Area2D

const SPEED = 600.0
const DAMAGE = 20
var direction = Vector2.RIGHT

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func set_direction(dir: Vector2) -> void:
	direction = dir

func _process(delta: float) -> void:
	position += direction * SPEED * delta
	# Destroy arrow if it goes too far off screen
	if position.length() > 2000.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("enemy"):
		if body.has_method("take_damage"):
			body.take_damage(DAMAGE, global_position)
		queue_free()
	elif body.is_in_group("player"):
		pass # Ignore player so you don't shoot yourself
	else:
		# Hit a wall or something else, destroy arrow
		queue_free()
