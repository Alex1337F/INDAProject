extends CharacterBody2D
const SPEED = 35.0
const CHASE_SPEED = 55.0
const DETECTION_RANGE = 100.0
const LOSE_RANGE = 160.0
const CONTACT_DAMAGE = 12
const DAMAGE_COOLDOWN = 0.8
const MAX_HEALTH = 40
const KNOCKBACK_FORCE = 300.0
const KNOCKBACK_DECAY = 10.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D
var current_health: int = MAX_HEALTH
var is_knockback: bool = false
var health_bar: Node2D

enum State { IDLE, PATROL, CHASE }
var state: State = State.IDLE
var patrol_direction: Vector2 = Vector2.ZERO
var patrol_timer: float = 0.0
var idle_timer: float = 0.0
var damage_timer: float = 0.0

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

	if is_knockback:
		velocity = velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		if velocity.length() < 5.0:
			is_knockback = false
		move_and_slide()
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()

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

	damage_timer -= delta
	if state == State.CHASE and distance < 12.0 and damage_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(CONTACT_DAMAGE)
			damage_timer = DAMAGE_COOLDOWN
			velocity = -to_player.normalized() * CHASE_SPEED * 2

func _play_directional_animation(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		anim.play("right" if dir.x > 0 else "left")
	else:
		anim.play("forward" if dir.y > 0 else "backward")

func _pick_patrol_direction() -> void:
	var angle = randf() * TAU
	patrol_direction = Vector2(cos(angle), sin(angle))
	patrol_timer = randf_range(1.5, 3.5)
