extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBarContainer/BarArea/HealthBar
@onready var damage_bar: ProgressBar = $HealthBarContainer/BarArea/DamageBar
@onready var health_label: Label = $HealthBarContainer/BarArea/HealthLabel
@onready var heart_icon: Label = $HealthBarContainer/HeartIcon
@onready var bar_container: Control = $HealthBarContainer

var previous_health: int = 100
var shake_intensity: float = 0.0
var original_bar_pos: Vector2
var heart_pulse_tween: Tween
var is_low_health: bool = false

func _ready() -> void:
	original_bar_pos = bar_container.position
	# Find the player node (dynamically spawned) via group
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_signal("health_changed"):
		player.health_changed.connect(_on_health_changed)
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)
		# Initialize
		previous_health = player.current_health
		damage_bar.max_value = player.MAX_HEALTH
		damage_bar.value = player.current_health
		_on_health_changed(player.current_health, player.MAX_HEALTH)

func _process(delta: float) -> void:
	# Shake decay
	if shake_intensity > 0:
		shake_intensity = lerp(shake_intensity, 0.0, 8.0 * delta)
		bar_container.position = original_bar_pos + Vector2(
			randf_range(-shake_intensity, shake_intensity),
			randf_range(-shake_intensity, shake_intensity)
		)
		if shake_intensity < 0.3:
			shake_intensity = 0.0
			bar_container.position = original_bar_pos

func _on_health_changed(current_hp: int, max_hp: int) -> void:
	var took_damage = current_hp < previous_health

	# --- Smooth health bar tween ---
	health_bar.max_value = max_hp
	damage_bar.max_value = max_hp

	var bar_tween = create_tween()
	bar_tween.tween_property(health_bar, "value", float(current_hp), 0.15).set_ease(Tween.EASE_OUT)

	# --- Damage ghost bar (trails behind) ---
	if took_damage:
		# Delay, then smoothly catch up
		var dmg_tween = create_tween()
		dmg_tween.tween_interval(0.4)
		dmg_tween.tween_property(damage_bar, "value", float(current_hp), 0.6).set_ease(Tween.EASE_IN_OUT)

		# --- Shake ---
		var damage_amount = previous_health - current_hp
		shake_intensity = clampf(float(damage_amount) * 0.5, 3.0, 12.0)

		# --- Flash the label red briefly ---
		health_label.modulate = Color(1.0, 0.3, 0.3)
		var label_tween = create_tween()
		label_tween.tween_property(health_label, "modulate", Color.WHITE, 0.4)

		# --- Heart icon bounce ---
		var heart_tween = create_tween()
		heart_icon.scale = Vector2(1.0, 1.0)
		heart_tween.tween_property(heart_icon, "scale", Vector2(1.6, 1.6), 0.08)
		heart_tween.tween_property(heart_icon, "scale", Vector2(0.85, 0.85), 0.1)
		heart_tween.tween_property(heart_icon, "scale", Vector2(1.0, 1.0), 0.15)
	else:
		# Healing / respawn – damage bar catches up immediately
		damage_bar.value = current_hp
		# Reset heart icon (in case we respawned after death)
		heart_icon.modulate = Color(0.95, 0.25, 0.25, 1.0)

	# --- Update label ---
	health_label.text = str(current_hp) + " / " + str(max_hp)

	# --- Color the fill bar based on health ---
	var percent = float(current_hp) / float(max_hp)
	var fill_style = health_bar.get_theme_stylebox("fill").duplicate()
	if percent > 0.5:
		fill_style.bg_color = Color(0.2, 0.9, 0.3)    # Green
	elif percent > 0.25:
		fill_style.bg_color = Color(1.0, 0.75, 0.1)   # Yellow/Orange
	else:
		fill_style.bg_color = Color(0.9, 0.15, 0.15)  # Red
	health_bar.add_theme_stylebox_override("fill", fill_style)

	# --- Low health pulsing heart ---
	if percent <= 0.25 and not is_low_health:
		is_low_health = true
		_start_heart_pulse()
	elif percent > 0.25 and is_low_health:
		is_low_health = false
		_stop_heart_pulse()

	previous_health = current_hp

func _start_heart_pulse() -> void:
	if heart_pulse_tween:
		heart_pulse_tween.kill()
	heart_pulse_tween = create_tween().set_loops()
	heart_pulse_tween.tween_property(heart_icon, "modulate:a", 0.4, 0.4).set_ease(Tween.EASE_IN_OUT)
	heart_pulse_tween.tween_property(heart_icon, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_IN_OUT)

func _stop_heart_pulse() -> void:
	if heart_pulse_tween:
		heart_pulse_tween.kill()
		heart_pulse_tween = null
	heart_icon.modulate.a = 1.0

func _on_player_died() -> void:
	health_label.text = "DEAD"
	_stop_heart_pulse()
	# Heart shatters
	var death_tween = create_tween()
	death_tween.tween_property(heart_icon, "modulate", Color(0.5, 0.5, 0.5, 0.4), 0.5)
