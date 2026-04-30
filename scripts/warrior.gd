extends PlayerBase

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

func _ready() -> void:
	register_sprite(_sprite)
	super._ready()

func _process(delta: float) -> void:
	if is_attacking:
		return
	if Input.is_action_just_pressed("aim-left"):
		attack("attack-right", true, Vector2.LEFT)
	elif Input.is_action_just_pressed("aim-right"):
		attack("attack-right", false, Vector2.RIGHT)
	elif Input.is_action_just_pressed("aim-up"):
		attack("attack-forward", false, Vector2.UP)
	elif Input.is_action_just_pressed("aim-down"):
		attack("attack-backwards", false, Vector2.DOWN)

func attack(anim_name: String, flip: bool, direction: Vector2) -> void:
	is_attacking = true
	anim.flip_h = flip
	
	# Rotate attack area to face direction
	attack_area.rotation = direction.angle()
	
	anim.play(anim_name)
	
	# Small delay so attack feels snappy, then do the hitcheck
	await get_tree().create_timer(0.15).timeout
	_do_attack(direction)
	
	await anim.animation_finished
	is_attacking = false

func _do_attack(attack_direction: Vector2) -> void:
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			var to_enemy = (body.global_position - global_position).normalized()
			var dot = attack_direction.dot(to_enemy)
			if dot > 0:
				body.take_damage(25, global_position)  # Pass global_position here
