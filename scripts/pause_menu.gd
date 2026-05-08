extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBox/Title
@onready var resume_btn: Button = $Panel/VBox/Buttons/ResumeBtn
@onready var restart_btn: Button = $Panel/VBox/Buttons/RestartBtn
@onready var quit_btn: Button = $Panel/VBox/Buttons/QuitBtn

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
