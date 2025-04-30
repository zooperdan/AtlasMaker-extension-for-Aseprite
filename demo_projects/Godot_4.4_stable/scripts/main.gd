extends CanvasLayer

func _ready() -> void:

	Events.set_player_position_and_direction.connect(_on_set_player_position_and_direction)

	AtlasManager.load_atlas()
	Dungeon.load_town()
	DungeonRenderer.init($Viewport)

func _input(event):
	
	if event is InputEventKey and event.pressed:
		if event.is_action_pressed("move_forward"):
			Player.move_forward()
		if event.is_action_pressed("move_backward"):
			Player.move_backward()
		if event.is_action_pressed("turn_left"):
			Player.turn_left()
		if event.is_action_pressed("turn_right"):
			Player.turn_right()  	
		if event.is_action_pressed("strafe_left"):
			Player.strafe_left()
		if event.is_action_pressed("strafe_right"):
			Player.strafe_right()

func _on_set_player_position_and_direction(pos:Vector2i, dir:int):
	Player.position = pos
	Player.direction = dir

func _on_level_loaded():
	pass
