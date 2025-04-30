extends Node
class_name Dungeon

static var dungeon_data =  {
	"floor": [], 
	"walls": [], 
	"doors": [],
	"size": 0,
	"name": "",
	"description": ""
}

static func name() -> String:
	return dungeon_data.name

static func description() -> String:
	return dungeon_data.description

static func size() -> int:
	return dungeon_data.size

static func get_data() -> Dictionary:
	return dungeon_data

static func get_object_property_from_dict(properties:Array, property_name:String, default_value:Variant) -> Variant:
	for property in properties:
		if property.name == property_name:
			return property.value

	return default_value
	
static func load_town():
	
	#var floor = []
	var objects = []
	
	var json_file = FileAccess.open("res://levels/town.json", FileAccess.READ)
	var json_text = json_file.get_as_text()
	var data = JSON.parse_string(json_text)

	if typeof(data) != TYPE_DICTIONARY:
		print("Failed to parse JSON")
		return

	var width:int = int(data.get("width", 0))
	var height:int = int(data.get("height", 0))

	dungeon_data.size = width
	dungeon_data.floor = init_and_fill_array(dungeon_data.size, 0)
	dungeon_data.walls = init_and_fill_array(dungeon_data.size, 0)
	dungeon_data.chests = init_and_fill_array(dungeon_data.size, null)
	dungeon_data.enemies = init_and_fill_array(dungeon_data.size, null)

	dungeon_data.name = get_object_property_from_dict(data.properties, "name", "")
	dungeon_data.description = get_object_property_from_dict(data.properties, "description", "")
	
	dungeon_data.floor.resize(width)
	for x in range(width):
		dungeon_data.floor[x] = []
		dungeon_data.floor[x].resize(height)

	for layer in data.get("layers", []):
		if layer.get("name") == "floor" and layer.get("type") == "tilelayer":
			var layer_data = layer.get("data", [])
			for i in range(min(layer_data.size(), width * height)):
				var x:int = i % width
				var y:int = int(i / floor(width))
				dungeon_data.floor[y][x] = int(layer_data[i])

		if layer.get("name") == "walls" and layer.get("type") == "tilelayer":
			var layer_data = layer.get("data", [])
			for i in range(min(layer_data.size(), width * height)):
				var x:int = i % width
				var y:int = int(i / floor(width))
				dungeon_data.walls[y][x] = int(layer_data[i])
						
		if layer.get("type") == "objectgroup":
			for obj in layer.get("objects", []):
				objects.append(obj)

	for obj in objects:
		if obj.type == "door" or obj.type == "gate" or obj.type == "vendor":
			var door := Door.new()
			door.id = ""
			match obj.type:
				"door": door.type = Door.DoorType.STANDARD
				"gate": door.type = Door.DoorType.GATE
				"vendor": door.type = Door.DoorType.VENDOR
			door.direction = get_object_property_from_dict(obj.properties, "direction", 0)
			door.state = get_object_property_from_dict(obj.properties, "state", 0)
			door.vendor_id = get_object_property_from_dict(obj.properties, "vendor_id", "")
			door.display_name = get_object_property_from_dict(obj.properties, "display_name", "")
			door.always_open = get_object_property_from_dict(obj.properties, "always_open", true)
			door.position = Vector2i(int(obj.x/32), int(obj.y/32)-1)
			dungeon_data.doors.append(door)
		if obj.type == "player_spawnpoint":
			var dir = get_object_property_from_dict(obj.properties, "direction", 0)
			var pos:Vector2i = Vector2i(int(obj.x/32), int(obj.y/32)-1)
			Events.set_player_position_and_direction.emit(pos, dir)

	Events.level_loaded.emit()

static func is_floor(pos:Vector2i) -> bool:
	return dungeon_data.floor[pos.y][pos.x] > 0
	
static func load_dungeon_data(dungeon_name:String) -> bool:

	var filename:String

	if OS.has_feature("standalone"):
		filename = str(OS.get_executable_path().get_base_dir(), "/data/", dungeon_name, ".json")
	else:
		filename = str("data/", dungeon_name, ".json")

	if not FileAccess.file_exists(filename):
		return false

	var file = FileAccess.open(filename, FileAccess.READ)
	if file == null:
		printerr("Failed to open dungeon file: ", filename)
		return false
	
	var json_text = file.get_as_text()
	var result = JSON.parse_string(json_text)
	
	if result == null:
		printerr("Failed to parse JSON from file: ", filename)
		return false
	
	dungeon_data.floor = result.ground
	dungeon_data.chests = result.chests
	dungeon_data.enemies = result.enemies
	
	return true
		
static func init_and_fill_array(count: int, default_value = null) -> Array:
	
	var row_template := []
	row_template.resize(count)
	row_template.fill(default_value)

	var grid = []
	grid.resize(count)
	for y in count:
		grid[y] = row_template.duplicate()

	return grid			
