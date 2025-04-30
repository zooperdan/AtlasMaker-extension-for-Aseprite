extends RefCounted
class_name AtlasManager

static var atlases = {
	"dungeon": { "texture": null, "json": null },
	"enemies": { "texture": null, "json": null },
	"containers": { "texture": null, "json": null },
	"props": { "texture": null, "json": null }
}	
	
static var atlas_info = {
	"render_depth": 7,
	"render_width": 6,
	"viewport_width": 512,
	"viewport_height": 360,
}

static func get_cropped_texture(texture: Texture2D, region: Rect2) -> Texture2D:
	var result := AtlasTexture.new()
	result.set_atlas(texture)
	result.region = region
	return result 
	
static func load_atlas():
	
	for key in atlases:
		var atlas = atlases[key]
		var image_filename = str("res://assets/atlases/", key, ".png")
		var json_filename = str("res://assets/atlases/", key, ".json")
		if FileAccess.file_exists(image_filename):
			atlas.texture =  load(image_filename)
		if FileAccess.file_exists(json_filename):
			atlas.json = load(json_filename).data
		
static func get_atlas_layer(atlas_name:String, layer_name:String) -> Dictionary:

	if !atlases.has(atlas_name):
		push_error("No atlas by this name: ", atlas_name)
		return {}

	return atlases[atlas_name].json["layers"][layer_name]

static func get_atlas_texture(atlas_name:String) -> Texture2D:

	if atlases.has(atlas_name):
		return atlases[atlas_name].texture

	return null
