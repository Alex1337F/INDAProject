extends CharacterBody2D
const FLY_SPEED = 55.0
const DASH_SPEED = 300.0
const DETECTION_RANGE = 120.0
const DASH_TRIGGER_DISTANCE = 40.0
const LOCK_ON_TIME = 0.3
const RECOVER_TIME = 0.6
const CONTACT_DAMAGE = 20
const DAMAGE_COOLDOWN = 0.6
const MAX_HEALTH = 30
const KNOCKBACK_FORCE = 400.0
const KNOCKBACK_DECAY = 12.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D
var current_health: int = MAX_HEALTH
var is_knockback: bool = false
var health_bar: Node2D

enum State { IDLE, APPROACHING, LOCK_ON, DASHING, RECOVERING }
var state: State = State.IDLE
var state_timer: float = 0.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_target: Vector2 = Vector2.ZERO
var dash_start: Vector2 = Vector2.ZERO
var damage_timer: float = 0.0
var bob_time: float = 0.0

func _ready() -> void:
	add_to_group("enemy")
	current_health = MAX_HEALTH
	player = get_tree().get_first_node_in_group("player")
	_create_health_bar()

func _create_health_bar() -> void:
	var hb_script = preload("res://scripts/enemy_health_bar.gd")
	health_bar = Node2D.new()
	health_bar.set_script(hb_script)
	add_child(health_bar)
	health_bar.setup(MAX_HEALTH)

func take_damage(amount: int, knockback_origin: Vector2) -> void:
	current_health -= amount
	if health_bar:
		health_bar.update_health(current_health, MAX_HEALTH)
	# Interrupt dash state on hit
	if state == State.DASHING or state == State.LOCK_ON:
		state = State.RECOVERING
		state_timer = RECOVER_TIME
		anim.modulate = Color.WHITE
	var knockback_dir = (global_position - knockback_origin).normalized()
	velocity = knockback_dir * KNOCKBACK_FORCE
	is_knockback = true
	anim.modulate = Color(1.0, 0.2, 0.2, 1.0)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.2)
	if current_health <= 0:
		queue_free()

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

	bob_time += delta * 5.0
	anim.position.y = sin(bob_time) * 1.5

	if is_knockback:
		velocity = velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		if velocity.length() < 5.0:
			is_knockback = false
		move_and_slide()
		return

	damage_timer -= delta
	if distance < 10.0 and damage_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(CONTACT_DAMAGE)
			damage_timer = DAMAGE_COOLDOWN

	match state:
		State.IDLE:
			velocity = Vector2.ZERO
			if distance <= DETECTION_RANGE:
				state = State.APPROACHING
		State.APPROACHING:
			var dir = to_player.normalized()
			velocity = dir * FLY_SPEED
			_play_directional_animation(dir)
			if distance <= DASH_TRIGGER_DISTANCE:
				state = State.LOCK_ON
				state_timer = LOCK_ON_TIME
				velocity = Vector2.ZERO
				dash_direction = to_player.normalized()
				dash_start = global_position
				dash_target = player.global_position + dash_direction * distance
			if distance > DETECTION_RANGE * 2.5:
				state = State.IDLE
		State.LOCK_ON:
			velocity = Vector2.ZERO
			state_timer -= delta
			var blink = fmod(state_timer, 0.1) < 0.05
			anim.modulate = Color(1.5, 1.5, 0.5) if blink else Color.WHITE
			_play_directional_animation(dash_direction)
			if state_timer <= 0:
				state = State.DASHING
				anim.modulate = Color(1.0, 1.0, 0.6)
		State.DASHING:
			velocity = dash_direction * DASH_SPEED
			_play_directional_animation(dash_direction)
			var to_target = dash_target - global_position
			if to_target.dot(dash_direction) <= 0:
				global_position = dash_target
				velocity = Vector2.ZERO
				state = State.RECOVERING
				state_timer = RECOVER_TIME
				anim.modulate = Color.WHITE
		State.RECOVERING:
			velocity = Vector2.ZERO
			state_timer -= delta
			if state_timer <= 0:
				state = State.APPROACHING

	move_and_slide()

func _play_directional_animation(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		anim.play("right" if dir.x > 0 else "left")
	else:
		anim.play("forward" if dir.y > 0 else "backward")
