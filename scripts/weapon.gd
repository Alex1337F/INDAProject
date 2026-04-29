extends Node2D

const AIM_DISTANCE = 12.0
var aim_direction = Vector2.RIGHT

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
