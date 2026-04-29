extends PlayerBase

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	register_sprite(_sprite)
	super._ready()

func _process(delta: float) -> void:
	if is_attacking:
		return
	if Input.is_action_just_pressed("aim-left"):
		attack("attack-right", true)
	elif Input.is_action_just_pressed("aim-right"):
		attack("attack-right", false)
	elif Input.is_action_just_pressed("aim-up"):
		attack("attack-forward", false)
	elif Input.is_action_just_pressed("aim-down"):
		attack("attack-backwards", false)

func attack(anim_name: String, flip: bool) -> void:
	is_attacking = true
	anim.flip_h = flip
	anim.play(anim_name)
	await anim.animation_finished
	is_attacking = false
