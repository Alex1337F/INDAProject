extends CharacterBody2D

signal boss_died
signal died(pos: Vector2)

const MAX_HEALTH = 600  # 10x normal enemy (60hp)
const SPEED = 45.0
const KNOCKBACK_FORCE = 150.0
const KNOCKBACK_DECAY = 6.0

# Contact damage
const CONTACT_DAMAGE = 20
const CONTACT_COOLDOWN = 0.8
const CONTACT_RANGE = 14.0

# Slam attack (medium range)
const SLAM_DAMAGE = 35
const SLAM_RANGE = 55.0
const SLAM_COOLDOWN = 2.5
const SLAM_WINDUP = 0.4
const RANDOM_SLAM_CHANCE = 0.22
const FAR_SLAM_MIN_DISTANCE = 120.0

var current_health: int = MAX_HEALTH
var is_knockback: bool = false
var contact_timer: float = 0.0
var slam_timer: float = 1.0
var is_slamming: bool = false
var player: CharacterBody2D
var health_bar: Node2D

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	add_to_group("enemy")
	current_health = MAX_HEALTH
	player = get_tree().get_first_node_in_group("player")
	_create_health_bar()
	# Entrance effect
	anim.scale = Vector2(0.0, 0.0)
	var tween = create_tween()
	tween.tween_property(anim, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_show_arrival_text()

func _create_health_bar() -> void:
	var hb_script = preload("res://scripts/enemy_health_bar.gd")
	health_bar = Node2D.new()
	health_bar.set_script(hb_script)
	add_child(health_bar)
	health_bar.setup(MAX_HEALTH)

func _show_arrival_text() -> void:
	var canvas = CanvasLayer.new()
	get_tree().current_scene.add_child(canvas)
	var label = Label.new()
	label.text = "⚠ MINI-BOSS APPROACHES ⚠"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	label.offset_left = -400
	label.offset_right = 400
	label.offset_top = 40
	label.offset_bottom = 80
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.1))
	label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.modulate.a = 0.0
	canvas.add_child(label)
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3)
	tween.tween_interval(2.0)
	tween.tween_property(label, "modulate:a", 0.0, 0.5)
	await tween.finished
	canvas.queue_free()

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

	if is_slamming:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	velocity = direction * SPEED
	anim.play("idle")  # always idle while moving
	move_and_slide()

	contact_timer -= delta
	slam_timer -= delta

	if distance < CONTACT_RANGE and contact_timer <= 0:
		if player.has_method("take_damage"):
			player.take_damage(CONTACT_DAMAGE)
		contact_timer = CONTACT_COOLDOWN

	if slam_timer <= 0 and not is_slamming:

	# Close range = always slam
		if distance < SLAM_RANGE:
			_do_slam(direction)

	# Far away = occasional stomp anyway
		elif distance > FAR_SLAM_MIN_DISTANCE:
			if randf() < RANDOM_SLAM_CHANCE:
				_do_slam(direction)

func _do_slam(direction: Vector2) -> void:
	is_slamming = true
	slam_timer = SLAM_COOLDOWN

	# Play jump animation as windup
	anim.sprite_frames.set_animation_loop("jump", false)
	anim.play("jump")
	await anim.animation_finished

	# Flash and grow on impact
	var slam_tween = create_tween().set_parallel(true)
	slam_tween.tween_property(anim, "modulate", Color(2.0, 1.8, 0.2), 0.05)
	slam_tween.tween_property(anim, "scale", Vector2(1.3, 1.3), 0.05)
	await get_tree().create_timer(0.05).timeout

	var reset_tween = create_tween().set_parallel(true)
	reset_tween.tween_property(anim, "modulate", Color.WHITE, 0.15)
	reset_tween.tween_property(anim, "scale", Vector2(1.0, 1.0), 0.15)

	# Check if player is still in range
	if player and global_position.distance_to(player.global_position) < SLAM_RANGE:
		if player.has_method("take_damage"):
			player.take_damage(SLAM_DAMAGE)

	_spawn_slam_projectiles()
	_spawn_slam_effect()

	# Go back to idle after slam
	anim.play("idle")
	await get_tree().create_timer(0.3).timeout
	is_slamming = false

func _spawn_slam_projectiles() -> void:
	var projectile_scene = preload("res://scenes/shockwave_projectile.tscn")

	for i in range(8):
		var projectile = projectile_scene.instantiate()

		var angle = TAU / 8.0 * i
		var dir = Vector2.RIGHT.rotated(angle)

		projectile.global_position = global_position
		projectile.direction = dir

		get_tree().current_scene.add_child(projectile)

	# Big impact flash
	_create_slam_burst()

func _create_slam_burst():
	var burst = Node2D.new()
	burst.global_position = global_position
	get_tree().current_scene.add_child(burst)

	for i in range(12):
		var rect = ColorRect.new()

		rect.color = Color(1.0, 0.7, 0.2, 1.0)
		rect.size = Vector2(20, 6)
		rect.position = Vector2(-10, -3)

		rect.rotation = TAU / 12.0 * i

		burst.add_child(rect)

	var tween = create_tween().set_parallel(true)

	tween.tween_property(burst, "scale", Vector2(4.0, 4.0), 0.35)
	tween.tween_property(burst, "modulate:a", 0.0, 0.35)

	await tween.finished
	burst.queue_free()
func _spawn_slam_effect() -> void:
	var node = Node2D.new()
	node.global_position = global_position
	get_tree().current_scene.add_child(node)

	# Ring of rects as shockwave
	for i in range(8):
		var angle = TAU / 8.0 * i
		var rect = ColorRect.new()
		rect.color = Color(1.0, 0.6, 0.1, 0.9)
		rect.size = Vector2(12, 5)
		rect.position = Vector2(cos(angle) * 20.0 - 6, sin(angle) * 20.0 - 2.5)
		node.add_child(rect)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector2(3.0, 3.0), 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 0.0, 0.35).set_ease(Tween.EASE_IN)
	await tween.finished
	node.queue_free()

func take_damage(amount: int, knockback_origin: Vector2) -> void:
	current_health -= amount
	current_health = max(current_health, 0)
	if health_bar:
		health_bar.update_health(current_health, MAX_HEALTH)
	var knockback_dir = (global_position - knockback_origin).normalized()
	velocity = knockback_dir * KNOCKBACK_FORCE
	is_knockback = true
	anim.modulate = Color(1.0, 0.2, 0.2, 1.0)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.2)
	if current_health <= 0:
		die()

func die() -> void:
	died.emit(global_position)
	boss_died.emit()
	_drop_coins()
	queue_free()

func _drop_coins() -> void:
	var game = get_tree().current_scene
	if not game.has_method("_spawn_coin_at"):
		return
	# Drop 10 coins scattered around death position
	for i in range(10):
		var angle = TAU / 10.0 * i
		var offset = Vector2(cos(angle), sin(angle)) * randf_range(10.0, 35.0)
		game.call_deferred("_spawn_coin_at", global_position + offset)

func _play_directional_animation(dir: Vector2) -> void:
	if abs(dir.x) >= abs(dir.y):
		anim.play("enemy-right")
		anim.flip_h = dir.x < 0
	else:
		anim.flip_h = false
		if dir.y < 0:
			anim.play("enemy-backwards")
		else:
			anim.play("enemy-forward")
