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
<<<<<<< Updated upstream
=======

func _do_attack(attack_direction: Vector2) -> void:
	var atk_mult: float = GameState.get_meta("attack_multiplier", 1.0) if GameState.has_meta("attack_multiplier") else 1.0
	var damage: int = roundi(25.0 * atk_mult)
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			var to_enemy = (body.global_position - global_position).normalized()
			var dot = attack_direction.dot(to_enemy)
			if dot > 0:
				body.take_damage(damage, global_position)
>>>>>>> Stashed changes
