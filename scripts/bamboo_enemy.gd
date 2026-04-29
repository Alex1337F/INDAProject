extends CharacterBody2D

const SPEED = 35.0
const CHASE_SPEED = 55.0
const DETECTION_RANGE = 100.0  # How close before it starts chasing
const LOSE_RANGE = 160.0       # How far before it gives up chasing
const CONTACT_DAMAGE = 12
const DAMAGE_COOLDOWN = 0.8    # Seconds between contact damage hits

@onready var player: CharacterBody2D = $"../player/Archer"
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

enum State { IDLE, PATROL, CHASE }
var state: State = State.IDLE

# Patrol
var patrol_direction: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
var idle_timer: float = 0.0

# Contact damage
var damage_timer: float = 0.0

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	# --- State transitions ---
	match state:
		State.IDLE:
			idle_timer -= delta
			if distance <= DETECTION_RANGE:
				state = State.CHASE
			elif idle_timer <= 0:
				state = State.PATROL
				_pick_patrol_direction()

		State.PATROL:
			patrol_timer -= delta
			if distance <= DETECTION_RANGE:
				state = State.CHASE
			elif patrol_timer <= 0:
				state = State.IDLE
				idle_timer = randf_range(1.0, 2.5)

		State.CHASE:
			if distance > LOSE_RANGE:
				state = State.IDLE
				idle_timer = randf_range(0.5, 1.5)

	# --- Movement ---
	match state:
		State.IDLE:
			velocity = velocity.lerp(Vector2.ZERO, 0.2)
			anim.stop()

		State.PATROL:
			velocity = patrol_direction * SPEED
			_play_directional_animation(patrol_direction)

		State.CHASE:
			var direction = to_player.normalized()
			velocity = direction * CHASE_SPEED
			_play_directional_animation(direction)

	move_and_slide()

	# --- Contact damage ---
	damage_timer -= delta
	if state == State.CHASE and distance < 12.0 and damage_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(CONTACT_DAMAGE)
			damage_timer = DAMAGE_COOLDOWN
			# Knockback: push the enemy back slightly
			velocity = -to_player.normalized() * CHASE_SPEED * 2


func _play_directional_animation(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		# Horizontal movement
		if dir.x > 0:
			anim.play("right")
		else:
			anim.play("left")
	else:
		# Vertical movement
		if dir.y > 0:
			anim.play("forward")
		else:
			anim.play("backward")


func _pick_patrol_direction() -> void:
	var angle = randf() * TAU
	patrol_direction = Vector2(cos(angle), sin(angle))
	patrol_timer = randf_range(1.5, 3.5)
