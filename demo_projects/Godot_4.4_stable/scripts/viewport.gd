extends Node2D

var _delta:float = 0 

func _draw():
	if DungeonRenderer.is_ready:
		DungeonRenderer.render(self._delta, Dungeon.get_data())
	
func _process(delta):
	self._delta = delta
	queue_redraw() 
