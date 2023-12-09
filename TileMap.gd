@tool
class_name TileMapHexagon
extends TileMap

@export var tile_size = Vector2(111,95)
signal laod_complete(data,node)
# Called when the node enters the scene tree for the first time.
func _ready():
	var img_tex = (load("res://hex_grid.png"))
	var ts := TileSet.new()
	ts.tile_size = Vector2(111,95)
	ts.tile_shape = TileSet.TILE_SHAPE_SQUARE
	ts.tile_offset_axis =TileSet.TILE_OFFSET_AXIS_VERTICAL
	var idx := 0
	
#			var at := AtlasTexture.new()
#			at.atlas = img_tex
#			at.region = Rect2(x * tile_size.x, y * tile_size.y, tile_size.x, tile_size.y)
	var source = TileSetAtlasSource.new()
	source.texture =img_tex
	source.texture_region_size = Vector2(111,95)
	
	source.create_tile(Vector2(0,0)) 
	source.create_tile(Vector2(0,1))
	source.create_tile(Vector2(0,2))  
	#for x in range(3):
	#	for y in range(1):
	#		source.create_tile(Vector2(x,y)) 
	ts.add_source( source,idx)
	#idx += 1
	tile_set = ts
	laod_complete.emit(img_tex,self)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
