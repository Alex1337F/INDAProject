extends CanvasLayer

@onready var container: VBoxContainer = $Container

const TIMER_ITEM_SCENE = preload("res://scenes/PowerupTimerItem.tscn")

func _ready() -> void:
	PowerupManager.powerup_activated.connect(_on_powerup_activated)

func _on_powerup_activated(type: String) -> void:
	# Don't add duplicate if one already exists for this type
	for child in container.get_children():
		if child.has_method("setup") and child.powerup_type == type:
			# Refresh the existing timer instead
			child.setup(type, PowerupManager.POWERUP_DURATION)
			return

	var item = TIMER_ITEM_SCENE.instantiate()
	container.add_child(item)
	# Call setup after it's in the tree so @onready vars are ready
	item.call_deferred("setup", type, PowerupManager.POWERUP_DURATION)
