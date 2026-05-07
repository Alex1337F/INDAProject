extends Area2D

@export var target_scene: String
@export var idle_animation: String = "default"


@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var portal_open: bool = false
var check_timer: Timer

func _ready() -> void:
	body_entered.connect(_on_body_entered)

	anim.visible = false
	monitoring = false

	var wave_manager = get_tree().get_first_node_in_group("wave_manager")

	# If this level has waves, wait for level_complete
	if wave_manager:
		wave_manager.level_complete.connect(_open_portal)

	# Otherwise use normal enemy-clear logic
	else:
		check_timer = Timer.new()
		add_child(check_timer)
		check_timer.wait_time = 0.5
		check_timer.timeout.connect(_check_enemies)
		check_timer.start()

func _check_enemies() -> void:
	if portal_open:
		return
	var enemies = get_tree().get_nodes_in_group("enemy")
	print("Enemies alive: ", enemies.size())
	for e in enemies:
		print("  - ", e.name, " | valid: ", is_instance_valid(e))
	if enemies.size() == 0:
		check_timer.stop()
		_open_portal()

func _open_portal() -> void:
	print("open")
	print("anim visible: ", anim.visible)
	print("anim global_position: ", anim.global_position)
	print("anim scale before tween: ", anim.scale)
	portal_open = true
	anim.visible = true
	monitoring = true
	anim.scale = Vector2(0.0, 0.0)
	var tween = create_tween()
	tween.tween_property(anim, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	anim.play(idle_animation)
func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player") and portal_open:
		call_deferred("_change_scene")

func _change_scene() -> void:
	get_tree().change_scene_to_file(target_scene)
