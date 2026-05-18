extends Area2D

const SPEED = 190.0
const DAMAGE = 20
const HIT_RADIUS = 18.0

const SPLIT_ANGLE = 25.0
const SPLIT_DELAY = 0.65
const MAX_LIFETIME = 2.0

var direction: Vector2
var has_split := false
var lifetime := 0.0
var can_split := true

var player: CharacterBody2D

@onready var rect = $ColorRect

func _ready():
	player = get_tree().get_first_node_in_group("player")

	rotation = direction.angle()

	scale = Vector2(0.8, 0.8)

	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15)

func _physics_process(delta):
	global_position += direction * SPEED * delta

	lifetime += delta

	# Re-find player if needed
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	# DAMAGE DETECTION
	if player:
		var dist = global_position.distance_to(player.global_position)

		if dist <= HIT_RADIUS:
			if player.has_method("take_damage"):
				player.take_damage(DAMAGE)
			return

	# SPLIT
	if can_split and not has_split and lifetime >= SPLIT_DELAY:
		split()

	# FADE OUT
	if lifetime >= MAX_LIFETIME - 0.2:
		modulate.a = lerp(modulate.a, 0.0, 8.0 * delta)

	if lifetime >= MAX_LIFETIME:
		queue_free()

func split():
	has_split = true

	for angle_offset in [-SPLIT_ANGLE, SPLIT_ANGLE]:
		var child = preload("res://scenes/shockwave_projectile.tscn").instantiate()

		child.global_position = global_position
		child.direction = direction.rotated(deg_to_rad(angle_offset))

		# Prevent infinite recursion
		child.can_split = false

		get_tree().current_scene.add_child(child)

	_create_split_flash()
	queue_free()

func _create_split_flash():
	var flash = ColorRect.new()

	flash.color = Color(1.0, 0.8, 0.3, 0.9)
	flash.size = Vector2(16, 16)
	flash.position = Vector2(-8, -8)

	add_child(flash)

	var tween = create_tween()

	tween.tween_property(flash, "scale", Vector2(2.5, 2.5), 0.15)
	tween.parallel().tween_property(flash, "modulate:a", 0.0, 0.15)

	await tween.finished

	flash.queue_free()
