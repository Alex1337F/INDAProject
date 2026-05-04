extends CharacterBody2D
const FLOAT_SPEED = 65.0
const DETECTION_RANGE = 130.0
const TELEPORT_INTERVAL_MIN = 1.8
const TELEPORT_INTERVAL_MAX = 3.2
const BLINK_STRIKE_CHANCE = 0.35
const TELEPORT_RADIUS = 50.0
const CONTACT_DAMAGE = 15
const DAMAGE_COOLDOWN = 1.0
const MAX_HEALTH = 45
const KNOCKBACK_FORCE = 320.0
const KNOCKBACK_DECAY = 8.0

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var player: CharacterBody2D
var current_health: int = MAX_HEALTH
var is_knockback: bool = false
var teleport_timer: float = 0.0
var damage_timer: float = 0.0
var bob_time: float = 0.0
var is_teleporting: bool = false
var teleport_phase: float = 0.0
var teleport_target: Vector2 = Vector2.ZERO
var active: bool = false

const FADE_OUT_TIME = 0.15
const FADE_IN_TIME = 0.2

func _ready() -> void:
	add_to_group("enemy")
	current_health = MAX_HEALTH
	teleport_timer = randf_range(TELEPORT_INTERVAL_MIN, TELEPORT_INTERVAL_MAX)
	player = get_tree().get_first_node_in_group("player")

func take_damage(amount: int, knockback_origin: Vector2) -> void:
	current_health -= amount
	# Cancel teleport if mid-teleport
	if is_teleporting:
		is_teleporting = false
		anim.modulate.a = 1.0
		anim.scale = Vector2.ONE
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

	bob_time += delta * 4.0
	anim.position.y = sin(bob_time) * 2.0

	if is_knockback:
		velocity = velocity.lerp(Vector2.ZERO, KNOCKBACK_DECAY * delta)
		if velocity.length() < 5.0:
			is_knockback = false
		move_and_slide()
		return

	if not active:
		velocity = Vector2.ZERO
		if distance <= DETECTION_RANGE:
			active = true
			anim.play("forward")
		return

	if is_teleporting:
		_process_teleport(delta)
		return

	var direction = to_player.normalized()
	velocity = direction * FLOAT_SPEED
	_play_directional_animation(direction)
	move_and_slide()

	teleport_timer -= delta
	if teleport_timer <= 0:
		_begin_teleport()

	damage_timer -= delta
	if distance < 12.0 and damage_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(CONTACT_DAMAGE)
			damage_timer = DAMAGE_COOLDOWN
			var knockback = create_tween()
			knockback.tween_property(self, "global_position",
				global_position - direction * 30.0, 0.15).set_ease(Tween.EASE_OUT)

func _begin_teleport() -> void:
	is_teleporting = true
	teleport_phase = 0.0
	velocity = Vector2.ZERO
	if randf() < BLINK_STRIKE_CHANCE and player != null:
		var behind = Vector2.DOWN
		if player.velocity.length() > 10:
			behind = -player.velocity.normalized()
		teleport_target = player.global_position + behind * 18.0
	else:
		var angle = randf() * TAU
		var dist = randf_range(25.0, TELEPORT_RADIUS)
		teleport_target = player.global_position + Vector2(cos(angle), sin(angle)) * dist

func _process_teleport(delta: float) -> void:
	teleport_phase += delta
	if teleport_phase < FADE_OUT_TIME:
		var t = teleport_phase / FADE_OUT_TIME
		anim.modulate.a = 1.0 - t
		anim.scale = Vector2.ONE * (1.0 - t * 0.6)
	elif teleport_phase < FADE_OUT_TIME + 0.05:
		global_position = teleport_target
		anim.modulate.a = 0.0
	elif teleport_phase < FADE_OUT_TIME + 0.05 + FADE_IN_TIME:
		var t = (teleport_phase - FADE_OUT_TIME - 0.05) / FADE_IN_TIME
		anim.modulate.a = t
		anim.scale = Vector2.ONE * (1.0 + (1.0 - t) * 0.4)
		if player:
			var dir = (player.global_position - global_position).normalized()
			_play_directional_animation(dir)
	else:
		anim.modulate.a = 1.0
		anim.scale = Vector2.ONE
		is_teleporting = false
		teleport_timer = randf_range(TELEPORT_INTERVAL_MIN, TELEPORT_INTERVAL_MAX)

func _play_directional_animation(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		anim.play("right" if dir.x > 0 else "left")
	else:
		anim.play("forward" if dir.y > 0 else "backward")
