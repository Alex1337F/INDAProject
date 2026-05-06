extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 120.0
var lifetime: float = 4.0
const DAMAGE: int = 15
const HIT_RADIUS: float = 10.0

func _ready() -> void:
	# Auto-destroy after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	rotation = direction.angle()
	position += direction * speed * delta

	# Direct distance check — no physics engine dependency
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < HIT_RADIUS:
			if player.has_method("take_damage"):
				player.take_damage(DAMAGE)
			queue_free()
