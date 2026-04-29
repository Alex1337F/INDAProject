extends CharacterBody2D

# The Eye is an aggressive teleporting enemy. It zips toward the player,
# then blinks to a new position. Sometimes it warps right behind you.

const FLOAT_SPEED = 65.0
const DETECTION_RANGE = 130.0
const TELEPORT_INTERVAL_MIN = 1.8
const TELEPORT_INTERVAL_MAX = 3.2
const BLINK_STRIKE_CHANCE = 0.35
const TELEPORT_RADIUS = 50.0
const CONTACT_DAMAGE = 15
const DAMAGE_COOLDOWN = 1.0

@onready var player: CharacterBody2D = $"../player/Archer"
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var teleport_timer: float = 0.0
var damage_timer: float = 0.0
var bob_time: float = 0.0
var is_teleporting: bool = false
var teleport_phase: float = 0.0 # 0 = not teleporting, >0 = in progress
var teleport_target: Vector2 = Vector2.ZERO
var active: bool = false

const FADE_OUT_TIME = 0.15
const FADE_IN_TIME = 0.2

func _ready() -> void:
	teleport_timer = randf_range(TELEPORT_INTERVAL_MIN, TELEPORT_INTERVAL_MAX)

func _physics_process(delta: float) -> void:
	if player == null:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	# --- Floating bob ---
	bob_time += delta * 4.0
	anim.position.y = sin(bob_time) * 2.0

	# --- Activation ---
	if not active:
		velocity = Vector2.ZERO
		if distance <= DETECTION_RANGE:
			active = true
			anim.play("forward")
		return

	# --- Teleport animation (frame-based, no await) ---
	if is_teleporting:
		_process_teleport(delta)
		return

	# --- Movement: zip toward the player ---
	var direction = to_player.normalized()
	velocity = direction * FLOAT_SPEED
	_play_directional_animation(direction)
	move_and_slide()

	# --- Teleport countdown ---
	teleport_timer -= delta
	if teleport_timer <= 0:
		_begin_teleport()

	# --- Contact damage ---
	damage_timer -= delta
	if distance < 12.0 and damage_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(CONTACT_DAMAGE)
			damage_timer = DAMAGE_COOLDOWN
			# Bounce away after hitting
			var knockback = create_tween()
			knockback.tween_property(self , "global_position",
				global_position - direction * 30.0, 0.15).set_ease(Tween.EASE_OUT)


func _begin_teleport() -> void:
	is_teleporting = true
	teleport_phase = 0.0
	velocity = Vector2.ZERO

	# Pick destination
	if randf() < BLINK_STRIKE_CHANCE and player != null:
		# Blink strike: appear behind the player's movement direction
		var behind = Vector2.DOWN
		if player.velocity.length() > 10:
			behind = - player.velocity.normalized()
		teleport_target = player.global_position + behind * 18.0
	else:
		# Random spot near the player
		var angle = randf() * TAU
		var dist = randf_range(25.0, TELEPORT_RADIUS)
		teleport_target = player.global_position + Vector2(cos(angle), sin(angle)) * dist


func _process_teleport(delta: float) -> void:
	teleport_phase += delta

	if teleport_phase < FADE_OUT_TIME:
		# Phase 1: Fade out + shrink
		var t = teleport_phase / FADE_OUT_TIME
		anim.modulate.a = 1.0 - t
		anim.scale = Vector2.ONE * (1.0 - t * 0.6)
	elif teleport_phase < FADE_OUT_TIME + 0.05:
		# Phase 2: Warp (instant)
		global_position = teleport_target
		anim.modulate.a = 0.0
	elif teleport_phase < FADE_OUT_TIME + 0.05 + FADE_IN_TIME:
		# Phase 3: Fade in + pop
		var t = (teleport_phase - FADE_OUT_TIME - 0.05) / FADE_IN_TIME
		anim.modulate.a = t
		# Overshoot scale for a "pop" effect
		var scale_val = 1.0 + (1.0 - t) * 0.4
		anim.scale = Vector2.ONE * scale_val
		# Face the player
		if player:
			var dir = (player.global_position - global_position).normalized()
			_play_directional_animation(dir)
	else:
		# Done
		anim.modulate.a = 1.0
		anim.scale = Vector2.ONE
		is_teleporting = false
		teleport_timer = randf_range(TELEPORT_INTERVAL_MIN, TELEPORT_INTERVAL_MAX)


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
