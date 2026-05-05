extends Control

# Icons (for hover/click animations)
@onready var _icons: Dictionary = {
	"firerate": $Book/FirerateIcon,
	"speed": $Book/SpeedIcon,
	"attack": $Book/AttackIcon,
	"defence": $Book/DefenceIcon,
}

# Price labels (the "10" next to the coin)
@onready var _price_labels: Dictionary = {
	"firerate": $Book/FireratePrice,
	"speed": $Book/SpeedPrice,
	"attack": $Book/AttackPrice,
	"defence": $Book/DefencePrice,
}

# Level labels (the "0" showing current level)
@onready var _level_labels: Dictionary = {
	"firerate": $Book/FirerateLevel,
	"speed": $Book/SpeedLevel,
	"attack": $Book/AttackLevel,
	"defence": $Book/DefenceLevel,
}

var _icon_buttons: Dictionary = {}
var _icon_base_scales: Dictionary = {}

func _ready() -> void:
	$Book.visible = false
	if has_node("Blur shader"):
		$"Blur shader".visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Save original icon scales for hover animation
	for stat in _icons:
		_icon_base_scales[stat] = _icons[stat].scale

	# Create invisible clickable buttons over each icon
	for stat in _icons:
		var icon: Sprite2D = _icons[stat]
		var base_scale: Vector2 = _icon_base_scales[stat]

		var btn = Button.new()
		var tex = icon.texture
		var region_size: Vector2
		if icon.region_enabled:
			region_size = icon.region_rect.size
		else:
			region_size = tex.get_size()
		var icon_screen_size = region_size * base_scale
		btn.custom_minimum_size = icon_screen_size
		btn.size = icon_screen_size
		btn.position = icon.position - icon_screen_size / 2.0

		var empty_style = StyleBoxFlat.new()
		empty_style.bg_color = Color(0, 0, 0, 0)
		empty_style.set_border_width_all(0)
		for style_name in ["normal", "hover", "pressed", "disabled", "focus"]:
			btn.add_theme_stylebox_override(style_name, empty_style)
		btn.flat = true
		btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

		btn.pressed.connect(_on_upgrade_pressed.bind(stat))
		btn.mouse_entered.connect(_on_icon_hover.bind(stat, true))
		btn.mouse_exited.connect(_on_icon_hover.bind(stat, false))
		add_child(btn)
		_icon_buttons[stat] = btn

	GameState.upgrades_changed.connect(_refresh_ui)
	GameState.coins_changed.connect(func(_c): _refresh_ui())
	_refresh_ui()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.physical_keycode == KEY_G:
			_toggle_menu()
			get_viewport().set_input_as_handled()

func _toggle_menu() -> void:
	$Book.visible = !$Book.visible
	if has_node("Blur shader"):
		$"Blur shader".visible = $Book.visible
	get_tree().paused = $Book.visible

func _on_icon_hover(stat: String, hovering: bool) -> void:
	var icon = _icons[stat]
	var base = _icon_base_scales[stat]
	var tw = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	if hovering:
		tw.tween_property(icon, "scale", base * 1.15, 0.12)
	else:
		tw.tween_property(icon, "scale", base, 0.12)

func _on_upgrade_pressed(stat: String) -> void:
	if GameState.try_upgrade(stat):
		# Punch animation on the icon
		var icon = _icons[stat]
		var base = _icon_base_scales[stat]
		var tw = create_tween()
		tw.tween_property(icon, "scale", base * 1.3, 0.06)
		tw.tween_property(icon, "scale", base, 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	_refresh_ui()

func _refresh_ui() -> void:
	for stat in _icons:
		var level = GameState.upgrade_levels[stat]

		# Update level label
		_level_labels[stat].text = str(level)

		# Update price label
		if level >= GameState.MAX_UPGRADE_LEVEL:
			_price_labels[stat].text = "MAX"
		else:
			_price_labels[stat].text = str(GameState.get_upgrade_cost(stat))

		# Dim the icon if can't afford or maxed
		var icon = _icons[stat]
		if level >= GameState.MAX_UPGRADE_LEVEL:
			icon.modulate = Color(1.0, 0.9, 0.4) # Golden tint for maxed
		elif GameState.coins < GameState.get_upgrade_cost(stat):
			icon.modulate = Color(0.5, 0.5, 0.5) # Grey out if too expensive
		else:
			icon.modulate = Color.WHITE
