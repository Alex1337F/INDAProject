class_name PlayerBase
extends CharacterBody2D

@export var SPEED = 150.0
@export var DASH_SPEED = 700.0
@export var DASH_TIME = 0.15

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var dash_timer = 0.0
var dash_direction = Vector2.ZERO
var is_attacking = false

func _physics_process(delta: float) -> void:
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
