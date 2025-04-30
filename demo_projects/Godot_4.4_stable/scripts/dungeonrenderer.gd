extends RefCounted
class_name DungeonRenderer

static var _dungeon_data = {}
static var is_ready:bool = false
static var _canvas:Node2D
static var _delta:float = 0

# ==========================================================================================================================================================

static func init(canvas:Node2D) -> void:
	_canvas = canvas
	RenderingServer.set_default_clear_color(Color(0.0,0.0,0.0,1.0)) 
	is_ready = true

static func get_doors_at(pos:Vector2i) -> Array[Door]:
	var result:Array[Door] = []
	for door in _dungeon_data.doors:
		if door.position == pos:
			result.append(door)
	return result
	
# ==========================================================================================================================================================

static func find_chest_by_position(pos:Vector2i) -> Dictionary:
	for chest in _dungeon_data.chests:
		if chest.position_x == pos.x and chest.position_y == pos.y:
			return chest
	return {}

# ==========================================================================================================================================================

static func find_enemy_by_position(pos:Vector2i) -> Dictionary:
	for enemy in _dungeon_data.enemies:
		if enemy.position_x == pos.x and enemy.position_y == pos.y:
			return enemy
	return {}
	
# ==========================================================================================================================================================
	
static func get_player_direction_vector_offsets(x, z):
	if Player.direction == 0:
		return { x = Player.position.x + x, y = Player.position.y + z }
	elif Player.direction == 1:
		return { x = Player.position.x - z, y = Player.position.y + x }
	elif Player.direction == 2:
		return { x = Player.position.x - x, y = Player.position.y - z }
	elif Player.direction == 3:
		return { x = Player.position.x + z, y = Player.position.y - x } 

# ==========================================================================================================================================================

static func get_tile_from_atlas(atlas_id, layer_id, x, z, orientation = null, frame_index = -1):

	var layer = AtlasManager.get_atlas_layer(atlas_id, layer_id)
	
	for tile in layer.tiles:
		if tile.x == x and tile.z == z:
			if orientation:
				if frame_index != -1:
					if tile.orientation == orientation and tile.frame == frame_index:
						return tile
				else:
					if tile.orientation == orientation:
						return tile
			elif frame_index != -1:
				if tile.frame_index == frame_index:
					return tile
			else:
				return tile
	return null

# ==========================================================================================================================================================

static func draw_tile(atlas_id, layer_id, x, z, orientation = null):
	
	var tile = get_tile_from_atlas(atlas_id, layer_id, x, z, orientation);

	if tile:
		var texture = AtlasManager.get_cropped_texture(AtlasManager.get_atlas_texture(atlas_id), Rect2(tile.atlas_coords.x, tile.atlas_coords.y, tile.atlas_coords.w, tile.atlas_coords.h))
		_canvas.draw_texture(texture, Vector2(tile.screen_coords.x,tile.screen_coords.y))
		
# ==========================================================================================================================================================
		
static func draw_front_wall_tile(atlas_id, layer_id, x, z, orientation = null):
	
	var tile = get_tile_from_atlas(atlas_id, layer_id, 0, z, orientation);

	if tile:
		var texture = AtlasManager.get_cropped_texture(AtlasManager.get_atlas_texture(atlas_id), Rect2(tile.atlas_coords.x, tile.atlas_coords.y, tile.atlas_coords.w, tile.atlas_coords.h))
		if x == 0:
			_canvas.draw_texture(texture, Vector2(tile.screen_coords.x,tile.screen_coords.y))
		elif x < 0:
			var sx = tile.screen_coords.x - (-x * tile.screen_coords.w-1)
			_canvas.draw_texture(texture, Vector2(sx,tile.screen_coords.y))
		elif x > 0:
			var sx = tile.screen_coords.x + (x * tile.screen_coords.w-1)
			_canvas.draw_texture(texture, Vector2(sx,tile.screen_coords.y))

# ==========================================================================================================================================================

static func draw_left_walls(x, z):

	var p = get_player_direction_vector_offsets(x, z);
	
	if p.x >= 0 and p.y >= 0 and p.x < _dungeon_data.size and p.y < _dungeon_data.size:
		if _dungeon_data.walls[p.y][p.x] != 0:
			draw_tile("dungeon", "walls_left", x, z)

