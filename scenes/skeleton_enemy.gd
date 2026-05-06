extends CharacterBody2D
const SPEED = 40.0
const PREFERRED_DISTANCE = 80.0
const STOP_DISTANCE = 10.0
const FIRE_INTERVAL = 1.5
const PROJECTILE_SPEED = 120.0
const MAX_HEALTH = 50
const KNOCKBACK_FORCE = 350.0
const KNOCKBACK_DECAY = 10.0

@onready var player: CharacterBody2D
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hands: Sprite2D = $Hands
@onready var hands2: Sprite2D = $Hands2
@onready var bone: Sprite2D = $Bone

var fire_timer: float = 0.0
var wiggle_time: float = 0.0
var is_dead: bool = false
var current_health: int = MAX_HEALTH
var is_knockback: bool = false

var hands_base_pos: Vector2
var hands2_base_pos: Vector2
var bone_base_pos: Vector2
var bone_base_rot: float

const WIGGLE_SPEED = 8.0
const WIGGLE_AMOUNT = 1.5
const WIGGLE_ROTATION = 0.06

var skeleton_projectile_scene: PackedScene = preload("res://scenes/skeleton_projectile.tscn")

func _ready() -> void:
	add_to_group("enemy")
	current_health = MAX_HEALTH
	hands_base_pos = hands.position
	hands2_base_pos = hands2.position
	bone_base_pos = bone.position
	bone_base_rot = bone.rotation
	player = get_tree().get_first_node_in_group("player")

func take_damage(amount: int, knockback_origin: Vector2) -> void:
	if is_dead:
		return
	current_health -= amount
	var knockback_dir = (global_position - knockback_origin).normalized()
	velocity = knockback_dir * KNOCKBACK_FORCE
	is_knockback = true
	anim.modulate = Color(1.0, 0.2, 0.2, 1.0)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.2)
	if current_health <= 0:
		_die()



func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	hands.visible = false
	hands2.visible = false
	bone.visible = false
	anim.sprite_frames.set_animation_loop("die", false)
	anim.play("die")
	await anim.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
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
	var direction = to_player.normalized()

	if distance > PREFERRED_DISTANCE + STOP_DISTANCE:
		velocity = direction * SPEED
		_play_run_animation(direction)
	elif distance < PREFERRED_DISTANCE - STOP_DISTANCE:
		velocity = -direction * SPEED
		_play_run_animation(-direction)
	else:
		velocity = Vector2.ZERO
		_play_idle_animation(direction)

	move_and_slide()

	if velocity != Vector2.ZERO:
		wiggle_time += delta * WIGGLE_SPEED
		var bob = sin(wiggle_time) * WIGGLE_AMOUNT
		var bob2 = sin(wiggle_time + 1.0) * WIGGLE_AMOUNT
		var rot = sin(wiggle_time + 0.5) * WIGGLE_ROTATION
		hands.position = hands_base_pos + Vector2(0, bob)
		hands2.position = hands2_base_pos + Vector2(0, bob2)
		bone.position = bone_base_pos + Vector2(0, bob2)
		bone.rotation = bone_base_rot + rot
	else:
		wiggle_time = 0.0
		hands.position = hands.position.lerp(hands_base_pos, 0.15)
		hands2.position = hands2.position.lerp(hands2_base_pos, 0.15)
		bone.position = bone.position.lerp(bone_base_pos, 0.15)
		bone.rotation = lerp(bone.rotation, bone_base_rot, 0.15)

	fire_timer += delta
	if distance <= PREFERRED_DISTANCE + STOP_DISTANCE + 40.0:
		if fire_timer >= FIRE_INTERVAL:
			fire_timer = 0.0
			_fire_projectile(direction)

func _play_run_animation(dir: Vector2) -> void:
	anim.play("run")
	anim.flip_h = dir.x < 0

func _play_idle_animation(dir: Vector2) -> void:
	anim.play("idle")
	anim.flip_h = dir.x < 0

func _fire_projectile(direction: Vector2) -> void:
	var projectile = skeleton_projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.direction = direction
	projectile.speed = PROJECTILE_SPEED
