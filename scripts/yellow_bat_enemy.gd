extends CharacterBody2D

# Yellow Bat — Flies toward the player, pauses briefly, then dashes
# straight through them, stopping at an equal distance on the other side.
# Pattern: Approach → Pause → Dash through → Recover → Repeat

const FLY_SPEED = 55.0
const DASH_SPEED = 300.0
const DETECTION_RANGE = 120.0
const DASH_TRIGGER_DISTANCE = 40.0  # How close before it starts the dash wind-up
const LOCK_ON_TIME = 0.3             # Brief pause before dashing
const RECOVER_TIME = 0.6             # Rest after dashing
const CONTACT_DAMAGE = 20
const DAMAGE_COOLDOWN = 0.6

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
var player: CharacterBody2D

enum State { IDLE, APPROACHING, LOCK_ON, DASHING, RECOVERING }
var state: State = State.IDLE

var state_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_target: Vector2 = Vector2.ZERO  # Where the dash ends
var dash_start: Vector2 = Vector2.ZERO   # Where the dash started
var damage_timer: float = 0.0
var bob_time: float = 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	# --- Flying bob ---
	bob_time += delta * 5.0
	anim.position.y = sin(bob_time) * 1.5

	# --- Contact damage ---
	damage_timer -= delta
	if distance < 10.0 and damage_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(CONTACT_DAMAGE)
			damage_timer = DAMAGE_COOLDOWN

	# --- State machine ---
	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if distance <= DETECTION_RANGE:
				state = State.APPROACHING

		State.APPROACHING:
			# Fly straight toward the player
			var dir = to_player.normalized()
			velocity = dir * FLY_SPEED
			_play_directional_animation(dir)

			# When close enough, lock on
			if distance <= DASH_TRIGGER_DISTANCE:
				state = State.LOCK_ON
				state_timer = LOCK_ON_TIME
				velocity = Vector2.ZERO
				# Lock dash direction and calculate target (equal distance on other side)
				dash_direction = to_player.normalized()
				dash_start = global_position
				dash_target = player.global_position + dash_direction * distance

			# Lost the player
			if distance > DETECTION_RANGE * 2.5:
				state = State.IDLE

		State.LOCK_ON:
			# Brief pause — telegraph the attack
			velocity = Vector2.ZERO
			state_timer -= delta

			# Flash yellow as warning
			var blink = fmod(state_timer, 0.1) < 0.05
			anim.modulate = Color(1.5, 1.5, 0.5) if blink else Color.WHITE
			_play_directional_animation(dash_direction)

			if state_timer <= 0:
				state = State.DASHING
				anim.modulate = Color(1.0, 1.0, 0.6)

		State.DASHING:
			# Dash in the locked direction
			velocity = dash_direction * DASH_SPEED
			_play_directional_animation(dash_direction)

			# Stop when we've reached or passed the target
			var to_target = dash_target - global_position
			if to_target.dot(dash_direction) <= 0:
				# We've passed the target point
				global_position = dash_target
				velocity = Vector2.ZERO
				state = State.RECOVERING
				state_timer = RECOVER_TIME
				anim.modulate = Color.WHITE

		State.RECOVERING:
			velocity = Vector2.ZERO
			state_timer -= delta

			if state_timer <= 0:
				# Turn around and approach again
				state = State.APPROACHING

	move_and_slide()


func _play_directional_animation(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		if dir.x > 0:
			anim.play("right")
		else:
			anim.play("left")
	else:
		if dir.y > 0:
			anim.play("forward")
		else:
			anim.play("backward")
