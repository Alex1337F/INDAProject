class_name PlayerBase
extends CharacterBody2D

signal health_changed(current_hp: int, max_hp: int)
signal player_died()

@export var SPEED = 150.0
@export var DASH_SPEED = 700.0
@export var DASH_TIME = 0.15
@export var MAX_HEALTH: int = 100

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var current_health: int
var dash_timer = 0.0
var dash_direction = Vector2.ZERO
var is_attacking = false
var is_invincible = false
var is_dead = false
var invincibility_timer: float = 0.0
var spawn_position: Vector2
const INVINCIBILITY_DURATION = 0.8  # Seconds of invincibility after being hit
const RESPAWN_DELAY = 1.2           # Seconds before respawning

func _ready() -> void:
	current_health = MAX_HEALTH
	spawn_position = global_position
	health_changed.emit(current_health, MAX_HEALTH)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	var direction = Vector2.ZERO

	if not is_attacking:
		if Input.is_action_pressed("walk-left"):
			direction.x -= 1
		if Input.is_action_pressed("walk-right"):
			direction.x += 1
		if Input.is_action_pressed("walk-forward"):
			direction.y -= 1
		if Input.is_action_pressed("walk-backwards"):
			direction.y += 1
		if direction != Vector2.ZERO:
			direction = direction.normalized()

		# Start dash
		if Input.is_action_just_pressed("dash"):
			if direction != Vector2.ZERO:
				dash_direction = direction
			elif velocity != Vector2.ZERO:
				dash_direction = velocity.normalized()
			if dash_direction != Vector2.ZERO:
				dash_timer = DASH_TIME

		# Dash movement
		if dash_timer > 0:
			dash_timer -= delta
			velocity = dash_direction * DASH_SPEED
		else:
			velocity = direction * SPEED

		# Animations
		if velocity != Vector2.ZERO:
			var move_dir = velocity.normalized()
			if abs(move_dir.x) >= abs(move_dir.y):
				anim.play("walk-right")
				anim.flip_h = move_dir.x < 0
			else:
				anim.flip_h = false
				if move_dir.y < 0:
					anim.play("walk-forward")
				else:
					anim.play("walk-backwards")
		else:
			anim.stop()
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	# --- Invincibility timer ---
	if is_invincible:
		invincibility_timer -= delta
		# Flash the sprite by toggling visibility
		anim.modulate.a = 0.4 if fmod(invincibility_timer, 0.15) < 0.075 else 1.0
		if invincibility_timer <= 0:
			is_invincible = false
			anim.modulate.a = 1.0

func take_damage(amount: int) -> void:
	if is_invincible or is_dead:
		return
	current_health = max(current_health - amount, 0)
	health_changed.emit(current_health, MAX_HEALTH)
	# Start invincibility
	is_invincible = true
	invincibility_timer = INVINCIBILITY_DURATION
	# Red flash
	anim.modulate = Color(1.0, 0.3, 0.3, 1.0)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.2)
	if current_health <= 0:
		_on_player_died()

func heal(amount: int) -> void:
	current_health = min(current_health + amount, MAX_HEALTH)
	health_changed.emit(current_health, MAX_HEALTH)

func _on_player_died() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	player_died.emit()

	# Death animation: shrink + spin + fade out
	var death_tween = create_tween().set_parallel(true)
	death_tween.tween_property(anim, "modulate:a", 0.0, 0.6)
	death_tween.tween_property(anim, "scale", Vector2(0.3, 0.3), 0.6)
	death_tween.tween_property(anim, "rotation", TAU, 0.6)

	await death_tween.finished

	# Wait before respawning
	await get_tree().create_timer(RESPAWN_DELAY).timeout

	_respawn()

func _respawn() -> void:
	# Reset position
	global_position = spawn_position

	# Reset health
	current_health = MAX_HEALTH
	health_changed.emit(current_health, MAX_HEALTH)

	# Reset visual state
	anim.modulate = Color.WHITE
	anim.modulate.a = 0.0
	anim.scale = Vector2(1.0, 1.0)
	anim.rotation = 0.0

	# Un-die
	is_dead = false
	is_invincible = true
	invincibility_timer = INVINCIBILITY_DURATION * 2  # Extra invincibility on respawn

	# Fade back in
	var spawn_tween = create_tween()
	spawn_tween.tween_property(anim, "modulate:a", 1.0, 0.3)
