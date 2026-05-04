extends CharacterBody2D

const SPEED = 30.0
var MAX_HEALTH: int = 60
var current_health: int
var is_knockback: bool = false  # Add this

const KNOCKBACK_FORCE = 400.0   # Add this
const KNOCKBACK_DECAY = 10.0    # Add this - how fast it slows down

@onready var player: CharacterBody2D
@onready var anim = $AnimatedSprite2D

func _ready():
	add_to_group("enemy")
	current_health = MAX_HEALTH
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	if is_knockback:
		# Slow down the knockback over time
		velocity = velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		if velocity.length() < 5.0:
			is_knockback = false
		move_and_slide()
		return  # Skip normal movement while knocked back

	var direction = (player.position - position).normalized()
	velocity = direction * SPEED

	# Animations
	if abs(direction.x) >= abs(direction.y):
		anim.play("enemy-right")
		anim.flip_h = direction.x < 0
	else:
		anim.flip_h = false
		if direction.y < 0:
			anim.play("enemy-backwards")
		else:
			anim.play("enemy-forward")

	move_and_slide()

func take_damage(amount: int, knockback_origin: Vector2) -> void:
	current_health -= amount
	print("Enemy hit! HP: ", current_health)

	# Apply knockback away from attacker
	var knockback_dir = (global_position - knockback_origin).normalized()
	velocity = knockback_dir * KNOCKBACK_FORCE
	is_knockback = true

	# Flash red
	anim.modulate = Color(1.0, 0.2, 0.2, 1.0)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.2)

	if current_health <= 0:
		die()

func die() -> void:
	queue_free()
