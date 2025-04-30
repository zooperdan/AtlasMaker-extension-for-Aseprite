extends Entity
class_name Door

enum DoorType {
	STANDARD = 0,
	GATE = 1,
	VENDOR = 2
}

enum DoorState {
	UNLOCKED = 0,
	LOCKED = 1,
	BLOCKED = 2,
}

var id:String
var display_name:String = ""
var position:Vector2i
var direction:int
var type:DoorType = DoorType.STANDARD
var state:DoorState = DoorState.UNLOCKED

# vendor properties
var vendor_id:String = ""
var always_open:bool = true
