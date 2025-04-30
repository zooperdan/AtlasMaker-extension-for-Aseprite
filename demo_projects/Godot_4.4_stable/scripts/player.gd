extends Node

var position:Vector2i = Vector2i.ZERO
var direction = 0
			
func can_move(pos: Vector2i) -> bool:
	
	if !Dungeon.is_floor(pos):
		return false
	
	return true
	
func invert_direction(dir:int) -> int:
	var result = 0
	if dir == 0: result = 2
	if dir == 1: result = 3
	if dir == 2: result = 0
	if dir == 3: result = 1
	return result

func get_dest_pos(dir:int) -> Vector2:
	
	var vec = Vector2(
		sin(deg_to_rad(dir*90)),
		-cos(deg_to_rad(dir*90))
	)

	vec.x = vec.x + Player.position.x
	vec.y = vec.y + Player.position.y
	
	return vec

func move_forward():

	var destPos = get_dest_pos(Player.direction)

	if can_move(destPos):
		position = destPos
	
func move_backward():

	var destPos = get_dest_pos(invert_direction(Player.direction))

	if can_move(destPos):
		position = destPos
		
func strafe_left():

	var dir = Player.direction - 1
	if dir < 0: dir = 3
	
	var destPos = get_dest_pos(dir)

	if can_move(destPos):
		position = destPos
	
func strafe_right():

	var dir = Player.direction + 1
	if dir > 3: dir = 0
	
	var destPos = get_dest_pos(dir)

	if can_move(destPos):
		position = destPos
		
func turn_left():
	direction = direction - 1
	if direction < 0:
		direction = 3
		
func turn_right():
	direction = direction + 1
	if direction > 3:
		direction = 0
