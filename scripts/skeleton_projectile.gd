extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 120.0
var lifetime: float = 4.0 # Destroy after 4 seconds

func _ready() -> void:
	# Connect the body_entered signal for collision with the player
	body_entered.connect(_on_body_entered)
	# Auto-destroy after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _process(delta: float) -> void:
	# Set rotation to face the movement direction (only matters on first frame)
	rotation = direction.angle()
	position += direction * speed * delta

func _on_body_entered(body: Node) -> void:
	# Ignore the skeleton that fired this
	if body.get_parent() != null and body.get_parent().name == "SkeletonEnemy":
		return
	if body is PlayerBase:
		body.take_damage(15)
		queue_free()
