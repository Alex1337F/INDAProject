extends Node2D

const ARROW = preload("uid://bltawdbi8a00q")
const AIM_DISTANCE = 12.0
var aim_direction = Vector2.RIGHT
var fire_timer: float = 0.0
const FIRE_INTERVAL = 0.6

func _ready() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.centered = true

func _process(delta: float) -> void:
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("aim-left"):
		input_dir.x -= 1
	if Input.is_action_pressed("aim-right"):
		input_dir.x += 1
	if Input.is_action_pressed("aim-up"):
		input_dir.y -= 1
	if Input.is_action_pressed("aim-down"):
		input_dir.y += 1
	if input_dir != Vector2.ZERO:
		aim_direction = input_dir.normalized()

	position = aim_direction * AIM_DISTANCE
	rotation = aim_direction.angle() + PI

	fire_timer += delta
	if input_dir != Vector2.ZERO:
		if fire_timer >= FIRE_INTERVAL:
			fire_timer = 0.0
			fire_arrow()
	else:
		fire_timer = FIRE_INTERVAL  # keeps it ready to fire instantly when you start aiming

func fire_arrow() -> void:
	var arrow = ARROW.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position
	arrow.rotation = aim_direction.angle()

	if arrow.has_method("set_direction"):
		arrow.set_direction(aim_direction)
	elif "direction" in arrow:
		arrow.direction = aim_direction
