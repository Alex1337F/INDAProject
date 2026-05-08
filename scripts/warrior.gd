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
		_start_berserker_effect()
	if type == "spin_attack":
		_spawn_spin_ring()
	if type == "triple_slash":
		_flash_slash_indicator()

func _on_powerup_expired(type: String) -> void:
	if type == "berserker":
		berserker_active = false
		_sprite.modulate = Color.WHITE

func _start_berserker_effect() -> void:
	# Turn player red with pulsing glow
	var tween = create_tween().set_loops()
	tween.tween_property(_sprite, "modulate", Color(1.8, 0.2, 0.2, 1.0), 0.4)
	tween.tween_property(_sprite, "modulate", Color(1.2, 0.1, 0.1, 1.0), 0.4)
	# Store tween so we can kill it later
	set_meta("berserker_tween", tween)

func _on_powerup_expired_berserker() -> void:
	if has_meta("berserker_tween"):
		get_meta("berserker_tween").kill()
		remove_meta("berserker_tween")
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
	if PowerupManager.has_powerup("spin_attack"):
		spin_damage_accum += SPIN_DAMAGE_PER_SEC * delta
		if spin_damage_accum >= 1.0:
			var dmg = int(spin_damage_accum)
			spin_damage_accum -= dmg
			_do_spin_damage(dmg)
		_spawn_spin_particles(delta)

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
	_spawn_slash_effect(direction, false)
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
		_spawn_slash_effect(direction, true)
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
		if is_instance_valid(body) and body.has_method("take_damage"):
			var dist = global_position.distance_to(body.global_position)
			if dist <= SPIN_RADIUS:
				body.take_damage(dmg, body.global_position)

# --- Visual Effects ---

var spin_angle: float = 0.0
var spin_particle_timer: float = 0.0

func _spawn_spin_particles(delta: float) -> void:
	spin_particle_timer -= delta
	if spin_particle_timer > 0:
		return
	spin_particle_timer = 0.05  # spawn every 0.05s

	spin_angle += 0.4
	# Spawn 3 orbiting slashes evenly spread
	for i in range(3):
		var angle = spin_angle + (TAU / 3.0 * i)
		var offset = Vector2(cos(angle), sin(angle)) * SPIN_RADIUS
		_spawn_orbit_slash(global_position + offset, angle)

func _spawn_orbit_slash(pos: Vector2, angle: float) -> void:
	var slash = ColorRect.new()
	slash.color = Color(0.6, 0.8, 1.0, 0.7)
	slash.size = Vector2(14, 4)
	slash.position = Vector2(-7, -2)
	var node = Node2D.new()
	node.global_position = pos
	node.rotation = angle
	node.add_child(slash)
	get_tree().current_scene.add_child(node)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(slash, "color:a", 0.0, 0.12)
	tween.tween_property(node, "scale", Vector2(1.5, 1.5), 0.12)
	await tween.finished
	node.queue_free()

func _spawn_slash_effect(direction: Vector2, is_triple: bool) -> void:
	var count = 3 if is_triple else 1
	var color = Color(1.0, 0.5, 0.1, 0.9) if is_triple else Color(1.0, 1.0, 0.6, 0.9)
	for i in range(count):
		var offset_angle = direction.angle() + randf_range(-0.3, 0.3)
		var slash_dir = Vector2(cos(offset_angle), sin(offset_angle))
		var node = Node2D.new()
		node.global_position = global_position + slash_dir * 20.0
		node.rotation = offset_angle
		get_tree().current_scene.add_child(node)
		# Main slash line
		var rect = ColorRect.new()
		rect.color = color
		rect.size = Vector2(28, 3)
		rect.position = Vector2(-4, -1.5)
		node.add_child(rect)
		# Secondary thinner line slightly offset
		var rect2 = ColorRect.new()
		rect2.color = Color(color.r, color.g, color.b, 0.4)
		rect2.size = Vector2(20, 2)
		rect2.position = Vector2(-4, 3)
		node.add_child(rect2)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(node, "scale", Vector2(1.6, 1.0), 0.15).set_ease(Tween.EASE_OUT)
		tween.tween_property(rect, "color:a", 0.0, 0.2)
		tween.tween_property(rect2, "color:a", 0.0, 0.2)
		tween.tween_property(node, "global_position", node.global_position + slash_dir * 18.0, 0.15)
		await tween.finished
		node.queue_free()

func _spawn_spin_ring() -> void:
	# Big ring flash when spin activates
	var node = Node2D.new()
	node.global_position = global_position
	get_tree().current_scene.add_child(node)
	# Draw ring as multiple small rects in a circle
	for i in range(12):
		var angle = TAU / 12.0 * i
		var rect = ColorRect.new()
		rect.color = Color(0.4, 0.7, 1.0, 0.8)
		rect.size = Vector2(10, 3)
		rect.position = Vector2(cos(angle) * SPIN_RADIUS - 5, sin(angle) * SPIN_RADIUS - 1.5)
		node.add_child(rect)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(node, "scale", Vector2(1.5, 1.5), 0.4).set_ease(Tween.EASE_OUT)
	tween.tween_property(node, "modulate:a", 0.0, 0.4)
	await tween.finished
	node.queue_free()

func _flash_slash_indicator() -> void:
	# X shape flash when triple slash activates
	for angle in [0.0, PI / 2.0, PI / 4.0, -PI / 4.0]:
		var node = Node2D.new()
		node.global_position = global_position
		node.rotation = angle
		get_tree().current_scene.add_child(node)
		var rect = ColorRect.new()
		rect.color = Color(1.0, 0.5, 0.1, 0.9)
		rect.size = Vector2(40, 3)
		rect.position = Vector2(-20, -1.5)
		node.add_child(rect)
		var tween = create_tween().set_parallel(true)
		tween.tween_property(node, "scale", Vector2(1.8, 1.8), 0.3).set_ease(Tween.EASE_OUT)
		tween.tween_property(rect, "color:a", 0.0, 0.3)
		await tween.finished
		node.queue_free()
