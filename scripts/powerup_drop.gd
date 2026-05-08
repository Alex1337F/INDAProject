extends Area2D

@export var powerup_type: String = ""  # set when spawned

const ARCHER_POWERUPS = ["triple_shot", "rapid_fire", "explosive_arrows"]
const WARRIOR_POWERUPS = ["spin_attack", "triple_slash", "berserker"]
const BOB_SPEED = 2.0
const BOB_AMOUNT = 3.0
const LIFETIME = 10.0  # disappears after 10 seconds

@onready var label: Label = $Label
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var bob_time: float = 0.0
var lifetime_timer: float = LIFETIME
var base_y: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	base_y = position.y
	# Pick random powerup for the player's class if not set
	if powerup_type == "":
		if GameState.chosen_class == "archer":
			powerup_type = ARCHER_POWERUPS[randi() % ARCHER_POWERUPS.size()]
		else:
			powerup_type = WARRIOR_POWERUPS[randi() % WARRIOR_POWERUPS.size()]
	# Show name above pickup
	if label:
		label.text = _get_display_name()
	# Pop in
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _get_display_name() -> String:
	match powerup_type:
		"triple_shot": return "Triple Shot"
		"rapid_fire": return "Rapid Fire"
		"explosive_arrows": return "Explosive Arrows"
		"spin_attack": return "Spin Attack"
		"triple_slash": return "Triple Slash"
		"berserker": return "Berserker"
	return powerup_type

func _process(delta: float) -> void:
	# Bob up and down
	bob_time += delta * BOB_SPEED
	position.y = base_y + sin(bob_time) * BOB_AMOUNT
	# Lifetime
	lifetime_timer -= delta
	if lifetime_timer <= 0:
		queue_free()
	# Flash when about to expire
	if lifetime_timer < 3.0:
		modulate.a = 0.4 if fmod(lifetime_timer, 0.3) < 0.15 else 1.0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		PowerupManager.activate(powerup_type)
		_show_pickup_text()
		queue_free()

func _show_pickup_text() -> void:
	var canvas = CanvasLayer.new()
	get_tree().current_scene.add_child(canvas)
	var lbl = Label.new()
	lbl.text = "✦ " + _get_display_name() + " ✦"
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.set_anchors_preset(Control.PRESET_CENTER)
	lbl.grow_horizontal = Control.GROW_DIRECTION_BOTH
	lbl.offset_left = -300
	lbl.offset_right = 300
	lbl.offset_top = 20
	lbl.offset_bottom = 60
	lbl.add_theme_font_size_override("font_size", 28)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	lbl.modulate.a = 0.0
	canvas.add_child(lbl)
	var tween = create_tween()
	tween.tween_property(lbl, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.5)
	tween.tween_property(lbl, "modulate:a", 0.0, 0.5)
	await tween.finished
	canvas.queue_free()
