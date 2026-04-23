extends CharacterBody2D

const SPEED = 40.0
const PREFERRED_DISTANCE = 80.0 # Distance the mage tries to keep from the player
const STOP_DISTANCE = 10.0 # Tolerance band so it doesn't jitter
const FIRE_INTERVAL = 1.5 # Seconds between shots
const PROJECTILE_SPEED = 120.0

@onready var player: CharacterBody2D = $"../player/Archer"
@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hands: Sprite2D = $Hands
@onready var hands2: Sprite2D = $Hands2
@onready var bone: Sprite2D = $Bone

var fire_timer: float = 0.0
var wiggle_time: float = 0.0
var is_dead: bool = false

# Store the original positions/rotations set in the editor
var hands_base_pos: Vector2
var hands2_base_pos: Vector2
var bone_base_pos: Vector2
var bone_base_rot: float

const WIGGLE_SPEED = 8.0 # How fast the wiggle oscillates
const WIGGLE_AMOUNT = 1.5 # Pixels of vertical bob
const WIGGLE_ROTATION = 0.06 # Radians of rotation wiggle

# Preload the projectile scene (you'll create this in the editor)
var skeleton_projectile_scene: PackedScene = preload("res://scenes/skeleton_projectile.tscn")

func _ready() -> void:
	# Capture the positions you set in the editor as the "rest" positions
	hands_base_pos = hands.position
	hands2_base_pos = hands2.position
	bone_base_pos = bone.position
	bone_base_rot = bone.rotation

func _unhandled_input(event: InputEvent) -> void:
	# Debug: press P to kill the skeleton
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		if not is_dead:
			_die()

func _die() -> void:
	is_dead = true
	velocity = Vector2.ZERO
	# Hide the hands and staff
	hands.visible = false
	hands2.visible = false
	bone.visible = false
	# Play death animation (disable loop so it plays once and stops)
	anim.sprite_frames.set_animation_loop("die", false)
	anim.play("die")
	await anim.animation_finished
	queue_free()

func _physics_process(delta: float) -> void:
	if player == null or is_dead:
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	# --- Movement ---
	if distance > PREFERRED_DISTANCE + STOP_DISTANCE:
		# Too far – walk closer
		velocity = direction * SPEED
		_play_run_animation(direction)
	elif distance < PREFERRED_DISTANCE - STOP_DISTANCE:
		# Too close – back away
		velocity = - direction * SPEED
		_play_run_animation(-direction)
	else:
		# In the sweet spot – stand still and face the player
		velocity = Vector2.ZERO
		_play_idle_animation(direction)

	move_and_slide()

	# --- Wiggle hands & staff ---
	if velocity != Vector2.ZERO:
		wiggle_time += delta * WIGGLE_SPEED
		var bob = sin(wiggle_time) * WIGGLE_AMOUNT
		var bob2 = sin(wiggle_time + 1.0) * WIGGLE_AMOUNT # offset phase
		var rot = sin(wiggle_time + 0.5) * WIGGLE_ROTATION

		hands.position = hands_base_pos + Vector2(0, bob)
		hands2.position = hands2_base_pos + Vector2(0, bob2)
		bone.position = bone_base_pos + Vector2(0, bob2)
		bone.rotation = bone_base_rot + rot
	else:
		# Smoothly return to rest position when standing still
		wiggle_time = 0.0
		hands.position = hands.position.lerp(hands_base_pos, 0.15)
		hands2.position = hands2.position.lerp(hands2_base_pos, 0.15)
		bone.position = bone.position.lerp(bone_base_pos, 0.15)
		bone.rotation = lerp(bone.rotation, bone_base_rot, 0.15)

	# --- Shooting ---
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
