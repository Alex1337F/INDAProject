extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var victory_title: Label = $VictoryTitle
@onready var divider: ColorRect = $Divider
@onready var subtitle: Label = $Subtitle
@onready var stats_label: Label = $StatsLabel
@onready var continue_btn: Button = $ContinueBtn

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	continue_btn.pressed.connect(_on_continue)

	# Hide everything for animation
	overlay.color.a = 0.0
	victory_title.modulate.a = 0.0
	victory_title.scale = Vector2(2.5, 2.5)
	victory_title.pivot_offset = victory_title.size / 2.0
	divider.scale = Vector2(0.0, 1.0)
	divider.pivot_offset = Vector2(divider.size.x / 2.0, 0)
	subtitle.modulate.a = 0.0
	stats_label.modulate.a = 0.0
	continue_btn.modulate.a = 0.0

	# Populate stats
	stats_label.text = "Kills: %d  |  Deaths: %d  |  Time: %s" % [
		GameState.total_kills,
		GameState.total_deaths,
		GameState.get_time_string()
	]

	# Animate in
	_animate_in()

func _animate_in() -> void:
	var tween = create_tween()

	# Phase 1: Overlay
	tween.tween_property(overlay, "color:a", 0.8, 1.0).set_ease(Tween.EASE_OUT)

	# Phase 2: Title slams in
	tween.tween_property(victory_title, "modulate:a", 1.0, 0.01)
	tween.tween_property(victory_title, "scale", Vector2(1.05, 1.05), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(victory_title, "scale", Vector2(1.0, 1.0), 0.15)

	# Phase 3: Divider
	tween.tween_property(divider, "scale:x", 1.0, 0.3).set_ease(Tween.EASE_OUT)

	# Phase 4: Subtitle
	tween.tween_property(subtitle, "modulate:a", 1.0, 0.4)

	# Phase 5: Stats
	tween.tween_interval(0.2)
	tween.tween_property(stats_label, "modulate:a", 1.0, 0.4)

	# Phase 6: Button
	tween.tween_interval(0.3)
	tween.tween_property(continue_btn, "modulate:a", 1.0, 0.4)

func _on_continue() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/class_select.tscn")
