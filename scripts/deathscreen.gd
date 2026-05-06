extends CanvasLayer

@onready var overlay: ColorRect = $Overlay
@onready var death_title: Label = $DeathTitle
@onready var death_subtitle: Label = $DeathSubtitle
@onready var death_divider: ColorRect = $Divider

var is_showing: bool = false
var subtitle_pulse_tween: Tween
var _player_ref: PlayerBase = null

func _ready() -> void:
	layer = 20 # Above everything
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Wait for player to spawn, then connect
	await get_tree().process_frame
	await get_tree().process_frame
	_connect_to_player()

func _connect_to_player() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		_player_ref = player
		if player.has_signal("player_died"):
			player.player_died.connect(_on_player_died)

func _on_player_died() -> void:
	show_death_screen()

func show_death_screen() -> void:
	is_showing = true
	visible = true

	# Reset starting states
	overlay.modulate.a = 0.0
	death_title.scale = Vector2(2.0, 2.0)
	death_title.pivot_offset = death_title.size / 2.0
	death_title.modulate = Color(1.0, 0.15, 0.1, 0.0)
	death_divider.scale = Vector2(0.0, 1.0)
	death_divider.pivot_offset = Vector2(death_divider.size.x / 2.0, 0)
	death_subtitle.modulate.a = 0.0

	var tween = create_tween()

	# Phase 1: Dark overlay fades in
	tween.tween_property(overlay, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_OUT)

	# Phase 2: Title slams in (scale down from big + fade in)
	tween.tween_property(death_title, "modulate:a", 1.0, 0.01)
	tween.tween_property(death_title, "scale", Vector2(1.05, 1.05), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(death_title, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN_OUT)

	# Phase 3: Divider line expands from center
	tween.tween_property(death_divider, "scale:x", 1.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)

	# Phase 4: Subtitle fades in
	tween.tween_property(death_subtitle, "modulate:a", 1.0, 0.4).set_ease(Tween.EASE_IN_OUT)

	# Phase 5: Start pulsing the subtitle
	await tween.finished
	_start_subtitle_pulse()

func _start_subtitle_pulse() -> void:
	if subtitle_pulse_tween:
		subtitle_pulse_tween.kill()
	subtitle_pulse_tween = create_tween().set_loops()
	subtitle_pulse_tween.tween_property(death_subtitle, "modulate:a", 0.3, 0.8).set_ease(Tween.EASE_IN_OUT)
	subtitle_pulse_tween.tween_property(death_subtitle, "modulate:a", 1.0, 0.8).set_ease(Tween.EASE_IN_OUT)

func hide_death_screen() -> void:
	is_showing = false
	if subtitle_pulse_tween:
		subtitle_pulse_tween.kill()
		subtitle_pulse_tween = null
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(death_title, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(death_subtitle, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(death_divider, "modulate:a", 0.0, 0.3)
	await tween.finished
	# Reset divider modulate for next death
	death_divider.modulate.a = 1.0
	visible = false

func _input(event: InputEvent) -> void:
	if is_showing and event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_R:
			hide_death_screen()
			if _player_ref and _player_ref.has_method("_respawn"):
				_player_ref._respawn()
			get_viewport().set_input_as_handled()
