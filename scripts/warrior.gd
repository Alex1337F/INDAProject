extends PlayerBase

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_area: Area2D = $AttackArea

const BASE_DAMAGE: int = 25
const SPIN_RADIUS = 60.0
const SPIN_DAMAGE_PER_SEC = 50.0
const BERSERKER_SPEED_MULT = 1.6
const BERSERKER_DAMAGE_MULT = 1.8

var spin_timer: float = 0.0
var spin_damage_accum: float = 0.0
var berserker_active: bool = false

func _ready() -> void:
	register_sprite(_sprite)
	super._ready()
	PowerupManager.powerup_activated.connect(_on_powerup_activated)
	PowerupManager.powerup_expired.connect(_on_powerup_expired)

func _on_powerup_activated(type: String) -> void:
	if type == "berserker":
		berserker_active = true
		_sprite.modulate = Color(1.0, 0.3, 0.3)

func _on_powerup_expired(type: String) -> void:
	if type == "berserker":
		berserker_active = false
		_sprite.modulate = Color.WHITE

func get_attack_damage() -> int:
	var dmg = int(ceil(float(BASE_DAMAGE) * GameState.get_multiplier("attack")))
	if berserker_active:
		dmg = int(ceil(float(dmg) * BERSERKER_DAMAGE_MULT))
	return dmg

func get_effective_speed() -> float:
	var spd = super.get_effective_speed()
	if berserker_active:
		spd *= BERSERKER_SPEED_MULT
	return spd

func _process(delta: float) -> void:
	# Spin attack tick
	if PowerupManager.has_powerup("spin_attack"):
		spin_damage_accum += SPIN_DAMAGE_PER_SEC * delta
		if spin_damage_accum >= 1.0:
			var dmg = int(spin_damage_accum)
			spin_damage_accum -= dmg
			_do_spin_damage(dmg)

	if is_attacking:
		return
	if Input.is_action_just_pressed("aim-left"):
		_start_attack("attack-right", true, Vector2.LEFT)
	elif Input.is_action_just_pressed("aim-right"):
		_start_attack("attack-right", false, Vector2.RIGHT)
	elif Input.is_action_just_pressed("aim-up"):
		_start_attack("attack-forward", false, Vector2.UP)
	elif Input.is_action_just_pressed("aim-down"):
		_start_attack("attack-backwards", false, Vector2.DOWN)

func _start_attack(anim_name: String, flip: bool, direction: Vector2) -> void:
	if PowerupManager.has_powerup("triple_slash"):
		triple_slash(anim_name, flip, direction)
	else:
		attack(anim_name, flip, direction)

func attack(anim_name: String, flip: bool, direction: Vector2) -> void:
	is_attacking = true
	anim.flip_h = flip
	attack_area.rotation = direction.angle()
	anim.play(anim_name)
	await get_tree().create_timer(0.05).timeout
	_do_attack(direction)
	await anim.animation_finished
	is_attacking = false

func triple_slash(anim_name: String, flip: bool, direction: Vector2) -> void:
	is_attacking = true
	for i in range(3):
		anim.flip_h = flip
		attack_area.rotation = direction.angle()
		anim.play(anim_name)
		await get_tree().create_timer(0.05).timeout
		_do_attack(direction)
		await get_tree().create_timer(0.2).timeout
	is_attacking = false

func _do_attack(attack_direction: Vector2) -> void:
	var bodies = attack_area.get_overlapping_bodies()
	for body in bodies:
		if body.is_in_group("enemy"):
			var to_enemy = (body.global_position - global_position).normalized()
			var dot = attack_direction.dot(to_enemy)
			if dot > 0:
				body.take_damage(get_attack_damage(), global_position)

func _do_spin_damage(dmg: int) -> void:
	for body in get_tree().get_nodes_in_group("enemy"):
		if is_instance_valid(body):
			var dist = global_position.distance_to(body.global_position)
			if dist <= SPIN_RADIUS:
				body.take_damage(dmg, global_position)
