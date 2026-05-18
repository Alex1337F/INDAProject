class_name PlayerBase
extends CharacterBody2D

signal health_changed(current_hp: int, max_hp: int)
signal player_died()

@export var SPEED: float = 150.0
@export var DASH_SPEED = 700.0
@export var DASH_TIME = 0.15
@export var DASH_COOLDOWN = 0.6
@export var MAX_HEALTH: int = 100

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var current_health: int
var dash_timer = 0.0
var dash_cooldown_timer = 0.0
var dash_direction = Vector2.ZERO
var is_dashing = false
var is_attacking = false
var is_invincible = false
var is_dead = false
var invincibility_timer: float = 0.0
var spawn_position: Vector2
var last_move_direction: Vector2 = Vector2.RIGHT
const INVINCIBILITY_DURATION = 0.8
const RESPAWN_DELAY = 1.2
const DUST_INTERVAL = 0.03

var _dust_timer: float = 0.0

func register_sprite(sprite: AnimatedSprite2D) -> void:
	anim = sprite

func _ready() -> void:
	add_to_group("player")
	current_health = MAX_HEALTH
	spawn_position = global_position
	health_changed.emit(current_health, MAX_HEALTH)

func get_effective_speed() -> float:
	return SPEED * GameState.get_multiplier("speed")

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# --- Dash cooldown ---
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

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
			last_move_direction = direction

		# Start dash
		if Input.is_action_just_pressed("dash") and dash_cooldown_timer <= 0:
			if direction != Vector2.ZERO:
				dash_direction = direction
			elif velocity != Vector2.ZERO:
				dash_direction = velocity.normalized()
			else:
				dash_direction = last_move_direction
			if dash_direction != Vector2.ZERO:
				dash_timer = DASH_TIME
				dash_cooldown_timer = DASH_COOLDOWN
				is_dashing = true
				is_invincible = true
				invincibility_timer = DASH_TIME + 0.05
				_dust_timer = 0.0
				# Tint player slightly blue-white during dash
				anim.modulate = Color(0.7, 0.85, 1.0, 0.6)

		# Dash movement
		if dash_timer > 0:
			dash_timer -= delta
			velocity = dash_direction * DASH_SPEED
			# Spawn dust trail
			_dust_timer -= delta
			if _dust_timer <= 0:
				_dust_timer = DUST_INTERVAL
				_spawn_dust_particle()
			if dash_timer <= 0:
				is_dashing = false
				# Restore modulate (invincibility flash will handle the rest)
				if not is_invincible or invincibility_timer <= 0:
					anim.modulate = Color.WHITE
		else:
			velocity = direction * get_effective_speed()

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
		if is_dashing:
			# Keep the dash tint during dash
			anim.modulate = Color(0.7, 0.85, 1.0, 0.6)
		else:
			# Standard flash after dash or damage
			anim.modulate.a = 0.4 if fmod(invincibility_timer, 0.15) < 0.075 else 1.0
		if invincibility_timer <= 0:
			is_invincible = false
			anim.modulate = Color.WHITE
			anim.modulate.a = 1.0

func _spawn_dust_particle() -> void:
	var dust = Node2D.new()
	dust.global_position = global_position + Vector2(randf_range(-4, 4), randf_range(2, 6))
	get_tree().current_scene.add_child(dust)

	var rect = ColorRect.new()
	var size_val = randf_range(2.0, 5.0)
	rect.size = Vector2(size_val, size_val)
	rect.position = -rect.size / 2.0
	rect.color = Color(0.85, 0.82, 0.7, 0.7)
	dust.add_child(rect)

	dust.scale = Vector2(0.5, 0.5)
	var tween = dust.create_tween().set_parallel(true)
	tween.tween_property(dust, "scale", Vector2(1.2, 1.2), 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(rect, "color:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_property(dust, "position:y", dust.position.y - 6.0, 0.25)
	tween.chain().tween_callback(dust.queue_free)

func _unhandled_input(event: InputEvent) -> void:
	# Debug: P gives 50 coins
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_P:
			GameState.add_coins(50)

func take_damage(amount: int) -> void:
	if is_invincible or is_dead:
		return
	# Apply defence multiplier (each level reduces damage by 10%)
	var reduced = int(ceil(float(amount) * GameState.get_multiplier("defence")))
	reduced = max(reduced, 0)
	current_health = max(current_health - reduced, 0)
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
	GameState.record_death()

	# Death animation: shrink + spin + fade out
	var death_tween = create_tween().set_parallel(true)
	death_tween.tween_property(anim, "modulate:a", 0.0, 0.6)
	death_tween.tween_property(anim, "scale", Vector2(0.3, 0.3), 0.6)
	death_tween.tween_property(anim, "rotation", TAU, 0.6)
	# Player stays dead until _respawn() is called externally (by death screen)

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
	invincibility_timer = INVINCIBILITY_DURATION * 2 # Extra invincibility on respawn

	# Fade back in
	var spawn_tween = create_tween()
	spawn_tween.tween_property(anim, "modulate:a", 1.0, 0.3)
