extends CharacterBody2D

const SPEED = 30.0
const CONTACT_DAMAGE = 10
const DAMAGE_COOLDOWN = 0.8
var MAX_HEALTH: int = 60
var current_health: int
var is_knockback: bool = false
var damage_timer: float = 0.0

const KNOCKBACK_FORCE = 400.0
const KNOCKBACK_DECAY = 10.0

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
		velocity = velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		if velocity.length() < 5.0:
			is_knockback = false
		move_and_slide()
		return

	var direction = (player.global_position - global_position).normalized()
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

	# Contact damage
	damage_timer -= delta
	var distance = global_position.distance_to(player.global_position)
	if distance < 12.0 and damage_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(CONTACT_DAMAGE)
			damage_timer = DAMAGE_COOLDOWN
			velocity = -direction * SPEED * 2

func take_damage(amount: int, knockback_origin: Vector2) -> void:
	current_health -= amount

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
