extends CharacterBody2D

const SPEED = 30.0
#@export var player: CharacterBody2D
@onready var player: CharacterBody2D


@onready var anim = $AnimatedSprite2D

func _ready():
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return

	var direction = (player.position - position).normalized()
	velocity = direction * SPEED

	# Animations
	if abs(direction.x) >= abs(direction.y):
		anim.play("enemy-right")
		anim.flip_h = direction.x < 0
	else:
		anim.flip_h = false
		if direction.y < 0:
			anim.play("enemy-backwards")
		else:
			anim.play("enemy-forward")

	move_and_slide()
