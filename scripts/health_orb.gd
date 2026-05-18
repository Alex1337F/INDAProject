extends Area2D

@export var heal_amount: int = 25

@onready var sprite: Sprite2D = $Sprite2D
@onready var particles: Node2D = $Particles

var bob_time: float = 0.0
var is_picked_up: bool = false
var lifetime: float = 12.0
var pulse_time: float = 0.0

func _ready() -> void:
	bob_time = randf() * TAU
	body_entered.connect(_on_body_entered)

	# Pop-in animation
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _process(delta: float) -> void:
	if is_picked_up:
		return

	# Bobbing
	bob_time += delta * 2.5
	sprite.position.y = sin(bob_time) * 2.5

	# Gentle sprite pulse
	pulse_time += delta * 3.0
	var s = 1.0 + sin(pulse_time) * 0.08
	sprite.scale = Vector2(s, s)

	# Spawn ambient particles
	_spawn_ambient_particle(delta)

	# Lifetime
	lifetime -= delta
	if lifetime < 3.0:
		# Flash when about to expire
		modulate.a = 0.4 if fmod(lifetime, 0.3) < 0.15 else 1.0
	if lifetime <= 0:
		_expire()

func _on_body_entered(body: Node) -> void:
	if is_picked_up:
		return
	if body is PlayerBase:
		if body.current_health >= body.MAX_HEALTH:
			return  # Don't pick up at full health
		_collect(body)

func _collect(player: PlayerBase) -> void:
	is_picked_up = true
	player.heal(heal_amount)

	# Burst of heal particles
	for i in range(8):
		_spawn_burst_particle()

	# Pickup animation
	var tween = create_tween().set_parallel(true)
	tween.tween_property(sprite, "scale", Vector2(2.0, 2.0), 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	tween.tween_property(sprite, "position:y", sprite.position.y - 15.0, 0.25).set_ease(Tween.EASE_OUT)
	await tween.finished
	queue_free()

func _expire() -> void:
	is_picked_up = true
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	await tween.finished
	queue_free()

# Small green sparkle particles floating upward
var _particle_timer: float = 0.0
func _spawn_ambient_particle(delta: float) -> void:
	_particle_timer -= delta
	if _particle_timer > 0:
		return
	_particle_timer = 0.15

	var p = ColorRect.new()
	var s = randf_range(1.5, 3.0)
	p.size = Vector2(s, s)
	p.color = Color(0.3, 1.0, 0.4, 0.6)
	p.position = global_position + Vector2(randf_range(-6, 6), randf_range(-4, 4))
	get_tree().current_scene.add_child(p)

	var tween = p.create_tween().set_parallel(true)
	tween.tween_property(p, "position:y", p.position.y - randf_range(8, 14), 0.6)
	tween.tween_property(p, "modulate:a", 0.0, 0.6)
	tween.tween_property(p, "size", Vector2(0.5, 0.5), 0.6)
	tween.chain().tween_callback(p.queue_free)

func _spawn_burst_particle() -> void:
	var p = ColorRect.new()
	var s = randf_range(2.0, 4.0)
	p.size = Vector2(s, s)
	p.color = Color(0.2, 1.0, 0.35, 0.9)
	p.position = global_position + Vector2(randf_range(-3, 3), randf_range(-3, 3))
	get_tree().current_scene.add_child(p)

	var angle = randf() * TAU
	var dist = randf_range(12, 24)
	var target = p.position + Vector2(cos(angle), sin(angle)) * dist

	var tween = p.create_tween().set_parallel(true)
	tween.tween_property(p, "position", target, 0.35).set_ease(Tween.EASE_OUT)
	tween.tween_property(p, "modulate:a", 0.0, 0.35)
	tween.chain().tween_callback(p.queue_free)
