extends PanelContainer

@onready var name_label: Label = $VBox/NameLabel
@onready var timer_bar: ProgressBar = $VBox/TimerBar

var powerup_type: String = ""
var max_duration: float = 10.0
var time_left: float = 10.0

# Color thresholds
const COLOR_GOOD = Color(0.3, 0.85, 0.4)       # Green — plenty of time
const COLOR_WARNING = Color(1.0, 0.75, 0.15)    # Yellow — getting low
const COLOR_DANGER = Color(0.9, 0.2, 0.15)      # Red — about to expire

func setup(type: String, duration: float) -> void:
	powerup_type = type
	max_duration = duration
	time_left = duration
	timer_bar.max_value = duration
	timer_bar.value = duration
	if name_label:
		name_label.text = _get_display_name(type)
	_update_bar_color()

	# Pop-in animation
	modulate.a = 0.0
	scale = Vector2(0.8, 0.8)
	pivot_offset = size / 2.0
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.15)
	tween.parallel().tween_property(self, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _process(delta: float) -> void:
	if not PowerupManager.has_powerup(powerup_type):
		# Powerup expired — fade out and remove
		_expire()
		set_process(false)
		return

	time_left = PowerupManager.active_powerups.get(powerup_type, 0.0)
	timer_bar.value = time_left
	_update_bar_color()

	# Flash when critically low
	if time_left < 2.0:
		var flash = fmod(time_left, 0.4) < 0.2
		name_label.modulate.a = 0.5 if flash else 1.0

func _update_bar_color() -> void:
	var ratio = time_left / max_duration if max_duration > 0 else 0.0
	var color: Color
	if ratio > 0.5:
		color = COLOR_GOOD
	elif ratio > 0.2:
		# Lerp from yellow to green
		var t = (ratio - 0.2) / 0.3
		color = COLOR_WARNING.lerp(COLOR_GOOD, t)
	else:
		# Lerp from red to yellow
		var t = ratio / 0.2
		color = COLOR_DANGER.lerp(COLOR_WARNING, t)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = color
	fill_style.corner_radius_top_left = 2
	fill_style.corner_radius_top_right = 2
	fill_style.corner_radius_bottom_right = 2
	fill_style.corner_radius_bottom_left = 2
	timer_bar.add_theme_stylebox_override("fill", fill_style)

func _expire() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(self, "scale", Vector2(0.8, 0.8), 0.2)
	await tween.finished
	queue_free()

func _get_display_name(type: String) -> String:
	match type:
		"triple_shot": return "Triple Shot"
		"rapid_fire": return "Rapid Fire"
		"explosive_arrows": return "Explosive Arrows"
		"spin_attack": return "Spin Attack"
		"triple_slash": return "Triple Slash"
		"berserker": return "Berserker"
	return type.capitalize()
