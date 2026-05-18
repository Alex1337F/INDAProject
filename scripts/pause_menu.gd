extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var resume_btn: Button = $Panel/VBox/Buttons/ResumeBtn
@onready var restart_btn: Button = $Panel/VBox/Buttons/RestartBtn
@onready var quit_btn: Button = $Panel/VBox/Buttons/QuitBtn

# Stats labels
@onready var total_kills_label: Label = $StatsPanel/StatsVBox/TotalKills
@onready var deaths_label: Label = $StatsPanel/StatsVBox/Deaths
@onready var coins_earned_label: Label = $StatsPanel/StatsVBox/CoinsEarned
@onready var time_played_label: Label = $StatsPanel/StatsVBox/TimePlayed
@onready var kill_breakdown: VBoxContainer = $StatsPanel/StatsVBox/KillBreakdown

var is_paused: bool = false
var anim_tween: Tween

func _ready() -> void:
	layer = 25
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	quit_btn.pressed.connect(_on_quit)

	# Button hover styling
	for btn in [resume_btn, restart_btn, quit_btn]:
		btn.mouse_entered.connect(_on_button_hover.bind(btn))
		btn.mouse_exited.connect(_on_button_unhover.bind(btn))

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_ESCAPE:
			if is_paused:
				_resume()
			else:
				_pause()
			get_viewport().set_input_as_handled()

func _pause() -> void:
	is_paused = true
	visible = true
	get_tree().paused = true
	_refresh_stats()
	
	overlay.modulate.a = 0.0
	panel.modulate.a = 0.0
	
	if anim_tween:
		anim_tween.kill()
	anim_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	anim_tween.tween_property(overlay, "modulate:a", 1.0, 0.1)
	anim_tween.parallel().tween_property(panel, "modulate:a", 1.0, 0.1)

func _resume() -> void:
	is_paused = false
	
	if anim_tween:
		anim_tween.kill()
	anim_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	
	anim_tween.tween_property(overlay, "modulate:a", 0.0, 0.1)
	anim_tween.parallel().tween_property(panel, "modulate:a", 0.0, 0.1)
	
	await anim_tween.finished
	visible = false
	get_tree().paused = false

func _on_resume() -> void:
	_resume()

func _on_restart() -> void:
	get_tree().paused = false
	is_paused = false
	get_tree().reload_current_scene()

func _on_quit() -> void:
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene_to_file("res://scenes/class_select.tscn")

func _on_button_hover(btn: Button) -> void:
	# No hover animation, standard stylebox handles it
	pass

func _on_button_unhover(btn: Button) -> void:
	# No unhover animation
	pass

func _refresh_stats() -> void:
	total_kills_label.text = "Kills: %d" % GameState.total_kills
	deaths_label.text = "Deaths: %d" % GameState.total_deaths
	coins_earned_label.text = "Coins Earned: %d" % GameState.total_coins_earned
	time_played_label.text = "Time: %s" % GameState.get_time_string()

	# Clear old breakdown rows
	for child in kill_breakdown.get_children():
		child.queue_free()

	# Add a row for each enemy type killed
	var sorted_types = GameState.kills_by_type.keys()
	sorted_types.sort()
	for enemy_type in sorted_types:
		var count = GameState.kills_by_type[enemy_type]
		var row = HBoxContainer.new()
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var name_lbl = Label.new()
		name_lbl.text = enemy_type
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_lbl.add_theme_font_size_override("font_size", 12)
		name_lbl.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
		row.add_child(name_lbl)

		var count_lbl = Label.new()
		count_lbl.text = str(count)
		count_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		count_lbl.add_theme_font_size_override("font_size", 12)
		count_lbl.add_theme_color_override("font_color", Color(0.9, 0.85, 0.6))
		row.add_child(count_lbl)

		kill_breakdown.add_child(row)

	# If no kills yet, show a placeholder
	if GameState.kills_by_type.is_empty():
		var empty_lbl = Label.new()
		empty_lbl.text = "No kills yet"
		empty_lbl.add_theme_font_size_override("font_size", 11)
		empty_lbl.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		kill_breakdown.add_child(empty_lbl)

func _on_fullscreen_pressed() -> void:
	var win = get_window()
	#if win.has_method("is_embedded") and win.is_embedded():
	#	print("Fullscreen is not supported while the game window is embedded.")
	#	return

	if win.mode == Window.MODE_FULLSCREEN or win.mode == Window.MODE_EXCLUSIVE_FULLSCREEN:
		win.mode = Window.MODE_WINDOWED
		win.borderless = false
	else:
		win.mode = Window.MODE_FULLSCREEN
		win.borderless = true