# ==========================================================================================================================================================

static func draw_right_walls(x, z):

	var p = get_player_direction_vector_offsets(x, z);
	
	if p.x >= 0 and p.y >= 0 and p.x < _dungeon_data.size and p.y < _dungeon_data.size:
		if _dungeon_data.walls[p.y][p.x] != 0:
			draw_tile("dungeon", "walls_right", x, z)

# ==========================================================================================================================================================

static func draw_front_walls(x, z):

	var p = get_player_direction_vector_offsets(x, z);
	
	if p.x >= 0 and p.y >= 0 and p.x < _dungeon_data.size and p.y < _dungeon_data.size:
		if _dungeon_data.walls[p.y][p.x] != 0:
			draw_front_wall_tile("dungeon", "walls_front", x, z)

# ==========================================================================================================================================================

static func draw_side_doors(x, z):
	
	var p = get_player_direction_vector_offsets(x, z);
	
	if p.x >= 0 and p.y >= 0 and p.x < _dungeon_data.size and p.y < _dungeon_data.size:
	
		var doors = get_doors_at(Vector2i(p.x, p.y))
		for door in doors:
			match Player.direction:
				0: # player facing north
					if door.direction == 1: # door facing east
						draw_tile("dungeon", "doors_left", x, z)
					if door.direction == 3: # door facing west
						draw_tile("dungeon", "doors_right", x-2, z)
				2: # player facing south
					if door.direction == 1: # door facing east
						draw_tile("dungeon", "doors_right", x-2, z)
					if door.direction == 3: # door facing west
						draw_tile("dungeon", "doors_left", x, z)
				1: # player facing east
					if door.direction == 0: # door facing north
						draw_tile("dungeon", "doors_right", x-2, z)
					if door.direction == 2: # door facing south
						draw_tile("dungeon", "doors_left", x, z)
				3: # player facing west
					if door.direction == 0: # door facing north
						draw_tile("dungeon", "doors_left", x, z)
					if door.direction == 2: # door facing south
						draw_tile("dungeon", "doors_right", x-2, z)

# ==========================================================================================================================================================

static func draw_front_doors(x, z):
	
	var p = get_player_direction_vector_offsets(x, z);
	
	if p.x >= 0 and p.y >= 0 and p.x < _dungeon_data.size and p.y < _dungeon_data.size:
	
		var doors = get_doors_at(Vector2i(p.x, p.y))
		for door in doors:
			match Player.direction:
				0: # player facing north
					if door.direction == 2: # door facing south
						draw_front_wall_tile("dungeon", "doors_front", x, z)
				2: # player facing south
					if door.direction == 0: # door facing north
						draw_front_wall_tile("dungeon", "doors_front", x, z)
				1: # player facing east
					if door.direction == 3: # door facing west
						draw_front_wall_tile("dungeon", "doors_front", x, z)
				3: # player facing west
					if door.direction == 1: # door facing west
						draw_front_wall_tile("dungeon", "doors_front", x, z)

# ==========================================================================================================================================================
			
static func draw_map_square(x, z):
	
	var p = get_player_direction_vector_offsets(x, z);
	
	if p.x >= 0 and p.y >= 0 and p.x < _dungeon_data.size and p.y < _dungeon_data.size:

		if _dungeon_data.walls[p.y][p.x] != 0:
			draw_left_walls(x, z)
			draw_right_walls(x, z)
			draw_front_walls(x, z)

			draw_side_doors(x, z)
			draw_front_doors(x, z)

# ==========================================================================================================================================================
			
static func render(delta:float, dungeon_data:Dictionary):
	
	if !is_ready:
		return
	
	_dungeon_data = dungeon_data
	_delta = delta
	
	_canvas.draw_rect(Rect2(0, 0, 176, 176), Color.BLACK)
	
	for z in range(-AtlasManager.atlas_info.render_depth, 1):
		for x in range(-AtlasManager.atlas_info.render_width,0):
			draw_map_square(x, z)
		for x in range(AtlasManager.atlas_info.render_width+1,0, -1):
			draw_map_square(x, z)
		draw_map_square(0, z) 
