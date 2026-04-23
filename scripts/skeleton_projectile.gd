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
	if body.name == "player" or body is CharacterBody2D:
		# Don't hit the skeleton itself
		if body == get_parent():
			return
		print("Skeleton projectile hit: ", body.name)
		queue_free()
