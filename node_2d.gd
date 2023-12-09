
extends Node2D


#0绘制 1擦除
var pen_mode = 0
var pen_post = Vector2(0,0)
var data = {
	"map":{}
}
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

#func _input(event):
#
#	pass
#


func _on_removal_button_pressed():
	pen_mode = 1
	pass # Replace with function body.


func _on_draw_button_pressed():
	pen_mode = 0
	pass # Replace with function body.


func _on_tile_map_laod_complete(textrue ,node:TileMapHexagon):
	print(textrue)
	for x in range(textrue.get_width() / node.tile_size.x):
		for y in range(textrue.get_height() / node.tile_size.y):
			var at := AtlasTexture.new()
			at.atlas = textrue
			at.region = Rect2(x * node.tile_size.x, y * node.tile_size.y, node.tile_size.x, node.tile_size.y)
			var map_item = load("res://map_item.tscn").instantiate()
			map_item.data = {
				"texture":at,
				"Vector2":Vector2(x,y)
			}
			
			map_item.on_click.connect(Callable(self,"map_on_click"))
			%HFlowContainer.add_child(map_item)
			print(map_item.data)
			pass
	pass # Replace with function body.

func map_on_click(node):
	pen_post = node.data.Vector2
	print("test====",pen_post)
	pass
	
func _on_margin_container_2_gui_input(event):
	if event is InputEventScreenDrag:
		
		var map_post = $TileMap.local_to_map(get_global_mouse_position())
		print("test+++++",pen_post)
		match pen_mode:
			0:
#				layer: int, coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(-1, -1), alternative_tile: int = 0)
				$TileMap.set_cell(0,map_post,0,pen_post)
				data.map[map_post] = ({"layer":0,"coords":map_post,"source_id":0,"atlas_coords":pen_post})
			1:
				$TileMap.set_cell(0,map_post,-1,Vector2(0,0))
				data.map.erase(map_post)
	pass # Replace with function body.


func _on_export_button_pressed():
	%FileExportDialog.popup()
	#var file = FileAccess.open("res://mapData//save_game.dat", FileAccess.WRITE)
	#file.store_string(var_to_str(data))

	pass # Replace with function body.


func _on_import_button_pressed():
	%FileImportDialog.popup()


func _on_file_export_dialog_file_selected(path):
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(var_to_str(data))


func _on_file_import_dialog_file_selected(path):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	data = str_to_var(content)
#	print()
	for key in str_to_var(content).map:
		var item = str_to_var(content).map[key]
		$TileMap.set_cell(item.layer,item.coords,item.source_id,item.atlas_coords)

	pass # Replace with function body.
