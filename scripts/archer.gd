extends PlayerBase

const ARROW = preload("res://scenes/arrow.tscn")
const BASE_FIRE_INTERVAL: float = 0.5
const RAPID_FIRE_MULT = 0.25  # 75% reduction

@onready var bow: Node2D = $weapon
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

var fire_timer: float = 0.0
var can_shoot: bool = true

func _ready() -> void:
	register_sprite(animated_sprite_2d)
	super._ready()

func get_fire_interval() -> float:
	var interval = BASE_FIRE_INTERVAL / GameState.get_multiplier("firerate")
	if PowerupManager.has_powerup("rapid_fire"):
		interval *= RAPID_FIRE_MULT
	return interval

func _process(delta: float) -> void:
	if not can_shoot:
		fire_timer -= delta
		if fire_timer <= 0.0:
			can_shoot = true

	var aiming = Input.is_action_pressed("aim-left") or Input.is_action_pressed("aim-right") or \
				 Input.is_action_pressed("aim-up") or Input.is_action_pressed("aim-down")

	if aiming and can_shoot:
		fire_arrow()
		can_shoot = false
		fire_timer = get_fire_interval()

func fire_arrow() -> void:
	if PowerupManager.has_powerup("triple_shot"):
		_fire_triple()
	else:
		_fire_single(bow.aim_direction)

func _fire_single(dir: Vector2) -> void:
	var arrow = ARROW.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = bow.global_position
	arrow.rotation = dir.angle()
	arrow.scale.x = 1.0
	if arrow.has_method("set_explosive"):
		arrow.set_explosive(PowerupManager.has_powerup("explosive_arrows"))
	if arrow.has_method("set_direction"):
		arrow.set_direction(dir)
	elif "direction" in arrow:
		arrow.direction = dir

func _fire_triple() -> void:
	var angles = [-deg_to_rad(20.0), 0.0, deg_to_rad(20.0)]
	for offset in angles:
		var dir = bow.aim_direction.rotated(offset)
		_fire_single(dir)
