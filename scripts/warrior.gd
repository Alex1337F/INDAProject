extends PlayerBase

func _process(delta: float) -> void:
	if not is_attacking:
		if Input.is_action_just_pressed("ui_left"):
			attack("attack-right", true)
		elif Input.is_action_just_pressed("ui_right"):
			attack("attack-right", false)
		elif Input.is_action_just_pressed("ui_up"):
			attack("attack-forward", false)
		elif Input.is_action_just_pressed("ui_down"):
			attack("attack-backwards", false)

func attack(anim_name: String, flip: bool) -> void:
	is_attacking = true
	anim.flip_h = flip
	anim.play(anim_name)
	await anim.animation_finished
	is_attacking = false
